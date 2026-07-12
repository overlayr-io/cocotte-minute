import 'dart:async';

import 'package:cocotte_minute/core/auth/auth_bloc.dart';
import 'package:cocotte_minute/core/premium/premium_cubit.dart';
import 'package:cocotte_minute/core/premium/premium_models.dart';
import 'package:cocotte_minute/core/premium/premium_repository.dart';
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
    when(() => repository.logOut()).thenAnswer((_) async {});
    when(() => repository.setUserAttributes(
          email: any(named: 'email'),
          displayName: any(named: 'displayName'),
          custom: any(named: 'custom'),
        )).thenAnswer((_) async {});
  });

  tearDown(() => authStream.close());

  PremiumCubit build(AuthState initial) {
    when(() => authBloc.state).thenReturn(initial);
    return PremiumCubit(repository: repository, authBloc: authBloc)..init();
  }

  test('invité : jamais de logIn RevenueCat, état ready non premium', () async {
    final cubit =
        build(AuthAuthenticated(user: _user(id: 'guest-1', anonymous: true)));
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.status, PremiumStatus.ready);
    expect(cubit.state.isGuest, isTrue);
    expect(cubit.state.isPremium, isFalse);
    verifyNever(() => repository.logIn(any()));

    await cubit.close();
  });

  test('compte inscrit : logIn avec le userId Supabase, entitlement appliqué',
      () async {
    when(() => repository.logIn('user-42')).thenAnswer(
      (_) async => const PremiumEntitlement(
        isActive: true,
        isTrial: true,
        expirationDate: '2026-08-01T00:00:00Z',
      ),
    );

    final cubit = build(AuthAuthenticated(user: _user(id: 'user-42')));
    await Future<void>.delayed(Duration.zero);

    verify(() => repository.logIn('user-42')).called(1);
    expect(cubit.state.status, PremiumStatus.ready);
    expect(cubit.state.isGuest, isFalse);
    expect(cubit.state.isPremium, isTrue);
    expect(cubit.state.isTrial, isTrue);
    expect(cubit.state.expirationDate, '2026-08-01T00:00:00Z');

    await cubit.close();
  });

  test('même utilisateur ré-émis : logIn appelé une seule fois', () async {
    when(() => repository.logIn('user-42'))
        .thenAnswer((_) async => PremiumEntitlement.none);

    final cubit = build(AuthAuthenticated(user: _user(id: 'user-42')));
    await Future<void>.delayed(Duration.zero);
    authStream.add(AuthAuthenticated(user: _user(id: 'user-42')));
    await Future<void>.delayed(Duration.zero);

    verify(() => repository.logIn('user-42')).called(1);

    await cubit.close();
  });

  test('mise à jour CustomerInfo (listener) : active le premium sans logIn',
      () async {
    when(() => repository.logIn('user-42'))
        .thenAnswer((_) async => PremiumEntitlement.none);

    final cubit = build(AuthAuthenticated(user: _user(id: 'user-42')));
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.isPremium, isFalse);

    // Capture l'écouteur enregistré et simule un achat (entitlement actif).
    final listener = verify(() => repository.addEntitlementListener(captureAny()))
        .captured
        .single as PremiumEntitlementListener;
    listener(const PremiumEntitlement(isActive: true, isTrial: false));

    expect(cubit.state.isPremium, isTrue);
    expect(cubit.state.isTrial, isFalse);

    await cubit.close();
  });

  test('déconnexion : logOut appelé, état ready non premium', () async {
    when(() => repository.logIn('user-42'))
        .thenAnswer((_) async => PremiumEntitlement.none);

    final cubit = build(AuthAuthenticated(user: _user(id: 'user-42')));
    await Future<void>.delayed(Duration.zero);

    authStream.add(const AuthUnauthenticated());
    await Future<void>.delayed(Duration.zero);

    // La garde « déjà anonyme » vit dans le repository (Purchases.isAnonymous),
    // le cubit délègue systématiquement.
    verify(() => repository.logOut()).called(1);
    expect(cubit.state.status, PremiumStatus.ready);
    expect(cubit.state.isPremium, isFalse);
    expect(cubit.state.isGuest, isFalse);

    await cubit.close();
  });

  test('RevenueCat non configuré : aucun appel SDK, état ready non premium',
      () async {
    when(() => repository.isConfigured).thenReturn(false);

    final cubit = build(AuthAuthenticated(user: _user(id: 'user-42')));
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.status, PremiumStatus.ready);
    expect(cubit.state.isPremium, isFalse);
    verifyNever(() => repository.logIn(any()));
    verifyNever(() => repository.addEntitlementListener(any()));

    await cubit.close();
  });

  test('échec du logIn (réseau/SDK) : reste non premium sans crash', () async {
    when(() => repository.logIn('user-42')).thenThrow(Exception('network'));

    final cubit = build(AuthAuthenticated(user: _user(id: 'user-42')));
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.status, PremiumStatus.ready);
    expect(cubit.state.isPremium, isFalse);

    await cubit.close();
  });
}
