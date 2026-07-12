import { Body, Controller, Get, Param, ParseUUIDPipe, Put, UseGuards } from '@nestjs/common';

import { AuthenticatedUser } from '../../common/auth/authenticated-user';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { SupabaseAuthGuard } from '../../common/guards/supabase-auth.guard';
import { UpsertIngredientPriceDto } from './dto/upsert-ingredient-price.dto';
import { IngredientPriceDto, IngredientPricesService } from './ingredient-prices.service';

@Controller('ingredient-prices')
@UseGuards(SupabaseAuthGuard)
export class IngredientPricesController {
  constructor(private readonly ingredientPricesService: IngredientPricesService) {}

  /** Tous mes prix ingrédients — alimente le cache offline mobile. */
  @Get()
  listMine(@CurrentUser() user: AuthenticatedUser): Promise<IngredientPriceDto[]> {
    return this.ingredientPricesService.listMine(user.id);
  }

  @Put(':ingredientId')
  upsert(
    @CurrentUser() user: AuthenticatedUser,
    @Param('ingredientId', ParseUUIDPipe) ingredientId: string,
    @Body() dto: UpsertIngredientPriceDto,
  ): Promise<IngredientPriceDto> {
    return this.ingredientPricesService.upsert(user.id, ingredientId, dto);
  }
}
