import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/notification_service.dart';

class ReminderSettings {
  final bool reminderEnabled;
  final int reminderHour;
  final int reminderMinute;
  final Set<int> reminderWeekdays;

  final bool checkInEnabled;
  final int checkInHour;
  final int checkInMinute;

  final int restTimerSeconds;

  const ReminderSettings({
    required this.reminderEnabled,
    required this.reminderHour,
    required this.reminderMinute,
    required this.reminderWeekdays,
    required this.checkInEnabled,
    required this.checkInHour,
    required this.checkInMinute,
    required this.restTimerSeconds,
  });

  ReminderSettings copyWith({
    bool? reminderEnabled,
    int? reminderHour,
    int? reminderMinute,
    Set<int>? reminderWeekdays,
    bool? checkInEnabled,
    int? checkInHour,
    int? checkInMinute,
    int? restTimerSeconds,
  }) {
    return ReminderSettings(
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      reminderWeekdays: reminderWeekdays ?? this.reminderWeekdays,
      checkInEnabled: checkInEnabled ?? this.checkInEnabled,
      checkInHour: checkInHour ?? this.checkInHour,
      checkInMinute: checkInMinute ?? this.checkInMinute,
      restTimerSeconds: restTimerSeconds ?? this.restTimerSeconds,
    );
  }

  TimeOfDay get reminderTime =>
      TimeOfDay(hour: reminderHour, minute: reminderMinute);
  TimeOfDay get checkInTime =>
      TimeOfDay(hour: checkInHour, minute: checkInMinute);

  static const ReminderSettings defaults = ReminderSettings(
    reminderEnabled: false,
    reminderHour: 18,
    reminderMinute: 30,
    reminderWeekdays: {1, 2, 3, 4, 5},
    checkInEnabled: false,
    checkInHour: 8,
    checkInMinute: 0,
    restTimerSeconds: 90,
  );
}

class SettingsNotifier extends AsyncNotifier<ReminderSettings> {
  static const _kReminderEnabled = 'reminder.enabled';
  static const _kReminderHour = 'reminder.hour';
  static const _kReminderMinute = 'reminder.minute';
  static const _kReminderWeekdays = 'reminder.weekdays';

  static const _kCheckInEnabled = 'checkin.enabled';
  static const _kCheckInHour = 'checkin.hour';
  static const _kCheckInMinute = 'checkin.minute';

  static const _kRest = 'rest.seconds';

  late SharedPreferences _prefs;

  @override
  Future<ReminderSettings> build() async {
    _prefs = await SharedPreferences.getInstance();
    final wdRaw = _prefs.getStringList(_kReminderWeekdays);
    final wd = wdRaw == null
        ? ReminderSettings.defaults.reminderWeekdays
        : wdRaw.map(int.parse).toSet();
    return ReminderSettings(
      reminderEnabled: _prefs.getBool(_kReminderEnabled) ??
          ReminderSettings.defaults.reminderEnabled,
      reminderHour: _prefs.getInt(_kReminderHour) ??
          ReminderSettings.defaults.reminderHour,
      reminderMinute: _prefs.getInt(_kReminderMinute) ??
          ReminderSettings.defaults.reminderMinute,
      reminderWeekdays: wd,
      checkInEnabled: _prefs.getBool(_kCheckInEnabled) ??
          ReminderSettings.defaults.checkInEnabled,
      checkInHour: _prefs.getInt(_kCheckInHour) ??
          ReminderSettings.defaults.checkInHour,
      checkInMinute: _prefs.getInt(_kCheckInMinute) ??
          ReminderSettings.defaults.checkInMinute,
      restTimerSeconds:
          _prefs.getInt(_kRest) ?? ReminderSettings.defaults.restTimerSeconds,
    );
  }

  Future<void> _save(ReminderSettings s) async {
    await _prefs.setBool(_kReminderEnabled, s.reminderEnabled);
    await _prefs.setInt(_kReminderHour, s.reminderHour);
    await _prefs.setInt(_kReminderMinute, s.reminderMinute);
    await _prefs.setStringList(_kReminderWeekdays,
        s.reminderWeekdays.map((e) => e.toString()).toList());
    await _prefs.setBool(_kCheckInEnabled, s.checkInEnabled);
    await _prefs.setInt(_kCheckInHour, s.checkInHour);
    await _prefs.setInt(_kCheckInMinute, s.checkInMinute);
    await _prefs.setInt(_kRest, s.restTimerSeconds);
  }

  Future<void> _applyReminder(ReminderSettings s) async {
    if (s.reminderEnabled) {
      await NotificationService.scheduleWorkoutReminder(
        hour: s.reminderHour,
        minute: s.reminderMinute,
        weekdays: s.reminderWeekdays,
      );
    } else {
      await NotificationService.cancelWorkoutReminders();
    }
  }

  Future<void> _applyCheckIn(ReminderSettings s) async {
    if (s.checkInEnabled) {
      await NotificationService.scheduleMorningCheckIn(
        hour: s.checkInHour,
        minute: s.checkInMinute,
      );
    } else {
      await NotificationService.cancelCheckInReminders();
    }
  }

  Future<void> setReminderEnabled(bool enabled) async {
    final cur = state.value ?? ReminderSettings.defaults;
    if (enabled) {
      final granted = await NotificationService.requestPermission();
      if (!granted) {
        state = AsyncData(cur.copyWith(reminderEnabled: false));
        return;
      }
    }
    final next = cur.copyWith(reminderEnabled: enabled);
    state = AsyncData(next);
    await _save(next);
    await _applyReminder(next);
  }

  Future<void> setReminderTime(TimeOfDay t) async {
    final cur = state.value ?? ReminderSettings.defaults;
    final next = cur.copyWith(reminderHour: t.hour, reminderMinute: t.minute);
    state = AsyncData(next);
    await _save(next);
    await _applyReminder(next);
  }

  Future<void> toggleReminderWeekday(int weekday) async {
    final cur = state.value ?? ReminderSettings.defaults;
    final s = Set<int>.from(cur.reminderWeekdays);
    if (!s.remove(weekday)) s.add(weekday);
    final next = cur.copyWith(reminderWeekdays: s);
    state = AsyncData(next);
    await _save(next);
    await _applyReminder(next);
  }

  Future<void> setCheckInEnabled(bool enabled) async {
    final cur = state.value ?? ReminderSettings.defaults;
    if (enabled) {
      final granted = await NotificationService.requestPermission();
      if (!granted) {
        state = AsyncData(cur.copyWith(checkInEnabled: false));
        return;
      }
    }
    final next = cur.copyWith(checkInEnabled: enabled);
    state = AsyncData(next);
    await _save(next);
    await _applyCheckIn(next);
  }

  Future<void> setCheckInTime(TimeOfDay t) async {
    final cur = state.value ?? ReminderSettings.defaults;
    final next = cur.copyWith(checkInHour: t.hour, checkInMinute: t.minute);
    state = AsyncData(next);
    await _save(next);
    await _applyCheckIn(next);
  }

  Future<void> setRestTimer(int seconds) async {
    final cur = state.value ?? ReminderSettings.defaults;
    final next = cur.copyWith(restTimerSeconds: seconds);
    state = AsyncData(next);
    await _save(next);
  }
}

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, ReminderSettings>(
        SettingsNotifier.new);
