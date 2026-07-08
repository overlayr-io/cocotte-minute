import { Transform } from 'class-transformer';
import { IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

/**
 * Message envoyé depuis « Nous contacter ». `appVersion` est facultatif : le
 * mobile le renseigne (package_info) pour faciliter le support, mais un client
 * qui ne le fournit pas reste accepté.
 */
export class ContactDto {
  @IsString()
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @MinLength(1)
  @MaxLength(120)
  subject!: string;

  @IsString()
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @MinLength(1)
  @MaxLength(4000)
  message!: string;

  @IsOptional()
  @IsString()
  @MaxLength(40)
  appVersion?: string;
}
