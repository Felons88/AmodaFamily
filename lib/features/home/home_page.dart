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
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Good morning'
        : now.hour < 18
        ? 'Good afternoon'
        : 'Good evening';
    final monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
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
            const OfflineBanner(),
            const SizedBox(height: 16),
            // Hero greeting card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      scheme.primary.withValues(alpha: 0.16),
                      scheme.surface.withValues(alpha: 0.0),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            greeting,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: scheme.primary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Hi ${actor.name}',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${circle.name} • ${monthNames[now.month - 1]} ${now.day}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    MemberAvatar(name: actor.name, size: 52),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Today's meals card
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
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.restaurant_menu_outlined,
                              size: 18,
                              color: scheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Today\'s meals',
                              style: Theme.of(context).textTheme.titleMedium,
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
                            Row(
                              children: [
                                Icon(
                                  Icons.restaurant_menu_outlined,
                                  size: 18,
                                  color: scheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'No plan yet',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Build a safe, affordable week of meals for your household.',
                            ),
                          ],
                        ),
                      ),
                    if (todaySlots.isNotEmpty)
                      for (final s in todaySlots)
                        _MealRow(
                          slot: s,
                          onTap: () {
                            final r = catalog.recipes[s.recipeId];
                            if (r != null) {
                              context.push(
                                '${AppRoute.recipeDetail.path}/${r.id}',
                              );
                            }
                          },
                        ),
                    if (todaySlots.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                        child: Text(
                          'Tap a meal for the recipe • tap the card for the week plan',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
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
                    child: _StatCard(
                      icon: Icons.how_to_vote_outlined,
                      value: Text(
                        '$openVotes',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      label: 'Open votes',
                      onTap: () => context.push(AppRoute.votes.path),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.account_balance_wallet_outlined,
                      value: MoneyText(
                        budget.remainingCents,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      label: 'Budget left',
                      onTap: () => context.push(AppRoute.spending.path),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.shopping_cart_outlined,
                      value: Text(
                        '${store.groceryList.where((g) => !g.checked).length}',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      label: 'To buy',
                      onTap: () => context.push(AppRoute.shop.path),
                    ),
                  ),
                ],
              ),
            ),
            // Budget progress
            if (store.showPrices && budget.totalCents > 0) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FcCard(
                  onTap: () => context.push(AppRoute.spending.path),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Budget this period',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          Text(
                            '${fmtCents(budget.spentCents)} of ${fmtCents(budget.totalCents)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: (budget.spentCents / budget.totalCents).clamp(
                            0.0,
                            1.0,
                          ),
                          minHeight: 10,
                          backgroundColor: scheme.surfaceContainerHighest,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${fmtCents(budget.remainingCents)} remaining',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            // Actionable vote card
            if (openVotes > 0) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FcCard(
                  onTap: () => context.push(AppRoute.votes.path),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.how_to_vote_outlined,
                          size: 20,
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$openVotes open vote${openVotes == 1 ? '' : 's'} waiting',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(
                              'Tap to cast your pick',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
            ],
            if (expiring.isNotEmpty) ...[
              const SectionHeader('Use soon'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FcCard(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      for (final p in expiring)
                        ListTile(
                          leading: const Icon(
                            Icons.schedule_outlined,
                            color: FamilyCircleColors.warning,
                          ),
                          title: Text(
                            catalog.ingredients[p.ingredientId]?.name ??
                                p.ingredientId,
                          ),
                          subtitle: Text(
                            'Expires ${p.expiresAt!.month}/${p.expiresAt!.day} • ${fmtQty(p.quantity)}',
                          ),
                          trailing: const Icon(Icons.chevron_right, size: 18),
                        ),
                    ],
                  ),
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

/// One row inside the "Today's meals" card: meal-type icon, recipe title
/// and a tap target that opens the recipe detail.
class _MealRow extends StatelessWidget {
  const _MealRow({required this.slot, required this.onTap});

  final PlanSlot slot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final recipe = catalog.recipes[slot.recipeId];
    return InkWell(
      onTap: recipe == null ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                switch (slot.meal) {
                  MealType.breakfast => Icons.wb_sunny_outlined,
                  MealType.lunch => Icons.lunch_dining_outlined,
                  MealType.dinner => Icons.nightlight_outlined,
                },
                size: 18,
                color: scheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe?.title ?? 'Unknown recipe',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Text(
                    slot.meal.label,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            if (recipe != null)
              Icon(
                Icons.chevron_right,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }
}

/// Compact tappable stat tile used in the home dashboard row.
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Widget value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FcCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: scheme.primary),
          ),
          const SizedBox(height: 8),
          value,
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
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
