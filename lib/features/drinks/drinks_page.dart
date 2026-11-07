/// ADULT-006 Drinks — beverage profiles, EWMA consumption forecast,
/// 'initial estimate' labeling until 3 confirmed intervals.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../shared/catalog.dart' as catalog;
import '../../shared/errors.dart';
import '../../shared/models.dart';
import '../../shared/widgets.dart';

class DrinksPage extends ConsumerWidget {
  const DrinksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(appStoreProvider);
    return FcScaffold(
      title: 'Drinks',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Track household beverages and what to buy before the next trip. Water suggestions are not medical advice.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          for (final bev in catalog.beverages.values)
            _beverageCard(context, store, bev),
          const SizedBox(height: 8),
          Text(
            'Forecasts use confirmed check-ins. Until three are logged, amounts are an initial estimate.',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: FamilyCircleColors.muted),
          ),
        ],
      ),
    );
  }

  Widget _beverageCard(BuildContext context, AppStore store, Beverage bev) {
    final profile =
        store.beverages.where((b) => b.beverageId == bev.id).firstOrNull ??
        BeverageProfile(beverageId: bev.id);
    final forecast = store.beverageForecast(bev.id);
    return FcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary
                      .withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.local_drink_outlined,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  bev.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              FcChip(
                forecast.confident ? 'Observed rate' : 'Initial estimate',
                icon: forecast.confident
                    ? Icons.check_circle_outline
                    : Icons.help_outline,
                color: forecast.confident
                    ? FamilyCircleColors.primary
                    : FamilyCircleColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '~${profile.servingsPerDay.toStringAsFixed(1)} servings/day set • ${forecast.packsNeeded.toInt()} pack${forecast.packsNeeded == 1 ? '' : 's'} (${fmtQty(bev.packSize)}) for next trip',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton(
                onPressed: () => _editProfile(context, store, bev, profile),
                child: const Text('Edit'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                icon: const Icon(Icons.playlist_add_check, size: 18),
                label: const Text('Log check-in'),
                onPressed: () => _logCheckin(context, store, bev, profile),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _editProfile(
    BuildContext context,
    AppStore store,
    Beverage bev,
    BeverageProfile profile,
  ) {
    final servings = TextEditingController(
      text: profile.servingsPerDay.toStringAsFixed(0),
    );
    final onHand = TextEditingController(
      text: profile.onHand.toStringAsFixed(1),
    );
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${bev.name} profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: servings,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Servings per day'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: onHand,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Packs on hand'),
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
              try {
                store.setBeverageProfile(
                  bev.id,
                  servingsPerDay: double.tryParse(servings.text.trim()),
                  onHand: double.tryParse(onHand.text.trim()),
                );
                Navigator.of(dialogContext).pop();
              } on FcException catch (e) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(e.safeMessage)));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _logCheckin(
    BuildContext context,
    AppStore store,
    Beverage bev,
    BeverageProfile profile,
  ) {
    final rate = TextEditingController(
      text: profile.dailyRate == 0
          ? profile.servingsPerDay.toStringAsFixed(1)
          : profile.dailyRate.toStringAsFixed(1),
    );
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Log ${bev.name} usage'),
        content: TextField(
          controller: rate,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Packs used per day'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              try {
                store.confirmBeverageInterval(
                  bev.id,
                  double.tryParse(rate.text.trim()) ?? 0,
                );
                Navigator.of(dialogContext).pop();
              } on FcException catch (e) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(e.safeMessage)));
              }
            },
            child: const Text('Log'),
          ),
        ],
      ),
    );
  }
}
