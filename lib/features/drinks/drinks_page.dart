/// ADULT-006 Drinks — beverage profile cards with EWMA forecast and honest
/// 'initial estimate' labeling until three confirmed intervals.
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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          FcCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary
                        .withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    Icons.local_drink_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Track household beverages and what to buy before the next trip. Water suggestions are not medical advice.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          for (final bev in catalog.beverages.values) ...[
            _beverageCard(context, store, bev),
            const SizedBox(height: 10),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Forecasts use confirmed check-ins. Until three are logged, amounts are an initial estimate.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
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
    final scheme = Theme.of(context).colorScheme;
    return FcCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      scheme.primary.withValues(alpha: .85),
                      scheme.primary.withValues(alpha: .5),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  Icons.local_drink_outlined,
                  color: scheme.onPrimary,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bev.name,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'Pack size ${fmtQty(bev.packSize)}',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
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
          const SizedBox(height: 14),
          Row(
            children: [
              _ForecastMetric(
                value: '${forecast.packsNeeded.toInt()}',
                label: 'packs needed',
                icon: Icons.inventory_2_outlined,
              ),
              _ForecastMetric(
                value: profile.onHand.toStringAsFixed(1),
                label: 'on hand',
                icon: Icons.water_drop_outlined,
              ),
              _ForecastMetric(
                value: profile.servingsPerDay.toStringAsFixed(1),
                label: 'servings/day',
                icon: Icons.local_cafe_outlined,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '~${profile.servingsPerDay.toStringAsFixed(1)} servings/day set • ${forecast.packsNeeded.toInt()} pack${forecast.packsNeeded == 1 ? '' : 's'} for next trip',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => _editProfile(context, store, bev, profile),
                icon: const Icon(Icons.tune, size: 18),
                label: const Text('Edit'),
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

class _ForecastMetric extends StatelessWidget {
  const _ForecastMetric({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh.withValues(alpha: .48),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 17, color: scheme.primary),
            const SizedBox(height: 7),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
