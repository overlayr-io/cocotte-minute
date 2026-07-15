import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/premium/premium_cubit.dart';
import '../../../../core/premium/premium_limit_error.dart';
import '../../../../core/premium/premium_limit_sheet.dart';
import '../../../../core/storage/image_pick_upload.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/image_upload_picker.dart' show ImageCropAspect;
import '../../data/ingredients_repository.dart';
import '../../domain/ingredient_photo.dart';

/// Quota « Mes produits » par ingrédient (miroir du serveur) : plafond réel même
/// en Pro. Au-delà : upsell en gratuit, simple message en Pro.
const int _kFreeLimit = 1;
const int _kProLimit = 3;

/// Section « Mes produits » (#14) de l'écran ingrédient : galerie de photos du
/// vrai produit acheté, distincte de l'icône. Auto-portée (state local + repo).
class IngredientProductPhotosSection extends StatefulWidget {
  const IngredientProductPhotosSection({super.key, required this.ingredientId});

  final String ingredientId;

  @override
  State<IngredientProductPhotosSection> createState() =>
      _IngredientProductPhotosSectionState();
}

class _IngredientProductPhotosSectionState
    extends State<IngredientProductPhotosSection> {
  final IngredientsRepository _repository = sl<IngredientsRepository>();

  List<IngredientPhoto>? _photos;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final photos = await _repository.fetchProductPhotos(widget.ingredientId);
      if (mounted) setState(() => _photos = photos);
    } on IngredientsRepositoryException {
      // Échec non bloquant : la section reste masquée le temps du chargement.
      if (mounted) setState(() => _photos = const []);
    }
  }

  Future<void> _add() async {
    if (_busy) return;
    final isPremium = context.read<PremiumCubit>().state.isPremium;
    final l10n = AppLocalizations.of(context);
    final limit = isPremium ? _kProLimit : _kFreeLimit;
    final current = _photos?.length ?? 0;

    // Quota vérifié côté client avant le picker (le serveur reste la vérité).
    if (current >= limit) {
      if (isPremium) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(l10n.ingredientProductsFullPro(limit))),
          );
      } else {
        showPremiumLimitSheet(
          context,
          error: PremiumLimitError(
            code: PremiumLimitError.ingredientPhotos,
            limit: limit,
            current: current,
          ),
        );
      }
      return;
    }

    final url = await pickCropUploadImage(
      context,
      folder: 'ingredient-products',
      cropAspect: ImageCropAspect.square,
      maxBytes: kGalleryMaxBytes,
    );
    if (url == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final photos = await _repository.addProductPhoto(widget.ingredientId, url);
      if (mounted) setState(() => _photos = photos);
    } on IngredientsRepositoryException catch (e) {
      if (!mounted) return;
      if (e.premiumLimit != null) {
        showPremiumLimitSheet(context, error: e.premiumLimit!);
      } else {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(IngredientPhoto photo) async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.ingredientProductsDeleteTitle),
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
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await _repository.removeProductPhoto(widget.ingredientId, photo.id);
      if (mounted) {
        setState(() =>
            _photos = _photos?.where((p) => p.id != photo.id).toList());
      }
    } on IngredientsRepositoryException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final photos = _photos;
    if (photos == null) return const SizedBox.shrink();
    final isPremium =
        context.select<PremiumCubit, bool>((c) => c.state.isPremium);
    final limit = isPremium ? _kProLimit : _kFreeLimit;
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _FieldLabel(l10n.ingredientProductsSection),
            if (photos.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                '${photos.length}/$limit',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 9),
        if (photos.isEmpty)
          GestureDetector(
            onTap: _add,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFC4BEAD), width: 1.5),
              ),
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1EEE4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add_a_photo_outlined,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.ingredientProductsEmptyCta,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF5C7A4C),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.ingredientProductsHint,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final photo in photos)
                _Thumb(photo: photo, onDelete: () => _remove(photo)),
              if (photos.length < limit) _AddTile(onTap: _add),
            ],
          ),
      ],
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.photo, required this.onDelete});

  final IngredientPhoto photo;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: AppNetworkImage(photo.imageUrl,
              width: 88, height: 88, decodeWidth: 180),
        ),
        Positioned(
          top: 3,
          right: 3,
          child: GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Color(0xCC1F2933),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded,
                  size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFC4BEAD), width: 1.5),
        ),
        child: const Icon(Icons.add_a_photo_outlined,
            size: 22, color: AppColors.primary),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: AppColors.textMuted,
      ),
    );
  }
}
