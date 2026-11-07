/// Family Circle design system components.
/// Tokens from docs/design_system/DESIGN_SYSTEM.md: restrained charcoal
/// surfaces, fresh-green accent, cream text, 4pt spacing, 12/16/24 radii,
/// >=44pt touch targets, no emojis, labeled image states.
library;

import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../app/theme.dart';
import 'errors.dart';
import 'models.dart';
import 'store.dart';

export 'store.dart' show AppStore;

final appStoreProvider = ChangeNotifierProvider<AppStore>((ref) => AppStore());

String fmtCents(int cents) {
  final sign = cents < 0 ? '-' : '';
  final abs = cents.abs();
  return '$sign\$${abs ~/ 100}.${(abs % 100).toString().padLeft(2, '0')}';
}

String fmtQty(FoodQuantity q) => switch (q.unit) {
  FoodUnit.grams =>
    q.amount >= 1000
        ? '${(q.amount / 1000).toStringAsFixed(1)} kg'
        : '${q.amount} g',
  FoodUnit.milliliters =>
    q.amount >= 1000
        ? '${(q.amount / 1000).toStringAsFixed(1)} L'
        : '${q.amount} ml',
  FoodUnit.pieces => '${q.amount} pc',
};

// ---------- scaffolding ----------

class FcScaffold extends StatelessWidget {
  const FcScaffold({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.fab,
    this.showBack = true,
  });

  final String title;
  final Widget child;
  final List<Widget>? actions;
  final Widget? fab;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        automaticallyImplyLeading: showBack,
        actions: actions,
      ),
      floatingActionButton: fab,
      body: SafeArea(
        child: Column(
          children: [
            const OfflineBanner(),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(appStoreProvider);
    if (!store.isOffline) return const SizedBox.shrink();
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        color: FamilyCircleColors.warning.withValues(alpha: 0.16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.cloud_off, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                store.pending.isEmpty
                    ? 'You are offline. Showing saved content.'
                    : 'Offline. ${store.pending.length} change(s) will send when you reconnect.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- content blocks ----------

class FcCard extends StatelessWidget {
  const FcCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class FcChip extends StatelessWidget {
  const FcChip(this.label, {super.key, this.icon, this.color});

  final String label;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = color ?? scheme.primary;
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: c.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon case final i?) ...[
              Icon(i, size: 14, color: c),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: c),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- money & provenance (adult surfaces only) ----------

/// Renders money only for adult actors; children never see amounts.
class MoneyText extends ConsumerWidget {
  const MoneyText(this.cents, {super.key, this.style});

  final int cents;
  final TextStyle? style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible = ref.watch(appStoreProvider).showPrices;
    if (!visible) return const SizedBox.shrink();
    return Text(fmtCents(cents), style: style);
  }
}

/// Every estimate carries source, date and confidence per contract.
class EstimateBadge extends StatelessWidget {
  const EstimateBadge({super.key, required this.offer});

  final PriceOffer offer;

  @override
  Widget build(BuildContext context) {
    final date =
        '${offer.observedAt.year}-${offer.observedAt.month.toString().padLeft(2, '0')}-${offer.observedAt.day.toString().padLeft(2, '0')}';
    return Tooltip(
      message:
          'Source: ${offer.source} • Region: ${offer.region}\nObserved: $date • Confidence: ${(offer.confidence * 100).round()}%',
      child: FcChip(
        'Estimate • ${(offer.confidence * 100).round()}% confident',
        icon: Icons.info_outline,
        color: FamilyCircleColors.warning,
      ),
    );
  }
}

class SnapBadge extends StatelessWidget {
  const SnapBadge({super.key, required this.eligibility});

  final BenefitEligibility eligibility;

  @override
  Widget build(BuildContext context) {
    return switch (eligibility) {
      BenefitEligibility.eligible => const FcChip(
        'SNAP eligible (verified)',
        icon: Icons.check_circle_outline,
      ),
      BenefitEligibility.ineligible => const FcChip(
        'Not SNAP eligible',
        icon: Icons.block,
        color: FamilyCircleColors.muted,
      ),
      BenefitEligibility.unknown => const FcChip(
        'SNAP eligibility unverified',
        icon: Icons.help_outline,
        color: FamilyCircleColors.warning,
      ),
    };
  }
}

// ---------- recipe imagery ----------

/// Never shows a wrong dish: labeled placeholder when no verified photo.
class DishImage extends StatelessWidget {
  const DishImage({super.key, required this.image, this.height = 140});

  final RecipeImage image;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, label) = switch (image.kind) {
      ImageKind.verifiedPhoto => (Icons.restaurant, image.altText),
      ImageKind.aiIllustration => (Icons.auto_awesome, image.altText),
      ImageKind.placeholder => (Icons.dinner_dining, image.altText),
    };
    return Semantics(
      image: true,
      label: image.altText,
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: FamilyCircleColors.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: scheme.primary),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                image.badge,
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: FamilyCircleColors.muted),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- states ----------

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.icon = Icons.inbox_outlined,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final fc = error is FcException ? error as FcException : null;
    return EmptyState(
      icon: Icons.error_outline,
      title: 'Something needs attention',
      message: fc?.safeMessage ?? 'An unexpected problem occurred.',
      actionLabel: (fc?.retryable ?? false) && onRetry != null
          ? 'Try again'
          : null,
      onAction: onRetry,
    );
  }
}

class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 4});

  final int count;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: count,
      itemBuilder: (context, i) => Semantics(
        label: 'Loading',
        child: Container(
          height: 84,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: FamilyCircleColors.surfaceElevated.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

// ---------- shared tiles ----------

class MemberAvatar extends StatelessWidget {
  const MemberAvatar({
    super.key,
    required this.name,
    this.minor = false,
    this.size = 36,
  });

  final String name;
  final bool minor;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: minor
          ? scheme.tertiary.withValues(alpha: 0.25)
          : scheme.primary.withValues(alpha: 0.2),
      child: Text(
        name.isEmpty ? '?' : name.characters.first.toUpperCase(),
        style: TextStyle(
          color: minor ? scheme.tertiary : scheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

IconData gameIcon(String key) => switch (key) {
  'trophy' => Icons.emoji_events_outlined,
  'grid' => Icons.grid_on,
  'shuffle' => Icons.shuffle,
  'tag' => Icons.sell_outlined,
  'rescue' => Icons.kitchen_outlined,
  'stack' => Icons.layers_outlined,
  'mystery' => Icons.help_outline,
  'globe' => Icons.public,
  'menu_book' => Icons.menu_book_outlined,
  'shield' => Icons.shield_outlined,
  'quiz' => Icons.quiz_outlined,
  'chef' => Icons.soup_kitchen_outlined,
  'people' => Icons.people_outline,
  'search' => Icons.search,
  'fridge' => Icons.ac_unit_outlined,
  _ => Icons.sports_esports_outlined,
};
