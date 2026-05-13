import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/db/app_database.dart';
import '../../data/providers.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(dbProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: StreamBuilder<List<Workout>>(
        stream: db.workoutDao.watchAllFinished(),
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snap.data!;
          if (list.isEmpty) {
            return const Center(child: Text('No completed workouts yet'));
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: list.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final w = list[i];
              return FutureBuilder<int>(
                future: db.setDao.setsForWorkout(w.id).then(
                      (s) =>
                          s.map((e) => e.exerciseId).toSet().length,
                    ),
                builder: (ctx, exSnap) {
                  final exCount = exSnap.data ?? 0;
                  final dateStr =
                      DateFormat('EEE, MMM d').format(w.startedAt);
                  final mins = (w.durationSec / 60).round();
                  return ListTile(
                    title: Text(w.title,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      '$dateStr  ·  $mins min  ·  $exCount ex',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/history/${w.id}'),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
