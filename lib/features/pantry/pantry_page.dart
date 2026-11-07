/// ADULT-005 Pantry — NoWaste-style expiry zones, quantity and days-left
/// badges. Manual-first entry; camera/OCR remains explicitly unavailable.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../shared/catalog.dart' as catalog;
import '../../shared/errors.dart';
import '../../shared/models.dart';
import '../../shared/widgets.dart';

class PantryPage extends ConsumerWidget {
  const PantryPage({super.key});

  static const _zoneOrder = ['Fridge', 'Freezer', 'Pantry'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(appStoreProvider);
    final items = store.pantry;
    final now = DateTime.now();
    final grouped = <String, List<PantryItem>>{};
    for (final item in items) {
      grouped.putIfAbsent(_zoneFor(item), () => []).add(item);
    }
    final expiring = items.where((p) => p.expiringSoon(now)).length;

    return FcScaffold(
      title: 'Pantry',
      fab: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context, store),
        icon: const Icon(Icons.add),
        label: const Text('Add item'),
      ),
      child: items.isEmpty
          ? const EmptyState(
              icon: Icons.kitchen_outlined,
              title: 'Pantry is empty',
              message: 'Add what you have on hand — confirmed items reduce your grocery list.',
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                _PantrySummary(
                  total: items.length,
                  expiring: expiring,
                  confirmed: items.where((p) => p.confirmed).length,
                ),
                for (final zone in _zoneOrder)
                  if (grouped[zone]?.isNotEmpty ?? false) ...[
                    SectionHeader(zone),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: FcCard(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          children: [
                            for (var i = 0; i < grouped[zone]!.length; i++) ...[
                              _PantryTile(
                                item: grouped[zone]![i],
                                now: now,
                                onAdjust: () => _showAdjustSheet(
                                  context,
                                  store,
                                  grouped[zone]![i],
                                ),
                              ),
                              if (i < grouped[zone]!.length - 1)
                                Divider(
                                  height: 1,
                                  indent: 68,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outlineVariant
                                      .withValues(alpha: .45),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
              ],
            ),
    );
  }

  String _zoneFor(PantryItem item) {
    return switch (item.ingredientId) {
      'frozen_veg' => 'Freezer',
      'milk_whole' ||
      'cheese_cheddar' ||
      'yogurt_plain' ||
      'egg' ||
      'chicken_breast' ||
      'ground_beef' ||
      'salmon' ||
      'cucumber' ||
      'lettuce' ||
      'bell_pepper' ||
      'hummus' => 'Fridge',
      _ => 'Pantry',
    };
  }

  void _showAddSheet(BuildContext context, AppStore store) {
    String? selected;
    final amount = TextEditingController();
    final days = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: SafeArea(
          child: StatefulBuilder(
            builder: (context, setSheetState) => Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Add pantry item',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selected,
                    decoration: const InputDecoration(labelText: 'Ingredient'),
                    items: [
                      for (final ing in catalog.ingredients.values)
                        DropdownMenuItem(value: ing.id, child: Text(ing.name)),
                    ],
                    onChanged: (v) => setSheetState(() => selected = v),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amount,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText:
                          'Amount ${selected == null ? '' : '(${switch (catalog.ingredients[selected]!.stockUnit) {
                                  FoodUnit.grams => 'g',
                                  FoodUnit.milliliters => 'ml',
                                  FoodUnit.pieces => 'pieces',
                                }})'}',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: days,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Expires in days (optional)',
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      try {
                        if (selected == null) {
                          throw const FcException(
                            FcErrorCode.validation,
                            'Pick an ingredient.',
                          );
                        }
                        store.addPantryItem(
                          selected!,
                          int.tryParse(amount.text.trim()) ?? 0,
                          expiresAt: int.tryParse(days.text.trim()) == null
                              ? null
                              : DateTime.now().add(
                                  Duration(days: int.parse(days.text.trim())),
                                ),
                        );
                        Navigator.of(sheetContext).pop();
                      } on FcException catch (e) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(e.safeMessage)));
                      }
                    },
                    child: const Text('Add'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAdjustSheet(BuildContext context, AppStore store, PantryItem item) {
    final controller = TextEditingController(text: '${item.quantity.amount}');
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Adjust ${catalog.ingredients[item.ingredientId]?.name ?? item.ingredientId}',
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'New amount'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  try {
                    store.adjustPantry(
                      item.ingredientId,
                      int.tryParse(controller.text.trim()) ?? -1,
                    );
                    Navigator.of(sheetContext).pop();
                  } on FcException catch (e) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(e.safeMessage)));
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PantrySummary extends StatelessWidget {
  const _PantrySummary({
    required this.total,
    required this.expiring,
    required this.confirmed,
  });

  final int total;
  final int expiring;
  final int confirmed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: FcCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _SummaryMetric(
              icon: Icons.inventory_2_outlined,
              value: '$total',
              label: 'items',
            ),
            _SummaryMetric(
              icon: Icons.verified_outlined,
              value: '$confirmed',
              label: 'confirmed',
            ),
            _SummaryMetric(
              icon: Icons.schedule_outlined,
              value: '$expiring',
              label: 'expiring soon',
              color: expiring > 0 ? FamilyCircleColors.warning : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.icon,
    required this.value,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = color ?? scheme.primary;
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: accent),
          const SizedBox(height: 5),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _PantryTile extends StatelessWidget {
  const _PantryTile({
    required this.item,
    required this.now,
    required this.onAdjust,
  });

  final PantryItem item;
  final DateTime now;
  final VoidCallback onAdjust;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ingredient = catalog.ingredients[item.ingredientId];
    final days = _daysLeft(item.expiresAt, now);
    final expiryColor = days == null
        ? scheme.onSurfaceVariant
        : days < 0 || days <= 2
        ? FamilyCircleColors.error
        : days <= 7
        ? FamilyCircleColors.warning
        : FamilyCircleColors.primary;
    final expiryLabel = days == null
        ? 'No date'
        : days < 0
        ? 'Expired'
        : days == 0
        ? 'Use today'
        : '$days day${days == 1 ? '' : 's'} left';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color:
              (item.confirmed
                      ? FamilyCircleColors.primary
                      : FamilyCircleColors.warning)
                  .withValues(alpha: .13),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(
          item.confirmed ? Icons.check_circle_outline : Icons.help_outline,
          size: 21,
          color: item.confirmed
              ? FamilyCircleColors.primary
              : FamilyCircleColors.warning,
        ),
      ),
      title: Text(
        ingredient?.name ?? item.ingredientId,
        style: Theme.of(context).textTheme.titleSmall
            ?.copyWith(fontWeight: FontWeight.w800),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            [
              fmtQty(item.quantity),
              if (item.expiresAt != null)
                'expires ${item.expiresAt!.month}/${item.expiresAt!.day}/${item.expiresAt!.year}',
            ].join(' • '),
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _Badge(label: expiryLabel, color: expiryColor),
              _Badge(
                label: item.confirmed ? 'Confirmed' : 'Unconfirmed',
                color: item.confirmed
                    ? FamilyCircleColors.primary
                    : FamilyCircleColors.warning,
                icon: item.confirmed
                    ? Icons.verified_outlined
                    : Icons.help_outline,
              ),
            ],
          ),
        ],
      ),
      trailing: IconButton(
        tooltip: 'Adjust amount',
        icon: const Icon(Icons.edit_outlined, size: 20),
        onPressed: onAdjust,
      ),
    );
  }

  int? _daysLeft(DateTime? expiresAt, DateTime now) {
    if (expiresAt == null) return null;
    final expiry = DateTime(expiresAt.year, expiresAt.month, expiresAt.day);
    final today = DateTime(now.year, now.month, now.day);
    return expiry.difference(today).inDays;
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .13),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: .28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
