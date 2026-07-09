import { Module } from '@nestjs/common';

import { BillingController } from './billing.controller';
import { BillingService } from './billing.service';
import { PremiumService } from './premium.service';
import { RevenueCatAdminService } from './revenuecat-admin.service';

/**
 * Domaine facturation/premium : webhook RevenueCat (écriture de la projection),
 * lecture du droit d'accès, admin REST RevenueCat (suppression RGPD).
 * Cf. features/premium-version.md. Les autres modules n'importent que les
 * services exportés — jamais le schéma `accounts` directement.
 */
@Module({
  controllers: [BillingController],
  providers: [BillingService, PremiumService, RevenueCatAdminService],
  exports: [PremiumService, RevenueCatAdminService],
})
export class BillingModule {}
