import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/db/app_database.dart';
import '../../data/providers.dart';

const _muscleGroups = [
  'All',
  'Chest',
  'Back',
  'Legs',
  'Shoulders',
  'Arms',
  'Core',
];

class ExercisePickerScreen extends ConsumerStatefulWidget {
  const ExercisePickerScreen({super.key});

  @override
  ConsumerState<ExercisePickerScreen> createState() =>
      _ExercisePickerScreenState();
}

class _ExercisePickerScreenState extends ConsumerState<ExercisePickerScreen> {
  String _query = '';
  String _group = 'All';

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(dbProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add custom exercise',
            onPressed: () => context.push('/exercises/new'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search exercises',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v.trim()),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _muscleGroups.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final g = _muscleGroups[i];
                return ChoiceChip(
                  label: Text(g),
                  selected: _group == g,
                  onSelected: (_) => setState(() => _group = g),
                );
              },
            ),
          ),
          const Divider(height: 16),
          Expanded(
            child: StreamBuilder<List<Exercise>>(
              stream: db.exerciseDao.watchAll(),
              builder: (ctx, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final all = snap.data!;
                final filtered = all.where((e) {
                  final matchGroup = _group == 'All' || e.muscleGroup == _group;
                  final matchQuery = _query.isEmpty ||
                      e.name.toLowerCase().contains(_query.toLowerCase());
                  return matchGroup && matchQuery;
                }).toList();
                if (filtered.isEmpty) {
                  return const Center(child: Text('No exercises found'));
                }
                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final e = filtered[i];
                    return ListTile(
                      title: Text(e.name),
                      subtitle: Text(e.muscleGroup),
                      trailing: const Icon(Icons.add_circle_outline),
                      onTap: () => context.pop(e.id),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
