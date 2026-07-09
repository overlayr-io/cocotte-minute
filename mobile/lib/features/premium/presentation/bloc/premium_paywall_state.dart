part of 'premium_paywall_cubit.dart';

/// Chargement de l'offering (bloquant : les prix en dépendent).
enum PaywallStatus { loading, failure, ready }

/// Phase d'une action d'achat/restauration. `success` = entitlement actif,
/// la page affiche l'état de succès puis se referme.
enum PaywallPhase { idle, purchasing, restoring, success }

/// Message transitoire (snackbar) — sémantique, traduit par la page.
enum PaywallMessage { purchasePending, purchaseFailed, restoreNone }

class PremiumPaywallState extends Equatable {
  const PremiumPaywallState({
    this.status = PaywallStatus.loading,
    this.offering,
    this.annualSelected = true,
    this.phase = PaywallPhase.idle,
    this.message,
  });

  final PaywallStatus status;

  /// Offering courant. Null en mode invité ou si RevenueCat n'en expose aucun.
  final PremiumOffering? offering;

  final bool annualSelected;
  final PaywallPhase phase;

  /// Message transitoire, remis à null à la prochaine émission (non porté).
  final PaywallMessage? message;

  PremiumPackage? get selectedPackage {
    final o = offering;
    if (o == null) return null;
    return annualSelected ? (o.annual ?? o.monthly) : (o.monthly ?? o.annual);
  }

  PremiumPaywallState copyWith({
    PaywallStatus? status,
    PremiumOffering? offering,
    bool? annualSelected,
    PaywallPhase? phase,
    PaywallMessage? message,
  }) {
    return PremiumPaywallState(
      status: status ?? this.status,
      offering: offering ?? this.offering,
      annualSelected: annualSelected ?? this.annualSelected,
      phase: phase ?? this.phase,
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, offering, annualSelected, phase, message];
}
