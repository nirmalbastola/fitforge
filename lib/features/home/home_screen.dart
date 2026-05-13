import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/dao/check_in_dao.dart';
import '../../data/db/app_database.dart';
import '../../data/providers.dart';
import '../checkin/checkin_providers.dart';
import 'home_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(homeStatsProvider);
    final recent = ref.watch(recentWorkoutsProvider);
    final streakAsync = ref.watch(streakProvider);
    final todayAsync = ref.watch(todayCheckInProvider);
    final dateStr = DateFormat('EEEE, MMM d').format(DateTime.now());
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(homeStatsProvider);
            ref.invalidate(recentWorkoutsProvider);
            ref.invalidate(streakProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Welcome back',
                            style: theme.textTheme.headlineSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(dateStr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    tooltip: 'Settings',
                    onPressed: () => context.push('/settings'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _CheckInCard(
                today: todayAsync.valueOrNull,
                streak: streakAsync.valueOrNull,
                onTap: () => context.push('/checkin'),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Start Workout'),
                onPressed: () async {
                  final db = ref.read(dbProvider);
                  final id = await db.workoutDao.startWorkout();
                  if (!context.mounted) return;
                  context.push('/workout/$id');
                },
              ),
              const SizedBox(height: 20),
              stats.when(
                data: (s) => _StatsRow(stats: s),
                loading: () => const SizedBox(
                    height: 80,
                    child: Center(child: CircularProgressIndicator())),
                error: (e, _) => Text('Error: $e'),
              ),
              const SizedBox(height: 24),
              Text('Recent Workouts',
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              recent.when(
                data: (list) {
                  if (list.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'No workouts yet. Tap "Start Workout" to begin.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    );
                  }
                  return Column(
                    children: list
                        .map((w) => _RecentTile(
                              title: w.title,
                              date: w.startedAt,
                              durationSec: w.durationSec,
                              onTap: () => context.push('/history/${w.id}'),
                            ))
                        .toList(),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Text('Error: $e'),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.list_alt_rounded),
                      label: const Text('Plans',
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      onPressed: () => context.push('/plans'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.history),
                      label: const Text('History',
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      onPressed: () => context.push('/history'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.show_chart),
                label: const Text('Progress'),
                onPressed: () => context.push('/progress'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckInCard extends StatelessWidget {
  final DailyCheckIn? today;
  final CheckInStreak? streak;
  final VoidCallback onTap;
  const _CheckInCard({
    required this.today,
    required this.streak,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasCheckedIn = today != null;
    final s = streak ??
        const CheckInStreak(current: 0, longest: 0, thisWeek: 0);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: hasCheckedIn
                ? [
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  ]
                : [
                    const Color(0xFFFF6A00),
                    const Color(0xFFFF8A2A),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '${s.current}',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: hasCheckedIn
                        ? theme.colorScheme.onPrimaryContainer
                        : Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    s.current == 0
                        ? (hasCheckedIn ? 'Day 1 starts now' : 'Start a streak today')
                        : '${s.current}-day streak',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: hasCheckedIn
                          ? theme.colorScheme.onPrimaryContainer
                          : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasCheckedIn
                        ? _statusLabel(today!.status)
                        : 'Tap to check in',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: (hasCheckedIn
                              ? theme.colorScheme.onPrimaryContainer
                              : Colors.white)
                          .withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              hasCheckedIn ? Icons.check_circle : Icons.arrow_forward,
              color: hasCheckedIn
                  ? theme.colorScheme.onPrimaryContainer
                  : Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  static String _statusLabel(String s) {
    switch (s) {
      case checkInTrained:
        return 'Trained today';
      case checkInRest:
        return 'Rest day logged';
      case checkInSkipped:
        return 'Skipped — back tomorrow';
    }
    return 'Checked in';
  }
}

class _StatsRow extends StatelessWidget {
  final HomeStats stats;
  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(label: 'This Week', value: '${stats.weekCount}'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(label: 'Total', value: '${stats.totalCount}'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: 'Volume',
            value: _formatVolume(stats.totalVolume),
          ),
        ),
      ],
    );
  }

  static String _formatVolume(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                style: theme.textTheme.headlineSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentTile extends StatelessWidget {
  final String title;
  final DateTime date;
  final int durationSec;
  final VoidCallback onTap;
  const _RecentTile({
    required this.title,
    required this.date,
    required this.durationSec,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM d').format(date);
    final mins = (durationSec / 60).round();
    return Card(
      child: ListTile(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('$dateStr  ·  $mins min',
            maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
