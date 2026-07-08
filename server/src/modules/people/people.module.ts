import { Module } from '@nestjs/common';

import { TagsModule } from '../tags/tags.module';
import { PeopleController } from './people.controller';
import { PeopleService } from './people.service';

@Module({
  // Importe TagsModule pour hydrater/valider les tags associés via son service
  // exporté (jamais son schéma) — isolation des domaines.
  imports: [TagsModule],
  controllers: [PeopleController],
  providers: [PeopleService],
  // Exporté pour qu'AccountService puisse purger les personnes lors du
  // "repartir de zéro".
  exports: [PeopleService],
})
export class PeopleModule {}
