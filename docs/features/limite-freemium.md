---
feature: limite-freemium
status: planned
scope: v1 (documentation seulement — implémentation reportée après v1 fonctionnel, paiement non intégré cf. décision actée précédemment)
depends_on: [auth, sous-recette, liste-courses-auto, recherche-avancee]
order: 10
---

# Limites freemium / abonnement premium

## Problème résolu
Définir les limites du plan gratuit et ce que débloque l'abonnement premium,
pour orienter la conception des features déjà documentées sans encore
intégrer de logique de paiement réelle (Stripe/RevenueCat reporté après
le v1 fonctionnel, décision actée précédemment).

## Offre envisagée
- Abonnement à 3,99€/mois, avec 15 jours d'essai gratuit.
- Statut premium simple (`is_premium` ou équivalent) déjà prévu dans
  `PROJECT_CONTEXT.md`, indépendant du mode de paiement.

## Limites du plan gratuit

### Recettes de base (sous-recettes)
- Maximum 5 sous-recettes créées en gratuit (déjà acté dans
  `PROJECT_CONTEXT.md` et `sous-recette`).
- Illimité en premium.

### Liste de courses
- **1 seule liste active à la fois** en gratuit. L'utilisateur doit "clear"
  (vider/clôturer) sa liste actuelle avant d'en recréer une nouvelle.
- En premium : accès à plusieurs listes en parallèle + un onglet historique
  des listes passées.
- ⚠️ Impact sur `liste-courses-auto.md` : le comportement "plusieurs listes
  en parallèle, garder un historique" documenté précédemment est en réalité
  **le comportement premium uniquement**. Le gratuit est restreint à une
  seule liste active, sans historique.

### Recherche avancée — nombre de critères cumulables
- Limite en gratuit : un total de critères sélectionnés cumulés, tous types
  confondus (personnes + tags + texte de recherche + catégories sélectionnées),
  plafonné à un nombre max (6 ou 8, à trancher précisément).
    - Exemple donné : 2 personnes + 3 tags + 1 texte de recherche = 6 critères
      au total.
    - Une catégorie/dossier sélectionné comme scope compte également comme
      1 critère dans ce total (si 3 dossiers sélectionner alors 3 critères).
- Illimité en premium.
- ⚠️ Impact sur `recherche-avancee.md` : la logique ET sur les filtres reste
  valable, mais un plafond de critères cumulés au total (pas par famille de
  filtre) doit être ajouté pour le compte gratuit.

### Recherche IA locale
- Fonctionnalité réservée entièrement au premium (aucun accès en gratuit).

### Marketplace (chef)
- Prévue comme feature premium plus tard (V2), pas dans ce v1.

## Impact technique
- Server : validation des limites côté server obligatoire (cohérent avec
  la règle déjà actée pour les sous-recettes) — jamais une vérification
  uniquement côté UI.
    - Compteur de sous-recettes par utilisateur (déjà prévu).
    - Vérification "1 liste de courses active max" avant création d'une nouvelle
      liste si non-premium.
    - Vérification du total de critères de recherche envoyés dans la requête
      si non-premium.
- Mobile : affichage clair des limites atteintes + incitation à l'abonnement
  (UI à définir), sans bloquer l'usage de base des features concernées.

## Règles métier spécifiques
- Toutes les vérifications de limite doivent se baser sur le champ de statut
  premium simple déjà prévu, pas sur une logique de paiement réelle (non
  implémentée dans ce v1).

## Hors scope pour cette feature
- Toute intégration réelle de paiement (Stripe/RevenueCat) — reportée après
  le v1 fonctionnel, décision déjà actée.
- Logique d'essai gratuit de 15 jours (dépend de l'intégration paiement réelle,
  non implémentable sans elle).

## Questions ouvertes / à trancher
- Plafond exact du nombre de critères de recherche : 6 ou 8, à trancher
  précisément avant l'implémentation.
- D'autres limites potentielles à ajouter pour renforcer l'incitation à
  l'abonnement (mentionné comme "à enrichir" mais pas encore précisé) —
  liste non figée, à compléter avant l'implémentation réelle de cette feature.
- Que se passe-t-il exactement au clear d'une liste de courses gratuite :
  suppression définitive (aucune trace), ou passage en "archivée" invisible
  tant que non-premium (débloquée rétroactivement si abonnement pris plus tard) ?