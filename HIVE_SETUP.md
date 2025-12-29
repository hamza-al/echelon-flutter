# Hive Database Setup - User Data Storage

## Overview
Implemented local database storage using Hive CE to persist user information collected during onboarding and subscription status.

## Files Created

### 1. `/lib/models/user.dart`
- Hive model for storing user data
- Fields:
  - `gender` (String?)
  - `weight` (String?)
  - `height` (String?)
  - `goals` (List<String>)
  - `hasPaidSubscription` (bool)
  - `createdAt` (DateTime?)
  - `lastUpdated` (DateTime?)
- Methods:
  - `updateFromOnboarding()` - Update user data from onboarding
  - `updateSubscriptionStatus()` - Update subscription status
  - `isOnboardingComplete` - Check if all required fields are filled

### 2. `/lib/models/user.g.dart`
- Auto-generated Hive TypeAdapter for User model
- Handles serialization/deserialization of User objects

### 3. `/lib/services/user_service.dart`
- Service layer for interacting with Hive user data
- Methods:
  - `init()` - Initialize Hive box (called in main.dart)
  - `getCurrentUser()` - Get or create current user
  - `saveUser(User)` - Save user to database
  - `updateFromOnboarding()` - Convenience method to update onboarding data
  - `updateSubscriptionStatus(bool)` - Update subscription status
  - `hasCompletedOnboarding()` - Check if onboarding is done
  - `hasPaidSubscription()` - Check if user has paid
  - `clearUserData()` - Clear all data (for testing/logout)
  - `close()` - Close Hive box

## Integration Points

### main.dart
- Initialized Hive before app starts
- Registered UserAdapter
- Called UserService.init()
- Added `AppInitializer` widget that checks subscription status on app launch
  - If user has paid: Routes to HomeScreen
  - If user hasn't paid: Routes to LandingPage

### onboarding_flow.dart
- Saves user data to Hive when onboarding completes
- Calls `UserService.updateFromOnboarding()`

### paywall_screen.dart
- Updates subscription status when purchase succeeds
- Calls `UserService.updateSubscriptionStatus(true)`
- Navigates to HomeScreen after successful purchase

### home_screen.dart (NEW)
- Main app screen for paid users
- Displays personalized greeting based on user goals
- Shows workout stats and pulsing sphere for voice control
- Accessible only after successful subscription purchase

## Dependencies Added
```yaml
dependencies:
  hive_ce: ^2.16.0
  hive_ce_flutter: ^2.1.0

dev_dependencies:
  hive_ce_generator: ^1.7.3
  build_runner: ^2.4.14
```

## How to Regenerate Type Adapters
If you modify the User model, run:
```bash
dart run build_runner build --delete-conflicting-outputs
```

## Usage Examples
See `/lib/services/user_service_example.dart` for detailed usage examples.

## Notes
- User data is stored locally on device using Hive
- Only one user is stored (single-user app model)
- Data persists across app restarts
- Subscription status is synced with RevenueCat purchases

