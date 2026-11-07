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

/// Vivid per-game accent colors for the lobby. Rendered as tints so both
/// light and dark themes stay readable.
const _gameAccents = [
  Color(0xFF7C6CF0),
  Color(0xFFFF8A5C),
  Color(0xFF42B6E8),
  Color(0xFFFFC94D),
  Color(0xFF9B7EDE),
  Color(0xFF3ECF8E),
  Color(0xFFFF7BA9),
  Color(0xFF5AA9E6),
  Color(0xFF66BB6A),
  Color(0xFFAB47BC),
  Color(0xFF26C6DA),
  Color(0xFFEF5350),
  Color(0xFF8D6E63),
  Color(0xFF78909C),
  Color(0xFFEC407A),
  Color(0xFF7E57C2),
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
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: FamilyCircleColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: FamilyCircleColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: FamilyCircleColors.primary.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.sports_esports_outlined,
                    color: FamilyCircleColors.primary,
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: locked
                ? Theme.of(context).colorScheme.outlineVariant
                      .withValues(alpha: 0.4)
                : accent.withValues(alpha: 0.35),
          ),
        ),
        child: InkWell(
          onTap: locked
              ? null
              : () => context.push('${AppRoute.games.path}/${def.id}'),
          child: Opacity(
            opacity: locked ? 0.65 : 1,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: locked ? 0.08 : 0.16),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: accent.withValues(alpha: locked ? 0.2 : 0.45),
                      ),
                    ),
                    child: Icon(
                      gameIcon(def.icon),
                      size: 28,
                      color: locked ? FamilyCircleColors.muted : accent,
                    ),
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
                              const Icon(
                                Icons.lock_outline,
                                size: 16,
                                color: FamilyCircleColors.muted,
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
                          const FcChip(
                            'For older kids',
                            icon: Icons.lock_outline,
                            color: FamilyCircleColors.muted,
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
                        ? FamilyCircleColors.muted
                        : Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  int _ageIndex(AgeBand b) => AgeBand.values.indexOf(b);
}
