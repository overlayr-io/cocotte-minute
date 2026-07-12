import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

/**
 * Encapsule la suppression effective de fichiers dans Supabase Storage
 * (feature galerie-recette) — jusqu'ici le serveur ne supprimait jamais de
 * fichier Storage (la couverture classique laissait des orphelins). La galerie
 * exige un nettoyage réel : à la suppression d'une photo, au remplacement d'une
 * couverture, et à la suppression d'une recette / d'un compte.
 *
 * Seule classe du serveur qui parle à l'API Storage — même principe que
 * `SupabaseAdminService` (REST admin + service-role key, pas de dépendance
 * `@supabase/supabase-js`). Les appels sont *best-effort* : toute erreur est
 * journalisée mais NON propagée, pour qu'une suppression métier (recette, photo)
 * aboutisse même si le Storage est momentanément indisponible. Un fichier
 * éventuellement orphelin est un moindre mal comparé à une opération métier qui
 * échoue.
 */
@Injectable()
export class SupabaseStorageService {
  private readonly logger = new Logger(SupabaseStorageService.name);
  private readonly baseUrl: string;
  private readonly serviceRoleKey: string;

  /** Bucket public partagé (cf. mobile ImageUploadService : « images »). */
  private static readonly BUCKET = 'images';

  constructor(config: ConfigService) {
    this.baseUrl = config.getOrThrow<string>('SUPABASE_URL').replace(/\/+$/, '');
    this.serviceRoleKey = config.getOrThrow<string>('SUPABASE_SERVICE_ROLE_KEY');
  }

  /**
   * Supprime les fichiers désignés par leurs URL publiques Storage. Ignore
   * silencieusement les URL qui ne pointent pas vers notre bucket (ex. une URL
   * externe collée à la main) et les valeurs vides. Best-effort.
   */
  async removeByPublicUrls(urls: Array<string | null | undefined>): Promise<void> {
    const paths = urls
      .map((url) => this.pathFromPublicUrl(url))
      .filter((p): p is string => p !== null);
    if (paths.length === 0) return;

    const endpoint = `${this.baseUrl}/storage/v1/object/${SupabaseStorageService.BUCKET}`;
    try {
      const res = await fetch(endpoint, {
        method: 'DELETE',
        headers: {
          apikey: this.serviceRoleKey,
          Authorization: `Bearer ${this.serviceRoleKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ prefixes: paths }),
      });
      if (!res.ok) {
        const detail = await res.text().catch(() => '');
        this.logger.warn(
          `Suppression Storage (${paths.length} fichier(s)) échouée (${res.status}) : ${detail}`,
        );
      }
    } catch (err) {
      this.logger.warn(`Suppression Storage injoignable : ${String(err)}`);
    }
  }

  /**
   * Extrait le chemin objet (dans le bucket) depuis une URL publique Supabase
   * de forme `.../storage/v1/object/public/<bucket>/<path>`. Retourne `null` si
   * l'URL est vide, malformée, ou ne cible pas notre bucket.
   */
  private pathFromPublicUrl(url: string | null | undefined): string | null {
    if (!url) return null;
    const marker = `/storage/v1/object/public/${SupabaseStorageService.BUCKET}/`;
    const idx = url.indexOf(marker);
    if (idx === -1) return null;
    const path = url.slice(idx + marker.length).split('?')[0];
    return path ? decodeURIComponent(path) : null;
  }
}
