import 'package:flutter/foundation.dart';

/// Message in the coach chat
class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    String? id,
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp = timestamp ?? DateTime.now();

  /// Convert to JSON for API
  Map<String, dynamic> toJson() => {
        'text': text,
        'is_user': isUser,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// Store for managing coach chat state
/// Similar to Pinia stores - provides reactive state management
class CoachChatStore extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get messageCount => _messages.length;
  bool get hasMessages => _messages.isNotEmpty;

  /// Add a user message
  ChatMessage addUserMessage(String text) {
    final message = ChatMessage(
      text: text,
      isUser: true,
    );
    _messages.add(message);
    _error = null;
    notifyListeners();
    return message;
  }

  /// Add an agent message
  ChatMessage addAgentMessage(String text) {
    final message = ChatMessage(
      text: text,
      isUser: false,
    );
    _messages.add(message);
    notifyListeners();
    return message;
  }

  /// Add both user and agent messages (useful after API call)
  void addExchange({
    required String userText,
    required String agentText,
  }) {
    addUserMessage(userText);
    addAgentMessage(agentText);
  }

  /// Set loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error state
  void setError(String? errorMessage) {
    _error = errorMessage;
    _isLoading = false;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Clear all messages
  void clearMessages() {
    _messages.clear();
    _error = null;
    notifyListeners();
  }

  /// Get the chat history for sending to backend
  /// Returns list of message objects with text, is_user, and timestamp
  List<Map<String, dynamic>> getChatHistory() {
    return _messages.map((msg) => msg.toJson()).toList();
  }

  /// Get only the text conversation (simplified format)
  List<Map<String, String>> getSimpleHistory() {
    return _messages
        .map((msg) => {
              'role': msg.isUser ? 'user' : 'assistant',
              'content': msg.text,
            })
        .toList();
  }

  /// Get last N messages for context window
  List<Map<String, dynamic>> getRecentHistory(int count) {
    final recentMessages = _messages.length > count
        ? _messages.sublist(_messages.length - count)
        : _messages;
    return recentMessages.map((msg) => msg.toJson()).toList();
  }

  /// Remove last message (useful for retry scenarios)
  void removeLastMessage() {
    if (_messages.isNotEmpty) {
      _messages.removeLast();
      notifyListeners();
    }
  }

  /// Update a specific message (useful for streaming responses)
  void updateMessage(String messageId, String newText) {
    final index = _messages.indexWhere((msg) => msg.id == messageId);
    if (index != -1) {
      final oldMessage = _messages[index];
      _messages[index] = ChatMessage(
        id: oldMessage.id,
        text: newText,
        isUser: oldMessage.isUser,
        timestamp: oldMessage.timestamp,
      );
      notifyListeners();
    }
  }
}

