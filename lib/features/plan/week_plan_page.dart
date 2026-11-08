/// ADULT-002 Week plan — visual 7-day meal board, safe replacement,
/// basket estimate with provenance, approve/regenerate.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/family_circle_app.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../shared/ai.dart';
import '../../shared/catalog.dart' as catalog;
import '../../shared/errors.dart';
import '../../shared/models.dart';
import '../../shared/widgets.dart';

class WeekPlanPage extends ConsumerWidget {
  const WeekPlanPage({super.key});

  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _monthShort = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(appStoreProvider);
    final plan = store.plan;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Week plan'),
        actions: [
          IconButton(
            tooltip: 'Regenerate plan',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              try {
                store.generatePlan();
              } on FcException catch (e) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(e.safeMessage)));
              }
            },
          ),
        ],
      ),
      bottomNavigationBar: const AdultNavBar(current: '/plan'),
      body: SafeArea(
        child: plan == null
            ? _empty(context, store)
            : _plan(context, store, plan),
      ),
    );
  }

  Widget _empty(BuildContext context, AppStore store) {
    return Column(
      children: [
        const OfflineBanner(),
        Expanded(
          child: EmptyState(
            icon: Icons.calendar_view_week_outlined,
            title: 'No plan this week',
            message:
                'Generate a 7-day plan checked against allergies and budget.',
            actionLabel: 'Generate plan',
            onAction: () {
              try {
                store.generatePlan();
              } on FcException catch (e) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(e.safeMessage)));
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _plan(BuildContext context, AppStore store, WeekPlan plan) {
    final basket = plan.basket;
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final isToday = now.weekday - 1;
    final approved = plan.status == PlanStatus.approved;
    final filledSlots = plan.slots.length;
    final recipeCount = plan.slots
        .map((s) => catalog.recipes[s.recipeId])
        .whereType<CatalogRecipe>()
        .toSet()
        .length;

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const OfflineBanner(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: FcCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: (approved ? scheme.primary : context.kcWarning)
                            .withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        approved
                            ? Icons.verified_outlined
                            : Icons.edit_calendar_outlined,
                        color: approved ? scheme.primary : context.kcWarning,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            approved ? 'Plan approved' : 'Draft plan',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            approved
                                ? 'Ready for the week • revision ${plan.revision}'
                                : 'Review meals, prices and safety before approving',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    FcChip(
                      approved ? 'Approved' : 'Draft',
                      icon: approved
                          ? Icons.check_circle_outline
                          : Icons.edit_outlined,
                      color: approved ? scheme.primary : context.kcWarning,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _PlanMetric(
                      value: '$filledSlots',
                      label: 'meal slots',
                      icon: Icons.restaurant_menu_outlined,
                    ),
                    _PlanMetric(
                      value: '$recipeCount',
                      label: 'unique dishes',
                      icon: Icons.auto_awesome_motion_outlined,
                    ),
                    _PlanMetric(
                      value:
                          '${plan.weekStart.day}-${plan.weekStart.add(const Duration(days: 6)).day}',
                      label: _monthShort[plan.weekStart.month - 1],
                      icon: Icons.date_range_outlined,
                    ),
                  ],
                ),
                if (basket != null) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (store.showPrices)
                        FcChip(
                          'Est. ${fmtCents(basket.totalEstimateCents)}',
                          icon: Icons.shopping_basket_outlined,
                        ),
                      if (basket.unknownPriceIngredientIds.isNotEmpty)
                        FcChip(
                          '${basket.unknownPriceIngredientIds.length} unpriced item(s)',
                          icon: Icons.warning_amber_outlined,
                          color: context.kcWarning,
                        ),
                      if (basket.eligibleBenefitEstimateCents > 0 &&
                          store.showPrices)
                        FcChip(
                          'SNAP-eligible est. ${fmtCents(basket.eligibleBenefitEstimateCents)}',
                          icon: Icons.check_circle_outline,
                        ),
                    ],
                  ),
                ],
                if (plan.status == PlanStatus.draft)
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.check),
                        label: const Text('Approve plan'),
                        onPressed: () {
                          try {
                            store.approvePlan(plan.revision);
                          } on FcException catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.safeMessage)),
                            );
                          }
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        _WeekOverview(plan: plan, isToday: isToday),
        const SizedBox(height: 8),
        for (var day = 0; day < 7; day++)
          _DaySection(
            day: day,
            plan: plan,
            isToday: day == isToday,
            onSwap: (meal) => _showSwapSheet(context, store, day, meal),
          ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: AiMealIdeaCard(),
        ),
      ],
    );
  }

  void _showSwapSheet(
    BuildContext context,
    AppStore store,
    int day,
    MealType meal,
  ) {
    final options = store.eligibleRecipes(meal: meal);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(sheetContext).size.height * 0.62,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Text(
                'Safe ${meal.label} options',
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
              Text(
                'Only allergy-checked recipes are shown',
                style: Theme.of(sheetContext).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: options.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'No allergy-safe options for this meal yet — adjust member allergies or try another meal.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                        itemCount: options.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final r = options[index];
                          return Card(
                            clipBehavior: Clip.antiAlias,
                            child: ListTile(
                              leading: _MiniDishIcon(image: r.image),
                              title: Text(r.title),
                              subtitle: Text(
                                '${r.minutes} min • serves ${r.servings} • ${r.cuisine}',
                              ),
                              trailing: const Icon(Icons.swap_horiz),
                              onTap: () {
                                try {
                                  store.swapSlot(day, meal, r.id);
                                  Navigator.of(sheetContext).pop();
                                } on FcException catch (e) {
                                  Navigator.of(sheetContext).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(e.safeMessage)),
                                  );
                                }
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanMetric extends StatelessWidget {
  const _PlanMetric({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: scheme.primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekOverview extends StatelessWidget {
  const _WeekOverview({required this.plan, required this.isToday});

  final WeekPlan plan;
  final int isToday;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: .5),
          ),
        ),
        child: Row(
          children: [
            for (var day = 0; day < 7; day++)
              Expanded(
                child: Builder(
                  builder: (context) {
                    final date = plan.weekStart.add(Duration(days: day));
                    final count = plan.slots.where((s) => s.day == day).length;
                    final selected = day == isToday;
                    return Column(
                      children: [
                        Text(
                          WeekPlanPage._dayNames[day],
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: selected
                                    ? scheme.primary
                                    : scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selected
                                ? scheme.primary.withValues(alpha: .18)
                                : Colors.transparent,
                            border: Border.all(
                              color: selected
                                  ? scheme.primary.withValues(alpha: .5)
                                  : scheme.outlineVariant.withValues(alpha: .5),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '${date.day}',
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: selected
                                        ? scheme.primary
                                        : scheme.onSurface,
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$count',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DaySection extends StatelessWidget {
  const _DaySection({
    required this.day,
    required this.plan,
    required this.isToday,
    required this.onSwap,
  });

  final int day;
  final WeekPlan plan;
  final bool isToday;
  final void Function(MealType meal) onSwap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final date = plan.weekStart.add(Duration(days: day));
    final count = plan.slots.where((s) => s.day == day).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: FcCard(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isToday
                        ? scheme.primary.withValues(alpha: .16)
                        : scheme.surfaceContainerHigh.withValues(alpha: .55),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${date.day}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: isToday ? scheme.primary : scheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        WeekPlanPage._dayNames[day],
                        style: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '${WeekPlanPage._monthShort[date.month - 1]} ${date.day} • $count meal${count == 1 ? '' : 's'}',
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                if (isToday) FcChip('Today', color: scheme.primary),
              ],
            ),
            const SizedBox(height: 10),
            for (final meal in MealType.values) ...[
              _MealSlot(
                day: day,
                meal: meal,
                plan: plan,
                onSwap: () => onSwap(meal),
              ),
              if (meal != MealType.dinner) const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _MealSlot extends StatelessWidget {
  const _MealSlot({
    required this.day,
    required this.meal,
    required this.plan,
    required this.onSwap,
  });

  final int day;
  final MealType meal;
  final WeekPlan plan;
  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final slot = plan.slots
        .where((s) => s.day == day && s.meal == meal)
        .firstOrNull;
    final recipe = slot == null ? null : catalog.recipes[slot.recipeId];

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: recipe == null
          ? null
          : () => context.push('${AppRoute.recipeDetail.path}/${recipe.id}'),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: recipe == null
              ? scheme.surfaceContainerHigh.withValues(alpha: .28)
              : scheme.surfaceContainerHigh.withValues(alpha: .48),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: scheme.outlineVariant.withValues(
              alpha: recipe == null ? .25 : .45,
            ),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 70,
              height: 96,
              child: recipe == null
                  ? _EmptyDishIcon(meal: meal)
                  : DishImage(image: recipe.image, height: 96),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        switch (meal) {
                          MealType.breakfast => Icons.wb_sunny_outlined,
                          MealType.lunch => Icons.lunch_dining_outlined,
                          MealType.dinner => Icons.nightlight_outlined,
                        },
                        size: 15,
                        color: recipe == null
                            ? scheme.onSurfaceVariant
                            : scheme.primary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        meal.label,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: recipe == null
                              ? scheme.onSurfaceVariant
                              : scheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    recipe?.title ?? 'Not filled',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: recipe == null
                          ? scheme.onSurfaceVariant
                          : scheme.onSurface,
                      fontStyle: recipe == null ? FontStyle.italic : null,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    recipe == null
                        ? 'Choose a safe option'
                        : '${recipe.minutes} min • serves ${recipe.servings} • ${recipe.cuisine}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            if (recipe != null)
              IconButton(
                tooltip: 'Swap ${meal.label}',
                onPressed: onSwap,
                icon: Icon(Icons.swap_horiz, color: scheme.onSurfaceVariant),
              ),
          ],
        ),
      ),
    );
  }
}

class _MiniDishIcon extends StatelessWidget {
  const _MiniDishIcon({required this.image});

  final RecipeImage image;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final icon = switch (image.kind) {
      ImageKind.verifiedPhoto => Icons.restaurant_outlined,
      ImageKind.aiIllustration => Icons.auto_awesome_outlined,
      ImageKind.placeholder => Icons.dinner_dining_outlined,
    };
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: scheme.primary),
    );
  }
}

class _EmptyDishIcon extends StatelessWidget {
  const _EmptyDishIcon({required this.meal});

  final MealType meal;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: .55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: .4)),
      ),
      child: Icon(switch (meal) {
        MealType.breakfast => Icons.add_photo_alternate_outlined,
        MealType.lunch => Icons.add_photo_alternate_outlined,
        MealType.dinner => Icons.add_photo_alternate_outlined,
      }, color: scheme.onSurfaceVariant),
    );
  }
}

// ---------- AI meal idea (adult + explicit AI consent; never safety evidence) ----------

class AiMealIdeaCard extends ConsumerStatefulWidget {
  const AiMealIdeaCard({super.key});

  @override
  ConsumerState<AiMealIdeaCard> createState() => _AiMealIdeaCardState();
}

class _AiMealIdeaCardState extends ConsumerState<AiMealIdeaCard> {
  final _client = AiMealIdeaClient();
  AiResult? _idea;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _client.dispose();
    super.dispose();
  }

  Future<void> _ask(AppStore store) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final circle = store.circle!;
      final allergens = {
        for (final m in circle.activeMembers) ...m.hardAllergens,
      };
      // Only names of verified-safe catalog ingredients are sent — never
      // member names, events history or child data.
      final safeNames = store
          .eligibleRecipes()
          .expand((r) => r.needs)
          .map((n) => catalog.ingredients[n.ingredientId]?.name)
          .whereType<String>()
          .toSet()
          .toList();
      final result = await _client.mealIdea(
        hardAllergens: allergens,
        safeIngredientNames: safeNames,
        servings: circle.activeMembers.length,
        meal: MealType.dinner,
      );
      if (mounted) setState(() => _idea = result);
    } on FcException catch (e) {
      if (mounted) setState(() => _error = e.safeMessage);
    } catch (_) {
      if (mounted) setState(() => _error = 'AI is unavailable right now.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(appStoreProvider);
    if (store.actorIsMinor || !store.consent.aiProcessing) {
      return const SizedBox.shrink();
    }
    return FcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'AI meal idea',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              FcChip(
                'AI-generated',
                icon: Icons.auto_awesome,
                color: context.kcWarning,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_idea == null && _error == null)
            const Text(
              'Get one suggestion using only your verified-safe ingredients. It is never treated as allergy-verified.',
            ),
          if (_idea != null) ...[
            Text(_idea!.text),
            const SizedBox(height: 8),
            Text(
              'Model: ${_idea!.model} • Idea only — always re-check safety before cooking.',
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: context.kcWarning),
            ),
          ],
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            icon: const Icon(Icons.auto_awesome, size: 18),
            label: Text(
              _busy ? 'Asking…' : (_idea == null ? 'Ask AI' : 'Ask again'),
            ),
            onPressed: _busy ? null : () => _ask(store),
          ),
        ],
      ),
    );
  }
}
