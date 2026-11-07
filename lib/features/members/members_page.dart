/// ADULT-007 Circle members — invite/remove adults, add managed children,
/// review roles. Kids see none of this (server rejects anyway).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/catalog.dart' as catalog;
import '../../shared/errors.dart';
import '../../shared/models.dart';
import '../../shared/widgets.dart';

class MembersPage extends ConsumerWidget {
  const MembersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(appStoreProvider);
    final circle = store.circle;
    if (circle == null) {
      return const FcScaffold(title: 'Members', child: SkeletonList());
    }
    return FcScaffold(
      title: 'Household members',
      fab: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context, store),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Add'),
      ),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          const SectionHeader('Adults'),
          for (final m in circle.adults) _memberTile(context, store, m),
          const SectionHeader('Managed kids'),
          if (circle.minors.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No kid profiles yet. Adults manage them — kids never need accounts.',
              ),
            )
          else
            for (final m in circle.minors) _memberTile(context, store, m),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Kid profiles see no prices, billing, ads or purchase prompts — ever. Removing a member keeps household meal history.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _memberTile(BuildContext context, AppStore store, CircleMember m) {
    return ListTile(
      leading: MemberAvatar(name: m.name, minor: m.isMinor),
      title: Text(m.name),
      subtitle: Text(
        [
          m.isMinor ? 'Kid • ages ${m.ageBand.label}' : m.role.name,
          if (m.hardAllergens.isNotEmpty)
            'allergies: ${m.hardAllergens.join(', ').replaceAll('_', ' ')}',
        ].join(' • '),
      ),
      trailing: m.role == MemberRole.owner
          ? const Padding(padding: EdgeInsets.all(8), child: FcChip('Owner'))
          : IconButton(
              tooltip: 'Remove ${m.name}',
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () => _confirmRemove(context, store, m),
            ),
      onTap: () => _editAllergens(context, store, m),
    );
  }

  void _editAllergens(BuildContext context, AppStore store, CircleMember m) {
    final selected = {...m.hardAllergens};
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${m.name}\'s hard allergies',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Only confirmed allergies. Unverified foods always fail closed regardless.',
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final key in catalog.allergenKeys)
                      FilterChip(
                        label: Text(key.replaceAll('_', ' ')),
                        selected: selected.contains(key),
                        onSelected: (sel) => setSheetState(
                          () => sel ? selected.add(key) : selected.remove(key),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    try {
                      store.setMemberAllergens(m.id, selected);
                      Navigator.of(sheetContext).pop();
                    } on FcException catch (e) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(e.safeMessage)));
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmRemove(BuildContext context, AppStore store, CircleMember m) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Remove ${m.name}?'),
        content: Text(
          m.isMinor
              ? 'Their votes and badges stay in household history.'
              : 'They lose access to this household.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              try {
                store.removeMember(m.id);
                Navigator.of(dialogContext).pop();
              } on FcException catch (e) {
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(e.safeMessage)));
              }
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showAddSheet(BuildContext context, AppStore store) {
    final name = TextEditingController();
    var minor = true;
    var band = AgeBand.a9to12;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              left: 24,
              right: 24,
              top: 8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Add member',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 12),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('Adult')),
                    ButtonSegment(value: true, label: Text('Managed kid')),
                  ],
                  selected: {minor},
                  onSelectionChanged: (s) =>
                      setSheetState(() => minor = s.first),
                ),
                if (minor) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<AgeBand>(
                    initialValue: band,
                    decoration: const InputDecoration(labelText: 'Age band'),
                    items: [
                      for (final b in AgeBand.values.where((b) => b.isMinor))
                        DropdownMenuItem(
                          value: b,
                          child: Text('Ages ${b.label}'),
                        ),
                    ],
                    onChanged: (v) => setSheetState(() => band = v ?? band),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    try {
                      store.addMember(name.text, minor: minor, band: band);
                      Navigator.of(sheetContext).pop();
                    } on FcException catch (e) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(e.safeMessage)));
                    }
                  },
                  child: const Text('Add member'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
