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

// ---------- ONB-001 Welcome ----------

class WelcomePage extends ConsumerWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Semantics(
                header: true,
                child: Icon(
                  Icons.dinner_dining,
                  size: 72,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Family Circle',
                style: Theme.of(context).textTheme.displaySmall
                    ?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'A safe, affordable week of meals for your household — planned together.',
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(color: FamilyCircleColors.muted),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => context.go(AppRoute.account.path),
                child: const Text('Get started'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.go(AppRoute.preview.path),
                child: const Text('Preview sample meals'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  ref.read(appStoreProvider).signInDemo();
                },
                child: const Text('Explore the demo household'),
              ),
              const SizedBox(height: 8),
              Text(
                'Demo data is sample content, not real household data.',
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: FamilyCircleColors.muted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
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
          FilledButton(
            onPressed: () => context.go(AppRoute.account.path),
            child: const Text('Create your household'),
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
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;

  Future<void> _submit({required bool create}) async {
    setState(() => _busy = true);
    try {
      ref
          .read(appStoreProvider)
          .signIn(_email.text, _password.text, create: create);
      if (mounted) context.go(AppRoute.household.path);
    } on FcException catch (e) {
      if (mounted) _showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FcScaffold(
      title: 'Your account',
      showBack: false,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'An adult account manages the household, budget and approvals.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            autofillHints: const [AutofillHints.newPassword],
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _busy ? null : () => _submit(create: true),
            child: const Text('Create account'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _busy ? null : () => _submit(create: false),
            child: const Text('Sign in'),
          ),
          const SizedBox(height: 24),
          Text(
            'Children never need accounts — adults add managed kid profiles later.',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: FamilyCircleColors.muted),
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
    return FcScaffold(
      title: 'Your household',
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Name your household, then add the people who eat with you. Age bands are enough — no birthdates.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          if (circle == null) ...[
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Household name',
                hintText: 'The Rivera Family',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                try {
                  store.createCircle(_name.text);
                } on FcException catch (e) {
                  _showError(context, e);
                }
              },
              child: const Text('Create household'),
            ),
          ] else ...[
            Text(circle.name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            for (final m in circle.activeMembers)
              ListTile(
                leading: MemberAvatar(name: m.name, minor: m.isMinor),
                title: Text(m.name),
                subtitle: Text(
                  m.isMinor ? 'Kid profile • ${m.ageBand.label}' : 'Adult',
                ),
                contentPadding: EdgeInsets.zero,
              ),
            const Divider(height: 32),
            Text(
              'Add a member',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _memberName,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Adult')),
                ButtonSegment(value: true, label: Text('Managed kid')),
              ],
              selected: {_minor},
              onSelectionChanged: (s) => setState(() => _minor = s.first),
            ),
            if (_minor) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<AgeBand>(
                initialValue: _band,
                decoration: const InputDecoration(labelText: 'Age band'),
                items: [
                  for (final b in AgeBand.values.where((b) => b.isMinor))
                    DropdownMenuItem(value: b, child: Text('Ages ${b.label}')),
                ],
                onChanged: (v) => setState(() => _band = v ?? _band),
              ),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Add member'),
              onPressed: () {
                try {
                  store.addMember(_memberName.text, minor: _minor, band: _band);
                  _memberName.clear();
                } on FcException catch (e) {
                  _showError(context, e);
                }
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go(AppRoute.foodNeeds.path),
              child: const Text('Continue'),
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
    return FcScaffold(
      title: 'Food needs',
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Mark hard allergies for each person. Anything we cannot verify is treated as unsafe — unknown ingredients are never guessed.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Allergies are safety rules, not taste preferences. Skipping this means no restrictions are applied.',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: FamilyCircleColors.warning),
          ),
          const SizedBox(height: 16),
          for (final m in members) ...[
            Row(
              children: [
                MemberAvatar(name: m.name, minor: m.isMinor),
                const SizedBox(width: 12),
                Text(m.name, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final key in catalog.allergenKeys)
                  FilterChip(
                    label: Text(key.replaceAll('_', ' ')),
                    selected: (_selections[m.id] ?? m.hardAllergens).contains(
                      key,
                    ),
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
            const SizedBox(height: 20),
          ],
          FilledButton(
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
            child: const Text('Continue'),
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
    return FcScaffold(
      title: 'Budget & benefits',
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Set a weekly food budget so plans stay affordable. Cash, SNAP, or both.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: FamilyCircleColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Enter amounts only. Never enter EBT card numbers, logins or PINs — balances are not synced.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _cash,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Cash budget per week',
              prefixText: r'$',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _snap,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'SNAP amount per week (optional)',
              prefixText: r'$',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _depositDay,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Benefit deposit day of month (optional)',
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
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
            child: const Text('Continue'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.go(AppRoute.firstPlan.path),
            child: const Text('Skip for now'),
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
    return FcScaffold(
      title: 'Your first week',
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
            FilledButton(
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
              child: Text(
                _generating ? 'Checking safe recipes…' : 'Generate plan',
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
        Text(
          '${plan.slots.length} meals across 7 days',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        if (total != null)
          Row(
            children: [
              Text(
                'Estimated basket: ',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              MoneyText(total, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(width: 8),
              const FcChip(
                'Sample estimate',
                icon: Icons.info_outline,
                color: FamilyCircleColors.warning,
              ),
            ],
          ),
        const SizedBox(height: 12),
        for (var day = 0; day < 7; day++)
          FcCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Day ${day + 1}',
                  style: Theme.of(context).textTheme.titleSmall,
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
                        title: Text(recipe?.title ?? '—'),
                        subtitle: Text(meal.label),
                      );
                    },
                  ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () {
            try {
              store.approvePlan(plan.revision);
              context.go(AppRoute.home.path);
            } on FcException catch (e) {
              _showError(context, e);
            }
          },
          child: const Text('Approve plan'),
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
