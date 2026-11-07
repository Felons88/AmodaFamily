/// ADULT-004 Grocery list, SHARED-003 Trip review, ADULT-008 Spending,
/// ADULT-009 Shopping calendar.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/family_circle_app.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../shared/catalog.dart' as catalog;
import '../../shared/errors.dart';
import '../../shared/models.dart';
import '../../shared/widgets.dart';

// ---------- ADULT-004 Grocery list ----------

class GroceryListPage extends ConsumerWidget {
  const GroceryListPage({super.key});

  static const _categoryOrder = [
    'Produce',
    'Dairy & eggs',
    'Meat & fish',
    'Pantry & staples',
    'Other',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(appStoreProvider);
    final items = store.groceryList;
    final remaining = items.where((g) => !g.checked).length;
    final checked = items.length - remaining;
    final pricedTotal = items
        .where((g) => g.priced)
        .fold<int>(0, (s, g) => s + g.estimatedCents!);
    final grouped = <String, List<GroceryLine>>{};
    for (final item in items) {
      grouped.putIfAbsent(_groceryCategory(item), () => []).add(item);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grocery list'),
        actions: [
          if (items.any((g) => g.checked))
            TextButton(
              onPressed: () => context.push(AppRoute.tripReview.path),
              child: const Text('Review trip'),
            ),
        ],
      ),
      bottomNavigationBar: const AdultNavBar(current: '/shop'),
      body: SafeArea(
        child: Column(
          children: [
            const OfflineBanner(),
            _ListSummary(
              remaining: remaining,
              checked: checked,
              total: items.length,
              pricedTotal: pricedTotal,
            ),
            const SizedBox(height: 8),
            if (items.isEmpty)
              const Expanded(
                child: EmptyState(
                  icon: Icons.shopping_basket_outlined,
                  title: 'List is empty',
                  message: 'Approve a week plan and your consolidated grocery list appears here.',
                ),
              )
            else
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 12),
                  children: [
                    for (final category in _categoryOrder)
                      if (grouped[category]?.isNotEmpty ?? false) ...[
                        _AisleHeader(
                          title: category,
                          count: grouped[category]!.length,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: FcCard(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Column(
                              children: [
                                for (
                                  var i = 0;
                                  i < grouped[category]!.length;
                                  i++
                                ) ...[
                                  _GroceryTile(
                                    item: grouped[category]![i],
                                    showPrices: store.showPrices,
                                    onTap: () => store.toggleGrocery(
                                      grouped[category]![i].ingredientId,
                                    ),
                                  ),
                                  if (i < grouped[category]!.length - 1)
                                    Divider(
                                      height: 1,
                                      indent: 62,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outlineVariant
                                          .withValues(alpha: .45),
                                    ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                  ],
                ),
              ),
            if (items.isNotEmpty)
              _ListFooter(
                remaining: remaining,
                checked: checked,
                total: items.length,
                pricedTotal: pricedTotal,
              ),
          ],
        ),
      ),
    );
  }
}

String _groceryCategory(GroceryLine item) {
  return switch (item.ingredientId) {
    'banana' ||
    'apple' ||
    'potato' ||
    'carrot' ||
    'onion' ||
    'cucumber' ||
    'lettuce' ||
    'bell_pepper' => 'Produce',
    'milk_whole' ||
    'cheese_cheddar' ||
    'yogurt_plain' ||
    'egg' => 'Dairy & eggs',
    'chicken_breast' || 'ground_beef' || 'salmon' => 'Meat & fish',
    'rolled_oats' ||
    'rice_white' ||
    'pasta' ||
    'tomato_sauce' ||
    'black_beans' ||
    'tortilla' ||
    'flour_tortilla' ||
    'olive_oil' ||
    'lentils' ||
    'frozen_veg' ||
    'peanut_butter' ||
    'bread_whole' ||
    'hummus' => 'Pantry & staples',
    _ => 'Other',
  };
}

IconData _categoryIcon(String category) => switch (category) {
  'Produce' => Icons.eco_outlined,
  'Dairy & eggs' => Icons.egg_alt_outlined,
  'Meat & fish' => Icons.set_meal_outlined,
  'Pantry & staples' => Icons.inventory_2_outlined,
  _ => Icons.shopping_basket_outlined,
};

class _ListSummary extends StatelessWidget {
  const _ListSummary({
    required this.remaining,
    required this.checked,
    required this.total,
    required this.pricedTotal,
  });

  final int remaining;
  final int checked;
  final int total;
  final int pricedTotal;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fraction = total == 0 ? 0.0 : checked / total;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: FcCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                Icons.shopping_basket_outlined,
                color: scheme.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$remaining item${remaining == 1 ? '' : 's'} to buy',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    total == 0
                        ? 'Your list is ready when a plan is approved'
                        : '$checked of $total checked off',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: fraction,
                      minHeight: 7,
                      backgroundColor: scheme.surfaceContainerHighest,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Estimate',
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
                MoneyText(
                  pricedTotal,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AisleHeader extends StatelessWidget {
  const _AisleHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Row(
        children: [
          Icon(_categoryIcon(title), size: 18, color: scheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _GroceryTile extends StatelessWidget {
  const _GroceryTile({
    required this.item,
    required this.showPrices,
    required this.onTap,
  });

  final GroceryLine item;
  final bool showPrices;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: item.checked ? scheme.primary : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: item.checked ? scheme.primary : scheme.outlineVariant,
                  width: 1.6,
                ),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                child: item.checked
                    ? Icon(
                        Icons.check,
                        key: const ValueKey('checked'),
                        size: 18,
                        color: scheme.onPrimary,
                      )
                    : Icon(
                        Icons.circle_outlined,
                        key: const ValueKey('unchecked'),
                        size: 18,
                        color: scheme.onSurfaceVariant,
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 180),
                    style: Theme.of(context).textTheme.titleSmall!.copyWith(
                      fontWeight: FontWeight.w700,
                      decoration: item.checked
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      color: item.checked
                          ? scheme.onSurfaceVariant
                          : scheme.onSurface,
                    ),
                    child: Text(item.name),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '${item.packs} pack${item.packs == 1 ? '' : 's'} • need ${fmtQty(item.requiredQty)}${item.pantryDeducted.amount > 0 ? ' • ${fmtQty(item.pantryDeducted)} from pantry' : ''}',
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                      if (item.offer != null && showPrices)
                        EstimateBadge(offer: item.offer!),
                      if (item.offer != null)
                        SnapBadge(eligibility: item.offer!.benefitEligibility),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (item.priced && showPrices)
              Text(
                fmtCents(item.estimatedCents!),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  decoration: item.checked
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                  color: item.checked
                      ? scheme.onSurfaceVariant
                      : scheme.onSurface,
                ),
              )
            else if (!item.priced)
              const Tooltip(
                message: 'Price estimate unavailable',
                child: Icon(
                  Icons.help_outline,
                  color: FamilyCircleColors.warning,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ListFooter extends StatelessWidget {
  const _ListFooter({
    required this.remaining,
    required this.checked,
    required this.total,
    required this.pricedTotal,
  });

  final int remaining;
  final int checked;
  final int total;
  final int pricedTotal;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fraction = total == 0 ? 0.0 : checked / total;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: scheme.outlineVariant.withValues(alpha: .55)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$remaining left • $checked done',
                        style: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: fraction,
                          minHeight: 8,
                          backgroundColor: scheme.surfaceContainerHighest,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Trip estimate',
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    MoneyText(
                      pricedTotal,
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- SHARED-003 Trip review ----------

class TripReviewPage extends ConsumerStatefulWidget {
  const TripReviewPage({super.key});

  @override
  ConsumerState<TripReviewPage> createState() => _TripReviewPageState();
}

class _TripReviewPageState extends ConsumerState<TripReviewPage> {
  final Map<String, TextEditingController> _actuals = {};

  @override
  void dispose() {
    for (final c in _actuals.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(appStoreProvider);
    final checked = store.groceryList
        .where((g) => g.checked && g.priced)
        .toList();
    final estTotal = checked.fold<int>(0, (s, g) => s + g.estimatedCents!);
    final snapEst = checked
        .where(
          (g) => g.offer!.benefitEligibility == BenefitEligibility.eligible,
        )
        .fold<int>(0, (s, g) => s + g.estimatedCents!);
    final scheme = Theme.of(context).colorScheme;

    return FcScaffold(
      title: 'Review your trip',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          FcCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    Icons.receipt_long_outlined,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Confirm what you actually paid. Estimates stay labeled — your entry becomes the record.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (checked.isEmpty)
            const EmptyState(
              icon: Icons.checklist_outlined,
              title: 'Nothing checked yet',
              message:
                  'Check items on the grocery list, then review the trip here.',
            )
          else ...[
            for (final g in checked)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: FcCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              g.name,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${g.packs} pack${g.packs == 1 ? '' : 's'} • est. ${fmtCents(g.estimatedCents!)}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 112,
                        child: TextField(
                          controller: _actuals.putIfAbsent(
                            g.ingredientId,
                            () => TextEditingController(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Actual',
                            prefixText: r'$',
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            FcCard(
              child: Column(
                children: [
                  _totalRow(
                    context,
                    'Estimated total',
                    fmtCents(estTotal),
                    strong: true,
                  ),
                  const Divider(height: 20),
                  _totalRow(
                    context,
                    'SNAP-verified portion (estimate)',
                    fmtCents(snapEst),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.verified_outlined,
                        size: 16,
                        color: FamilyCircleColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Items with unverified SNAP eligibility are never counted as covered.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Confirm purchase'),
                onPressed: checked.isEmpty
                    ? null
                    : () {
                        try {
                          final actuals = <String, int>{
                            for (final e in _actuals.entries)
                              if (double.tryParse(e.value.text.trim()) != null)
                                e.key: (double.parse(e.value.text.trim()) * 100)
                                    .round(),
                          };
                          store.confirmTrip(actuals);
                          context.pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Trip confirmed. Pantry updated.'),
                            ),
                          );
                        } on FcException catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.safeMessage)),
                          );
                        }
                      },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _totalRow(
    BuildContext context,
    String label,
    String value, {
    bool strong = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: strong
                ? Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)
                : Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Text(
          value,
          style:
              (strong
                      ? Theme.of(context).textTheme.titleMedium
                      : Theme.of(context).textTheme.bodyLarge)
                  ?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

// ---------- ADULT-008 Spending ----------

class SpendingPage extends ConsumerWidget {
  const SpendingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(appStoreProvider);
    final budget = store.budget;
    final remaining = budget.remainingCents;
    return FcScaffold(
      title: 'Spending',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          FcCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary
                            .withValues(alpha: .14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Remaining this period',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          Text(
                            fmtCents(remaining),
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                    FcChip(
                      '${fmtCents(budget.spentCents)} spent',
                      icon: Icons.trending_up,
                      color:
                          budget.spentCents > budget.totalCents &&
                              budget.totalCents > 0
                          ? FamilyCircleColors.error
                          : FamilyCircleColors.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FcCard(
            child: Column(
              children: [
                _budgetRow(
                  context,
                  'Cash',
                  budget.cashCents,
                  budget.spentCashCents,
                ),
                const Divider(height: 24),
                _budgetRow(
                  context,
                  'SNAP (manual)',
                  budget.snapCents,
                  budget.spentSnapCents,
                ),
                const Divider(height: 24),
                _budgetRow(
                  context,
                  'Total',
                  budget.totalCents,
                  budget.spentCents,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Budgets are manual entries — no account or EBT balances are synced.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _editBudget(context, store),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                ),
              ],
            ),
          ),
          const SectionHeader('Trips'),
          if (store.trips.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('No confirmed trips yet.'),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FcCard(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    for (var i = 0; i < store.trips.length; i++) ...[
                      _tripTile(
                        context,
                        store.trips[store.trips.length - 1 - i],
                      ),
                      if (i < store.trips.length - 1)
                        Divider(
                          height: 1,
                          indent: 62,
                          color: Theme.of(context).colorScheme.outlineVariant
                              .withValues(alpha: .45),
                        ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _editBudget(BuildContext context, AppStore store) {
    final cash = TextEditingController(
      text: (store.budget.cashCents / 100).toStringAsFixed(2),
    );
    final snap = TextEditingController(
      text: (store.budget.snapCents / 100).toStringAsFixed(2),
    );
    final deposit = TextEditingController(
      text: store.budget.depositDay?.toString() ?? '',
    );
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit budget'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: cash,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Cash per period (\$)',
              ),
            ),
            TextField(
              controller: snap,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'SNAP per period (\$)',
              ),
            ),
            TextField(
              controller: deposit,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Deposit day (1-31, optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              int cents(String s) => ((double.tryParse(s) ?? -1) * 100).round();
              final cashCents = cents(cash.text);
              final snapCents = cents(snap.text);
              final dayText = deposit.text.trim();
              final day = dayText.isEmpty ? null : int.tryParse(dayText);
              try {
                store.setBudget(
                  cashCents: cashCents,
                  snapCents: snapCents,
                  depositDay: day,
                );
                Navigator.of(dialogContext).pop();
              } on FcException catch (e) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(e.safeMessage)));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _tripTile(BuildContext context, ShoppingTrip t) {
    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(
          Icons.receipt_long_outlined,
          size: 19,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(
        '${t.date.month}/${t.date.day}/${t.date.year} — ${t.items.length} item${t.items.length == 1 ? '' : 's'}',
        style: Theme.of(context).textTheme.titleSmall,
      ),
      subtitle: Text(
        'SNAP ${fmtCents(t.snapCents)} • Cash ${fmtCents(t.cashCents)}',
      ),
      trailing: Text(
        fmtCents(t.totalCents),
        style: Theme.of(context).textTheme.titleSmall
            ?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _budgetRow(BuildContext context, String label, int total, int spent) {
    final frac = total <= 0 ? 0.0 : (spent / total).clamp(0.0, 1.0);
    final over = spent > total && total > 0;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            Text(
              '${fmtCents(spent)} of ${fmtCents(total)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: over ? FamilyCircleColors.error : null,
                fontWeight: over ? FontWeight.w700 : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: LinearProgressIndicator(
            value: frac,
            minHeight: 9,
            backgroundColor: scheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              over ? FamilyCircleColors.error : scheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------- ADULT-009 Shopping calendar ----------

class ShoppingCalendarPage extends ConsumerWidget {
  const ShoppingCalendarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(appStoreProvider);
    final budget = store.budget;
    final now = DateTime.now();
    final nextTrip = now.add(Duration(days: store.shoppingIntervalDays));
    final perishables = store.pantry
        .where((p) => p.expiringSoon(nextTrip))
        .toList();

    DateTime? nextDeposit;
    if (budget.depositDay != null) {
      var d = DateTime(now.year, now.month, budget.depositDay!);
      if (d.isBefore(now)) {
        d = DateTime(now.year, now.month + 1, budget.depositDay!);
      }
      nextDeposit = d;
    }

    return FcScaffold(
      title: 'Shopping calendar',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          FcCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary
                            .withValues(alpha: .14),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(
                        Icons.event_repeat_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'How often do you shop?',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            'Kinplora spaces trips around expiry dates.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 3, label: Text('2x / week')),
                      ButtonSegment(value: 7, label: Text('Weekly')),
                      ButtonSegment(value: 14, label: Text('2 weeks')),
                    ],
                    selected: {store.shoppingIntervalDays},
                    onSelectionChanged: (s) =>
                        store.setShoppingInterval(s.first),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FcCard(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary
                          .withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      Icons.shopping_cart_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  title: const Text('Next suggested trip'),
                  subtitle: Text(
                    '${nextTrip.month}/${nextTrip.day}/${nextTrip.year}',
                  ),
                  trailing: FcChip(
                    'In ${store.shoppingIntervalDays}d',
                    icon: Icons.schedule_outlined,
                  ),
                ),
                if (nextDeposit != null)
                  ListTile(
                    leading: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: FamilyCircleColors.tertiary.withValues(
                          alpha: .12,
                        ),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        Icons.payments_outlined,
                        color: FamilyCircleColors.tertiary,
                      ),
                    ),
                    title: const Text('Next benefit deposit (manual)'),
                    subtitle: Text(
                      '${nextDeposit.month}/${nextDeposit.day}/${nextDeposit.year}',
                    ),
                  ),
              ],
            ),
          ),
          const SectionHeader('Perishables before next trip'),
          if (perishables.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Nothing expiring before the next trip.'),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FcCard(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    for (var i = 0; i < perishables.length; i++) ...[
                      ListTile(
                        leading: const Icon(
                          Icons.schedule_outlined,
                          color: FamilyCircleColors.warning,
                        ),
                        title: Text(
                          catalog
                                  .ingredients[perishables[i].ingredientId]
                                  ?.name ??
                              perishables[i].ingredientId.replaceAll('_', ' '),
                        ),
                        subtitle: Text(
                          'Expires ${perishables[i].expiresAt!.month}/${perishables[i].expiresAt!.day}/${perishables[i].expiresAt!.year}',
                        ),
                      ),
                      if (i < perishables.length - 1)
                        Divider(
                          height: 1,
                          indent: 56,
                          color: Theme.of(context).colorScheme.outlineVariant
                              .withValues(alpha: .45),
                        ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
