---
feature: galerie-recette
status: done
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
- **Écart d'implémentation (validé au rendu)** : le relais automatique
  « la photo de galerie la plus ancienne devient couverture quand la couverture
  empruntée est supprimée » **n'a pas été codé**. L'ajout d'une action
  « Changer la photo » (voir ci-dessous) rend ce chemin inatteignable — il n'y a
  plus d'état où la couverture redevient vide sans qu'une nouvelle soit fournie
  dans la foulée. À rouvrir seulement si un bouton « retirer la couverture »
  (sans remplacement) est un jour ajouté.
- **Écart d'implémentation (validé au rendu)** : contrairement au texte initial
  (« l'édition de recette ne permet pas de changer la couverture »), une action
  **« Changer la photo »** a été ajoutée au menu « … » de la fiche recette
  (`recipe_detail_view.dart`). Elle remplace la couverture à tout moment
  (couverture empruntée ou définie à la création), via `PATCH /recipes/:id`
  (`photoUrl`) ; l'ancien fichier Storage est supprimé au remplacement. C'était
  nécessaire car **aucune** surface existante ne permettait de changer la
  couverture après la création. Le formulaire d'édition
  (`recipe_edit_sheet.dart`) reste inchangé (ne touche toujours pas la photo).

## Impact technique

### Server
- Nouvelle table `recipe_gallery_images` (`recipeId` FK → `recipes.id`,
  `onDelete: cascade`, `imageUrl`, `createdAt`) — stocke uniquement les photos
  "additionnelles", jamais la couverture. Migration `0016_recipe_gallery.sql`.
- **Placement (écart validé au rendu)** : pas de module NestJS séparé — la
  galerie est un **sous-domaine du module recettes** (`RecipeGalleryService` /
  `RecipeGalleryController` dans `modules/recipes/`), monté en
  `/recipes/:id/gallery`, cohérent avec les ingrédients/étapes/composants déjà
  gérés dans ce module (et non dans des modules séparés). Cela évite aussi une
  dépendance circulaire (la galerie a besoin de `RecipesService`, et
  `RecipesService` a besoin des URLs de galerie pour le nettoyage).
- Vérification du quota (3 gratuit / 6 Pro **par recette**) avant insertion :
  compte les lignes existantes, `premiumService.isPremium` fixe la limite
  (`6` ou `3`), sinon lève `PremiumLimitException` (nouveau code
  `PREMIUM_LIMIT_GALLERY_PHOTOS`). **Le plafond existe même en Pro** (ce n'est
  pas « illimité » comme les autres quotas) : le message d'exception est neutre,
  et le mobile n'affiche l'upsell qu'aux comptes gratuits (voir Mobile).
- Nettoyage Storage Supabase (`SupabaseStorageService`, REST `service_role`,
  best-effort, sur le modèle de `SupabaseAdminService`) : câblé à la suppression
  d'une photo de galerie, au **remplacement de couverture** (`PATCH`), au **soft
  delete** d'une recette (qui ne déclenche aucune cascade FK), et à la **purge
  de compte** (`deleteAllForUser`). À la suppression d'une recette, la couverture
  est supprimée aussi, quelle que soit son origine (le fichier n'est plus
  référencé de toute façon) — comportement **plus strict que l'existant**.
  Aucune reprise rétroactive des fichiers déjà orphelins créés avant cette
  feature.
- Endpoint d'ajout : reçoit l'URL déjà uploadée côté mobile (upload direct
  Flutter → Supabase Storage, le serveur ne fait qu'enregistrer l'URL,
  cohérent avec le pattern `ImageUploadService` existant). Le 1er upload sur une
  recette sans couverture la définit comme couverture (`setPhotoIfEmpty`,
  atomique) au lieu d'entrer en galerie (hors quota). `galleryPhotos` est exposé
  dans `RecipeDetailDto`.

### Mobile
- Réutilisation telle quelle du pipeline `ImageUploadPicker`/`image_cropper`
  existant (compression JPEG qualité 82, max 1600px) — pas de paramétrage
  spécifique pour la galerie.
- Validation avant upload : taille max 5 Mo, types `image/*` uniquement.
- Upload bloqué si pas de réseau (bouton désactivé ou message) — cohérent
  avec le reste des recettes (cache passif lecture seule, aucune écriture
  hors-ligne en dehors de la liste de courses).
- Quota atteint → clic sur "+" : garde côté client avant même d'ouvrir le
  picker (le serveur reste la vérité). **En gratuit** : paywall existant
  (`showPremiumLimitSheet`, nouveau cas galerie). **En Pro (6/6)** : simple
  message « limite atteinte » (rien à vendre à un compte déjà Pro) — écart
  assumé par rapport aux autres quotas, validé au rendu.
- Nouvelle section `RecipeGallerySection` dans `recipe_detail_view.dart` (onglet
  Ingrédients, après les sous-recettes) : grille 3 colonnes, état vide incitatif,
  bouton `+` avec badge `x/limite`.
- Nouveau `gallery_viewer_page.dart` : vue plein écran (`PageView` +
  `InteractiveViewer` pour le zoom, sans dépendance ajoutée), navigable entre
  les photos, suppression confirmée (seule action). Réservée au propriétaire
  (la fiche `recipe_detail_view.dart` n'est ouverte que par le propriétaire).
- Helper `pickCropUploadImage` (`core/storage/image_pick_upload.dart`) : extrait
  le pipeline pick → crop/compression (JPEG 82, ≤1600px) → upload, réutilisé par
  la galerie (crop libre) et « Changer la photo » (ratio 4:3). Contrôle des 5 Mo
  sur le fichier **original avant compression** (rejet immédiat).

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

## Décisions prises à l'implémentation
- Vérification des 5 Mo : **sur le fichier original avant compression** (rejet
  immédiat) — défaut proposé retenu.
- Libellé du bouton d'état vide : **« Uploade ta première création »** (défaut
  proposé retenu ; aucune maquette d'état vide n'était fournie).
- Grille : **3 colonnes, vignettes carrées** (`object-fit: cover`), conforme à
  l'écran 2d. Les photos sont recadrées librement à l'upload (pas de ratio
  imposé) ; le carré n'est qu'un cadrage d'affichage.
- Badge de comptage : **`x/limite`** (`4/6`) plutôt que le nombre brut « 18 » de
  la maquette (illustratif) — reflète le quota réel.
- Quota Pro plafonné à 6 (pas illimité) → message au lieu du paywall ; menu
  « Changer la photo » ajouté ; relais automatique de couverture abandonné.
  Voir « Écart d'implémentation » dans les sections ci-dessus.
