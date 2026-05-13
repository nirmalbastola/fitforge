import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/dao/check_in_dao.dart';
import '../../data/db/app_database.dart';
import '../../data/providers.dart';

final todayCheckInProvider = StreamProvider<DailyCheckIn?>((ref) {
  return ref.watch(dbProvider).checkInDao.watchToday();
});

final streakProvider = FutureProvider<CheckInStreak>((ref) {
  return ref.watch(dbProvider).checkInDao.streak();
});

final recentCheckInsProvider = FutureProvider<List<DailyCheckIn>>((ref) {
  return ref.watch(dbProvider).checkInDao.recent(limit: 14);
});
