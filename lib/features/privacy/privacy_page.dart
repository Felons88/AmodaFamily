/// ADULT-014 Privacy controls — analytics/personalization/AI consent,
/// export, learning deletion, child policies, household deletion.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../shared/errors.dart';
import '../../shared/widgets.dart';

class PrivacyPage extends ConsumerWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(appStoreProvider);
    final consent = store.consent;
    return FcScaffold(
      title: 'Privacy controls',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionHeader('Data choices'),
          SwitchListTile(
            title: const Text('Usage analytics'),
            subtitle: const Text(
              'Privacy-minimized events that help the app work. Required for core features.',
            ),
            value: consent.analytics,
            onChanged: (v) => store.setConsent(analytics: v),
          ),
          SwitchListTile(
            title: const Text('Personalization'),
            subtitle: const Text(
              'Learn from your explicit choices to improve meal suggestions.',
            ),
            value: consent.personalization,
            onChanged: (v) => store.setConsent(personalization: v),
          ),
          SwitchListTile(
            title: const Text('AI processing'),
            subtitle: const Text(
              'Optional AI features. Hard allergy checks never rely on AI either way.',
            ),
            value: consent.aiProcessing,
            onChanged: (v) => store.setConsent(aiProcessing: v),
          ),
          const Divider(height: 32),
          const SectionHeader('Your data'),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('Export my data'),
            subtitle: const Text(
              'Household profile, events count and learned signals.',
            ),
            onTap: () => _showExport(context, store),
          ),
          ListTile(
            leading: const Icon(Icons.auto_delete_outlined),
            title: const Text('Delete learning data'),
            subtitle: const Text(
              'Clears taste signals, feedback and activity. Plans stay.',
            ),
            onTap: () => _confirm(
              context,
              'Delete learning data?',
              'Recommendations reset to neutral. This cannot be undone.',
              () => store.deleteLearningData(),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.child_care_outlined),
            title: const Text('Children\'s data'),
            subtitle: const Text(
              'Kid activity is only used for requested features — never ads or profiling.',
            ),
            onTap: () => _showChildPolicy(context),
          ),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(
              Icons.delete_forever_outlined,
              color: Colors.redAccent,
            ),
            title: const Text('Delete household'),
            subtitle: const Text('Removes the circle, members and all data.'),
            onTap: () => _confirm(context, 'Delete household?', 'All members lose access and data is removed. This cannot be undone.', () {
              store.deleteHousehold();
              context.go(AppRoute.welcome.path);
            }),
          ),
        ],
      ),
    );
  }

  void _showExport(BuildContext context, AppStore store) {
    try {
      final data = const JsonEncoder.withIndent('  ')
          .convert(store.exportData());
      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Your export'),
          content: SingleChildScrollView(
            child: SelectableText(
              data,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } on FcException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.safeMessage)));
    }
  }

  void _showChildPolicy(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Children\'s data policy'),
        content: const SingleChildScrollView(
          child: Text(
            'Managed kid profiles:\n\n'
            '• Never see prices, billing, ads or purchase prompts\n'
            '• Activity teaches the meal planner only when it helps a feature they use\n'
            '• Are never profiled for advertising\n'
            '• Game rewards are virtual badges only — no purchases, no stranger contact\n'
            '• Parents can delete kid data anytime from this screen',
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _confirm(
    BuildContext context,
    String title,
    String body,
    VoidCallback action,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              try {
                action();
              } on FcException catch (e) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(e.safeMessage)));
              }
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
