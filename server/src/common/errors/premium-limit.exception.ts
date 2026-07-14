import { ForbiddenException } from '@nestjs/common';

/**
 * Codes de limite freemium (cf. features/premium-version.md — « Application
 * des limites »). Identifiants stables consommés par le mobile pour afficher
 * la feuille d'upsell adaptée : ne jamais les renommer sans migration côté app.
 */
export const PREMIUM_LIMIT_CODES = [
  'PREMIUM_LIMIT_BASE_RECIPES',
  'PREMIUM_LIMIT_SHOPPING_LISTS',
  'PREMIUM_LIMIT_SEARCH_CRITERIA',
  'PREMIUM_LIMIT_GALLERY_PHOTOS',
  'PREMIUM_LIMIT_MEAL_SLOT_ENTRIES',
  'PREMIUM_LIMIT_MEAL_PLAN_WEEK',
  'PREMIUM_LIMIT_FAVORITES',
  'PREMIUM_LIMIT_INGREDIENT_PHOTOS',
] as const;

export type PremiumLimitCode = (typeof PREMIUM_LIMIT_CODES)[number];

/**
 * 403 structuré `{ code, limit, current, message }` : le mobile lit `code`
 * pour router vers l'upsell, `limit`/`current` pour le texte. Le filtre global
 * (AllExceptionsFilter) fait suivre ces champs dans la réponse JSON.
 */
export class PremiumLimitException extends ForbiddenException {
  constructor(code: PremiumLimitCode, limit: number, current: number, message: string) {
    super({ code, limit, current, message });
  }
}
