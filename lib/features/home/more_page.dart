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
        Icons.local_drink_outlined,
        'Drinks',
        'Beverage profiles & forecast',
        AppRoute.drinks.path,
      ),
      (
        Icons.people_outline,
        'Members',
        'Manage household & kids',
        AppRoute.members.path,
      ),
      (
        Icons.account_balance_wallet_outlined,
        'Spending',
        'Budget vs actuals',
        AppRoute.spending.path,
      ),
      (
        Icons.event_outlined,
        'Shopping calendar',
        'Trips & cadence',
        AppRoute.calendar.path,
      ),
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
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      bottomNavigationBar: const AdultNavBar(current: '/more'),
      body: SafeArea(
        child: ListView(
          children: [
            const OfflineBanner(),
            for (final e in entries)
              ListTile(
                leading: Icon(e.$1),
                title: Text(e.$2),
                subtitle: Text(e.$3),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(e.$4),
              ),
            const Divider(height: 32),
            SwitchListTile(
              secondary: const Icon(Icons.wifi_off_outlined),
              title: const Text('Simulate offline'),
              subtitle: const Text(
                'Demo: test offline caching and queued changes',
              ),
              value: store.isOffline,
              onChanged: (v) => store.setOffline(v),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign out'),
              onTap: () {
                store.signOut();
                context.go(AppRoute.welcome.path);
              },
            ),
          ],
        ),
      ),
    );
  }
}
