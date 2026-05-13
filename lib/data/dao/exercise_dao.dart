import 'package:drift/drift.dart';

import '../db/app_database.dart';
import '../db/tables.dart';

part 'exercise_dao.g.dart';

@DriftAccessor(tables: [Exercises])
class ExerciseDao extends DatabaseAccessor<AppDatabase>
    with _$ExerciseDaoMixin {
  ExerciseDao(super.db);

  Future<List<Exercise>> getAll() {
    return (select(exercises)
          ..orderBy([(t) => OrderingTerm(expression: t.name)]))
        .get();
  }

  Stream<List<Exercise>> watchAll() {
    return (select(exercises)
          ..orderBy([(t) => OrderingTerm(expression: t.name)]))
        .watch();
  }

  Future<List<Exercise>> search(String query) {
    final q = '%${query.toLowerCase()}%';
    return (select(exercises)
          ..where((t) => t.name.lower().like(q))
          ..orderBy([(t) => OrderingTerm(expression: t.name)]))
        .get();
  }

  Future<List<Exercise>> byGroup(String group) {
    return (select(exercises)
          ..where((t) => t.muscleGroup.equals(group))
          ..orderBy([(t) => OrderingTerm(expression: t.name)]))
        .get();
  }

  Future<Exercise?> getById(int id) {
    return (select(exercises)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> addExercise({required String name, required String group}) {
    return into(exercises).insert(
      ExercisesCompanion.insert(
        name: name,
        muscleGroup: group,
        isCustom: const Value(true),
      ),
    );
  }
}
