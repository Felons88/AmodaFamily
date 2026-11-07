import 'package:family_circle/app/family_circle_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app boots into its foundation route', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FamilyCircleApp()));
    await tester.pumpAndSettle();

    expect(find.text('Family Circle'), findsOneWidget);
    expect(find.byType(FoundationScreen), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
