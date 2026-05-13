import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/dao/plan_dao.dart';
import '../../data/db/app_database.dart';
import '../../data/providers.dart';

final allPlansProvider = StreamProvider<List<Plan>>((ref) {
  return ref.watch(dbProvider).planDao.watchAllPlans();
});

final activePlanProvider = FutureProvider<Plan?>((ref) async {
  return ref.watch(dbProvider).planDao.activePlan();
});

final daysForPlanProvider =
    StreamProvider.family<List<PlanDay>, int>((ref, planId) {
  return ref.watch(dbProvider).planDao.watchDaysForPlan(planId);
});

final exercisesForDayProvider = StreamProvider.family<
    List<PlanExerciseWithDetails>, int>((ref, dayId) {
  return ref.watch(dbProvider).planDao.watchExercisesForDay(dayId);
});
