import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Image réseau avec cache disque + redimensionnement du décodage en mémoire.
///
/// À utiliser partout à la place de `Image.network` : sans contrainte de
/// décodage, une photo pleine résolution est décodée entière même dans une
/// vignette de 64 px, ce qui provoque des saccades au scroll.
///
/// Fournir [width]/[height] quand le widget a une taille fixe, sinon
/// [decodeWidth] (largeur logique estimée de la zone d'affichage).
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage(
    this.url, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.decodeWidth,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;

  /// Largeur logique de décodage quand le widget n'a pas de largeur fixe
  /// (ex. image plein écran dans un Stack). La hauteur suit le ratio.
  final double? decodeWidth;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final logicalWidth = width ?? decodeWidth;
    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      // Une seule dimension pour préserver le ratio au décodage.
      memCacheWidth: logicalWidth != null ? (logicalWidth * dpr).round() : null,
      memCacheHeight: logicalWidth == null && height != null
          ? (height! * dpr).round()
          : null,
      fadeInDuration: const Duration(milliseconds: 150),
      placeholder: (_, _) => const ColoredBox(color: AppColors.pill),
      errorWidget: (_, _, _) => const ColoredBox(
        color: AppColors.pill,
        child: Icon(Icons.image_not_supported_outlined,
            color: AppColors.textMuted),
      ),
    );
  }
}

/// Provider caché/redimensionné pour les usages `DecorationImage`
/// (avatars, tuiles avec `BoxDecoration`).
///
/// [logicalWidth] = taille logique d'affichage ; le provider télécharge une
/// fois (cache disque) et décode à la taille demandée.
ImageProvider cachedImageProvider(
  BuildContext context,
  String url, {
  required double logicalWidth,
}) {
  final dpr = MediaQuery.devicePixelRatioOf(context);
  return CachedNetworkImageProvider(
    url,
    maxWidth: (logicalWidth * dpr).round(),
  );
}
