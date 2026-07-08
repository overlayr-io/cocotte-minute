import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

/**
 * Encapsule les opérations d'administration de Supabase Auth (GoTrue) nécessaires
 * au parcours RGPD : anonymisation et suppression de l'utilisateur *Auth* (l'email
 * et les identités OAuth vivent dans Supabase Auth, pas dans notre DB métier).
 *
 * Seule classe du serveur qui parle à l'API admin GoTrue — conformément au
 * principe « aucune librairie/appel externe directement dans un service métier ».
 * On utilise l'API REST admin (`/auth/v1/admin/users`) avec la **service-role key**
 * plutôt que d'ajouter `@supabase/supabase-js` (pas de dépendance supplémentaire).
 *
 * IMPORTANT (gap à connaître) : ces opérations exigent que `SUPABASE_SERVICE_ROLE_KEY`
 * soit une **vraie clé service_role** du projet (déjà requise par env.validation).
 * Les appels sont *best-effort* : toute erreur est journalisée mais NON propagée,
 * pour que la suppression cascade côté DB (cœur RGPD) aboutisse même si l'API Auth
 * est momentanément indisponible ou mal configurée. Un échec ici doit être suivi
 * manuellement / via monitoring.
 */
@Injectable()
export class SupabaseAdminService {
  private readonly logger = new Logger(SupabaseAdminService.name);
  private readonly baseUrl: string;
  private readonly serviceRoleKey: string;

  constructor(config: ConfigService) {
    this.baseUrl = config.getOrThrow<string>('SUPABASE_URL').replace(/\/+$/, '');
    this.serviceRoleKey = config.getOrThrow<string>('SUPABASE_SERVICE_ROLE_KEY');
  }

  /**
   * Retire les données directement identifiantes de l'utilisateur Auth (email,
   * téléphone, métadonnées) tout en conservant le compte — nécessaire au rollback
   * pendant les 30 jours. Best-effort.
   */
  async anonymizeAuthUser(userId: string): Promise<void> {
    await this.adminRequest('PUT', userId, {
      email: `deleted+${userId}@deleted.invalid`,
      phone: null,
      user_metadata: {},
      app_metadata: {},
    });
  }

  /**
   * Supprime définitivement l'utilisateur Auth (et ses identités liées).
   * Best-effort. À appeler après la purge cascade des données métier.
   */
  async deleteAuthUser(userId: string): Promise<void> {
    await this.adminRequest('DELETE', userId);
  }

  private async adminRequest(
    method: 'PUT' | 'DELETE',
    userId: string,
    body?: unknown,
  ): Promise<void> {
    const url = `${this.baseUrl}/auth/v1/admin/users/${userId}`;
    try {
      const res = await fetch(url, {
        method,
        headers: {
          apikey: this.serviceRoleKey,
          Authorization: `Bearer ${this.serviceRoleKey}`,
          'Content-Type': 'application/json',
        },
        body: body === undefined ? undefined : JSON.stringify(body),
      });
      if (!res.ok) {
        const detail = await res.text().catch(() => '');
        this.logger.warn(
          `Appel admin Supabase ${method} user ${userId} échoué (${res.status}) : ${detail}`,
        );
      }
    } catch (err) {
      this.logger.warn(
        `Appel admin Supabase ${method} user ${userId} injoignable : ${String(err)}`,
      );
    }
  }
}
