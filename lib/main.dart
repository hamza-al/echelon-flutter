import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'dart:io' show Platform;
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'styles.dart';
import 'screens/landing_page.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/onboarding_flow.dart';
import 'screens/nutrition_goal_setup_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'models/user.dart';
import 'models/workout.dart';
import 'models/exercise.dart';
import 'models/exercise_set.dart';
import 'models/food_entry.dart';
import 'models/daily_nutrition.dart';
import 'models/auth_data.dart';
import 'models/workout_split.dart';
import 'services/user_service.dart';
import 'services/workout_service.dart';
import 'services/nutrition_service.dart';
import 'services/auth_service.dart';
import 'services/workout_audio_cache.dart';
import 'services/split_service.dart';
import 'stores/active_workout_store.dart';
import 'stores/coach_chat_store.dart';
import 'stores/nutrition_store.dart';

// DEBUG FLAG: Set to true to always show onboarding flow
const bool kForceShowOnboarding = false;


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Register adapters
  Hive.registerAdapter(UserAdapter());
  Hive.registerAdapter(WorkoutAdapter());
  Hive.registerAdapter(ExerciseAdapter());
  Hive.registerAdapter(ExerciseSetAdapter());
  Hive.registerAdapter(FoodEntryAdapter());
  Hive.registerAdapter(DailyNutritionAdapter());
  Hive.registerAdapter(AuthDataAdapter());
  Hive.registerAdapter(WorkoutSplitAdapter());
  
  // Initialize services
  await UserService.init();
  await WorkoutService.init();
  await SplitService.init();
  
  final nutritionService = NutritionService();
  await nutritionService.initialize();
  
  final authService = AuthService();
  await authService.initialize();
  
  // Initialize workout audio cache
  final workoutAudioCache = WorkoutAudioCache(authService);
  
  // Pre-fetch workout start audio in background (non-blocking)
  workoutAudioCache.fetchAndCacheAudio().catchError((_) {
    // Silently ignore errors - will fetch on demand if needed
  });
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  final apiKey = dotenv.env['REVENUE_CAT_API_KEY']!;

  
  // Initialize RevenueCat
  await _initRevenueCat(apiKey);
  
  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>.value(value: authService),
        Provider<WorkoutAudioCache>.value(value: workoutAudioCache),
        Provider<NutritionService>.value(value: nutritionService),
        ChangeNotifierProvider(create: (_) => ActiveWorkoutStore()),
        ChangeNotifierProvider(create: (_) => CoachChatStore()),
        ChangeNotifierProvider(create: (_) => NutritionStore(nutritionService)),
      ],
      child: const MyApp(),
    ),
  );
}

Future<void> _initRevenueCat(String apiKey) async {
  // Only set log level in debug mode
  // Removed for production: await Purchases.setLogLevel(LogLevel.debug);
  
  if (!Platform.isIOS && !Platform.isAndroid) {
    return;
  }
  
  final configuration = PurchasesConfiguration(apiKey);
  await Purchases.configure(configuration);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'echelon',
        theme: ThemeData(
          scaffoldBackgroundColor: AppColors.background,
          colorScheme: ColorScheme.dark(
            surface: AppColors.background,
            primary: AppColors.accent,
            onSurface: AppColors.accent,
          ),
        ),
        home: const AppInitializer(),
        routes: {
          '/onboarding': (context) => const OnboardingFlow(),
          '/nutrition_goal_setup': (context) => const NutritionGoalSetupScreen(),
          '/home': (context) => const MainNavigationScreen(),
          '/landing': (context) => const LandingPage(),
        },
      );
  }
}

// New widget to determine initial route based on user state
class AppInitializer extends StatelessWidget {
  const AppInitializer({super.key});

  @override
  Widget build(BuildContext context) {
    // DEBUG: Force show onboarding flow
    if (kForceShowOnboarding) {
      return const LandingPage();
    }
    
    // Check if user has paid subscription
    final hasPaid = UserService.hasPaidSubscription();
    
    // If user has paid, go straight to main navigation
    if (hasPaid) {
      return const MainNavigationScreen();
    }
    
    // Otherwise show landing page for new users
    return const LandingPage();
  }
}
