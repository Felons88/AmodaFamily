/// Family tab — votes summary, members summary, quest approvals,
/// entry into kids mode.
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
        .where((v) => v.status == VoteRoundStatus.open)
        .toList();
    final pendingApprovals = store.quest
        .where((q) => q.done && !q.adultApproved)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Family')),
      bottomNavigationBar: const AdultNavBar(current: '/family'),
      body: SafeArea(
        child: ListView(
          children: [
            const OfflineBanner(),
            const SectionHeader('Voting'),
            if (openVotes.isEmpty)
              const ListTile(
                leading: Icon(Icons.how_to_vote_outlined),
                title: Text('No open votes'),
                subtitle: Text('Start a ballot so everyone picks dinner.'),
              )
            else
              for (final v in openVotes)
                ListTile(
                  leading: const Icon(Icons.how_to_vote_outlined),
                  title: Text(v.title),
                  subtitle: Text(
                    '${v.votes.length}/${circle.activeMembers.length} voted • closes ${v.closesAt.month}/${v.closesAt.day}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(AppRoute.votes.path),
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
                          m.isMinor
                              ? 'Kid • ${m.ageBand.label}'
                              : m.role.name,
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
              for (final q in pendingApprovals)
                ListTile(
                  leading: const Icon(
                    Icons.flag_outlined,
                    color: FamilyCircleColors.warning,
                  ),
                  title: Text(q.title),
                  subtitle: const Text('A kid marked this done'),
                  trailing: FilledButton.tonal(
                    onPressed: () => store.approveQuestObjective(q.id),
                    child: const Text('Approve'),
                  ),
                ),
            ],
            const SectionHeader('Kids mode'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Hand the device to a kid: pick their profile and the app switches to a safe view with no prices or purchases.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 8),
            for (final m in circle.minors)
              ListTile(
                leading: MemberAvatar(name: m.name, minor: true),
                title: Text('Open ${m.name}\'s view'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  store.switchActor(m.id);
                  context.go(AppRoute.kidsHome.path);
                },
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
