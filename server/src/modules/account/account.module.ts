import { Module } from '@nestjs/common';

import { IngredientsModule } from '../ingredients/ingredients.module';
import { AccountController } from './account.controller';
import { AccountService } from './account.service';

@Module({
  // Importe IngredientsModule pour purger les ingrédients via son service exporté
  // (jamais son schéma) lors du "repartir de zéro".
  imports: [IngredientsModule],
  controllers: [AccountController],
  providers: [AccountService],
})
export class AccountModule {}
