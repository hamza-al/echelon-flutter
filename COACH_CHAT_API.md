# Coach Chat API Documentation

## Overview
The Coach Chat feature allows users to have text-based conversations with an AI fitness coach. This is separate from the voice-based workout logging feature. The coach has access to the user's workout history for personalized advice.

## Endpoint

### POST `/chat/coach`

Send a message to the AI coach and receive a text response.

#### Request Format

```json
{
  "message": "What's a good workout routine for building muscle?",
  "conversation_history": [
    {
      "text": "Hi coach!",
      "is_user": true,
      "timestamp": "2025-12-25T10:30:00.000Z"
    },
    {
      "text": "Hello! How can I help you today?",
      "is_user": false,
      "timestamp": "2025-12-25T10:30:01.000Z"
    }
  ],
  "workout_history": [
    {
      "id": "1234567890",
      "date": "2025-12-24T18:30:00.000Z",
      "duration_minutes": 45,
      "exercises": [
        {
          "name": "bench_press",
          "display_name": "Bench Press",
          "type": "weight",
          "sets": 3,
          "total_reps": 24,
          "total_volume": 5400.0,
          "total_duration_seconds": null
        },
        {
          "name": "running",
          "display_name": "Running",
          "type": "duration",
          "sets": 1,
          "total_reps": null,
          "total_volume": null,
          "total_duration_seconds": 1800
        }
      ]
    }
  ]
}
```

#### Request Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `message` | string | Yes | The user's current message |
| `conversation_history` | array | Yes | Array of previous messages (can be empty for first message) |
| `workout_history` | array | No | Array of recent workouts (up to 10 most recent, can be omitted) |

#### Conversation History Object

| Field | Type | Description |
|-------|------|-------------|
| `text` | string | The message content |
| `is_user` | boolean | `true` if sent by user, `false` if sent by assistant |
| `timestamp` | string | ISO 8601 timestamp |

#### Workout History Object

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Workout ID |
| `date` | string | ISO 8601 timestamp of workout start |
| `duration_minutes` | number | Workout duration in minutes |
| `exercises` | array | Array of exercises performed |

#### Exercise Object (in Workout History)

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Exercise name (snake_case) |
| `display_name` | string | Formatted exercise name |
| `type` | string | Exercise type: 'weight' or 'duration' |
| `sets` | number | Number of sets performed |
| `total_reps` | number\|null | Total reps (null for duration-based) |
| `total_volume` | number\|null | Total volume in lbs (null for duration-based) |
| `total_duration_seconds` | number\|null | Total duration in seconds (null for weight-based) |

#### Response Format

```json
{
  "response": "Based on your recent bench press sessions, I can see you've been consistent with 3 sets. For building muscle, I recommend..."
}
```

#### Response Fields

| Field | Type | Description |
|-------|------|-------------|
| `response` | string | The AI coach's response text |

## Example Implementation (Python/FastAPI)

```python
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Optional

app = FastAPI()

class ConversationMessage(BaseModel):
    text: str
    is_user: bool
    timestamp: str

class Exercise(BaseModel):
    name: str
    display_name: str
    type: str
    sets: int
    total_reps: Optional[int]
    total_volume: Optional[float]
    total_duration_seconds: Optional[int]

class WorkoutHistoryItem(BaseModel):
    id: str
    date: str
    duration_minutes: int
    exercises: List[Exercise]

class CoachChatRequest(BaseModel):
    message: str
    conversation_history: List[ConversationMessage]
    workout_history: Optional[List[WorkoutHistoryItem]] = None

class CoachChatResponse(BaseModel):
    response: str

@app.post("/chat/coach", response_model=CoachChatResponse)
async def coach_chat(request: CoachChatRequest):
    """
    Handle coach chat messages.
    
    This endpoint receives a user message, conversation history, and workout history,
    then returns a text response from the AI coach.
    """
    
    # Build conversation context for your LLM
    messages = []
    
    # Add system prompt with workout context if available
    system_prompt = """You are an expert fitness coach. Your role is to:
    - Answer questions about workouts, nutrition, and fitness
    - Provide personalized advice based on user context
    - Be encouraging and supportive
    - Keep responses concise but informative
    - Reference the user's workout history when relevant
    """
    
    # Add workout history context to system prompt
    if request.workout_history:
        workout_summary = f"\n\nUser's Recent Workout History ({len(request.workout_history)} workouts):\n"
        for workout in request.workout_history:
            workout_summary += f"- {workout.date}: {workout.duration_minutes} min, {len(workout.exercises)} exercises\n"
            for exercise in workout.exercises:
                if exercise.type == "weight":
                    workout_summary += f"  • {exercise.display_name}: {exercise.sets} sets, {exercise.total_reps} reps, {exercise.total_volume} lbs volume\n"
                else:
                    workout_summary += f"  • {exercise.display_name}: {exercise.sets} sets, {exercise.total_duration_seconds}s\n"
        system_prompt += workout_summary
    
    messages.append({
        "role": "system",
        "content": system_prompt
    })
    
    # Add conversation history
    for msg in request.conversation_history:
        messages.append({
            "role": "user" if msg.is_user else "assistant",
            "content": msg.text
        })
    
    # Add current message
    messages.append({
        "role": "user",
        "content": request.message
    })
    
    # Call your LLM (example with OpenAI)
    try:
        # response = await your_llm_call(messages)
        # For now, return a placeholder
        response_text = "I'm your AI fitness coach! Based on your workout history, I can provide personalized advice."
        
        return CoachChatResponse(response=response_text)
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
```

## Error Responses

### 400 Bad Request
```json
{
  "detail": "Invalid request format"
}
```

### 500 Internal Server Error
```json
{
  "detail": "Error processing request"
}
```

## Key Differences from Voice Workout Endpoint

| Feature | Coach Chat | Voice Workout |
|---------|-----------|---------------|
| Input | Text | Audio file |
| Output | Text only | Text + Audio + Commands |
| Purpose | General fitness Q&A | Workout logging |
| History | Full conversation + Workout history | Workout session only |
| Commands | None | `log_set` commands |

## Client-Side Implementation

The Flutter app uses:
- **Store**: `CoachChatStore` - Manages conversation state
- **Service**: `CoachChatService` - Handles API calls and workout history
- **Screen**: `CoachChatScreen` - UI with message bubbles

### Key Features
- Automatic message history management
- Automatic workout history inclusion (last 10 workouts)
- Loading states during API calls (animated sphere)
- Error handling with user feedback
- Clear chat functionality
- Auto-scroll to latest messages

### Workout History Integration
The service automatically includes the user's last 10 completed workouts with each request. This can be configured:

```dart
// Include workout history (default)
await CoachChatService.sendMessageWithStore(
  userMessage: message,
  store: store,
);

// Include more workouts
await CoachChatService.sendMessageWithStore(
  userMessage: message,
  store: store,
  workoutHistoryLimit: 20,
);

// Exclude workout history
await CoachChatService.sendMessageWithStore(
  userMessage: message,
  store: store,
  includeWorkoutHistory: false,
);
```

## Testing

### Example cURL Request

```bash
curl -X POST http://localhost:8000/chat/coach \
  -H "Content-Type: application/json" \
  -d '{
    "message": "What exercises should I do for chest?",
    "conversation_history": [],
    "workout_history": [
      {
        "id": "123",
        "date": "2025-12-24T18:00:00.000Z",
        "duration_minutes": 45,
        "exercises": [
          {
            "name": "bench_press",
            "display_name": "Bench Press",
            "type": "weight",
            "sets": 3,
            "total_reps": 24,
            "total_volume": 5400.0,
            "total_duration_seconds": null
          }
        ]
      }
    ]
  }'
```

### Expected Response

```json
{
  "response": "I see you've been doing bench press recently with great consistency! For chest development, I recommend continuing with bench press as your main movement, then adding..."
}
```

## Future Enhancements

Potential additions to consider:
- User profile context (goals, stats from onboarding)
- Personal records and progress tracking
- Streaming responses for longer answers
- Rich media support (images, videos)
- Voice input/output integration
- Exercise form videos and demonstrations
