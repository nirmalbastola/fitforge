import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../../data/providers.dart';

final workoutProvider =
    FutureProvider.family<Workout?, int>((ref, id) async {
  final db = ref.watch(dbProvider);
  return db.workoutDao.getWorkout(id);
});

final setsForWorkoutProvider =
    StreamProvider.family<List<WorkoutSet>, int>((ref, workoutId) {
  final db = ref.watch(dbProvider);
  return db.setDao.watchSetsForWorkout(workoutId);
});

final exerciseByIdProvider =
    FutureProvider.family<Exercise?, int>((ref, id) async {
  final db = ref.watch(dbProvider);
  return db.exerciseDao.getById(id);
});

class PreviousBestArgs {
  final int exerciseId;
  final int beforeWorkoutId;
  const PreviousBestArgs(this.exerciseId, this.beforeWorkoutId);

  @override
  bool operator ==(Object other) =>
      other is PreviousBestArgs &&
      other.exerciseId == exerciseId &&
      other.beforeWorkoutId == beforeWorkoutId;

  @override
  int get hashCode => Object.hash(exerciseId, beforeWorkoutId);
}

final previousBestProvider =
    FutureProvider.family<WorkoutSet?, PreviousBestArgs>((ref, args) async {
  final db = ref.watch(dbProvider);
  return db.setDao.previousBest(
    exerciseId: args.exerciseId,
    beforeWorkoutId: args.beforeWorkoutId,
  );
});

final previousWorkoutSetsProvider =
    FutureProvider.family<List<WorkoutSet>, PreviousBestArgs>((ref, args) async {
  final db = ref.watch(dbProvider);
  final history = (await db.setDao.historyForExercise(args.exerciseId))
      .where((s) => s.workoutId != args.beforeWorkoutId)
      .toList();
  if (history.isEmpty) return const [];
  history.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  final lastWorkoutId = history.first.workoutId;
  return history.where((s) => s.workoutId == lastWorkoutId).toList()
    ..sort((a, b) => a.setIndex.compareTo(b.setIndex));
});
