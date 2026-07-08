import 'package:flutter/widgets.dart';

/// Clé du navigateur racine, exposée pour permettre une navigation hors contexte
/// widget — notamment l'ouverture d'un lien de partage reçu par deep link
/// ([DeepLinkService]), qui survient en dehors de l'arbre de widgets.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
