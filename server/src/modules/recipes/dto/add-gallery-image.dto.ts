import { IsUrl, MaxLength } from 'class-validator';

/**
 * Ajout d'une photo de galerie (feature galerie-recette). L'image est déjà
 * uploadée côté mobile vers Supabase Storage ; le serveur ne reçoit que son URL
 * publique (même pattern que `photoUrl` à la création de recette).
 */
export class AddGalleryImageDto {
  @IsUrl({ require_tld: false })
  @MaxLength(2048)
  imageUrl!: string;
}
