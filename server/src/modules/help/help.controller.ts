import { Body, Controller, Get, HttpCode, HttpStatus, Post, UseGuards } from '@nestjs/common';

import { AuthenticatedUser } from '../../common/auth/authenticated-user';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { SupabaseAuthGuard } from '../../common/guards/supabase-auth.guard';
import { ContactDto } from './dto/contact.dto';
import { FaqEntryDto, HelpService } from './help.service';

@Controller('help')
@UseGuards(SupabaseAuthGuard)
export class HelpController {
  constructor(private readonly helpService: HelpService) {}

  /** FAQ du centre d'aide (contenu éditorial, servi depuis faq.json). */
  @Get('faq')
  listFaq(): FaqEntryDto[] {
    return this.helpService.listFaq();
  }

  /** Message « Nous contacter ». Journalisé avec l'identité et la version d'app. */
  @Post('contact')
  @HttpCode(HttpStatus.ACCEPTED)
  submitContact(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: ContactDto,
  ): { status: 'received' } {
    return this.helpService.submitContact(user, dto);
  }
}
