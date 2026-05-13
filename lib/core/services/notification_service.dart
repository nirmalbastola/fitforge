import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'motivation.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _workoutChannelId = 'fitforge_reminders';
  static const _workoutChannelName = 'Workout Reminders';
  static const _workoutChannelDesc = 'Daily reminders to log a workout.';

  static const _checkInChannelId = 'fitforge_checkin';
  static const _checkInChannelName = 'Daily Check-in';
  static const _checkInChannelDesc =
      'Morning prompts to check in and stay accountable.';

  // Notification IDs use disjoint ranges so we can cancel by category cleanly.
  static const _workoutBaseId = 100; // 100 + weekday (1..7)
  static const _checkInBaseId = 200; // 200 + weekday (1..7)

  static Future<void> init() async {
    tz_data.initializeTimeZones();
    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _workoutChannelId,
        _workoutChannelName,
        description: _workoutChannelDesc,
        importance: Importance.high,
      ),
    );
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _checkInChannelId,
        _checkInChannelName,
        description: _checkInChannelDesc,
        importance: Importance.high,
      ),
    );
  }

  static Future<bool> requestPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.notification.request();
      return status.isGranted;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final granted = await ios?.requestPermissions(
        alert: true, badge: true, sound: true);
    return granted ?? false;
  }

  static Future<void> scheduleWorkoutReminder({
    required int hour,
    required int minute,
    required Set<int> weekdays,
    int currentStreak = 0,
  }) async {
    await cancelWorkoutReminders();
    if (weekdays.isEmpty) return;
    for (final wd in weekdays) {
      final msg =
          Motivation.pickWorkoutReminder(currentStreak: currentStreak);
      final scheduledDate = _nextInstanceOfWeekday(wd, hour, minute);
      await _plugin.zonedSchedule(
        _workoutBaseId + wd,
        msg.title,
        msg.body,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _workoutChannelId,
            _workoutChannelName,
            channelDescription: _workoutChannelDesc,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  static Future<void> scheduleMorningCheckIn({
    required int hour,
    required int minute,
    int currentStreak = 0,
    bool hadRecentWorkout = false,
  }) async {
    await cancelCheckInReminders();
    for (var wd = 1; wd <= 7; wd++) {
      final msg = Motivation.pickMorning(
        currentStreak: currentStreak,
        hadRecentWorkout: hadRecentWorkout,
      );
      final scheduledDate = _nextInstanceOfWeekday(wd, hour, minute);
      await _plugin.zonedSchedule(
        _checkInBaseId + wd,
        msg.title,
        msg.body,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _checkInChannelId,
            _checkInChannelName,
            channelDescription: _checkInChannelDesc,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  static Future<void> showImmediate({
    required String title,
    required String body,
    String channel = _checkInChannelId,
  }) {
    final isCheckIn = channel == _checkInChannelId;
    return _plugin.show(
      999,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          isCheckIn ? _checkInChannelId : _workoutChannelId,
          isCheckIn ? _checkInChannelName : _workoutChannelName,
          channelDescription:
              isCheckIn ? _checkInChannelDesc : _workoutChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  static Future<void> cancelWorkoutReminders() async {
    for (var wd = 1; wd <= 7; wd++) {
      await _plugin.cancel(_workoutBaseId + wd);
    }
  }

  static Future<void> cancelCheckInReminders() async {
    for (var wd = 1; wd <= 7; wd++) {
      await _plugin.cancel(_checkInBaseId + wd);
    }
  }

  static Future<void> cancelAll() => _plugin.cancelAll();

  static tz.TZDateTime _nextInstanceOfWeekday(
      int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var next =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    while (next.weekday != weekday || !next.isAfter(now)) {
      next = next.add(const Duration(days: 1));
    }
    return next;
  }
}
