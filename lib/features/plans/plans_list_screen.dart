import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';
import 'plans_providers.dart';

class PlansListScreen extends ConsumerWidget {
  const PlansListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(allPlansProvider);
    final activeAsync = ref.watch(activePlanProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Plans'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New plan',
            onPressed: () => _newPlan(context, ref),
          ),
        ],
      ),
      body: plansAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          if (list.isEmpty) {
            return _Empty(onCreate: () => _newPlan(context, ref));
          }
          final activeId = activeAsync.valueOrNull?.id;
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (ctx, i) {
              final p = list[i];
              final isActive = p.id == activeId;
              return Card(
                margin: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: Icon(
                    isActive
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_outline_rounded,
                    color: isActive
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  title: Text(p.name),
                  subtitle: Text(isActive ? 'Active plan' : 'Tap to open'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) => _menuAction(context, ref, p.id, v),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                          value: isActive ? 'deactivate' : 'activate',
                          child: Text(
                              isActive ? 'Set inactive' : 'Set as active')),
                      const PopupMenuItem(
                          value: 'rename', child: Text('Rename')),
                      const PopupMenuItem(
                          value: 'delete', child: Text('Delete')),
                    ],
                  ),
                  onTap: () => context.push('/plans/${p.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _newPlan(BuildContext context, WidgetRef ref) async {
    final name = await _promptName(context, title: 'New plan');
    if (name == null || name.isEmpty) return;
    final id = await ref.read(dbProvider).planDao.createPlan(name);
    if (!context.mounted) return;
    context.push('/plans/$id');
  }

  Future<void> _menuAction(
      BuildContext context, WidgetRef ref, int planId, String action) async {
    final dao = ref.read(dbProvider).planDao;
    switch (action) {
      case 'rename':
        final cur = await dao.getPlan(planId);
        if (!context.mounted) return;
        final name = await _promptName(context,
            title: 'Rename plan', initial: cur?.name);
        if (name == null || name.isEmpty) return;
        await dao.renamePlan(planId, name);
      case 'delete':
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete plan?'),
            content:
                const Text('This will remove the plan and its days/exercises.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel')),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Delete')),
            ],
          ),
        );
        if (ok == true) await dao.deletePlan(planId);
        ref.invalidate(activePlanProvider);
      case 'activate':
        await dao.setActivePlan(planId);
        ref.invalidate(activePlanProvider);
      case 'deactivate':
        await dao.setActivePlan(null);
        ref.invalidate(activePlanProvider);
    }
  }

  Future<String?> _promptName(BuildContext context,
      {required String title, String? initial}) {
    final ctrl = TextEditingController(text: initial ?? '');
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
              hintText: 'e.g. Push / Pull / Legs',
              border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Save')),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final VoidCallback onCreate;
  const _Empty({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.list_alt_rounded,
                size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            const Text('No plans yet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text(
                'Create a plan like Push/Pull/Legs and start prescribed workouts.',
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Create plan'),
              onPressed: onCreate,
            ),
          ],
        ),
      ),
    );
  }
}
