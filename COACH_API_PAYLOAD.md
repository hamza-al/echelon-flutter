# Coach Chat API Payload Documentation

## Endpoint
`POST /chat/coach`

## Overview
The Flutter app sends user messages along with contextual data (workout history and nutrition data) to provide the AI coach with full context for personalized responses.

## Request Payload Structure

```json
{
  "message": "string",
  "conversation_history": [],
  "workout_history": [],
  "nutrition_history": []
}
```

---

## 1. Message Field

**Type:** `string`  
**Required:** Yes

The current user message/question.

**Example:**
```json
{
  "message": "Should I increase my protein intake?"
}
```

---

## 2. Conversation History

**Type:** `array` of objects  
**Required:** Yes (can be empty)

Previous messages in the conversation for context.

**Structure:**
```json
{
  "conversation_history": [
    {
      "role": "user",
      "content": "How was my last workout?"
    },
    {
      "role": "assistant", 
      "content": "Your last workout was great! You hit 8 sets..."
    }
  ]
}
```

---

## 3. Workout History

**Type:** `array` of objects  
**Required:** No (optional, null if not included)

Up to 10 most recent completed workouts.

**Structure:**
```json
{
  "workout_history": [
    {
      "id": "uuid-string",
      "date": "2024-01-15T14:30:00.000Z",
      "duration_minutes": 45,
      "exercises": [
        {
          "name": "bench_press",
          "display_name": "Bench Press",
          "type": "weight_based",
          "sets": 3,
          "total_reps": 24,
          "total_volume": 3600.0,
          "total_duration_seconds": null
        },
        {
          "name": "plank",
          "display_name": "Plank",
          "type": "duration_based",
          "sets": 3,
          "total_reps": null,
          "total_volume": null,
          "total_duration_seconds": 180
        }
      ]
    }
  ]
}
```

**Field Types:**
- `id`: string (UUID)
- `date`: string (ISO 8601 timestamp)
- `duration_minutes`: int
- `exercises`: array
  - `name`: string (internal identifier)
  - `display_name`: string (user-facing name)
  - `type`: string (`"weight_based"` or `"duration_based"`)
  - `sets`: int
  - `total_reps`: int or null
  - `total_volume`: double or null (weight × reps)
  - `total_duration_seconds`: int or null

---

## 4. Nutrition History (NEW)

**Type:** `array` with single object  
**Required:** No (optional, null if not included)

Today's nutritional data including calories, macros, and recent meals.

### Full Structure

```json
{
  "nutrition_history": [
    {
      "goal": "cut",
      "calories": {
        "consumed": 1420,
        "target": 1800,
        "remaining": 380
      },
      "macros": {
        "protein": {
          "consumed": 85.0,
          "target": 170.0,
          "remaining": 85.0
        },
        "carbs": {
          "consumed": 210.0,
          "target": 382.5,
          "remaining": 172.5
        },
        "fats": {
          "consumed": 42.0,
          "target": 59.5,
          "remaining": 17.5
        }
      },
      "meals_logged": 3,
      "recent_meals": [
        {
          "name": "2 Eggs",
          "calories": 140,
          "protein": 12.0,
          "carbs": 1.0,
          "fats": 10.0,
          "time": "8:30 AM"
        }
      ]
    }
  ]
}
```

### Field Details

#### Top Level
- **`goal`**: `string` - User's nutrition goal
  - Values: `"cut"`, `"bulk"`, or `"maintain"`
  - Indicates whether user is trying to lose fat, gain muscle, or maintain weight

#### Calories Object
- **`consumed`**: `int` - Total calories eaten today
- **`target`**: `int` - Daily calorie goal
- **`remaining`**: `int` - Calories left (can be negative if over)

#### Macros Object
Each macro (protein, carbs, fats) has the same structure:

- **`consumed`**: `double` - Grams consumed today
- **`target`**: `double` - Daily target in grams
- **`remaining`**: `double` - Grams remaining (always >= 0, clamped)

**Macro Target Calculations:**
- **Protein**: 1g per lb of body weight
- **Carbs**: 2.25g per lb of body weight  
- **Fats** (varies by goal):
  - Cut: 0.35g per lb
  - Maintain: 0.45g per lb
  - Bulk: 0.55g per lb

#### Meals Array
- **`meals_logged`**: `int` - Total number of meals logged today
- **`recent_meals`**: `array` - Last 5 meals (most recent first)

**Meal Object:**
- **`name`**: `string` - Food item name (e.g., "2 Eggs", "Chicken Breast")
- **`calories`**: `int` - Calories in this meal
- **`protein`**: `double` or `null` - Protein in grams (nullable)
- **`carbs`**: `double` or `null` - Carbs in grams (nullable)
- **`fats`**: `double` or `null` - Fats in grams (nullable)
- **`time`**: `string` - Formatted time (e.g., "8:30 AM", "2:15 PM")

---

## Complete Example Request

```json
{
  "message": "Should I eat more protein today?",
  "conversation_history": [
    {
      "role": "user",
      "content": "How's my workout progress?"
    },
    {
      "role": "assistant",
      "content": "Your progress is looking great! You've been consistent..."
    }
  ],
  "workout_history": [
    {
      "id": "abc-123",
      "date": "2024-01-15T10:00:00.000Z",
      "duration_minutes": 45,
      "exercises": [
        {
          "name": "squat",
          "display_name": "Squat",
          "type": "weight_based",
          "sets": 4,
          "total_reps": 32,
          "total_volume": 8000.0,
          "total_duration_seconds": null
        }
      ]
    }
  ],
  "nutrition_history": [
    {
      "goal": "bulk",
      "calories": {
        "consumed": 1850,
        "target": 2500,
        "remaining": 650
      },
      "macros": {
        "protein": {
          "consumed": 95.0,
          "target": 170.0,
          "remaining": 75.0
        },
        "carbs": {
          "consumed": 220.0,
          "target": 382.5,
          "remaining": 162.5
        },
        "fats": {
          "consumed": 58.0,
          "target": 93.5,
          "remaining": 35.5
        }
      },
      "meals_logged": 4,
      "recent_meals": [
        {
          "name": "Protein Shake",
          "calories": 250,
          "protein": 30.0,
          "carbs": 10.0,
          "fats": 5.0,
          "time": "2:30 PM"
        },
        {
          "name": "Chicken & Rice",
          "calories": 650,
          "protein": 45.0,
          "carbs": 80.0,
          "fats": 12.0,
          "time": "12:00 PM"
        }
      ]
    }
  ]
}
```

---

## Backend Implementation Guide

### Python (FastAPI) Example

```python
from pydantic import BaseModel
from typing import List, Optional

class MacroData(BaseModel):
    consumed: float
    target: float
    remaining: float

class CalorieData(BaseModel):
    consumed: int
    target: int
    remaining: int

class Meal(BaseModel):
    name: str
    calories: int
    protein: Optional[float]
    carbs: Optional[float]
    fats: Optional[float]
    time: str

class NutritionData(BaseModel):
    goal: str  # "cut", "bulk", or "maintain"
    calories: CalorieData
    macros: dict[str, MacroData]  # keys: "protein", "carbs", "fats"
    meals_logged: int
    recent_meals: List[Meal]

class CoachChatRequest(BaseModel):
    message: str
    conversation_history: List[dict]
    workout_history: Optional[List[dict]] = None
    nutrition_history: Optional[List[NutritionData]] = None

@app.post("/chat/coach")
async def coach_chat(request: CoachChatRequest):
    # Access nutrition data
    if request.nutrition_history:
        nutrition = request.nutrition_history[0]
        
        # Check if user needs more protein
        protein_remaining = nutrition.macros["protein"].remaining
        if protein_remaining > 50:
            # Suggest high-protein foods
            pass
        
        # Check if user is over calories
        if nutrition.calories.remaining < 0:
            # Warn about overeating
            pass
    
    # Generate response with full context
    response = generate_coach_response(
        message=request.message,
        history=request.conversation_history,
        workouts=request.workout_history,
        nutrition=request.nutrition_history
    )
    
    return {"response": response}
```

---

## Key Points for Backend

1. **Nutrition is always an array** (even though it only contains today's data)
2. **All macro values are doubles** (not strings)
3. **Meal macros can be null** (if not provided by nutrition API)
4. **Remaining values are clamped to >= 0** for macros
5. **Calories remaining can be negative** (indicates over goal)
6. **Goal affects macro targets** especially fats
7. **Recent meals limited to 5** most recent entries
8. **Time is formatted string** not timestamp

---

## Use Cases for AI Coach

With this data, the coach can:

✅ Recommend protein intake adjustments  
✅ Suggest meal timing for workouts  
✅ Warn if user is consistently under/over calories  
✅ Provide macro balance feedback  
✅ Suggest foods to hit remaining targets  
✅ Adjust workout intensity based on calorie intake  
✅ Give context-aware bulking/cutting advice  
✅ Track progress over conversation  

---

## Testing Tips

1. **Empty nutrition**: If user hasn't set goals, `nutrition_history` will be `null`
2. **No meals**: `recent_meals` will be empty array `[]`
3. **Negative remaining**: Check for over-goal scenarios
4. **Null macros**: Some meals may not have complete macro data
5. **Type safety**: All numbers are proper numeric types, not strings

---

## Version History

- **v1.0** (2024-01): Initial nutrition integration
  - Added `nutrition_history` field
  - Includes calories, macros, and recent meals
  - Goal-based macro calculations

