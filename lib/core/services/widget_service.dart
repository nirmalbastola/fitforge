import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import '../../data/db/app_database.dart';

class WidgetService {
  static const _appGroupId = 'com.example.fitforge.widget';
  static const _compactProvider = 'CompactWidgetProvider';
  static const _largeProvider = 'LargeWidgetProvider';

  static Future<void> init() async {
    await HomeWidget.setAppGroupId(_appGroupId);
  }

  static Future<void> refresh(AppDatabase db) async {
    if (!_isAndroid) return;
    try {
      final week = await db.workoutDao.countThisWeek();
      final total = await db.workoutDao.countAll();
      final volume = await db.workoutDao.totalVolume();
      final recent = await db.workoutDao.recentWorkouts(limit: 3);

      await HomeWidget.saveWidgetData<int>('week_count', week);
      await HomeWidget.saveWidgetData<int>('total_count', total);
      await HomeWidget.saveWidgetData<String>(
          'total_volume_pretty', _formatVolume(volume));
      await HomeWidget.saveWidgetData<String>(
          'today_label', DateFormat('MMM d').format(DateTime.now()));

      for (var i = 0; i < 3; i++) {
        final key = 'recent_${i + 1}';
        if (i < recent.length) {
          final w = recent[i];
          final mins = (w.durationSec / 60).round();
          final dateStr = DateFormat('MMM d').format(w.startedAt);
          await HomeWidget.saveWidgetData<String>(
              key, '${w.title}  ·  $dateStr · ${mins}m');
        } else {
          await HomeWidget.saveWidgetData<String>(key, '');
        }
      }

      await HomeWidget.updateWidget(
        name: _compactProvider,
        androidName: _compactProvider,
      );
      await HomeWidget.updateWidget(
        name: _largeProvider,
        androidName: _largeProvider,
      );
    } catch (e) {
      debugPrint('WidgetService.refresh failed: $e');
    }
  }

  static String _formatVolume(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k kg';
    return '${v.toStringAsFixed(0)} kg';
  }

  static bool get _isAndroid =>
      defaultTargetPlatform == TargetPlatform.android && !kIsWeb;
}
