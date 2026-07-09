import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../auth/auth_bloc.dart';
import 'premium_models.dart';
import 'premium_repository.dart';

part 'premium_state.dart';

/// Statut d'abonnement partagé (core, comme AuthBloc) : synchronise
/// RevenueCat sur les changements d'auth (`logIn` avec l'userId Supabase à la
/// connexion d'un compte inscrit, `logOut` à la déconnexion — jamais pour un
/// invité) et écoute les mises à jour de CustomerInfo (activation instantanée
/// après achat).
///
/// N'est qu'un gating d'AFFICHAGE : la vérité des limites reste le serveur
/// (403 `PREMIUM_LIMIT_*`), l'UI affiche l'upsell même si l'état local se
/// croyait premium.
class PremiumCubit extends Cubit<PremiumState> {
  PremiumCubit({
    required PremiumRepository repository,
    required AuthBloc authBloc,
  })  : _repository = repository,
        _authBloc = authBloc,
        super(const PremiumState());

  final PremiumRepository _repository;
  final AuthBloc _authBloc;

  StreamSubscription<AuthState>? _authSub;
  bool _listening = false;
  String? _syncedUserId;

  /// À appeler une fois à la création (provider `lazy: false` dans l'app).
  void init() {
    _onAuthChanged(_authBloc.state);
    _authSub = _authBloc.stream.listen(_onAuthChanged);
  }

  Future<void> _onAuthChanged(AuthState authState) async {
    switch (authState) {
      case AuthAuthenticated(:final user) when user.isAnonymous:
        // Invité : n'interagit JAMAIS avec RevenueCat (ni logIn ni achat).
        _syncedUserId = null;
        emit(const PremiumState(status: PremiumStatus.ready, isGuest: true));
      case AuthAuthenticated(:final user):
        await _syncUser(user.id);
      case AuthUnauthenticated():
        _syncedUserId = null;
        if (_repository.isConfigured) {
          try {
            await _repository.logOut();
          } catch (_) {
            // Non bloquant : l'utilisateur est déconnecté côté app quoi qu'il
            // arrive, l'état repart non-premium.
          }
        }
        emit(const PremiumState(status: PremiumStatus.ready));
      default:
        // AuthInitial / AuthLoading / AuthFailure : rien à synchroniser.
        break;
    }
  }

  Future<void> _syncUser(String userId) async {
    if (!_repository.isConfigured) {
      // RevenueCat indisponible : on reste non-premium (les limites serveur
      // font foi de toute façon).
      emit(const PremiumState(status: PremiumStatus.ready));
      return;
    }
    _ensureListener();
    if (_syncedUserId == userId) return;
    _syncedUserId = userId;
    try {
      final entitlement = await _repository.logIn(userId);
      _apply(entitlement);
    } catch (_) {
      emit(const PremiumState(status: PremiumStatus.ready));
    }
  }

  void _ensureListener() {
    if (_listening) return;
    _listening = true;
    _repository.addEntitlementListener(_onEntitlement);
  }

  void _onEntitlement(PremiumEntitlement entitlement) {
    // L'info anonyme RevenueCat ne concerne jamais un invité côté app.
    if (state.isGuest || isClosed) return;
    _apply(entitlement);
  }

  void _apply(PremiumEntitlement entitlement) {
    emit(PremiumState(
      status: PremiumStatus.ready,
      isPremium: entitlement.isActive,
      isTrial: entitlement.isTrial,
      expirationDate: entitlement.expirationDate,
    ));
  }

  @override
  Future<void> close() {
    _authSub?.cancel();
    if (_listening) _repository.removeEntitlementListener(_onEntitlement);
    return super.close();
  }
}
