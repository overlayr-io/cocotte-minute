import { Body, Controller, Get, HttpCode, HttpStatus, Post, Query, UseGuards } from '@nestjs/common';

import { SupabaseAuthGuard } from '../../common/guards/supabase-auth.guard';
import { SearchImagesQueryDto } from './dto/search-images-query.dto';
import { TrackDownloadDto } from './dto/track-download.dto';
import { ImageSuggestionDto, UnsplashService } from './unsplash.service';

@Controller('images')
@UseGuards(SupabaseAuthGuard)
export class ImagesController {
  constructor(private readonly unsplash: UnsplashService) {}

  @Get('search')
  search(@Query() query: SearchImagesQueryDto): Promise<ImageSuggestionDto[]> {
    return this.unsplash.search(query.query);
  }

  /**
   * À appeler dès qu'une suggestion est effectivement utilisée (photo posée
   * sur une recette) — condition d'accès production de l'API Unsplash.
   */
  @Post('track-download')
  @HttpCode(HttpStatus.NO_CONTENT)
  trackDownload(@Body() dto: TrackDownloadDto): Promise<void> {
    return this.unsplash.trackDownload(dto.downloadLocation);
  }
}
