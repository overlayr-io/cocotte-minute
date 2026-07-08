import { Transform } from 'class-transformer';
import { IsIn, IsString, MaxLength, MinLength } from 'class-validator';

import { TAG_COLORS, type TagColor } from '../../../db/schema/tags.schema';

export class CreateTagDto {
  @IsString()
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @MinLength(1)
  @MaxLength(60)
  name!: string;

  @IsIn(TAG_COLORS)
  color!: TagColor;
}
