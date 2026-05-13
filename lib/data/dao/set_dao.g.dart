// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'set_dao.dart';

// ignore_for_file: type=lint
mixin _$SetDaoMixin on DatabaseAccessor<AppDatabase> {
  $WorkoutsTable get workouts => attachedDatabase.workouts;
  $ExercisesTable get exercises => attachedDatabase.exercises;
  $WorkoutSetsTable get workoutSets => attachedDatabase.workoutSets;
  SetDaoManager get managers => SetDaoManager(this);
}

class SetDaoManager {
  final _$SetDaoMixin _db;
  SetDaoManager(this._db);
  $$WorkoutsTableTableManager get workouts =>
      $$WorkoutsTableTableManager(_db.attachedDatabase, _db.workouts);
  $$ExercisesTableTableManager get exercises =>
      $$ExercisesTableTableManager(_db.attachedDatabase, _db.exercises);
  $$WorkoutSetsTableTableManager get workoutSets =>
      $$WorkoutSetsTableTableManager(_db.attachedDatabase, _db.workoutSets);
}
