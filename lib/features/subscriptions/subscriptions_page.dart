/// ADULT-013 Subscriptions — adult-only billing surface. Mock provider,
/// clearly labeled; kids can never reach this route (redirect + server rule).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../shared/errors.dart';
import '../../shared/models.dart';
import '../../shared/widgets.dart';

class SubscriptionsPage extends ConsumerWidget {
  const SubscriptionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(appStoreProvider);
    final ent = store.entitlement;
    return FcScaffold(
      title: 'Subscription',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FcCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current plan',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        ent.plan.label,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      if (ent.expiresAt != null)
                        Text(
                          ent.cancelAtPeriodEnd
                              ? 'Ends ${ent.expiresAt!.month}/${ent.expiresAt!.day}/${ent.expiresAt!.year} (cancels at period end)'
                              : 'Renews ${ent.expiresAt!.month}/${ent.expiresAt!.day}/${ent.expiresAt!.year}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                FcChip(
                  ent.verified ? 'Verified' : 'Unverified',
                  icon: ent.verified
                      ? Icons.verified_outlined
                      : Icons.error_outline,
                ),
              ],
            ),
          ),
          const SectionHeader('Plans'),
          _tier(
            context,
            store,
            EntitlementPlan.free,
            'Complete weekly plan, allergy safety, grocery totals, budget tracking, pantry entry, basic voting and challenges.',
          ),
          _tier(
            context,
            store,
            EntitlementPlan.plus,
            'More game rounds, more vote ballots, expanded beverage forecasts.',
          ),
          _tier(
            context,
            store,
            EntitlementPlan.familyPro,
            'Largest quotas and priority family features for the whole household.',
          ),
          const SizedBox(height: 12),
          Text(
            'One subscription covers the whole household — kids never see or pay for it. Demo checkout uses a mock provider; no real charge occurs.',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: FamilyCircleColors.muted),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.restore),
            label: const Text('Restore purchase'),
            onPressed: () {
              try {
                store.restorePurchase();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Purchase restored.')),
                );
              } on FcException catch (e) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(e.safeMessage)));
              }
            },
          ),
          if (ent.isPaid && !ent.cancelAtPeriodEnd) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Cancel at period end'),
              onPressed: () => store.cancelSubscription(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tier(
    BuildContext context,
    AppStore store,
    EntitlementPlan plan,
    String perks,
  ) {
    final current = store.entitlement.plan == plan;
    final scheme = Theme.of(context).colorScheme;
    return FcCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (current ? FamilyCircleColors.primary : scheme.primary)
                  .withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              switch (plan) {
                EntitlementPlan.free => Icons.eco_outlined,
                EntitlementPlan.plus => Icons.star_outline,
                EntitlementPlan.familyPro => Icons.workspace_premium_outlined,
              },
              size: 20,
              color: current
                  ? FamilyCircleColors.primary
                  : scheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      plan.label,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      plan.monthlyCents == 0
                          ? 'Free'
                          : '${fmtCents(plan.monthlyCents)}/mo',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(perks, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (current)
            const FcChip('Active', icon: Icons.check)
          else
            FilledButton.tonal(
              onPressed: () {
                try {
                  store.checkout(plan);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${plan.label} activated (demo).')),
                  );
                } on FcException catch (e) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(e.safeMessage)));
                }
              },
              child: const Text('Choose'),
            ),
        ],
      ),
    );
  }
}
