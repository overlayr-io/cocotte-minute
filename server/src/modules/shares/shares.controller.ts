import { Controller, Param, ParseUUIDPipe, Post, UseGuards } from '@nestjs/common';

import { CurrentUser } from '../../common/decorators/current-user.decorator';
import type { AuthenticatedUser } from '../../common/auth/authenticated-user';
import { SupabaseAuthGuard } from '../../common/guards/supabase-auth.guard';
import { ShareLinkDto, SharesService } from './shares.service';

/**
 * Génération d'un lien de partage — route authentifiée : seul le propriétaire d'une
 * recette peut créer son lien. Montée sous `recipes/` pour rester proche de la
 * ressource (`POST /recipes/:id/share`) ; la lecture publique vit dans un contrôleur
 * séparé, non gardé (`PublicSharesController`).
 */
@Controller('recipes')
@UseGuards(SupabaseAuthGuard)
export class SharesController {
  constructor(private readonly sharesService: SharesService) {}

  @Post(':id/share')
  create(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<ShareLinkDto> {
    return this.sharesService.createShareLink(user.id, id);
  }
}
