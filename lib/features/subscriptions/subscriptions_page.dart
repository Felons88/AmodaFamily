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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          FcCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary
                            .withValues(alpha: .14),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        Icons.workspace_premium_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current plan',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          Text(
                            ent.plan.label,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
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
                      color: ent.verified
                          ? FamilyCircleColors.primary
                          : FamilyCircleColors.warning,
                    ),
                  ],
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
          const SectionHeader('Billing'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FcCard(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.restore),
                    title: const Text('Restore purchase'),
                    subtitle: const Text('Check an existing subscription'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      try {
                        store.restorePurchase();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Purchase restored.')),
                        );
                      } on FcException catch (e) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(e.safeMessage)));
                      }
                    },
                  ),
                  if (ent.isPaid && !ent.cancelAtPeriodEnd)
                    ListTile(
                      leading: const Icon(Icons.cancel_outlined),
                      title: const Text('Cancel at period end'),
                      subtitle: const Text('Keep access until renewal date'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => store.cancelSubscription(),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'One subscription covers the whole household — kids never see or pay for it. Demo checkout uses a mock provider; no real charge occurs.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: FcCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: (current ? FamilyCircleColors.primary : scheme.primary)
                    .withValues(alpha: .14),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(switch (plan) {
                EntitlementPlan.free => Icons.eco_outlined,
                EntitlementPlan.plus => Icons.star_outline,
                EntitlementPlan.familyPro => Icons.workspace_premium_outlined,
              }, color: current ? FamilyCircleColors.primary : scheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        plan.label,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        plan.monthlyCents == 0
                            ? 'Free'
                            : '${fmtCents(plan.monthlyCents)}/mo',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    perks,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (current)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: FcChip('Active', icon: Icons.check),
              )
            else
              FilledButton.tonal(
                onPressed: () {
                  try {
                    store.checkout(plan);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${plan.label} activated (demo).'),
                      ),
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
      ),
    );
  }
}
