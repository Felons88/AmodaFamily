/// ADULT-012 Recipe vault — favorites, cook history, opt-in moderated
/// catalog sharing (private notes and child data never migrate).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
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
        padding: const EdgeInsets.all(16),
        children: [
          const SectionHeader('Favorites'),
          if (favorites.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Save recipes with the heart icon and they appear here.',
              ),
            )
          else
            for (final f in favorites)
              Builder(
                builder: (context) {
                  final r = catalog.recipes[f.recipeId];
                  if (r == null) return const SizedBox.shrink();
                  return ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: FamilyCircleColors.error.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: FamilyCircleColors.error,
                        size: 18,
                      ),
                    ),
                    title: Text(r.title),
                    subtitle: Text('${r.meal.label} • ${r.minutes} min'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () =>
                        context.push('${AppRoute.recipeDetail.path}/${r.id}'),
                  );
                },
              ),
          const SectionHeader('Cook history'),
          if (vault.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Meals you confirm as cooked build this history.'),
            )
          else
            for (final v in vault)
              Builder(
                builder: (context) {
                  final r = catalog.recipes[v.recipeId];
                  if (r == null) return const SizedBox.shrink();
                  return FcCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.title,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              Text(
                                'Cooked ${v.cookedCount}x${v.lastCooked == null ? '' : ' • last ${v.lastCooked!.month}/${v.lastCooked!.day}'}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 4),
                              FcChip(
                                switch (v.shareStatus) {
                                  ShareStatus.privateOnly =>
                                    'Private to household',
                                  ShareStatus.pendingReview =>
                                    'Pending catalog review',
                                  ShareStatus.published => 'Shared to catalog',
                                },
                                icon: switch (v.shareStatus) {
                                  ShareStatus.privateOnly => Icons.lock_outline,
                                  ShareStatus.pendingReview =>
                                    Icons.hourglass_top_outlined,
                                  ShareStatus.published => Icons.public,
                                },
                                color: v.shareStatus == ShareStatus.privateOnly
                                    ? FamilyCircleColors.muted
                                    : FamilyCircleColors.primary,
                              ),
                            ],
                          ),
                        ),
                        if (v.shareStatus == ShareStatus.privateOnly)
                          TextButton(
                            onPressed: () =>
                                _confirmShare(context, store, v.recipeId),
                            child: const Text('Share'),
                          ),
                      ],
                    ),
                  );
                },
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
