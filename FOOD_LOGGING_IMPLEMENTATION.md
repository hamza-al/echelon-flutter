# Food Logging Implementation

## Overview
Added complete food logging functionality with AI-powered nutrition analysis and macro tracking.

## New Features

### 1. AI-Powered Food Entry
- **Endpoint**: `/chat/calories`
- **Input**: Natural language food description (e.g., "2 eggs", "chicken breast")
- **Output**: Formatted item name, calories, protein, carbs, fats
- **Model**: GPT-4o-mini with structured output for consistency

### 2. Macro Tracking System

#### Extended Data Models
- **`FoodEntry`** now includes:
  - `@HiveField(5) carbs`: double? (grams)
  - `@HiveField(6) fats`: double? (grams)
- **`DailyNutrition`** computed properties:
  - `totalCarbs`: Sum of all entry carbs
  - `totalFats`: Sum of all entry fats

#### Macro Target Calculations (`MacroCalculator`)
Based on user's weight and nutrition goal:

**Protein**: `1g per lb of body weight`
- Universal across all goals

**Carbs**: `2.25g per lb of body weight`
- Universal across all goals

**Fats**: Varies by goal
- **Cut**: `0.35g per lb` (0.3-0.4 range)
- **Maintain**: `0.45g per lb` (0.4-0.5 range)
- **Bulk**: `0.55g per lb` (0.5-0.6 range)

### 3. Services

#### `CaloriesApiService` (`/lib/services/`)
HTTP client for nutrition API:
- `getCalories(quantity, foodItem)`: Returns `CaloriesResponse`
- **Models**:
  - `CaloriesResponse`: item_name, calories, macros
  - `Macros`: protein, carbs, fats

### 4. UI Components

#### `AddFoodDialog` (`/lib/widgets/`)
Food logging modal:
- Single text input for natural language
- Loading state during API call
- Error handling with user feedback
- Calls API → Logs to store → Closes on success

#### Redesigned Nutrition Screen
**Major visual changes:**

1. **Removed card background from calorie ring**
   - Clean, minimal design
   - Ring floats directly on black background

2. **Added 3 macro rings below calorie ring**
   - **Protein**: Indigo (#6366F1)
   - **Carbs**: Amber (#F59E0B)
   - **Fats**: Pink (#EC4899)
   - Each shows: current/target, "X left" text
   - Smaller rings (80x80px) with thinner stroke

3. **New "Log Food" button**
   - Purple primary color
   - Icon + text
   - Opens `AddFoodDialog`

4. **Enhanced meal entries**
   - Now displays macros inline: "P:25g C:30g F:10g"
   - Time + macros in same row
   - Cleaner, more informative

### 5. Data Flow

```
User enters "2 eggs"
  ↓
AddFoodDialog → CaloriesApiService.getCalories()
  ↓
OpenAI API (structured output)
  ↓
Returns: {
  item_name: "2 Eggs",
  calories: 140,
  macros: { protein: 12, carbs: 1, fats: 10 }
}
  ↓
NutritionStore.logFood() → FoodEntry (with macros)
  ↓
DailyNutrition saved to Hive
  ↓
UI updates reactively (Provider)
```

## Visual Design

### Calorie Ring (Main)
- **Size**: 200x200px
- **Stroke**: 16px
- **Color**: Purple (normal), Orange (over goal)
- **Display**: Consumed / Target, Remaining text
- **Background**: None (floats on black)

### Macro Rings (3-column row)
- **Size**: 80x80px each
- **Stroke**: 8px
- **Colors**:
  - Protein: Indigo
  - Carbs: Amber
  - Fats: Pink
- **Layout**: Equal width columns with 12px spacing
- **Display**: 
  - Ring center: Current amount + unit
  - Below: Macro name + "X left" text

### Log Food Button
- **Full width** in horizontal padding
- **Purple** background
- **Icon**: `add_circle_outline`
- **Text**: "Log Food"
- **Style**: Rounded (16px), elevated

## Key Implementation Details

1. **Weight parsing**: Extracts numeric value from weight string (handles "170 lbs", "170", etc.)
2. **API integration**: Single endpoint call with error handling
3. **Macro display**: Conditional rendering (only shows if values exist)
4. **Progress rings**: Custom painters for smooth animations
5. **Target calculations**: Dynamic based on user profile and goals

## User Experience Flow

1. User taps **"Log Food"** button
2. Dialog opens with text input (autofocus)
3. User types food description naturally
4. Taps "Add" or presses Enter
5. Loading spinner shows during API call
6. On success:
   - Food entry added to list
   - Calorie ring updates
   - Macro rings update
   - Dialog closes
7. On error: Error message shown in dialog

## Backend Integration

Backend endpoint must return:
```json
{
  "item_name": "2 Eggs",
  "calories": 140,
  "macros": {
    "protein": 12.0,
    "carbs": 1.0,
    "fats": 10.0
  }
}
```

## Future Enhancements

- [ ] Voice-based food logging (optional)
- [ ] Recent foods / favorites for quick-add
- [ ] Meal templates (breakfast, lunch, dinner categories)
- [ ] Barcode scanning for packaged foods
- [ ] Food search/autocomplete
- [ ] Undo delete (snackbar with undo action)
- [ ] Edit existing entries
- [ ] Copy yesterday's meals
- [ ] Weekly macro trends graph

