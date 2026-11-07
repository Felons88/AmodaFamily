/// ADULT-001 Home — next meal, plan CTA, upcoming trip, voting status,
/// budget summary, profile switching and demo connectivity control.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/family_circle_app.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../shared/catalog.dart' as catalog;
import '../../shared/models.dart';
import '../../shared/updates.dart';
import '../../shared/widgets.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(appStoreProvider);
    final circle = store.circle;
    final actor = store.actor;
    if (circle == null || actor == null) {
      return const Scaffold(body: SkeletonList());
    }

    final plan = store.plan;
    final today = DateTime.now().weekday - 1;
    final todaySlots =
        plan?.slots.where((s) => s.day == today.clamp(0, 6)).toList() ??
        <PlanSlot>[];
    final openVotes = store.voteRounds
        .where(
          (v) =>
              v.status == VoteRoundStatus.open && !v.isExpired(DateTime.now()),
        )
        .length;
    final budget = store.budget;
    final expiring = store.pantry
        .where((p) => p.expiringSoon(DateTime.now()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(circle.name),
        actions: [
          IconButton(
            tooltip: 'Notifications settings',
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push(AppRoute.notifications.path),
          ),
          IconButton(
            tooltip: 'Switch profile',
            icon: const Icon(Icons.switch_account_outlined),
            onPressed: () => _showProfilePicker(context, ref),
          ),
        ],
      ),
      bottomNavigationBar: const AdultNavBar(current: '/home'),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const _UpdateCheck(),
            const OfflineBanner(),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Hi ${actor.name}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: 16),
            // Next meal card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FcCard(
                onTap: () => context.go(AppRoute.plan.path),
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (todaySlots.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Today\'s meals',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            for (final s in todaySlots)
                              Builder(
                                builder: (context) {
                                  final r = catalog.recipes[s.recipeId];
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    dense: true,
                                    leading: Icon(switch (s.meal) {
                                      MealType.breakfast =>
                                        Icons.wb_sunny_outlined,
                                      MealType.lunch =>
                                        Icons.lunch_dining_outlined,
                                      MealType.dinner =>
                                        Icons.nightlight_outlined,
                                    }),
                                    title: Text(r?.title ?? 'Unknown recipe'),
                                    subtitle: Text(s.meal.label),
                                    onTap: r == null
                                        ? null
                                        : () => context.push(
                                            '${AppRoute.recipeDetail.path}/${r.id}',
                                          ),
                                  );
                                },
                              ),
                          ],
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'No plan yet',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Build a safe, affordable week of meals for your household.',
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Status row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: FcCard(
                      onTap: () => context.push(AppRoute.votes.path),
                      child: Column(
                        children: [
                          Icon(
                            Icons.how_to_vote_outlined,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$openVotes',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          Text(
                            'Open votes',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FcCard(
                      onTap: () => context.push(AppRoute.spending.path),
                      child: Column(
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 8),
                          MoneyText(
                            budget.remainingCents,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          Text(
                            'Budget left',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FcCard(
                      onTap: () => context.push(AppRoute.shop.path),
                      child: Column(
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${store.groceryList.where((g) => !g.checked).length}',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          Text(
                            'To buy',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (expiring.isNotEmpty) ...[
              const SectionHeader('Use soon'),
              for (final p in expiring)
                ListTile(
                  leading: const Icon(
                    Icons.schedule_outlined,
                    color: FamilyCircleColors.warning,
                  ),
                  title: Text(
                    catalog.ingredients[p.ingredientId]?.name ?? p.ingredientId,
                  ),
                  subtitle: Text(
                    'Expires ${p.expiresAt!.month}/${p.expiresAt!.day} • ${fmtQty(p.quantity)}',
                  ),
                ),
            ],
            const SectionHeader('Quick actions'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.add_shopping_cart, size: 18),
                    label: const Text('Grocery list'),
                    onPressed: () => context.push(AppRoute.shop.path),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.kitchen_outlined, size: 18),
                    label: const Text('Pantry'),
                    onPressed: () => context.push(AppRoute.pantry.path),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.how_to_vote_outlined, size: 18),
                    label: const Text('Start a vote'),
                    onPressed: () => context.push(AppRoute.votes.path),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.sports_esports_outlined, size: 18),
                    label: const Text('Games'),
                    onPressed: () => context.push(AppRoute.games.path),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.child_care_outlined, size: 18),
                    label: const Text('Kids mode'),
                    onPressed: () => _showProfilePicker(context, ref),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// Invisible widget that runs the auto-update check once per home mount.
class _UpdateCheck extends StatefulWidget {
  const _UpdateCheck();

  @override
  State<_UpdateCheck> createState() => _UpdateCheckState();
}

class _UpdateCheckState extends State<_UpdateCheck> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateChecker.promptIfAvailable(context);
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}


extension on HomePage {
  void _showProfilePicker(BuildContext context, WidgetRef ref) {
    final store = ref.read(appStoreProvider);
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Text(
              'Who\'s using the app?',
              style: Theme.of(sheetContext).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final m in store.circle?.activeMembers ?? [])
              ListTile(
                leading: MemberAvatar(name: m.name, minor: m.isMinor),
                title: Text(m.name),
                subtitle: Text(
                  m.isMinor ? 'Kid mode — no prices or purchases' : 'Adult',
                ),
                trailing: store.actor?.id == m.id
                    ? const Icon(
                        Icons.check_circle,
                        color: FamilyCircleColors.primary,
                      )
                    : null,
                onTap: () {
                  store.switchActor(m.id);
                  Navigator.of(sheetContext).pop();
                  context.go(
                    m.isMinor ? AppRoute.kidsHome.path : AppRoute.home.path,
                  );
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
