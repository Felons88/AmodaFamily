/// ADULT-011 Food insights — inferred tastes with evidence, correction
/// and deletion. Inferences are labeled uncertain; absence never counts.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../shared/catalog.dart' as catalog;
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
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'What we think your household likes — always a guess, never a rule. Correct or delete anything.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Only explicit actions change these: votes cast, ratings, cooked confirmations. Skipped or unseen meals count as neutral.',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: FamilyCircleColors.muted),
          ),
          const SectionHeader('Learned tastes'),
          if (signals.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No taste signals yet. Vote and rate meals to teach the planner.',
              ),
            )
          else
            for (final s in signals)
              Builder(
                builder: (context) {
                  final recipe = catalog.recipes[s.recipeId];
                  final pct = (s.score * 100).round();
                  return FcCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                recipe?.title ?? s.recipeId,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 6),
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
                                color: pct > 0
                                    ? FamilyCircleColors.primary
                                    : pct < 0
                                    ? FamilyCircleColors.error
                                    : FamilyCircleColors.muted,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                pct > 0
                                    ? '+$pct from ${s.evidence.length} action${s.evidence.length == 1 ? '' : 's'}'
                                    : pct < 0
                                    ? '$pct from ${s.evidence.length} action${s.evidence.length == 1 ? '' : 's'}'
                                    : 'No strong signal yet',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                'Evidence: ${s.evidence.map((e) => e.replaceAll('_', ' ')).join(', ')}',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(color: FamilyCircleColors.muted),
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
                  );
                },
              ),
          const SectionHeader('Recent activity (privacy-safe)'),
          if (events.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No recorded activity.'),
            )
          else
            for (final e in events.reversed.take(15))
              ListTile(
                dense: true,
                leading: const Icon(Icons.bolt_outlined, size: 18),
                title: Text(e.type.replaceAll('_', ' ')),
                subtitle: Text(
                  '${e.at.hour.toString().padLeft(2, '0')}:${e.at.minute.toString().padLeft(2, '0')}',
                ),
              ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
