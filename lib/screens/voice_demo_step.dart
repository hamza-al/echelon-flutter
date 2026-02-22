import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../styles.dart';
import '../widgets/pulsing_particle_sphere.dart';
import '../components/workout_results_display.dart';
import '../services/auth_service.dart';

class VoiceDemoStep extends StatefulWidget {
  final VoidCallback onComplete;

  const VoiceDemoStep({
    super.key,
    required this.onComplete,
  });

  @override
  State<VoiceDemoStep> createState() => _VoiceDemoStepState();
}

class _VoiceDemoStepState extends State<VoiceDemoStep> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  bool _isRecording = false;
  bool _isProcessing = false;
  bool _isPlaying = false;
  bool _hasCompletedDemo = false;
  bool _showResults = false;
  bool _hideSphere = false; // New flag to control sphere visibility
  List<Map<String, dynamic>> _loggedSets = [];
  String _statusText = 'Try saying:';
  String _instructionText = '"Log 3 sets of 8 bench presses at 225 pounds"';

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    if (await _audioRecorder.hasPermission()) {
      // Permission granted
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final tempDir = Directory.systemTemp;
        final tempPath = '${tempDir.path}/voice_demo.m4a';
        
        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: tempPath,
        );
        
        setState(() {
          _isRecording = true;
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
      });

      if (path != null) {
        await _sendToAPI(path);
      }
    } catch (e) {
      setState(() {
        _isRecording = false;
        _isProcessing = false;
      });
    }
  }

  Future<void> _sendToAPI(String audioPath) async {
    try {
      final authService = context.read<AuthService>();
      final token = authService.token;
      
      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://echelon-fastapi.fly.dev/chat/voice_onboarding'),
      );
      
      // Add auth header
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
      
      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        
        // Get the base64 audio (same parsing as active_workout_screen)
        final base64Audio = body['audio']['base64'] as String;
        
        // Check if follow_up_needed is false
        final followUpNeeded = body['follow_up_needed'] as bool? ?? true;
        
        // Store the logged sets (same parsing as active_workout_screen)
        final commands = body['commands'] as List<dynamic>;
        _loggedSets = commands
            .where((cmd) => cmd['type'] == 'log_set')
            .map((cmd) => cmd['payload'] as Map<String, dynamic>)
            .toList();
        
        // Decode and play the audio
        await _playResponseAudio(base64Audio);
        
        // After audio finishes, show results with fade
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _showResults = true;
              _hasCompletedDemo = true;
              _hideSphere = !followUpNeeded; // Hide sphere if no follow up needed
            });
          }
        });
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _playResponseAudio(String base64Audio) async {
    try {
      // Decode base64 to bytes
      final audioBytes = base64Decode(base64Audio);
      
      // Save to temp file
      final tempDir = Directory.systemTemp;
      final tempPath = '${tempDir.path}/response_audio.mp3';
      final tempFile = File(tempPath);
      await tempFile.writeAsBytes(audioBytes);
      
      setState(() {
        _isProcessing = false;
        _isPlaying = true;
      });
      
      // Play the audio
      await _audioPlayer.play(DeviceFileSource(tempPath));
      
      // Listen for completion
      _audioPlayer.onPlayerComplete.listen((_) {
        if (mounted) {
          setState(() {
            _isPlaying = false;
          });
        }
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _isPlaying = false;
      });
    }
  }

  void _handleTap() {
    if (_isRecording) {
      _stopRecording();
    } else if (!_isProcessing && !_isPlaying) {
      _startRecording();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              // Title
              Text(
                'Try it yourself',
                style: AppStyles.mainHeader().copyWith(
                  fontSize: 32,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'Log your workouts hands-free',
                style: AppStyles.questionSubtext().copyWith(
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),
              
              Expanded(
                child: Column(
                  children: [
                    // Recording view (sphere and instructions)
                    if (!_hideSphere)
                      Expanded(
                        child: _buildRecordingView(screenHeight),
                      ),
                    
                    // Completion message when sphere is hidden
                    if (_hideSphere)
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 60,
                                color: AppColors.primary,
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Perfect.',
                                style: AppStyles.mainHeader().copyWith(
                                  fontSize: 32,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'That\'s how it works. Unlock all features like the automatic timer in the next step!',
                                style: AppStyles.questionSubtext().copyWith(
                                  fontSize: 15,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    // Results view (displayed below sphere or completion message)
                    if (_showResults && _loggedSets.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: _buildResultsView(),
                      ),
                  ],
                ),
              ),
              
              // Continue button (visible after demo)
              if (_hasCompletedDemo)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: widget.onComplete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.background,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Continue',
                      style: AppStyles.mainText().copyWith(
                        color: AppColors.background,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingView(double screenHeight) {
    return Column(
      key: const ValueKey('recording'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Status text with fixed height
        SizedBox(
          height: 20,
          child: Text(
            _statusText,
            style: AppStyles.questionSubtext().copyWith(
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Instruction text with fixed height
        SizedBox(
          height: 60,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              _instructionText,
              style: AppStyles.mainText().copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.accent.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
            ),
          ),
        ),
        
        SizedBox(height: screenHeight * 0.05),
        
        // Sphere with tap gesture
        GestureDetector(
          onTap: _handleTap,
          child: PulsingParticleSphere(
            size: 180,
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
        
        SizedBox(height: screenHeight * 0.05),
        
        // Hint text with fixed height
        SizedBox(
          height: 40,
          child: Center(
            child: !_isRecording && !_isProcessing && !_isPlaying
                ? Text(
                    'Tap the sphere to start',
                    style: AppStyles.questionSubtext().copyWith(
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  )
                : _isRecording
                    ? Text(
                        'Tap again when finished',
                        style: AppStyles.questionSubtext().copyWith(
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      )
                    : (_isProcessing || _isPlaying)
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primaryLight,
                            ),
                          )
                        : const SizedBox(),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsView() {
    return WorkoutResultsDisplay(
      loggedSets: _loggedSets,
    );
  }
}

