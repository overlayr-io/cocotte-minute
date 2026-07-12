import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/premium/premium_cubit.dart';
import '../../../../core/premium/premium_limit_error.dart';
import '../../../../core/premium/premium_limit_sheet.dart';
import '../../../../core/storage/image_pick_upload.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/image_upload_picker.dart' show ImageCropAspect;
import '../../domain/recipe.dart';
import '../bloc/recipe_detail_cubit.dart';
import '../pages/gallery_viewer_page.dart';

/// Quota de photos de galerie par recette (miroir du serveur) : plafond réel,
/// même en Pro. Au-delà : upsell en gratuit, simple message en Pro.
const int _kFreeLimit = 3;
const int _kProLimit = 6;

/// Section « Galerie » de la fiche recette (feature galerie-recette, écran 2d) :
/// grille des réalisations + ajout. Placée dans l'onglet Ingrédients, juste
/// après les sous-recettes. S'affiche pour une recette normale comme de base.
class RecipeGallerySection extends StatelessWidget {
  const RecipeGallerySection({super.key, required this.detail});

  final RecipeDetail detail;

  Future<void> _add(BuildContext context) async {
    final cubit = context.read<RecipeDetailCubit>();
    final isPremium = context.read<PremiumCubit>().state.isPremium;
    final l10n = AppLocalizations.of(context);
    final limit = isPremium ? _kProLimit : _kFreeLimit;
    final current = detail.galleryPhotos.length;

    // Quota vérifié côté client avant d'ouvrir le picker (le serveur reste la
    // vérité). En Pro : simple message ; en gratuit : upsell.
    if (current >= limit) {
      if (isPremium) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(l10n.recipeGalleryFullPro(limit))),
          );
      } else {
        showPremiumLimitSheet(
          context,
          error: PremiumLimitError(
            code: PremiumLimitError.galleryPhotos,
            limit: limit,
            current: current,
          ),
        );
      }
      return;
    }

    final url = await pickCropUploadImage(
      context,
      folder: 'recipe-gallery',
      cropAspect: ImageCropAspect.free,
      maxBytes: kGalleryMaxBytes,
    );
    if (url == null) return;
    await cubit.addGalleryPhoto(url);
  }

  void _openViewer(BuildContext context, int index) {
    Navigator.of(context).push(
      GalleryViewerPage.route(
        photos: detail.galleryPhotos,
        initialIndex: index,
        cubit: context.read<RecipeDetailCubit>(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPremium =
        context.select<PremiumCubit, bool>((c) => c.state.isPremium);
    final limit = isPremium ? _kProLimit : _kFreeLimit;
    final l10n = AppLocalizations.of(context);
    final photos = detail.galleryPhotos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 22),
        Row(
          children: [
            Text(
              l10n.recipeGallerySection,
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: AppColors.textPrimary,
              ),
            ),
            if (photos.isNotEmpty) ...[
              const SizedBox(width: 8),
              _CountBadge(text: l10n.recipeGalleryCounter(photos.length, limit)),
            ],
            const Spacer(),
            if (photos.isNotEmpty)
              _AddButton(
                tooltip: l10n.recipeGalleryAdd,
                onTap: () => _add(context),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (photos.isEmpty)
          _EmptyCard(
            count: photos.length,
            limit: limit,
            l10n: l10n,
            onTap: () => _add(context),
          )
        else
          GridView.count(
            crossAxisCount: 3,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (var i = 0; i < photos.length; i++)
                GestureDetector(
                  onTap: () => _openViewer(context, i),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AppNetworkImage(photos[i].imageUrl, decodeWidth: 140),
                  ),
                ),
            ],
          ),
        if (photos.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            l10n.recipeGalleryHint,
            style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
          ),
        ],
      ],
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFBECEA),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFFFF6F61),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap, required this.tooltip});

  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: const BorderSide(color: Color(0xFFCFD8C4), width: 1.5),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: const SizedBox(
            width: 32,
            height: 32,
            child: Icon(Icons.add_rounded, size: 18, color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.count,
    required this.limit,
    required this.l10n,
    required this.onTap,
  });

  final int count;
  final int limit;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DottedBorderBox(
        child: Column(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFF1EEE4),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_photo_alternate_outlined,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.recipeGalleryEmptyCta,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF5C7A4C),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.recipeGalleryEmptyMeta(count, limit),
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cadre en pointillés de l'état vide (pas de dépendance externe — CustomPaint).
class DottedBorderBox extends StatelessWidget {
  const DottedBorderBox({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRectPainter(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 18),
        child: Center(child: child),
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC4BEAD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    const radius = 16.0;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    const dash = 5.0;
    const gap = 4.0;
    for (final metric in path.computeMetrics()) {
      double dist = 0;
      while (dist < metric.length) {
        canvas.drawPath(
          metric.extractPath(dist, dist + dash),
          paint,
        );
        dist += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
