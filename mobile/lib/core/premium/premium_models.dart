import 'package:equatable/equatable.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Identifiant de l'entitlement RevenueCat qui déverrouille tout le premium.
const String kPremiumEntitlementId = 'pro';

/// Projection « métier » de l'abonnement d'un utilisateur, extraite du
/// [CustomerInfo] RevenueCat par le [PremiumRepository]. Les cubits ne
/// manipulent jamais les types du SDK directement (testabilité).
class PremiumEntitlement extends Equatable {
  const PremiumEntitlement({
    required this.isActive,
    required this.isTrial,
    this.expirationDate,
    this.managementUrl,
  });

  /// Aucun abonnement (état par défaut / invité / déconnecté).
  static const PremiumEntitlement none = PremiumEntitlement(
    isActive: false,
    isTrial: false,
  );

  factory PremiumEntitlement.fromCustomerInfo(CustomerInfo info) {
    final entitlement = info.entitlements.active[kPremiumEntitlementId];
    return PremiumEntitlement(
      isActive: entitlement?.isActive ?? false,
      isTrial: entitlement?.periodType == PeriodType.trial,
      expirationDate: entitlement?.expirationDate,
      managementUrl: info.managementURL,
    );
  }

  final bool isActive;

  /// Vrai pendant la période d'essai gratuit.
  final bool isTrial;

  /// Fin de la période courante (ISO 8601), null si inconnue.
  final String? expirationDate;

  /// URL de gestion de l'abonnement côté store (deep link), si connue.
  final String? managementUrl;

  @override
  List<Object?> get props => [isActive, isTrial, expirationDate, managementUrl];
}

/// Unité de la durée d'un essai gratuit (miroir de `PeriodUnit` RevenueCat).
enum PremiumTrialUnit { day, week, month, year }

/// Essai gratuit attaché à un produit (Introductory Offer à prix 0), lu depuis
/// les données store — jamais codé en dur côté app.
class PremiumTrial extends Equatable {
  const PremiumTrial({required this.units, required this.unit});

  final int units;
  final PremiumTrialUnit unit;

  @override
  List<Object?> get props => [units, unit];
}

/// Un package achetable (mensuel ou annuel) avec son prix localisé store.
class PremiumPackage extends Equatable {
  const PremiumPackage({
    required this.identifier,
    required this.priceString,
    required this.price,
    required this.currencyCode,
    this.trial,
    this.rcPackage,
  });

  static PremiumPackage? fromPackage(Package? package) {
    if (package == null) return null;
    final product = package.storeProduct;
    final intro = product.introductoryPrice;
    PremiumTrial? trial;
    // Un prix d'intro à 0 = essai gratuit ; sinon c'est une offre payante
    // d'introduction, non présentée comme un essai.
    if (intro != null && intro.price == 0) {
      trial = PremiumTrial(
        units: intro.periodNumberOfUnits,
        unit: switch (intro.periodUnit) {
          PeriodUnit.day => PremiumTrialUnit.day,
          PeriodUnit.week => PremiumTrialUnit.week,
          PeriodUnit.month => PremiumTrialUnit.month,
          PeriodUnit.year => PremiumTrialUnit.year,
          PeriodUnit.unknown => PremiumTrialUnit.day,
        },
      );
    }
    return PremiumPackage(
      identifier: package.identifier,
      priceString: product.priceString,
      price: product.price,
      currencyCode: product.currencyCode,
      trial: trial,
      rcPackage: package,
    );
  }

  final String identifier;

  /// Prix formaté localisé fourni par le store (ex. « 3,99 € »).
  final String priceString;

  final double price;
  final String currencyCode;

  /// Essai gratuit du produit, null si aucun.
  final PremiumTrial? trial;

  /// [Package] RevenueCat sous-jacent, requis pour l'achat. Null uniquement
  /// dans les tests (jamais lu par l'UI).
  final Object? rcPackage;

  @override
  List<Object?> get props => [identifier, priceString, price, currencyCode, trial];
}

/// Offre courante (offering RevenueCat) : les deux formules du même entitlement.
class PremiumOffering extends Equatable {
  const PremiumOffering({this.monthly, this.annual});

  final PremiumPackage? monthly;
  final PremiumPackage? annual;

  bool get isEmpty => monthly == null && annual == null;

  /// Économie de l'annuel vs 12 mois de mensuel, en % arrondi (ex. 37).
  /// Null si l'une des deux formules manque ou si le calcul est impossible.
  int? get annualSavingsPercent {
    final m = monthly;
    final a = annual;
    if (m == null || a == null || m.price <= 0) return null;
    final yearlyAtMonthlyRate = m.price * 12;
    if (a.price >= yearlyAtMonthlyRate) return null;
    return ((1 - a.price / yearlyAtMonthlyRate) * 100).round();
  }

  @override
  List<Object?> get props => [monthly, annual];
}

/// Issue d'un achat/restauration qui n'a pas abouti, en termes métier
/// (l'UI décide : annulation silencieuse, info « en attente », ou erreur).
enum PremiumPurchaseErrorType { cancelled, pending, failed }

class PremiumPurchaseException implements Exception {
  const PremiumPurchaseException(this.type, {this.message});

  final PremiumPurchaseErrorType type;
  final String? message;

  @override
  String toString() => 'PremiumPurchaseException($type, $message)';
}
