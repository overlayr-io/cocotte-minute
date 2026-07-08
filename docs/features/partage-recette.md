---
feature: partage-recette
status: done        # planned | in-progress | done
scope: v1           # v1 | v2 | later
depends_on: [recette-base, recette-etapes, auth]
order: 12
---

# Partage & export d'une recette

> **État de livraison (v1).** Rendu dérivé des maquettes du bundle design
> « Recette Web » (feuille A4 2 colonnes) et « Recette Mobile » (carte). Feuille
> « Partager » validée avant implémentation (Explore → Plan → Design → code).

## Problème résolu

Permettre de **sortir une recette de l'app** : l'exporter en PDF imprimable, ou
la partager via un **lien public** (message, réseaux) qui ouvre une page web
lisible sans compte — et, si l'app est installée, la recette directement dans
l'app (universal / app links).

## Comportement attendu

### Point d'entrée
Depuis le menu « … » de la fiche recette, une feuille **« Partager la recette »** :
- **Exporter en PDF** — feuille A4 imprimable (cf. rendu ci-dessous), partagée via
  la feuille OS (`Printing.sharePdf`).
- **Copier le lien** — génère (ou réutilise) un lien de partage public et le copie
  dans le presse-papiers.
- **Partager…** — même lien, envoyé via la feuille de partage OS (`share_plus`).

### Rendu PDF (« page 1 » du design)
`RecipePdfService` (`pdf` + `printing`, polices Bricolage/Hanken bundlées) — A4,
deux colonnes qui paginent (`pw.Partitions`) :
- en-tête : eyebrow « Recette », titre, description, photo ;
- bandeau méta : **Personnes / Préparation / Cuisson / Repos** (tuiles présentes
  seulement si la donnée existe) ;
- colonne gauche **Ingrédients** (cases à cocher, quantité en vert) ;
- colonne droite **Préparation** (étapes numérotées, bannières, sous-recettes
  dépliées en blocs `a/b/c`) ;
- sous-recettes utilisées en pied (pleine largeur), footer signé + pagination.

### Lien public & page web (« page 2 » responsive)
- `GET /r/:token` sert une **page web autonome** réutilisant le design : feuille
  A4 sur desktop, carte empilée sur mobile. Balises Open Graph (titre / desc /
  image) pour un aperçu propre en messagerie.
- `GET /share/:token` renvoie la même fiche en **JSON** (consommée par l'app
  après un deep link).

### Deep linking
- L'app capte `https://<domaine>/r/<token>` (universal / app links) et le scheme
  de repli `cocotteminute://r/<token>` (`app_links` → `DeepLinkService`).
- Résolution du token → si la recette **appartient à l'utilisateur courant**,
  bascule vers la fiche complète (éditable) ; sinon, écran **lecture seule**
  (`SharedRecipePage`).

## Impact technique

### Serveur (module `shares`)
- Table `recipe_shares` (`token` opaque URL-safe, révocable via `revoked_at`) —
  migration `0010_recipe_shares`.
- `POST /recipes/:id/share` (authentifié, **propriétaire uniquement**) → `{token, url}`.
- `GET /share/:token` (public) → `RecipeDetailDto` en lecture seule.
- `GET /r/:token` (public) → page web HTML.
- `GET /.well-known/apple-app-site-association` + `assetlinks.json` (association
  deep link).
- `RecipesService.getPublicDetail()` (hydratation depuis l'auteur, sans contrôle
  de propriété) + `assertOwnedRecipe()` (isolation des domaines préservée).
- Env : `PUBLIC_BASE_URL`, `APPLE_APP_ID`, `ANDROID_CERT_SHA256`.

### Mobile
- Feuille `ShareRecipeSheet` ; `RecipesRepository.createShareLink()` /
  `fetchByShareToken()`.
- `DeepLinkService` (`app_links`) + `appNavigatorKey` ; `SharedRecipeCubit` /
  `SharedRecipePage` (lecture seule).
- Dép. `share_plus`, `app_links`.

## Prérequis de déploiement (placeholders `TODO_*` à renseigner)

| Élément | Où | Valeur |
|---|---|---|
| Domaine public | `PUBLIC_BASE_URL` (serveur), `AndroidManifest` (`android:host`), `Runner.entitlements` (`applinks:`) | ex. `https://cocotte.example` |
| App ID iOS | `APPLE_APP_ID` (AASA) | `<TeamID>.com.cocotteminute.cocotteMinute` |
| Entitlements iOS | lier `ios/Runner/Runner.entitlements` au target dans Xcode (Associated Domains) | — |
| Empreinte Android | `ANDROID_CERT_SHA256` (assetlinks.json) | SHA256 du certificat de signing |

Tant que ces valeurs ne sont pas renseignées : le **scheme custom** iOS/Android
fonctionne, mais les **universal / app links** (https) non.

## Décisions & écarts assumés
- **Difficulté** : la maquette montre une tuile « Difficulté » — champ absent du
  modèle `Recipe`. Remplacée par **Repos** (`restTime`), **sans migration**.
- **Astuce** : encart « Astuce » de la maquette — pas de champ dédié — **omis**
  (réactivable si un champ `tip` est ajouté plus tard).
- **Lien = recette publique** : le token expose la recette en lecture seule à
  quiconque a le lien. Révocable (`revoked_at`) sans toucher la recette.

## Hors scope v1
- Partage en **image** (carte mobile rendue en PNG) — non retenu (le lien + la
  page web couvrent le besoin de partage visuel).
- Gestion fine des liens (liste, révocation depuis l'app, expiration) — la
  structure le permet (`revoked_at`) mais l'UI n'est pas exposée.
- Permissions granulaires / recette collaborative.
