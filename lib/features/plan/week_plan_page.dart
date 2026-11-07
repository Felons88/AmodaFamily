/// ADULT-002 Week plan — 7 days x 3 meal slots, safe replacement,
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
            icon: Icons.calendar_month_outlined,
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
    final isToday = DateTime.now().weekday - 1;
    final approved = plan.status == PlanStatus.approved;
    return ListView(
      children: [
        const OfflineBanner(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FcCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: (approved
                                ? FamilyCircleColors.primary
                                : FamilyCircleColors.warning)
                            .withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        approved
                            ? Icons.check_circle_outline
                            : Icons.edit_calendar_outlined,
                        size: 18,
                        color: approved
                            ? FamilyCircleColors.primary
                            : FamilyCircleColors.warning,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            approved ? 'Approved plan' : 'Draft plan',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            approved
                                ? 'Ready for the week'
                                : 'Review before approving',
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
                      color: approved
                          ? FamilyCircleColors.primary
                          : FamilyCircleColors.warning,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (basket != null)
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
                          color: FamilyCircleColors.warning,
                        ),
                      if (basket.eligibleBenefitEstimateCents > 0 &&
                          store.showPrices)
                        FcChip(
                          'SNAP-eligible est. ${fmtCents(basket.eligibleBenefitEstimateCents)}',
                          icon: Icons.check_circle_outline,
                        ),
                    ],
                  ),
                if (plan.status == PlanStatus.draft)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
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
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        for (var day = 0; day < 7; day++)
          FcCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _dayNames[day],
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    if (day == isToday) ...[
                      const SizedBox(width: 8),
                      const FcChip('Today', color: FamilyCircleColors.primary),
                    ],
                  ],
                ),
                const Divider(height: 16),
                for (final meal in MealType.values)
                  _slot(context, store, plan, day, meal),
              ],
            ),
          ),
        const AiMealIdeaCard(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _slot(
    BuildContext context,
    AppStore store,
    WeekPlan plan,
    int day,
    MealType meal,
  ) {
    final slot = plan.slots
        .where((s) => s.day == day && s.meal == meal)
        .firstOrNull;
    final recipe = slot == null ? null : catalog.recipes[slot.recipeId];
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: (recipe == null
                  ? FamilyCircleColors.muted
                  : scheme.primary)
              .withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          switch (meal) {
            MealType.breakfast => Icons.wb_sunny_outlined,
            MealType.lunch => Icons.lunch_dining_outlined,
            MealType.dinner => Icons.nightlight_outlined,
          },
          size: 16,
          color: recipe == null ? FamilyCircleColors.muted : scheme.primary,
        ),
      ),
      title: Text(
        recipe?.title ?? 'Not filled',
        style: recipe == null
            ? Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              )
            : null,
      ),
      subtitle: Text(
        recipe == null
            ? meal.label
            : '${meal.label} • ${recipe.minutes} min',
      ),
      onTap: recipe == null
          ? null
          : () => context.push('${AppRoute.recipeDetail.path}/${recipe.id}'),
      trailing: recipe == null
          ? null
          : IconButton(
              tooltip: 'Swap ${meal.label}',
              icon: Icon(
                Icons.swap_horiz,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
              onPressed: () => _showSwapSheet(context, store, day, meal),
            ),
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
          height: MediaQuery.of(sheetContext).size.height * 0.6,
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
                child: ListView(
                  children: [
                    for (final r in options)
                      ListTile(
                        title: Text(r.title),
                        subtitle: Text(
                          '${r.minutes} min • serves ${r.servings}',
                        ),
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
      final allergens = {for (final m in circle.activeMembers) ...m.hardAllergens};
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
                child: Text('AI meal idea', style: Theme.of(context).textTheme.titleSmall),
              ),
              const FcChip('AI-generated', icon: Icons.auto_awesome, color: FamilyCircleColors.warning),
            ],
          ),
          const SizedBox(height: 8),
          if (_idea == null && _error == null)
            const Text('Get one suggestion using only your verified-safe ingredients. It is never treated as allergy-verified.'),
          if (_idea != null) ...[
            Text(_idea!.text),
            const SizedBox(height: 8),
            Text(
              'Model: ${_idea!.model} • Idea only — always re-check safety before cooking.',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: FamilyCircleColors.warning),
            ),
          ],
          if (_error != null) Text(_error!, style: const TextStyle(color: FamilyCircleColors.error)),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            icon: const Icon(Icons.auto_awesome, size: 18),
            label: Text(_busy ? 'Asking…' : (_idea == null ? 'Ask AI' : 'Ask again')),
            onPressed: _busy ? null : () => _ask(store),
          ),
        ],
      ),
    );
  }
}
