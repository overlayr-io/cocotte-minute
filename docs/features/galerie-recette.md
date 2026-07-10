---
feature: galerie-recette
status: planned
scope: v1
depends_on: [recette-base, limite-freemium, premium-version]
order: 13
---

# Galerie de photos utilisateur (fiche recette)

## Problème résolu
Permettre à l'utilisateur de montrer et retrouver plus tard les photos de ses
propres réalisations d'une recette (résultat en cuisine), au-delà de la photo
de couverture unique déjà existante.

## Comportement attendu

### Emplacement et affichage
- Section "Galerie" sur la fiche recette (widget unique `recipe_detail_view.dart`
  — s'applique donc aux recettes normales **et** aux recettes de base, un seul
  et même écran), dans l'onglet **Ingrédients**, juste après le bloc
  "Sous-recettes utilisées" / "Utilisée dans".
- État vide : bouton incitatif type "Uploade ta première création".
- État non vide : grille de vignettes carrées + bouton "+" à droite du titre de
  section pour ajouter une photo.
- Clic sur une vignette : ouverture plein écran avec carrousel/slider pour
  naviguer entre les photos de la galerie de cette recette.

### Suppression
- Possible uniquement depuis la vue plein écran/carrousel (pas de suppression
  directe depuis la grille).
- Aucune autre action que la suppression (pas de recadrage a posteriori, pas
  de légende, pas de réordonnancement manuel).
- Réservée au propriétaire de la recette (mono-propriétaire, cohérent avec le
  reste du modèle) — pas d'association à une "Personne".

### Photo de couverture vs galerie (modèle séparé)
- La photo de couverture (`recipes.photoUrl`) reste un champ à part, **jamais
  comptabilisé** dans le quota de galerie.
- Si la recette n'a **aucune** photo de couverture au moment du premier upload
  de galerie, cette photo devient automatiquement la couverture — et **sort du
  quota de galerie** (elle n'apparaît plus dans la grille, uniquement en haut
  de la fiche).
- Ce mécanisme ne s'applique que si la recette n'avait aucune couverture au
  départ. Une recette qui a déjà une couverture (définie à la création) la
  garde, quels que soient les ajouts en galerie ensuite.
- Si la couverture issue de ce mécanisme est supprimée, la photo de galerie la
  plus ancienne restante prend automatiquement le relais comme nouvelle
  couverture (et sort à son tour du quota galerie). Si la galerie est vide, la
  recette revient à "pas de photo".
- Rappel (comportement existant, non modifié ici) : l'édition de recette
  (`recipe_edit_sheet.dart`) ne permet pas de changer la photo de couverture —
  seules la création initiale et ce mécanisme de galerie peuvent la
  définir/remplacer.

## Impact technique

### Server
- Nouvelle table `recipe_gallery_images` (`recipeId` FK → `recipes.id`,
  `onDelete: cascade`, `imageUrl`, `createdAt`) — stocke uniquement les photos
  "additionnelles", jamais la couverture.
- Vérification du quota (3 gratuit / 6 Pro) avant insertion : même pattern que
  `assertBaseRecipeQuota` dans `recipes.service.ts` (compte les lignes
  existantes, sinon vérifie `premiumService.isPremium`, sinon lève
  `PremiumLimitException` — nouveau code à ajouter dans `PREMIUM_LIMIT_CODES`).
- Nettoyage Storage Supabase : à la suppression d'une recette (soft delete),
  supprimer effectivement les fichiers Storage des photos de galerie associées
  (et de la couverture si issue de ce mécanisme) — comportement **plus strict
  que l'existant** (qui laisse aujourd'hui des fichiers orphelins pour la
  photo de couverture classique), spécifique à cette feature. Aucune reprise
  rétroactive des fichiers déjà orphelins créés avant cette feature.
- Endpoint d'ajout : reçoit l'URL déjà uploadée côté mobile (upload direct
  Flutter → Supabase Storage, le serveur ne fait qu'enregistrer l'URL,
  cohérent avec le pattern `ImageUploadService` existant).

### Mobile
- Réutilisation telle quelle du pipeline `ImageUploadPicker`/`image_cropper`
  existant (compression JPEG qualité 82, max 1600px) — pas de paramétrage
  spécifique pour la galerie.
- Validation avant upload : taille max 5 Mo, types `image/*` uniquement.
- Upload bloqué si pas de réseau (bouton désactivé ou message) — cohérent
  avec le reste des recettes (cache passif lecture seule, aucune écriture
  hors-ligne en dehors de la liste de courses).
- Quota atteint → clic sur "+" ouvre directement le paywall existant (même
  pattern que sous-recettes / liste de courses / recherche avancée).
- Nouvelle section dans `recipe_detail_view.dart` (voir emplacement ci-dessus).
- Nouveau widget de vue plein écran/carrousel, navigable entre les photos de
  la galerie de la recette affichée.

## Règles métier spécifiques
- Quota : 3 photos de galerie max en gratuit, 6 en Pro, **par recette**
  (indépendant du nombre total de recettes de l'utilisateur).
- Taille max par photo : 5 Mo, types `image/*` uniquement.
- Compression obligatoire à l'upload (pipeline existant, pas de nouveau
  paramétrage).
- Suppression uniquement par le propriétaire de la recette, depuis la vue
  plein écran/carrousel.
- Aucune écriture hors-ligne : upload bloqué sans réseau.

## Hors scope pour cette feature
- Modification d'une photo de galerie déjà uploadée (recadrage a posteriori,
  légende, réordonnancement manuel) — seule action possible : la suppression.
- Association d'une photo à une "Personne".
- Vue "toutes les galeries" cross-recettes (flux global des réalisations de
  l'utilisateur).
- Modification de la photo de couverture depuis le formulaire d'édition de
  recette (comportement existant, non traité ici).
- Nettoyage Storage rétroactif des photos de couverture déjà orphelines
  créées avant cette feature (chantier séparé).

## Questions ouvertes / à trancher
- Vérification des 5 Mo : sur le fichier original avant compression (rejet
  immédiat), ou seulement si le fichier compressé dépasse encore 5 Mo après
  coup ? Défaut proposé : vérifier l'original avant compression (rejet
  immédiat) — à confirmer si un autre comportement est souhaité.
- Libellé exact du bouton d'état vide ("Uploade ta première création" ou
  autre formulation) — à valider avec le design final.
- Nombre de colonnes / ratio exact de la grille (maquette : 3 colonnes, ratio
  carré) — à confirmer tel quel ou à adapter.
