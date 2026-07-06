import { IsUUID } from 'class-validator';

export class AddAlternativeDto {
  /** Id de l'ingrédient utilisateur à déclarer comme alternative (relation symétrique). */
  @IsUUID()
  alternativeId!: string;
}
