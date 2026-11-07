/// SHARED-004 Offline & sync — pending queue, honest 'not synced' state,
/// safe retry. Unsynced work is never represented as done.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../shared/widgets.dart';

class OfflineStatusPage extends ConsumerWidget {
  const OfflineStatusPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(appStoreProvider);
    return FcScaffold(
      title: 'Offline & sync',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FcCard(
            child: Row(
              children: [
                Icon(
                  store.isOffline
                      ? Icons.cloud_off_outlined
                      : Icons.cloud_done_outlined,
                  size: 40,
                  color: store.isOffline
                      ? FamilyCircleColors.warning
                      : FamilyCircleColors.primary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        store.isOffline ? 'Offline' : 'Connected',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        store.isOffline
                            ? 'Reading saved content. Safe changes queue below.'
                            : 'Everything is in sync.',
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: store.isOffline,
                  onChanged: (v) => store.setOffline(v),
                ),
              ],
            ),
          ),
          const SectionHeader('Pending changes'),
          if (store.pending.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Nothing waiting to sync.'),
            )
          else
            for (final p in store.pending)
              ListTile(
                leading: const Icon(
                  Icons.schedule_outlined,
                  color: FamilyCircleColors.warning,
                ),
                title: Text(p.description),
                subtitle: const Text(
                  'Queued — will send on reconnect. Not done yet.',
                ),
              ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'While offline you can view your approved plan, pantry and votes. Purchases, plan changes and billing always need a connection.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
