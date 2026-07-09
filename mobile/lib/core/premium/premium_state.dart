part of 'premium_cubit.dart';

/// `loading` tant que le premier statut n'est pas résolu (auth en cours).
enum PremiumStatus { loading, ready }

class PremiumState extends Equatable {
  const PremiumState({
    this.status = PremiumStatus.loading,
    this.isPremium = false,
    this.isTrial = false,
    this.expirationDate,
    this.isGuest = false,
  });

  final PremiumStatus status;

  /// Entitlement `pro` actif (abonnement ou essai en cours).
  final bool isPremium;

  /// Vrai pendant la période d'essai gratuit.
  final bool isTrial;

  /// Fin de la période courante (ISO 8601), null si inconnue.
  final String? expirationDate;

  /// Compte invité (anonyme Supabase) : jamais loggé dans RevenueCat, le
  /// paywall lui montre « Créer un compte » à la place de l'achat.
  final bool isGuest;

  @override
  List<Object?> get props => [status, isPremium, isTrial, expirationDate, isGuest];
}
