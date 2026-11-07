/// More tab: hub for remaining adult destinations + session controls.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/family_circle_app.dart';
import '../../app/router.dart';
import '../../shared/widgets.dart';

class MorePage extends ConsumerWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(appStoreProvider);
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

    Widget section(String title, List<(IconData, String, String, String)> items) =>
        Column(
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
                        const Divider(height: 1, indent: 68),
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
          children: [
            const OfflineBanner(),
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
                      title: const Text('Simulate offline'),
                      subtitle: const Text(
                        'Demo: test offline caching and queued changes',
                      ),
                      value: store.isOffline,
                      onChanged: (v) => store.setOffline(v),
                    ),
                    const Divider(height: 1, indent: 68),
                    ListTile(
                      leading: const Icon(Icons.logout),
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
            const SizedBox(height: 24),
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
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(entry.$1, size: 18, color: scheme.primary),
      ),
      title: Text(entry.$2),
      subtitle: Text(entry.$3),
      trailing: Icon(
        Icons.chevron_right,
        size: 18,
        color: scheme.onSurfaceVariant,
      ),
      onTap: () => context.push(entry.$4),
    );
  }
}
