/// ADULT-003 Recipe detail — validated ingredients, labeled imagery,
/// substitutions, allergen uncertainty disclosure, instructions.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../shared/catalog.dart' as catalog;
import '../../shared/models.dart';
import '../../shared/widgets.dart';

class RecipeDetailPage extends ConsumerWidget {
  const RecipeDetailPage({super.key, required this.recipeId});

  final String recipeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(appStoreProvider);
    final recipe = catalog.recipes[recipeId];
    if (recipe == null) {
      return const FcScaffold(
        title: 'Recipe',
        child: EmptyState(
          title: 'Recipe unavailable',
          message: 'This recipe is not in the verified catalog.',
        ),
      );
    }
    final eligibility = store.eligibilityFor([recipe])[recipe.id];
    final favorite = store.favorites.any((f) => f.recipeId == recipe.id);
    final signal = store.learning[recipe.id];

    return FcScaffold(
      title: recipe.title,
      actions: [
        IconButton(
          tooltip: favorite ? 'Remove from favorites' : 'Save to favorites',
          icon: Icon(
            favorite ? Icons.favorite : Icons.favorite_border,
            color: favorite ? FamilyCircleColors.error : null,
          ),
          onPressed: () => store.toggleFavorite(recipe.id),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DishImage(image: recipe.image, height: 180),
          if (recipe.image.credit != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                recipe.image.credit!,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          const SizedBox(height: 12),
          Text(recipe.summary, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FcChip(recipe.meal.label, icon: Icons.restaurant_outlined),
              FcChip('${recipe.minutes} min', icon: Icons.schedule_outlined),
              FcChip('Serves ${recipe.servings}', icon: Icons.people_outline),
              FcChip(recipe.cuisine, icon: Icons.public),
              if (eligibility?.isEligible ?? false)
                const FcChip(
                  'Checked for your household',
                  icon: Icons.verified_user_outlined,
                )
              else
                FcChip(
                  'Not eligible: ${eligibility?.code.name ?? 'unknown'}',
                  icon: Icons.warning_amber_outlined,
                  color: FamilyCircleColors.error,
                ),
            ],
          ),
          const SectionHeader('Ingredients'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FcCard(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  for (final need in recipe.needs)
                    Builder(
                      builder: (context) {
                        final ing = catalog.ingredients[need.ingredientId];
                        final sub = recipe.substitutions[need.ingredientId];
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.grass_outlined,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          title: Text(ing?.name ?? need.ingredientId),
                          subtitle: Text(
                            [
                              '$need.amount ${ing == null ? '' : switch (ing.stockUnit) {
                                      FoodUnit.grams => 'g',
                                      FoodUnit.milliliters => 'ml',
                                      FoodUnit.pieces => 'pc',
                                    }}',
                              if (ing != null && ing.allergens.isNotEmpty)
                                'contains ${ing.allergens.join(', ').replaceAll('_', ' ')}',
                              if (sub != null)
                                'swap: ${catalog.ingredients[sub]?.name ?? sub}',
                            ].join(' • '),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          if (recipe.needs.any(
            (n) => catalog.ingredients[n.ingredientId]?.isPackaged ?? false,
          ))
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 8, 32, 0),
              child: Text(
                'Packaged ingredients: labels checked at catalog review. Always recheck labels at home — formulations change.',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: FamilyCircleColors.warning),
              ),
            ),
          const SectionHeader('Instructions'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FcCard(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  for (var i = 0; i < recipe.steps.length; i++)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 12,
                        child: Text('${i + 1}', style: const TextStyle(fontSize: 12)),
                      ),
                      title: Text(recipe.steps[i]),
                    ),
                ],
              ),
            ),
          ),
          if (signal != null && signal.evidence.isNotEmpty && store.showPrices)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Why suggested: ${signal.score > 0 ? 'your household responded well before' : 'new option for variety'}.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
