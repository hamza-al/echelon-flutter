# Rest Timer Command

## Overview
The app now supports a `start_timer` command that displays a rest timer module below the particle sphere during active workouts.

## Command Structure

### Command Type: `start_timer`

**Payload:**
```json
{
  "type": "start_timer",
  "payload": {
    "duration_seconds": 90
  }
}
```

**Fields:**
- `duration_seconds` (integer, required): Duration of the rest timer in seconds

## Example Response

The backend should include timer commands alongside `log_set` commands in the response:

```json
{
  "audio": {
    "base64": "..."
  },
  "user_transcript": "I just did 3 sets of 10 reps at 135 pounds on bench press",
  "assistant_text": "Great work! I've logged 3 sets of bench press at 135 pounds for 10 reps. Rest for 90 seconds.",
  "commands": [
    {
      "type": "log_set",
      "payload": {
        "exercise": "Bench Press",
        "reps": 10,
        "weight": 135,
        "duration_seconds": 0
      }
    },
    {
      "type": "log_set",
      "payload": {
        "exercise": "Bench Press",
        "reps": 10,
        "weight": 135,
        "duration_seconds": 0
      }
    },
    {
      "type": "log_set",
      "payload": {
        "exercise": "Bench Press",
        "reps": 10,
        "weight": 135,
        "duration_seconds": 0
      }
    },
    {
      "type": "start_timer",
      "payload": {
        "duration_seconds": 90
      }
    }
  ],
  "follow_up_needed": false
}
```

## UI Behavior

When a `start_timer` command is received:
1. The rest timer module appears below the particle sphere
2. Shows countdown in MM:SS format
3. Visual pulsing animation when less than 5 seconds remain
4. Progress bar fills as time elapses
5. User can skip the timer at any time
6. Timer auto-dismisses when complete

## Common Use Cases

- **After compound lifts**: 90-180 seconds
- **After isolation exercises**: 30-60 seconds
- **Circuit training**: 15-30 seconds
- **HIIT workouts**: 10-30 seconds

## Notes

- Multiple commands can be sent in one response (log sets + timer)
- Timer starts immediately when command is received
- Only one timer can be active at a time (new timer replaces old one)
- Timer uses device-local countdown (no network connection needed after start)

