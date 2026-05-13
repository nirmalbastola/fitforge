import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';
import '../dao/workout_dao.dart';
import '../dao/exercise_dao.dart';
import '../dao/set_dao.dart';
import '../dao/plan_dao.dart';
import '../dao/record_dao.dart';
import '../dao/check_in_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Workouts,
    Exercises,
    WorkoutSets,
    Plans,
    PlanDays,
    PlanExercises,
    Records,
    DailyCheckIns,
  ],
  daos: [WorkoutDao, ExerciseDao, SetDao, PlanDao, RecordDao, CheckInDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_open());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedExercises();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(exercises, exercises.defaultRestSec);
            await m.addColumn(workouts, workouts.planDayId);
            await m.addColumn(workouts, workouts.notes);
            await m.addColumn(workoutSets, workoutSets.notes);
            await m.createTable(plans);
            await m.createTable(planDays);
            await m.createTable(planExercises);
            await m.createTable(records);
          }
          if (from < 3) {
            await m.createTable(dailyCheckIns);
          }
        },
      );

  Future<void> _seedExercises() async {
    final seed = <({String name, String group, int rest})>[
      (name: 'Bench Press', group: 'Chest', rest: 120),
      (name: 'Incline Dumbbell Press', group: 'Chest', rest: 90),
      (name: 'Cable Fly', group: 'Chest', rest: 60),
      (name: 'Pull Up', group: 'Back', rest: 120),
      (name: 'Barbell Row', group: 'Back', rest: 120),
      (name: 'Lat Pulldown', group: 'Back', rest: 90),
      (name: 'Deadlift', group: 'Back', rest: 180),
      (name: 'Squat', group: 'Legs', rest: 180),
      (name: 'Leg Press', group: 'Legs', rest: 120),
      (name: 'Romanian Deadlift', group: 'Legs', rest: 120),
      (name: 'Leg Curl', group: 'Legs', rest: 60),
      (name: 'Leg Extension', group: 'Legs', rest: 60),
      (name: 'Overhead Press', group: 'Shoulders', rest: 120),
      (name: 'Lateral Raise', group: 'Shoulders', rest: 45),
      (name: 'Face Pull', group: 'Shoulders', rest: 60),
      (name: 'Barbell Curl', group: 'Arms', rest: 60),
      (name: 'Hammer Curl', group: 'Arms', rest: 60),
      (name: 'Tricep Pushdown', group: 'Arms', rest: 60),
      (name: 'Skull Crusher', group: 'Arms', rest: 60),
      (name: 'Plank', group: 'Core', rest: 45),
      (name: 'Cable Crunch', group: 'Core', rest: 45),
      (name: 'Hanging Leg Raise', group: 'Core', rest: 60),
    ];
    for (final e in seed) {
      await into(exercises).insert(
        ExercisesCompanion.insert(
          name: e.name,
          muscleGroup: e.group,
          defaultRestSec: Value(e.rest),
        ),
      );
    }
  }
}

QueryExecutor _open() {
  return driftDatabase(name: 'fitforge_db');
}
