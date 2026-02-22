# User Data Storage Synchronization

## Current Implementation ✅

Both **Onboarding** and **Profile** screens read and write to the **same local Hive store** via `UserService`.

### Shared Storage Architecture

**Data Store:**
- **Box Name:** `userBox`
- **Key:** `currentUser`
- **Model:** `User` (Hive TypeId: 0)
- **Service:** `UserService` (singleton pattern)

### Data Flow

#### Onboarding Flow → Storage
```dart
OnboardingFlow
  ↓ (collects data in OnboardingData model)
  ↓
UserService.updateFromOnboarding()
  ↓ (writes to Hive)
User model in userBox
```

#### Profile Screen ↔ Storage
```dart
ProfileScreen._loadUserData()
  ↓ (reads from Hive)
UserService.getCurrentUser()
  ↓
User model from userBox

ProfileScreen._saveProfile()
  ↓ (writes to Hive)
UserService.saveUser()
  ↓
User model in userBox
```

### Synchronized Fields

| Field | Onboarding | Profile | User Model | Synced? |
|-------|-----------|---------|------------|---------|
| Gender | ✅ | ✅ | `gender: String?` | ✅ |
| Weight | ✅ | ✅ | `weight: String?` | ✅ |
| Height | ✅ | ✅ | `height: String?` | ✅ |
| Goals | ✅ | ✅ | `goals: List<String>` | ✅ |
| Nutrition Goal | ✅ | ❌ | `nutritionGoal: String?` | ⚠️ Partial |
| Target Calories | ✅ | ❌ | `targetCalories: int?` | ⚠️ Partial |

### ⚠️ Potential Issue Found

**Nutrition Goals** are set during onboarding but **NOT** editable in the profile screen.

**Impact:**
- User can set nutrition goals during onboarding
- User cannot update nutrition goals in profile screen
- Must use separate Nutrition Goal Setup screen

**Recommendation:**
Consider adding nutrition goal editing to profile screen or adding a clear navigation path from profile to nutrition goal setup.

### How It Works

1. **App Launch:**
   ```dart
   UserService.init()
   // Opens Hive box 'userBox'
   // Creates User if doesn't exist
   ```

2. **During Onboarding:**
   ```dart
   // Collect data in OnboardingData
   OnboardingData {
     gender, weight, height, goals, nutritionGoal, targetCalories
   }
   
   // Save to Hive
   UserService.updateFromOnboarding(...)
   UserService.updateNutritionGoals(...)
   ```

3. **In Profile Screen:**
   ```dart
   // Load data
   final user = UserService.getCurrentUser()
   _selectedGender = user.gender
   _weightLbs = user.weight
   _heightInches = user.height
   _selectedGoals = user.goals
   
   // Save changes
   user.gender = _selectedGender
   user.weight = _weightLbs
   user.height = _heightInches
   user.goals = _selectedGoals
   UserService.saveUser(user)
   ```

### Verification

**Storage Location:**
- Data persists in Hive box at app's document directory
- Survives app restarts
- Shared across all screens via `UserService`

**Data Integrity:**
- Single source of truth (one User instance)
- Atomic updates (Hive transactions)
- Type-safe with Hive adapters

## Conclusion

✅ **Onboarding and Profile ARE synchronized** - they use the same Hive store via UserService.

⚠️ **Minor gap:** Nutrition goals set in onboarding but not editable in profile (by design).

All basic user info (gender, weight, height, fitness goals) is fully synchronized between onboarding and profile.

