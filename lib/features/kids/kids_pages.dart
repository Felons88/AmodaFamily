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
            if (dinner != null)
              FcCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tonight\'s dinner',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    DishImage(image: dinner.image, height: 110),
                    const SizedBox(height: 8),
                    Text(
                      dinner.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            _kidAction(
              context,
              Icons.how_to_vote_outlined,
              'Vote for meals',
              'Pick your favorite dinner',
              () => context.go(AppRoute.kidsVote.path),
            ),
            _kidAction(
              context,
              Icons.flag_outlined,
              'Family quest',
              'See this week\'s mission',
              () => context.go(AppRoute.kidsQuest.path),
            ),
            _kidAction(
              context,
              Icons.sports_esports_outlined,
              'Games',
              'Play safe family games',
              () => context.push(AppRoute.games.path),
            ),
            _kidAction(
              context,
              Icons.soup_kitchen_outlined,
              'Junior Chef',
              'Learn kitchen skills',
              () => context.push(AppRoute.kidsChef.path),
            ),
            _kidAction(
              context,
              Icons.public,
              'Food Passport',
              'Travel the world with food',
              () => context.push(AppRoute.kidsPassport.path),
            ),
            _kidAction(
              context,
              Icons.military_tech_outlined,
              'My badges',
              'See what you earned',
              () => context.go(AppRoute.kidsBadges.path),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kidAction(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return FcCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
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
                            Text(
                              round.title,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap your favorite. You can change your pick until it closes.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 12),
                            for (final optionId in round.optionIds)
                              Builder(
                                builder: (context) {
                                  final recipe = catalog.recipes[optionId];
                                  if (recipe == null) {
                                    return const SizedBox.shrink();
                                  }
                                  final selected = myVote == optionId;
                                  return FcCard(
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
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              DishImage(
                                                image: recipe.image,
                                                height: 90,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                recipe.title,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleSmall,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Icon(
                                          selected
                                              ? Icons.check_circle
                                              : Icons.circle_outlined,
                                          color: selected
                                              ? FamilyCircleColors.primary
                                              : FamilyCircleColors.muted,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            const SizedBox(height: 24),
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

// ---------- KIDS-003 Food quest ----------

class KidsQuestPage extends ConsumerWidget {
  const KidsQuestPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(appStoreProvider);
    store.ensureQuest();
    final doneCount = store.quest.where((q) => q.done).length;
    return Scaffold(
      appBar: AppBar(title: const Text('Family quest')),
      bottomNavigationBar: const KidsNavBar(current: '/kids/quest'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'This week\'s mission',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              '$doneCount of ${store.quest.length} done — no rush, there\'s no streak to lose.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: store.quest.isEmpty ? 0 : doneCount / store.quest.length,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 16),
            for (final q in store.quest)
              FcCard(
                child: Row(
                  children: [
                    Icon(
                      q.done
                          ? (q.adultApproved
                                ? Icons.verified
                                : Icons.check_circle)
                          : Icons.circle_outlined,
                      color: q.done
                          ? FamilyCircleColors.primary
                          : FamilyCircleColors.muted,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(q.title),
                          if (q.done && !q.adultApproved)
                            Text(
                              'Waiting for a grown-up to approve',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: FamilyCircleColors.warning),
                            ),
                        ],
                      ),
                    ),
                    if (!q.done)
                      FilledButton.tonal(
                        onPressed: () => store.completeQuestObjective(q.id),
                        child: const Text('I did it'),
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
            : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.1,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: store.badges.length,
                itemBuilder: (context, i) {
                  final b = store.badges[i];
                  return FcCard(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          gameIcon(catalog.gameById(b.gameId).icon),
                          size: 36,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          b.title,
                          style: Theme.of(context).textTheme.titleSmall,
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          b.description,
                          style: Theme.of(context).textTheme.labelSmall,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  );
                },
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
          Text(
            'Kitchen skills, safest first. Steps marked with an adult badge always need a grown-up.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          for (final lesson in catalog.chefLessons)
            FcCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lesson.title,
                          style: Theme.of(context).textTheme.titleSmall,
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
                  const SizedBox(height: 8),
                  for (var i = 0; i < lesson.steps.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 10,
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(lesson.steps[i])),
                        ],
                      ),
                    ),
                ],
              ),
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
          Text(
            'Explore how families eat around the world. Try a challenge only if you want to.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < catalog.passportStops.length; i++)
            Builder(
              builder: (context) {
                final stop = catalog.passportStops[i];
                final hasStamp = stamped.any(
                  (id) => id.contains('passport-$i'),
                );
                return FcCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.public,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              stop.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          if (hasStamp)
                            const FcChip('Stamp earned', icon: Icons.verified),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        stop.fact,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Challenge: ${stop.challenge}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      if (!hasStamp)
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
                                content: Text('Badge earned: ${badge.title}'),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
