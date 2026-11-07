/// Account settings — display name, sign-in identity and session controls.
/// Adult-only surface; minors are redirected by the router.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../shared/errors.dart';
import '../../shared/widgets.dart';

class AccountSettingsPage extends ConsumerStatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  ConsumerState<AccountSettingsPage> createState() =>
      _AccountSettingsPageState();
}

class _AccountSettingsPageState extends ConsumerState<AccountSettingsPage> {
  late final TextEditingController _name;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(
      text: ref.read(appStoreProvider).displayName ?? '',
    );
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    setState(() => _saving = true);
    try {
      ref.read(appStoreProvider).updateDisplayName(_name.text);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Name updated.')));
      }
    } on FcException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.safeMessage)));
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(appStoreProvider);
    final scheme = Theme.of(context).colorScheme;
    return FcScaffold(
      title: 'Account',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          FcCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Profile', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 12),
                TextField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Display name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(_saving ? 'Saving…' : 'Save'),
                  ),
                ),
              ],
            ),
          ),
          const SectionHeader('Sign-in'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FcCard(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      store.usedGoogleAuth
                          ? Icons.g_mobiledata
                          : Icons.mail_outline,
                      color: scheme.primary,
                    ),
                    title: Text(
                      store.usedGoogleAuth
                          ? 'Signed in with Google'
                          : 'Signed in with email',
                    ),
                    subtitle: Text(
                      store.userEmail ?? store.displayName ?? 'Account',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (store.isDemoMode)
                    const ListTile(
                      leading: Icon(Icons.science_outlined),
                      title: Text('Demo mode'),
                      subtitle: Text(
                        'This is sample data — sign out to start a real household.',
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () {
                ref.read(appStoreProvider).signOut();
                context.go(AppRoute.welcome.path);
              },
            ),
          ),
        ],
      ),
    );
  }
}
