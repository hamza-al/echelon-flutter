import 'dart:async';
import 'package:flutter/material.dart';
import '../styles.dart';
import '../models/onboarding_data.dart';
import '../models/workout_split.dart';
import '../services/user_service.dart';
import '../services/split_service.dart';
import 'onboarding_processing_screen.dart';
import 'voice_demo_step.dart';
import 'paywall_screen.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

enum _ItemRole { coach, user }

class _ChatItem {
  final _ItemRole role;
  final String text;
  _ChatItem(this.role, this.text);
}

class _OnboardingFlowState extends State<OnboardingFlow>
    with TickerProviderStateMixin {
  final OnboardingData _data = OnboardingData();
  String? _selectedSplit;

  final List<_ChatItem> _messages = [];
  final ScrollController _scroll = ScrollController();
  final TextEditingController _textCtrl = TextEditingController();
  final FocusNode _textFocus = FocusNode();

  int _questionIndex = 0;
  bool _isTyping = false;
  bool _inputReady = false;
  String _typedSoFar = '';
  Timer? _typeTimer;

  static const _totalQuestions = 9;

  final List<String> _goals = [
    'Build muscle',
    'Lose fat',
    'Get stronger',
    'Improve form',
    'Stay consistent',
    'Increase endurance',
    'Improve mobility',
    'Athletic performance',
    'General health',
  ];

  final Set<String> _selectedGoals = {};

  String? _selectedNutritionGoal;

  int _heightFeet = 5;
  int _heightInches = 8;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _typeCoachMessage(_questionText(0));
    });
  }

  @override
  void dispose() {
    _typeTimer?.cancel();
    _scroll.dispose();
    _textCtrl.dispose();
    _textFocus.dispose();
    super.dispose();
  }

  String _questionText(int index) {
    switch (index) {
      case 0:
        return "Hey there! What's your name?";
      case 1:
        final name = _data.name ?? '';
        return "Nice to meet you, $name. How are you doing?";
      case 2:
        return "How old are you?";
      case 3:
        return "And your biological sex? Totally fine to skip.";
      case 4:
        return "How tall are you?";
      case 5:
        return "And what do you weigh right now?";
      case 6:
        return "What are you working towards? Pick as many as you want.";
      case 7:
        return "Are you trying to cut, bulk, or maintain?";
      case 8:
        return "Last thing, how do you like to split your training?";
      default:
        return '';
    }
  }

  String _coachReaction(int answeredIndex) {
    switch (answeredIndex) {
      case 0:
        return '';
      case 1:
        return "Good to hear! Let me get to know you a bit.";
      case 2:
        return '';
      case 3:
        return '';
      case 4:
        return '';
      case 5:
        return 'Cool, that helps me dial things in.';
      case 6:
        if (_selectedGoals.length > 2) {
          return "Love it. I'll keep all of that in mind.";
        }
        return 'Solid.';
      case 7:
        final cals = _calculateCalories(_selectedNutritionGoal ?? 'maintain');
        _data.targetCalories = cals;
        _data.nutritionGoal = _selectedNutritionGoal;
        final goalWord = _selectedNutritionGoal ?? 'maintain';
        return 'To $goalWord at your build, you need around $cals calories a day.';
      case 8:
        return "You're all set. Let me put this together.";
      default:
        return '';
    }
  }

  void _typeCoachMessage(String text) {
    setState(() {
      _isTyping = true;
      _inputReady = false;
      _typedSoFar = '';
    });

    int charIndex = 0;
    _typeTimer?.cancel();
    _typeTimer = Timer.periodic(const Duration(milliseconds: 28), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (charIndex < text.length) {
        setState(() {
          charIndex++;
          _typedSoFar = text.substring(0, charIndex);
        });
        _scrollToBottom();
      } else {
        timer.cancel();
        setState(() {
          _isTyping = false;
          _messages.add(_ChatItem(_ItemRole.coach, text));
          _typedSoFar = '';
          _inputReady = true;
        });
        _scrollToBottom();
        _focusInputIfNeeded();
      }
    });
  }

  void _focusInputIfNeeded() {
    if (_questionIndex == 0 ||
        _questionIndex == 1 ||
        _questionIndex == 2 ||
        _questionIndex == 5) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _textFocus.requestFocus();
      });
    }
  }

  int _calculateCalories(String goal) {
    double weightKg = 70;
    double heightCm = 170;
    int age = _data.age ?? 25;
    bool isMale = _data.gender != 'Female';

    final rawWeight = _data.weight ?? '';
    final wMatch = RegExp(r'(\d+)').firstMatch(rawWeight);
    if (wMatch != null) weightKg = int.parse(wMatch.group(1)!) / 2.205;

    final rawHeight = _data.height ?? '';
    final hMatch = RegExp(r"(\d+)'(\d+)").firstMatch(rawHeight);
    if (hMatch != null) {
      final feet = int.parse(hMatch.group(1)!);
      final inches = int.parse(hMatch.group(2)!);
      heightCm = (feet * 12 + inches) * 2.54;
    }

    double bmr = 10 * weightKg + 6.25 * heightCm - 5 * age;
    bmr += isMale ? 5 : -161;

    double tdee = bmr * 1.55;

    switch (goal) {
      case 'cut':
        tdee -= 500;
        break;
      case 'bulk':
        tdee += 300;
        break;
    }

    return (tdee / 50).round() * 50;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _submitAnswer(String displayText) {
    FocusScope.of(context).unfocus();
    final answeredIndex = _questionIndex;

    setState(() {
      _messages.add(_ChatItem(_ItemRole.user, displayText));
      _inputReady = false;
    });
    _scrollToBottom();

    final reaction = _coachReaction(answeredIndex);
    final nextIndex = _questionIndex + 1;

    if (nextIndex > _totalQuestions - 1) {
      // Done — show reaction then navigate
      if (reaction.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) {
            _typeCoachReactionThenComplete(reaction);
          }
        });
      } else {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) _onComplete();
        });
      }
      return;
    }

    setState(() {
      _questionIndex = nextIndex;
    });

    if (reaction.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          _typeCoachReactionThenNext(reaction, nextIndex);
        }
      });
    } else {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _typeCoachMessage(_questionText(nextIndex));
      });
    }
  }

  void _typeCoachReactionThenNext(String reaction, int nextIndex) {
    setState(() {
      _isTyping = true;
      _typedSoFar = '';
    });

    int charIndex = 0;
    _typeTimer?.cancel();
    _typeTimer = Timer.periodic(const Duration(milliseconds: 28), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (charIndex < reaction.length) {
        charIndex++;
        setState(() {
          _typedSoFar = reaction.substring(0, charIndex);
        });
        _scrollToBottom();
      } else {
        timer.cancel();
        setState(() {
          _isTyping = false;
          _messages.add(_ChatItem(_ItemRole.coach, reaction));
          _typedSoFar = '';
        });
        _scrollToBottom();
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) _typeCoachMessage(_questionText(nextIndex));
        });
      }
    });
  }

  void _typeCoachReactionThenComplete(String reaction) {
    setState(() {
      _isTyping = true;
      _typedSoFar = '';
    });

    int charIndex = 0;
    _typeTimer?.cancel();
    _typeTimer = Timer.periodic(const Duration(milliseconds: 28), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (charIndex < reaction.length) {
        charIndex++;
        setState(() {
          _typedSoFar = reaction.substring(0, charIndex);
        });
        _scrollToBottom();
      } else {
        timer.cancel();
        setState(() {
          _isTyping = false;
          _messages.add(_ChatItem(_ItemRole.coach, reaction));
          _typedSoFar = '';
        });
        _scrollToBottom();
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) _onComplete();
        });
      }
    });
  }

  Future<void> _onComplete() async {
    await UserService.updateFromOnboarding(
      name: _data.name,
      age: _data.age,
      gender: _data.gender,
      weight: _data.weight,
      height: _data.height,
      goals: _data.goals,
    );

    if (_data.nutritionGoal != null) {
      await UserService.updateNutritionGoals(
        goal: _data.nutritionGoal!,
        calories: _data.targetCalories,
      );
    }

    if (_selectedSplit != null) {
      final splitObj = WorkoutSplit.getAllSplits()
          .firstWhere((s) => s.splitType == _selectedSplit);
      await SplitService.setSplit(splitObj);
    }

    final splitObj = _selectedSplit != null
        ? WorkoutSplit.getAllSplits()
            .firstWhere((s) => s.splitType == _selectedSplit)
        : WorkoutSplit.pushPullLegs();
    final trainingDays =
        splitObj.dayNames.where((d) => d != 'Rest').length;

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => OnboardingProcessingScreen(
            nutritionGoal: _data.nutritionGoal ?? 'maintain',
            targetCalories: _data.targetCalories,
            splitName: _selectedSplit ?? 'Push/Pull/Legs',
            trainingDays: trainingDays,
            goals: _data.goals,
            onContinue: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => VoiceDemoStep(
                    onComplete: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const PaywallScreen(),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      );
    }
  }

  // --- Build ---

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildProgressBar(),
            Expanded(
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  itemCount: _messages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index < _messages.length) {
                      return _buildChatBubble(_messages[index]);
                    }
                    return _buildTypingBubble();
                  },
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _inputReady && _questionIndex < _totalQuestions
                  ? Container(
                      key: ValueKey('input-$_questionIndex'),
                      padding:
                          EdgeInsets.fromLTRB(20, 12, 20, bottomPad + 16),
                      child: _buildInputForQuestion(_questionIndex),
                    )
                  : SizedBox(
                      key: const ValueKey('empty'),
                      height: bottomPad + 16,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _skip() {
    _typeTimer?.cancel();
    _onComplete();
  }

  Widget _buildProgressBar() {
    final progress = _questionIndex / _totalQuestions;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 3,
                backgroundColor: Colors.white.withValues(alpha: 0.06),
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white.withValues(alpha: 0.25),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          GestureDetector(
            onTap: _skip,
            child: Text(
              'Skip',
              style: AppStyles.mainText().copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Colors.white.withValues(alpha: 0.25),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(_ChatItem item) {
    final isCoach = item.role == _ItemRole.coach;
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
                : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: isCoach
                ? null
                : Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                    width: 0.5,
                  ),
          ),
          child: Text(
            item.text,
            style: AppStyles.mainText().copyWith(
              fontSize: isCoach ? 20 : 16,
              fontWeight: isCoach ? FontWeight.w500 : FontWeight.w500,
              color: isCoach
                  ? Colors.white.withValues(alpha: 0.5)
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
        child: Text(
          _typedSoFar,
          style: AppStyles.mainText().copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.85),
            height: 1.4,
          ),
        ),
      ),
    );
  }

  // --- Input Widgets ---

  Widget _buildInputForQuestion(int index) {
    switch (index) {
      case 0:
        return _buildTextField(
          hint: 'Your name',
          inputType: TextInputType.name,
          onSubmit: (val) {
            if (val.trim().isEmpty) return;
            _data.name = val.trim();
            _textCtrl.clear();
            _submitAnswer(val.trim());
          },
        );
      case 1:
        return _buildTextField(
          hint: 'Type here...',
          inputType: TextInputType.text,
          onSubmit: (val) {
            if (val.trim().isEmpty) return;
            _textCtrl.clear();
            _submitAnswer(val.trim());
          },
        );
      case 2:
        return _buildTextField(
          hint: 'Age',
          inputType: TextInputType.number,
          onSubmit: (val) {
            final age = int.tryParse(val.trim());
            if (age == null || age < 10 || age > 120) return;
            _data.age = age;
            _textCtrl.clear();
            _submitAnswer('$age');
          },
        );
      case 3:
        return _buildGenderPills();
      case 4:
        return _buildHeightPicker();
      case 5:
        return _buildTextField(
          hint: 'Weight in lbs',
          inputType: TextInputType.number,
          onSubmit: (val) {
            final w = int.tryParse(val.trim());
            if (w == null || w < 50 || w > 500) return;
            _data.weight = '$w lbs';
            _textCtrl.clear();
            _submitAnswer('$w lbs');
          },
        );
      case 6:
        return _buildGoalChips();
      case 7:
        return _buildNutritionGoalPicker();
      case 8:
        return _buildSplitPicker();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTextField({
    required String hint,
    required TextInputType inputType,
    required ValueChanged<String> onSubmit,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _textCtrl,
            focusNode: _textFocus,
            keyboardType: inputType,
            textCapitalization: inputType == TextInputType.name
                ? TextCapitalization.words
                : TextCapitalization.none,
            style: AppStyles.mainText().copyWith(fontSize: 16),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppStyles.mainText().copyWith(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.15),
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.04),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.06),
                  width: 0.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.06),
                  width: 0.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 0.5,
                ),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            ),
            onSubmitted: onSubmit,
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => onSubmit(_textCtrl.text),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white.withValues(alpha: 0.6),
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderPills() {
    return Row(
      children: [
        Expanded(child: _pill('Male')),
        const SizedBox(width: 10),
        Expanded(child: _pill('Female')),
        const SizedBox(width: 10),
        Expanded(child: _pill('Skip', muted: true)),
      ],
    );
  }

  Widget _pill(String label, {bool muted = false}) {
    return GestureDetector(
      onTap: () {
        if (label != 'Skip') _data.gender = label;
        _submitAnswer(label);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: muted ? 0.03 : 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 0.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppStyles.mainText().copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white
                  .withValues(alpha: muted ? 0.3 : 0.7),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeightPicker() {
    return StatefulBuilder(
      builder: (context, setLocal) {
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _heightStepper(
                  label: 'ft',
                  value: _heightFeet,
                  min: 4,
                  max: 7,
                  onChanged: (v) => setLocal(() => _heightFeet = v),
                ),
                const SizedBox(width: 24),
                _heightStepper(
                  label: 'in',
                  value: _heightInches,
                  min: 0,
                  max: 11,
                  onChanged: (v) => setLocal(() => _heightInches = v),
                ),
              ],
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () {
                _data.height = "$_heightFeet'$_heightInches\"";
                _submitAnswer("$_heightFeet'$_heightInches\"");
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'Continue',
                    style: AppStyles.mainText().copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _heightStepper({
    required String label,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            if (value < max) onChanged(value + 1);
          },
          child: Container(
            width: 44,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.add_rounded,
                size: 18, color: Colors.white.withValues(alpha: 0.4)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$value',
          style: AppStyles.mainText().copyWith(
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: AppStyles.mainText().copyWith(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.3),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            if (value > min) onChanged(value - 1);
          },
          child: Container(
            width: 44,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.remove_rounded,
                size: 18, color: Colors.white.withValues(alpha: 0.4)),
          ),
        ),
      ],
    );
  }

  Widget _buildGoalChips() {
    return StatefulBuilder(
      builder: (context, setLocal) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _goals.map((goal) {
                final isSelected = _selectedGoals.contains(goal);
                return GestureDetector(
                  onTap: () {
                    setLocal(() {
                      if (isSelected) {
                        _selectedGoals.remove(goal);
                      } else {
                        _selectedGoals.add(goal);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.12)
                          : Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.22)
                            : Colors.white.withValues(alpha: 0.06),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      goal,
                      style: AppStyles.mainText().copyWith(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.85)
                            : Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: _selectedGoals.isEmpty
                  ? null
                  : () {
                      _data.goals = _selectedGoals.toList();
                      _submitAnswer(_selectedGoals.join(', '));
                    },
              child: AnimatedOpacity(
                opacity: _selectedGoals.isEmpty ? 0.3 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'Continue',
                      style: AppStyles.mainText().copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNutritionGoalPicker() {
    final desc = {
      'cut': 'Lose fat, keep muscle',
      'bulk': 'Build muscle, gain size',
      'maintain': 'Stay where you are',
    };
    return Column(
      children: ['cut', 'bulk', 'maintain'].map((goal) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () {
              _selectedNutritionGoal = goal;
              final label = goal[0].toUpperCase() + goal.substring(1);
              _submitAnswer(label);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.06),
                  width: 0.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal[0].toUpperCase() + goal.substring(1),
                    style: AppStyles.mainText().copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc[goal]!,
                    style: AppStyles.mainText().copyWith(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSplitPicker() {
    final splits =
        WorkoutSplit.getAllSplits().where((s) => s.splitType != 'Custom');
    return Column(
      children: splits.map((split) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () {
              _selectedSplit = split.splitType;
              _submitAnswer(split.splitType);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.06),
                  width: 0.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    split.splitType,
                    style: AppStyles.mainText().copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    split.dayNames.where((d) => d != 'Rest').join(' · '),
                    style: AppStyles.mainText().copyWith(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
