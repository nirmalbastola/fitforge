import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/dao/plan_dao.dart';
import '../../data/db/app_database.dart';
import '../../data/providers.dart';
import 'plans_providers.dart';

class PlanEditorScreen extends ConsumerWidget {
  final int planId;
  const PlanEditorScreen({super.key, required this.planId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daysAsync = ref.watch(daysForPlanProvider(planId));
    final planFuture = ref.watch(_planFutureProvider(planId));

    return Scaffold(
      appBar: AppBar(
        title: planFuture.when(
          data: (p) => Text(p?.name ?? 'Plan'),
          loading: () => const Text('Plan'),
          error: (_, _) => const Text('Plan'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add day',
            onPressed: () => _addDay(context, ref),
          ),
        ],
      ),
      body: daysAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (days) {
          if (days.isEmpty) {
            return _EmptyDays(onAdd: () => _addDay(context, ref));
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: days.length,
            itemBuilder: (ctx, i) {
              final d = days[i];
              return _PlanDayCard(planId: planId, day: d);
            },
          );
        },
      ),
    );
  }

  Future<void> _addDay(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add day'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
              hintText: 'e.g. Push, Pull, Legs',
              border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Add')),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    await ref.read(dbProvider).planDao.addDay(planId, name);
  }
}

final _planFutureProvider = FutureProvider.family<Plan?, int>((ref, id) {
  return ref.watch(dbProvider).planDao.getPlan(id);
});

class _PlanDayCard extends ConsumerWidget {
  final int planId;
  final PlanDay day;
  const _PlanDayCard({required this.planId, required this.day});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercisesAsync = ref.watch(exercisesForDayProvider(day.id));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(day.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showDayMenu(context, ref),
                ),
              ],
            ),
            exercisesAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(8),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('Error: $e'),
              data: (list) {
                if (list.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      'No exercises in this day',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }
                return Column(
                  children: list
                      .map((e) => _PlanExerciseRow(item: e))
                      .toList(),
                );
              },
            ),
            Row(
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add exercise'),
                  onPressed: () => _addExercise(context, ref),
                ),
                const Spacer(),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Start'),
                  onPressed: () => _startWorkoutFromDay(context, ref),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addExercise(BuildContext context, WidgetRef ref) async {
    final selected = await context.push<int>('/exercises/picker');
    if (selected == null) return;
    await ref.read(dbProvider).planDao.addExerciseToDay(
          dayId: day.id,
          exerciseId: selected,
        );
  }

  Future<void> _startWorkoutFromDay(
      BuildContext context, WidgetRef ref) async {
    final db = ref.read(dbProvider);
    final exercises = await db.planDao.exercisesForDay(day.id);
    final wId = await db.workoutDao.startWorkoutFromPlanDay(
      title: day.name,
      planDayId: day.id,
    );
    for (final pe in exercises) {
      for (var i = 1; i <= pe.pe.targetSets; i++) {
        await db.setDao.addSet(
          workoutId: wId,
          exerciseId: pe.exercise.id,
          setIndex: i,
        );
      }
    }
    if (!context.mounted) return;
    context.push('/workout/$wId');
  }

  void _showDayMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Rename day'),
              onTap: () async {
                Navigator.pop(ctx);
                final ctrl = TextEditingController(text: day.name);
                final name = await showDialog<String>(
                  context: context,
                  builder: (dctx) => AlertDialog(
                    title: const Text('Rename day'),
                    content: TextField(
                      controller: ctrl,
                      autofocus: true,
                      decoration: const InputDecoration(
                          border: OutlineInputBorder()),
                    ),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(dctx),
                          child: const Text('Cancel')),
                      TextButton(
                          onPressed: () =>
                              Navigator.pop(dctx, ctrl.text.trim()),
                          child: const Text('Save')),
                    ],
                  ),
                );
                if (name != null && name.isNotEmpty) {
                  await ref.read(dbProvider).planDao.renameDay(day.id, name);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete day'),
              onTap: () async {
                Navigator.pop(ctx);
                await ref.read(dbProvider).planDao.deleteDay(day.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanExerciseRow extends ConsumerWidget {
  final PlanExerciseWithDetails item;
  const _PlanExerciseRow({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pe = item.pe;
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => _editTargets(context, ref),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(item.exercise.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge),
                  Text(
                    '${pe.targetSets} × ${pe.targetRepsMin}-${pe.targetRepsMax} reps',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close),
              tooltip: 'Remove',
              onPressed: () =>
                  ref.read(dbProvider).planDao.removePlanExercise(pe.id),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editTargets(BuildContext context, WidgetRef ref) async {
    final pe = item.pe;
    final setsCtrl = TextEditingController(text: '${pe.targetSets}');
    final minCtrl = TextEditingController(text: '${pe.targetRepsMin}');
    final maxCtrl = TextEditingController(text: '${pe.targetRepsMax}');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item.exercise.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: setsCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Target sets', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: minCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Reps min',
                        border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: maxCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Reps max',
                        border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(dbProvider).planDao.updatePlanExercise(
          id: pe.id,
          targetSets: int.tryParse(setsCtrl.text),
          targetRepsMin: int.tryParse(minCtrl.text),
          targetRepsMax: int.tryParse(maxCtrl.text),
        );
  }
}

class _EmptyDays extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyDays({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_view_day,
                size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            const Text('No days yet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text(
                'Add training days like Push, Pull, Legs.',
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add day'),
              onPressed: onAdd,
            ),
          ],
        ),
      ),
    );
  }
}
