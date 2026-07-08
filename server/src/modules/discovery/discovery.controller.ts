import { Controller, Get, UseGuards } from '@nestjs/common';

import { AuthenticatedUser } from '../../common/auth/authenticated-user';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { SupabaseAuthGuard } from '../../common/guards/supabase-auth.guard';
import { DiscoveryHomeDto, DiscoveryService } from './discovery.service';

@Controller('discovery')
@UseGuards(SupabaseAuthGuard)
export class DiscoveryController {
  constructor(private readonly discoveryService: DiscoveryService) {}

  /** Données de la vue Découverte de l'Accueil (recettes enrichies + personnes + dossiers). */
  @Get('home')
  getHome(@CurrentUser() user: AuthenticatedUser): Promise<DiscoveryHomeDto> {
    return this.discoveryService.getHome(user.id);
  }
}
