import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../../data/providers.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(dbProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: FutureBuilder<_ProgressData>(
        future: _load(db),
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final d = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _Stat(
                        label: 'Total Volume',
                        value: _fmtVol(d.totalVolume)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _Stat(
                        label: 'Workouts',
                        value: '${d.workoutCount}'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _Stat(
                        label: 'PRs',
                        value: '${d.prCount}'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Volume per Workout',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              SizedBox(
                height: 220,
                child: d.volumeSeries.isEmpty
                    ? const Center(child: Text('No data yet'))
                    : _VolumeChart(points: d.volumeSeries),
              ),
              const SizedBox(height: 24),
              Text('Personal Records',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (d.prs.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('No PRs yet'),
                )
              else
                ...d.prs.map((pr) => Card(
                      child: ListTile(
                        title: Text(pr.exerciseName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        subtitle: Text(pr.muscleGroup,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        trailing: Text(
                          '${_fmtWeight(pr.weight)} × ${pr.reps}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                    )),
            ],
          );
        },
      ),
    );
  }

  Future<_ProgressData> _load(AppDatabase db) async {
    final workouts = await db.workoutDao.recentWorkouts(limit: 1000);
    final reversed = workouts.reversed.toList();
    final volumeSeries = <_VolumePoint>[];
    for (final w in reversed) {
      final vol = await db.workoutDao.volumeForWorkout(w.id);
      volumeSeries.add(_VolumePoint(
          date: w.startedAt, volume: vol, label: w.title));
    }

    final exercises = await db.exerciseDao.getAll();
    final prs = <_PR>[];
    for (final ex in exercises) {
      final history = await db.setDao.historyForExercise(ex.id);
      if (history.isEmpty) continue;
      history.sort((a, b) {
        final w = b.weight.compareTo(a.weight);
        if (w != 0) return w;
        return b.reps.compareTo(a.reps);
      });
      final best = history.first;
      if (best.weight == 0 && best.reps == 0) continue;
      prs.add(_PR(
        exerciseName: ex.name,
        muscleGroup: ex.muscleGroup,
        weight: best.weight,
        reps: best.reps,
      ));
    }
    prs.sort((a, b) => b.weight.compareTo(a.weight));

    final totalVolume = volumeSeries.fold<double>(0, (a, b) => a + b.volume);

    return _ProgressData(
      totalVolume: totalVolume,
      workoutCount: workouts.length,
      prCount: prs.length,
      volumeSeries: volumeSeries,
      prs: prs.take(20).toList(),
    );
  }

  static String _fmtVol(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }

  static String _fmtWeight(double w) {
    if (w == w.truncateToDouble()) return '${w.toStringAsFixed(0)}kg';
    return '${w.toStringAsFixed(1)}kg';
  }
}

class _ProgressData {
  final double totalVolume;
  final int workoutCount;
  final int prCount;
  final List<_VolumePoint> volumeSeries;
  final List<_PR> prs;
  const _ProgressData({
    required this.totalVolume,
    required this.workoutCount,
    required this.prCount,
    required this.volumeSeries,
    required this.prs,
  });
}

class _VolumePoint {
  final DateTime date;
  final double volume;
  final String label;
  const _VolumePoint(
      {required this.date, required this.volume, required this.label});
}

class _PR {
  final String exerciseName;
  final String muscleGroup;
  final double weight;
  final int reps;
  const _PR({
    required this.exerciseName,
    required this.muscleGroup,
    required this.weight,
    required this.reps,
  });
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
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
            const SizedBox(height: 4),
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

class _VolumeChart extends StatelessWidget {
  final List<_VolumePoint> points;
  const _VolumeChart({required this.points});

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    for (var i = 0; i < points.length; i++) {
      spots.add(FlSpot(i.toDouble(), points[i].volume));
    }
    final maxY = points.map((p) => p.volume).fold<double>(0, (a, b) => a > b ? a : b);
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY == 0 ? 1 : maxY * 1.15,
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        titlesData: const FlTitlesData(
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 3,
            color: Theme.of(context).colorScheme.primary,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }
}
