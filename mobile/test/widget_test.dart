import 'package:cocotte_minute/app.dart';
import 'package:cocotte_minute/core/di/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('L\'app démarre et monte un MaterialApp', (tester) async {
    // L'app résout PremiumRepository & co via get_it dès le premier build.
    // RevenueCat n'étant pas configuré ici, le PremiumCubit reste inerte.
    setupServiceLocator();
    addTearDown(sl.reset);

    await tester.pumpWidget(const CocotteApp());
    await tester.pump();

    // Sans Supabase configuré, l'AuthGate affiche loader puis écran d'erreur.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
