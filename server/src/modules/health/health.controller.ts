import { Controller, Get, UseGuards } from '@nestjs/common';

import { AuthenticatedUser } from '../../common/auth/authenticated-user';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { SupabaseAuthGuard } from '../../common/guards/supabase-auth.guard';

@Controller('health')
export class HealthController {
  /** Sonde de liveness publique. */
  @Get()
  check(): { status: string } {
    return { status: 'ok' };
  }

  /** Démo du guard + décorateur : renvoie l'identité extraite du JWT Supabase. */
  @UseGuards(SupabaseAuthGuard)
  @Get('me')
  me(@CurrentUser() user: AuthenticatedUser): AuthenticatedUser {
    return user;
  }
}
