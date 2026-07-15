import 'package:flutter/material.dart';

import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../domain/recipe.dart';
import '../bloc/recipe_detail_cubit.dart';

/// Vue plein écran / carrousel des photos de galerie d'une recette (feature
/// galerie-recette). Navigation par glissement, zoom pincé, et — pour le
/// propriétaire — suppression (seule action possible ici, cf. doc). La
/// suppression met à jour l'état du [cubit] : la grille se rafraîchit au retour.
class GalleryViewerPage extends StatefulWidget {
  const GalleryViewerPage({
    super.key,
    required this.photos,
    required this.initialIndex,
    required this.cubit,
  });

  final List<RecipeGalleryPhoto> photos;
  final int initialIndex;
  final RecipeDetailCubit cubit;

  static Route<void> route({
    required List<RecipeGalleryPhoto> photos,
    required int initialIndex,
    required RecipeDetailCubit cubit,
  }) {
    return MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => GalleryViewerPage(
        photos: photos,
        initialIndex: initialIndex,
        cubit: cubit,
      ),
    );
  }

  @override
  State<GalleryViewerPage> createState() => _GalleryViewerPageState();
}

class _GalleryViewerPageState extends State<GalleryViewerPage> {
  late final List<RecipeGalleryPhoto> _photos = List.of(widget.photos);
  late int _index = widget.initialIndex.clamp(0, widget.photos.length - 1);
  late final PageController _controller = PageController(initialPage: _index);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final photo = _photos[_index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.recipeGalleryDeleteConfirmTitle),
        content: Text(l10n.recipeGalleryDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await widget.cubit.removeGalleryPhoto(photo.id);
    if (!mounted) return;
    setState(() {
      _photos.removeAt(_index);
      if (_photos.isEmpty) return;
      if (_index >= _photos.length) _index = _photos.length - 1;
    });
    if (_photos.isEmpty) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: PageView.builder(
                controller: _controller,
                itemCount: _photos.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) => InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Center(
                    child: AppNetworkImage(
                      _photos[i].imageUrl,
                      fit: BoxFit.contain,
                      decodeWidth: MediaQuery.sizeOf(context).width,
                    ),
                  ),
                ),
              ),
            ),
            // Barre supérieure : fermer · position · supprimer.
            Positioned(
              top: 6,
              left: 10,
              right: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _RoundButton(
                    icon: Icons.close_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  if (_photos.length > 1)
                    Text(
                      l10n.recipeGalleryPosition(_index + 1, _photos.length),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  _RoundButton(
                    icon: Icons.delete_outline_rounded,
                    tooltip: l10n.recipeGalleryDelete,
                    onTap: _delete,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onTap, this.tooltip});

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: Colors.white24,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}
