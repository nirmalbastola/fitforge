import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../../data/providers.dart';

class HomeStats {
  final int weekCount;
  final int totalCount;
  final double totalVolume;
  const HomeStats({
    required this.weekCount,
    required this.totalCount,
    required this.totalVolume,
  });
}

final homeStatsProvider = FutureProvider<HomeStats>((ref) async {
  final db = ref.watch(dbProvider);
  final week = await db.workoutDao.countThisWeek();
  final total = await db.workoutDao.countAll();
  final volume = await db.workoutDao.totalVolume();
  return HomeStats(weekCount: week, totalCount: total, totalVolume: volume);
});

final recentWorkoutsProvider = FutureProvider<List<Workout>>((ref) async {
  final db = ref.watch(dbProvider);
  return db.workoutDao.recentWorkouts(limit: 3);
});
