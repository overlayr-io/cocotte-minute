import { Module } from '@nestjs/common';

import { ImagesController } from './images.controller';
import { UnsplashService } from './unsplash.service';

@Module({
  controllers: [ImagesController],
  providers: [UnsplashService],
})
export class ImagesModule {}
