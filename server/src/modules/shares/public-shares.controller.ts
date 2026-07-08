import { Controller, Get, Header, Param } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import { RecipeDetailDto } from '../recipes/recipes.service';
import { renderSharePage } from './share-page.template';
import { SharesService } from './shares.service';

/**
 * Lecture publique d'une recette partagée (feature partage-recette) — AUCUN guard :
 * ces routes sont volontairement accessibles sans authentification.
 *  - `GET /share/:token`  → fiche recette JSON (consommée par l'app après un deep link) ;
 *  - `GET /r/:token`      → page web autonome (aperçu + cible des universal/app links) ;
 *  - `/.well-known/*`     → fichiers d'association deep link (iOS/Android).
 *
 * Les valeurs d'identité app (Team ID iOS, empreinte SHA256 Android) sont lues depuis
 * la config (placeholders `TODO_*` par défaut, à renseigner au déploiement).
 */
@Controller()
export class PublicSharesController {
  constructor(
    private readonly sharesService: SharesService,
    private readonly config: ConfigService,
  ) {}

  @Get('share/:token')
  getJson(@Param('token') token: string): Promise<RecipeDetailDto> {
    return this.sharesService.getSharedRecipe(token);
  }

  @Get('r/:token')
  @Header('Content-Type', 'text/html; charset=utf-8')
  async getPage(@Param('token') token: string): Promise<string> {
    const detail = await this.sharesService.getSharedRecipe(token);
    return renderSharePage(detail);
  }

  /**
   * Apple App Site Association — DOIT être servi sans extension et en
   * `application/json`. `paths` autorise l'ouverture native des liens `/r/*`.
   */
  @Get('.well-known/apple-app-site-association')
  @Header('Content-Type', 'application/json')
  appleAppSiteAssociation(): Record<string, unknown> {
    const appId = this.config.get<string>(
      'APPLE_APP_ID',
      'TODO_TEAMID.com.cocotteminute.cocotteMinute',
    );
    return {
      applinks: {
        apps: [],
        details: [{ appID: appId, paths: ['/r/*'] }],
      },
    };
  }

  /** Digital Asset Links Android — associe le domaine au package pour les App Links. */
  @Get('.well-known/assetlinks.json')
  @Header('Content-Type', 'application/json')
  assetLinks(): unknown[] {
    const sha256 = this.config.get<string>(
      'ANDROID_CERT_SHA256',
      'TODO_SHA256_FINGERPRINT',
    );
    return [
      {
        relation: ['delegate_permission/common.handle_all_urls'],
        target: {
          namespace: 'android_app',
          package_name: 'com.cocotteminute.cocotte_minute',
          sha256_cert_fingerprints: [sha256],
        },
      },
    ];
  }
}
