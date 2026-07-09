import { plainToInstance, Type } from 'class-transformer';
import { IsInt, IsOptional, IsString, IsUrl, Max, Min, validateSync } from 'class-validator';

/**
 * Validation stricte des variables d'environnement au démarrage.
 * Le process crash immédiatement si une variable requise manque ou est invalide,
 * plutôt que d'échouer plus tard à la première requête DB/auth.
 */
export class EnvironmentVariables {
  @IsString()
  DATABASE_URL!: string;

  @IsUrl({ require_tld: false })
  SUPABASE_URL!: string;

  @IsString()
  SUPABASE_SERVICE_ROLE_KEY!: string;

  @IsString()
  SUPABASE_JWT_SECRET!: string;

  /**
   * URL publique de base du serveur (feature partage-recette) : sert à construire
   * les liens de partage (`/r/:token`) et doit correspondre au domaine déclaré dans
   * les fichiers de deep link (.well-known). Défaut local pour le dev.
   */
  @IsUrl({ require_tld: false })
  PUBLIC_BASE_URL = 'http://localhost:3000';

  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(65535)
  PORT = 3000;

  /**
   * Valeur attendue dans le header `Authorization` des webhooks RevenueCat
   * (configurée à l'identique dans le dashboard RevenueCat → Webhooks).
   * Obligatoire : sans elle le endpoint accepterait des événements forgés.
   */
  @IsString()
  REVENUECAT_WEBHOOK_SECRET!: string;

  /**
   * Clé API secrète RevenueCat (`sk_...`) pour l'API REST v1 — utilisée
   * uniquement pour la suppression RGPD du subscriber. Optionnelle : si
   * absente, la suppression RevenueCat est ignorée (best-effort, loggé).
   */
  @IsOptional()
  @IsString()
  REVENUECAT_API_KEY?: string;
}

export function validateEnv(config: Record<string, unknown>): EnvironmentVariables {
  const validated = plainToInstance(EnvironmentVariables, config, {
    enableImplicitConversion: true,
  });

  const errors = validateSync(validated, { skipMissingProperties: false });
  if (errors.length > 0) {
    throw new Error(
      `Configuration d'environnement invalide :\n${errors
        .map((e) => `  - ${e.property}: ${Object.values(e.constraints ?? {}).join(', ')}`)
        .join('\n')}`,
    );
  }
  return validated;
}
