import 'package:drift/drift.dart';

class Workouts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withDefault(const Constant('Workout'))();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  IntColumn get durationSec => integer().withDefault(const Constant(0))();
  IntColumn get planDayId => integer().nullable()();
  TextColumn get notes => text().nullable()();
}

class Exercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get muscleGroup => text()();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
  IntColumn get defaultRestSec => integer().nullable()();
}

class WorkoutSets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get workoutId =>
      integer().references(Workouts, #id, onDelete: KeyAction.cascade)();
  IntColumn get exerciseId => integer().references(Exercises, #id)();
  IntColumn get setIndex => integer()();
  RealColumn get weight => real().withDefault(const Constant(0))();
  IntColumn get reps => integer().withDefault(const Constant(0))();
  BoolColumn get done => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get notes => text().nullable()();
}

class Plans extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isActive => boolean().withDefault(const Constant(false))();
}

class PlanDays extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get planId =>
      integer().references(Plans, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  IntColumn get dayOrder => integer()();
}

class PlanExercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get planDayId =>
      integer().references(PlanDays, #id, onDelete: KeyAction.cascade)();
  IntColumn get exerciseId => integer().references(Exercises, #id)();
  IntColumn get targetSets => integer().withDefault(const Constant(3))();
  IntColumn get targetRepsMin => integer().withDefault(const Constant(8))();
  IntColumn get targetRepsMax => integer().withDefault(const Constant(12))();
  IntColumn get exerciseOrder => integer()();
}

/// One row per calendar day the user checks in.
/// status: 'trained' | 'rest' | 'skipped'.
class DailyCheckIns extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get dateKey => text().unique()(); // 'YYYY-MM-DD' local
  TextColumn get status => text()();
  IntColumn get energy => integer().withDefault(const Constant(3))(); // 1..5
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

/// Cached PRs for fast home/progress reads. Recomputed on workout finish.
class Records extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get exerciseId => integer().references(Exercises, #id)();
  TextColumn get type => text()(); // 'weight' | 'reps' | 'volume' | 'e1rm'
  RealColumn get value => real()();
  IntColumn get reps => integer().nullable()();
  RealColumn get weight => real().nullable()();
  DateTimeColumn get achievedAt => dateTime()();
  IntColumn get workoutId => integer().nullable()();
}
