import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

export interface ImageSuggestionDto {
  id: string;
  thumbUrl: string;
  fullUrl: string;
  /** Nom du photographe — attribution obligatoire (conditions API Unsplash). */
  authorName: string;
  /** Lien vers le profil du photographe, avec paramètres `utm_*` requis. */
  authorUrl: string;
  /**
   * URL à appeler (GET) pour déclencher le comptage officiel de téléchargement
   * dès que la photo est utilisée — condition d'accès au quota production
   * (1000 req/h). Jamais affichée, seulement renvoyée à `POST /images/track-download`.
   */
  downloadLocation: string;
}

/** Nom d'app utilisé dans les paramètres `utm_source` (conditions d'attribution Unsplash). */
const UTM_APP_NAME = 'cocotte_minute';

/**
 * Encapsule l'API Unsplash (seule classe du serveur qui lui parle) : suggère
 * des photos libres de droits basées sur le nom de la recette (feature #4 —
 * pas d'upload, seule l'URL choisie est enregistrée) et déclenche le comptage
 * officiel de téléchargement à l'usage, comme l'exigent les conditions
 * d'accès production de l'API (hotlink + attribution + tracking).
 */
@Injectable()
export class UnsplashService {
  private readonly logger = new Logger(UnsplashService.name);
  private readonly accessKey: string | undefined;

  constructor(config: ConfigService) {
    this.accessKey = config.get<string>('UNSPLASH_ACCESS_KEY');
  }

  /** Ajoute `utm_source`/`utm_medium` à un lien Unsplash (attribution requise). */
  private withUtm(url: string): string {
    const u = new URL(url);
    u.searchParams.set('utm_source', UTM_APP_NAME);
    u.searchParams.set('utm_medium', 'referral');
    return u.toString();
  }

  async search(query: string): Promise<ImageSuggestionDto[]> {
    if (!this.accessKey) {
      this.logger.warn('UNSPLASH_ACCESS_KEY absente : suggestion d’image désactivée');
      return [];
    }
    const url = new URL('https://api.unsplash.com/search/photos');
    url.searchParams.set('query', query);
    url.searchParams.set('per_page', '6');
    url.searchParams.set('orientation', 'landscape');
    try {
      const res = await fetch(url, {
        headers: { Authorization: `Client-ID ${this.accessKey}` },
      });
      if (!res.ok) {
        this.logger.warn(`Recherche Unsplash « ${query} » échouée (${res.status})`);
        return [];
      }
      const body = (await res.json()) as {
        results: Array<{
          id: string;
          urls: { thumb: string; regular: string };
          user: { name: string; links: { html: string } };
          links: { download_location: string };
        }>;
      };
      return body.results.map((r) => ({
        id: r.id,
        thumbUrl: r.urls.thumb,
        fullUrl: r.urls.regular,
        authorName: r.user.name,
        authorUrl: this.withUtm(r.user.links.html),
        downloadLocation: r.links.download_location,
      }));
    } catch (err) {
      this.logger.warn(`API Unsplash injoignable : ${String(err)}`);
      return [];
    }
  }

  /**
   * Déclenche le comptage officiel de téléchargement (GET sur
   * `download_location`, cf. conditions API) dès qu'une suggestion est
   * effectivement utilisée. Best-effort, jamais bloquant pour l'utilisateur.
   * N'appelle que des URLs `api.unsplash.com` (défense en profondeur contre un
   * `downloadLocation` forgé côté client).
   */
  async trackDownload(downloadLocation: string): Promise<void> {
    if (!this.accessKey) return;
    if (!downloadLocation.startsWith('https://api.unsplash.com/')) {
      this.logger.warn(`URL de tracking Unsplash invalide ignorée : ${downloadLocation}`);
      return;
    }
    try {
      const res = await fetch(downloadLocation, {
        headers: { Authorization: `Client-ID ${this.accessKey}` },
      });
      if (!res.ok) {
        this.logger.warn(`Tracking de téléchargement Unsplash échoué (${res.status})`);
      }
    } catch (err) {
      this.logger.warn(`Tracking de téléchargement Unsplash injoignable : ${String(err)}`);
    }
  }
}
