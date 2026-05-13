import 'package:drift/drift.dart';

import '../db/app_database.dart';
import '../db/tables.dart';

part 'workout_dao.g.dart';

@DriftAccessor(tables: [Workouts, WorkoutSets, Exercises])
class WorkoutDao extends DatabaseAccessor<AppDatabase> with _$WorkoutDaoMixin {
  WorkoutDao(super.db);

  Future<int> startWorkout({String title = 'Workout'}) {
    return into(workouts).insert(
      WorkoutsCompanion.insert(
        title: Value(title),
        startedAt: DateTime.now(),
      ),
    );
  }

  Future<int> startWorkoutFromPlanDay({
    required String title,
    required int planDayId,
  }) {
    return into(workouts).insert(
      WorkoutsCompanion.insert(
        title: Value(title),
        startedAt: DateTime.now(),
        planDayId: Value(planDayId),
      ),
    );
  }

  Future<void> setNotes(int workoutId, String? notes) {
    return (update(workouts)..where((t) => t.id.equals(workoutId)))
        .write(WorkoutsCompanion(notes: Value(notes)));
  }

  Future<void> finishWorkout(int workoutId) async {
    final now = DateTime.now();
    final w = await (select(workouts)..where((t) => t.id.equals(workoutId)))
        .getSingle();
    final duration = now.difference(w.startedAt).inSeconds;
    await (update(workouts)..where((t) => t.id.equals(workoutId))).write(
      WorkoutsCompanion(
        endedAt: Value(now),
        durationSec: Value(duration),
      ),
    );
  }

  Future<void> renameWorkout(int workoutId, String title) {
    return (update(workouts)..where((t) => t.id.equals(workoutId)))
        .write(WorkoutsCompanion(title: Value(title)));
  }

  Future<void> deleteWorkout(int workoutId) {
    return (delete(workouts)..where((t) => t.id.equals(workoutId))).go();
  }

  Future<Workout?> getWorkout(int workoutId) {
    return (select(workouts)..where((t) => t.id.equals(workoutId)))
        .getSingleOrNull();
  }

  Future<List<Workout>> recentWorkouts({int limit = 3}) {
    return (select(workouts)
          ..where((t) => t.endedAt.isNotNull())
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
          ..limit(limit))
        .get();
  }

  Stream<List<Workout>> watchAllFinished() {
    return (select(workouts)
          ..where((t) => t.endedAt.isNotNull())
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
        .watch();
  }

  Future<int> countThisWeek() async {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final rows = await (select(workouts)
          ..where((t) =>
              t.endedAt.isNotNull() & t.startedAt.isBiggerOrEqualValue(monday)))
        .get();
    return rows.length;
  }

  Future<int> countAll() async {
    final rows =
        await (select(workouts)..where((t) => t.endedAt.isNotNull())).get();
    return rows.length;
  }

  Future<double> totalVolume() async {
    final all = await select(workoutSets).get();
    double sum = 0;
    for (final s in all) {
      if (s.done) sum += s.weight * s.reps;
    }
    return sum;
  }

  Future<double> volumeForWorkout(int workoutId) async {
    final rows = await (select(workoutSets)
          ..where((t) => t.workoutId.equals(workoutId)))
        .get();
    double sum = 0;
    for (final s in rows) {
      if (s.done) sum += s.weight * s.reps;
    }
    return sum;
  }
}
