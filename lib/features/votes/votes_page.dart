/// ADULT-010 Family votes — parent-approved ballots, deterministic close and
/// neutral handling for skips/unseen members. Kids can vote through KIDS-002.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: FcCard(
                child: Text(
                  'No open ballots. Start one and everyone gets a pick.',
                ),
              ),
            )
          else
            for (final r in open)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: _roundCard(context, store, r),
              ),
          const SectionHeader('Closed'),
          if (closed.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('No finished votes yet.'),
            )
          else
            for (final r in closed)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: _closedTile(context, r),
              ),
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
    final scheme = Theme.of(context).colorScheme;
    final hoursLeft = round.closesAt.difference(DateTime.now()).inHours;

    return FcCard(
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
                  color: scheme.primary.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(Icons.how_to_vote_outlined, color: scheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      round.title,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      hoursLeft > 0
                          ? 'Closes in ~${hoursLeft}h • ${round.votes.length} vote${round.votes.length == 1 ? '' : 's'}'
                          : 'Closing soon • ${round.votes.length} vote${round.votes.length == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              FcChip(
                '${round.votes.length} votes',
                icon: Icons.how_to_vote_outlined,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '$notYetVoted member${notYetVoted == 1 ? ' hasn\'t' : 's haven\'t'} voted — that stays neutral, not a dislike.',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
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
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      try {
                        store.castVote(round.id, optionId);
                      } on FcException catch (e) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(e.safeMessage)));
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: selected
                            ? scheme.primary.withValues(alpha: .11)
                            : scheme.surfaceContainerHigh.withValues(alpha: .4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? scheme.primary.withValues(alpha: .55)
                              : scheme.outlineVariant.withValues(alpha: .4),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            selected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: selected
                                ? scheme.primary
                                : scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  recipe?.title ?? optionId,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 5),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: share,
                                    minHeight: 5,
                                    backgroundColor:
                                        scheme.surfaceContainerHighest,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      scheme.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  '$votes vote${votes == 1 ? '' : 's'} • ${recipe?.minutes ?? 0} min',
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                ),
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
    final closed = round.status == VoteRoundStatus.closed;
    return FcCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color:
                  (closed
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant)
                      .withValues(alpha: .14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              closed ? Icons.check_circle_outline : Icons.timer_off_outlined,
              color: closed
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  round.title,
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  closed
                      ? (winner == null
                            ? 'Closed — no votes cast (neutral)'
                            : 'Winner: ${winner.title}')
                      : 'Expired unclosed — counted as neutral',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
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
                    child: ListView.separated(
                      itemCount: options.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final r = options[index];
                        final checked = selected.contains(r.id);
                        return Card(
                          clipBehavior: Clip.antiAlias,
                          child: CheckboxListTile(
                            value: checked,
                            onChanged: (sel) => setSheetState(
                              () => sel == true
                                  ? selected.add(r.id)
                                  : selected.remove(r.id),
                            ),
                            title: Text(r.title),
                            subtitle: Text(
                              '${r.meal.label} • ${r.minutes} min • serves ${r.servings}',
                            ),
                            secondary: checked
                                ? Icon(
                                    Icons.check_circle,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.how_to_vote_outlined),
                      label: const Text('Open vote'),
                      onPressed: () {
                        try {
                          store.openVoteRound(title.text, selected.toList());
                          Navigator.of(sheetContext).pop();
                        } on FcException catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.safeMessage)),
                          );
                        }
                      },
                    ),
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
