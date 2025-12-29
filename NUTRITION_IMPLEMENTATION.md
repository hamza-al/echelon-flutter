# Nutrition Tracking Implementation

## Overview
Successfully implemented a complete nutrition calorie tracking system with goal setup and visual display.

## Architecture

### 1. Data Models (`/lib/models/`)

#### `User` (Hive TypeId: 0)
**Extended with nutrition fields:**
- `@HiveField(8) nutritionGoal`: String? - 'cut', 'bulk', or 'maintain'
- `@HiveField(9) targetCalories`: int? - Daily calorie target
- **Methods:**
  - `updateNutritionGoals(goal, calories)`: Updates nutrition settings
  - `hasNutritionGoals`: Boolean getter to check if set

#### `FoodEntry` (Hive TypeId: 4)
- **Fields:**
  - `id`: Unique identifier (UUID)
  - `name`: Food name
  - `calories`: Calorie count
  - `protein`: Optional protein amount (grams)
  - `timestamp`: When the food was logged
- **Computed:** `timeFormatted` - Returns formatted time string (e.g., "2:30 PM")

#### `DailyNutrition` (Hive TypeId: 5)
- **Fields:**
  - `id`: Unique identifier (UUID)
  - `date`: Date for this nutrition record (normalized to midnight)
  - `entries`: List of `FoodEntry` for the day
  - `calorieGoal`: Target calories for the day
- **Computed Properties:**
  - `totalCalories`: Sum of all entry calories
  - `totalProtein`: Sum of all entry protein
  - `remaining`: Calories remaining (or over if negative)
  - `progress`: Progress percentage (0.0 - 2.0, clamped)
  - `isOverGoal`: Boolean if over calorie target
  - `entryCount`: Number of entries logged

### 2. Service Layer (`/lib/services/`)

#### `UserService`
Extended with nutrition goal persistence:
- **Methods:**
  - `updateNutritionGoals(goal, calories)`: Saves nutrition goals to User model in Hive
  - `getNutritionGoals()`: Returns Map with 'goal' and 'calories', or null if not set

#### `NutritionService`
Handles all Hive database operations for nutrition data:
- **Methods:**
  - `initialize()`: Opens Hive box
  - `getTodayNutrition(calorieGoal)`: Gets or creates today's record
  - `getNutritionForDate(date)`: Gets record for specific date
  - `logFood(entry, calorieGoal)`: Adds a food entry
  - `deleteFood(entryId, calorieGoal)`: Removes a food entry
  - `updateCalorieGoal(newGoal)`: Updates target for today
  - `getAllNutrition()`: Gets all nutrition history
  - `getNutritionInRange(start, end)`: Gets records in date range
  - `clearAll()`: Resets all data

### 3. State Management (`/lib/stores/`)

#### `NutritionStore` (extends `ChangeNotifier`)
Reactive state layer using Provider pattern:
- **State:**
  - `todayNutrition`: Current day's `DailyNutrition` record (in memory)
  - **Nutrition goals read from Hive `User` model via `UserService`:**
    - `nutritionGoal`: 'cut', 'bulk', or 'maintain' (persisted)
    - `targetCalories`: Daily calorie target (persisted)
- **Computed Getters:**
  - `totalCalories`, `totalProtein`, `remaining`, `progress`, `isOverGoal`, `entries`
  - `hasSetGoals`: Boolean indicating if user has completed goal setup (reads from Hive)
- **Methods:**
  - `initialize()`: Loads today's data (only if goals are set in Hive)
  - `setNutritionGoals(goal, calories)`: Sets user goals and saves to Hive
  - `updateTargetCalories(calories)`: Updates target and saves to Hive
  - `logFood(name, calories, protein)`: Logs a food entry
  - `deleteFood(entryId)`: Removes an entry
  - `refreshToday()`: Reloads today's data
  - `getNutritionForDate(date)`: Gets historical data
  - `getAllNutrition()`: Gets all history

**Persistence Strategy:**
- Nutrition goals (goal type + target calories) → Stored in `User` model (Hive)
- Daily food entries → Stored in `DailyNutrition` records (Hive)
- Current day state → Cached in memory, refreshed on app launch

### 4. UI Screens

#### `NutritionGoalSetupScreen` (`/lib/screens/`)
**Purpose:** Shown after onboarding to set nutrition goals

**Features:**
- Three goal options: Cut, Bulk, Maintain
- Each goal has description and suggested calorie target
- Adjustable calorie target with +/- buttons (50 cal increments)
- Range: 1000-5000 cal/day
- Auto-suggests calories based on goal:
  - Cut: 1800 cal
  - Bulk: 2500 cal
  - Maintain: 2000 cal
- Reassurance text: "You can change this anytime"
- Navigates to `/home` on completion

#### `NutritionScreen` (`/lib/screens/`)
**Purpose:** Main nutrition tab displaying daily calorie tracking

**Goal Setup Check:**
- **Gatekeeper logic:** Before rendering, checks if `hasSetGoals` is true
- If goals not set: Shows loading spinner and redirects to `/nutrition_goal_setup`
- If goals set: Shows full nutrition tracking interface
- This ensures users cannot access nutrition tab without completing setup

**Layout:**
1. **Header:**
   - "Nutrition" title
   - "Today" subtitle

2. **Calorie Ring (Center Module):**
   - Large circular progress indicator
   - Center shows: consumed calories / target calories
   - Ring color: Purple (normal), Orange (over goal)
   - Bottom text: "X cal remaining" or "X cal over"
   - Background: Light purple card with border

3. **Today's Meals Section:**
   - Header: "Today's Meals" with entry count
   - Empty state: Restaurant icon + "No meals logged yet"

4. **Food Entry List:**
   - Each entry is a card showing:
     - Food name (bold)
     - Time logged (e.g., "2:30 PM")
     - Calories (purple, bold, right-aligned)
     - Protein amount (if provided, gray, small)
   - Swipe-to-delete functionality (dismissible)
   - Delete background: Red with trash icon

**Custom Painter:**
- `_CalorieRingPainter`: Draws the circular progress ring with smooth animations

### 5. Navigation Integration

#### Updated `MainNavigationScreen`
- Added 4th tab: "Nutrition" (between Workout and Coach)
- Icon: `Icons.restaurant_outlined`
- Navigation indices shifted:
  - 0: Progress
  - 1: Workout
  - 2: Nutrition (NEW)
  - 3: Coach

#### Updated `OnboardingFlow`
- Now navigates to `NutritionGoalSetupScreen` after completion
- User sets nutrition goals before entering main app

### 6. Initialization (`main.dart`)

**Changes:**
1. Registered Hive adapters: `FoodEntryAdapter`, `DailyNutritionAdapter`
2. Initialize `NutritionService` before app starts
3. Added `NutritionStore` to `MultiProvider`
4. Added `/nutrition_goal_setup` route
5. Pass `nutritionService` to `MyApp` widget

### 7. Styles (`lib/styles.dart`)

**New Colors:**
- `text`: White (alias for accent)
- `cardBackground`: Dark gray (#1C1C1E)

## User Flow

1. **New User:**
   - Landing Page → Onboarding (goals, physical data, gender)
   - **Nutrition Goal Setup** (NEW) → Home (with Nutrition tab)

2. **Existing User:**
   - Opens app → Sees Nutrition tab in bottom nav
   - Can view today's calorie progress and logged meals
   - Can swipe to delete entries

3. **Future Enhancement:**
   - Add manual food logging UI
   - Voice logging integration (optional)
   - Historical view (weekly/monthly)
   - Macros breakdown (protein, carbs, fats)

## Key Design Decisions

1. **Goal setup is mandatory:** Ensures users have a target from day one
2. **Goal gating:** Users cannot access nutrition screen until goals are set (redirects to setup)
3. **Hive persistence for goals:** Nutrition goals stored in `User` model, persist across app launches
4. **Separate storage for entries:** Daily food entries stored in `DailyNutrition` records
5. **Hybrid state management:** Goals read from Hive on-demand, today's entries cached in memory
6. **Display-first approach:** Focus on showing progress, logging mechanism can be added later
7. **Swipe-to-delete:** Quick way to remove entries without confirmation dialog
8. **Purple/Orange color scheme:** Purple for normal state, orange for over-goal warning
9. **Circular ring progress:** Visual at-a-glance understanding of daily progress
10. **Date normalization:** All dates stored at midnight for consistent querying
11. **Reactive state with Provider:** UI updates automatically when data changes

## Testing Checklist

- [ ] Goal setup flow after onboarding
- [ ] Navigation to nutrition tab
- [ ] Empty state display
- [ ] (Manual) Add food entries to test ring progress
- [ ] Swipe-to-delete entries
- [ ] Progress ring color change when over goal
- [ ] Calorie adjustment in goal setup

## Next Steps (Future Enhancements)

1. Add manual food logging dialog/screen
2. Integrate voice logging (optional, via backend command)
3. Add historical view (past days)
4. Add macro tracking (protein, carbs, fats)
5. Add weekly/monthly summaries
6. Add quick-add favorites
7. Add search functionality for common foods
8. Persist nutrition goals in User model

