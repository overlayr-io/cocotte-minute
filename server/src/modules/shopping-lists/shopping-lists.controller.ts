import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';

import { AuthenticatedUser } from '../../common/auth/authenticated-user';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { SupabaseAuthGuard } from '../../common/guards/supabase-auth.guard';
import { CreateShoppingListDto } from './dto/create-shopping-list.dto';
import {
  AddShoppingListItemDto,
  UpdateShoppingListItemDto,
} from './dto/shopping-list-item.dto';
import { UpdateShoppingListDto } from './dto/update-shopping-list.dto';
import {
  ShoppingListDetailDto,
  ShoppingListItemDto,
  ShoppingListsService,
  ShoppingListSummaryDto,
} from './shopping-lists.service';

@Controller('shopping-lists')
@UseGuards(SupabaseAuthGuard)
export class ShoppingListsController {
  constructor(private readonly shoppingListsService: ShoppingListsService) {}

  /** Mes listes actives (gratuit : une seule ; l'écran 5a n'en affiche qu'une). */
  @Get()
  listMine(
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<ShoppingListSummaryDto[]> {
    return this.shoppingListsService.listMine(user.id);
  }

  @Get(':id')
  getDetail(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<ShoppingListDetailDto> {
    return this.shoppingListsService.getDetail(user.id, id);
  }

  /** Génère une liste à partir de recettes + parts + placard (5b → 5d). */
  @Post()
  generate(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreateShoppingListDto,
  ): Promise<ShoppingListDetailDto> {
    return this.shoppingListsService.generate(user.id, dto);
  }

  @Patch(':id')
  rename(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateShoppingListDto,
  ): Promise<ShoppingListSummaryDto> {
    return this.shoppingListsService.rename(user.id, id, dto);
  }

  /** « Vider » la liste (soft delete — pas d'historique en gratuit). */
  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  clear(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<void> {
    return this.shoppingListsService.clear(user.id, id);
  }

  /** Ajoute un article libre (hors recette). */
  @Post(':id/items')
  addItem(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: AddShoppingListItemDto,
  ): Promise<ShoppingListItemDto> {
    return this.shoppingListsService.addItem(user.id, id, dto);
  }

  /** Coche/décoche un article ou lui applique une alternative (5h). */
  @Patch(':id/items/:itemId')
  updateItem(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Param('itemId', ParseUUIDPipe) itemId: string,
    @Body() dto: UpdateShoppingListItemDto,
  ): Promise<ShoppingListItemDto> {
    return this.shoppingListsService.updateItem(user.id, id, itemId, dto);
  }

  @Delete(':id/items/:itemId')
  @HttpCode(HttpStatus.NO_CONTENT)
  removeItem(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Param('itemId', ParseUUIDPipe) itemId: string,
  ): Promise<void> {
    return this.shoppingListsService.removeItem(user.id, id, itemId);
  }
}
