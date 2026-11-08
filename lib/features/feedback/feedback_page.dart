/// SHARED-002 Feedback — explicit quick-reason chips, optional text and a
/// skip path that never creates a negative inference.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/catalog.dart' as catalog;
import '../../shared/errors.dart';
import '../../shared/models.dart';
import '../../shared/widgets.dart';

class FeedbackPage extends ConsumerStatefulWidget {
  const FeedbackPage({super.key, this.recipeId});

  final String? recipeId;

  @override
  ConsumerState<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends ConsumerState<FeedbackPage> {
  String? _recipeId;
  String? _value;
  String? _reason;
  final _note = TextEditingController();
  bool _sent = false;

  static const _reasons = [
    'too_spicy',
    'not_in_mood',
    'time',
    'cost',
    'texture',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    _recipeId = widget.recipeId;
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(appStoreProvider);
    final recipes = store.eligibleRecipes();
    _recipeId ??= recipes.firstOrNull?.id;
    final recipe = _recipeId == null ? null : catalog.recipes[_recipeId];

    if (_sent) {
      return FcScaffold(
        title: 'Feedback',
        child: EmptyState(
          icon: Icons.check_circle_outline,
          title: 'Thanks — saved',
          message: 'Your explicit feedback updates suggestions. Skipping would have stayed neutral.',
          actionLabel: 'Done',
          onAction: () => context.pop(),
        ),
      );
    }

    return FcScaffold(
      title: 'Meal feedback',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          FcCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.feedback_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tell us about a meal. Only what you submit counts — silence is neutral.',
                    style: Theme.of(context).textTheme.bodyLarge
                        ?.copyWith(height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          FcCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Meal',
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _recipeId,
                  decoration: const InputDecoration(
                    labelText: 'Meal',
                    prefixIcon: Icon(Icons.restaurant_menu_outlined),
                  ),
                  items: [
                    for (final r in recipes)
                      DropdownMenuItem(value: r.id, child: Text(r.title)),
                  ],
                  onChanged: (v) => setState(() => _recipeId = v),
                ),
                if (recipe != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    '${recipe.meal.label} • ${recipe.minutes} min • serves ${recipe.servings}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          FcCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How did it go?',
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'like',
                        label: Text('Liked'),
                        icon: Icon(Icons.thumb_up_outlined),
                      ),
                      ButtonSegment(
                        value: 'dislike',
                        label: Text('Disliked'),
                        icon: Icon(Icons.thumb_down_outlined),
                      ),
                      ButtonSegment(
                        value: 'cooked',
                        label: Text('Cooked'),
                        icon: Icon(Icons.soup_kitchen_outlined),
                      ),
                    ],
                    selected: {?_value},
                    emptySelectionAllowed: true,
                    onSelectionChanged: (s) =>
                        setState(() => _value = s.firstOrNull),
                  ),
                ),
                if (_value == 'dislike') ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final r in _reasons)
                        ChoiceChip(
                          label: Text(r.replaceAll('_', ' ')),
                          selected: _reason == r,
                          onSelected: (sel) =>
                              setState(() => _reason = sel ? r : null),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Reasons describe this meal — not everything with similar ingredients.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          FcCard(
            child: TextField(
              controller: _note,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Anything else? (optional)',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.send_outlined),
              label: const Text('Send feedback'),
              onPressed: _recipeId == null || _value == null
                  ? null
                  : () {
                      try {
                        store.submitFeedback(
                          _recipeId!,
                          _value!,
                          reason: _reason,
                        );
                        setState(() => _sent = true);
                      } on FcException catch (e) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(e.safeMessage)));
                      }
                    },
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => context.pop(),
              child: const Text('Skip without rating'),
            ),
          ),
          if (recipe != null)
            Center(
              child: Text(
                'About: ${recipe.title}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
