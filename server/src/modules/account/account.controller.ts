import { Controller, HttpCode, HttpStatus, Post, UseGuards } from '@nestjs/common';

import { AuthenticatedUser } from '../../common/auth/authenticated-user';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { SupabaseAuthGuard } from '../../common/guards/supabase-auth.guard';
import {
  AccountService,
  type CancelDeletionResult,
  type RequestDeletionResult,
} from './account.service';

@Controller('account')
@UseGuards(SupabaseAuthGuard)
export class AccountController {
  constructor(private readonly accountService: AccountService) {}

  /**
   * "Repartir de zéro" (cf. features/auth.md) : efface les données invité de
   * l'utilisateur courant après conversion de son compte anonyme.
   */
  @Post('reset-guest-data')
  @HttpCode(HttpStatus.NO_CONTENT)
  async resetGuestData(@CurrentUser() user: AuthenticatedUser): Promise<void> {
    await this.accountService.resetGuestData(user.id);
  }

  /**
   * Demande de suppression de compte (RGPD). Compte anonyme → suppression
   * immédiate ; compte complet → anonymisation + délai de 30 jours (rollback).
   */
  @Post('request-deletion')
  @HttpCode(HttpStatus.OK)
  async requestDeletion(@CurrentUser() user: AuthenticatedUser): Promise<RequestDeletionResult> {
    return this.accountService.requestDeletion(user);
  }

  /**
   * Annule une suppression en attente (tant que délai de 30 jours non dépassé).
   */
  @Post('cancel-deletion')
  @HttpCode(HttpStatus.OK)
  async cancelDeletion(@CurrentUser() user: AuthenticatedUser): Promise<CancelDeletionResult> {
    return this.accountService.cancelDeletion(user.id);
  }
}
