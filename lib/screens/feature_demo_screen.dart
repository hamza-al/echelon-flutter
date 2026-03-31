import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../styles.dart';
import '../widgets/pulsing_particle_sphere.dart';
import '../components/workout_results_display.dart';
import '../services/calories_api_service.dart';
import '../services/auth_service.dart';

enum _DemoPhase { mealInput, mealLoading, mealResult, voiceIdle, voiceRecording, voiceProcessing, done }

class FeatureDemoScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const FeatureDemoScreen({super.key, required this.onComplete});

  @override
  State<FeatureDemoScreen> createState() => _FeatureDemoScreenState();
}

class _FeatureDemoScreenState extends State<FeatureDemoScreen> {
  final TextEditingController _foodController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AudioRecorder _audioRecorder = AudioRecorder();

  _DemoPhase _phase = _DemoPhase.mealInput;
  CaloriesResponse? _caloriesResult;
  List<Map<String, dynamic>> _loggedSets = [];

  @override
  void initState() {
    super.initState();
    _audioRecorder.hasPermission();
  }

  @override
  void dispose() {
    _foodController.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _submitFood() async {
    final text = _foodController.text.trim();
    if (text.isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() => _phase = _DemoPhase.mealLoading);
    _scrollToBottom();

    try {
      final authService = context.read<AuthService>();
      final api = CaloriesApiService(authService);
      final result = await api.getCalories(quantity: '1', foodItem: text);
      if (mounted) {
        setState(() {
          _caloriesResult = result;
          _phase = _DemoPhase.mealResult;
        });
        _scrollToBottom();
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          setState(() => _phase = _DemoPhase.voiceIdle);
          _scrollToBottom();
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _caloriesResult = CaloriesResponse(
            itemName: text.toUpperCase(),
            calories: 350,
            macros: Macros(protein: 25, carbs: 30, fats: 15),
          );
          _phase = _DemoPhase.mealResult;
        });
        _scrollToBottom();
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          setState(() => _phase = _DemoPhase.voiceIdle);
          _scrollToBottom();
        }
      }
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final tempDir = Directory.systemTemp;
        final tempPath = '${tempDir.path}/feature_demo.m4a';
        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: tempPath,
        );
        setState(() => _phase = _DemoPhase.voiceRecording);
      }
    } catch (_) {}
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() => _phase = _DemoPhase.voiceProcessing);
      _scrollToBottom();

      if (path != null) {
        await _sendVoice(path);
      }
    } catch (_) {
      if (mounted) setState(() => _phase = _DemoPhase.voiceIdle);
    }
  }

  Future<void> _sendVoice(String audioPath) async {
    try {
      final authService = context.read<AuthService>();
      final token = authService.token;

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://echelon-fastapi.fly.dev/chat/voice_onboarding'),
      );
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.files.add(await http.MultipartFile.fromPath('audio', audioPath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final commands = body['commands'] as List<dynamic>;
        _loggedSets = commands
            .where((cmd) => cmd['type'] == 'log_set')
            .map((cmd) => cmd['payload'] as Map<String, dynamic>)
            .toList();

        if (mounted) {
          setState(() => _phase = _DemoPhase.done);
          _scrollToBottom();
        }
      } else {
        throw Exception('API Error');
      }
    } catch (_) {
      if (mounted) {
        _loggedSets = [
          {'exercise': 'bench_press', 'sets': 3, 'reps': 10, 'weight': 185},
        ];
        setState(() => _phase = _DemoPhase.done);
        _scrollToBottom();
      }
    }
  }

  void _handleSphereTap() {
    if (_phase == _DemoPhase.voiceRecording) {
      _stopRecording();
    } else if (_phase == _DemoPhase.voiceIdle) {
      _startRecording();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
                  children: [
                    Text(
                      'Now, on to the features.',
                      style: AppStyles.mainText().copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        color: AppColors.overlay.withValues(alpha: 0.9),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Let\'s try logging your first meal.',
                      style: AppStyles.mainText().copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        color: AppColors.overlay.withValues(alpha: 0.9),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Type anything — "2 eggs and toast", "a protein shake"...',
                      style: AppStyles.mainText().copyWith(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: AppColors.overlay.withValues(alpha: 0.25),
                        height: 1.4,
                      ),
                    ),

                    if (_foodController.text.isNotEmpty &&
                        _phase != _DemoPhase.mealInput) ...[
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.overlay.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.overlay.withValues(alpha: 0.10),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            _foodController.text,
                            style: AppStyles.mainText().copyWith(
                              fontSize: 15,
                              color: AppColors.overlay.withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                      ),
                    ],

                    if (_phase == _DemoPhase.mealLoading) ...[
                      const SizedBox(height: 24),
                       Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primaryLight,
                          ),
                        ),
                      ),
                    ],

                    if (_caloriesResult != null &&
                        _phase.index >= _DemoPhase.mealResult.index) ...[
                      const SizedBox(height: 20),
                      _buildNutritionCard(_caloriesResult!),
                      const SizedBox(height: 24),
                      Text(
                        'Nice — ${_caloriesResult!.calories.round()} calories, '
                        '${_caloriesResult!.macros.protein.round()}g protein. '
                        'That\'s all it takes.',
                        style: AppStyles.mainText().copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          color: AppColors.overlay.withValues(alpha: 0.9),
                          height: 1.3,
                        ),
                      ),
                    ],

                    if (_phase.index >= _DemoPhase.voiceIdle.index) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Now let\'s try logging a set with your voice.',
                        style: AppStyles.mainText().copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          color: AppColors.overlay.withValues(alpha: 0.9),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try saying "3 sets of 10 bench press at 185 pounds"',
                        style: AppStyles.mainText().copyWith(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: AppColors.primaryLight.withValues(alpha: 0.45),
                          height: 1.4,
                        ),
                      ),
                    ],

                    if (_phase.index >= _DemoPhase.voiceIdle.index &&
                        _phase != _DemoPhase.done) ...[
                      const SizedBox(height: 32),
                      Center(
                        child: GestureDetector(
                          onTap: _handleSphereTap,
                          child: PulsingParticleSphere(
                            size: 180,
                            primaryColor: _phase == _DemoPhase.voiceRecording
                                ? AppColors.recordingPrimary
                                : AppColors.primary,
                            secondaryColor: _phase == _DemoPhase.voiceRecording
                                ? AppColors.recordingSecondary
                                : AppColors.primaryLight,
                            accentColor: _phase == _DemoPhase.voiceRecording
                                ? AppColors.recordingAccent
                                : AppColors.primaryDark,
                            highlightColor: _phase == _DemoPhase.voiceRecording
                                ? AppColors.recordingHighlight
                                : AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          _phase == _DemoPhase.voiceProcessing
                              ? 'Processing...'
                              : _phase == _DemoPhase.voiceRecording
                                  ? 'Tap again when finished'
                                  : 'Tap the sphere to start',
                          style: AppStyles.mainText().copyWith(
                            fontSize: 13,
                            color: AppColors.overlay.withValues(alpha: 0.25),
                          ),
                        ),
                      ),
                    ],

                    if (_phase == _DemoPhase.voiceProcessing) ...[
                      const SizedBox(height: 16),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          PulsingParticleSphere(size: 40),
                        ],
                      ),
                    ],

                    if (_phase == _DemoPhase.done && _loggedSets.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      WorkoutResultsDisplay(loggedSets: _loggedSets),
                    ],

                    if (_phase == _DemoPhase.done) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Perfect. You\'re all set.',
                        style: AppStyles.mainText().copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          color: AppColors.overlay.withValues(alpha: 0.9),
                          height: 1.3,
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            if (_phase == _DemoPhase.mealInput)
              Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPad + 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF111111),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppColors.overlay.withValues(alpha: 0.08),
                            width: 0.5,
                          ),
                        ),
                        child: TextField(
                          controller: _foodController,
                          style: AppStyles.mainText().copyWith(fontSize: 15),
                          decoration: InputDecoration(
                            hintText: 'e.g. chicken breast and rice',
                            hintStyle: AppStyles.mainText().copyWith(
                              fontSize: 15,
                              color: AppColors.overlay.withValues(alpha: 0.2),
                            ),
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                          textCapitalization: TextCapitalization.sentences,
                          onSubmitted: (_) => _submitFood(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _submitFood,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.overlay.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.arrow_upward_rounded,
                          color: AppColors.overlay.withValues(alpha: 0.8),
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (_phase == _DemoPhase.done)
              Padding(
                padding: EdgeInsets.fromLTRB(24, 0, 24, bottomPad + 24),
                child: GestureDetector(
                  onTap: widget.onComplete,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.overlay.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.overlay.withValues(alpha: 0.08),
                        width: 0.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Continue',
                        style: AppStyles.mainText().copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.overlay.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionCard(CaloriesResponse result) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.overlay.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.overlay.withValues(alpha: 0.06),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            result.itemName.toUpperCase(),
            style: AppStyles.mainText().copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
              color: AppColors.overlay.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${result.calories.round()}',
                style: AppStyles.mainText().copyWith(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppColors.overlay.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'cal',
                style: AppStyles.mainText().copyWith(
                  fontSize: 14,
                  color: AppColors.overlay.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _macroChip('${result.macros.protein.round()}g', 'Protein'),
              const SizedBox(width: 8),
              _macroChip('${result.macros.carbs.round()}g', 'Carbs'),
              const SizedBox(width: 8),
              _macroChip('${result.macros.fats.round()}g', 'Fats'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _macroChip(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.overlay.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: AppStyles.mainText().copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.overlay.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppStyles.mainText().copyWith(
                fontSize: 11,
                color: AppColors.overlay.withValues(alpha: 0.25),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
