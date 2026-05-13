import 'package:drift/drift.dart';

import '../db/app_database.dart';
import '../db/tables.dart';

part 'check_in_dao.g.dart';

const checkInTrained = 'trained';
const checkInRest = 'rest';
const checkInSkipped = 'skipped';

class CheckInStreak {
  final int current;
  final int longest;
  final int thisWeek;
  const CheckInStreak({
    required this.current,
    required this.longest,
    required this.thisWeek,
  });
}

@DriftAccessor(tables: [DailyCheckIns])
class CheckInDao extends DatabaseAccessor<AppDatabase> with _$CheckInDaoMixin {
  CheckInDao(super.db);

  static String dateKeyFor(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  Future<DailyCheckIn?> forDate(DateTime d) {
    return (select(dailyCheckIns)..where((t) => t.dateKey.equals(dateKeyFor(d))))
        .getSingleOrNull();
  }

  Stream<DailyCheckIn?> watchForDate(DateTime d) {
    return (select(dailyCheckIns)..where((t) => t.dateKey.equals(dateKeyFor(d))))
        .watchSingleOrNull();
  }

  Future<DailyCheckIn?> today() => forDate(DateTime.now());
  Stream<DailyCheckIn?> watchToday() => watchForDate(DateTime.now());

  Future<void> upsert({
    required DateTime date,
    required String status,
    int energy = 3,
    String? note,
  }) async {
    final key = dateKeyFor(date);
    final existing = await (select(dailyCheckIns)
          ..where((t) => t.dateKey.equals(key)))
        .getSingleOrNull();
    if (existing == null) {
      await into(dailyCheckIns).insert(
        DailyCheckInsCompanion.insert(
          dateKey: key,
          status: status,
          energy: Value(energy),
          note: Value(note),
          createdAt: DateTime.now(),
        ),
      );
    } else {
      await (update(dailyCheckIns)..where((t) => t.dateKey.equals(key))).write(
        DailyCheckInsCompanion(
          status: Value(status),
          energy: Value(energy),
          note: Value(note),
        ),
      );
    }
  }

  Future<void> deleteForDate(DateTime d) {
    return (delete(dailyCheckIns)
          ..where((t) => t.dateKey.equals(dateKeyFor(d))))
        .go();
  }

  Future<List<DailyCheckIn>> recent({int limit = 30}) {
    return (select(dailyCheckIns)
          ..orderBy([(t) => OrderingTerm.desc(t.dateKey)])
          ..limit(limit))
        .get();
  }

  /// Streak rules:
  ///  - "trained" or "rest" continues the streak.
  ///  - "skipped" or a missing day breaks it.
  /// Today not yet checked in does NOT break the streak (keep yesterday's).
  Future<CheckInStreak> streak() async {
    final all = await (select(dailyCheckIns)
          ..orderBy([(t) => OrderingTerm.desc(t.dateKey)]))
        .get();
    if (all.isEmpty) {
      return const CheckInStreak(current: 0, longest: 0, thisWeek: 0);
    }

    final byKey = {for (final c in all) c.dateKey: c};
    final today = DateTime.now();
    final todayKey = dateKeyFor(today);

    DateTime cursor = today;
    if (!byKey.containsKey(todayKey)) {
      cursor = today.subtract(const Duration(days: 1));
    }

    int current = 0;
    while (true) {
      final key = dateKeyFor(cursor);
      final c = byKey[key];
      if (c == null) break;
      if (c.status == checkInSkipped) break;
      current++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    int longest = 0;
    int run = 0;
    final sortedAsc = all.reversed.toList();
    DateTime? prev;
    for (final c in sortedAsc) {
      final parts = c.dateKey.split('-').map(int.parse).toList();
      final d = DateTime(parts[0], parts[1], parts[2]);
      if (c.status == checkInSkipped) {
        run = 0;
        prev = d;
        continue;
      }
      if (prev == null || d.difference(prev).inDays == 1) {
        run++;
      } else {
        run = 1;
      }
      if (run > longest) longest = run;
      prev = d;
    }

    final monday = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: today.weekday - 1));
    int thisWeek = 0;
    for (var i = 0; i < 7; i++) {
      final d = monday.add(Duration(days: i));
      final c = byKey[dateKeyFor(d)];
      if (c != null && c.status == checkInTrained) thisWeek++;
    }

    return CheckInStreak(
        current: current, longest: longest, thisWeek: thisWeek);
  }
}
