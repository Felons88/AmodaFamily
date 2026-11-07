/// SHARED-004 Offline & sync — pending queue, honest 'not synced' state and
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
    final scheme = Theme.of(context).colorScheme;
    final offlineColor = store.isOffline
        ? FamilyCircleColors.warning
        : FamilyCircleColors.primary;
    return FcScaffold(
      title: 'Offline & sync',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          FcCard(
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: offlineColor.withValues(alpha: .14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    store.isOffline
                        ? Icons.cloud_off_outlined
                        : Icons.cloud_done_outlined,
                    size: 34,
                    color: offlineColor,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  store.isOffline ? 'Offline' : 'Connected',
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 5),
                Text(
                  store.isOffline
                      ? 'Reading saved content. Safe changes queue below.'
                      : 'Everything is in sync.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    icon: Icon(
                      store.isOffline
                          ? Icons.wifi_off_outlined
                          : Icons.wifi_outlined,
                    ),
                    label: Text(
                      store.isOffline
                          ? 'Simulate reconnect'
                          : 'Simulate offline',
                    ),
                    onPressed: () => store.setOffline(!store.isOffline),
                  ),
                ),
              ],
            ),
          ),
          const SectionHeader('Pending changes'),
          if (store.pending.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: FcCard(child: Text('Nothing waiting to sync.')),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FcCard(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    for (var i = 0; i < store.pending.length; i++) ...[
                      ListTile(
                        leading: const Icon(
                          Icons.schedule_outlined,
                          color: FamilyCircleColors.warning,
                        ),
                        title: Text(store.pending[i].description),
                        subtitle: const Text(
                          'Queued — will send on reconnect. Not done yet.',
                        ),
                      ),
                      if (i < store.pending.length - 1)
                        Divider(
                          height: 1,
                          indent: 56,
                          color: scheme.outlineVariant.withValues(alpha: .45),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          const SectionHeader('What works offline'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FcCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: scheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'While offline you can view your approved plan, pantry and votes. Purchases, plan changes and billing always need a connection.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
