import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';

import { AccountService } from './account.service';

/**
 * Job CRON RGPD (cf. auth.md) : chaque nuit, supprime définitivement en cascade
 * les comptes `pending_deletion` dont le délai de 30 jours est dépassé.
 *
 * La logique métier vit dans AccountService.purgeExpiredDeletions ; ce provider
 * ne fait que la planifier (Single Responsibility). Nécessite
 * `ScheduleModule.forRoot()` enregistré dans l'AppModule.
 */
@Injectable()
export class AccountDeletionCron {
  private readonly logger = new Logger(AccountDeletionCron.name);

  constructor(private readonly accountService: AccountService) {}

  @Cron(CronExpression.EVERY_DAY_AT_3AM, { name: 'account-hard-deletion' })
  async handleExpiredDeletions(): Promise<void> {
    try {
      await this.accountService.purgeExpiredDeletions();
    } catch (err) {
      // Ne jamais laisser une exception faire tomber le scheduler.
      this.logger.error('Échec du job de suppression RGPD', err as Error);
    }
  }
}
