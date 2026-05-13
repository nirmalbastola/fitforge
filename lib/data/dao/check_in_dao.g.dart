// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'check_in_dao.dart';

// ignore_for_file: type=lint
mixin _$CheckInDaoMixin on DatabaseAccessor<AppDatabase> {
  $DailyCheckInsTable get dailyCheckIns => attachedDatabase.dailyCheckIns;
  CheckInDaoManager get managers => CheckInDaoManager(this);
}

class CheckInDaoManager {
  final _$CheckInDaoMixin _db;
  CheckInDaoManager(this._db);
  $$DailyCheckInsTableTableManager get dailyCheckIns =>
      $$DailyCheckInsTableTableManager(_db.attachedDatabase, _db.dailyCheckIns);
}
