/// Game lobby — catalog of all games with per-window quota status.
/// Minors see a neutral 'available again' time, never an upgrade prompt.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../shared/catalog.dart' as catalog;
import '../../shared/models.dart';
import '../../shared/widgets.dart';

/// Warm, vivid per-game accent colors (terracotta / coral / honey family)
/// that harmonize with the cream-and-terracotta app theme. Rendered as
/// tints so both light and dark themes stay readable.
const _gameAccents = [
  Color(0xFFE8863F), // terracotta
  Color(0xFFFF8A5C), // coral
  Color(0xFFF2B84B), // honey
  Color(0xFF2BB3A3), // lagoon teal
  Color(0xFFFF7BA9), // bubblegum pink
  Color(0xFFB565D8), // plum
  Color(0xFF4FA8DE), // warm sky
  Color(0xFF7CB342), // leaf green
  Color(0xFFD96C47), // clay
  Color(0xFFFF9E80), // peach
  Color(0xFFFFD54F), // butter
  Color(0xFF4DB6AC), // aqua
  Color(0xFFF48FB1), // rose
  Color(0xFFCE93D8), // lilac
  Color(0xFF90CAF9), // periwinkle
  Color(0xFFAED581), // lime leaf
];

Color _lobbyAccent(String id) {
  var h = 0;
  for (final c in id.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return _gameAccents[h % _gameAccents.length];
}

class GamesLobbyPage extends ConsumerWidget {
  const GamesLobbyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(appStoreProvider);
    final minor = store.actorIsMinor;
    return FcScaffold(
      title: 'Family games',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFFF8A5C).withValues(alpha: 0.22),
                  FamilyCircleColors.primary.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: const Color(0xFFFF8A5C).withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF8A5C).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFFF8A5C).withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Icon(
                    Icons.sports_esports_outlined,
                    color: Color(0xFFFF8A5C),
                    size: 30,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Games use only allergy-checked food. Rewards are fun badges — nothing is ever for sale${minor ? '' : ', and quotas renew on their own'}.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < catalog.gameDefinitions.length; i++)
            _gameTile(context, store, catalog.gameDefinitions[i], minor, i),
        ],
      ),
    );
  }

  Widget _gameTile(
    BuildContext context,
    AppStore store,
    GameDefinition def,
    bool minor,
    int index,
  ) {
    final remaining = store.gamePlaysRemaining(def.id);
    final exhausted = remaining <= 0;
    final windowLabel = def.window.inDays >= 30 ? 'month' : 'week';
    final tooYoung =
        minor &&
        store.actor != null &&
        _ageIndex(store.actor!.ageBand) < _ageIndex(def.minAge);
    final locked = exhausted || tooYoung;
    final accent = _lobbyAccent(def.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: locked
                ? Theme.of(context).colorScheme.outlineVariant
                      .withValues(alpha: 0.4)
                : accent.withValues(alpha: 0.4),
            width: locked ? 1 : 1.5,
          ),
        ),
        child: InkWell(
          onTap: locked
              ? null
              : () => context.push('${AppRoute.games.path}/${def.id}'),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: locked
                    ? [
                        Theme.of(context).colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.25),
                        Colors.transparent,
                      ]
                    : [
                        accent.withValues(alpha: 0.14),
                        accent.withValues(alpha: 0.03),
                      ],
              ),
            ),
            child: Opacity(
              opacity: locked ? 0.7 : 1,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: accent.withValues(
                              alpha: locked ? 0.08 : 0.2,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: accent.withValues(
                                alpha: locked ? 0.2 : 0.5,
                              ),
                              width: 1.5,
                            ),
                            boxShadow: locked
                                ? null
                                : [
                                    BoxShadow(
                                      color: accent.withValues(alpha: 0.25),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                          ),
                          child: Icon(
                            gameIcon(def.icon),
                            size: 32,
                            color: locked
                                ? Theme.of(context).colorScheme.onSurfaceVariant
                                : accent,
                          ),
                        ),
                        if (tooYoung)
                          Positioned(
                            right: -4,
                            bottom: -4,
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: FamilyCircleColors.surfaceHighest,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                              child: Icon(
                                Icons.lock_outline,
                                size: 15,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  def.title,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              if (tooYoung)
                                Icon(
                                  Icons.lock_outline,
                                  size: 16,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            def.summary,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          if (tooYoung)
                            FcChip(
                              'For older kids',
                              icon: Icons.lock_outline,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            )
                          else if (exhausted)
                            FcChip(
                              minor
                                  ? 'Available again later'
                                  : 'Used up this $windowLabel',
                              icon: Icons.schedule_outlined,
                              color: FamilyCircleColors.warning,
                            )
                          else
                            FcChip(
                              minor
                                  ? 'Ready to play'
                                  : '$remaining left this $windowLabel',
                              icon: Icons.play_circle_outline,
                              color: accent,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      locked ? Icons.lock_outline : Icons.chevron_right,
                      color: locked
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  int _ageIndex(AgeBand b) => AgeBand.values.indexOf(b);
}
