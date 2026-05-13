import 'package:drift/drift.dart';

import '../db/app_database.dart';
import '../db/tables.dart';

part 'record_dao.g.dart';

const recordTypeWeight = 'weight';
const recordTypeReps = 'reps';
const recordTypeVolume = 'volume';
const recordTypeE1rm = 'e1rm';

class PrSummary {
  final int exerciseId;
  final double topWeight;
  final int topReps;
  final double topVolume;
  final double topE1rm;
  final DateTime achievedAt;
  const PrSummary({
    required this.exerciseId,
    required this.topWeight,
    required this.topReps,
    required this.topVolume,
    required this.topE1rm,
    required this.achievedAt,
  });
}

@DriftAccessor(tables: [Records])
class RecordDao extends DatabaseAccessor<AppDatabase> with _$RecordDaoMixin {
  RecordDao(super.db);

  Future<List<Record>> all() {
    return (select(records)
          ..orderBy([(t) => OrderingTerm.desc(t.achievedAt)]))
        .get();
  }

  Future<Record?> bestForExercise({
    required int exerciseId,
    required String type,
  }) {
    return (select(records)
          ..where((t) => t.exerciseId.equals(exerciseId) & t.type.equals(type))
          ..orderBy([(t) => OrderingTerm.desc(t.value)])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<int> insert({
    required int exerciseId,
    required String type,
    required double value,
    int? reps,
    double? weight,
    int? workoutId,
  }) {
    return into(records).insert(
      RecordsCompanion.insert(
        exerciseId: exerciseId,
        type: type,
        value: value,
        reps: Value(reps),
        weight: Value(weight),
        achievedAt: DateTime.now(),
        workoutId: Value(workoutId),
      ),
    );
  }

  Future<void> deleteForExercise(int exerciseId) {
    return (delete(records)..where((t) => t.exerciseId.equals(exerciseId)))
        .go();
  }
}
