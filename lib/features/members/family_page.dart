/// Family tab — votes summary, household members, quest approvals and
/// entry into the safe kids view.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/family_circle_app.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../shared/models.dart';
import '../../shared/widgets.dart';

class FamilyPage extends ConsumerWidget {
  const FamilyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(appStoreProvider);
    final circle = store.circle;
    if (circle == null) return const Scaffold(body: SkeletonList());
    final openVotes = store.voteRounds
        .where(
          (v) =>
              v.status == VoteRoundStatus.open && !v.isExpired(DateTime.now()),
        )
        .toList();
    final pendingApprovals = store.quest
        .where((q) => q.done && !q.adultApproved)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Family')),
      bottomNavigationBar: const AdultNavBar(current: '/family'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const OfflineBanner(),
            _HouseholdHeader(circle: circle),
            const SectionHeader('Voting'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: openVotes.isEmpty
                  ? const FcCard(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.how_to_vote_outlined),
                        title: Text('No open votes'),
                        subtitle: Text(
                          'Start a ballot so everyone picks dinner.',
                        ),
                      ),
                    )
                  : FcCard(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        children: [
                          for (var i = 0; i < openVotes.length; i++) ...[
                            _VoteTile(
                              round: openVotes[i],
                              voted: openVotes[i].votes.length,
                              total: circle.activeMembers.length,
                              onTap: () => context.push(AppRoute.votes.path),
                            ),
                            if (i < openVotes.length - 1)
                              Divider(
                                height: 1,
                                indent: 62,
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant
                                    .withValues(alpha: .45),
                              ),
                          ],
                        ],
                      ),
                    ),
            ),
            const SectionHeader('Members'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FcCard(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    for (final m in circle.activeMembers.take(4))
                      ListTile(
                        leading: MemberAvatar(name: m.name, minor: m.isMinor),
                        title: Text(m.name),
                        subtitle: Text(
                          m.isMinor ? 'Kid • ${m.ageBand.label}' : m.role.name,
                        ),
                        dense: true,
                      ),
                    if (circle.activeMembers.length > 4)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '+${circle.activeMembers.length - 4} more',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 24, top: 4),
                child: TextButton.icon(
                  icon: const Icon(Icons.settings_outlined, size: 18),
                  label: const Text('Manage members'),
                  onPressed: () => context.push(AppRoute.members.path),
                ),
              ),
            ),
            if (pendingApprovals.isNotEmpty) ...[
              const SectionHeader('Quest approvals'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FcCard(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    children: [
                      for (var i = 0; i < pendingApprovals.length; i++) ...[
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                          ),
                          leading: Icon(
                            Icons.flag_outlined,
                            color: context.kcWarning,
                          ),
                          title: Text(pendingApprovals[i].title),
                          subtitle: const Text('A kid marked this done'),
                          trailing: FilledButton.tonal(
                            onPressed: () => store.approveQuestObjective(
                              pendingApprovals[i].id,
                            ),
                            child: const Text('Approve'),
                          ),
                        ),
                        if (i < pendingApprovals.length - 1)
                          Divider(
                            height: 1,
                            indent: 56,
                            color: Theme.of(context).colorScheme.outlineVariant
                                .withValues(alpha: .45),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
            const SectionHeader('Kids mode'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FcCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hand the device to a kid: pick their profile and the app switches to a safe view with no prices or purchases.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (circle.minors.isEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        'No managed kid profiles yet.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (circle.minors.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FcCard(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    children: [
                      for (final m in circle.minors)
                        ListTile(
                          leading: MemberAvatar(name: m.name, minor: true),
                          title: Text('Open ${m.name}\'s view'),
                          subtitle: Text('Ages ${m.ageBand.label} • safe mode'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            store.switchActor(m.id);
                            context.go(AppRoute.kidsHome.path);
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

class _HouseholdHeader extends StatelessWidget {
  const _HouseholdHeader({required this.circle});

  final Circle circle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.primary.withValues(alpha: .18),
              scheme.primary.withValues(alpha: .04),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: scheme.primary.withValues(alpha: .25)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: .18),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                Icons.family_restroom_outlined,
                color: scheme.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    circle.name,
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    '${circle.activeMembers.length} members • ${circle.minors.length} kid${circle.minors.length == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.bodySmall
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

class _VoteTile extends StatelessWidget {
  const _VoteTile({
    required this.round,
    required this.voted,
    required this.total,
    required this.onTap,
  });

  final VoteRound round;
  final int voted;
  final int total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      leading: const Icon(Icons.how_to_vote_outlined),
      title: Text(
        round.title,
        style: Theme.of(context).textTheme.titleSmall
            ?.copyWith(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        '$voted/$total voted • closes ${round.closesAt.month}/${round.closesAt.day}',
      ),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}
