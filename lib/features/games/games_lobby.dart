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

class GamesLobbyPage extends ConsumerWidget {
  const GamesLobbyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(appStoreProvider);
    final minor = store.actorIsMinor;
    return FcScaffold(
      title: 'Family games',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Games use only allergy-checked food. Rewards are fun badges — nothing is ever for sale${minor ? '' : ', and quotas renew on their own'}.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          for (final def in catalog.gameDefinitions)
            _gameTile(context, store, def, minor),
        ],
      ),
    );
  }

  Widget _gameTile(
    BuildContext context,
    AppStore store,
    GameDefinition def,
    bool minor,
  ) {
    final remaining = store.gamePlaysRemaining(def.id);
    final exhausted = remaining <= 0;
    final windowLabel = def.window.inDays >= 30 ? 'month' : 'week';
    final tooYoung =
        minor &&
        store.actor != null &&
        _ageIndex(store.actor!.ageBand) < _ageIndex(def.minAge);
    return FcCard(
      onTap: (exhausted || tooYoung)
          ? null
          : () => context.push('${AppRoute.games.path}/${def.id}'),
      child: Row(
        children: [
          Icon(
            gameIcon(def.icon),
            size: 36,
            color: exhausted || tooYoung
                ? FamilyCircleColors.muted
                : Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(def.title, style: Theme.of(context).textTheme.titleSmall),
                Text(def.summary, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
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
                  ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }

  int _ageIndex(AgeBand b) => AgeBand.values.indexOf(b);
}
