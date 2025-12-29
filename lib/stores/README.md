# Stores (State Management)

This folder contains **Provider-based state stores** for managing short-term, reactive state across the app — similar to Pinia stores in Vue 3.

## Why Provider Stores?

- **Reactive**: UI updates automatically when state changes
- **Scoped**: State is cleared when needed (e.g., when workout ends)
- **Accessible**: Can be accessed from any widget in the tree
- **Lightweight**: No persistence overhead like Hive

---

## ActiveWorkoutStore

Manages the state of an ongoing workout session, including conversation history.

### Purpose
Store user transcripts and agent responses during an active workout. This conversation history can later be sent to the backend for context.

### Usage

```dart
// Get the store
final workoutStore = context.read<ActiveWorkoutStore>();

// Or watch for changes (rebuilds on updates)
final workoutStore = context.watch<ActiveWorkoutStore>();

// Start a workout
workoutStore.startWorkout(workoutId);

// Add a message
workoutStore.addMessage(
  userTranscript: "Log 3 sets of 8 bench presses at 225 pounds",
  agentResponse: "Great job! I've logged those sets.",
);

// Access conversation
final messages = workoutStore.conversation;
final messageCount = workoutStore.messageCount;

// Get history for API
final history = workoutStore.getConversationHistory();
// Returns: [{"user_transcript": "...", "agent_response": "...", "timestamp": "..."}]

// End workout (clears all state)
workoutStore.endWorkout();
```

### Auto-cleared on workout end
When `endWorkout()` is called, all conversation history is wiped. This keeps memory clean and ensures each workout starts fresh.

---

## CoachChatStore

Manages the coach chat conversation history.

### Purpose
Store chat messages between user and AI coach. Unlike workout conversations, this persists during the app session.

### Usage

```dart
// Get the store
final chatStore = context.read<CoachChatStore>();

// Add messages
chatStore.addUserMessage("How do I improve my bench press?");
chatStore.addAgentMessage("Here are 3 key tips...");

// Set loading state
chatStore.setLoading(true);
// ... make API call ...
chatStore.setLoading(false);

// Access messages
final messages = chatStore.messages;
final isLoading = chatStore.isLoading;

// Get history for API
final history = chatStore.getChatHistory();
// Returns: [{"text": "...", "is_user": true, "timestamp": "..."}]

// Clear chat
chatStore.clearMessages();
```

### Message Structure
Each message has:
- `text`: The message content
- `isUser`: Whether it's from the user (true) or agent (false)
- `timestamp`: When the message was sent

---

## When to Use Stores vs Hive

### Use Stores (ActiveWorkoutStore, CoachChatStore) for:
- ✅ Temporary, session-based data
- ✅ Real-time UI updates
- ✅ Data that should be cleared on logout/reset
- ✅ Conversation history during active sessions

### Use Hive (UserService, WorkoutService) for:
- ✅ Long-term persistence (user profile, completed workouts)
- ✅ Data that survives app restarts
- ✅ Historical records and analytics
- ✅ Settings and preferences

---

## Example: Sending Conversation to Backend

```dart
// In ActiveWorkoutScreen
Future<void> _sendConversationContext() async {
  final workoutStore = context.read<ActiveWorkoutStore>();
  final conversationHistory = workoutStore.getConversationHistory();
  
  final response = await http.post(
    Uri.parse('https://echelon-fastapi.fly.dev/chat/voice'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'audio': audioData,
      'conversation_history': conversationHistory,
    }),
  );
}
```

---

## Architecture Summary

```
┌─────────────────────────────────────┐
│         UI Layer (Widgets)          │
│  context.read/watch<Store>()        │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│    Stores (Provider - Reactive)     │
│  • ActiveWorkoutStore               │
│  • CoachChatStore                   │
│  (Short-term, cleared on session)   │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│    Services (Hive - Persistent)     │
│  • UserService                      │
│  • WorkoutService                   │
│  (Long-term, survives restarts)     │
└─────────────────────────────────────┘
```

