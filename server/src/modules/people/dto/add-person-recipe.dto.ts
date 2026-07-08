import { IsUUID } from 'class-validator';

export class AddPersonRecipeDto {
  @IsUUID()
  recipeId!: string;
}
