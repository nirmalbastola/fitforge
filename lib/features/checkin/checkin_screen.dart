import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/dao/check_in_dao.dart';
import '../../data/db/app_database.dart';
import '../../data/providers.dart';
import 'checkin_providers.dart';

class CheckInScreen extends ConsumerStatefulWidget {
  const CheckInScreen({super.key});

  @override
  ConsumerState<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends ConsumerState<CheckInScreen> {
  String? _status;
  int _energy = 3;
  final _noteCtrl = TextEditingController();
  bool _initialized = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  void _hydrate(DailyCheckIn? existing) {
    if (_initialized) return;
    _initialized = true;
    if (existing != null) {
      _status = existing.status;
      _energy = existing.energy;
      _noteCtrl.text = existing.note ?? '';
    }
  }

  Future<void> _save() async {
    if (_status == null) return;
    await ref.read(dbProvider).checkInDao.upsert(
          date: DateTime.now(),
          status: _status!,
          energy: _energy,
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        );
    ref.invalidate(streakProvider);
    ref.invalidate(recentCheckInsProvider);
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final todayAsync = ref.watch(todayCheckInProvider);
    final dateStr = DateFormat('EEEE, MMM d').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Check-in')),
      body: todayAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (existing) {
          _hydrate(existing);
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(dateStr,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                existing == null
                    ? 'How is today going?'
                    : 'Updating today\'s check-in',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),
              const _SectionLabel('STATUS'),
              const SizedBox(height: 8),
              _StatusGrid(
                selected: _status,
                onSelect: (s) => setState(() => _status = s),
              ),
              const SizedBox(height: 24),
              const _SectionLabel('ENERGY'),
              const SizedBox(height: 8),
              _EnergySlider(
                value: _energy,
                onChanged: (v) => setState(() => _energy = v),
              ),
              const SizedBox(height: 24),
              const _SectionLabel('NOTE (OPTIONAL)'),
              const SizedBox(height: 8),
              TextField(
                controller: _noteCtrl,
                maxLines: 3,
                maxLength: 280,
                decoration: const InputDecoration(
                  hintText: 'Felt strong today / sore knee / busy week...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                icon: const Icon(Icons.check),
                label: Text(existing == null ? 'Check in' : 'Update'),
                onPressed: _status == null ? null : _save,
              ),
              if (existing != null) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remove today\'s check-in'),
                  onPressed: () async {
                    await ref
                        .read(dbProvider)
                        .checkInDao
                        .deleteForDate(DateTime.now());
                    ref.invalidate(streakProvider);
                    ref.invalidate(recentCheckInsProvider);
                    if (!context.mounted) return;
                    context.pop();
                  },
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _StatusGrid extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelect;
  const _StatusGrid({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        value: checkInTrained,
        label: 'Trained',
        icon: Icons.fitness_center,
      ),
      (
        value: checkInRest,
        label: 'Rest day',
        icon: Icons.self_improvement,
      ),
      (
        value: checkInSkipped,
        label: 'Skipped',
        icon: Icons.cancel_outlined,
      ),
    ];
    return LayoutBuilder(
      builder: (ctx, constraints) {
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) {
            final isSelected = selected == item.value;
            final width = (constraints.maxWidth - 16) / 3;
            return SizedBox(
              width: width,
              child: _StatusCard(
                label: item.label,
                icon: item.icon,
                selected: isSelected,
                onTap: () => onSelect(item.value),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _StatusCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.2),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 28,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? theme.colorScheme.onPrimaryContainer
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EnergySlider extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _EnergySlider({required this.value, required this.onChanged});

  static const _labels = ['Drained', 'Low', 'OK', 'Good', 'Great'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Slider(
          value: value.toDouble(),
          min: 1,
          max: 5,
          divisions: 4,
          label: _labels[value - 1],
          onChanged: (v) => onChanged(v.round()),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _labels
                .map((l) => Text(l,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        )))
                .toList(),
          ),
        ),
      ],
    );
  }
}
