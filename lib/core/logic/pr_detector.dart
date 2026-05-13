import '../../data/dao/record_dao.dart';
import '../../data/db/app_database.dart';
import 'pr_calculator.dart';

class PrDetector {
  final AppDatabase db;
  const PrDetector(this.db);

  /// Compares this set against historical bests for [exerciseId] (excluding [excludeWorkoutId]).
  /// Records any new PRs and returns the events for UI feedback.
  Future<List<PrEvent>> evaluateSet({
    required int exerciseId,
    required int workoutId,
    required double weight,
    required int reps,
  }) async {
    if (weight <= 0 && reps <= 0) return const [];

    final history = (await db.setDao.historyForExercise(exerciseId))
        .where((s) => s.workoutId != workoutId)
        .toList();

    final priorTopWeight = history.isEmpty
        ? 0.0
        : history.map((s) => s.weight).reduce((a, b) => a > b ? a : b);
    final priorTopReps = history.isEmpty
        ? 0
        : history.map((s) => s.reps).reduce((a, b) => a > b ? a : b);
    final priorTopVolume = history.isEmpty
        ? 0.0
        : history
            .map((s) => PrCalculator.setVolume(s.weight, s.reps))
            .reduce((a, b) => a > b ? a : b);
    final priorTopE1rm = history.isEmpty
        ? 0.0
        : history
            .map((s) => PrCalculator.estimated1RM(s.weight, s.reps))
            .reduce((a, b) => a > b ? a : b);

    final volume = PrCalculator.setVolume(weight, reps);
    final e1rm = PrCalculator.estimated1RM(weight, reps);

    final events = <PrEvent>[];

    if (weight > priorTopWeight) {
      events.add(PrEvent(
        kind: PrKind.weight,
        newValue: weight,
        previousValue: priorTopWeight,
      ));
      await db.recordDao.insert(
        exerciseId: exerciseId,
        type: recordTypeWeight,
        value: weight,
        reps: reps,
        weight: weight,
        workoutId: workoutId,
      );
    }
    if (reps > priorTopReps) {
      events.add(PrEvent(
        kind: PrKind.reps,
        newValue: reps.toDouble(),
        previousValue: priorTopReps.toDouble(),
      ));
      await db.recordDao.insert(
        exerciseId: exerciseId,
        type: recordTypeReps,
        value: reps.toDouble(),
        reps: reps,
        weight: weight,
        workoutId: workoutId,
      );
    }
    if (volume > priorTopVolume) {
      events.add(PrEvent(
        kind: PrKind.volume,
        newValue: volume,
        previousValue: priorTopVolume,
      ));
      await db.recordDao.insert(
        exerciseId: exerciseId,
        type: recordTypeVolume,
        value: volume,
        reps: reps,
        weight: weight,
        workoutId: workoutId,
      );
    }
    if (e1rm > priorTopE1rm) {
      events.add(PrEvent(
        kind: PrKind.e1rm,
        newValue: e1rm,
        previousValue: priorTopE1rm,
      ));
      await db.recordDao.insert(
        exerciseId: exerciseId,
        type: recordTypeE1rm,
        value: e1rm,
        reps: reps,
        weight: weight,
        workoutId: workoutId,
      );
    }

    return events;
  }
}
