import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/premium/premium_models.dart';
import '../../../../core/premium/premium_repository.dart';

part 'premium_paywall_state.dart';

/// Pilote le paywall maison : chargement de l'offering RevenueCat (prix
/// localisés store, jamais codés en dur), sélection mensuel/annuel, achat
/// natif et restauration. En mode invité, aucun appel RevenueCat n'est fait
/// (la page montre « Créer un compte » à la place de l'achat).
class PremiumPaywallCubit extends Cubit<PremiumPaywallState> {
  PremiumPaywallCubit({
    required PremiumRepository repository,
    required bool isGuest,
  })  : _repository = repository,
        _isGuest = isGuest,
        super(const PremiumPaywallState());

  final PremiumRepository _repository;
  final bool _isGuest;

  bool get isGuest => _isGuest;

  Future<void> load() async {
    if (_isGuest) {
      // Invité : pas d'offering (aucune interaction RevenueCat), la page
      // affiche le comparatif + CTA de création de compte.
      emit(const PremiumPaywallState(status: PaywallStatus.ready));
      return;
    }
    emit(const PremiumPaywallState(status: PaywallStatus.loading));
    try {
      final offering = await _repository.getOffering();
      emit(PremiumPaywallState(
        status: PaywallStatus.ready,
        offering: offering,
        // L'annuel (mis en avant) est présélectionné quand il existe.
        annualSelected: offering?.annual != null,
      ));
    } catch (_) {
      emit(const PremiumPaywallState(status: PaywallStatus.failure));
    }
  }

  void selectAnnual(bool annual) {
    if (state.status != PaywallStatus.ready) return;
    emit(state.copyWith(annualSelected: annual));
  }

  Future<void> purchase() async {
    final package = state.selectedPackage;
    if (package == null || state.phase != PaywallPhase.idle) return;
    emit(state.copyWith(phase: PaywallPhase.purchasing));
    try {
      final entitlement = await _repository.purchase(package);
      if (entitlement.isActive) {
        emit(state.copyWith(phase: PaywallPhase.success));
      } else {
        emit(state.copyWith(
          phase: PaywallPhase.idle,
          message: PaywallMessage.purchaseFailed,
        ));
      }
    } on PremiumPurchaseException catch (e) {
      _handlePurchaseError(e);
    } catch (_) {
      emit(state.copyWith(
        phase: PaywallPhase.idle,
        message: PaywallMessage.purchaseFailed,
      ));
    }
  }

  Future<void> restore() async {
    if (state.phase != PaywallPhase.idle) return;
    emit(state.copyWith(phase: PaywallPhase.restoring));
    try {
      final entitlement = await _repository.restore();
      if (entitlement.isActive) {
        emit(state.copyWith(phase: PaywallPhase.success));
      } else {
        emit(state.copyWith(
          phase: PaywallPhase.idle,
          message: PaywallMessage.restoreNone,
        ));
      }
    } on PremiumPurchaseException catch (e) {
      _handlePurchaseError(e);
    } catch (_) {
      emit(state.copyWith(
        phase: PaywallPhase.idle,
        message: PaywallMessage.purchaseFailed,
      ));
    }
  }

  void _handlePurchaseError(PremiumPurchaseException e) {
    switch (e.type) {
      case PremiumPurchaseErrorType.cancelled:
        // Annulation utilisateur : silencieuse (aucun message).
        emit(state.copyWith(phase: PaywallPhase.idle));
      case PremiumPurchaseErrorType.pending:
        emit(state.copyWith(
          phase: PaywallPhase.idle,
          message: PaywallMessage.purchasePending,
        ));
      case PremiumPurchaseErrorType.failed:
        emit(state.copyWith(
          phase: PaywallPhase.idle,
          message: PaywallMessage.purchaseFailed,
        ));
    }
  }
}
