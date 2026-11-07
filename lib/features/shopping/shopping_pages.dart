/// ADULT-004 Grocery list, SHARED-003 Trip review, ADULT-008 Spending,
/// ADULT-009 Shopping calendar.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/family_circle_app.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../shared/errors.dart';
import '../../shared/models.dart';
import '../../shared/widgets.dart';

// ---------- ADULT-004 Grocery list ----------

class GroceryListPage extends ConsumerWidget {
  const GroceryListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(appStoreProvider);
    final items = store.groceryList;
    final remaining = items.where((g) => !g.checked).length;
    final pricedTotal = items
        .where((g) => g.priced)
        .fold<int>(0, (s, g) => s + g.estimatedCents!);

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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '$remaining item${remaining == 1 ? '' : 's'} to buy',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  MoneyText(
                    pricedTotal,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
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
                  children: [
                    for (final g in items)
                      CheckboxListTile(
                        value: g.checked,
                        onChanged: (_) => store.toggleGrocery(g.ingredientId),
                        title: Text(
                          g.name,
                          style: TextStyle(
                            decoration: g.checked
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        subtitle: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              '${g.packs} pack${g.packs == 1 ? '' : 's'} • need ${fmtQty(g.requiredQty)}${g.pantryDeducted.amount > 0 ? ' • ${fmtQty(g.pantryDeducted)} from pantry' : ''}',
                            ),
                            if (g.offer != null && store.showPrices)
                              EstimateBadge(offer: g.offer!),
                            if (g.offer != null)
                              SnapBadge(
                                eligibility: g.offer!.benefitEligibility,
                              ),
                          ],
                        ),
                        secondary: g.priced && store.showPrices
                            ? Text(fmtCents(g.estimatedCents!))
                            : (!g.priced
                                  ? const Icon(
                                      Icons.help_outline,
                                      color: FamilyCircleColors.warning,
                                    )
                                  : null),
                      ),
                  ],
                ),
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

    return FcScaffold(
      title: 'Review your trip',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Confirm what you actually paid. Estimates stay labeled — your entry becomes the record.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          for (final g in checked) ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        g.name,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        '${g.packs} pack${g.packs == 1 ? '' : 's'} • est. ${fmtCents(g.estimatedCents!)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 110,
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
            const Divider(height: 24),
          ],
          Row(
            children: [
              Expanded(
                child: Text(
                  'Estimated total',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                fmtCents(estTotal),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(child: Text('SNAP-verified portion (estimate)')),
              Text(fmtCents(snapEst)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Items with unverified SNAP eligibility are never counted as covered.',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: FamilyCircleColors.warning),
          ),
          const SizedBox(height: 24),
          FilledButton(
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
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(e.safeMessage)));
                    }
                  },
            child: const Text('Confirm purchase'),
          ),
        ],
      ),
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
    return FcScaffold(
      title: 'Spending',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
          Text(
            'Budgets are manual entries — no account or EBT balances are synced.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SectionHeader('Trips'),
          if (store.trips.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No confirmed trips yet.'),
            )
          else
            for (final t in store.trips.reversed)
              ListTile(
                leading: const Icon(Icons.receipt_long_outlined),
                title: Text(
                  '${t.date.month}/${t.date.day} — ${t.items.length} items',
                ),
                subtitle: Text(
                  'SNAP ${fmtCents(t.snapCents)} • Cash ${fmtCents(t.cashCents)}',
                ),
                trailing: Text(fmtCents(t.totalCents)),
              ),
        ],
      ),
    );
  }

  Widget _budgetRow(BuildContext context, String label, int total, int spent) {
    final frac = total <= 0 ? 0.0 : (spent / total).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.titleSmall),
            ),
            Text('${fmtCents(spent)} of ${fmtCents(total)}'),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: frac,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
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
    final nextTrip = DateTime.now().add(
      Duration(days: store.shoppingIntervalDays),
    );
    final perishables = store.pantry
        .where((p) => p.expiringSoon(nextTrip))
        .toList();

    DateTime? nextDeposit;
    if (budget.depositDay != null) {
      final now = DateTime.now();
      var d = DateTime(now.year, now.month, budget.depositDay!);
      if (d.isBefore(now)) {
        d = DateTime(now.year, now.month + 1, budget.depositDay!);
      }
      nextDeposit = d;
    }

    return FcScaffold(
      title: 'Shopping calendar',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'How often do you shop?',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 3, label: Text('2x / week')),
              ButtonSegment(value: 7, label: Text('Weekly')),
              ButtonSegment(value: 14, label: Text('2 weeks')),
            ],
            selected: {store.shoppingIntervalDays},
            onSelectionChanged: (s) => store.setShoppingInterval(s.first),
          ),
          const SizedBox(height: 24),
          FcCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.shopping_cart_outlined),
                  title: const Text('Next suggested trip'),
                  subtitle: Text('${nextTrip.month}/${nextTrip.day}'),
                ),
                if (nextDeposit != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.payments_outlined),
                    title: const Text('Next benefit deposit (manual)'),
                    subtitle: Text('${nextDeposit.month}/${nextDeposit.day}'),
                  ),
              ],
            ),
          ),
          const SectionHeader('Perishables before next trip'),
          if (perishables.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Nothing expiring before the next trip.'),
            )
          else
            for (final p in perishables)
              ListTile(
                leading: const Icon(
                  Icons.schedule_outlined,
                  color: FamilyCircleColors.warning,
                ),
                title: Text(p.ingredientId.replaceAll('_', ' ')),
                subtitle: Text(
                  'Expires ${p.expiresAt!.month}/${p.expiresAt!.day}',
                ),
              ),
        ],
      ),
    );
  }
}
