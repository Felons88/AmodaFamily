/// SHARED-001 Notifications — grouped channel and reminder preferences,
/// quiet hours, and transparent adult/kid frequency caps.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../shared/models.dart';
import '../../shared/widgets.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(appStoreProvider);
    final prefs = store.notifPrefs;
    void save(NotificationPrefs p) => store.setNotifPrefs(p);

    Widget card(Widget child) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: FcCard(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: child,
      ),
    );

    Widget divider() => Divider(
      height: 1,
      indent: 68,
      color: Theme.of(context).colorScheme.outlineVariant
          .withValues(alpha: .45),
    );

    return FcScaffold(
      title: 'Notifications',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          const SectionHeader('Channels'),
          card(
            Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_active_outlined),
                  title: const Text('Push notifications'),
                  subtitle: const Text('Trip, vote and pantry reminders'),
                  value: prefs.pushEnabled,
                  onChanged: (v) => save(prefs.copyWith(pushEnabled: v)),
                ),
                divider(),
                SwitchListTile(
                  secondary: const Icon(Icons.email_outlined),
                  title: const Text('Email'),
                  subtitle: const Text('Weekly plan and spending summaries'),
                  value: prefs.emailEnabled,
                  onChanged: (v) => save(prefs.copyWith(emailEnabled: v)),
                ),
              ],
            ),
          ),
          const SectionHeader('What we can send'),
          card(
            Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.shopping_cart_outlined),
                  title: const Text('Shopping trip reminders'),
                  value: prefs.tripReminders,
                  onChanged: (v) => save(prefs.copyWith(tripReminders: v)),
                ),
                divider(),
                SwitchListTile(
                  secondary: const Icon(Icons.how_to_vote_outlined),
                  title: const Text('Vote round reminders'),
                  subtitle: const Text('Only for rounds an adult opened.'),
                  value: prefs.voteReminders,
                  onChanged: (v) => save(prefs.copyWith(voteReminders: v)),
                ),
                divider(),
                SwitchListTile(
                  secondary: const Icon(Icons.kitchen_outlined),
                  title: const Text('Pantry expiry estimates'),
                  value: prefs.pantryExpiry,
                  onChanged: (v) => save(prefs.copyWith(pantryExpiry: v)),
                ),
                divider(),
                SwitchListTile(
                  secondary: const Icon(Icons.restaurant_outlined),
                  title: const Text('Meal prep reminders'),
                  value: prefs.mealPrep,
                  onChanged: (v) => save(prefs.copyWith(mealPrep: v)),
                ),
              ],
            ),
          ),
          const SectionHeader('Quiet hours'),
          card(
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: FamilyCircleColors.tertiary.withValues(alpha: .13),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.bedtime_outlined,
                  color: FamilyCircleColors.tertiary,
                ),
              ),
              title: Text(
                '${prefs.quietStartHour}:00 – ${prefs.quietEndHour}:00',
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              subtitle: const Text(
                'Nothing is sent during quiet hours (device timezone).',
              ),
              trailing: FilledButton.tonal(
                onPressed: () => _editQuietHours(context, prefs, save),
                child: const Text('Edit'),
              ),
            ),
          ),
          const SectionHeader('Kids & limits'),
          card(
            Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.child_care_outlined),
                  title: const Text('Kid reminders (parent-controlled)'),
                  subtitle: const Text(
                    'At most 1 per week, quest reminders only. Never engagement nudges.',
                  ),
                  value: prefs.minorOptIn,
                  onChanged: (v) => save(prefs.copyWith(minorOptIn: v)),
                ),
                divider(),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Frequency caps'),
                  subtitle: const Text(
                    'Adults get at most 3 non-critical messages a week; kids at most 1 when a parent opts in.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _editQuietHours(
    BuildContext context,
    NotificationPrefs prefs,
    void Function(NotificationPrefs) save,
  ) {
    var start = prefs.quietStartHour;
    var end = prefs.quietEndHour;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Quiet hours'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Starts'),
                trailing: DropdownButton<int>(
                  value: start,
                  items: [
                    for (var h = 18; h <= 23; h++)
                      DropdownMenuItem(value: h, child: Text('$h:00')),
                  ],
                  onChanged: (v) => setState(() => start = v ?? start),
                ),
              ),
              ListTile(
                title: const Text('Ends'),
                trailing: DropdownButton<int>(
                  value: end,
                  items: [
                    for (var h = 5; h <= 10; h++)
                      DropdownMenuItem(value: h, child: Text('$h:00')),
                  ],
                  onChanged: (v) => setState(() => end = v ?? end),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                save(prefs.copyWith(quietStartHour: start, quietEndHour: end));
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
