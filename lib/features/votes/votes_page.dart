/// ADULT-010 Family votes — create parent-approved ballots, close rounds,
/// deterministic tie handling. Voting is also open to managed kids via
/// KIDS-002; abstention and unseen ballots stay neutral.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../shared/catalog.dart' as catalog;
import '../../shared/errors.dart';
import '../../shared/models.dart';
import '../../shared/widgets.dart';

class VotesPage extends ConsumerWidget {
  const VotesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(appStoreProvider);
    final rounds = store.voteRounds;
    final open = rounds
        .where(
          (r) =>
              r.status == VoteRoundStatus.open && !r.isExpired(DateTime.now()),
        )
        .toList();
    final closed = rounds
        .where(
          (r) =>
              r.status == VoteRoundStatus.closed || r.isExpired(DateTime.now()),
        )
        .toList();

    return FcScaffold(
      title: 'Family votes',
      fab: FloatingActionButton.extended(
        onPressed: () => _showCreateSheet(context, store),
        icon: const Icon(Icons.add),
        label: const Text('New vote'),
      ),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          const SectionHeader('Open'),
          if (open.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No open ballots. Start one and everyone gets a pick.',
              ),
            )
          else
            for (final r in open) _roundCard(context, store, r),
          const SectionHeader('Closed'),
          if (closed.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No finished votes yet.'),
            )
          else
            for (final r in closed) _closedTile(context, r),
        ],
      ),
    );
  }

  Widget _roundCard(BuildContext context, AppStore store, VoteRound round) {
    final me = store.actor?.id;
    final myVote = me == null ? null : round.votes[me];
    final members = store.circle?.activeMembers ?? [];
    final notYetVoted = members
        .where((m) => !round.votes.containsKey(m.id))
        .length;
    return FcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  round.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              FcChip(
                '${round.votes.length} votes',
                icon: Icons.how_to_vote_outlined,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$notYetVoted member${notYetVoted == 1 ? ' hasn\'t' : 's haven\'t'} voted — that stays neutral, not a dislike.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const Divider(height: 24),
          for (final optionId in round.optionIds)
            Builder(
              builder: (context) {
                final recipe = catalog.recipes[optionId];
                final votes = round.votes.values
                    .where((v) => v == optionId)
                    .length;
                final selected = myVote == optionId;
                final share = members.isEmpty
                    ? 0.0
                    : (votes / members.length).clamp(0.0, 1.0);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: selected ? FamilyCircleColors.primary : null,
                  ),
                  onTap: () {
                    try {
                      store.castVote(round.id, optionId);
                    } on FcException catch (e) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(e.safeMessage)));
                    }
                  },
                  title: Text(recipe?.title ?? optionId),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$votes vote${votes == 1 ? '' : 's'}'),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: share,
                          minHeight: 4,
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(
                onPressed: () => store.skipVote(round.id),
                child: const Text('Skip (neutral)'),
              ),
              const Spacer(),
              FilledButton.tonal(
                onPressed: () {
                  try {
                    store.closeVoteRound(round.id);
                  } on FcException catch (e) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(e.safeMessage)));
                  }
                },
                child: const Text('Close vote'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _closedTile(BuildContext context, VoteRound round) {
    final winner = round.winnerId == null
        ? null
        : catalog.recipes[round.winnerId];
    return ListTile(
      leading: Icon(
        round.status == VoteRoundStatus.closed
            ? Icons.check_circle_outline
            : Icons.timer_off_outlined,
        color: round.status == VoteRoundStatus.closed
            ? FamilyCircleColors.primary
            : FamilyCircleColors.muted,
      ),
      title: Text(round.title),
      subtitle: Text(
        round.status == VoteRoundStatus.closed
            ? (winner == null
                  ? 'Closed — no votes cast (neutral)'
                  : 'Winner: ${winner.title}')
            : 'Expired unclosed — counted as neutral',
      ),
    );
  }

  void _showCreateSheet(BuildContext context, AppStore store) {
    final title = TextEditingController();
    final selected = <String>{};
    final options = store.eligibleRecipes();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.75,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'New ballot',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Only allergy-checked recipes can be offered.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: title,
                    decoration: const InputDecoration(
                      labelText: 'Vote title',
                      hintText: 'Friday dinner pick',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      children: [
                        for (final r in options)
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: selected.contains(r.id),
                            onChanged: (sel) => setSheetState(
                              () => sel == true
                                  ? selected.add(r.id)
                                  : selected.remove(r.id),
                            ),
                            title: Text(r.title),
                            subtitle: Text(r.meal.label),
                          ),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: () {
                      try {
                        store.openVoteRound(title.text, selected.toList());
                        Navigator.of(sheetContext).pop();
                      } on FcException catch (e) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(e.safeMessage)));
                      }
                    },
                    child: const Text('Open vote'),
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
