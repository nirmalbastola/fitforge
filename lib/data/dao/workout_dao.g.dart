// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_dao.dart';

// ignore_for_file: type=lint
mixin _$WorkoutDaoMixin on DatabaseAccessor<AppDatabase> {
  $WorkoutsTable get workouts => attachedDatabase.workouts;
  $ExercisesTable get exercises => attachedDatabase.exercises;
  $WorkoutSetsTable get workoutSets => attachedDatabase.workoutSets;
  WorkoutDaoManager get managers => WorkoutDaoManager(this);
}

class WorkoutDaoManager {
  final _$WorkoutDaoMixin _db;
  WorkoutDaoManager(this._db);
  $$WorkoutsTableTableManager get workouts =>
      $$WorkoutsTableTableManager(_db.attachedDatabase, _db.workouts);
  $$ExercisesTableTableManager get exercises =>
      $$ExercisesTableTableManager(_db.attachedDatabase, _db.exercises);
  $$WorkoutSetsTableTableManager get workoutSets =>
      $$WorkoutSetsTableTableManager(_db.attachedDatabase, _db.workoutSets);
}
