import 'dart:async';
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
enum _BubbleRole { coach, user }

class _ChatBubble {
  final _BubbleRole role;
  final String? text;
  final Widget? widget;
  _ChatBubble.text(this.role, this.text) : widget = null;
  _ChatBubble.widget(this.role, this.widget) : text = null;
}

class FeatureDemoScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const FeatureDemoScreen({super.key, required this.onComplete});

  @override
  State<FeatureDemoScreen> createState() => _FeatureDemoScreenState();
}

class _FeatureDemoScreenState extends State<FeatureDemoScreen>
    with TickerProviderStateMixin {
  final TextEditingController _foodController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AudioRecorder _audioRecorder = AudioRecorder();

  _DemoPhase _phase = _DemoPhase.mealInput;
  List<Map<String, dynamic>> _loggedSets = [];

  final List<_ChatBubble> _messages = [];
  bool _isTyping = false;
  String _typedSoFar = '';
  Timer? _typeTimer;
  bool _inputReady = false;

  static const double _coachFontSize = 17.0;

  @override
  void initState() {
    super.initState();
    _audioRecorder.hasPermission();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      _typeCoachMessage(
        'Now, on to the features.',
        onDone: () {
          if (!mounted) return;
          _typeCoachMessage(
            'Let\'s try logging your first meal.',
            onDone: () {
              if (!mounted) return;
              _typeCoachMessage(
                'Type anything — "2 eggs and toast", "a protein shake"...',
                unlockInput: true,
              );
            },
          );
        },
      );
    });
  }

  @override
  void dispose() {
    _typeTimer?.cancel();
    _foodController.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _typeCoachMessage(
    String text, {
    VoidCallback? onDone,
    bool unlockInput = false,
  }) {
    setState(() {
      _isTyping = true;
      _inputReady = false;
      _typedSoFar = '';
    });

    int charIndex = 0;
    _typeTimer?.cancel();
    _typeTimer = Timer.periodic(const Duration(milliseconds: 28), (timer) {
      if (!mounted) { timer.cancel(); return; }
      if (charIndex < text.length) {
        charIndex++;
        setState(() => _typedSoFar = text.substring(0, charIndex));
        _scrollToBottom();
      } else {
        timer.cancel();
        setState(() {
          _isTyping = false;
          _messages.add(_ChatBubble.text(_BubbleRole.coach, text));
          _typedSoFar = '';
          if (unlockInput) _inputReady = true;
        });
        _scrollToBottom();
        onDone?.call();
      }
    });
  }

  void _addCoachBubbleWithWidget(Widget widget) {
    setState(() {
      _messages.add(_ChatBubble.widget(_BubbleRole.coach, widget));
    });
    _scrollToBottom();
  }

  Future<void> _submitFood() async {
    final text = _foodController.text.trim();
    if (text.isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _messages.add(_ChatBubble.text(_BubbleRole.user, text));
      _inputReady = false;
      _phase = _DemoPhase.mealLoading;
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      final authService = context.read<AuthService>();
      final api = CaloriesApiService(authService);
      final result = await api.getCalories(quantity: '1', foodItem: text);
      if (mounted) {
        setState(() {
          _isTyping = false;
          _phase = _DemoPhase.mealResult;
        });
        _addCoachBubbleWithWidget(_buildNutritionCard(result));
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) {
          _typeCoachMessage(
            'Nice — ${result.calories.round()} calories, ${result.macros.protein.round()}g protein. That\'s all it takes.',
            onDone: () {
              if (!mounted) return;
              _typeCoachMessage(
                'Now let\'s try logging a set with your voice.',
                onDone: () {
                  if (!mounted) return;
                  _addVoiceExampleHint();
                  setState(() {
                    _phase = _DemoPhase.voiceIdle;
                  });
                  _scrollToBottom();
                },
              );
            },
          );
        }
      }
    } catch (_) {
      if (mounted) {
        final result = CaloriesResponse(
          itemName: text.toUpperCase(),
          calories: 350,
          macros: Macros(protein: 25, carbs: 30, fats: 15),
        );
        setState(() {
          _isTyping = false;
          _phase = _DemoPhase.mealResult;
        });
        _addCoachBubbleWithWidget(_buildNutritionCard(result));
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) {
          _typeCoachMessage(
            'Nice — ${result.calories.round()} calories, ${result.macros.protein.round()}g protein. That\'s all it takes.',
            onDone: () {
              if (!mounted) return;
              _typeCoachMessage(
                'Now let\'s try logging a set with your voice.',
                onDone: () {
                  if (!mounted) return;
                  _addVoiceExampleHint();
                  setState(() {
                    _phase = _DemoPhase.voiceIdle;
                  });
                  _scrollToBottom();
                },
              );
            },
          );
        }
      }
    }
  }

  void _addVoiceExampleHint() {
    setState(() {
      _messages.add(
        _ChatBubble.widget(
          _BubbleRole.coach,
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: Text(
              '"3 sets of 10 bench press at 185 pounds"',
              textAlign: TextAlign.center,
              style: AppStyles.mainText().copyWith(
                fontSize: 14,
                height: 1.4,
                color: AppColors.primaryLight.withValues(alpha: 0.55),
              ),
            ),
          ),
        ),
      );
    });
    _scrollToBottom();
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
      setState(() {
        _phase = _DemoPhase.voiceProcessing;
        _isTyping = true;
      });
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
      } else {
        throw Exception('API Error');
      }
    } catch (_) {
      _loggedSets = [
        {'exercise': 'bench_press', 'sets': 3, 'reps': 10, 'weight': 185},
      ];
    }

    if (mounted) {
      setState(() => _isTyping = false);
      if (_loggedSets.isNotEmpty) {
        _addCoachBubbleWithWidget(
          WorkoutResultsDisplay(loggedSets: _loggedSets),
        );
      }
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) {
        _typeCoachMessage("Perfect. You're all set.", onDone: () {
          setState(() => _phase = _DemoPhase.done);
        });
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
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 48, 20, 8),
                  itemCount: _messages.length
                      + (_isTyping ? 1 : 0)
                      + (_phase.index >= _DemoPhase.voiceIdle.index && _phase != _DemoPhase.done ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index < _messages.length) {
                      return _buildBubble(_messages[index]);
                    }

                    final afterMessages = index - _messages.length;

                    if (_isTyping && afterMessages == 0) {
                      return _typedSoFar.isEmpty
                          ? _buildBouncingDots()
                          : _buildTypingBubble();
                    }

                    if (_phase.index >= _DemoPhase.voiceIdle.index && _phase != _DemoPhase.done) {
                      return _buildVoiceSphere();
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),

            if (_phase == _DemoPhase.mealInput && _inputReady)
              Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPad + 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.overlay.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.overlay.withValues(alpha: 0.06),
                            width: 0.5,
                          ),
                        ),
                        child: TextField(
                          controller: _foodController,
                          style: AppStyles.mainText().copyWith(fontSize: 15),
                          decoration: InputDecoration(
                            hintText: 'e.g. 2 eggs and toast',
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
                          color: AppColors.overlay.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.overlay.withValues(alpha: 0.06),
                            width: 0.5,
                          ),
                        ),
                        child: Icon(
                          Icons.arrow_upward_rounded,
                          color: AppColors.overlay.withValues(alpha: 0.6),
                          size: 18,
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

  Widget _buildBubble(_ChatBubble item) {
    final isCoach = item.role == _BubbleRole.coach;

    if (isCoach && item.widget != null) {
      final contentWidth = MediaQuery.sizeOf(context).width - 40;
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: SizedBox(
          width: contentWidth,
          child: item.widget,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: isCoach ? Alignment.centerLeft : Alignment.centerRight,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isCoach
                ? Colors.transparent
                : AppColors.overlay.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: isCoach
                ? null
                : Border.all(
                    color: AppColors.overlay.withValues(alpha: 0.08),
                    width: 0.5,
                  ),
          ),
          child: Text(
            item.text!,
            style: AppStyles.mainText().copyWith(
              fontSize: isCoach ? _coachFontSize : 15,
              fontWeight: FontWeight.w500,
              color: isCoach
                  ? AppColors.overlay.withValues(alpha: 0.48)
                  : AppColors.textPrimary,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          child: Text(
            _typedSoFar,
            style: AppStyles.mainText().copyWith(
              fontSize: _coachFontSize,
              fontWeight: FontWeight.w500,
              color: AppColors.overlay.withValues(alpha: 0.48),
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBouncingDots() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: _BouncingDots(),
      ),
    );
  }

  Widget _buildVoiceSphere() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Center(
            child: GestureDetector(
              onTap: _handleSphereTap,
              child: PulsingParticleSphere(
                size: 160,
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
          const SizedBox(height: 12),
          Text(
            _phase == _DemoPhase.voiceRecording
                ? 'Tap again when finished'
                : 'Tap to start',
            style: AppStyles.mainText().copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.overlay.withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionCard(CaloriesResponse result) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.overlay.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.overlay.withValues(alpha: 0.06),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            result.itemName.toUpperCase(),
            textAlign: TextAlign.center,
            style: AppStyles.mainText().copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
              color: AppColors.overlay.withValues(alpha: 0.25),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${result.calories.round()}',
                style: AppStyles.mainText().copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: AppColors.overlay.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'cal',
                style: AppStyles.mainText().copyWith(
                  fontSize: 14,
                  color: AppColors.overlay.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
              textAlign: TextAlign.center,
              style: AppStyles.mainText().copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.overlay.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
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

class _BouncingDots extends StatefulWidget {
  @override
  State<_BouncingDots> createState() => _BouncingDotsState();
}

class _BouncingDotsState extends State<_BouncingDots>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (i) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      );
    });
    _animations = _controllers.map((c) {
      return Tween<double>(begin: 0, end: -6).animate(
        CurvedAnimation(parent: c, curve: Curves.easeInOut),
      );
    }).toList();

    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 160), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _animations[i],
            builder: (context, _) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                child: Transform.translate(
                  offset: Offset(0, _animations[i].value),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.overlay.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
