import { IsString, MaxLength, MinLength } from 'class-validator';

export class SearchImagesQueryDto {
  @IsString()
  @MinLength(1)
  @MaxLength(160)
  query!: string;
}
