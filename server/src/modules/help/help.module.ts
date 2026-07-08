import { Module } from '@nestjs/common';

import { HelpController } from './help.controller';
import { HelpService } from './help.service';

/** Centre d'aide : FAQ (contenu éditorial) + réception des messages de contact. */
@Module({
  controllers: [HelpController],
  providers: [HelpService],
})
export class HelpModule {}
