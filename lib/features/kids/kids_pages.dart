/// KIDS-001..006 — child-safe surfaces: home, voting, quest, badges,
/// junior chef, food passport. No prices, commerce, ads or stranger
/// contact anywhere in these flows.
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

// ---------- shared kid-mode visuals ----------

/// Vivid accent palette for kid surfaces. Works in both themes because it is
/// always rendered as a tint behind a themed icon/text.
/// Warm, vivid kid palette (terracotta / coral / honey family) that
/// harmonizes with the cream-and-terracotta app theme.
const _kidPalette = [
  Color(0xFFE8863F), // terracotta
  Color(0xFFFF8A5C), // coral
  Color(0xFFF2B84B), // honey
  Color(0xFF2BB3A3), // lagoon teal
  Color(0xFFFF7BA9), // bubblegum pink
  Color(0xFFB565D8), // plum
  Color(0xFF4FA8DE), // warm sky
  Color(0xFF7CB342), // leaf green
];

Color _kidAccent(String seed) {
  var h = 0;
  for (final c in seed.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return _kidPalette[h % _kidPalette.length];
}

/// Rounded-square icon medallion used across kid cards.
class _KidMedallion extends StatelessWidget {
  const _KidMedallion({
    required this.icon,
    required this.accent,
    this.size = 52,
    this.glow = false,
  });

  final IconData icon;
  final Color accent;
  final double size;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(size * 0.34),
        border: Border.all(color: accent.withValues(alpha: 0.55), width: 1.5),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.4),
                  blurRadius: 18,
                  spreadRadius: 1,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Icon(icon, color: accent, size: size * 0.52),
    );
  }
}

/// Small playful section header with an accent dot.
class _KidSectionHeader extends StatelessWidget {
  const _KidSectionHeader(this.title, {required this.accent});

  final String title;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- KIDS-001 Kids home ----------

class KidsHomePage extends ConsumerWidget {
  const KidsHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(appStoreProvider);
    final actor = store.actor;
    store.ensureQuest();
    final today = DateTime.now().weekday - 1;
    final todayDinner = store.plan?.slots
        .where((s) => s.day == today.clamp(0, 6) && s.meal == MealType.dinner)
        .firstOrNull;
    final dinner = todayDinner == null
        ? null
        : catalog.recipes[todayDinner.recipeId];

    final actions = [
      (
        Icons.how_to_vote_outlined,
        'Vote for meals',
        'Pick your favorite dinner',
        AppRoute.kidsVote.path,
        false,
      ),
      (
        Icons.flag_outlined,
        'Family quest',
        'See this week\'s mission',
        AppRoute.kidsQuest.path,
        false,
      ),
      (
        Icons.sports_esports_outlined,
        'Games',
        'Play safe family games',
        AppRoute.games.path,
        true,
      ),
      (
        Icons.soup_kitchen_outlined,
        'Junior Chef',
        'Learn kitchen skills',
        AppRoute.kidsChef.path,
        true,
      ),
      (
        Icons.public,
        'Food Passport',
        'Travel the world with food',
        AppRoute.kidsPassport.path,
        true,
      ),
      (
        Icons.military_tech_outlined,
        'My badges',
        'See what you earned',
        AppRoute.kidsBadges.path,
        false,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Hi ${actor?.name ?? 'friend'}!'),
        actions: [
          IconButton(
            tooltip: 'Back to grown-up view',
            icon: const Icon(Icons.family_restroom_outlined),
            onPressed: () => _pickAdult(context, ref),
          ),
        ],
      ),
      bottomNavigationBar: const KidsNavBar(current: '/kids/home'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Greeting hero — kid-mode framing with a playful medallion
            // cluster and a warm coral-to-honey gradient.
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFF8A5C).withValues(alpha: 0.28),
                    const Color(0xFFF2B84B).withValues(alpha: 0.14),
                    FamilyCircleColors.primary.withValues(alpha: 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: const Color(0xFFFF8A5C).withValues(alpha: 0.45),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Stack(
                    children: [
                      const _KidMedallion(
                        icon: Icons.restaurant_menu_outlined,
                        accent: Color(0xFFFF8A5C),
                        size: 76,
                        glow: true,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: _KidMedallion(
                          icon: Icons.dinner_dining_outlined,
                          accent: const Color(0xFFF2B84B),
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome to Kids Mode',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Fun, safe and only for you — no prices here!',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            for (final c in [
                              const Color(0xFFFF8A5C),
                              const Color(0xFFF2B84B),
                              const Color(0xFF2BB3A3),
                              const Color(0xFFFF7BA9),
                            ]) ...[
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: c,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              if (c != const Color(0xFFFF7BA9))
                                const SizedBox(width: 6),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (dinner != null)
              Builder(
                builder: (context) {
                  final accent = _kidAccent(dinner.id);
                  return Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _KidMedallion(
                              icon: Icons.dinner_dining_outlined,
                              accent: accent,
                              size: 40,
                              glow: true,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Tonight\'s dinner',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        DishImage(image: dinner.image, height: 120),
                        const SizedBox(height: 10),
                        Text(
                          dinner.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  );
                },
              ),
            const _KidSectionHeader(
              'What do you want to do?',
              accent: FamilyCircleColors.primary,
            ),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.05,
              children: [
                for (final a in actions)
                  _KidActionCard(
                    icon: a.$1,
                    title: a.$2,
                    subtitle: a.$3,
                    accent: _kidAccent(a.$2),
                    onTap: () => a.$5 ? context.push(a.$4) : context.go(a.$4),
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _pickAdult(BuildContext context, WidgetRef ref) {
    final store = ref.read(appStoreProvider);
    final adults = store.circle?.adults ?? [];
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Text(
              'Grown-ups only',
              style: Theme.of(sheetContext).textTheme.titleMedium,
            ),
            for (final a in adults)
              ListTile(
                leading: MemberAvatar(name: a.name),
                title: Text('Switch to ${a.name}'),
                onTap: () {
                  store.switchActor(a.id);
                  Navigator.of(sheetContext).pop();
                  context.go(AppRoute.home.path);
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _KidActionCard extends StatelessWidget {
  const _KidActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: accent.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withValues(alpha: 0.16),
                accent.withValues(alpha: 0.05),
              ],
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _KidMedallion(icon: icon, accent: accent, size: 48),
              const Spacer(),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.labelSmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------- KIDS-002 Meal voting ----------

class KidsVotePage extends ConsumerWidget {
  const KidsVotePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(appStoreProvider);
    final open = store.voteRounds
        .where(
          (r) =>
              r.status == VoteRoundStatus.open && !r.isExpired(DateTime.now()),
        )
        .toList();
    final me = store.actor?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Meal vote')),
      bottomNavigationBar: const KidsNavBar(current: '/kids/vote'),
      body: SafeArea(
        child: open.isEmpty
            ? const EmptyState(
                icon: Icons.how_to_vote_outlined,
                title: 'No votes right now',
                message:
                    'When a grown-up starts a vote, your picks show up here.',
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: FamilyCircleColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: FamilyCircleColors.primary.withValues(
                          alpha: 0.35,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.touch_app_outlined,
                          color: FamilyCircleColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Tap your favorite! You can change your pick until the vote closes.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final round in open) ...[
                    Builder(
                      builder: (context) {
                        WidgetsBinding.instance.addPostFrameCallback(
                          (_) => store.markBallotSeen(round.id),
                        );
                        final myVote = me == null ? null : round.votes[me];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _KidMedallion(
                                  icon: Icons.how_to_vote_outlined,
                                  accent: _kidAccent(round.id),
                                  size: 36,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    round.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            for (final optionId in round.optionIds)
                              Builder(
                                builder: (context) {
                                  final recipe = catalog.recipes[optionId];
                                  if (recipe == null) {
                                    return const SizedBox.shrink();
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 14),
                                    child: _VoteOptionCard(
                                      recipe: recipe,
                                      selected: myVote == optionId,
                                      accent: _kidAccent(optionId),
                                      onTap: () {
                                        try {
                                          store.castVote(round.id, optionId);
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Vote counted! You can change it until it closes.',
                                                  ),
                                                ),
                                              );
                                        } on FcException catch (e) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                                SnackBar(
                                                  content: Text(e.safeMessage),
                                                ),
                                              );
                                        }
                                      },
                                    ),
                                  );
                                },
                              ),
                            const SizedBox(height: 18),
                          ],
                        );
                      },
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

/// Oversized tappable meal card for voting. Springs with a scale + border
/// pop when selected and shows a bold "YOUR PICK" badge.
class _VoteOptionCard extends StatelessWidget {
  const _VoteOptionCard({
    required this.recipe,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final CatalogRecipe recipe;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: selected ? 1 : 0),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutBack,
      builder: (context, t, child) =>
          Transform.scale(scale: 1 + 0.025 * t, child: child),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.13) : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected
                ? accent
                : scheme.outlineVariant.withValues(alpha: 0.55),
            width: selected ? 3 : 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DishImage(image: recipe.image, height: 110),
                        const SizedBox(height: 10),
                        Text(
                          recipe.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected ? accent : Colors.transparent,
                          border: Border.all(
                            color: accent.withValues(alpha: 0.65),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          selected ? Icons.check : Icons.radio_button_unchecked,
                          size: 22,
                          color: selected ? Colors.white : accent,
                        ),
                      ),
                      if (selected) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star, size: 13, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'YOUR PICK',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------- KIDS-003 Food quest ----------

class KidsQuestPage extends ConsumerWidget {
  const KidsQuestPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(appStoreProvider);
    store.ensureQuest();
    final doneCount = store.quest.where((q) => q.done).length;
    final progress = store.quest.isEmpty ? 0.0 : doneCount / store.quest.length;
    return Scaffold(
      appBar: AppBar(title: const Text('Family quest')),
      bottomNavigationBar: const KidsNavBar(current: '/kids/quest'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: FamilyCircleColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: FamilyCircleColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _KidMedallion(
                        icon: Icons.flag_outlined,
                        accent: FamilyCircleColors.primary,
                        size: 40,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'This week\'s mission',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      FcChip(
                        '$doneCount / ${store.quest.length}',
                        icon: Icons.emoji_events_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 14,
                      backgroundColor: FamilyCircleColors.primary.withValues(
                        alpha: 0.15,
                      ),
                      valueColor: const AlwaysStoppedAnimation(
                        FamilyCircleColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$doneCount of ${store.quest.length} done — no rush, there\'s no streak to lose.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (progress >= 1 && store.quest.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        for (final c in _kidPalette.take(5)) ...[
                          Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                        ],
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Mission complete — amazing job!',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: FamilyCircleColors.primary,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const _KidSectionHeader(
              'Mission steps',
              accent: FamilyCircleColors.warning,
            ),
            for (final q in store.quest)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: q.done
                        ? FamilyCircleColors.primary.withValues(alpha: 0.1)
                        : null,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: q.done
                          ? FamilyCircleColors.primary.withValues(alpha: 0.55)
                          : Theme.of(context).colorScheme.outlineVariant
                                .withValues(alpha: 0.4),
                      width: q.done ? 1.5 : 1,
                    ),
                    boxShadow: q.done
                        ? [
                            BoxShadow(
                              color: FamilyCircleColors.primary.withValues(
                                alpha: 0.18,
                              ),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: q.done
                                ? FamilyCircleColors.primary.withValues(
                                    alpha: 0.18,
                                  )
                                : Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest
                                      .withValues(alpha: 0.5),
                          ),
                          child: Icon(
                            q.done
                                ? (q.adultApproved
                                      ? Icons.verified
                                      : Icons.check_circle)
                                : Icons.radio_button_unchecked,
                            size: 20,
                            color: q.done
                                ? FamilyCircleColors.primary
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                q.title,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      fontWeight: q.done
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                              ),
                              if (q.done && !q.adultApproved)
                                Text(
                                  'Waiting for a grown-up to approve',
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: FamilyCircleColors.warning,
                                      ),
                                ),
                            ],
                          ),
                        ),
                        if (!q.done)
                          FilledButton.tonalIcon(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 44),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(Icons.stars_outlined, size: 18),
                            onPressed: () => store.completeQuestObjective(q.id),
                            label: const Text('I did it'),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------- KIDS-004 Badge vault ----------

class KidsBadgesPage extends ConsumerWidget {
  const KidsBadgesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(appStoreProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My badges')),
      bottomNavigationBar: const KidsNavBar(current: '/kids/badges'),
      body: SafeArea(
        child: store.badges.isEmpty
            ? const EmptyState(
                icon: Icons.military_tech_outlined,
                title: 'No badges yet',
                message: 'Play games and finish quest steps to earn badges. They\'re just for fun — they can\'t be bought.',
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      _KidMedallion(
                        icon: Icons.military_tech_outlined,
                        accent: FamilyCircleColors.primary,
                        size: 44,
                        glow: true,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your sticker book',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            Text(
                              '${store.badges.length} badge${store.badges.length == 1 ? '' : 's'} earned — so far so awesome!',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.92,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemCount: store.badges.length,
                    itemBuilder: (context, i) {
                      final b = store.badges[i];
                      final accent = _kidAccent('${b.gameId}-${b.id}');
                      return Container(
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.45),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.22),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 58,
                                height: 58,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: accent.withValues(alpha: 0.22),
                                  border: Border.all(
                                    color: accent.withValues(alpha: 0.7),
                                    width: 2.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: accent.withValues(alpha: 0.3),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  gameIcon(catalog.gameById(b.gameId).icon),
                                  size: 28,
                                  color: accent,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                b.title,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                b.description,
                                style: Theme.of(context).textTheme.labelSmall,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              FcChip('Earned', icon: Icons.star, color: accent),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
      ),
    );
  }
}

// ---------- KIDS-005 Junior chef ----------

class KidsChefPage extends ConsumerWidget {
  const KidsChefPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FcScaffold(
      title: 'Junior Chef',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: FamilyCircleColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: FamilyCircleColors.warning.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const _KidMedallion(
                  icon: Icons.soup_kitchen_outlined,
                  accent: FamilyCircleColors.warning,
                  size: 44,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Kitchen skills, safest first. Steps marked with an adult badge always need a grown-up.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const _KidSectionHeader(
            'Lessons',
            accent: FamilyCircleColors.primary,
          ),
          for (var li = 0; li < catalog.chefLessons.length; li++)
            Builder(
              builder: (context) {
                final lesson = catalog.chefLessons[li];
                final accent = _kidAccent('lesson-$li');
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: accent.withValues(alpha: 0.35)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _KidMedallion(
                                icon: Icons.menu_book_outlined,
                                accent: accent,
                                size: 46,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Lesson ${li + 1}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: accent,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    Text(
                                      lesson.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              if (lesson.needsAdult)
                                const FcChip(
                                  'With a grown-up',
                                  icon: Icons.family_restroom_outlined,
                                  color: FamilyCircleColors.warning,
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          for (var i = 0; i < lesson.steps.length; i++)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: accent.withValues(alpha: 0.2),
                                      border: Border.all(
                                        color: accent.withValues(alpha: 0.6),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${i + 1}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: accent,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(lesson.steps[i])),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

// ---------- KIDS-006 Food passport ----------

class KidsPassportPage extends ConsumerWidget {
  const KidsPassportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(appStoreProvider);
    final stamped = store.badges
        .where((b) => b.gameId == 'world-food')
        .map((b) => b.id)
        .toSet();
    return FcScaffold(
      title: 'Food Passport',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _kidAccent('passport').withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _kidAccent('passport').withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const _KidMedallion(
                  icon: Icons.travel_explore_outlined,
                  accent: Color(0xFF5AA9E6),
                  size: 44,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Explore how families eat around the world. Try a challenge only if you want to.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const _KidSectionHeader(
            'Stamp your passport',
            accent: Color(0xFF5AA9E6),
          ),
          for (var i = 0; i < catalog.passportStops.length; i++)
            Builder(
              builder: (context) {
                final stop = catalog.passportStops[i];
                final hasStamp = stamped.any(
                  (id) => id.contains('passport-$i'),
                );
                final accent = _kidAccent('stop-$i');
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: hasStamp ? accent.withValues(alpha: 0.12) : null,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: hasStamp
                            ? accent.withValues(alpha: 0.6)
                            : Theme.of(context).colorScheme.outlineVariant
                                  .withValues(alpha: 0.4),
                        width: hasStamp ? 2 : 1.5,
                      ),
                      boxShadow: hasStamp
                          ? [
                              BoxShadow(
                                color: accent.withValues(alpha: 0.25),
                                blurRadius: 16,
                                offset: const Offset(0, 5),
                              ),
                            ]
                          : null,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Circular stamp visual with a double ring.
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: hasStamp
                                      ? accent.withValues(alpha: 0.2)
                                      : Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest
                                            .withValues(alpha: 0.4),
                                  border: Border.all(
                                    color: hasStamp
                                        ? accent
                                        : Theme.of(context)
                                              .colorScheme
                                              .outlineVariant,
                                    width: hasStamp ? 3 : 1.5,
                                  ),
                                  boxShadow: hasStamp
                                      ? [
                                          BoxShadow(
                                            color: accent.withValues(
                                              alpha: 0.35,
                                            ),
                                            blurRadius: 12,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Icon(
                                  hasStamp ? Icons.verified : Icons.public,
                                  color: hasStamp
                                      ? accent
                                      : Theme.of(context).colorScheme.onSurfaceVariant,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  stop.name,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              if (hasStamp)
                                FcChip(
                                  'Stamp earned',
                                  icon: Icons.verified,
                                  color: accent,
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            stop.fact,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Challenge: ${stop.challenge}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          if (!hasStamp) ...[
                            const SizedBox(height: 12),
                            FilledButton.tonalIcon(
                              icon: const Icon(Icons.stars_outlined, size: 18),
                              label: const Text('Earn this stamp'),
                              onPressed: () {
                                final session = store.startGame('world-food');
                                final badge = store.finishGame(
                                  GameSession(
                                    id: 'passport-$i-${session.id}',
                                    gameId: 'world-food',
                                    startedAt: DateTime.now(),
                                  ),
                                  rewardTitle: '${stop.name} Explorer',
                                  rewardDescription:
                                      'Learned about food from ${stop.name}.',
                                );
                                store.completeQuestObjective('q-passport');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Badge earned: ${badge.title}',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
