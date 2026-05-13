import 'package:drift/drift.dart';

import '../db/app_database.dart';
import '../db/tables.dart';

part 'set_dao.g.dart';

@DriftAccessor(tables: [WorkoutSets, Exercises, Workouts])
class SetDao extends DatabaseAccessor<AppDatabase> with _$SetDaoMixin {
  SetDao(super.db);

  Future<int> addSet({
    required int workoutId,
    required int exerciseId,
    required int setIndex,
    double weight = 0,
    int reps = 0,
  }) {
    return into(workoutSets).insert(
      WorkoutSetsCompanion.insert(
        workoutId: workoutId,
        exerciseId: exerciseId,
        setIndex: setIndex,
        weight: Value(weight),
        reps: Value(reps),
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> updateSet({
    required int id,
    double? weight,
    int? reps,
    bool? done,
  }) {
    return (update(workoutSets)..where((t) => t.id.equals(id))).write(
      WorkoutSetsCompanion(
        weight: weight == null ? const Value.absent() : Value(weight),
        reps: reps == null ? const Value.absent() : Value(reps),
        done: done == null ? const Value.absent() : Value(done),
      ),
    );
  }

  Future<void> deleteSet(int id) {
    return (delete(workoutSets)..where((t) => t.id.equals(id))).go();
  }

  Future<List<WorkoutSet>> setsForWorkout(int workoutId) {
    return (select(workoutSets)
          ..where((t) => t.workoutId.equals(workoutId))
          ..orderBy([(t) => OrderingTerm(expression: t.id)]))
        .get();
  }

  Stream<List<WorkoutSet>> watchSetsForWorkout(int workoutId) {
    return (select(workoutSets)
          ..where((t) => t.workoutId.equals(workoutId))
          ..orderBy([(t) => OrderingTerm(expression: t.id)]))
        .watch();
  }

  /// Last completed set for an exercise, prior to a given workout.
  Future<WorkoutSet?> previousBest({
    required int exerciseId,
    required int beforeWorkoutId,
  }) async {
    final query = select(workoutSets)
      ..where((t) =>
          t.exerciseId.equals(exerciseId) &
          t.done.equals(true) &
          t.workoutId.isNotValue(beforeWorkoutId))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(1);
    return query.getSingleOrNull();
  }

  Future<List<WorkoutSet>> historyForExercise(int exerciseId) {
    return (select(workoutSets)
          ..where((t) => t.exerciseId.equals(exerciseId) & t.done.equals(true))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
        .get();
  }
}
