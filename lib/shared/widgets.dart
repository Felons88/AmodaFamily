/// Design tokens for the Kinplora warm food-app palette: cream surfaces,
/// deep green primary, terracotta/amber accents, warm charcoal dark theme.
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

final appStoreProvider = ChangeNotifierProvider<AppStore>((ref) {
  final store = AppStore();
  AppStore.instanceFromAuth = store;
  store.restoreSupabaseSession();
  return store;
});

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
    this.bottomNavigationBar,
    this.extendBody = false,
  });

  final String title;
  final Widget child;
  final List<Widget>? actions;
  final Widget? fab;
  final bool showBack;
  final Widget? bottomNavigationBar;
  final bool extendBody;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        automaticallyImplyLeading: showBack,
        actions: actions,
      ),
      floatingActionButton: fab,
      bottomNavigationBar: bottomNavigationBar,
      extendBody: extendBody,
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
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: FamilyCircleColors.warning.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: FamilyCircleColors.warning.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: FamilyCircleColors.warning.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off,
                size: 16,
                color: FamilyCircleColors.warning,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                store.pending.isEmpty
                    ? 'You are offline. Showing saved content.'
                    : 'Offline. ${store.pending.length} change(s) will send when you reconnect.',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.onSurface),
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
    this.margin,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) {
    final card = Card(
      clipBehavior: Clip.antiAlias,
      margin: margin,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
    return card;
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.1,
                color: scheme.onSurface,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Alias kept for the Fc-prefixed component contract.
class FcSection extends StatelessWidget {
  const FcSection(this.title, {super.key, this.trailing, this.child});

  final String title;
  final Widget? trailing;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title, trailing: trailing),
        ?child,
      ],
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: c.withValues(alpha: 0.24)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon case final i?) ...[
              Icon(i, size: 13, color: c),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: c,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pill-shaped primary action used across feature surfaces.
class FcPrimaryButton extends StatelessWidget {
  const FcPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expanded = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final button = FilledButton.icon(
      onPressed: onPressed,
      icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 18),
      label: Text(label),
      style: expanded
          ? FilledButton.styleFrom(minimumSize: const Size.fromHeight(50))
          : null,
    );
    return expanded ? SizedBox(width: double.infinity, child: button) : button;
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
/// Placeholder art uses warm terracotta/sage/amber gradient palettes seeded
/// by the recipe's alt text so each dish gets a stable, appetizing backdrop.
class DishImage extends StatelessWidget {
  const DishImage({super.key, required this.image, this.height = 140});

  final RecipeImage image;
  final double height;

  static const _lightPalettes = [
    // Terracotta
    (gradient: [Color(0xFFFCE9DC), Color(0xFFF3C4A4)], icon: Color(0xFFB85C38)),
    // Sage
    (gradient: [Color(0xFFEAF0E2), Color(0xFFCBDFC0)], icon: Color(0xFF5F7D4F)),
    // Amber
    (gradient: [Color(0xFFFDF1D6), Color(0xFFF6DDA9)], icon: Color(0xFFB07F22)),
  ];

  static const _darkPalettes = [
    // Terracotta
    (gradient: [Color(0xFF3A2B24), Color(0xFF4E352A)], icon: Color(0xFFE8A87C)),
    // Sage
    (gradient: [Color(0xFF25301F), Color(0xFF33412A)], icon: Color(0xFFB7D6A8)),
    // Amber
    (gradient: [Color(0xFF3A2F1E), Color(0xFF4C3C24)], icon: Color(0xFFE8C37E)),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final (icon, label) = switch (image.kind) {
      ImageKind.verifiedPhoto => (Icons.restaurant, image.altText),
      ImageKind.aiIllustration => (Icons.auto_awesome, image.altText),
      ImageKind.placeholder => (Icons.dinner_dining, image.altText),
    };
    final seed = image.altText.codeUnits.fold(0, (a, b) => a + b);
    final palette = (dark ? _darkPalettes : _lightPalettes)[seed.abs() % 3];
    final accent = palette.icon;
    return Semantics(
      image: true,
      label: image.altText,
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: palette.gradient,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: dark ? 0.22 : 0.16),
                shape: BoxShape.circle,
                border: Border.all(
                  color: accent.withValues(alpha: 0.35),
                  width: 1.2,
                ),
              ),
              child: Icon(icon, size: 32, color: accent),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                image.badge,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    scheme.primary.withValues(alpha: 0.2),
                    scheme.tertiary.withValues(alpha: 0.14),
                  ],
                ),
                border: Border.all(
                  color: scheme.primary.withValues(alpha: 0.22),
                ),
              ),
              child: Icon(icon, size: 42, color: scheme.primary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              FcPrimaryButton(
                label: actionLabel!,
                onPressed: onAction,
                expanded: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Alias kept for the Fc-prefixed component contract.
class FcEmptyState extends StatelessWidget {
  const FcEmptyState({
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
    return EmptyState(
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
      icon: icon,
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
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant
                  .withValues(alpha: 0.4),
            ),
          ),
          child: const _Shimmer(),
        ),
      ),
    );
  }
}

/// Fc-prefixed alias for [SkeletonList].
class FcLoadingState extends StatelessWidget {
  const FcLoadingState({super.key, this.count = 4});

  final int count;

  @override
  Widget build(BuildContext context) => SkeletonList(count: count);
}

class _Shimmer extends StatefulWidget {
  const _Shimmer();

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-1 + 2 * t, 0),
                end: Alignment(1 + 2 * t, 0),
                colors: [
                  Colors.transparent,
                  scheme.onSurface.withValues(alpha: 0.06),
                  Colors.transparent,
                ],
              ),
            ),
          );
        },
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
    final seed = name.isEmpty ? 0 : name.codeUnits.fold(0, (a, b) => a + b);
    final base = minor ? scheme.tertiary : scheme.primary;
    final angle = (seed % 4) * 0.5 - 0.5;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment(angle, -angle),
          end: Alignment(-angle, angle),
          colors: [
            base.withValues(alpha: minor ? 0.5 : 0.85),
            base.withValues(alpha: 0.35),
          ],
        ),
        border: Border.all(color: base.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Center(
        child: Text(
          name.isEmpty ? '?' : name.characters.first.toUpperCase(),
          style: TextStyle(
            color: minor ? scheme.tertiary : scheme.onPrimary,
            fontWeight: FontWeight.w800,
            fontSize: size * 0.42,
          ),
        ),
      ),
    );
  }
}

/// Days-left chip colored by food urgency: fresh green, amber when expiring
/// soon (<=3 days), coral/red once expired or past date.
class FreshnessBadge extends StatelessWidget {
  const FreshnessBadge({super.key, required this.daysLeft, this.icon});

  /// Negative or zero means expired / expires today.
  final int daysLeft;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final light = Theme.of(context).brightness == Brightness.light;
    final (color, iconData, label) = switch (daysLeft) {
      < 0 => (
        light ? FamilyCircleColors.lightExpired : FamilyCircleColors.expired,
        Icons.error_outline,
        'Expired',
      ),
      0 => (
        light
            ? FamilyCircleColors.lightExpiringSoon
            : FamilyCircleColors.expiringSoon,
        Icons.schedule,
        'Expires today',
      ),
      1 => (
        light
            ? FamilyCircleColors.lightExpiringSoon
            : FamilyCircleColors.expiringSoon,
        Icons.schedule,
        '1 day left',
      ),
      <= 3 => (
        light
            ? FamilyCircleColors.lightExpiringSoon
            : FamilyCircleColors.expiringSoon,
        Icons.schedule,
        '$daysLeft days left',
      ),
      _ => (
        light ? FamilyCircleColors.lightFresh : FamilyCircleColors.fresh,
        Icons.eco_outlined,
        '$daysLeft days left',
      ),
    };
    return FcChip(label, icon: icon ?? iconData, color: color);
  }
}

/// Rounded icon tile used for pantry categories and quick filters.
class CategoryIconTile extends StatelessWidget {
  const CategoryIconTile({
    super.key,
    required this.icon,
    required this.label,
    this.color,
    this.onTap,
    this.size = 52,
  });

  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = color ?? scheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: c.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: c.withValues(alpha: 0.22)),
              ),
              child: Icon(icon, size: size * 0.46, color: c),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
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
