/// ADULT-003 Recipe detail — AnyList-style hero, metadata, ingredients,
/// substitutions, allergen uncertainty disclosure and numbered steps.
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
    final eligible = eligibility?.isEligible ?? false;
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
        padding: EdgeInsets.zero,
        children: [
          Stack(
            children: [
              DishImage(image: recipe.image, height: 250),
              if (recipe.image.credit != null)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 10,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: .48),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        recipe.image.credit!,
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  recipe.summary,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 42,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _MetaPill(
                        icon: Icons.restaurant_outlined,
                        label: recipe.meal.label,
                      ),
                      _MetaPill(
                        icon: Icons.schedule_outlined,
                        label: '${recipe.minutes} min',
                      ),
                      _MetaPill(
                        icon: Icons.people_outline,
                        label: 'Serves ${recipe.servings}',
                      ),
                      _MetaPill(icon: Icons.public, label: recipe.cuisine),
                      if (recipe.kidFriendly)
                        const _MetaPill(
                          icon: Icons.child_care_outlined,
                          label: 'Kid friendly',
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _EligibilityCard(
                  eligible: eligible,
                  code: eligibility?.code.name,
                ),
              ],
            ),
          ),
          const SectionHeader('Ingredients'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FcCard(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  for (var i = 0; i < recipe.needs.length; i++)
                    _IngredientRow(
                      need: recipe.needs[i],
                      recipe: recipe,
                      showDivider: i < recipe.needs.length - 1,
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
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
              child: Column(
                children: [
                  for (var i = 0; i < recipe.steps.length; i++)
                    _StepRow(
                      index: i + 1,
                      text: recipe.steps[i],
                      last: i == recipe.steps.length - 1,
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
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh.withValues(alpha: .6),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: .45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: scheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _EligibilityCard extends StatelessWidget {
  const _EligibilityCard({required this.eligible, required this.code});

  final bool eligible;
  final String? code;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = eligible
        ? FamilyCircleColors.primary
        : FamilyCircleColors.error;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: .3)),
      ),
      child: Row(
        children: [
          Icon(
            eligible
                ? Icons.verified_user_outlined
                : Icons.warning_amber_outlined,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              eligible
                  ? 'Checked safe for your household'
                  : 'Not eligible for this household: ${code ?? 'unknown'}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({
    required this.need,
    required this.recipe,
    required this.showDivider,
  });

  final RecipeNeed need;
  final CatalogRecipe recipe;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ingredient = catalog.ingredients[need.ingredientId];
    final recipeSubstitution = recipe.substitutions[need.ingredientId];
    return Builder(
      builder: (context) {
        final details = <String>[
          '${need.amount} ${switch (ingredient?.stockUnit) {
            FoodUnit.grams => 'g',
            FoodUnit.milliliters => 'ml',
            FoodUnit.pieces => 'pc',
            null => '',
          }}',
          if (ingredient != null && ingredient.allergens.isNotEmpty)
            'contains ${ingredient.allergens.join(', ').replaceAll('_', ' ')}',
          if (recipeSubstitution != null)
            'swap: ${catalog.ingredients[recipeSubstitution]?.name ?? recipeSubstitution}',
        ];
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      Icons.eco_outlined,
                      size: 18,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ingredient?.name ?? need.ingredientId,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          details.join(' • '),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (showDivider)
              Divider(
                height: 1,
                color: scheme.outlineVariant.withValues(alpha: .45),
              ),
          ],
        );
      },
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.index, required this.text, required this.last});

  final int index;
  final String text;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: .15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: .35),
                  ),
                ),
                child: Center(
                  child: Text(
                    '$index',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              if (!last)
                Expanded(
                  child: Container(
                    width: 1.5,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: scheme.outlineVariant.withValues(alpha: .55),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 8 : 16),
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(height: 1.45),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
