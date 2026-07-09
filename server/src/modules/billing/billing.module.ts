import { Module } from '@nestjs/common';

import { PremiumService } from './premium.service';

/**
 * Domaine facturation/premium : projection du statut RevenueCat et lecture
 * du droit d'accès (cf. features/premium-version.md). Les autres modules
 * n'importent que `PremiumService` — jamais le schéma `accounts` directement.
 */
@Module({
  providers: [PremiumService],
  exports: [PremiumService],
})
export class BillingModule {}
