import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'dart:io' show Platform;
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:tiktok_business_sdk/tiktok_business_sdk.dart';
import 'package:tiktok_business_sdk/tiktok_business_sdk_platform_interface.dart';
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
import 'models/class_entry.dart';
import 'services/user_service.dart';
import 'services/workout_service.dart';
import 'services/nutrition_service.dart';
import 'services/auth_service.dart';
import 'services/workout_audio_cache.dart';
import 'services/split_service.dart';
import 'services/class_service.dart';
import 'services/review_service.dart';
import 'services/notification_service.dart';
import 'services/sleep_service.dart';
import 'stores/active_workout_store.dart';
import 'stores/coach_chat_store.dart';
import 'stores/nutrition_store.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
  Hive.registerAdapter(ClassEntryAdapter());
  
  // Initialize services
  await UserService.init();
  await WorkoutService.init();
  await SplitService.init();
  await ClassService.init();
  await ReviewService.init();
  ReviewService.trackAppOpen();
  await SleepService.init();
  await NotificationService.init();
  NotificationService.onNotificationTap = (payload) {
    if (payload == 'sleep_log') {
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const MainNavigationScreen(
            initialTab: 2,
            openSleepTab: true,
          ),
        ),
        (_) => false,
      );
    }
  };
  
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
  
  // Initialize TikTok Business SDK
  await _initTikTokSdk();
  
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
  if (!Platform.isIOS && !Platform.isAndroid) {
    return;
  }
  
  final configuration = PurchasesConfiguration(apiKey);
  await Purchases.configure(configuration);
}

Future<void> _initTikTokSdk() async {
  if (!Platform.isIOS && !Platform.isAndroid) {
    return;
  }
  
  try {
    final tiktokSdk = TiktokBusinessSdk();
    await tiktokSdk.initTiktokBusinessSdk(
      accessToken: dotenv.env['TIKTOK_ACCESS_TOKEN'] ?? '',
      appId: dotenv.env['TIKTOK_APP_ID'] ?? '',
      ttAppId: dotenv.env['TIKTOK_TT_APP_ID'] ?? '',
      enableAutoIapTrack: true,
    );
    
    tiktokSdk.trackTTEvent(event: EventName.LaunchApp);
  } catch (e) {
    debugPrint('TikTok SDK init failed: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppColors.themeNotifier,
      builder: (context, isDark, _) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'echelon',
          theme: ThemeData(
            scaffoldBackgroundColor: AppColors.background,
            colorScheme: isDark
                ? ColorScheme.dark(
                    surface: AppColors.background,
                    primary: AppColors.textPrimary,
                    onSurface: AppColors.textPrimary,
                  )
                : ColorScheme.light(
                    surface: AppColors.background,
                    primary: AppColors.textPrimary,
                    onSurface: AppColors.textPrimary,
                  ),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            splashFactory: NoSplash.splashFactory,
          ),
          home: const AppInitializer(),
          routes: {
            '/onboarding': (context) => const OnboardingFlow(),
            '/nutrition_goal_setup': (context) => const NutritionGoalSetupScreen(),
            '/home': (context) => const MainNavigationScreen(),
            '/landing': (context) => const LandingPage(),
          },
        );
      },
    );
  }
}

// New widget to determine initial route based on user state
class AppInitializer extends StatelessWidget {
  const AppInitializer({super.key});

  static const bool kForceOnboarding = false;

  @override
  Widget build(BuildContext context) {  
    if (kForceOnboarding) {
      return const LandingPage();
    }

    final hasPaid = UserService.hasPaidSubscription();

    if (hasPaid) {
      return const MainNavigationScreen();
    }

    return const LandingPage();
  }
}
