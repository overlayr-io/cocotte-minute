import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import '../config/env.dart';
import 'premium_models.dart';

/// Signature des écouteurs de changement d'abonnement côté app.
typedef PremiumEntitlementListener =
    void Function(PremiumEntitlement entitlement);

/// Unique point de contact avec les SDK RevenueCat (`purchases_flutter` +
/// `purchases_ui_flutter`) : aucun cubit n'appelle les statiques `Purchases.*`
/// directement (testabilité via mocktail, miroir de la convention serveur).
class PremiumRepository {
  bool _configured = false;

  /// Vrai une fois `Purchases.configure` passé avec succès. Tant que faux,
  /// les cubits doivent se comporter comme « non premium » sans appeler le SDK.
  bool get isConfigured => _configured;

  final Map<PremiumEntitlementListener, void Function(CustomerInfo)>
  _listeners = {};

  /// Configure RevenueCat au démarrage, SANS appUserID (utilisateur anonyme
  /// RevenueCat) ; `logIn` n'est appelé que pour un compte Supabase inscrit.
  /// À envelopper d'un try/catch côté appelant : un échec ne doit jamais
  /// bloquer le démarrage de l'app.
  Future<void> configure() async {
    if (_configured) return;
    // Garde-fou release : sans clé de prod (`appl_`/`goog_`), on NE configure
    // PAS RevenueCat avec la clé du Test Store. Le premium reste désactivé
    // proprement (l'appelant catch, l'app démarre) au lieu de faire échouer le
    // paywall sur l'appareil du reviewer Apple (rejet 2.1). En debug, repli
    // Test Store toléré via Env.revenueCatApiKey.
    if (Env.revenueCatKeyMissingInRelease) {
      throw StateError(
        'RevenueCat: REVENUECAT_API_KEY (clé de prod appl_.../goog_...) '
        'manquante en release. La fournir via '
        '--dart-define-from-file=env.prod.json avant tout build de release.',
      );
    }
    if (kDebugMode) {
      await Purchases.setLogLevel(LogLevel.debug);
    }
    await Purchases.configure(PurchasesConfiguration(Env.revenueCatApiKey));
    _configured = true;
  }

  /// Identifie l'utilisateur RevenueCat par son userId Supabase (`sub`).
  Future<PremiumEntitlement> logIn(String supabaseUserId) async {
    final result = await Purchases.logIn(supabaseUserId);
    _debugDumpCustomerInfo('logIn', result.customerInfo);
    return PremiumEntitlement.fromCustomerInfo(result.customerInfo);
  }

  /// Renseigne les subscriber attributes RevenueCat (email, nom, données
  /// Supabase utiles) pour peupler la fiche customer côté dashboard et les
  /// intégrations. Non bloquant : un échec ne doit jamais casser la connexion
  /// ni l'achat. À n'appeler QUE pour un compte inscrit (jamais un invité).
  Future<void> setUserAttributes({
    String? email,
    String? displayName,
    Map<String, String> custom = const {},
  }) async {
    if (!_configured) return;
    try {
      if (email != null && email.isNotEmpty) await Purchases.setEmail(email);
      if (displayName != null && displayName.isNotEmpty) {
        await Purchases.setDisplayName(displayName);
      }
      final cleaned = {
        for (final e in custom.entries)
          if (e.value.isNotEmpty) e.key: e.value,
      };
      if (cleaned.isNotEmpty) await Purchases.setAttributes(cleaned);
    } catch (_) {
      // Best-effort : les attributes ne conditionnent aucun droit premium.
    }
  }

  /// Diagnostic (debug uniquement) : distingue « entitlement `pro` non rattaché
  /// au produit » d'un « abonnement bien accordé ». Si `activeSubscriptions`
  /// contient le produit mais que `entitlements.active` est vide → le mapping
  /// produit→entitlement `pro` manque dans le dashboard RevenueCat.
  void _debugDumpCustomerInfo(String origin, CustomerInfo info) {
    if (!kDebugMode) return;
    debugPrint('[Premium/$origin] appUserId=${info.originalAppUserId}');
    debugPrint(
      '[Premium/$origin] activeSubscriptions='
      '${info.activeSubscriptions}',
    );
    debugPrint(
      '[Premium/$origin] entitlements.all='
      '${info.entitlements.all.keys.toList()}',
    );
    debugPrint(
      '[Premium/$origin] entitlements.active='
      '${info.entitlements.active.keys.toList()}',
    );
    debugPrint(
      '[Premium/$origin] pro actif='
      '${info.entitlements.active[kPremiumEntitlementId] != null}',
    );
  }

  /// Déconnecte l'utilisateur RevenueCat. `Purchases.logOut()` lève si
  /// l'utilisateur courant est déjà anonyme → garde `isAnonymous`.
  Future<void> logOut() async {
    if (await Purchases.isAnonymous) return;
    await Purchases.logOut();
  }

  Future<PremiumEntitlement> currentEntitlement() async {
    final info = await Purchases.getCustomerInfo();
    return PremiumEntitlement.fromCustomerInfo(info);
  }

  /// Abonne [listener] aux mises à jour d'abonnement (activation instantanée
  /// après achat, sans attendre le webhook serveur). RevenueCat rappelle
  /// immédiatement avec la dernière info connue si elle existe.
  void addEntitlementListener(PremiumEntitlementListener listener) {
    void wrapped(CustomerInfo info) {
      _debugDumpCustomerInfo('update', info);
      listener(PremiumEntitlement.fromCustomerInfo(info));
    }

    _listeners[listener] = wrapped;
    Purchases.addCustomerInfoUpdateListener(wrapped);
  }

  void removeEntitlementListener(PremiumEntitlementListener listener) {
    final wrapped = _listeners.remove(listener);
    if (wrapped != null) Purchases.removeCustomerInfoUpdateListener(wrapped);
  }

  /// Offering courant (formules mensuelle/annuelle) avec prix localisés store.
  /// Null si aucun offering courant n'est configuré côté RevenueCat.
  Future<PremiumOffering?> getOffering() async {
    final offerings = await Purchases.getOfferings();
    final current = offerings.current;
    if (current == null) return null;
    return PremiumOffering(
      monthly: PremiumPackage.fromPackage(current.monthly),
      annual: PremiumPackage.fromPackage(current.annual),
    );
  }

  /// Achat natif du package. Lève une [PremiumPurchaseException] typée
  /// (annulation, paiement en attente, échec) — jamais une PlatformException.
  Future<PremiumEntitlement> purchase(PremiumPackage package) async {
    final rc = package.rcPackage;
    if (rc is! Package) {
      throw const PremiumPurchaseException(PremiumPurchaseErrorType.failed);
    }
    try {
      final result = await Purchases.purchase(PurchaseParams.package(rc));
      _debugDumpCustomerInfo('purchase', result.customerInfo);
      return PremiumEntitlement.fromCustomerInfo(result.customerInfo);
    } on PlatformException catch (e) {
      throw PremiumPurchaseException(_errorTypeOf(e), message: e.message);
    }
  }

  /// « Restaurer mes achats » (obligatoire pour la review Apple).
  Future<PremiumEntitlement> restore() async {
    try {
      final info = await Purchases.restorePurchases();
      return PremiumEntitlement.fromCustomerInfo(info);
    } on PlatformException catch (e) {
      throw PremiumPurchaseException(_errorTypeOf(e), message: e.message);
    }
  }

  /// Ouvre le Customer Center RevenueCat (gestion de l'abonnement).
  Future<void> showCustomerCenter() async {
    if (!_configured) return;
    await RevenueCatUI.presentCustomerCenter();
  }

  static PremiumPurchaseErrorType _errorTypeOf(PlatformException e) {
    final code = PurchasesErrorHelper.getErrorCode(e);
    return switch (code) {
      PurchasesErrorCode.purchaseCancelledError =>
        PremiumPurchaseErrorType.cancelled,
      PurchasesErrorCode.paymentPendingError =>
        PremiumPurchaseErrorType.pending,
      _ => PremiumPurchaseErrorType.failed,
    };
  }
}
