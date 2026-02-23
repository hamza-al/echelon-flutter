import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../styles.dart';
import '../widgets/pulsing_particle_sphere.dart';
import '../widgets/rest_timer_module.dart';
import '../services/workout_service.dart';
import '../services/auth_service.dart';
import '../models/workout.dart';
import '../stores/active_workout_store.dart';
import '../components/workout_results_display.dart';
import 'exercise_selection_screen.dart';

class ActiveWorkoutScreen extends StatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> with SingleTickerProviderStateMixin {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // Voice states
  bool _isProcessing = false;
  bool _isPlaying = false;
  bool _isListening = false;      // Mic is open, waiting for speech
  bool _speechDetected = false;   // Speech has been detected in current recording
  
  // Adaptive VAD
  double? _noiseFloor;
  double _speechThreshold = -30.0;
  double _silenceThreshold = -45.0;
  bool _isCalibrating = false;
  final List<double> _calibrationSamples = [];
  int _speechConfirmCount = 0;
  static const int _speechConfirmRequired = 2;
  static const double _speechOffset = 18.0;
  static const double _silenceOffset = 8.0;
  static const double _minHysteresis = 10.0;
  static const Duration _silenceTimeout = Duration(milliseconds: 1500);
  StreamSubscription<Amplitude>? _amplitudeSubscription;
  Timer? _silenceTimer;
  
  Workout? _currentWorkout;
  // ignore: unused_field
  int _totalSets = 0;
  String _statusText = 'Starting...';
  
  // For showing workout results
  bool _showResults = false;
  List<Map<String, dynamic>> _lastLoggedSets = [];
  
  // For rest timer
  bool _showRestTimer = false;
  int _restTimerDuration = 0;
  
  // Animation controller for results fade
  AnimationController? _fadeController;
  Animation<double>? _fadeAnimation;
  
  // Tab control - 0: Voice, 1: Manual
  int _selectedTab = 0;
  
  // Manual logging form controllers
  final TextEditingController _exerciseController = TextEditingController();
  final TextEditingController _repsController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final FocusNode _repsFocusNode = FocusNode();
  final FocusNode _weightFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController!,
      curve: Curves.easeInOut,
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeWorkout();
    });
  }

  @override
  void dispose() {
    _silenceTimer?.cancel();
    _amplitudeSubscription?.cancel();
    _fadeController?.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _exerciseController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    _repsFocusNode.dispose();
    _weightFocusNode.dispose();
    super.dispose();
  }

  Future<void> _initializeWorkout() async {
    Workout? activeWorkout = WorkoutService.getActiveWorkout();
    
    if (activeWorkout != null) {
      if (mounted) {
        final workoutStore = context.read<ActiveWorkoutStore>();
        if (!workoutStore.hasActiveWorkout) {
          workoutStore.startWorkout(activeWorkout.id);
        }
      }
      
      setState(() {
        _currentWorkout = activeWorkout;
        _totalSets = activeWorkout.totalSets;
      });
    }
    
    if (mounted && _currentWorkout == null) {
      final workoutStore = context.read<ActiveWorkoutStore>();
      if (!workoutStore.hasActiveWorkout) {
        workoutStore.startWorkout('pending');
      }
    }
    
    if (mounted) {
      // Auto-start listening on voice tab
      if (_selectedTab == 0) {
        await _startListening();
      }
    }
  }

  // --- VAD-based auto-listening ---

  Future<void> _startListening() async {
    if (_isListening || _isProcessing || _isPlaying) return;

    try {
      if (!await _audioRecorder.hasPermission()) return;

      final tempDir = Directory.systemTemp;
      final filePath = '${tempDir.path}/workout_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 44100,
          bitRate: 128000,
        ),
        path: filePath,
      );

      _speechDetected = false;
      _silenceTimer?.cancel();
      
      // Reset adaptive VAD state for fresh calibration
      _noiseFloor = null;
      _calibrationSamples.clear();
      _speechConfirmCount = 0;
      _isCalibrating = true;
      
      // Monitor amplitude for VAD
      _amplitudeSubscription?.cancel();
      _amplitudeSubscription = _audioRecorder
          .onAmplitudeChanged(const Duration(milliseconds: 150))
          .listen(_onAmplitude);
      
      if (mounted) {
        setState(() {
          _isListening = true;
          _statusText = 'Calibrating...';
        });
      }
    } catch (e) {
      // Fall back to ready state
    }
  }

  void _onAmplitude(Amplitude amp) {
    if (!mounted || !_isListening) return;

    final db = amp.current;

    // Phase A: Calibration — collect samples to measure noise floor
    if (_isCalibrating) {
      _calibrationSamples.add(db);
      debugPrint('[VAD] Calibrating sample ${_calibrationSamples.length}: ${db.toStringAsFixed(1)} dB');

      if (_calibrationSamples.length >= 6) {
        final sorted = List<double>.from(_calibrationSamples)..sort();
        final trimmed = sorted.sublist(0, sorted.length - 1);
        _noiseFloor = trimmed.reduce((a, b) => a + b) / trimmed.length;
        _speechThreshold = _noiseFloor! + _speechOffset;
        _silenceThreshold = _noiseFloor! + _silenceOffset;

        // Enforce minimum hysteresis
        if ((_speechThreshold - _silenceThreshold) < _minHysteresis) {
          _speechThreshold = _silenceThreshold + _minHysteresis;
        }

        _isCalibrating = false;
        debugPrint('[VAD] Calibration done — floor: ${_noiseFloor!.toStringAsFixed(1)}, speechTh: ${_speechThreshold.toStringAsFixed(1)}, silenceTh: ${_silenceThreshold.toStringAsFixed(1)}');

        if (mounted) {
          setState(() { _statusText = 'Listening...'; });
        }
      }
      return;
    }

    // Phase B & C: Speech detection with confirmation + silence detection
    debugPrint('[VAD] dB: ${db.toStringAsFixed(1)} | floor: ${_noiseFloor?.toStringAsFixed(1)} | speechTh: ${_speechThreshold.toStringAsFixed(1)} | silenceTh: ${_silenceThreshold.toStringAsFixed(1)} | confirm: $_speechConfirmCount/$_speechConfirmRequired | speech: $_speechDetected');

    if (db > _speechThreshold) {
      _speechConfirmCount++;
      if (!_speechDetected && _speechConfirmCount >= _speechConfirmRequired) {
        _speechDetected = true;
        debugPrint('[VAD] >>> Speech confirmed after $_speechConfirmCount samples');
        if (mounted) {
          setState(() { _statusText = 'Hearing you...'; });
        }
      }
      _silenceTimer?.cancel();
      _silenceTimer = null;
    } else {
      _speechConfirmCount = 0;

      if (_speechDetected && db < _silenceThreshold) {
        if (_silenceTimer == null) {
          debugPrint('[VAD] ... Silence detected, starting ${_silenceTimeout.inMilliseconds}ms countdown');
        }
        _silenceTimer ??= Timer(_silenceTimeout, () {
          debugPrint('[VAD] <<< Silence timeout — sending recording');
          if (mounted && _isListening && _speechDetected) {
            _finishAndSend();
          }
        });
      }
    }
  }

  Future<void> _finishAndSend() async {
    _silenceTimer?.cancel();
    _silenceTimer = null;
    _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;

    try {
      final path = await _audioRecorder.stop();
      
      if (mounted) {
        setState(() {
          _isListening = false;
          _speechDetected = false;
          _isProcessing = true;
          _statusText = 'Processing...';
        });
      }

      if (path != null) {
        await _sendToAPI(path);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isListening = false;
          _speechDetected = false;
          _isProcessing = false;
        });
        // Restart listening on error
        await _startListening();
      }
    }
  }

  Future<void> _stopListening() async {
    _silenceTimer?.cancel();
    _silenceTimer = null;
    _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;

    if (_isListening) {
      try {
        await _audioRecorder.stop();
      } catch (e) {
        // Ignore
      }
    }

    if (mounted) {
      setState(() {
        _isListening = false;
        _speechDetected = false;
        _isCalibrating = false;
      });
    }
  }

  Future<void> _sendToAPI(String audioPath) async {
    try {
      // Get conversation history from store
      final workoutStore = context.read<ActiveWorkoutStore>();
      final conversationHistory = workoutStore.getConversationHistory();
      
      final authService = context.read<AuthService>();
      final token = authService.token;
      
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://echelon-fastapi.fly.dev/chat/voice'),
      );
      
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      
      // Add audio file
      request.files.add(
        await http.MultipartFile.fromPath(
          'audio',
          audioPath,
        ),
      );
      
      // Add conversation history as JSON field
      request.fields['conversation_history'] = json.encode(conversationHistory);
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        
        // Store conversation in the store
        final userTranscript = body['user_transcript'] as String? ?? '';
        final agentResponse = body['assistant_text'] as String? ?? '';
        
        if (mounted) {
          context.read<ActiveWorkoutStore>().addMessage(
            userTranscript: userTranscript,
            agentResponse: agentResponse,
          );
        }
        
        // Get the base64 audio
        final base64Audio = body['audio']['base64'];
        
        // Save the sets to Hive (only if there are commands)
        final commands = body['commands'] as List<dynamic>;
        if (commands.isNotEmpty) {
          await _saveWorkoutData(commands);
        }
        
        // Play response audio
        await _playResponseAudio(base64Audio);
        
        // After response, restart listening automatically
        if (mounted && _selectedTab == 0) {
          await _startListening();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        // Restart listening on error
        if (_selectedTab == 0) {
          await _startListening();
        }
      }
    }
  }

  Future<void> _saveWorkoutData(List<dynamic> commands) async {
    // Skip if no commands
    if (commands.isEmpty) return;
    
    // Check for timer commands first
    for (var command in commands) {
      if (command['type'] == 'start_timer') {
        final payload = command['payload'];
        final durationSeconds = payload['duration_seconds'] as int;
        
        setState(() {
          _showRestTimer = true;
          _restTimerDuration = durationSeconds;
        });
        
      }
    }
    
    // Create workout on first log if it doesn't exist
    if (_currentWorkout == null) {
      _currentWorkout = await WorkoutService.createWorkout(
        notes: 'Voice-logged workout',
      );
      
      // Initialize store with workout ID ONLY if not already started
      if (mounted) {
        final workoutStore = context.read<ActiveWorkoutStore>();
        if (!workoutStore.hasActiveWorkout) {
          workoutStore.startWorkout(_currentWorkout!.id);
        }
      }
    }
    
    // Extract the logged sets for display
    final loggedSets = commands
        .where((cmd) => cmd['type'] == 'log_set')
        .map((cmd) => cmd['payload'] as Map<String, dynamic>)
        .toList();
    
    // Skip if no log_set commands
    if (loggedSets.isEmpty) return;
    
    for (var command in commands) {
      if (command['type'] == 'log_set') {
        final payload = command['payload'];
        final exercise = payload['exercise'] as String;
        
        // Backend returns all fields but sets irrelevant ones to 0
        // Check duration_seconds to determine exercise type
        final durationSeconds = payload['duration_seconds'] as int? ?? 0;
        
        if (durationSeconds > 0) {
          // Duration-based exercise (cardio)
          await WorkoutService.addDurationSetToExercise(
            _currentWorkout!,
            exercise,
            durationSeconds,
          );
        } else {
          // Weight-based exercise
          final reps = payload['reps'] as int;
          final weight = payload['weight'] != null && (payload['weight'] as num) > 0
              ? (payload['weight'] as num).toDouble()
              : null;
          
          await WorkoutService.addSetToExercise(
            _currentWorkout!,
            exercise,
            reps,
            weight,
          );
        }
      }
    }
    
    // Update total sets count and show results
    setState(() {
      _totalSets = _currentWorkout!.totalSets;
      _lastLoggedSets = loggedSets;
      _showResults = true;
    });
    
    // Trigger fade-in animation
    _fadeController?.forward(from: 0.0);
    
    // Auto-hide after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _fadeController?.reverse().then((_) {
          if (mounted) {
            setState(() {
              _showResults = false;
            });
          }
        });
      }
    });
  }

  Future<void> _playResponseAudio(String base64Audio) async {
    try {
      if (_selectedTab != 0) {
        setState(() {
          _isProcessing = false;
          _isPlaying = false;
        });
        return;
      }
      
      final audioBytes = base64Decode(base64Audio);
      final tempDir = Directory.systemTemp;
      final tempPath = '${tempDir.path}/response_audio.mp3';
      final tempFile = File(tempPath);
      await tempFile.writeAsBytes(audioBytes);
      
      setState(() {
        _isProcessing = false;
        _isPlaying = true;
        _statusText = 'Speaking...';
      });
      
      await _audioPlayer.play(DeviceFileSource(tempPath));
      await _audioPlayer.onPlayerComplete.first;
      
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isPlaying = false;
        });
      }
    }
  }

  Future<void> _endWorkout() async {
    await _stopListening();
    
    try {
      await _audioPlayer.stop();
    } catch (e) {
      // Ignore
    }

    if (_currentWorkout != null) {
      if (_currentWorkout!.exercises.isEmpty) {
        await WorkoutService.deleteWorkout(_currentWorkout!);
      } else {
        await WorkoutService.completeWorkout(_currentWorkout!);
      }
    }
    
    if (mounted) {
      context.read<ActiveWorkoutStore>().endWorkout();
      Navigator.of(context).pop();
    }
  }

  Future<void> _logManualSet() async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();
    
    // Validate inputs
    if (_exerciseController.text.trim().isEmpty) {
      _showError('Please enter an exercise name');
      return;
    }
    
    if (_repsController.text.trim().isEmpty) {
      _showError('Please enter reps');
      return;
    }
    
    final reps = int.tryParse(_repsController.text.trim());
    if (reps == null || reps <= 0) {
      _showError('Please enter a valid number of reps');
      return;
    }
    
    double? weight;
    if (_weightController.text.trim().isNotEmpty) {
      weight = double.tryParse(_weightController.text.trim());
      if (weight == null || weight < 0) {
        _showError('Please enter a valid weight');
        return;
      }
    }
    
    // Create workout if needed
    if (_currentWorkout == null) {
      _currentWorkout = await WorkoutService.createWorkout(
        notes: 'Manual workout',
      );
      
      if (mounted) {
        final workoutStore = context.read<ActiveWorkoutStore>();
        if (!workoutStore.hasActiveWorkout) {
          workoutStore.startWorkout(_currentWorkout!.id);
        }
      }
    }
    
    // Log the set
    final exerciseName = _exerciseController.text.trim().toLowerCase().replaceAll(' ', '_');
    await WorkoutService.addSetToExercise(
      _currentWorkout!,
      exerciseName,
      reps,
      weight,
    );
    
    // Update UI
    setState(() {
      _totalSets = _currentWorkout!.totalSets;
      _lastLoggedSets = [{
        'exercise': exerciseName,
        'reps': reps,
        'weight': weight ?? 0,
        'duration_seconds': 0,
      }];
      _showResults = true;
    });
    
    // Trigger fade-in animation
    _fadeController?.forward(from: 0.0);
    
    // Auto-hide after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _fadeController?.reverse().then((_) {
          if (mounted) {
            setState(() {
              _showResults = false;
            });
          }
        });
      }
    });
  }
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  Future<void> _selectExercise() async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();
    
    // Navigate to exercise selection screen
    final selectedExercise = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const ExerciseSelectionScreen(),
      ),
    );
    
    if (selectedExercise != null) {
      setState(() {
        _exerciseController.text = _formatExerciseName(selectedExercise);
      });
      _prefillFromHistory(selectedExercise);
      _repsFocusNode.requestFocus();
    }
  }

  void _prefillFromHistory(String exerciseName) {
    final normalizedName = exerciseName.toLowerCase().replaceAll(' ', '_');
    
    // Check current workout first
    if (_currentWorkout != null) {
      for (final exercise in _currentWorkout!.exercises.reversed) {
        if (exercise.name == normalizedName && exercise.sets.isNotEmpty) {
          final lastSet = exercise.sets.last;
          _repsController.text = lastSet.reps.toString();
          if (lastSet.weight != null && lastSet.weight! > 0) {
            _weightController.text = lastSet.weight!.toStringAsFixed(0);
          }
          return;
        }
      }
    }

    // Fall back to previous completed workouts
    final workouts = WorkoutService.getCompletedWorkouts();
    for (final workout in workouts) {
      for (final exercise in workout.exercises) {
        if (exercise.name == normalizedName && exercise.sets.isNotEmpty) {
          final lastSet = exercise.sets.last;
          _repsController.text = lastSet.reps.toString();
          if (lastSet.weight != null && lastSet.weight! > 0) {
            _weightController.text = lastSet.weight!.toStringAsFixed(0);
          }
          return;
        }
      }
    }
  }
  
  String _formatExerciseName(String exercise) {
    return exercise
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
  
  Future<void> _stopAllAudioAndRecording() async {
    await _stopListening();
    
    try {
      await _audioPlayer.stop();
    } catch (e) {
      // Ignore
    }
    
    if (mounted) {
      setState(() {
        _isProcessing = false;
        _isPlaying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside
        if (_selectedTab == 1) {
          FocusScope.of(context).unfocus();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  // Header with close button and tab control
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Row(
                      children: [
                        // Close button
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: AppColors.accent,
                            size: 28,
                          ),
                          onPressed: _endWorkout,
                        ),
                        
                        const Spacer(),
                        
                        // Tab control
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildTabButton(
                                label: 'Voice',
                                icon: Icons.mic,
                                index: 0,
                              ),
                              const SizedBox(width: 4),
                              _buildTabButton(
                                label: 'Manual',
                                icon: Icons.edit,
                                index: 1,
                              ),
                            ],
                          ),
                        ),
                        
                        const Spacer(),
                        
                        // Spacer to balance the close button
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  
                  // Main content area
                  Expanded(
                    child: _selectedTab == 0 
                        ? _buildVoiceContent()
                        : _buildManualContent(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTabButton({
    required String label,
    required IconData icon,
    required int index,
  }) {
    final isSelected = _selectedTab == index;
    
    return GestureDetector(
      onTap: () async {
        await _stopAllAudioAndRecording();
        
        setState(() {
          _selectedTab = index;
        });
        FocusScope.of(context).unfocus();
        
        // Auto-start listening when switching to voice tab
        if (index == 0) {
          await _startListening();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.primaryLight 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected 
                  ? AppColors.background 
                  : AppColors.accent.withOpacity(0.5),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppStyles.mainText().copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected 
                    ? AppColors.background 
                    : AppColors.accent.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildVoiceContent() {
    final bool isActive = _speechDetected && _isListening;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Status text
          Text(
            _statusText,
            style: AppStyles.mainText().copyWith(
              fontSize: 16,
              color: AppColors.accent.withOpacity(0.7),
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Sphere -- tap to force-send if VAD hasn't triggered
          GestureDetector(
            onTap: () {
              if (_speechDetected && _isListening) {
                debugPrint('[VAD] Manual tap — force sending');
                _finishAndSend();
              }
            },
            child: Hero(
              tag: 'workout_sphere',
              child: PulsingParticleSphere(
                size: 240,
              primaryColor: isActive
                  ? AppColors.recordingPrimary
                  : AppColors.primary,
              secondaryColor: isActive
                  ? AppColors.recordingSecondary
                  : AppColors.primaryLight,
              accentColor: isActive
                  ? AppColors.recordingAccent
                  : AppColors.primaryDark,
              highlightColor: isActive
                  ? AppColors.recordingHighlight
                  : AppColors.primary,
              ),
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Rest timer module
          if (_showRestTimer)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: RestTimerModule(
                key: ValueKey(_restTimerDuration),
                durationSeconds: _restTimerDuration,
                onComplete: () {
                  setState(() {
                    _showRestTimer = false;
                  });
                },
              ),
            ),
          
          // Workout results
          if (_showResults && _lastLoggedSets.isNotEmpty && _fadeAnimation != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: FadeTransition(
                opacity: _fadeAnimation!,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: WorkoutResultsDisplay(
                    loggedSets: _lastLoggedSets,
                  ),
                ),
              ),
            ),
          
          if (!_showRestTimer && !_showResults)
            const SizedBox(height: 40),
          
          // Hint text
          Text(
            _isProcessing
                ? ''
                : _isPlaying
                    ? ''
                    : _isListening
                        ? 'Speak naturally — hands free'
                        : '',
            style: AppStyles.questionSubtext().copyWith(
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildManualContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          
          // Title
          Text(
            'Log a Set',
            style: AppStyles.mainHeader().copyWith(
              fontSize: 28,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 40),
          
          // Exercise name field
          Text(
            'Exercise',
            style: AppStyles.mainText().copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.accent.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _selectExercise,
            child: AbsorbPointer(
              child: TextField(
                controller: _exerciseController,
                style: AppStyles.mainText().copyWith(fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Tap to select',
                  hintStyle: AppStyles.questionSubtext().copyWith(fontSize: 16),
                  filled: true,
                  fillColor: AppColors.primary.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.accent.withOpacity(0.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Reps field
          Text(
            'Reps',
            style: AppStyles.mainText().copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.accent.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _repsController,
            focusNode: _repsFocusNode,
            style: AppStyles.mainText().copyWith(fontSize: 16),
            decoration: InputDecoration(
              hintText: 'e.g., 10',
              hintStyle: AppStyles.questionSubtext().copyWith(fontSize: 16),
              filled: true,
              fillColor: AppColors.primary.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            keyboardType: TextInputType.number,
            onSubmitted: (_) => _weightFocusNode.requestFocus(),
          ),
          
          const SizedBox(height: 24),
          
          // Weight field (optional)
          Text(
            'Weight (lbs) - Optional',
            style: AppStyles.mainText().copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.accent.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _weightController,
            focusNode: _weightFocusNode,
            style: AppStyles.mainText().copyWith(fontSize: 16),
            decoration: InputDecoration(
              hintText: 'e.g., 135',
              hintStyle: AppStyles.questionSubtext().copyWith(fontSize: 16),
              filled: true,
              fillColor: AppColors.primary.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onSubmitted: (_) => _logManualSet(),
          ),
          
          const SizedBox(height: 40),
          
          // Log button
          ElevatedButton(
            onPressed: _logManualSet,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryLight,
              foregroundColor: AppColors.background,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Log Set',
              style: AppStyles.mainText().copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.background,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Workout results (for manual mode)
          if (_showResults && _lastLoggedSets.isNotEmpty && _fadeAnimation != null)
            FadeTransition(
              opacity: _fadeAnimation!,
              child: WorkoutResultsDisplay(
                loggedSets: _lastLoggedSets,
              ),
            ),
        ],
      ),
    );
  }
}

