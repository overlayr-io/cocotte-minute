import { Transform } from 'class-transformer';
import {
  IsIn,
  IsNotEmpty,
  IsString,
  IsUUID,
  Matches,
  MaxLength,
  ValidateIf,
} from 'class-validator';

import {
  MEAL_ENTRY_TYPES,
  MEAL_SLOTS,
  MealEntryType,
  MealSlot,
} from '../../../db/schema/meal-plan.schema';

/** Ajout d'une entrée sur un créneau du planning (écrans 2a/2c). */
export class CreateMealPlanEntryDto {
  /** Jour planifié, `YYYY-MM-DD`. */
  @Matches(/^\d{4}-\d{2}-\d{2}$/)
  day!: string;

  @IsIn(MEAL_SLOTS)
  slot!: MealSlot;

  @IsIn(MEAL_ENTRY_TYPES)
  entryType!: MealEntryType;

  /** Requis pour une entrée `recipe`, interdit sinon. */
  @ValidateIf((o: CreateMealPlanEntryDto) => o.entryType === 'recipe')
  @IsUUID()
  recipeId?: string;

  /** Requis pour une entrée `note`, interdit sinon. */
  @ValidateIf((o: CreateMealPlanEntryDto) => o.entryType === 'note')
  @IsString()
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @IsNotEmpty()
  @MaxLength(160)
  noteText?: string;
}
