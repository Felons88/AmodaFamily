import 'package:family_circle/app/family_circle_app.dart';
import 'package:family_circle/features/onboarding/onboarding_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app boots into the welcome route', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FamilyCircleApp()));
    await tester.pumpAndSettle();

    expect(find.text('Kinplora'), findsWidgets);
    expect(find.byType(WelcomePage), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
