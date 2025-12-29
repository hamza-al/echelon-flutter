import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../styles.dart';
import '../stores/coach_chat_store.dart';
import '../stores/nutrition_store.dart';
import '../services/coach_chat_service.dart';
import '../services/auth_service.dart';
import '../widgets/pulsing_particle_sphere.dart';
import '../widgets/typewriter_markdown.dart';

class CoachChatScreen extends StatefulWidget {
  final VoidCallback? onNavigateBack;
  
  const CoachChatScreen({super.key, this.onNavigateBack});

  @override
  State<CoachChatScreen> createState() => _CoachChatScreenState();
}

class _CoachChatScreenState extends State<CoachChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

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

    // Send message using the service
    await CoachChatService.sendMessageWithStore(
      service: coachService,
      userMessage: message,
      store: store,
      nutritionStore: nutritionStore,
    );

    // Scroll to bottom after sending
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
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.chevron_left,
                      color: AppColors.accent,
                      size: 28,
                    ),
                    onPressed: widget.onNavigateBack,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Coach',
                          style: AppStyles.mainHeader().copyWith(
                            fontSize: 30,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your AI fitness coach',
                          style: AppStyles.questionSubtext(),
                        ),
                      ],
                    ),
                  ),
                  // Clear chat button
                  Consumer<CoachChatStore>(
                    builder: (context, store, _) {
                      if (!store.hasMessages) return const SizedBox.shrink();
                      
                      return IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: AppColors.accent.withOpacity(0.5),
                        ),
                        onPressed: () {
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
                                      color: AppColors.accent.withOpacity(0.6),
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
                                      color: AppColors.primaryLight,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),

            // Messages List
            Expanded(
              child: Consumer<CoachChatStore>(
                builder: (context, store, _) {
                  if (store.messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: AppColors.accent.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Start a conversation',
                            style: AppStyles.mainText().copyWith(
                              color: AppColors.accent.withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 48),
                            child: Text(
                              'Ask about workouts, nutrition, or get personalized advice',
                              style: AppStyles.questionSubtext().copyWith(
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
                    itemCount: store.messages.length + (store.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Show loading indicator at the top
                      if (index == 0 && store.isLoading) {
                        return _buildLoadingBubble();
                      }
                      
                      final messageIndex = store.isLoading ? index - 1 : index;
                      final message = store.messages.reversed.toList()[messageIndex];
                      final isLatestAssistantMessage = 
                          !message.isUser && messageIndex == 0 && !store.isLoading;
                      return _buildMessageBubble(message, isLatestAssistantMessage);
                    },
                  );
                },
              ),
            ),

            // Error message
            Consumer<CoachChatStore>(
              builder: (context, store, _) {
                if (store.error == null) return const SizedBox.shrink();
                
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red.shade300,
                        size: 20,
                      ),
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
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: Colors.red.shade300,
                          size: 18,
                        ),
                        onPressed: () => store.clearError(),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Input Area
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border(
                  top: BorderSide(
                    color: AppColors.accent.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Consumer<CoachChatStore>(
                builder: (context, store, _) {
                  return Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          style: AppStyles.mainText().copyWith(fontSize: 15),
                          decoration: InputDecoration(
                            hintText: 'Ask your coach...',
                            hintStyle: AppStyles.questionSubtext().copyWith(
                              fontSize: 15,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(
                                color: AppColors.primary.withOpacity(0.3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(
                                color: AppColors.primary.withOpacity(0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(
                                color: AppColors.primaryLight,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            filled: true,
                            fillColor: AppColors.primary.withOpacity(0.05),
                          ),
                          maxLines: 5,
                          minLines: 1,
                          textCapitalization: TextCapitalization.sentences,
                          enabled: !store.isLoading,
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: store.isLoading
                              ? AppColors.primaryLight.withOpacity(0.5)
                              : AppColors.primaryLight,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.send,
                            color: AppColors.background,
                            size: 22,
                          ),
                          onPressed: store.isLoading ? null : _sendMessage,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const PulsingParticleSphere(
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

  Widget _buildMessageBubble(ChatMessage message, bool shouldTypewrite) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: message.isUser ? 16 : 0,
                vertical: message.isUser ? 12 : 0,
              ),
              decoration: message.isUser
                  ? BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(16),
                    )
                  : null,
              child: message.isUser
                  ? Text(
                      message.text,
                      style: AppStyles.mainText().copyWith(
                        fontSize: 15,
                        color: AppColors.background,
                      ),
                    )
                  : (shouldTypewrite
                      ? TypewriterMarkdown(
                          data: message.text,
                          styleSheet: MarkdownStyleSheet(
                            p: AppStyles.mainText().copyWith(
                              fontSize: 15,
                              color: AppColors.accent,
                            ),
                            strong: AppStyles.mainText().copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent,
                            ),
                            em: AppStyles.mainText().copyWith(
                              fontSize: 15,
                              fontStyle: FontStyle.italic,
                              color: AppColors.accent,
                            ),
                            code: AppStyles.mainText().copyWith(
                              fontSize: 14,
                              fontFamily: 'monospace',
                              color: AppColors.primaryLight,
                              backgroundColor: AppColors.background,
                            ),
                            listBullet: AppStyles.mainText().copyWith(
                              fontSize: 15,
                              color: AppColors.primaryLight,
                            ),
                          ),
                        )
                      : MarkdownBody(
                          data: message.text,
                          styleSheet: MarkdownStyleSheet(
                            p: AppStyles.mainText().copyWith(
                              fontSize: 15,
                              color: AppColors.accent,
                            ),
                            strong: AppStyles.mainText().copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent,
                            ),
                            em: AppStyles.mainText().copyWith(
                              fontSize: 15,
                              fontStyle: FontStyle.italic,
                              color: AppColors.accent,
                            ),
                            code: AppStyles.mainText().copyWith(
                              fontSize: 14,
                              fontFamily: 'monospace',
                              color: AppColors.primaryLight,
                              backgroundColor: AppColors.background,
                            ),
                            listBullet: AppStyles.mainText().copyWith(
                              fontSize: 15,
                              color: AppColors.primaryLight,
                            ),
                          ),
                        )),
            ),
          ),
          if (message.isUser)
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(left: 12),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                size: 18,
                color: AppColors.accent,
              ),
            ),
        ],
      ),
    );
  }
}

