import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'theme.dart';

enum AppRoute { foundation }

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    routes: [
      GoRoute(
        name: AppRoute.foundation.name,
        path: '/',
        builder: (context, state) => const FoundationScreen(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

class FamilyCircleApp extends ConsumerWidget {
  const FamilyCircleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Family Circle',
      theme: FamilyCircleTheme.light,
      darkTheme: FamilyCircleTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}

/// Temporary entry point for FC-001. Product screens follow their own contracts.
class FoundationScreen extends StatelessWidget {
  const FoundationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Semantics(
              label: 'Family Circle app foundation',
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.restaurant_menu, size: 48),
                  const SizedBox(height: 24),
                  Text(
                    'Family Circle',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Your family meal planner is taking shape.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
