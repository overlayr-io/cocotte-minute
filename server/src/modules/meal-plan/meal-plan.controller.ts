import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';

import { AuthenticatedUser } from '../../common/auth/authenticated-user';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { SupabaseAuthGuard } from '../../common/guards/supabase-auth.guard';
import { CreateMealPlanEntryDto } from './dto/create-meal-plan-entry.dto';
import { MealPlanEntryDto, MealPlanService } from './meal-plan.service';

@Controller('meal-plan')
@UseGuards(SupabaseAuthGuard)
export class MealPlanController {
  constructor(private readonly mealPlanService: MealPlanService) {}

  /** Entrées de la semaine `weekStart` (un lundi, YYYY-MM-DD). */
  @Get()
  listWeek(
    @CurrentUser() user: AuthenticatedUser,
    @Query('weekStart') weekStart: string,
  ): Promise<MealPlanEntryDto[]> {
    return this.mealPlanService.listWeek(user.id, weekStart ?? '');
  }

  /** Ajoute une entrée (recette / manger dehors / note) sur un créneau. */
  @Post('entries')
  addEntry(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreateMealPlanEntryDto,
  ): Promise<MealPlanEntryDto> {
    return this.mealPlanService.addEntry(user.id, dto);
  }

  /** Retire une entrée d'un créneau. */
  @Delete('entries/:id')
  @HttpCode(HttpStatus.NO_CONTENT)
  async removeEntry(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<void> {
    await this.mealPlanService.removeEntry(user.id, id);
  }
}
