import 'package:flutter/material.dart';
import 'dart:io';
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
import '../services/workout_audio_cache.dart';
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
  
  bool _isRecording = false;
  bool _isProcessing = false;
  bool _isPlaying = false;
  bool _isInitializing = true;
  
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
    
    // Initialize fade animation controller
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController!,
      curve: Curves.easeInOut,
    );
    
    // Defer provider updates until after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeWorkout();
    });
  }

  @override
  void dispose() {
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
    // Check if there's already an active workout
    Workout? activeWorkout = WorkoutService.getActiveWorkout();
    
    if (activeWorkout != null) {
      // Initialize store with existing workout ID ONLY if not already started
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
    
    // If no active workout yet, start the store session without a workout ID
    // The workout will be created on first log
    if (mounted && _currentWorkout == null) {
      final workoutStore = context.read<ActiveWorkoutStore>();
      if (!workoutStore.hasActiveWorkout) {
        // Start with a temporary ID that will be replaced when workout is created
        workoutStore.startWorkout('pending');
      }
    }
    
    // Call the start workout endpoint and play greeting
    await _playStartWorkoutGreeting();
  }

  Future<void> _playStartWorkoutGreeting() async {
    try {
      setState(() {
        _statusText = 'Starting...';
      });

      final audioCache = context.read<WorkoutAudioCache>();
      
      // Try to get cached audio first
      final cachedPath = await audioCache.getCachedAudioPath();
      
      if (cachedPath != null) {
        // Play from cache - instant!
        setState(() {
          _isProcessing = false;
          _isPlaying = true;
        });
        
        await _audioPlayer.play(DeviceFileSource(cachedPath));
        await _audioPlayer.onPlayerComplete.first;
        
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _isInitializing = false;
            _statusText = 'Tap to speak';
          });
        }
      } else {
        // Fallback: fetch on demand if cache miss
        final authService = context.read<AuthService>();
        final token = authService.token;
        
        final headers = <String, String>{};
        if (token != null) {
          headers['Authorization'] = 'Bearer $token';
        }

        final response = await http.get(
          Uri.parse('https://echelon-fastapi.fly.dev/chat/start_workout_voice'),
          headers: headers,
        );

        if (response.statusCode == 200) {
          final body = json.decode(response.body);
          final base64Audio = body['audio']['base64'];
          
          // Play the greeting audio without auto-starting recording
          await _playResponseAudio(base64Audio, startRecordingAfter: false);
          
          // Cache for next time (fire and forget)
          audioCache.fetchAndCacheAudio().catchError((_) {});
        } else {
          // If request fails, still allow user to continue
          setState(() {
            _isInitializing = false;
            _statusText = 'Tap to speak';
          });
        }
      }
    } catch (e) {
      // If error occurs, still allow user to continue
      setState(() {
        _isInitializing = false;
        _statusText = 'Tap to speak';
      });
    }
  }

  Future<void> _handleTap() async {
    // Don't allow interaction during initialization, processing, or playing
    if (_isInitializing || _isProcessing || _isPlaying) return;

    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final Directory tempDir = Directory.systemTemp;
        final String filePath = '${tempDir.path}/workout_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            sampleRate: 44100,
            bitRate: 128000,
          ),
          path: filePath,
        );
        
        setState(() {
          _isRecording = true;
          _statusText = 'Listening...';
        });
      }
    } catch (e) {
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      
      setState(() {
        _isRecording = false;
        _isProcessing = true;
        _statusText = 'Processing...';
      });
      
      if (path != null) {
        await _sendToAPI(path);
      }
    } catch (e) {
      setState(() {
        _isRecording = false;
        _isProcessing = false;
        _statusText = 'Error occurred';
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
        
        // Update status
        setState(() {
          _statusText = commands.isNotEmpty ? 'Logged!' : 'Tap to speak';
        });
        
        // Reset status after delay (only if we logged something)
        if (commands.isNotEmpty) {
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                _statusText = 'Tap to speak';
              });
            }
          });
        }
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _statusText = 'Error occurred';
      });
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

  Future<void> _playResponseAudio(String base64Audio, {bool startRecordingAfter = false}) async {
    try {
      // Don't play audio if we're not on the voice tab
      if (_selectedTab != 0) {
        setState(() {
          _isProcessing = false;
          _isPlaying = false;
          _isInitializing = false;
          _statusText = 'Tap to speak';
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
      });
      
      await _audioPlayer.play(DeviceFileSource(tempPath));
      
      // Wait for playback to complete
      await _audioPlayer.onPlayerComplete.first;
      
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
        
        // If this is the start greeting, begin recording
        if (startRecordingAfter) {
          setState(() {
            _isInitializing = false;
            _statusText = 'Listening...';
          });
          await _startRecording();
        }
        // Otherwise, just set ready state
        else {
          setState(() {
            _isInitializing = false;
            _statusText = 'Tap to speak';
          });
        }
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _isPlaying = false;
        if (startRecordingAfter) {
          _isInitializing = false;
          _statusText = 'Tap to speak';
        }
      });
    }
  }

  Future<void> _endWorkout() async {
    if (_currentWorkout != null) {
      // If workout has no exercises, delete it instead of completing
      if (_currentWorkout!.exercises.isEmpty) {
        await WorkoutService.deleteWorkout(_currentWorkout!);
      } else {
        await WorkoutService.completeWorkout(_currentWorkout!);
      }
    }
    
    // Clear the workout store
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
    
    // Clear reps and weight, keep exercise name
    _repsController.clear();
    _weightController.clear();
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
      // Focus on reps field after selection
      _repsFocusNode.requestFocus();
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
    // Stop recording if in progress
    if (_isRecording) {
      try {
        await _audioRecorder.stop();
      } catch (e) {
        // Ignore errors when stopping
      }
    }
    
    // Stop audio playback if playing
    try {
      await _audioPlayer.stop();
    } catch (e) {
      // Ignore errors when stopping
    }
    
    // Reset states
    if (mounted) {
      setState(() {
        _isRecording = false;
        _isProcessing = false;
        _isPlaying = false;
        _isInitializing = false;
        _statusText = 'Tap to speak';
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
        // Stop all audio and recording before switching tabs
        await _stopAllAudioAndRecording();
        
        setState(() {
          _selectedTab = index;
        });
        // Dismiss keyboard when switching tabs
        FocusScope.of(context).unfocus();
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
          
          // Hero sphere
          GestureDetector(
            onTap: _handleTap,
            child: Hero(
              tag: 'workout_sphere',
              child: PulsingParticleSphere(
                size: 240,
                primaryColor: _isRecording 
                    ? AppColors.recordingPrimary
                    : AppColors.primary,
                secondaryColor: _isRecording
                    ? AppColors.recordingSecondary
                    : AppColors.primaryLight,
                accentColor: _isRecording
                    ? AppColors.recordingAccent
                    : AppColors.primaryDark,
                highlightColor: _isRecording
                    ? AppColors.recordingHighlight
                    : AppColors.primary,
              ),
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Rest timer module (appears below sphere)
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
          
          // Workout results (appears below sphere with fade)
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
            _isRecording 
                ? 'Tap when finished'
                : _isProcessing || _isPlaying || _isInitializing
                    ? ''
                    : 'Speak your sets',
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

