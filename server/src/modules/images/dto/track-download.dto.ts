import { IsUrl, MaxLength } from 'class-validator';

export class TrackDownloadDto {
  @IsUrl({ require_tld: false })
  @MaxLength(2048)
  downloadLocation!: string;
}
