import { Injectable, Logger } from '@nestjs/common';

import { IngredientsService } from '../ingredients/ingredients.service';

@Injectable()
export class AccountService {
  private readonly logger = new Logger(AccountService.name);

  constructor(private readonly ingredientsService: IngredientsService) {}

  /**
   * "Repartir de zéro" : supprime en cascade toutes les données métier liées à
   * l'utilisateur (recettes, sous-recettes, ingrédients personnalisés, tags,
   * listes de courses, ...). Le compte Supabase (auth) est conservé — seul son
   * contenu est effacé, ce qui revient à un compte vierge côté données.
   *
   * NB : l'auth étant la feature #1, aucune table métier n'existe encore dans le
   * schéma Drizzle. Cette méthode est le point d'ancrage extensible : chaque
   * feature ajoutera ici la suppression de ses tables `WHERE user_id = userId`,
   * dans une transaction unique pour garantir l'atomicité de la remise à zéro.
   */
  async resetGuestData(userId: string): Promise<void> {
    // Purge déléguée à chaque domaine via son service (isolation des modules).
    // TODO(features): brancher ici les autres domaines à mesure qu'ils arrivent
    //   (recettes, sous-recettes, tags, listes de courses...).
    await this.ingredientsService.deleteAllForUser(userId);
    this.logger.log(`Données invité réinitialisées pour l'utilisateur ${userId}`);
  }
}
