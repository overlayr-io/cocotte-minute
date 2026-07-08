import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

import '../../features/recipes/presentation/pages/shared_recipe_page.dart';
import 'app_navigator.dart';

/// Écoute les liens entrants (universal / app links + scheme custom) et ouvre la
/// recette partagée correspondante. Les liens ciblés :
///   - `https://<domaine>/r/<token>`  (universal / app link)
///   - `cocotteminute://r/<token>`    (scheme custom, repli hors association web)
///
/// Le service ne connaît pas le domaine : il repère le segment `r/<token>` quelle
/// que soit l'origine, ce qui le rend indépendant de la config de déploiement.
class DeepLinkService {
  DeepLinkService({AppLinks? appLinks}) : _appLinks = appLinks ?? AppLinks();

  final AppLinks _appLinks;
  StreamSubscription<Uri>? _subscription;

  /// Démarre l'écoute et traite un éventuel lien de lancement (app ouverte via
  /// le lien à froid). Idempotent : un second appel est sans effet.
  Future<void> init() async {
    if (_subscription != null) return;
    _subscription = _appLinks.uriLinkStream.listen(
      _handleUri,
      onError: (Object e) => debugPrint('DeepLinkService: lien invalide ($e)'),
    );
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) _handleUri(initial);
    } catch (e) {
      debugPrint('DeepLinkService: lien initial illisible ($e)');
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  void _handleUri(Uri uri) {
    final token = _shareTokenFrom(uri);
    if (token == null) return;
    appNavigatorKey.currentState?.push(SharedRecipePage.route(token));
  }

  /// Extrait le token d'un lien de partage : segment suivant un marqueur `r`
  /// (hôte ou chemin), sinon `null`. Couvre l'universal link et le scheme custom.
  static String? _shareTokenFrom(Uri uri) {
    final segments = <String>[
      uri.host,
      ...uri.pathSegments,
    ].where((s) => s.isNotEmpty).toList();
    final marker = segments.indexOf('r');
    if (marker != -1 && marker + 1 < segments.length) {
      return segments[marker + 1];
    }
    return null;
  }
}
