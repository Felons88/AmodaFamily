/// ONB-001..ONB-006 onboarding flow + guest preview.
/// Progressive, one task per screen, skippable where the contract allows.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../shared/catalog.dart' as catalog;
import '../../shared/errors.dart';
import '../../shared/models.dart';
import '../../shared/widgets.dart';

void _showError(BuildContext context, Object error) {
  final message = error is FcException
      ? error.safeMessage
      : 'Something went wrong. Try again.';
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

// ---------- shared onboarding chrome ----------

/// Slim progress row ("Step N of 6") pinned above each onboarding step.
class _StepProgress extends StatelessWidget {
  const _StepProgress({required this.step});

  final int step;
  static const int _total = 6;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Step $step of $_total',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
              const Spacer(),
              Text(
                'Setup',
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: step / _total,
              minHeight: 4,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }
}

/// Cheap staggered entrance animation for onboarding blocks.
class _FadeSlideIn extends StatelessWidget {
  const _FadeSlideIn({required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;
  static const double _offset = 14;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420) + delay,
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - t) * _offset),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// Onboarding step scaffold: progress row + scrollable content.
class _StepScaffold extends StatelessWidget {
  const _StepScaffold({
    required this.title,
    required this.step,
    required this.child,
    this.showBack = true,
  });

  final String title;
  final int step;
  final Widget child;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return FcScaffold(
      title: title,
      showBack: showBack,
      child: Column(
        children: [
          _StepProgress(step: step),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Frosted benefit row used on the dark welcome hero.
class _HeroBenefit extends StatelessWidget {
  const _HeroBenefit({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: FamilyCircleColors.primary.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 19, color: FamilyCircleColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: FamilyCircleColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: FamilyCircleColors.muted, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Themed Google sign-in button used on account surfaces.
class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.onPressed, required this.label});

  final VoidCallback? onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return OutlinedButton.icon(
      icon: Icon(Icons.g_mobiledata, size: 26, color: scheme.primary),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.onSurface,
        side: BorderSide(color: scheme.outlineVariant),
        backgroundColor: scheme.surface,
      ),
      onPressed: onPressed,
    );
  }
}

// ---------- ONB-001 Welcome / landing ----------

class WelcomePage extends ConsumerWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Branded hero backdrop — designed surface, not stock photography.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0D1A10),
                  Color(0xFF10231A),
                  Color(0xFF215C35),
                ],
              ),
            ),
          ),
          Positioned(
            top: -60,
            right: -60,
            child: CircleAvatar(
              radius: 160,
              backgroundColor: FamilyCircleColors.primary.withValues(
                alpha: 0.10,
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -40,
            child: CircleAvatar(
              radius: 200,
              backgroundColor: FamilyCircleColors.primary.withValues(
                alpha: 0.08,
              ),
            ),
          ),
          Positioned(
            top: 120,
            left: -50,
            child: CircleAvatar(
              radius: 90,
              backgroundColor: FamilyCircleColors.primary.withValues(
                alpha: 0.06,
              ),
            ),
          ),
          // Soft glow behind the hero copy.
          Positioned(
            top: 180,
            right: -80,
            child: CircleAvatar(
              radius: 140,
              backgroundColor: FamilyCircleColors.primary.withValues(
                alpha: 0.07,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _FadeSlideIn(
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: FamilyCircleColors.primary.withValues(
                                alpha: 0.16,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: FamilyCircleColors.primary.withValues(
                                  alpha: 0.35,
                                ),
                              ),
                            ),
                            child: const Icon(
                              Icons.dinner_dining,
                              size: 24,
                              color: FamilyCircleColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Family Circle',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: FamilyCircleColors.text,
                                  letterSpacing: 0.2,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    _FadeSlideIn(
                      delay: const Duration(milliseconds: 80),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Plan a safe,\naffordable week\nof meals — together.',
                            style: Theme.of(context).textTheme.displaySmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: FamilyCircleColors.text,
                                  height: 1.12,
                                ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Allergy-checked plans, shared grocery lists, family votes and kid-safe games — built for real households.',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: FamilyCircleColors.muted,
                                  height: 1.45,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _FadeSlideIn(
                      delay: const Duration(milliseconds: 160),
                      child: Column(
                        children: const [
                          _HeroBenefit(
                            icon: Icons.verified_user_outlined,
                            title: 'Allergy-safe plans',
                            subtitle: 'Hard allergies checked on every dish — unknowns are never guessed.',
                          ),
                          SizedBox(height: 10),
                          _HeroBenefit(
                            icon: Icons.account_balance_wallet_outlined,
                            title: 'SNAP + cash budgets',
                            subtitle: 'Weekly budgets that keep the whole basket affordable.',
                          ),
                          SizedBox(height: 10),
                          _HeroBenefit(
                            icon: Icons.child_care_outlined,
                            title: 'Kid-safe mode',
                            subtitle: 'Managed kid profiles with age-appropriate games and votes.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    _FadeSlideIn(
                      delay: const Duration(milliseconds: 240),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FilledButton.icon(
                            icon: const Icon(Icons.arrow_forward),
                            label: const Text('Get started'),
                            onPressed: () => context.go(AppRoute.account.path),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            icon: const Icon(
                              Icons.g_mobiledata,
                              size: 26,
                              color: Colors.white,
                            ),
                            label: const Text('Continue with Google'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.08,
                              ),
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.35),
                              ),
                            ),
                            onPressed: () {
                              ref.read(appStoreProvider).signInWithGoogle();
                              context.go(AppRoute.household.path);
                            },
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton(
                                onPressed: () =>
                                    context.go(AppRoute.preview.path),
                                child: Text(
                                  'Preview meals',
                                  style: TextStyle(
                                    color: FamilyCircleColors.muted,
                                  ),
                                ),
                              ),
                              Text(
                                '•',
                                style: TextStyle(
                                  color: FamilyCircleColors.muted.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () =>
                                    ref.read(appStoreProvider).signInDemo(),
                                child: Text(
                                  'Try demo',
                                  style: TextStyle(
                                    color: FamilyCircleColors.muted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Guest preview ----------

class GuestPreviewPage extends StatelessWidget {
  const GuestPreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final sample = catalog.recipes.values.take(6).toList();
    return FcScaffold(
      title: 'Sample meals',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Icon(
                Icons.restaurant_menu_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Sample meals',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'These are catalog examples. Create a household to get plans checked against your family\'s allergies and budget.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          for (final r in sample)
            FcCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DishImage(image: r.image, height: 110),
                  const SizedBox(height: 12),
                  Text(r.title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    '${r.meal.label} • ${r.minutes} min • serves ${r.servings}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.group_add_outlined),
            onPressed: () => context.go(AppRoute.account.path),
            label: const Text('Create your household'),
          ),
        ],
      ),
    );
  }
}

// ---------- ONB-002 Account ----------

class AccountPage extends ConsumerStatefulWidget {
  const AccountPage({super.key});

  @override
  ConsumerState<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends ConsumerState<AccountPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;

  Future<void> _submit({required bool create}) async {
    setState(() => _busy = true);
    try {
      ref
          .read(appStoreProvider)
          .signIn(
            _email.text,
            _password.text,
            create: create,
            name: _name.text,
          );
      if (mounted) context.go(AppRoute.household.path);
    } on FcException catch (e) {
      if (mounted) _showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: 'Create your account',
      step: 2,
      showBack: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        children: [
          _FadeSlideIn(
            child: Text(
              'An adult account manages the household, budget and approvals.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          const SizedBox(height: 24),
          _FadeSlideIn(
            delay: const Duration(milliseconds: 60),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant
                      .withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    autofillHints: const [AutofillHints.name],
                    decoration: InputDecoration(
                      labelText: 'Your name',
                      hintText: 'Jordan Rivera',
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'you@example.com',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    autofillHints: const [AutofillHints.newPassword],
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      hintText: 'At least 8 characters',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _FadeSlideIn(
            delay: const Duration(milliseconds: 140),
            child: FilledButton(
              onPressed: _busy ? null : () => _submit(create: true),
              child: Text(_busy ? 'Creating account…' : 'Create account'),
            ),
          ),
          const SizedBox(height: 20),
          _FadeSlideIn(
            delay: const Duration(milliseconds: 200),
            child: Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'or continue with',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _FadeSlideIn(
            delay: const Duration(milliseconds: 240),
            child: _GoogleButton(
              label: 'Sign up with Google',
              onPressed: _busy
                  ? null
                  : () {
                      ref
                          .read(appStoreProvider)
                          .signInWithGoogle(name: _name.text);
                      context.go(AppRoute.household.path);
                    },
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: _busy ? null : () => _submit(create: false),
              child: const Text('Already have an account? Sign in'),
            ),
          ),
          const SizedBox(height: 16),
          _FadeSlideIn(
            delay: const Duration(milliseconds: 300),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Kids never need accounts — adults add managed kid profiles next.',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: FamilyCircleColors.muted),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- ONB-003 Household ----------

class HouseholdPage extends ConsumerStatefulWidget {
  const HouseholdPage({super.key});

  @override
  ConsumerState<HouseholdPage> createState() => _HouseholdPageState();
}

class _HouseholdPageState extends ConsumerState<HouseholdPage> {
  final _name = TextEditingController();
  final _memberName = TextEditingController();
  AgeBand _band = AgeBand.a9to12;
  bool _minor = true;

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(appStoreProvider);
    final circle = store.circle;
    return _StepScaffold(
      title: 'Your household',
      step: 3,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        children: [
          Text(
            'Name your household, then add the people who eat with you. Age bands are enough — no birthdates.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          if (circle == null) ...[
            _FadeSlideIn(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant
                        .withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _name,
                      decoration: const InputDecoration(
                        labelText: 'Household name',
                        hintText: 'The Rivera Family',
                        prefixIcon: Icon(Icons.home_work_outlined),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      icon: const Icon(Icons.group_add_outlined),
                      label: const Text('Create household'),
                      onPressed: () {
                        try {
                          store.createCircle(_name.text);
                        } on FcException catch (e) {
                          _showError(context, e);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            _FadeSlideIn(
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    circle.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _FadeSlideIn(
              delay: const Duration(milliseconds: 80),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    for (final m in circle.activeMembers)
                      ListTile(
                        leading: MemberAvatar(name: m.name, minor: m.isMinor),
                        title: Text(m.name),
                        subtitle: Text(
                          m.isMinor
                              ? 'Kid profile • ${m.ageBand.label}'
                              : 'Adult',
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 2,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _FadeSlideIn(
              delay: const Duration(milliseconds: 140),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant
                        .withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.person_add_alt_1_outlined,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Add a member',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _memberName,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        hintText: 'Sam Rivera',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: false, label: Text('Adult')),
                        ButtonSegment(value: true, label: Text('Managed kid')),
                      ],
                      selected: {_minor},
                      onSelectionChanged: (s) =>
                          setState(() => _minor = s.first),
                    ),
                    if (_minor) ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<AgeBand>(
                        initialValue: _band,
                        decoration: const InputDecoration(
                          labelText: 'Age band',
                          prefixIcon: Icon(Icons.child_care_outlined),
                        ),
                        items: [
                          for (final b in AgeBand.values.where(
                            (b) => b.isMinor,
                          ))
                            DropdownMenuItem(
                              value: b,
                              child: Text('Ages ${b.label}'),
                            ),
                        ],
                        onChanged: (v) => setState(() => _band = v ?? _band),
                      ),
                    ],
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.person_add_outlined),
                      label: const Text('Add member'),
                      onPressed: () {
                        try {
                          store.addMember(
                            _memberName.text,
                            minor: _minor,
                            band: _band,
                          );
                          _memberName.clear();
                        } on FcException catch (e) {
                          _showError(context, e);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _FadeSlideIn(
              delay: const Duration(milliseconds: 220),
              child: FilledButton.icon(
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Continue'),
                onPressed: () => context.go(AppRoute.foodNeeds.path),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------- ONB-004 Food needs ----------

class FoodNeedsPage extends ConsumerStatefulWidget {
  const FoodNeedsPage({super.key});

  @override
  ConsumerState<FoodNeedsPage> createState() => _FoodNeedsPageState();
}

class _FoodNeedsPageState extends ConsumerState<FoodNeedsPage> {
  final Map<String, Set<String>> _selections = {};

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(appStoreProvider);
    final members = store.circle?.activeMembers ?? [];
    return _StepScaffold(
      title: 'Food needs',
      step: 4,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        children: [
          Text(
            'Mark hard allergies for each person. Anything we cannot verify is treated as unsafe — unknown ingredients are never guessed.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: FamilyCircleColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber_outlined,
                  size: 18,
                  color: FamilyCircleColors.warning,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Allergies are safety rules, not taste preferences. Skipping this means no restrictions are applied.',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: FamilyCircleColors.warning),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          for (final m in members) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant
                      .withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      MemberAvatar(name: m.name, minor: m.isMinor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          m.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Builder(
                        builder: (context) {
                          final count =
                              (_selections[m.id] ?? m.hardAllergens).length;
                          return FcChip(
                            count == 0 ? 'No allergies' : '$count marked',
                            icon: count == 0
                                ? Icons.check_circle_outline
                                : Icons.warning_amber_outlined,
                            color: count == 0
                                ? Theme.of(context).colorScheme.primary
                                : FamilyCircleColors.warning,
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final key in catalog.allergenKeys)
                        FilterChip(
                          label: Text(key.replaceAll('_', ' ')),
                          selected: (_selections[m.id] ?? m.hardAllergens)
                              .contains(key),
                          onSelected: (sel) => setState(() {
                            final current = <String>{
                              ...(_selections[m.id] ?? m.hardAllergens),
                            };
                            sel ? current.add(key) : current.remove(key);
                            _selections[m.id] = current;
                          }),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          _FadeSlideIn(
            child: FilledButton.icon(
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Continue'),
              onPressed: () {
                try {
                  for (final entry in _selections.entries) {
                    store.setMemberAllergens(entry.key, entry.value);
                  }
                  context.go(AppRoute.budget.path);
                } on FcException catch (e) {
                  _showError(context, e);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- ONB-005 Budget & benefits ----------

class BudgetPage extends ConsumerStatefulWidget {
  const BudgetPage({super.key});

  @override
  ConsumerState<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends ConsumerState<BudgetPage> {
  final _cash = TextEditingController();
  final _snap = TextEditingController();
  final _depositDay = TextEditingController();

  int? _cents(String text) {
    final v = double.tryParse(text.trim());
    if (v == null || v < 0) return null;
    return (v * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.read(appStoreProvider);
    return _StepScaffold(
      title: 'Budget & benefits',
      step: 5,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        children: [
          Text(
            'Set a weekly food budget so plans stay affordable. Cash, SNAP, or both.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: FamilyCircleColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: FamilyCircleColors.warning.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.privacy_tip_outlined,
                  size: 18,
                  color: FamilyCircleColors.warning,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Enter amounts only. Never enter EBT card numbers, logins or PINs — balances are not synced.',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: FamilyCircleColors.muted),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _FadeSlideIn(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant
                      .withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _cash,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Cash budget per week',
                      prefixIcon: Icon(Icons.payments_outlined),
                      prefixText: r'$',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _snap,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'SNAP amount per week (optional)',
                      prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                      prefixText: r'$',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _depositDay,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Benefit deposit day of month (optional)',
                      hintText: '1–28',
                      prefixIcon: Icon(Icons.calendar_month_outlined),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _FadeSlideIn(
            delay: const Duration(milliseconds: 120),
            child: FilledButton.icon(
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Continue'),
              onPressed: () {
                try {
                  store.setBudget(
                    cashCents: _cents(_cash.text) ?? 0,
                    snapCents: _cents(_snap.text) ?? 0,
                    depositDay: int.tryParse(_depositDay.text.trim()),
                  );
                  context.go(AppRoute.firstPlan.path);
                } on FcException catch (e) {
                  _showError(context, e);
                }
              },
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => context.go(AppRoute.firstPlan.path),
              child: const Text('Skip for now'),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- ONB-006 First plan ----------

class FirstPlanPage extends ConsumerStatefulWidget {
  const FirstPlanPage({super.key});

  @override
  ConsumerState<FirstPlanPage> createState() => _FirstPlanPageState();
}

class _FirstPlanPageState extends ConsumerState<FirstPlanPage> {
  bool _generating = false;

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(appStoreProvider);
    final plan = store.plan;
    return _StepScaffold(
      title: 'Your first week',
      step: 6,
      child: plan == null
          ? _buildGenerate(context, store)
          : _buildPlan(context, store, plan),
    );
  }

  Widget _buildGenerate(BuildContext context, AppStore store) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Build your first plan',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Seven days of meals, checked against your household\'s allergies and budget. Every price is a labeled estimate.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: Icon(
                _generating ? Icons.hourglass_top : Icons.auto_awesome,
              ),
              onPressed: _generating
                  ? null
                  : () async {
                      setState(() => _generating = true);
                      await Future<void>.delayed(
                        const Duration(milliseconds: 600),
                      );
                      if (!context.mounted) return;
                      try {
                        store.generatePlan();
                      } on FcException catch (e) {
                        if (context.mounted) _showError(context, e);
                      } finally {
                        if (mounted) setState(() => _generating = false);
                      }
                    },
              label: Text(
                _generating ? 'Checking safe recipes…' : 'Generate plan',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Takes a few seconds — every dish is re-checked against your family\'s allergies.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlan(BuildContext context, AppStore store, WeekPlan plan) {
    final total = plan.basket?.totalEstimateCents;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Your plan is ready',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${plan.slots.length} meals across 7 days',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (total != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      'Estimated basket: ',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    MoneyText(
                      total,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(width: 8),
                    const FcChip(
                      'Sample estimate',
                      icon: Icons.info_outline,
                      color: FamilyCircleColors.warning,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (var day = 0; day < 7; day++)
          FcCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Day ${day + 1}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
                const Divider(height: 16),
                for (final meal in MealType.values)
                  Builder(
                    builder: (context) {
                      final slot = plan.slots
                          .where((s) => s.day == day && s.meal == meal)
                          .firstOrNull;
                      final recipe = slot == null
                          ? null
                          : catalog.recipes[slot.recipeId];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: Icon(
                          Icons.restaurant_menu_outlined,
                          size: 20,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        title: Text(recipe?.title ?? '—'),
                        subtitle: Text(meal.label),
                      );
                    },
                  ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        FilledButton.icon(
          icon: const Icon(Icons.check),
          onPressed: () {
            try {
              store.approvePlan(plan.revision);
              context.go(AppRoute.home.path);
            } on FcException catch (e) {
              _showError(context, e);
            }
          },
          label: const Text('Approve plan'),
        ),
        const SizedBox(height: 8),
        Text(
          'You can replace any meal later — swaps are always re-checked for safety.',
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
