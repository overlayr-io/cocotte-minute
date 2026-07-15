import 'dart:async';

import 'package:cocotte_minute/core/auth/auth_bloc.dart';
import 'package:cocotte_minute/core/di/service_locator.dart';
import 'package:cocotte_minute/core/i18n/generated/app_localizations.dart';
import 'package:cocotte_minute/core/premium/premium_cubit.dart';
import 'package:cocotte_minute/core/premium/premium_models.dart';
import 'package:cocotte_minute/core/premium/premium_repository.dart';
import 'package:cocotte_minute/features/premium/presentation/pages/premium_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class _MockPremiumRepository extends Mock implements PremiumRepository {}

class _MockAuthBloc extends Mock implements AuthBloc {}

supabase.User _user({required String id, bool anonymous = false}) {
  return supabase.User(
    id: id,
    appMetadata: const {},
    userMetadata: const {},
    aud: 'authenticated',
    createdAt: '2026-01-01T00:00:00Z',
    isAnonymous: anonymous,
  );
}

void main() {
  late _MockPremiumRepository repository;
  late _MockAuthBloc authBloc;
  late StreamController<AuthState> authStream;

  setUpAll(() {
    registerFallbackValue((PremiumEntitlement _) {});
  });

  setUp(() {
    repository = _MockPremiumRepository();
    authBloc = _MockAuthBloc();
    authStream = StreamController<AuthState>.broadcast();
    when(() => authBloc.stream).thenAnswer((_) => authStream.stream);
    when(() => repository.isConfigured).thenReturn(true);
    when(() => repository.addEntitlementListener(any())).thenAnswer((_) {});
    when(() => repository.removeEntitlementListener(any())).thenAnswer((_) {});
    when(() => repository.setUserAttributes(
          email: any(named: 'email'),
          displayName: any(named: 'displayName'),
          custom: any(named: 'custom'),
        )).thenAnswer((_) async {});
    // La page résout le repository via get_it (comme en prod).
    sl.registerSingleton<PremiumRepository>(repository);
  });

  tearDown(() async {
    await authStream.close();
    await sl.reset();
  });

  PremiumCubit buildPremiumCubit({required bool guest}) {
    when(() => authBloc.state).thenReturn(
      AuthAuthenticated(user: _user(id: 'u1', anonymous: guest)),
    );
    return PremiumCubit(repository: repository, authBloc: authBloc)..init();
  }

  Future<void> pumpPage(WidgetTester tester, PremiumCubit premiumCubit) async {
    await tester.pumpWidget(
      MaterialApp(
        // Locale figée : les assertions ciblent les textes FR.
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<PremiumCubit>.value(
          value: premiumCubit,
          child: const PremiumPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('invité : comparatif + CTA « Créer ton compte », pas d\'achat',
      (tester) async {
    final premiumCubit = buildPremiumCubit(guest: true);
    addTearDown(premiumCubit.close);

    await pumpPage(tester, premiumCubit);

    // Aucun appel RevenueCat en invité (ni logIn ni offerings).
    verifyNever(() => repository.getOffering());
    verifyNever(() => repository.logIn(any()));

    expect(find.text('Créer ton compte'), findsOneWidget);
    expect(find.text('S\'abonner'), findsNothing);
    expect(find.text('Restaurer mes achats'), findsNothing);
    // Le comparatif gratuit vs Pro reste visible.
    expect(find.text('Recettes de base'), findsOneWidget);
    expect(find.text('Recherche avancée'), findsOneWidget);
  });

  testWidgets(
      'offering chargé : prix store, badge d\'économie, mention d\'essai',
      (tester) async {
    when(() => repository.logIn('u1'))
        .thenAnswer((_) async => PremiumEntitlement.none);
    when(() => repository.getOffering()).thenAnswer(
      (_) async => const PremiumOffering(
        monthly: PremiumPackage(
          identifier: r'$rc_monthly',
          priceString: '3,99 €',
          price: 3.99,
          currencyCode: 'EUR',
          trial: PremiumTrial(units: 15, unit: PremiumTrialUnit.day),
        ),
        annual: PremiumPackage(
          identifier: r'$rc_annual',
          priceString: '29,99 €',
          price: 29.99,
          currencyCode: 'EUR',
        ),
      ),
    );

    final premiumCubit = buildPremiumCubit(guest: false);
    addTearDown(premiumCubit.close);

    await pumpPage(tester, premiumCubit);

    // Prix localisés issus de l'offering (jamais codés en dur dans l'app).
    expect(find.text('3,99 €'), findsOneWidget);
    expect(find.text('29,99 €'), findsOneWidget);
    // Économie annuel vs 12 × mensuel : 1 - 29,99/47,88 ≈ 37 %.
    expect(find.text('-37 %'), findsOneWidget);
    expect(find.text('S\'abonner'), findsOneWidget);
    expect(find.text('Restaurer mes achats'), findsOneWidget);
    // Annuel présélectionné (sans essai) : mention prix seul.
    expect(find.text('29,99 €/an'), findsOneWidget);

    // Bascule sur le mensuel : la mention d'essai vient du store (15 jours).
    await tester.tap(find.text('Mensuel'));
    await tester.pumpAndSettle();
    expect(
      find.text('15 jours d\'essai gratuit, puis 3,99 €/mois'),
      findsOneWidget,
    );
  });

  testWidgets('échec de chargement des offerings : erreur + retry',
      (tester) async {
    when(() => repository.logIn('u1'))
        .thenAnswer((_) async => PremiumEntitlement.none);
    var calls = 0;
    when(() => repository.getOffering()).thenAnswer((_) async {
      calls++;
      if (calls == 1) throw Exception('network');
      return const PremiumOffering(
        monthly: PremiumPackage(
          identifier: r'$rc_monthly',
          priceString: '3,99 €',
          price: 3.99,
          currencyCode: 'EUR',
        ),
      );
    });

    final premiumCubit = buildPremiumCubit(guest: false);
    addTearDown(premiumCubit.close);

    await pumpPage(tester, premiumCubit);

    expect(
      find.text('Impossible de charger les offres. Vérifie ta connexion et réessaie.'),
      findsOneWidget,
    );

    // Les liens légaux (CGU/EULA + confidentialité) restent visibles même sur
    // l'écran d'erreur — exigence App Store 3.1.2 (scénario vu par le reviewer).
    expect(find.text('Conditions d\'utilisation'), findsOneWidget);
    expect(find.text('Politique de confidentialité'), findsOneWidget);

    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();
    expect(find.text('3,99 €'), findsOneWidget);
  });
}
