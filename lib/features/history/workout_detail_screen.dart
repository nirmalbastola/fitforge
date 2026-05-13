import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/db/app_database.dart';
import '../../data/providers.dart';

class WorkoutDetailScreen extends ConsumerWidget {
  final int workoutId;
  const WorkoutDetailScreen({super.key, required this.workoutId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(dbProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Workout')),
      body: FutureBuilder<_DetailData>(
        future: _load(db),
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final d = snap.data!;
          if (d.workout == null) {
            return const Center(child: Text('Workout not found'));
          }
          final w = d.workout!;
          final dateStr =
              DateFormat('EEEE, MMM d, y · h:mm a').format(w.startedAt);
          final mins = (w.durationSec / 60).round();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(w.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(dateStr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _StatChip(label: 'Duration', value: '$mins min'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatChip(
                        label: 'Volume',
                        value: _fmtVolume(d.totalVolume)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatChip(
                        label: 'Sets',
                        value: '${d.sets.where((s) => s.done).length}'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ...d.byExercise.entries.map((entry) {
                final ex = d.exerciseNames[entry.key] ?? 'Exercise';
                final muscle = d.exerciseGroups[entry.key] ?? '';
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ex,
                            style: Theme.of(context).textTheme.titleMedium),
                        if (muscle.isNotEmpty)
                          Text(muscle,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant)),
                        const SizedBox(height: 8),
                        ...entry.value.map((s) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 32,
                                    child: Text('${s.setIndex}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600)),
                                  ),
                                  Text(
                                      '${_fmtWeight(s.weight)}  ×  ${s.reps} reps'),
                                  const Spacer(),
                                  if (s.done)
                                    Icon(Icons.check_circle,
                                        size: 16,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Future<_DetailData> _load(AppDatabase db) async {
    final w = await db.workoutDao.getWorkout(workoutId);
    final sets = await db.setDao.setsForWorkout(workoutId);
    final byExercise = <int, List<WorkoutSet>>{};
    for (final s in sets) {
      byExercise.putIfAbsent(s.exerciseId, () => []).add(s);
    }
    final names = <int, String>{};
    final groups = <int, String>{};
    for (final id in byExercise.keys) {
      final e = await db.exerciseDao.getById(id);
      if (e != null) {
        names[id] = e.name;
        groups[id] = e.muscleGroup;
      }
    }
    double vol = 0;
    for (final s in sets) {
      if (s.done) vol += s.weight * s.reps;
    }
    return _DetailData(
      workout: w,
      sets: sets,
      byExercise: byExercise,
      exerciseNames: names,
      exerciseGroups: groups,
      totalVolume: vol,
    );
  }

  static String _fmtWeight(double w) {
    if (w == w.truncateToDouble()) return '${w.toStringAsFixed(0)}kg';
    return '${w.toStringAsFixed(1)}kg';
  }

  static String _fmtVolume(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }
}

class _DetailData {
  final Workout? workout;
  final List<WorkoutSet> sets;
  final Map<int, List<WorkoutSet>> byExercise;
  final Map<int, String> exerciseNames;
  final Map<int, String> exerciseGroups;
  final double totalVolume;
  const _DetailData({
    required this.workout,
    required this.sets,
    required this.byExercise,
    required this.exerciseNames,
    required this.exerciseGroups,
    required this.totalVolume,
  });
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.titleMedium),
            ),
          ],
        ),
      ),
    );
  }
}
