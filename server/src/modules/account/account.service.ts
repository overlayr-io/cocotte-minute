import { Inject, Injectable, Logger } from '@nestjs/common';

import { DRIZZLE, DrizzleDB } from '../../db/drizzle.provider';

@Injectable()
export class AccountService {
  private readonly logger = new Logger(AccountService.name);

  constructor(@Inject(DRIZZLE) private readonly db: DrizzleDB) {}

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
    await this.db.transaction(async (tx) => {
      // TODO(features): à mesure que les tables métier arrivent, supprimer ici
      // les lignes appartenant à `userId` (ordre respectant les FK), ex :
      //   await tx.delete(shoppingLists).where(eq(shoppingLists.userId, userId));
      //   await tx.delete(recipes).where(eq(recipes.userId, userId));
      void tx;
      void userId;
    });
    this.logger.log(`Données invité réinitialisées pour l'utilisateur ${userId}`);
  }
}
