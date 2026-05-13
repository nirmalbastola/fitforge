import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/logic/pr_calculator.dart';
import '../../core/logic/pr_detector.dart';
import '../../core/logic/progression_engine.dart';
import '../../core/services/widget_service.dart';
import '../../data/dao/check_in_dao.dart';
import '../../data/db/app_database.dart';
import '../../data/providers.dart';
import '../checkin/checkin_providers.dart';
import '../settings/settings_providers.dart';
import 'pr_flash_controller.dart';
import 'rest_timer_controller.dart';
import 'workout_providers.dart';

class WorkoutSessionScreen extends ConsumerStatefulWidget {
  final int workoutId;
  const WorkoutSessionScreen({super.key, required this.workoutId});

  @override
  ConsumerState<WorkoutSessionScreen> createState() =>
      _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends ConsumerState<WorkoutSessionScreen> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  DateTime? _startedAt;
  late final TextEditingController _titleCtrl;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _initWorkout();
  }

  Future<void> _initWorkout() async {
    final db = ref.read(dbProvider);
    final w = await db.workoutDao.getWorkout(widget.workoutId);
    if (w == null) return;
    _startedAt = w.startedAt;
    _titleCtrl.text = w.title;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _startedAt == null) return;
      setState(() => _elapsed = DateTime.now().difference(_startedAt!));
    });
    setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    _titleCtrl.dispose();
    super.dispose();
  }

  String _fmtDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  Future<bool> _confirmExit() async {
    final sets = await ref.read(dbProvider).setDao.setsForWorkout(widget.workoutId);
    if (sets.isEmpty) {
      await ref.read(dbProvider).workoutDao.deleteWorkout(widget.workoutId);
      return true;
    }
    if (!mounted) return false;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard workout?'),
        content: const Text('Your current workout has unsaved progress.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (result == true) {
      await ref.read(dbProvider).workoutDao.deleteWorkout(widget.workoutId);
      return true;
    }
    return false;
  }

  Future<void> _finish() async {
    final db = ref.read(dbProvider);
    final sets = await db.setDao.setsForWorkout(widget.workoutId);
    if (sets.isEmpty) {
      await db.workoutDao.deleteWorkout(widget.workoutId);
      if (!mounted) return;
      context.go('/');
      return;
    }
    await db.workoutDao.finishWorkout(widget.workoutId);
    final existing = await db.checkInDao.today();
    if (existing == null) {
      await db.checkInDao.upsert(
        date: DateTime.now(),
        status: checkInTrained,
        energy: 4,
      );
    } else if (existing.status != checkInTrained) {
      await db.checkInDao.upsert(
        date: DateTime.now(),
        status: checkInTrained,
        energy: existing.energy,
        note: existing.note,
      );
    }
    ref.invalidate(streakProvider);
    ref.invalidate(todayCheckInProvider);
    await WidgetService.refresh(db);
    if (!mounted) return;
    context.go('/');
  }

  Future<void> _addExercise() async {
    final selected = await context.push<int>('/exercises/picker');
    if (selected == null) return;
    final db = ref.read(dbProvider);
    final sets = await db.setDao.setsForWorkout(widget.workoutId);
    final existingForExercise =
        sets.where((s) => s.exerciseId == selected).length;
    await db.setDao.addSet(
      workoutId: widget.workoutId,
      exerciseId: selected,
      setIndex: existingForExercise + 1,
    );
  }

  Future<void> _renameTitle() async {
    await ref
        .read(dbProvider)
        .workoutDao
        .renameWorkout(widget.workoutId, _titleCtrl.text.trim().isEmpty
            ? 'Workout'
            : _titleCtrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final setsAsync = ref.watch(setsForWorkoutProvider(widget.workoutId));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final ok = await _confirmExit();
        if (!context.mounted) return;
        if (ok) context.go('/');
      },
      child: Scaffold(
        appBar: AppBar(
          leading: Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.close),
              onPressed: () async {
                final ok = await _confirmExit();
                if (!ctx.mounted) return;
                if (ok) ctx.go('/');
              },
            ),
          ),
          title: TextField(
            controller: _titleCtrl,
            maxLines: 1,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Workout',
              isDense: true,
            ),
            style: Theme.of(context).textTheme.titleLarge,
            onSubmitted: (_) => _renameTitle(),
          ),
          titleSpacing: 0,
          actions: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  _fmtDuration(_elapsed),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            setsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (sets) {
                final grouped = <int, List<WorkoutSet>>{};
                for (final s in sets) {
                  grouped.putIfAbsent(s.exerciseId, () => []).add(s);
                }
                if (grouped.isEmpty) {
                  return _EmptyState(onAdd: _addExercise);
                }
                final exerciseIds = grouped.keys.toList();
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                  itemCount: exerciseIds.length + 1,
                  itemBuilder: (ctx, i) {
                    if (i == exerciseIds.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add Exercise'),
                          onPressed: _addExercise,
                        ),
                      );
                    }
                    final exerciseId = exerciseIds[i];
                    return _ExerciseCard(
                      workoutId: widget.workoutId,
                      exerciseId: exerciseId,
                      sets: grouped[exerciseId]!,
                    );
                  },
                );
              },
            ),
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _PrFlashBanner(),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _RestTimerBanner(),
                FilledButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('Finish Workout'),
                  onPressed: _finish,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fitness_center,
                size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            const Text('No exercises yet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('Add an exercise to begin logging sets.'),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Exercise'),
              onPressed: onAdd,
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseCard extends ConsumerWidget {
  final int workoutId;
  final int exerciseId;
  final List<WorkoutSet> sets;

  const _ExerciseCard({
    required this.workoutId,
    required this.exerciseId,
    required this.sets,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exerciseAsync = ref.watch(exerciseByIdProvider(exerciseId));
    final prevAsync = ref.watch(
        previousBestProvider(PreviousBestArgs(exerciseId, workoutId)));
    final prevSetsAsync = ref.watch(
        previousWorkoutSetsProvider(PreviousBestArgs(exerciseId, workoutId)));

    final suggestion = prevSetsAsync.maybeWhen(
      data: (prev) {
        if (prev.isEmpty) return null;
        return const ProgressionEngine().suggest(previousDoneSets: prev);
      },
      orElse: () => null,
    );

    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    exerciseAsync.maybeWhen(
                      data: (e) => e?.name ?? 'Exercise',
                      orElse: () => '...',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showExerciseMenu(context, ref),
                ),
              ],
            ),
            prevAsync.maybeWhen(
              data: (p) => p == null
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        'Last: ${_fmtWeight(p.weight)} × ${p.reps}',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ),
              orElse: () => const SizedBox.shrink(),
            ),
            if (suggestion != null && suggestion.suggestedWeight > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _SuggestionChip(
                  text:
                      'Try ${_fmtWeight(suggestion.suggestedWeight)} × ${suggestion.suggestedRepsMin}–${suggestion.suggestedRepsMax}',
                  reasoning: suggestion.reasoning,
                ),
              ),
            const _SetsTableHeader(),
            ...sets.map((s) => _SetRow(
                  set: s,
                  exerciseId: exerciseId,
                  workoutId: workoutId,
                )),
            const SizedBox(height: 8),
            TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Set'),
              onPressed: () async {
                await ref.read(dbProvider).setDao.addSet(
                      workoutId: workoutId,
                      exerciseId: exerciseId,
                      setIndex: sets.length + 1,
                      weight: sets.isNotEmpty ? sets.last.weight : 0,
                      reps: sets.isNotEmpty ? sets.last.reps : 0,
                    );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showExerciseMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Remove all sets for this exercise'),
              onTap: () async {
                Navigator.pop(ctx);
                final db = ref.read(dbProvider);
                for (final s in sets) {
                  await db.setDao.deleteSet(s.id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  static String _fmtWeight(double w) {
    if (w == w.truncateToDouble()) return '${w.toStringAsFixed(0)}kg';
    return '${w.toStringAsFixed(1)}kg';
  }
}

class _SetsTableHeader extends StatelessWidget {
  const _SetsTableHeader();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 32, child: Text('SET', style: style)),
          const SizedBox(width: 8),
          Expanded(child: Text('WEIGHT', style: style, textAlign: TextAlign.center)),
          const SizedBox(width: 8),
          Expanded(child: Text('REPS', style: style, textAlign: TextAlign.center)),
          const SizedBox(width: 8),
          SizedBox(width: 40, child: Text('✓', style: style, textAlign: TextAlign.center)),
        ],
      ),
    );
  }
}

class _SetRow extends ConsumerStatefulWidget {
  final WorkoutSet set;
  final int exerciseId;
  final int workoutId;
  const _SetRow({
    required this.set,
    required this.exerciseId,
    required this.workoutId,
  });

  @override
  ConsumerState<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends ConsumerState<_SetRow> {
  late final TextEditingController _weightCtrl;
  late final TextEditingController _repsCtrl;

  @override
  void initState() {
    super.initState();
    _weightCtrl = TextEditingController(
      text: widget.set.weight == 0 ? '' : _trim(widget.set.weight),
    );
    _repsCtrl = TextEditingController(
      text: widget.set.reps == 0 ? '' : '${widget.set.reps}',
    );
  }

  static String _trim(double v) {
    if (v == v.truncateToDouble()) return v.toStringAsFixed(0);
    return v.toString();
  }

  @override
  void didUpdateWidget(covariant _SetRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.set.weight != widget.set.weight) {
      final newText = widget.set.weight == 0 ? '' : _trim(widget.set.weight);
      if (_weightCtrl.text != newText) _weightCtrl.text = newText;
    }
    if (oldWidget.set.reps != widget.set.reps) {
      final newText = widget.set.reps == 0 ? '' : '${widget.set.reps}';
      if (_repsCtrl.text != newText) _repsCtrl.text = newText;
    }
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    super.dispose();
  }

  Future<void> _persist() async {
    final w = double.tryParse(_weightCtrl.text.replaceAll(',', '.')) ?? 0;
    final r = int.tryParse(_repsCtrl.text) ?? 0;
    await ref.read(dbProvider).setDao.updateSet(
          id: widget.set.id,
          weight: w,
          reps: r,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = widget.set.done;
    final prevAsync = ref.watch(previousBestProvider(
        PreviousBestArgs(widget.exerciseId, widget.workoutId)));
    Color? deltaColor;
    if (done) {
      final prev = prevAsync.valueOrNull;
      if (prev != null) {
        final prevVol = PrCalculator.setVolume(prev.weight, prev.reps);
        final curVol =
            PrCalculator.setVolume(widget.set.weight, widget.set.reps);
        if (curVol > prevVol) {
          deltaColor = const Color(0xFF2E7D32); // green
        } else if (curVol > 0 && curVol < prevVol) {
          deltaColor = const Color(0xFFB71C1C); // red
        }
      }
    }
    final bg = done
        ? (deltaColor?.withValues(alpha: 0.18) ??
            theme.colorScheme.primaryContainer.withValues(alpha: 0.4))
        : Colors.transparent;

    return Dismissible(
      key: ValueKey('set-${widget.set.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: theme.colorScheme.errorContainer,
        child: Icon(Icons.delete_outline,
            color: theme.colorScheme.onErrorContainer),
      ),
      onDismissed: (_) async {
        await ref.read(dbProvider).setDao.deleteSet(widget.set.id);
      },
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        margin: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text(
                '${widget.set.setIndex}',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _weightCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: '0',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                ),
                onChanged: (_) => _persist(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _repsCtrl,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: '0',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                ),
                onChanged: (_) => _persist(),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 40,
              child: IconButton(
                icon: Icon(
                  done ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: done ? theme.colorScheme.primary : null,
                ),
                onPressed: () async {
                  await _persist();
                  await ref.read(dbProvider).setDao.updateSet(
                        id: widget.set.id,
                        done: !done,
                      );
                  if (!done) {
                    HapticFeedback.mediumImpact();
                    final db = ref.read(dbProvider);
                    final settings = ref.read(settingsProvider).valueOrNull;
                    final ex = await db.exerciseDao.getById(widget.exerciseId);
                    final rest = ex?.defaultRestSec ??
                        settings?.restTimerSeconds ??
                        90;
                    ref.read(restTimerProvider.notifier).start(rest);

                    final w = double.tryParse(
                            _weightCtrl.text.replaceAll(',', '.')) ??
                        0;
                    final r = int.tryParse(_repsCtrl.text) ?? 0;
                    if (w > 0 || r > 0) {
                      final events = await PrDetector(db).evaluateSet(
                        exerciseId: widget.exerciseId,
                        workoutId: widget.workoutId,
                        weight: w,
                        reps: r,
                      );
                      if (events.isNotEmpty) {
                        HapticFeedback.heavyImpact();
                        ref.read(prFlashProvider.notifier).show(events);
                      }
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RestTimerBanner extends ConsumerWidget {
  const _RestTimerBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(restTimerProvider);
    if (!state.active) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final progress = state.totalSeconds == 0
        ? 0.0
        : state.remainingSeconds / state.totalSeconds;
    final m = (state.remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (state.remainingSeconds % 60).toString().padLeft(2, '0');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 3,
                    backgroundColor:
                        theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.15),
                    color: theme.colorScheme.primary,
                  ),
                  Icon(Icons.timer_outlined,
                      size: 16,
                      color: theme.colorScheme.onPrimaryContainer),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Rest',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                          color: theme.colorScheme.onPrimaryContainer
                              .withValues(alpha: 0.7))),
                  Text('$m:$s',
                      style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.remove),
              tooltip: '−15s',
              onPressed: () =>
                  ref.read(restTimerProvider.notifier).addSeconds(-15),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.add),
              tooltip: '+15s',
              onPressed: () =>
                  ref.read(restTimerProvider.notifier).addSeconds(15),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close),
              tooltip: 'Skip',
              onPressed: () => ref.read(restTimerProvider.notifier).cancel(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String text;
  final String reasoning;
  const _SuggestionChip({required this.text, required this.reasoning});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(reasoning)),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: theme.colorScheme.tertiary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome,
                size: 14, color: theme.colorScheme.tertiary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onTertiaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrFlashBanner extends ConsumerWidget {
  const _PrFlashBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(prFlashProvider);
    if (events.isEmpty) return const SizedBox.shrink();
    final primary = events.first;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFF6A00),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6A00).withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.local_fire_department,
                  color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      events.length == 1
                          ? 'New ${primary.label}!'
                          : 'New PRs! (${events.length})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      _formatDelta(primary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 20),
                onPressed: () =>
                    ref.read(prFlashProvider.notifier).dismiss(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDelta(PrEvent e) {
    final delta = e.delta;
    final pct = e.pctImprovement;
    final sign = delta >= 0 ? '+' : '';
    if (e.previousValue == 0) {
      return 'First record!';
    }
    return '$sign${delta.toStringAsFixed(1)} (${pct.toStringAsFixed(0)}%)';
  }
}

