import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'user_service.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static void Function(String? payload)? onNotificationTap;

  static const _workoutChannelId = 'workout_reminder';
  static const _sleepChannelId = 'sleep_log_reminder';
  static const _workoutNotificationId = 1;
  static const _sleepNotificationId = 2;

  static Future<void> init() async {
    tzdata.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        onNotificationTap?.call(response.payload);
      },
    );
  }

  static Future<bool> requestPermission() async {
    if (Platform.isIOS) {
      final result = await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return result ?? false;
    }
    if (Platform.isAndroid) {
      final result = await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      return result ?? false;
    }
    return false;
  }

  static Future<void> scheduleDailyWorkoutReminder() async {
    final user = UserService.getCurrentUser();
    final hour = _workoutTimeToHour(user.preferredWorkoutTime);

    await _plugin.zonedSchedule(
      id: _workoutNotificationId,
      title: 'Time to train',
      body: 'Your workout is waiting. Let\'s go.',
      scheduledDate: _nextInstance(hour, 0),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _workoutChannelId,
          'Workout Reminders',
          channelDescription: 'Daily workout reminder',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'workout',
    );
  }

  static Future<void> scheduleSleepLogReminder() async {
    final user = UserService.getCurrentUser();
    final hour = user.wakeHour ?? 8;
    final extraMinutes = (user.wakeMinute ?? 0) + 15;

    await _plugin.zonedSchedule(
      id: _sleepNotificationId,
      title: 'Log your sleep',
      body: 'How did you sleep last night?',
      scheduledDate:
          _nextInstance(hour + extraMinutes ~/ 60, extraMinutes % 60),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _sleepChannelId,
          'Sleep Reminders',
          channelDescription: 'Daily sleep log reminder',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'sleep_log',
    );
  }

  static int _workoutTimeToHour(String? time) {
    switch (time?.toLowerCase()) {
      case 'morning':
        return 8;
      case 'afternoon':
        return 13;
      case 'evening':
        return 17;
      case 'night':
        return 20;
      default:
        return 9;
    }
  }

  static tz.TZDateTime _nextInstance(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
