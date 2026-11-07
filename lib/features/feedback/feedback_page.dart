/// SHARED-002 Feedback — explicit quick-reason chips, optional text,
/// skip without negative inference.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/catalog.dart' as catalog;
import '../../shared/errors.dart';
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
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Tell us about a meal. Only what you submit counts — silence is neutral.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
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
          const SizedBox(height: 16),
          SegmentedButton<String>(
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
            onSelectionChanged: (s) => setState(() => _value = s.firstOrNull),
          ),
          if (_value == 'dislike') ...[
            const SizedBox(height: 16),
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
          const SizedBox(height: 16),
          TextField(
            controller: _note,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Anything else? (optional)',
              prefixIcon: Icon(Icons.notes_outlined),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
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
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(e.safeMessage)));
                    }
                  },
            child: const Text('Send feedback'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Skip without rating'),
          ),
          if (recipe != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'About: ${recipe.title}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
        ],
      ),
    );
  }
}
