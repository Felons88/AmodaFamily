/// ADULT-005 Pantry — manual-first entry; camera/OCR deferred behind
/// explicit permission and labeled unavailable in this build.
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(appStoreProvider);
    final items = store.pantry;
    return FcScaffold(
      title: 'Pantry',
      actions: [
        IconButton(
          tooltip: 'Scan items (requires camera permission)',
          icon: const Icon(Icons.photo_camera_outlined),
          onPressed: () => _showScannerSheet(context),
        ),
      ],
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
                for (final p in items)
                  Builder(
                    builder: (context) {
                      final ing = catalog.ingredients[p.ingredientId];
                      return ListTile(
                        leading: Icon(
                          p.confirmed
                              ? Icons.check_circle_outline
                              : Icons.help_outline,
                          color: p.confirmed
                              ? FamilyCircleColors.primary
                              : FamilyCircleColors.warning,
                        ),
                        title: Text(ing?.name ?? p.ingredientId),
                        subtitle: Text(
                          [
                            fmtQty(p.quantity),
                            p.confirmed ? 'confirmed' : 'unconfirmed',
                            if (p.expiresAt != null)
                              'expires ${p.expiresAt!.month}/${p.expiresAt!.day}',
                          ].join(' • '),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Adjust amount',
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              onPressed: () =>
                                  _showAdjustSheet(context, store, p),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
    );
  }

  void _showScannerSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pantry scanning',
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Camera and receipt scanning need your explicit permission and are not available in this build. Manual entry always works and is verified by you.',
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: const Text('Got it'),
              ),
            ],
          ),
        ),
      ),
    );
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
