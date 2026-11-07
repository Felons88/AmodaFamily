/// More tab: grouped hub for remaining adult destinations and session
/// controls.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/family_circle_app.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../shared/models.dart';
import '../../shared/widgets.dart';

class MorePage extends ConsumerWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(appStoreProvider);
    final circle = store.circle;
    final actor = store.actor;
    final entries = [
      (
        Icons.event_repeat_outlined,
        'Shopping calendar',
        'Trips & cadence',
        AppRoute.calendar.path,
      ),
      (
        Icons.add_shopping_cart_outlined,
        'Grocery list',
        'What to buy next trip',
        AppRoute.shop.path,
      ),
      (
        Icons.kitchen_outlined,
        'Pantry',
        'What you have on hand',
        AppRoute.pantry.path,
      ),
      (
        Icons.local_drink_outlined,
        'Drinks',
        'Beverage profiles & forecast',
        AppRoute.drinks.path,
      ),
    ];
    final household = [
      (
        Icons.people_outline,
        'Members',
        'Manage household & kids',
        AppRoute.members.path,
      ),
      (
        Icons.face_retouching_natural_outlined,
        'Kids mode',
        'Kid-safe home, votes & quests',
        AppRoute.kidsHome.path,
      ),
      (
        Icons.sports_esports_outlined,
        'Family games',
        '16 games the whole household can play',
        AppRoute.games.path,
      ),
      (
        Icons.how_to_vote_outlined,
        'Votes',
        'Family ballots',
        AppRoute.votes.path,
      ),
      (
        Icons.account_balance_wallet_outlined,
        'Spending',
        'Budget vs actuals',
        AppRoute.spending.path,
      ),
    ];
    final personal = [
      (
        Icons.insights_outlined,
        'Food insights',
        'Learned tastes & corrections',
        AppRoute.insights.path,
      ),
      (
        Icons.menu_book_outlined,
        'Recipe vault',
        'Favorites & history',
        AppRoute.vault.path,
      ),
      (
        Icons.notifications_outlined,
        'Notifications',
        'Channels & quiet hours',
        AppRoute.notifications.path,
      ),
      (
        Icons.feedback_outlined,
        'Feedback',
        'Tell us about a meal',
        AppRoute.feedback.path,
      ),
    ];
    final system = [
      (
        Icons.cloud_off_outlined,
        'Offline & sync',
        'Pending changes',
        AppRoute.offlineStatus.path,
      ),
      (
        Icons.workspace_premium_outlined,
        'Subscription',
        'Plans & billing',
        AppRoute.subscriptions.path,
      ),
      (
        Icons.privacy_tip_outlined,
        'Privacy',
        'Data controls & export',
        AppRoute.privacy.path,
      ),
    ];

    Widget section(
      String title,
      List<(IconData, String, String, String)> items,
    ) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FcCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      indent: 68,
                      color: Theme.of(context).colorScheme.outlineVariant
                          .withValues(alpha: .45),
                    ),
                  _MoreTile(entry: items[i]),
                ],
              ],
            ),
          ),
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      bottomNavigationBar: const AdultNavBar(current: '/more'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const OfflineBanner(),
            _ProfileSummary(
              name: actor?.name ?? 'Adult',
              circleName: circle?.name ?? 'Household',
              memberCount: circle?.activeMembers.length ?? 0,
              plan: store.entitlement.plan.label,
              isDemo: store.isDemoMode,
            ),
            section('Plan & shop', entries),
            section('Household', household),
            section('You', personal),
            section('App', system),
            const SectionHeader('Session'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FcCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.wifi_off_outlined),
                      title: const Text('Offline mode'),
                      subtitle: const Text(
                        'Manually enable to test offline behavior and queued changes',
                      ),
                      value: store.isOffline,
                      onChanged: (v) => store.setOffline(v),
                    ),
                    Divider(
                      height: 1,
                      indent: 68,
                      color: Theme.of(context).colorScheme.outlineVariant
                          .withValues(alpha: .45),
                    ),
                    ListTile(
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: FamilyCircleColors.error.withValues(
                            alpha: .12,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.logout,
                          color: FamilyCircleColors.error,
                          size: 19,
                        ),
                      ),
                      title: const Text('Sign out'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        store.signOut();
                        context.go(AppRoute.welcome.path);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary({
    required this.name,
    required this.circleName,
    required this.memberCount,
    required this.plan,
    this.isDemo = false,
  });

  final String name;
  final String circleName;
  final int memberCount;
  final String plan;
  final bool isDemo;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.primary.withValues(alpha: .16),
              scheme.primary.withValues(alpha: .03),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: scheme.primary.withValues(alpha: .22)),
        ),
        child: Row(
          children: [
            MemberAvatar(name: name, size: 52),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hi, $name',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    '$circleName • $memberCount member${memberCount == 1 ? '' : 's'} • $plan',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  if (isDemo) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: FamilyCircleColors.warning.withValues(
                          alpha: .15,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Demo household — sample data',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: FamilyCircleColors.warning,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.tune, color: scheme.primary),
          ],
        ),
      ),
    );
  }
}

/// One navigation row inside a grouped card on the More page.
class _MoreTile extends StatelessWidget {
  const _MoreTile({required this.entry});

  final (IconData, String, String, String) entry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(entry.$1, size: 19, color: scheme.primary),
      ),
      title: Text(
        entry.$2,
        style: Theme.of(context).textTheme.titleSmall
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(entry.$3),
      trailing: Icon(
        Icons.chevron_right,
        size: 20,
        color: scheme.onSurfaceVariant,
      ),
      onTap: () => context.push(entry.$4),
    );
  }
}
