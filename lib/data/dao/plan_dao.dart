import 'package:drift/drift.dart';

import '../db/app_database.dart';
import '../db/tables.dart';

part 'plan_dao.g.dart';

class PlanDayWithExercises {
  final PlanDay day;
  final List<PlanExerciseWithDetails> exercises;
  const PlanDayWithExercises({required this.day, required this.exercises});
}

class PlanExerciseWithDetails {
  final PlanExercise pe;
  final Exercise exercise;
  const PlanExerciseWithDetails({required this.pe, required this.exercise});
}

@DriftAccessor(tables: [Plans, PlanDays, PlanExercises, Exercises])
class PlanDao extends DatabaseAccessor<AppDatabase> with _$PlanDaoMixin {
  PlanDao(super.db);

  // ---------- Plans ----------

  Stream<List<Plan>> watchAllPlans() {
    return (select(plans)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Future<List<Plan>> allPlans() {
    return (select(plans)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  Future<Plan?> getPlan(int id) {
    return (select(plans)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> createPlan(String name) {
    return into(plans).insert(
      PlansCompanion.insert(name: name, createdAt: DateTime.now()),
    );
  }

  Future<void> renamePlan(int planId, String name) {
    return (update(plans)..where((t) => t.id.equals(planId)))
        .write(PlansCompanion(name: Value(name)));
  }

  Future<void> deletePlan(int planId) {
    return (delete(plans)..where((t) => t.id.equals(planId))).go();
  }

  Future<Plan?> activePlan() {
    return (select(plans)..where((t) => t.isActive.equals(true)))
        .getSingleOrNull();
  }

  Future<void> setActivePlan(int? planId) async {
    await transaction(() async {
      await update(plans).write(const PlansCompanion(isActive: Value(false)));
      if (planId != null) {
        await (update(plans)..where((t) => t.id.equals(planId)))
            .write(const PlansCompanion(isActive: Value(true)));
      }
    });
  }

  // ---------- Plan Days ----------

  Future<List<PlanDay>> daysForPlan(int planId) {
    return (select(planDays)
          ..where((t) => t.planId.equals(planId))
          ..orderBy([(t) => OrderingTerm(expression: t.dayOrder)]))
        .get();
  }

  Stream<List<PlanDay>> watchDaysForPlan(int planId) {
    return (select(planDays)
          ..where((t) => t.planId.equals(planId))
          ..orderBy([(t) => OrderingTerm(expression: t.dayOrder)]))
        .watch();
  }

  Future<int> addDay(int planId, String name) async {
    final existing = await daysForPlan(planId);
    return into(planDays).insert(
      PlanDaysCompanion.insert(
        planId: planId,
        name: name,
        dayOrder: existing.length,
      ),
    );
  }

  Future<void> renameDay(int dayId, String name) {
    return (update(planDays)..where((t) => t.id.equals(dayId)))
        .write(PlanDaysCompanion(name: Value(name)));
  }

  Future<void> deleteDay(int dayId) {
    return (delete(planDays)..where((t) => t.id.equals(dayId))).go();
  }

  Future<PlanDay?> getDay(int dayId) {
    return (select(planDays)..where((t) => t.id.equals(dayId)))
        .getSingleOrNull();
  }

  // ---------- Plan Exercises ----------

  Future<List<PlanExerciseWithDetails>> exercisesForDay(int dayId) async {
    final query = select(planExercises).join([
      innerJoin(exercises, exercises.id.equalsExp(planExercises.exerciseId)),
    ])
      ..where(planExercises.planDayId.equals(dayId))
      ..orderBy([OrderingTerm(expression: planExercises.exerciseOrder)]);

    final rows = await query.get();
    return rows
        .map((r) => PlanExerciseWithDetails(
              pe: r.readTable(planExercises),
              exercise: r.readTable(exercises),
            ))
        .toList();
  }

  Stream<List<PlanExerciseWithDetails>> watchExercisesForDay(int dayId) {
    final query = select(planExercises).join([
      innerJoin(exercises, exercises.id.equalsExp(planExercises.exerciseId)),
    ])
      ..where(planExercises.planDayId.equals(dayId))
      ..orderBy([OrderingTerm(expression: planExercises.exerciseOrder)]);

    return query.watch().map((rows) => rows
        .map((r) => PlanExerciseWithDetails(
              pe: r.readTable(planExercises),
              exercise: r.readTable(exercises),
            ))
        .toList());
  }

  Future<int> addExerciseToDay({
    required int dayId,
    required int exerciseId,
    int targetSets = 3,
    int targetRepsMin = 8,
    int targetRepsMax = 12,
  }) async {
    final existing = await (select(planExercises)
          ..where((t) => t.planDayId.equals(dayId)))
        .get();
    return into(planExercises).insert(
      PlanExercisesCompanion.insert(
        planDayId: dayId,
        exerciseId: exerciseId,
        targetSets: Value(targetSets),
        targetRepsMin: Value(targetRepsMin),
        targetRepsMax: Value(targetRepsMax),
        exerciseOrder: existing.length,
      ),
    );
  }

  Future<void> updatePlanExercise({
    required int id,
    int? targetSets,
    int? targetRepsMin,
    int? targetRepsMax,
  }) {
    return (update(planExercises)..where((t) => t.id.equals(id))).write(
      PlanExercisesCompanion(
        targetSets:
            targetSets == null ? const Value.absent() : Value(targetSets),
        targetRepsMin:
            targetRepsMin == null ? const Value.absent() : Value(targetRepsMin),
        targetRepsMax:
            targetRepsMax == null ? const Value.absent() : Value(targetRepsMax),
      ),
    );
  }

  Future<void> removePlanExercise(int id) {
    return (delete(planExercises)..where((t) => t.id.equals(id))).go();
  }

  Future<void> reorderPlanExercises(List<int> orderedIds) async {
    await transaction(() async {
      for (var i = 0; i < orderedIds.length; i++) {
        await (update(planExercises)..where((t) => t.id.equals(orderedIds[i])))
            .write(PlanExercisesCompanion(exerciseOrder: Value(i)));
      }
    });
  }
}
