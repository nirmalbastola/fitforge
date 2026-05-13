import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _dayLabels = {
    1: 'M', 2: 'T', 3: 'W', 4: 'T', 5: 'F', 6: 'S', 7: 'S',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (s) => ListView(
          children: [
            const _SectionHeader(title: 'MORNING CHECK-IN'),
            SwitchListTile(
              title: const Text('Daily check-in'),
              subtitle: const Text(
                  'Morning prompt to log how you feel and set the day'),
              value: s.checkInEnabled,
              onChanged: (v) => notifier.setCheckInEnabled(v),
            ),
            ListTile(
              enabled: s.checkInEnabled,
              title: const Text('Check-in time'),
              subtitle: Text(s.checkInTime.format(context)),
              trailing: const Icon(Icons.wb_sunny_outlined),
              onTap: !s.checkInEnabled
                  ? null
                  : () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: s.checkInTime,
                      );
                      if (picked != null) await notifier.setCheckInTime(picked);
                    },
            ),
            const SizedBox(height: 16),
            const _SectionHeader(title: 'WORKOUT REMINDER'),
            SwitchListTile(
              title: const Text('Workout reminder'),
              subtitle: const Text('Daily nudge to log your workout'),
              value: s.reminderEnabled,
              onChanged: (v) => notifier.setReminderEnabled(v),
            ),
            ListTile(
              enabled: s.reminderEnabled,
              title: const Text('Reminder time'),
              subtitle: Text(s.reminderTime.format(context)),
              trailing: const Icon(Icons.access_time),
              onTap: !s.reminderEnabled
                  ? null
                  : () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: s.reminderTime,
                      );
                      if (picked != null) {
                        await notifier.setReminderTime(picked);
                      }
                    },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: List.generate(7, (i) {
                  final wd = i + 1;
                  final selected = s.reminderWeekdays.contains(wd);
                  return ChoiceChip(
                    label: Text(_dayLabels[wd]!),
                    selected: selected,
                    onSelected: !s.reminderEnabled
                        ? null
                        : (_) => notifier.toggleReminderWeekday(wd),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),
            const _SectionHeader(title: 'REST TIMER'),
            ListTile(
              title: const Text('Default rest between sets'),
              subtitle: Text('${s.restTimerSeconds}s'),
              trailing: const Icon(Icons.tune),
              onTap: () async {
                final picked = await showModalBottomSheet<int>(
                  context: context,
                  builder: (ctx) => _RestPicker(current: s.restTimerSeconds),
                );
                if (picked != null) await notifier.setRestTimer(picked);
              },
            ),
            const SizedBox(height: 24),
            const _SectionHeader(title: 'ABOUT'),
            const ListTile(
              title: Text('FitForge'),
              subtitle: Text('V2'),
              trailing: Icon(Icons.fitness_center),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _RestPicker extends StatefulWidget {
  final int current;
  const _RestPicker({required this.current});

  @override
  State<_RestPicker> createState() => _RestPickerState();
}

class _RestPickerState extends State<_RestPicker> {
  static const _options = [30, 45, 60, 90, 120, 180, 240, 300];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rest timer',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _options.map((s) {
                final selected = s == widget.current;
                return ChoiceChip(
                  label: Text('${s}s'),
                  selected: selected,
                  onSelected: (_) => Navigator.pop(context, s),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
