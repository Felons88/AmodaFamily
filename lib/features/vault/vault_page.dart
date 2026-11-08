/// ADULT-012 Recipe vault — favorites, cook history and opt-in moderated
/// catalog sharing. Private notes and child data never migrate.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../shared/catalog.dart' as catalog;
import '../../shared/models.dart';
import '../../shared/widgets.dart';

class VaultPage extends ConsumerWidget {
  const VaultPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(appStoreProvider);
    final favorites = store.favorites;
    final vault = store.vault.values.toList()
      ..sort((a, b) => b.cookedCount.compareTo(a.cookedCount));

    return FcScaffold(
      title: 'Recipe vault',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          const SectionHeader('Favorites'),
          if (favorites.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: FcCard(
                child: Text(
                  'Save recipes with the heart icon and they appear here.',
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FcCard(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    for (var i = 0; i < favorites.length; i++) ...[
                      _favoriteTile(context, favorites[i].recipeId),
                      if (i < favorites.length - 1)
                        Divider(
                          height: 1,
                          indent: 66,
                          color: Theme.of(context).colorScheme.outlineVariant
                              .withValues(alpha: .45),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          const SectionHeader('Cook history'),
          if (vault.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: FcCard(
                child: Text('Meals you confirm as cooked build this history.'),
              ),
            )
          else
            for (final v in vault)
              Builder(
                builder: (context) {
                  final r = catalog.recipes[v.recipeId];
                  if (r == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: _historyCard(context, store, v, r.title),
                  );
                },
              ),
        ],
      ),
    );
  }

  Widget _favoriteTile(BuildContext context, String recipeId) {
    final r = catalog.recipes[recipeId];
    if (r == null) return const SizedBox.shrink();
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error.withValues(alpha: .13),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(
          Icons.favorite,
          color: Theme.of(context).colorScheme.error,
          size: 20,
        ),
      ),
      title: Text(
        r.title,
        style: Theme.of(context).textTheme.titleSmall
            ?.copyWith(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        '${r.meal.label} • ${r.minutes} min • serves ${r.servings}',
      ),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: () => context.push('${AppRoute.recipeDetail.path}/${r.id}'),
    );
  }

  Widget _historyCard(
    BuildContext context,
    AppStore store,
    VaultEntry entry,
    String title,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return FcCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: .13),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.soup_kitchen_outlined, color: scheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cooked ${entry.cookedCount}x${entry.lastCooked == null ? '' : ' • last ${entry.lastCooked!.month}/${entry.lastCooked!.day}/${entry.lastCooked!.year}'}',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                FcChip(
                  switch (entry.shareStatus) {
                    ShareStatus.privateOnly => 'Private to household',
                    ShareStatus.pendingReview => 'Pending catalog review',
                    ShareStatus.published => 'Shared to catalog',
                  },
                  icon: switch (entry.shareStatus) {
                    ShareStatus.privateOnly => Icons.lock_outline,
                    ShareStatus.pendingReview => Icons.hourglass_top_outlined,
                    ShareStatus.published => Icons.public,
                  },
                  color: entry.shareStatus == ShareStatus.privateOnly
                      ? Theme.of(context).colorScheme.onSurfaceVariant
                      : Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
          if (entry.shareStatus == ShareStatus.privateOnly)
            TextButton(
              onPressed: () => _confirmShare(context, store, entry.recipeId),
              child: const Text('Share'),
            ),
        ],
      ),
    );
  }

  void _confirmShare(BuildContext context, AppStore store, String recipeId) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Share to catalog?'),
        content: const Text(
          'Shared recipes are checked for duplicates, ingredients and image licensing before publishing. Your private notes, budget and kids\' activity never travel with it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              store.shareToCatalog(recipeId);
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Send for review'),
          ),
        ],
      ),
    );
  }
}
