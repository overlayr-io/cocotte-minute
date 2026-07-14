import { IsUrl, MaxLength } from 'class-validator';

/** Ajout d'une photo « Mes produits » : URL Storage déjà uploadée côté mobile. */
export class AddIngredientPhotoDto {
  @IsUrl({ require_tld: false })
  @MaxLength(2048)
  imageUrl!: string;
}
