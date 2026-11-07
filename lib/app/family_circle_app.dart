import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../shared/updates.dart';
import 'router.dart';
import 'theme.dart';

class FamilyCircleApp extends ConsumerWidget {
  const FamilyCircleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Kinplora',
      theme: FamilyCircleTheme.light,
      darkTheme: FamilyCircleTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: ref.watch(appRouterProvider),
      builder: (context, child) =>
          _UpdateGate(child: child ?? const SizedBox.shrink()),
    );
  }
}

/// Runs the auto-update check once per app launch, on any screen.
class _UpdateGate extends StatefulWidget {
  const _UpdateGate({required this.child});

  final Widget child;

  @override
  State<_UpdateGate> createState() => _UpdateGateState();
}

class _UpdateGateState extends State<_UpdateGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateChecker.promptIfAvailable(context);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Bottom navigation shared by the five adult destinations.
/// Contract: max five destinations, >=44pt targets.
class AdultNavBar extends StatelessWidget {
  const AdultNavBar({super.key, required this.current});

  final String current;

  static const _tabs = [
    (AppRoute.home, Icons.home_outlined, Icons.home, 'Home'),
    (
      AppRoute.plan,
      Icons.calendar_view_week_outlined,
      Icons.calendar_view_week,
      'Plan',
    ),
    (
      AppRoute.shop,
      Icons.shopping_basket_outlined,
      Icons.shopping_basket,
      'Shop',
    ),
    (
      AppRoute.family,
      Icons.family_restroom_outlined,
      Icons.family_restroom,
      'Family',
    ),
    (AppRoute.more, Icons.more_horiz, Icons.more, 'More'),
  ];

  @override
  Widget build(BuildContext context) {
    final selected = _tabs.indexWhere((t) => t.$1.path == current).clamp(0, 4);
    return NavigationBar(
      selectedIndex: selected,
      onDestinationSelected: (i) => context.go(_tabs[i].$1.path),
      destinations: [
        for (final t in _tabs)
          NavigationDestination(
            icon: Icon(t.$2),
            selectedIcon: Icon(t.$3),
            label: t.$4,
          ),
      ],
    );
  }
}

class KidsNavBar extends StatelessWidget {
  const KidsNavBar({super.key, required this.current});

  final String current;

  static const _tabs = [
    (AppRoute.kidsHome, Icons.home_outlined, Icons.home, 'Home'),
    (AppRoute.kidsVote, Icons.how_to_vote_outlined, Icons.how_to_vote, 'Vote'),
    (AppRoute.kidsQuest, Icons.flag_outlined, Icons.flag, 'Quest'),
    (
      AppRoute.kidsBadges,
      Icons.military_tech_outlined,
      Icons.military_tech,
      'Badges',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final selected = _tabs.indexWhere((t) => t.$1.path == current).clamp(0, 3);
    return NavigationBar(
      selectedIndex: selected,
      onDestinationSelected: (i) => context.go(_tabs[i].$1.path),
      destinations: [
        for (final t in _tabs)
          NavigationDestination(
            icon: Icon(t.$2),
            selectedIcon: Icon(t.$3),
            label: t.$4,
          ),
      ],
    );
  }
}
