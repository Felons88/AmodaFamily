/// ADULT-001 Home — Mealime-style dashboard with a week strip, today hero,
/// pantry urgency, budget and vote entry points.
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

  static const _dayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _monthNames = [
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(appStoreProvider);
    final circle = store.circle;
    final actor = store.actor;
    if (circle == null || actor == null) {
      return const Scaffold(body: SkeletonList());
    }

    final plan = store.plan;
    final now = DateTime.now();
    final todayIndex = now.weekday - 1;
    final weekStart =
        plan?.weekStart ??
        DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: todayIndex));
    final todaySlots =
        plan?.slots.where((s) => s.day == todayIndex.clamp(0, 6)).toList() ??
        <PlanSlot>[];
    final openVotes = store.voteRounds
        .where(
          (v) =>
              v.status == VoteRoundStatus.open && !v.isExpired(DateTime.now()),
        )
        .length;
    final budget = store.budget;
    final expiring = store.pantry.where((p) => p.expiringSoon(now)).toList();
    final unchecked = store.groceryList.where((g) => !g.checked).length;
    final greeting = now.hour < 12
        ? 'Good morning'
        : now.hour < 18
        ? 'Good afternoon'
        : 'Good evening';

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const OfflineBanner(),
            _Header(
              greeting: greeting,
              name: actor.name,
              circleName: circle.name,
              dateLabel:
                  '${_monthNames[now.month - 1]} ${now.day}, ${now.year}',
              onNotifications: () => context.push(AppRoute.notifications.path),
              onSwitchProfile: () => _showProfilePicker(context, ref),
            ),
            const SizedBox(height: 18),
            _WeekStrip(
              weekStart: weekStart,
              plan: plan,
              todayIndex: todayIndex,
              onTap: () => context.go(AppRoute.plan.path),
            ),
            const SizedBox(height: 18),
            _TodayHero(
              slots: todaySlots,
              dateLabel:
                  'Today • ${_dayShort[todayIndex.clamp(0, 6)]} ${now.day}',
              onPlanTap: () => context.go(AppRoute.plan.path),
            ),
            const SizedBox(height: 14),
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
                      icon: Icons.shopping_basket_outlined,
                      value: Text(
                        '$unchecked',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      label: 'To buy',
                      onTap: () => context.push(AppRoute.shop.path),
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
                ],
              ),
            ),
            if (expiring.isNotEmpty) ...[
              const SizedBox(height: 18),
              _ExpiringCard(items: expiring),
            ],
            if (store.showPrices && budget.totalCents > 0) ...[
              const SizedBox(height: 14),
              _BudgetCard(
                budget: budget,
                onTap: () => context.push(AppRoute.spending.path),
              ),
            ],
            if (openVotes > 0) ...[
              const SizedBox(height: 14),
              _VoteCta(count: openVotes),
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
                    avatar: const Icon(Icons.local_drink_outlined, size: 18),
                    label: const Text('Drinks'),
                    onPressed: () => context.push(AppRoute.drinks.path),
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
            const SizedBox(height: 28),
          ],
        ),
      ),
      bottomNavigationBar: const AdultNavBar(current: '/home'),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.greeting,
    required this.name,
    required this.circleName,
    required this.dateLabel,
    required this.onNotifications,
    required this.onSwitchProfile,
  });

  final String greeting;
  final String name;
  final String circleName;
  final String dateLabel;
  final VoidCallback onNotifications;
  final VoidCallback onSwitchProfile;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Hi, $name',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.7,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$circleName • $dateLabel',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          MemberAvatar(name: name, size: 48),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Notifications settings',
            onPressed: onNotifications,
            icon: const Icon(Icons.notifications_outlined),
          ),
          IconButton(
            tooltip: 'Switch profile',
            onPressed: onSwitchProfile,
            icon: const Icon(Icons.switch_account_outlined),
          ),
        ],
      ),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    required this.weekStart,
    required this.plan,
    required this.todayIndex,
    required this.onTap,
  });

  final DateTime weekStart;
  final WeekPlan? plan;
  final int todayIndex;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: FcCard(
        onTap: onTap,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'This week',
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                Text(
                  '${weekStart.month}/${weekStart.day} – ${weekStart.add(const Duration(days: 6)).month}/${weekStart.add(const Duration(days: 6)).day}',
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 78,
              child: Row(
                children: [
                  for (var day = 0; day < 7; day++)
                    Expanded(
                      child: _DayChip(
                        label: HomePage._dayShort[day],
                        dayNumber: weekStart.add(Duration(days: day)).day,
                        mealCount: plan?.slots
                            .where((s) => s.day == day)
                            .length,
                        selected: day == todayIndex,
                      ),
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

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.label,
    required this.dayNumber,
    required this.mealCount,
    required this.selected,
  });

  final String label;
  final int dayNumber;
  final int? mealCount;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final count = mealCount ?? 0;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      decoration: BoxDecoration(
        color: selected
            ? scheme.primary.withValues(alpha: 0.16)
            : scheme.surfaceContainerHigh.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected
              ? scheme.primary.withValues(alpha: 0.55)
              : Colors.transparent,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: selected ? scheme.primary : scheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$dayNumber',
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < 3; i++)
                Container(
                  width: 5,
                  height: 5,
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < count
                        ? (selected ? scheme.primary : scheme.onSurfaceVariant)
                        : scheme.outlineVariant,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TodayHero extends StatelessWidget {
  const _TodayHero({
    required this.slots,
    required this.dateLabel,
    required this.onPlanTap,
  });

  final List<PlanSlot> slots;
  final String dateLabel;
  final VoidCallback onPlanTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final recipes = [for (final s in slots) ?catalog.recipes[s.recipeId]];
    final totalMinutes = recipes.fold<int>(
      0,
      (sum, recipe) => sum + recipe.minutes,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: FcCard(
        onTap: onPlanTap,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        scheme.primary.withValues(alpha: 0.9),
                        scheme.primary.withValues(alpha: 0.55),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.restaurant_menu_outlined,
                    color: scheme.onPrimary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today\'s plan',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        dateLabel,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${recipes.length}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      'meals',
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
            if (recipes.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FcChip(
                    '~$totalMinutes min cook time',
                    icon: Icons.schedule_outlined,
                  ),
                  FcChip(
                    '${recipes.map((r) => r.servings).reduce((a, b) => a > b ? a : b)} servings max',
                    icon: Icons.people_outline,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 112,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: slots.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, index) =>
                      _TodayMealCard(slot: slots[index]),
                ),
              ),
            ] else ...[
              const SizedBox(height: 12),
              Text(
                'No meals planned for today yet. Generate a safe week and it will show up here.',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              FcPrimaryButton(
                label: 'Build this week',
                icon: Icons.auto_awesome_outlined,
                onPressed: onPlanTap,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TodayMealCard extends StatelessWidget {
  const _TodayMealCard({required this.slot});

  final PlanSlot slot;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final recipe = catalog.recipes[slot.recipeId];
    if (recipe == null) return const SizedBox.shrink();
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => context.push('${AppRoute.recipeDetail.path}/${recipe.id}'),
      child: Container(
        width: 190,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                switch (slot.meal) {
                  MealType.breakfast => Icons.wb_sunny_outlined,
                  MealType.lunch => Icons.lunch_dining_outlined,
                  MealType.dinner => Icons.nightlight_outlined,
                },
                size: 21,
                color: scheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    slot.meal.label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    recipe.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${recipe.minutes} min • serves ${recipe.servings}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
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

class _ExpiringCard extends StatelessWidget {
  const _ExpiringCard({required this.items});

  final List<PantryItem> items;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: FcCard(
        onTap: () => context.push(AppRoute.pantry.path),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: FamilyCircleColors.warning.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.schedule_outlined,
                    color: FamilyCircleColors.warning,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Use soon',
                        style: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '${items.length} pantry item${items.length == 1 ? '' : 's'} expiring soon',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
            const SizedBox(height: 10),
            for (final item in items.take(3))
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.circle,
                      size: 8,
                      color: FamilyCircleColors.warning,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        catalog.ingredients[item.ingredientId]?.name ??
                            item.ingredientId,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      '${fmtQty(item.quantity)} • ${item.expiresAt!.month}/${item.expiresAt!.day}',
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
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

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.budget, required this.onTap});

  final BudgetCycle budget;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fraction = (budget.spentCents / budget.totalCents).clamp(0.0, 1.0);
    final over = budget.spentCents > budget.totalCents;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: FcCard(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_outlined,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Budget this period',
                        style: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '${fmtCents(budget.spentCents)} spent of ${fmtCents(budget.totalCents)}',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Text(
                  fmtCents(budget.remainingCents),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: over ? FamilyCircleColors.error : scheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 10,
                backgroundColor: scheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  over ? FamilyCircleColors.error : scheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              over
                  ? 'Over budget — review upcoming trips'
                  : 'Remaining for meals and essentials',
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _VoteCta extends StatelessWidget {
  const _VoteCta({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: FcCard(
        onTap: () => context.push(AppRoute.votes.path),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: FamilyCircleColors.tertiary.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.how_to_vote_outlined,
                color: FamilyCircleColors.tertiary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count vote${count == 1 ? '' : 's'} waiting for your pick',
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    'Tap to cast your ballot',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

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
