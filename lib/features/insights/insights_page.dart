/// ADULT-011 Food insights — inferred tastes with evidence, correction and
/// deletion. Inferences stay labeled uncertain; absence never counts.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../shared/catalog.dart' as catalog;
import '../../shared/models.dart';
import '../../shared/widgets.dart';

class InsightsPage extends ConsumerWidget {
  const InsightsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(appStoreProvider);
    final signals = store.learning.values.toList()
      ..sort((a, b) => b.score.abs().compareTo(a.score.abs()));
    final events = store.events;

    return FcScaffold(
      title: 'Food insights',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          FcCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.insights_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What we think your household likes — always a guess, never a rule.',
                        style: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Only explicit actions change these: votes cast, ratings, cooked confirmations. Skipped or unseen meals count as neutral.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SectionHeader('Learned tastes'),
          if (signals.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: FcCard(
                child: Text(
                  'No taste signals yet. Vote and rate meals to teach the planner.',
                ),
              ),
            )
          else
            for (final s in signals)
              Builder(
                builder: (context) {
                  final recipe = catalog.recipes[s.recipeId];
                  final pct = (s.score * 100).round();
                  final tone = pct > 0
                      ? FamilyCircleColors.primary
                      : pct < 0
                      ? FamilyCircleColors.error
                      : Theme.of(context).colorScheme.onSurfaceVariant;
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: FcCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  recipe?.title ?? s.recipeId,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 8),
                                FcChip(
                                  pct > 0
                                      ? 'Likely liked'
                                      : pct < 0
                                      ? 'Likely disliked'
                                      : 'Uncertain',
                                  icon: pct > 0
                                      ? Icons.thumb_up_outlined
                                      : pct < 0
                                      ? Icons.thumb_down_outlined
                                      : Icons.help_outline,
                                  color: tone,
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(5),
                                  child: LinearProgressIndicator(
                                    value: s.score.abs().clamp(0.0, 1.0),
                                    minHeight: 6,
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      tone,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  pct > 0
                                      ? '+$pct from ${s.evidence.length} action${s.evidence.length == 1 ? '' : 's'}'
                                      : pct < 0
                                      ? '$pct from ${s.evidence.length} action${s.evidence.length == 1 ? '' : 's'}'
                                      : 'No strong signal yet',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Evidence: ${s.evidence.map((e) => e.replaceAll('_', ' ')).join(', ')}',
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Remove this signal',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => store.correctLearning(s.recipeId),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          const SectionHeader('Recent activity (privacy-safe)'),
          if (events.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: FcCard(child: Text('No recorded activity.')),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FcCard(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    for (var i = 0; i < events.length && i < 15; i++) ...[
                      _eventTile(context, events[events.length - 1 - i]),
                      if (i < events.length - 1 && i < 14)
                        Divider(
                          height: 1,
                          indent: 48,
                          color: Theme.of(context).colorScheme.outlineVariant
                              .withValues(alpha: .45),
                        ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _eventTile(BuildContext context, AppEvent event) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(
          Icons.bolt_outlined,
          size: 17,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(
        event.type.replaceAll('_', ' '),
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${event.at.hour.toString().padLeft(2, '0')}:${event.at.minute.toString().padLeft(2, '0')}',
      ),
    );
  }
}
