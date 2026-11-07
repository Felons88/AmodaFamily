/// All 16 game implementations. Each follows the contract in docs/games/:
/// safe candidates only, deterministic results, one award per session,
/// neutral absence, no commerce or stranger surfaces for minors.
library;

import 'dart:math';

import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../shared/catalog.dart' as catalog;
import '../../shared/errors.dart';
import '../../shared/models.dart';
import '../../shared/widgets.dart';

/// Warm, vivid per-game accent colors (terracotta / coral / honey family)
/// that harmonize with the cream-and-terracotta app theme. Always used as
/// tints behind themed text/icons so light and dark themes stay readable.
const _gamePalette = [
  Color(0xFFE8863F), // terracotta
  Color(0xFFFF8A5C), // coral
  Color(0xFFF2B84B), // honey
  Color(0xFF2BB3A3), // lagoon teal
  Color(0xFFFF7BA9), // bubblegum pink
  Color(0xFFB565D8), // plum
  Color(0xFF4FA8DE), // warm sky
  Color(0xFF7CB342), // leaf green
];

Color _gameAccent(String seed) {
  var h = 0;
  for (final c in seed.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return _gamePalette[h % _gamePalette.length];
}

/// Rounded-square medallion used in game lobby and results screens.
class _GameMedallion extends StatelessWidget {
  const _GameMedallion({
    required this.icon,
    required this.accent,
    this.size = 72,
  });

  final IconData icon;
  final Color accent;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(size * 0.32),
        border: Border.all(color: accent.withValues(alpha: 0.55), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(icon, color: accent, size: size * 0.5),
    );
  }
}

/// Playful confetti-ish strip of colored dots shown on the results screen.
/// Dots gently pop and bob on a staggered loop for a celebratory feel.
class _ConfettiDots extends StatefulWidget {
  const _ConfettiDots();

  @override
  State<_ConfettiDots> createState() => _ConfettiDotsState();
}

class _ConfettiDotsState extends State<_ConfettiDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _gamePalette.length; i++) ...[
              _dot(i),
              if (i < _gamePalette.length - 1) const SizedBox(width: 7),
            ],
          ],
        );
      },
    );
  }

  Widget _dot(int i) {
    final phase = (_c.value + i / _gamePalette.length) % 1.0;
    final s = 0.75 + 0.3 * (0.5 + 0.5 * sin(phase * 2 * pi));
    return Transform.scale(
      scale: s,
      child: Container(
        width: 11,
        height: 11,
        decoration: BoxDecoration(
          color: _gamePalette[i],
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class GamePage extends ConsumerWidget {
  const GamePage({super.key, required this.gameId});

  final String gameId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final def = catalog.gameDefinitions
        .where((g) => g.id == gameId)
        .firstOrNull;
    if (def == null) {
      return const FcScaffold(
        title: 'Game',
        child: EmptyState(
          title: 'Unknown game',
          message: 'This game is not available.',
        ),
      );
    }
    return switch (gameId) {
      'dinner-showdown' => _ShowdownGame(def: def),
      'pantry-bingo' => _BingoGame(def: def),
      'recipe-roulette' => _RouletteGame(def: def),
      'price-guess' => _PriceGuessGame(def: def),
      'fridge-rescue' => _FridgeRescueGame(def: def),
      'build-a-meal' => _BuildMealGame(def: def),
      'mystery-recipe' => _MysteryGame(def: def),
      'world-food' => _WorldFoodGame(def: def),
      'family-restaurant' => _RestaurantGame(def: def),
      'budget-hero' => _BudgetHeroGame(def: def),
      'food-trivia' => _TriviaGame(def: def),
      'junior-chef' => _JuniorChefGame(def: def),
      'cooking-together' => _CookingTogetherGame(def: def),
      'grocery-detective' => _GroceryDetectiveGame(def: def),
      'leftover-legends' => _LeftoverGame(def: def),
      'family-food-quest' => _QuestGame(def: def),
      _ => FcScaffold(
        title: def.title,
        child: const EmptyState(
          title: 'Coming soon',
          message: 'This game is still being built.',
        ),
      ),
    };
  }
}

// ---------- shared game frame ----------

/// Handles session start/finish, quota errors and the award screen.
abstract class _GameState<T extends ConsumerStatefulWidget>
    extends ConsumerState<T> {
  GameSession? _session;
  Badge? _badge;
  String? _startError;

  GameDefinition get def;

  void begin() {
    try {
      setState(() {
        _session = ref.read(appStoreProvider).startGame(def.id);
        _startError = null;
      });
    } on FcException catch (e) {
      setState(() => _startError = e.safeMessage);
    }
  }

  void finish({
    int score = 50,
    String title = 'Player',
    String description = 'Played a family game.',
  }) {
    final s = _session;
    if (s == null) return;
    setState(
      () => _badge = ref
          .read(appStoreProvider)
          .finishGame(
            s,
            score: score,
            rewardTitle: title,
            rewardDescription: description,
          ),
    );
  }

  Widget lobby(String instructions) {
    final accent = _gameAccent(def.id);
    return FcScaffold(
      title: def.title,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 16),
          Center(
            child: _GameMedallion(
              icon: gameIcon(def.icon),
              accent: accent,
              size: 96,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            def.title,
            style: Theme.of(context).textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.w900),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Ready? Let\'s play!',
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700, color: accent),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accent.withValues(alpha: 0.3)),
            ),
            child: Text(
              instructions,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          if (_startError != null) ...[
            const SizedBox(height: 16),
            Text(
              _startError!,
              style: const TextStyle(color: FamilyCircleColors.warning),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 28),
          FilledButton.icon(
            icon: const Icon(Icons.play_arrow, size: 28),
            label: const Text('Play'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(60),
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            ),
            onPressed: begin,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  Widget results(String summary) {
    final badge = _badge!;
    final accent = _gameAccent(def.id);
    return FcScaffold(
      title: 'Great job!',
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _ConfettiDots(),
              const SizedBox(height: 24),
              _GameMedallion(
                icon: gameIcon(def.icon),
                accent: accent,
                size: 96,
              ),
              const SizedBox(height: 20),
              Text(
                badge.title,
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w900),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(summary, textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Text(
                'Great try — keep up the awesome work!',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.w600, color: accent),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FcChip(
                'Badge earned',
                icon: Icons.military_tech_outlined,
                color: accent,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(58),
                    textStyle: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  onPressed: () => context.pop(),
                  child: const Text('Back to games'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get playing => _session != null && _badge == null;
  bool get finished => _badge != null;
}

// ---------- GAME-001 Dinner Showdown ----------

class _ShowdownGame extends ConsumerStatefulWidget {
  const _ShowdownGame({required this.def});
  final GameDefinition def;
  @override
  ConsumerState<_ShowdownGame> createState() => _ShowdownState();
}

class _ShowdownState extends _GameState<_ShowdownGame> {
  @override
  GameDefinition get def => widget.def;
  List<CatalogRecipe> _bracket = [];
  int _round = 0; // 0,1 semifinals; 2 final
  String? _championId;

  void _pick(CatalogRecipe winner) {
    if (_round == 0) {
      _bracket = [winner, _bracket[2], _bracket[3]];
      setState(() => _round = 1);
    } else if (_round == 1) {
      _bracket = [_bracket[0], winner];
      setState(() => _round = 2);
    } else {
      setState(() => _championId = winner.id);
      finish(
        score: 80,
        title: 'Showdown Host',
        description: 'Ran a dinner showdown bracket.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (finished) {
      final champ = catalog.recipes[_championId];
      return results(
        '${champ?.title ?? 'A meal'} wins the bracket! Ask a grown-up to add it to the plan.',
      );
    }
    if (!playing) {
      final dinners = ref
          .read(appStoreProvider)
          .eligibleRecipes(meal: MealType.dinner);
      if (dinners.length < 4) {
        return const FcScaffold(
          title: 'Dinner Showdown',
          child: EmptyState(
            title: 'Not enough safe dinners',
            message: 'We need four allergy-checked dinners to run a bracket.',
          ),
        );
      }
      _bracket = dinners.take(4).toList();
      return lobby(
        'Four safe dinners enter. Pick the winner of each head-to-head — last meal standing wins.',
      );
    }
    final (a, b) = _round == 2
        ? (_bracket[0], _bracket[1])
        : (_bracket[_round * 2], _bracket[_round * 2 + 1]);
    final accent = _gameAccent(def.id);
    return FcScaffold(
      title: 'Dinner Showdown',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: accent.withValues(alpha: 0.45)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sports_mma_outlined, size: 18, color: accent),
                  const SizedBox(width: 8),
                  Text(
                    _round == 2 ? 'Final!' : 'Round ${_round + 1} of 3',
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800, color: accent),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          for (final r in [a, b])
            FcCard(
              onTap: () => _pick(r),
              child: Column(
                children: [
                  DishImage(image: r.image, height: 110),
                  const SizedBox(height: 8),
                  Text(r.title, style: Theme.of(context).textTheme.titleMedium),
                  Text(
                    '${r.minutes} min',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ---------- GAME-002 Pantry Bingo ----------

class _BingoGame extends ConsumerStatefulWidget {
  const _BingoGame({required this.def});
  final GameDefinition def;
  @override
  ConsumerState<_BingoGame> createState() => _BingoState();
}

class _BingoState extends _GameState<_BingoGame> {
  @override
  GameDefinition get def => widget.def;
  List<String> _squares = [];
  final Set<int> _marked = {};

  bool get _won {
    const lines = [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8],
      [0, 4, 8],
      [2, 4, 6],
    ];
    return lines.any((l) => l.every(_marked.contains));
  }

  @override
  Widget build(BuildContext context) {
    if (finished) return results('Bingo! You made a line on the pantry board.');
    if (!playing) {
      final pantry = ref.read(appStoreProvider).pantry;
      _squares = [
        for (final p in pantry.take(5))
          'Have ${catalog.ingredients[p.ingredientId]?.name ?? p.ingredientId}',
        'Help check the grocery list',
        'Find something expiring soon',
        'Wash hands before a meal',
        'Name one veggie in the fridge',
      ];
      while (_squares.length < 9) {
        _squares.add('Free square ${_squares.length - 4}');
      }
      _squares = _squares.take(9).toList();
      return lobby(
        'Mark squares you can honestly check off. Any row, column or diagonal wins.',
      );
    }
    final accent = _gameAccent(def.id);
    return FcScaffold(
      title: 'Pantry Bingo',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: LinearProgressIndicator(
                      value: _marked.length / 9,
                      minHeight: 10,
                      backgroundColor: accent.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation(accent),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FcChip(
                  '${_marked.length} marked',
                  icon: Icons.grid_on,
                  color: accent,
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.9,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: 9,
              itemBuilder: (context, i) {
                final marked = _marked.contains(i);
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    setState(() => marked ? _marked.remove(i) : _marked.add(i));
                    if (_won) {
                      finish(
                        score: 90,
                        title: 'Bingo Champ',
                        description: 'Completed a pantry bingo line.',
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: marked
                          ? FamilyCircleColors.primary.withValues(alpha: 0.2)
                          : FamilyCircleColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: marked
                            ? FamilyCircleColors.primary
                            : Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (marked)
                          const Icon(
                            Icons.check,
                            color: FamilyCircleColors.primary,
                          ),
                        Text(
                          _squares[i],
                          style: Theme.of(context).textTheme.labelSmall,
                          textAlign: TextAlign.center,
                          maxLines: 4,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- GAME-003 Recipe Roulette ----------

class _RouletteGame extends ConsumerStatefulWidget {
  const _RouletteGame({required this.def});
  final GameDefinition def;
  @override
  ConsumerState<_RouletteGame> createState() => _RouletteState();
}

class _RouletteState extends _GameState<_RouletteGame> {
  @override
  GameDefinition get def => widget.def;
  CatalogRecipe? _picked;
  bool _spinning = false;
  late List<CatalogRecipe> _pool;

  void _spin() async {
    setState(() {
      _spinning = true;
      _picked = null;
    });
    await Future<void>.delayed(const Duration(milliseconds: 900));
    setState(() {
      _spinning = false;
      _picked = _pool[Random().nextInt(_pool.length)];
    });
  }

  @override
  Widget build(BuildContext context) {
    if (finished) {
      return results(
        'Tonight\'s pick: ${_picked?.title}. A grown-up can add it to the plan.',
      );
    }
    if (!playing) {
      _pool = ref.read(appStoreProvider).eligibleRecipes(meal: MealType.dinner);
      if (_pool.isEmpty) {
        return const FcScaffold(
          title: 'Recipe Roulette',
          child: EmptyState(
            title: 'No safe dinners',
            message: 'Every dinner is filtered out by household allergies. A grown-up can review food needs.',
          ),
        );
      }
      return lobby(
        'Spin for a surprise dinner from only allergy-checked recipes. What you land on is a random pick from the safe pool.',
      );
    }
    return FcScaffold(
      title: 'Recipe Roulette',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_picked != null) ...[
                DishImage(image: _picked!.image, height: 160),
                const SizedBox(height: 16),
                Text(
                  _picked!.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Spin again'),
                      onPressed: _spin,
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: () => finish(
                        score: 70,
                        title: 'Roulette Spinner',
                        description: 'Let fate pick dinner.',
                      ),
                      child: const Text('Take it!'),
                    ),
                  ],
                ),
              ] else ...[
                Icon(
                  Icons.shuffle,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  icon: const Icon(Icons.casino_outlined, size: 24),
                  label: Text(
                    _spinning ? 'Spinning…' : 'Spin',
                    style: const TextStyle(fontSize: 17),
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: _spinning ? null : _spin,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------- GAME-004 Price Guess ----------

class _PriceGuessGame extends ConsumerStatefulWidget {
  const _PriceGuessGame({required this.def});
  final GameDefinition def;
  @override
  ConsumerState<_PriceGuessGame> createState() => _PriceGuessState();
}

class _PriceGuessState extends _GameState<_PriceGuessGame> {
  @override
  GameDefinition get def => widget.def;
  final _guess = TextEditingController();
  List<PriceOffer> _basket = [];
  int? _actualCents;

  @override
  Widget build(BuildContext context) {
    if (finished) {
      return results(
        'You guessed ${fmtCents(int.tryParse(_guess.text.trim()) ?? 0)} — the sample total was ${fmtCents(_actualCents!)}.',
      );
    }
    if (!playing) {
      _basket = catalog.priceOffers
          .where(
            (o) => [
              'banana',
              'milk_whole',
              'bread_whole',
              'egg',
            ].contains(o.ingredientId),
          )
          .toList();
      return lobby(
        'A small shopping basket is shown with sample prices. Guess the total, then compare — no wrong answers, just practice.',
      );
    }
    final isMinor = ref.watch(appStoreProvider).actorIsMinor;
    _actualCents = _basket.fold<int>(0, (s, o) => s + o.estimatedCents);
    return FcScaffold(
      title: 'Guess the Price',
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Sample basket (educational prices, US-DEMO, Oct 2026):',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          for (final o in _basket)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: const Icon(Icons.grass_outlined, size: 18),
              title: Text(
                catalog.ingredients[o.ingredientId]?.name ?? o.ingredientId,
              ),
              subtitle: Text(fmtQty(o.packSize)),
              // Kids see items only — amounts stay on adult surfaces per contract.
              trailing: isMinor ? null : Text(fmtCents(o.estimatedCents)),
            ),
          const SizedBox(height: 16),
          TextField(
            controller: _guess,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: isMinor ? 'Your guess in tokens' : 'Your guess',
              prefixText: isMinor ? 'T ' : r'$',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              final guess = int.tryParse(_guess.text.trim());
              if (guess == null) return;
              final cents = isMinor ? guess : (guess * 100);
              final diff = (cents - _actualCents!).abs();
              final score = (100 - (diff / _actualCents! * 100).round()).clamp(
                0,
                100,
              );
              finish(
                score: score,
                title: 'Price Guesser',
                description: 'Estimated a sample basket.',
              );
            },
            child: const Text('Reveal'),
          ),
        ],
      ),
    );
  }
}

// ---------- GAME-005 Fridge Rescue ----------

class _FridgeRescueGame extends ConsumerStatefulWidget {
  const _FridgeRescueGame({required this.def});
  final GameDefinition def;
  @override
  ConsumerState<_FridgeRescueGame> createState() => _FridgeRescueState();
}

class _FridgeRescueState extends _GameState<_FridgeRescueGame> {
  @override
  GameDefinition get def => widget.def;
  final Set<String> _picked = {};
  List<CatalogRecipe> _matches = [];
  CatalogRecipe? _rescued;

  void _find(AppStore store) {
    final eligible = store.eligibleRecipes();
    setState(() {
      _matches = eligible
          .where(
            (r) =>
                r.needs.where((n) => _picked.contains(n.ingredientId)).length >=
                2,
          )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (finished) {
      return results(
        'Rescued! ${_rescued?.title} uses your pantry picks. A grown-up confirms the real meal.',
      );
    }
    final store = ref.watch(appStoreProvider);
    final pantry = store.pantry;
    if (!playing) {
      if (pantry.length < 2) {
        return const FcScaffold(
          title: 'Fridge Rescue',
          child: EmptyState(
            title: 'Pantry too empty',
            message:
                'Add some pantry items first so there is something to rescue.',
          ),
        );
      }
      return lobby(
        'Pick 2-5 things from your pantry, then find safe meals that use them.',
      );
    }
    return FcScaffold(
      title: 'Fridge Rescue',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Pick your rescue items:',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              FcChip(
                '${_picked.length}/5 picked',
                icon: Icons.kitchen_outlined,
                color: _gameAccent(def.id),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in pantry)
                FilterChip(
                  label: Text(
                    catalog.ingredients[p.ingredientId]?.name ?? p.ingredientId,
                  ),
                  selected: _picked.contains(p.ingredientId),
                  onSelected: (sel) => setState(() {
                    if (sel && _picked.length < 5) {
                      _picked.add(p.ingredientId);
                    } else if (!sel) {
                      _picked.remove(p.ingredientId);
                    }
                  }),
                ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: _picked.length >= 2 ? () => _find(store) : null,
            child: const Text('Find safe meals'),
          ),
          if (_matches.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Matches:', style: Theme.of(context).textTheme.titleSmall),
            for (final r in _matches)
              ListTile(
                title: Text(r.title),
                subtitle: Text('${r.meal.label} • ${r.minutes} min'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _rescued = r;
                  finish(
                    score: 85,
                    title: 'Fridge Rescuer',
                    description: 'Saved pantry items from going to waste.',
                  );
                },
              ),
          ] else if (_picked.length >= 2)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text(
                'No safe recipe uses those yet — try a different mix.',
                style: TextStyle(color: FamilyCircleColors.warning),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------- GAME-006 Build a Meal ----------

class _BuildMealGame extends ConsumerStatefulWidget {
  const _BuildMealGame({required this.def});
  final GameDefinition def;
  @override
  ConsumerState<_BuildMealGame> createState() => _BuildMealState();
}

class _BuildMealState extends _GameState<_BuildMealGame> {
  @override
  GameDefinition get def => widget.def;
  String? _protein;
  String? _grain;
  String? _veg;
  String? _verdict;

  static const _proteins = [
    'chicken_breast',
    'ground_beef',
    'black_beans',
    'lentils',
    'egg',
    'salmon',
  ];
  static const _grains = [
    'rice_white',
    'pasta',
    'tortilla',
    'bread_whole',
    'potato',
  ];
  static const _vegs = [
    'frozen_veg',
    'carrot',
    'lettuce',
    'bell_pepper',
    'cucumber',
  ];

  void _check(AppStore store) {
    final ids = [_protein, _grain, _veg].whereType<String>().toList();
    final eaters = store.circle!.activeMembers
        .map((m) => EaterRestrictions(hardAllergens: m.hardAllergens))
        .toList();
    final facts = {
      for (final e in catalog.ingredients.entries) e.key: e.value.fact,
    };
    // Each component must be individually verified safe for all eaters.
    for (final id in ids) {
      final fact = facts[id];
      if (fact == null || !fact.compositionVerified) {
        setState(
          () => _verdict =
              'We cannot verify ${catalog.ingredients[id]?.name ?? id} — pick something else.',
        );
        return;
      }
      for (final e in eaters) {
        final allergens = e.hardAllergens.map((a) => a.toLowerCase()).toSet();
        if (fact.allergens
            .map((a) => a.toLowerCase())
            .toSet()
            .intersection(allergens)
            .isNotEmpty) {
          setState(
            () => _verdict =
                '${catalog.ingredients[id]?.name} is not safe for someone in your house. Swap it out.',
          );
          return;
        }
      }
    }
    setState(() => _verdict = 'safe');
    finish(
      score: 75,
      title: 'Meal Builder',
      description: 'Built a safe balanced plate.',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (finished) {
      return results(
        'Your plate: ${catalog.ingredients[_protein]?.name}, ${catalog.ingredients[_grain]?.name} and ${catalog.ingredients[_veg]?.name}. A grown-up can turn it into a real meal.',
      );
    }
    if (!playing) {
      return lobby(
        'Build a plate: one protein, one grain, one veggie. The checker only approves combos safe for your household.',
      );
    }
    final store = ref.watch(appStoreProvider);
    Widget picker(
      String label,
      List<String> options,
      String? value,
      void Function(String?) onChanged,
    ) {
      final safe = options.where((id) {
        final fact = catalog.ingredients[id];
        if (fact == null) return false;
        final eaters = store.circle!.activeMembers.map(
          (m) => m.hardAllergens.map((a) => a.toLowerCase()).toSet(),
        );
        return eaters.every(
          (a) => fact.allergens
              .map((x) => x.toLowerCase())
              .toSet()
              .intersection(a)
              .isEmpty,
        );
      }).toList();
      return DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(labelText: label),
        items: [
          for (final id in safe)
            DropdownMenuItem(
              value: id,
              child: Text(catalog.ingredients[id]!.name),
            ),
        ],
        onChanged: onChanged,
      );
    }

    return FcScaffold(
      title: 'Build a Meal',
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          picker(
            'Protein',
            _proteins,
            _protein,
            (v) => setState(() => _protein = v),
          ),
          const SizedBox(height: 12),
          picker(
            'Grain / starch',
            _grains,
            _grain,
            (v) => setState(() => _grain = v),
          ),
          const SizedBox(height: 12),
          picker('Veggie', _vegs, _veg, (v) => setState(() => _veg = v)),
          const SizedBox(height: 20),
          if (_verdict != null && _verdict != 'safe')
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _verdict!,
                style: const TextStyle(color: FamilyCircleColors.warning),
              ),
            ),
          FilledButton(
            onPressed: (_protein != null && _grain != null && _veg != null)
                ? () => _check(store)
                : null,
            child: const Text('Check my plate'),
          ),
        ],
      ),
    );
  }
}

// ---------- GAME-007 Mystery Recipe ----------

class _MysteryGame extends ConsumerStatefulWidget {
  const _MysteryGame({required this.def});
  final GameDefinition def;
  @override
  ConsumerState<_MysteryGame> createState() => _MysteryState();
}

class _MysteryState extends _GameState<_MysteryGame> {
  @override
  GameDefinition get def => widget.def;
  int _clueIndex = 0;
  int _wrongGuesses = 0;
  late catalog.MysteryClue _mystery;
  late List<CatalogRecipe> _choices;

  @override
  Widget build(BuildContext context) {
    if (finished) {
      return results(
        'You solved it: ${catalog.recipes[_mystery.recipeId]?.title} in ${_clueIndex + 1} clue(s)!',
      );
    }
    if (!playing) {
      final eligible = ref
          .read(appStoreProvider)
          .eligibleRecipes()
          .map((r) => r.id)
          .toSet();
      final candidates = catalog.mysteryRecipes
          .where((m) => eligible.contains(m.recipeId))
          .toList();
      if (candidates.isEmpty) {
        return const FcScaffold(
          title: 'Mystery Recipe',
          child: EmptyState(
            title: 'No safe mystery',
            message: 'All mystery answers are filtered by household allergies.',
          ),
        );
      }
      _mystery = candidates[Random().nextInt(candidates.length)];
      final others =
          catalog.recipes.values
              .where(
                (r) => r.id != _mystery.recipeId && eligible.contains(r.id),
              )
              .toList()
            ..shuffle();
      _choices = [catalog.recipes[_mystery.recipeId]!, ...others.take(3)]
        ..shuffle();
      return lobby(
        'Guess the dish! Reveal clues one at a time — fewer clues means a better guess.',
      );
    }
    final accent = _gameAccent(def.id);
    return FcScaffold(
      title: 'Mystery Recipe',
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          for (var i = 0; i <= _clueIndex && i < _mystery.clues.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FcCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline, size: 20, color: accent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('Clue ${i + 1}: ${_mystery.clues[i]}'),
                    ),
                  ],
                ),
              ),
            ),
          if (_clueIndex < _mystery.clues.length - 1)
            TextButton.icon(
              icon: const Icon(Icons.lightbulb_outline),
              label: const Text('Next clue'),
              onPressed: () => setState(() => _clueIndex++),
            ),
          const SizedBox(height: 16),
          for (final r in _choices)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  alignment: Alignment.centerLeft,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  if (r.id == _mystery.recipeId) {
                    finish(
                      score: (100 - _wrongGuesses * 15 - _clueIndex * 5).clamp(
                        10,
                        100,
                      ),
                      title: 'Clue Solver',
                      description: 'Guessed the mystery recipe.',
                    );
                  } else {
                    setState(() => _wrongGuesses++);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Not it — try another clue.'),
                      ),
                    );
                  }
                },
                child: Text(r.title),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------- GAME-008 World Food ----------

class _WorldFoodGame extends ConsumerStatefulWidget {
  const _WorldFoodGame({required this.def});
  final GameDefinition def;
  @override
  ConsumerState<_WorldFoodGame> createState() => _WorldFoodState();
}

class _WorldFoodState extends _GameState<_WorldFoodGame> {
  @override
  GameDefinition get def => widget.def;
  catalog.CuisineInfo? _stop;

  @override
  Widget build(BuildContext context) {
    if (finished) {
      return results(
        'Passport stamped for ${_stop?.name}! You learned: ${_stop?.fact}',
      );
    }
    if (!playing) {
      return lobby(
        'Pick a cuisine stop, learn a fact, and earn a passport stamp. No one has to eat anything.',
      );
    }
    return FcScaffold(
      title: 'World Food',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final stop in catalog.passportStops)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FcCard(
                onTap: () {
                  _stop = stop;
                  finish(
                    score: 60,
                    title: '${stop.name} Explorer',
                    description: 'Visited ${stop.name} in the food passport.',
                  );
                  ref
                      .read(appStoreProvider)
                      .completeQuestObjective('q-passport');
                },
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _gameAccent(stop.name).withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _gameAccent(stop.name).withValues(alpha: 0.45),
                        ),
                      ),
                      child: Icon(Icons.public, color: _gameAccent(stop.name)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stop.name,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Text(
                            stop.fact,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------- GAME-009 Family Restaurant ----------

class _RestaurantGame extends ConsumerStatefulWidget {
  const _RestaurantGame({required this.def});
  final GameDefinition def;
  @override
  ConsumerState<_RestaurantGame> createState() => _RestaurantState();
}

class _RestaurantState extends _GameState<_RestaurantGame> {
  @override
  GameDefinition get def => widget.def;
  final _menuName = TextEditingController(text: 'Our Family Café');
  final Set<String> _menu = {};

  @override
  Widget build(BuildContext context) {
    if (finished) {
      return results(
        '"${_menuName.text}" menu drafted with ${_menu.length} dishes. A grown-up can open a family vote from it.',
      );
    }
    if (!playing) {
      return lobby(
        'Draft a restaurant menu from safe recipes. Pick 3 dishes, name your place, and share it with the family vote.',
      );
    }
    final store = ref.watch(appStoreProvider);
    final options = store.eligibleRecipes();
    return FcScaffold(
      title: 'Family Restaurant',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _menuName,
            decoration: const InputDecoration(labelText: 'Restaurant name'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Pick 3 dishes (${_menu.length}/3):',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: _menu.length / 3,
              minHeight: 8,
              backgroundColor: _gameAccent(def.id).withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(_gameAccent(def.id)),
            ),
          ),
          const SizedBox(height: 8),
          for (final r in options)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _menu.contains(r.id),
              onChanged: (sel) => setState(() {
                if (sel == true && _menu.length < 3) {
                  _menu.add(r.id);
                } else if (sel == false) {
                  _menu.remove(r.id);
                }
              }),
              title: Text(r.title),
              subtitle: Text(r.meal.label),
            ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _menu.length == 3
                ? () {
                    try {
                      store.openVoteRound(
                        '${_menuName.text} menu',
                        _menu.toList(),
                      );
                    } on FcException {
                      // Vote quota may be exhausted; the draft still counts.
                    }
                    finish(
                      score: 70,
                      title: 'Menu Designer',
                      description: 'Drafted a family restaurant menu.',
                    );
                  }
                : null,
            child: const Text('Share menu as a vote'),
          ),
        ],
      ),
    );
  }
}

// ---------- GAME-010 Budget Hero ----------

class _BudgetHeroGame extends ConsumerStatefulWidget {
  const _BudgetHeroGame({required this.def});
  final GameDefinition def;
  @override
  ConsumerState<_BudgetHeroGame> createState() => _BudgetHeroState();
}

class _BudgetHeroState extends _GameState<_BudgetHeroGame> {
  @override
  GameDefinition get def => widget.def;
  double _target = 15;
  final Set<String> _picked = {};
  String? _verdict;

  int _costOf(Set<String> recipeIds) {
    var cents = 0;
    for (final id in recipeIds) {
      final r = catalog.recipes[id]!;
      for (final n in r.needs) {
        final offer = catalog.priceOffers
            .where((o) => o.ingredientId == n.ingredientId)
            .firstOrNull;
        if (offer != null) {
          cents +=
              ((n.amount / offer.packSize.amount).ceil() * offer.estimatedCents)
                  .clamp(0, offer.estimatedCents);
        }
      }
    }
    return cents;
  }

  @override
  Widget build(BuildContext context) {
    if (finished) {
      return results(
        _verdict ?? 'You planned within budget — that is the hero move.',
      );
    }
    if (!playing) {
      return lobby(
        'Set a pretend spending target, then pick meals whose sample prices fit under it. It is planning practice, not real money.',
      );
    }
    final store = ref.watch(appStoreProvider);
    final dinners = store.eligibleRecipes(meal: MealType.dinner);
    final minor = store.actorIsMinor;
    final targetCents = (_target * 100).round();
    final cost = _costOf(_picked);
    return FcScaffold(
      title: 'Budget Hero',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Pretend ${minor ? 'token ' : ''}budget: ${minor ? '${_target.round()} tokens' : fmtCents(targetCents)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Slider(
            value: _target,
            min: 5,
            max: 40,
            divisions: 35,
            label: '${_target.round()}',
            onChanged: (v) => setState(() => _target = v),
          ),
          const SizedBox(height: 8),
          for (final r in dinners)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _picked.contains(r.id),
              onChanged: (sel) => setState(
                () => sel == true ? _picked.add(r.id) : _picked.remove(r.id),
              ),
              title: Text(r.title),
              subtitle: Text(r.meal.label),
            ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: targetCents == 0 ? 0 : (cost / targetCents).clamp(0, 1),
              minHeight: 10,
              backgroundColor: _gameAccent(def.id).withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(
                cost <= targetCents
                    ? FamilyCircleColors.primary
                    : FamilyCircleColors.error,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            minor
                ? 'Sample cost: ${_picked.isEmpty ? 0 : (cost / 100).toStringAsFixed(0)} tokens'
                : 'Sample cost: ${fmtCents(cost)}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _picked.isEmpty
                ? null
                : () {
                    final feasible = cost <= targetCents;
                    _verdict = feasible
                        ? 'Fits! ${_picked.length} meal(s) inside the target — using labeled sample prices.'
                        : 'Over the target with sample prices. Try fewer or simpler picks — no shame in the math.';
                    finish(
                      score: feasible ? 90 : 40,
                      title: 'Budget Hero',
                      description: 'Practiced planning to a spending target.',
                    );
                  },
            child: const Text('Check my plan'),
          ),
        ],
      ),
    );
  }
}

// ---------- Food Trivia ----------

class _TriviaGame extends ConsumerStatefulWidget {
  const _TriviaGame({required this.def});
  final GameDefinition def;
  @override
  ConsumerState<_TriviaGame> createState() => _TriviaState();
}

class _TriviaState extends _GameState<_TriviaGame> {
  @override
  GameDefinition get def => widget.def;
  int _index = 0;
  int _correct = 0;
  bool _answered = false;
  int? _picked;

  @override
  Widget build(BuildContext context) {
    if (finished) {
      return results(
        'You got $_correct of ${catalog.triviaQuestions.length} right. Every answer teaches a kitchen fact.',
      );
    }
    if (!playing) {
      return lobby(
        'Short questions about food and kitchen safety. Pick an answer, learn the why.',
      );
    }
    final q = catalog.triviaQuestions[_index];
    final accent = _gameAccent(def.id);
    final progress =
        (_index + (_answered ? 1 : 0)) / catalog.triviaQuestions.length;
    return FcScaffold(
      title: 'Food Trivia',
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: accent.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation(accent),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FcChip(
                '${_index + 1}/${catalog.triviaQuestions.length}',
                icon: Icons.quiz_outlined,
                color: accent,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(q.question, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          for (var i = 0; i < q.choices.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  side: BorderSide(
                    color: !_answered
                        ? Theme.of(context).colorScheme.outline
                        : i == q.answerIndex
                        ? FamilyCircleColors.primary
                        : i == _picked
                        ? FamilyCircleColors.error
                        : Theme.of(context).colorScheme.outline,
                    width: 2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _answered
                    ? null
                    : () => setState(() {
                        _answered = true;
                        _picked = i;
                        if (i == q.answerIndex) _correct++;
                      }),
                child: Text(q.choices[i]),
              ),
            ),
          if (_answered) ...[
            const SizedBox(height: 8),
            Text(q.explanation, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                if (_index + 1 >= catalog.triviaQuestions.length) {
                  finish(
                    score: (_correct / catalog.triviaQuestions.length * 100)
                        .round(),
                    title: 'Trivia Whiz',
                    description: 'Finished the food quiz.',
                  );
                } else {
                  setState(() {
                    _index++;
                    _answered = false;
                    _picked = null;
                  });
                }
              },
              child: Text(
                _index + 1 >= catalog.triviaQuestions.length
                    ? 'Finish'
                    : 'Next',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------- Junior Chef ----------

class _JuniorChefGame extends ConsumerStatefulWidget {
  const _JuniorChefGame({required this.def});
  final GameDefinition def;
  @override
  ConsumerState<_JuniorChefGame> createState() => _JuniorChefState();
}

class _JuniorChefState extends _GameState<_JuniorChefGame> {
  @override
  GameDefinition get def => widget.def;
  int _lesson = 0;
  final Set<int> _stepsDone = {};

  @override
  Widget build(BuildContext context) {
    if (finished) {
      return results(
        'Lesson complete! Every skill here keeps grown-ups in charge of heat and sharp tools.',
      );
    }
    if (!playing) {
      return lobby(
        'Pick a lesson and check off each step with a grown-up nearby for marked steps.',
      );
    }
    final lesson = catalog.chefLessons[_lesson];
    final accent = _gameAccent(def.id);
    return FcScaffold(
      title: 'Junior Chef',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  lesson.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (lesson.needsAdult)
                const FcChip(
                  'With a grown-up',
                  icon: Icons.family_restroom_outlined,
                  color: FamilyCircleColors.warning,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LinearProgressIndicator(
                    value: _stepsDone.length / lesson.steps.length,
                    minHeight: 8,
                    backgroundColor: accent.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation(accent),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FcChip(
                'Lesson ${_lesson + 1}/${catalog.chefLessons.length} • ${_stepsDone.length}/${lesson.steps.length}',
                icon: Icons.restaurant_outlined,
                color: accent,
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < lesson.steps.length; i++)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _stepsDone.contains(i),
              onChanged: (sel) => setState(
                () => sel == true ? _stepsDone.add(i) : _stepsDone.remove(i),
              ),
              title: Text(lesson.steps[i]),
            ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _stepsDone.length == lesson.steps.length
                ? () {
                    ref.read(appStoreProvider).completeChefLesson(_lesson);
                    if (_lesson + 1 >= catalog.chefLessons.length) {
                      ref
                          .read(appStoreProvider)
                          .completeQuestObjective('q-skill');
                      finish(
                        score: 85,
                        title: 'Junior Chef',
                        description: 'Completed all safety lessons.',
                      );
                    } else {
                      setState(() {
                        _lesson++;
                        _stepsDone.clear();
                      });
                    }
                  }
                : null,
            child: Text(
              _lesson + 1 >= catalog.chefLessons.length
                  ? 'Finish lessons'
                  : 'Next lesson',
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Cooking Together ----------

class _CookingTogetherGame extends ConsumerStatefulWidget {
  const _CookingTogetherGame({required this.def});
  final GameDefinition def;
  @override
  ConsumerState<_CookingTogetherGame> createState() => _CookingTogetherState();
}

class _CookingTogetherState extends _GameState<_CookingTogetherGame> {
  @override
  GameDefinition get def => widget.def;
  CatalogRecipe? _recipe;
  final Set<int> _done = {};

  @override
  Widget build(BuildContext context) {
    if (finished) {
      return results(
        'You cooked together! Adults handled the heat and knives.',
      );
    }
    final store = ref.watch(appStoreProvider);
    if (!playing) {
      final recipes = store.eligibleRecipes(meal: MealType.dinner);
      if (recipes.isEmpty) {
        return const FcScaffold(
          title: 'Cooking Together',
          child: EmptyState(
            title: 'No safe recipe',
            message: 'No allergy-checked dinner is available to cook together.',
          ),
        );
      }
      return lobby(
        'Cook a safe recipe as a team. Steps are shared — adults always handle heat and knives.',
      );
    }
    _recipe ??= store.eligibleRecipes(meal: MealType.dinner).first;
    final recipe = _recipe!;
    return FcScaffold(
      title: 'Cooking Together',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(recipe.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Steps marked "grown-up" can only be checked by an adult.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LinearProgressIndicator(
                    value: _done.length / recipe.steps.length,
                    minHeight: 8,
                    backgroundColor: _gameAccent(def.id)
                        .withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation(_gameAccent(def.id)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FcChip(
                '${_done.length}/${recipe.steps.length} steps',
                icon: Icons.soup_kitchen_outlined,
                color: _gameAccent(def.id),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < recipe.steps.length; i++)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _done.contains(i),
              onChanged: (sel) =>
                  setState(() => sel == true ? _done.add(i) : _done.remove(i)),
              title: Text(recipe.steps[i]),
              subtitle: i == recipe.steps.length - 1
                  ? const Text('Grown-up step')
                  : null,
            ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _done.length == recipe.steps.length
                ? () {
                    store.completeQuestObjective('q-skill');
                    finish(
                      score: 80,
                      title: 'Sous Chef',
                      description: 'Cooked a meal together.',
                    );
                  }
                : null,
            child: const Text('We made it!'),
          ),
        ],
      ),
    );
  }
}

// ---------- Grocery Detective ----------

class _GroceryDetectiveGame extends ConsumerStatefulWidget {
  const _GroceryDetectiveGame({required this.def});
  final GameDefinition def;
  @override
  ConsumerState<_GroceryDetectiveGame> createState() =>
      _GroceryDetectiveState();
}

class _GroceryDetectiveState extends _GameState<_GroceryDetectiveGame> {
  @override
  GameDefinition get def => widget.def;
  final Set<int> _done = {};

  static const _tasks = [
    'Find one thing in the pantry with a "use by" date.',
    'Count how many fruits are in the kitchen right now.',
    'Find one food that needs to stay cold.',
    'Spot one packaged food label and find the allergen line (with a grown-up).',
  ];

  @override
  Widget build(BuildContext context) {
    if (finished) {
      return results('Case closed! You checked real items like a pro.');
    }
    if (!playing) {
      return lobby(
        'Detective tasks about your real kitchen. A grown-up confirms anything you change.',
      );
    }
    return FcScaffold(
      title: 'Grocery Detective',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Your cases:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              FcChip(
                '${_done.length}/${_tasks.length} solved',
                icon: Icons.search,
                color: _gameAccent(def.id),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < _tasks.length; i++)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _done.contains(i),
              onChanged: (sel) =>
                  setState(() => sel == true ? _done.add(i) : _done.remove(i)),
              title: Text(_tasks[i]),
            ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _done.length == _tasks.length
                ? () => finish(
                    score: 75,
                    title: 'Detective',
                    description: 'Solved every pantry case.',
                  )
                : null,
            child: const Text('Solve all cases'),
          ),
        ],
      ),
    );
  }
}

// ---------- Leftover Legends ----------

class _LeftoverGame extends ConsumerStatefulWidget {
  const _LeftoverGame({required this.def});
  final GameDefinition def;
  @override
  ConsumerState<_LeftoverGame> createState() => _LeftoverState();
}

class _LeftoverState extends _GameState<_LeftoverGame> {
  @override
  GameDefinition get def => widget.def;
  final Set<int> _safe = {};
  int _score = 0;

  // Days in fridge -> safe-to-reuse guidance (general rule: <=4 days).
  static const _cases = [
    ('Cooked chicken, 2 days', true),
    ('Cooked rice, 6 days', false),
    ('Soup, 3 days', true),
    ('Unknown container, no date', false),
    ('Pasta, 1 day', true),
    ('Leftovers, 9 days', false),
  ];

  void _check() {
    var correct = 0;
    for (var i = 0; i < _cases.length; i++) {
      if (_safe.contains(i) == _cases[i].$2) correct++;
    }
    _score = (correct / _cases.length * 100).round();
    finish(
      score: _score,
      title: 'Leftover Legend',
      description: 'Learned safe leftover storage.',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (finished) {
      return results(
        '$_score% right. Rule of thumb: when you do not know the date, it is safer to toss it.',
      );
    }
    if (!playing) {
      return lobby(
        'Tap the leftovers that are generally safe to reuse (about 4 days or less, properly chilled).',
      );
    }
    return FcScaffold(
      title: 'Leftover Legends',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Tap the SAFE ones:',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < _cases.length; i++)
            Card(
              child: CheckboxListTile(
                value: _safe.contains(i),
                onChanged: (sel) => setState(
                  () => sel == true ? _safe.add(i) : _safe.remove(i),
                ),
                title: Text(_cases[i].$1),
              ),
            ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _check, child: const Text('Check answers')),
        ],
      ),
    );
  }
}

// ---------- Family Food Quest (game surface) ----------

class _QuestGame extends ConsumerStatefulWidget {
  const _QuestGame({required this.def});
  final GameDefinition def;
  @override
  ConsumerState<_QuestGame> createState() => _QuestState();
}

class _QuestState extends _GameState<_QuestGame> {
  @override
  GameDefinition get def => widget.def;

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(appStoreProvider);
    store.ensureQuest();
    if (finished) {
      return results(
        'Quest finished together — every step was optional and zero-pressure.',
      );
    }
    if (!playing) {
      return lobby(
        'A weekly family mission: vote, check a grocery item, learn a skill. Grown-ups approve completions.',
      );
    }
    final doneCount = store.quest.where((q) => q.done).length;
    final accent = _gameAccent(def.id);
    return FcScaffold(
      title: 'Family Quest',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LinearProgressIndicator(
                    value: store.quest.isEmpty
                        ? 0
                        : doneCount / store.quest.length,
                    minHeight: 10,
                    backgroundColor: accent.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation(accent),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FcChip(
                '$doneCount/${store.quest.length}',
                icon: Icons.flag_outlined,
                color: accent,
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final q in store.quest)
            ListTile(
              leading: Icon(
                q.done ? Icons.check_circle : Icons.circle_outlined,
                color: q.done ? FamilyCircleColors.primary : null,
              ),
              title: Text(q.title),
              subtitle: q.done && !q.adultApproved
                  ? const Text('Waiting for grown-up approval')
                  : null,
              trailing: q.done
                  ? null
                  : TextButton(
                      onPressed: () => store.completeQuestObjective(q.id),
                      child: const Text('Done'),
                    ),
            ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: store.quest.every((q) => q.done)
                ? () => finish(
                    score: 70,
                    title: 'Quest Crew',
                    description: 'Completed the weekly family quest.',
                  )
                : null,
            child: const Text('Finish quest'),
          ),
        ],
      ),
    );
  }
}
