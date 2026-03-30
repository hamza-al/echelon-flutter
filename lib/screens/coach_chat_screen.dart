import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../styles.dart';
import '../stores/coach_chat_store.dart';
import '../stores/nutrition_store.dart';
import '../services/coach_chat_service.dart';
import '../services/auth_service.dart';
import '../widgets/pulsing_particle_sphere.dart';

class CoachChatScreen extends StatefulWidget {
  final VoidCallback? onNavigateBack;
  
  const CoachChatScreen({super.key, this.onNavigateBack});

  @override
  State<CoachChatScreen> createState() => _CoachChatScreenState();
}

class _CoachChatScreenState extends State<CoachChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Set<String> _animatedMessageIds = {};

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final message = _messageController.text.trim();
    _messageController.clear();

    final store = context.read<CoachChatStore>();
    final nutritionStore = context.read<NutritionStore>();
    final authService = context.read<AuthService>();
    final coachService = CoachChatService(authService);

    await CoachChatService.sendMessageWithStore(
      service: coachService,
      userMessage: message,
      store: store,
      nutritionStore: nutritionStore,
    );

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Coach',
                        style: AppStyles.mainHeader().copyWith(fontSize: 30),
                      ),
                    ),
                    Consumer<CoachChatStore>(
                      builder: (context, store, _) {
                        if (!store.hasMessages) return const SizedBox.shrink();
                        return GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: AppColors.background,
                                title: Text(
                                  'Clear Chat?',
                                  style: AppStyles.mainText().copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                content: Text(
                                  'This will delete all messages in this conversation.',
                                  style: AppStyles.questionSubtext(),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(
                                      'Cancel',
                                      style: AppStyles.mainText().copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      store.clearMessages();
                                      Navigator.pop(context);
                                    },
                                    child: Text(
                                      'Clear',
                                      style: AppStyles.mainText().copyWith(
                                        color: const Color(0xFFFF6B6B),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: Icon(
                            Icons.delete_outline,
                            color: AppColors.textMuted,
                            size: 22,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              Expanded(
                child: GestureDetector(
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: Consumer<CoachChatStore>(
                    builder: (context, store, _) {
                      if (store.messages.isEmpty) {
                        return Center(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 40),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'What\'s on\nyour mind?',
                                  textAlign: TextAlign.center,
                                  style: AppStyles.mainHeader().copyWith(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w300,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Ask about your training, dial in your nutrition, or just talk through what\'s next.',
                                  textAlign: TextAlign.center,
                                  style: AppStyles.mainText().copyWith(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
                        itemCount:
                            store.messages.length + (store.isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == 0 && store.isLoading) {
                            return _buildLoadingBubble();
                          }
                          final messageIndex =
                              store.isLoading ? index - 1 : index;
                          final message =
                              store.messages.reversed.toList()[messageIndex];
                          final isLatestAssistantMessage = !message.isUser &&
                              messageIndex == 0 &&
                              !store.isLoading;
                          return _buildMessageBubble(
                              message, isLatestAssistantMessage);
                        },
                      );
                    },
                  ),
                ),
              ),

              Consumer<CoachChatStore>(
                builder: (context, store, _) {
                  if (store.error == null) return const SizedBox.shrink();
                  return Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            color: Colors.red.shade300, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            store.error!,
                            style: AppStyles.mainText().copyWith(
                              fontSize: 13,
                              color: Colors.red.shade300,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => store.clearError(),
                          child: Icon(Icons.close,
                              color: Colors.red.shade300, size: 18),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Frosted glass input bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                child: Consumer<CoachChatStore>(
                  builder: (context, store, _) {
                    return CustomPaint(
                      painter: _GlassInputPainter(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                style: AppStyles.mainText()
                                    .copyWith(fontSize: 15),
                                decoration: InputDecoration(
                                  hintText: 'Ask your coach...',
                                  hintStyle: AppStyles.questionSubtext()
                                      .copyWith(fontSize: 15),
                                  border: InputBorder.none,
                                  contentPadding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                ),
                                maxLines: 5,
                                minLines: 1,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                enabled: !store.isLoading,
                                onSubmitted: (_) => _sendMessage(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: store.isLoading ? null : _sendMessage,
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: store.isLoading
                                      ? Colors.white.withValues(alpha: 0.06)
                                      : Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Icon(
                                  Icons.arrow_upward_rounded,
                                  color: store.isLoading
                                      ? Colors.white.withValues(alpha: 0.2)
                                      : Colors.white.withValues(alpha: 0.8),
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: const [
          PulsingParticleSphere(
            size: 40,
            primaryColor: AppColors.primary,
            secondaryColor: AppColors.primaryLight,
            accentColor: AppColors.primaryDark,
            highlightColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  MarkdownStyleSheet get _assistantMarkdownStyle => MarkdownStyleSheet(
        p: AppStyles.mainText().copyWith(
          fontSize: 15,
          color: AppColors.textPrimary,
        ),
        strong: AppStyles.mainText().copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        em: AppStyles.mainText().copyWith(
          fontSize: 15,
          fontStyle: FontStyle.italic,
          color: AppColors.textPrimary,
        ),
        code: AppStyles.mainText().copyWith(
          fontSize: 14,
          fontFamily: 'monospace',
          color: Colors.white.withValues(alpha: 0.7),
          backgroundColor: Colors.white.withValues(alpha: 0.06),
        ),
        listBullet: AppStyles.mainText().copyWith(
          fontSize: 15,
          color: Colors.white.withValues(alpha: 0.5),
        ),
      );

  Widget _buildMessageBubble(
      ChatMessage message, bool isNewAssistantMessage) {
    final shouldAnimate =
        isNewAssistantMessage && !_animatedMessageIds.contains(message.id);
    if (shouldAnimate) {
      _animatedMessageIds.add(message.id);
    }

    if (message.isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Flexible(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  message.text,
                  style: AppStyles.mainText().copyWith(
                    fontSize: 15,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: shouldAnimate
                ? _FadeIn(
                    key: ValueKey('fade_${message.id}'),
                    child: MarkdownBody(
                      data: message.text,
                      styleSheet: _assistantMarkdownStyle,
                    ),
                  )
                : MarkdownBody(
                    data: message.text,
                    styleSheet: _assistantMarkdownStyle,
                  ),
          ),
        ],
      ),
    );
  }
}

class _GlassInputPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(24));

    final fill = Paint()..color = const Color(0xFF111111);
    canvas.drawRRect(rr, fill);

    final borderPath = Path()..addRRect(rr);
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.15),
          Colors.white.withValues(alpha: 0.15),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.12, 0.88, 1.0],
      ).createShader(rect);

    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FadeIn extends StatefulWidget {
  final Widget child;

  const _FadeIn({super.key, required this.child});

  @override
  State<_FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<_FadeIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _opacity, child: widget.child);
  }
}
