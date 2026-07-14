---
feature: premium-version
status: done        # planned | in-progress | done
scope: v1 (application réelle des limites freemium + intégration paiement RevenueCat + écran d'offre)
depends_on: [auth, limite-freemium, recette-base, liste-courses-auto, recherche-avancee]
order: 11
---

> **État 2026-07-10** : code server + mobile livré et testé (migration 0013,
> webhook, limites, PremiumCubit, paywall, upsells). Reste uniquement de la
> config externe (pas de code) : dashboard RevenueCat (entitlement `pro`,
> produits, webhook), produits App Store Connect / Play Console.
>
> **État 2026-07-14** : 1re soumission App Store **rejetée** (submission
> 9d90d366, 3 points) — corrections code livrées, reste de la config externe.
> Voir [Soumission App Store — rejet 2026-07-14](#soumission-app-store--rejet-2026-07-14-et-corrections).

# Version premium — abonnement, écran d'offre et application des limites

## Problème résolu
`limite-freemium.md` définit les limites du plan gratuit mais rien n'est branché :
pas de statut premium en base, une seule limite réellement appliquée côté serveur
(1 liste de courses active), aucun écran d'offre. Cette feature met en production
le premium complet : présentation visuelle de l'offre Cocotte Minute (gratuit vs
premium), paiement réel, et application de toutes les limites côté serveur.

## Décision actée : RevenueCat (2026-07-08)
La décision "paiement reporté après le v1" de `limite-freemium.md` est levée.

- **Solution retenue : RevenueCat** (`purchases_flutter`) au-dessus des IAP natifs
  StoreKit / Play Billing.
- **Pourquoi pas Stripe** : depuis le DMA (UE, juin 2025), Stripe est légal sur iOS
  mais Apple prélève quand même 12-17 % sur les ventes externes (Store Services fee
  + Core Technology Commission + Initial Acquisition Fee), avec reporting obligatoire
  de chaque transaction à Apple. Ajouté aux frais Stripe et à la charge TVA/OSS
  (Stripe n'est pas merchant of record : TVA du pays du client à notre charge
  au-delà de 10 k€ de ventes UE transfrontalières), l'économie est nulle voire
  négative à notre volume, pour une UX dégradée (redirection navigateur).
- **Avec IAP natif** : Apple/Google sont commissionnaires → TVA gérée par les
  stores, zéro obligation OSS. Apple Small Business Program : 15 %
  (à activer dans App Store Connect). Google : 10 % sur les abonnements
  (barème EEE depuis le 30 juin 2026).
- **RevenueCat** : gratuit jusqu'à 2 500 $ de MTR (≈ 600 abonnés), puis 1 %.
  Webhooks serveur → NestJS maintient le statut premium dans Supabase.
- **Porte ouverte plus tard** : RevenueCat Web Billing (Stripe derrière) permet de
  vendre sur le site web sans commission Apple (modèle Spotify : aucun lien dans
  l'app iOS) — hors scope ici, mais le choix RevenueCat ne le ferme pas.

## Offre
- **Deux formules, un seul entitlement `premium`** (aucune différence de
  fonctionnalités entre elles, seulement prix/engagement) :
    - **Mensuel : 3,99 €/mois, essai gratuit de 15 jours** (essai géré
      nativement par les stores via RevenueCat, cf. `limite-freemium.md`).
    - **Annuel : 29,99 €/an, sans essai** (≈ 2,50 €/mois, ~37 % moins cher que
      le mensuel sur un an — argument de conversion sur le paywall).
  Les deux produits appartiennent au même **offering/entitlement RevenueCat**
  (`pro` — identifiant tranché le 2026-07-09) ; le paywall les présente comme
  deux options d'un même choix (toggle mensuel/annuel), pas comme deux offres
  différentes.
- **Achat unique à vie** (`lifetime`) : prévu dans `PROJECT_CONTEXT.md`
  (`premium_type: 'none'|'subscription'|'lifetime'`) — prix à trancher,
  peut être ajouté après le lancement (non-consommable RevenueCat).
- **Compte requis** : le premium n'est proposé qu'aux comptes inscrits
  (email ou OAuth). Un compte invité (`isAnonymous`) ne voit pas le paywall
  d'achat : il voit l'écran d'offre avec un CTA "Créer un compte" à la place
  du bouton d'abonnement (réutilise le flux de conversion invité→inscrit
  existant, `auth_repository.createAccountWithEmail` / `continueWithOAuth`).

### Offre de lancement (2026-07-09)
- **Un seul produit mensuel `pro_monthly`, toujours à 3,99 €/mois** — pas de
  second prix, pas de second produit. L'offre de lancement est portée
  uniquement par la durée de l'essai gratuit (Introductory Offer native
  StoreKit / Play Billing) :
    - **Pendant les 90 premiers jours suivant la sortie publique de l'app**
      (fenêtre calendaire fixe, pas par utilisateur) : essai gratuit de
      **30 jours** pour tout compte n'ayant jamais souscrit.
    - **Après ces 90 jours** : essai gratuit ramené à **15 jours** (durée
      normale), toujours pour les nouveaux abonnés.
    - Aucun grandfathering à gérer : un abonné qui a profité des 30 jours
      paie ensuite le même 3,99 €/mois que tout le monde, sans distinction en
      base. Rien à tracker côté serveur pour cette offre.
- **Pourquoi cette forme et pas un prix réduit à vie** : ni Apple ni Google ne
  proposent nativement un "prix réduit permanent réservé à une fenêtre de
  souscription calendaire" sur un seul produit — Introductory/Promotional/
  Win-Back Offers d'Apple sont toutes bornées à un nombre fini de périodes,
  et repassent au prix standard ensuite ; répliquer un prix à vie aurait
  demandé un second produit (`pro_monthly_launch`) + bascule d'Offering
  RevenueCat après 90 jours, pour un gain de conversion incertain vs. la
  complexité ajoutée (2 produits à maintenir dans le même subscription group,
  gestion de l'éligibilité à l'essai croisée). Un essai plus long est un
  levier d'acquisition tout aussi fort, 100 % natif, sans code supplémentaire.
- **Action manuelle requise** : modifier la durée de l'Intro Offer dans App
  Store Connect et Play Console (30j → 15j) à J+90 après la sortie — aucune
  action serveur/mobile.

## Offre gratuit vs premium (contenu de l'écran d'offre)

| Fonctionnalité                   | Gratuit                  | Premium                                                                       |
|----------------------------------|--------------------------|-------------------------------------------------------------------------------|
| Recettes                         | Illimité                 | Illimité                                                                      |
| Recettes de base (sous-recettes) | 5 max                    | Illimité                                                                      |
| Listes de courses                | 1 liste active à la fois | Listes multiples en parallèle                                                 |
| Historique des listes de courses | —                        | Historique complet (archives)                                                 |
| Recherche avancée                | 6 critères cumulés max   | Critères illimités                                                            |
| Recherche IA locale              | —                        | Inclus *(quand livrée — pas affichée sur le paywall tant que non disponible)* |
| Génération de recette            | -                        | Inclus *(quand livrée — pas affichée sur le paywall tant que non disponible)* |
| Marketplace                      | -                        | Inclus *(quand livrée — pas affichée sur le paywall tant que non disponible)* |

- Plafond de recherche **tranché à 6** (l'exemple de `limite-freemium.md`
  — 2 personnes + 3 tags + 1 texte — somme à 6 ; à confirmer, cf. questions
  ouvertes).
- Le paywall n'affiche **que des fonctionnalités livrées** : pas d'IA locale,
  pas d'export PDF tant que non implémentés.

## UX

### Écran d'offre (paywall)
- Page dédiée `PremiumPage` : proposition de valeur Cocotte Minute + tableau
  comparatif gratuit vs premium ci-dessus + **sélecteur mensuel/annuel**
  (annuel mis en avant, ex. badge "-37 %") + mention de la durée d'essai
  réellement éligible (15 ou 30 jours selon la fenêtre de lancement — lue
  depuis l'Introductory Offer RevenueCat, jamais codée en dur côté app)
  + bouton d'abonnement (achat natif) + lien "Restaurer mes achats"
  + liens CGU (EULA)/confidentialité (obligatoires pour la review Apple —
  guideline 3.1.2c). Depuis le 2026-07-14 ces liens vivent dans un
  **`_LegalFooter` persistant**, affiché sous la zone d'état dans **tous** les
  états du paywall (chargement, erreur, offres, succès) : ils ne disparaissent
  plus sur l'écran d'erreur (cf. section rejet App Store).
- Construite avec les paywalls RevenueCat **ou** en Flutter maison branchée sur
  les `Offerings` RevenueCat (prix localisés récupérés du store, jamais codés
  en dur) — à trancher à l'implémentation, paywall maison par défaut pour
  rester cohérent avec le design system existant.
- Points d'entrée :
    - Carte upsell existante de la page courses (`shopping_page.dart`) →
      remplace la navigation vers l'aperçu statique `premium_shopping_page.dart`
      par la vraie `PremiumPage`.
    - Page compte (`account_page.dart`) : ligne "Cocotte Minute Premium" avec
      statut (gratuit / premium / essai en cours).
    - Chaque limite atteinte (voir ci-dessous).

### Limite atteinte
- À chaque limite atteinte, feuille/bandeau clair : rappel de la limite,
  explication, CTA vers `PremiumPage`. Jamais de blocage silencieux ni de
  dialogue d'erreur brut (conforme à `limite-freemium.md` : ne pas bloquer
  l'usage de base).
    - 6e sous-recette : blocage à la création (le toggle `is_base` ou la
      création de recette de base affiche l'upsell).
    - 2e liste de courses : déjà géré serveur (ConflictException), l'UI
      remplace le message texte par la feuille d'upsell.
    - 7e critère de recherche : les chips/critères supplémentaires sont
      désactivés avec un indicateur "6/6 — passez premium".
- Utilisateur premium : aucune de ces UI n'apparaît.

### Gestion de l'abonnement
- Statut visible dans la page compte ; "Gérer mon abonnement" ouvre le
  **Customer Center RevenueCat** (`purchases_ui_flutter`, décision 2026-07-09) :
  annulation, remboursement et changement de formule en self-service.
- Annulation/remboursement : gérés par les stores, rien à faire côté app.
- "Restaurer mes achats" obligatoire (guideline Apple) — `Purchases.restorePurchases()`.

## Architecture technique

### Source de vérité
- **RevenueCat est la source de vérité de l'abonnement**, le serveur en garde
  une **projection** dans Postgres pour appliquer les limites sans appel réseau.
- Identification RevenueCat par **app user ID = userId Supabase** (`sub`),
  jamais l'ID anonyme RevenueCat : `Purchases.logIn(userId)` après connexion,
  `Purchases.logOut()` à la déconnexion. Les invités ne sont jamais loggés
  dans RevenueCat.

### Server (NestJS)
- **DB (migration)** : colonnes sur `accounts` (table existante, 1 ligne par user) :
    - `premium_type` : enum `none | subscription | lifetime`, défaut `none`.
    - `premium_until` : timestamp nullable (fin de période courante, null pour
      `lifetime`) — permet d'appliquer l'expiration même si un webhook se perd.
    - `premium_updated_at` : timestamp du dernier événement RevenueCat traité.
- **Module `billing`** :
    - `POST /billing/revenuecat` : webhook RevenueCat (INITIAL_PURCHASE, RENEWAL,
      CANCELLATION, EXPIRATION, BILLING_ISSUE, PRODUCT_CHANGE…). Auth par header
      secret (`Authorization` configuré côté RevenueCat), route publique hors
      guard JWT. Idempotent (les webhooks peuvent être rejoués).
    - `PremiumService.isPremium(userId)` : `premium_type != 'none'` ET
      (`lifetime` OU `premium_until > now()`). Utilisé par les gardes de limite.
- **Application des limites** (toujours côté serveur, cf. `server/CLAUDE.md`) :
    - Sous-recettes : à la création/passage `is_base=true`, si non-premium et
      `count(recipes where is_base and user_id) >= 5` → 403 avec code d'erreur
      dédié (ex. `PREMIUM_LIMIT_BASE_RECIPES`), exploitable par le mobile.
    - Liste de courses : `assertNoActiveList` existant → ne s'applique plus si
      premium ; endpoints d'archives/historique (`archivedAt`) réservés premium.
    - Recherche : `GET /search/recipes` compte les critères (texte + personnes
      + tags + catégories) ; si non-premium et total > 6 → 403
      `PREMIUM_LIMIT_SEARCH_CRITERIA`.
- Format d'erreur : réponse 403 structurée `{ code, limit, current }` pour que
  le mobile affiche l'upsell adapté sans parser de message.

### Mobile (Flutter)
- Dépendance `purchases_flutter` ; init au démarrage (clés API par plateforme),
  `logIn/logOut` synchronisés sur `AuthBloc`.
- **Clé RevenueCat / garde-fou release (2026-07-14)** : `Env.revenueCatApiKey`
  ne retombe sur la clé du **Test Store** qu'en **debug**
  (`kReleaseMode ? '' : _testStoreKey`). En release, une clé de prod
  (`appl_...`/`goog_...`) via `--dart-define-from-file=env.prod.json` est
  obligatoire : sinon `PremiumRepository.configure()` lève un `StateError`
  (attrapé par l'appelant → premium désactivé proprement, jamais la clé test
  embarquée). Empêche la récurrence du rejet 2.1 (paywall en erreur car un
  build prod embarquait la clé Test Store, qui ne sert pas les produits App
  Store réels).
- **`PremiumCubit`** (core) : expose `isPremium` + statut (essai, expiration).
  Alimenté par `Purchases.getCustomerInfo()` + listener
  `addCustomerInfoUpdateListener` (activation instantanée après achat, sans
  attendre le webhook serveur).
- Gating UI par `PremiumCubit` (affichage), mais **la vérité des limites reste
  le serveur** : sur 403 `PREMIUM_LIMIT_*`, l'UI affiche l'upsell même si l'état
  local croyait être premium.
- Achat : `Purchases.purchasePackage()` sur l'offering courant ; gestion des
  erreurs standard (annulation utilisateur silencieuse, achat en attente,
  store indisponible).
- Suppression de compte (RGPD existant) : appeler l'API RevenueCat de
  suppression du subscriber dans le flux de suppression serveur.

### Config stores (hors code, à faire)
- App Store Connect : **un groupe d'abonnement** avec deux produits
  auto-renouvelables — `pro_monthly` 3,99 €/mois (Introductory Offer = essai
  gratuit, **30 jours à la sortie, à repasser à 15 jours dans la console à
  J+90**) et `pro_annual` 29,99 €/an (sans essai) — pour que le passage
  mensuel↔annuel soit un simple upgrade/downgrade dans le même groupe ;
  inscription au **Small Business Program**.
- Google Play Console : mêmes deux produits (mensuel + annuel) dans un seul
  abonnement à bases multiples (base plan mensuel avec phase d'essai 30j
  puis 15j à J+90, base plan annuel sans essai).
- Dashboard RevenueCat : projet, entitlement `pro`, offering par défaut,
  webhook vers le serveur (header `Authorization` = `REVENUECAT_WEBHOOK_SECRET`).

## Soumission App Store — rejet 2026-07-14 et corrections
1re soumission (v1.0 build 1, submission `9d90d366-d6fe-4dd4-8bda-724e49f5c447`,
review sur iPad Air M3 / iPadOS 26.5) **rejetée** sur 3 points. Les corrections
**code** sont livrées ; le reste est de la config externe (ASC / RevenueCat /
`env.prod.json`).

- **2.1(a) — « Pro page displays an error message »** *(code corrigé)*.
  Cause racine : le build de prod embarquait la **clé Test Store** RevenueCat
  (`REVENUECAT_API_KEY` absente de `env.prod.json`, repli sur le `defaultValue`
  `test_` dans `env.dart`) → `Purchases.getOfferings()` échoue sur l'appareil
  réel du reviewer → `PaywallStatus.failure` (écran d'erreur plein écran).
  Correction : garde-fou release (cf. *Mobile (Flutter)* ci-dessus). **Reste
  user** : renseigner la vraie clé `appl_...` dans `env.prod.json`.
- **3.1.2(b) — durées d'abonnement en produits IAP séparés** *(config ASC,
  aucun code)*. Le doc prévoyait bien **un seul subscription group** (cf.
  *Config stores*), mais l'App Store Connect réel avait créé
  `cocotte_399_1m_30d0` (mensuel) et `cocotte_2999_1y_0` (annuel) comme produits
  séparés. **Reste user** : les regrouper dans **un même Subscription Group**
  (garder les identifiants — RevenueCat lit par `$rc_monthly` / `$rc_annual`,
  aucun impact code).
- **3.1.2(c) — lien Terms of Use (EULA) manquant** *(code corrigé + metadata
  user)*. Choix retenu = **EULA standard Apple** (Option A) : pas de EULA custom,
  `termsS6` laissé générique. Correction code : les liens légaux sont désormais
  dans un `_LegalFooter` persistant (cf. *Écran d'offre*) — visibles même sur
  l'écran d'erreur, où ils disparaissaient avant. **Reste user** : lien EULA
  standard `https://www.apple.com/legal/internet-services/itunes/dev/stdeula/`
  dans la **description App Store** + URL de politique de confidentialité dans
  le champ dédié ASC.

**Checklist resoumission (100 % côté user, hors code)** :
1. Clé `appl_...` dans `env.prod.json`, rebuild `--dart-define-from-file`.
2. Un seul Subscription Group en ASC (IDs inchangés).
3. Soumettre les 2 produits IAP **avec** le build.
4. EULA standard dans la description + Privacy Policy URL en metadata ASC.
5. RevenueCat : produits rattachés à l'entitlement `pro` + offering courant ;
   **Sandbox Testing Access = « Anybody »** (piège confirmé le 2026-07-12).

Tests : `test/features/premium/premium_page_test.dart` couvre les liens légaux
visibles sur l'écran d'erreur (scénario reviewer).

## Règles métier
- Toute vérification de limite s'appuie sur `PremiumService.isPremium()`
  (projection DB), jamais sur un flag envoyé par le client.
- **Expiration / rétrogradation** (fin d'abonnement non renouvelé) : aucune
  donnée supprimée.
    - Sous-recettes au-delà de 5 : conservées et utilisables dans les recettes
      existantes, mais création de nouvelles bloquée tant que > 5.
    - Listes multiples : conservées en lecture, mais impossible d'en créer une
      nouvelle tant qu'il existe ≥ 1 liste active ; l'historique redevient
      inaccessible (les archives restent en base → re-débloquées si
      réabonnement).
    - Recherche : plafond 6 réappliqué immédiatement.
- Grace period / problème de facturation (BILLING_ISSUE) : suivre la période
  de grâce des stores relayée par RevenueCat (l'accès premium reste actif tant
  que RevenueCat annonce l'entitlement actif).
- Un seul statut premium par compte, pas de partage familial dans ce v1.

## Impacts sur les docs existants
- `limite-freemium.md` : la décision "paiement non intégré" est levée ; le
  plafond de critères passe de "6 ou 8" à 6 ; ce doc devient la référence
  d'implémentation.
- `list-courses-auto.md` : "plusieurs listes + historique" confirmé comme
  comportement premium uniquement (déjà signalé dans `limite-freemium.md`).
- `advanced-search.md` : le plafond hors scope de la 11a-e est implémenté ici.
- `PROJECT_CONTEXT.md` : "paiement réel hors scope V1" à mettre à jour.

## Hors scope
- Recherche IA locale (feature à part entière, premium à sa livraison).
- Marketplace / chef (V2).
- RevenueCat Web Billing / vente web sans commission (piste ultérieure).
- Export PDF de la liste de courses (candidat premium futur — la feuille
  d'export existante affiche déjà "à venir").
- Codes promo, offres de réduction, parrainage.
- Achat lifetime au lancement (schéma prêt via `premium_type`, produit store
  à créer plus tard).

## Décisions tranchées à l'implémentation (2026-07-09)
- Plafond de recherche gratuit : **6 critères** cumulés (confirmé).
- Paywall : **page Flutter maison** branchée sur les Offerings.
- Gestion d'abonnement : **Customer Center RevenueCat** inclus.
- Entitlement RevenueCat : **`pro`**.
- Secours admin : `premium_type` modifiable à la main en DB (aucun endpoint).

## Questions ouvertes / à trancher
- Prix et disponibilité de l'achat à vie (`lifetime`).
- Comportement du "clear" d'une liste gratuite : suppression définitive ou
  archivage invisible débloqué rétroactivement en premium (question héritée
  de `limite-freemium.md` — l'archivage invisible est déjà le comportement
  de fait : soft delete via `deletedAt`).
