# Feature — « Mes produits » (photos de produit par ingrédient)

> Item #14 du backlog. Permettre à l'utilisateur d'ajouter des photos du vrai
> produit qu'il achète, pour chaque ingrédient (aide-mémoire pour les courses).

## Décisions (validées)

- **Modèle** : galerie **séparée** « Mes produits », distincte de l'icône
  (emoji/image) de l'ingrédient. Nouvelle table par utilisateur.
- **Quota freemium** : **1 photo en gratuit, 3 en Pro**, par (utilisateur,
  ingrédient) — plafond réel même en Pro (comme la galerie recette).
- **Portée** : sur **tous** les ingrédients (catalogue système inclus). Les
  photos sont **scopées par utilisateur** (chacun voit les siennes).
- **Icône** : inchangée. La 1ère photo produit **ne devient pas** l'icône de
  l'ingrédient.

## Modèle de données

- Table `ingredient_photos` : `id`, `user_id`, `ingredient_id` (FK cascade),
  `image_url`, `created_at`. Pas de couplage avec `ingredients.image_url/emoji`.

## API (module ingredients — sous-domaine, service dédié)

- `GET /ingredients/:id/photos` → `IngredientPhotoDto[]` (mes photos, plus
  anciennes d'abord).
- `POST /ingredients/:id/photos` `{ imageUrl }` → liste à jour. Vérifie la
  visibilité de l'ingrédient + le quota (403 `PREMIUM_LIMIT_INGREDIENT_PHOTOS`).
- `DELETE /ingredients/:id/photos/:photoId` → 204. Supprime la photo (mienne) +
  son fichier Storage.

`IngredientPhotosService` (nouveau) : délègue la visibilité à
`IngredientsService.assertVisible`, gère quota + Storage. Le module ingredients
importe `BillingModule` (statut premium) + `SupabaseStorageService`.

## Mobile

- `IngredientsRepository` : `fetchProductPhotos`, `addProductPhoto`,
  `removeProductPhoto`.
- Écran ingrédient : section « Mes produits » — vignettes + bouton d'ajout
  (upload crop/compress via `pickCropUploadImage`, comme la galerie recette),
  suppression, et upsell sur le quota (`PREMIUM_LIMIT_INGREDIENT_PHOTOS`).
- i18n FR/EN.

## Hors périmètre V1

- La 1ère photo produit comme icône de l'ingrédient.
- Partage des photos entre utilisateurs.
- Association d'une photo à une marque/prix précis.
