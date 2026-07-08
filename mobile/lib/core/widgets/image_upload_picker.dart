import 'package:flutter/material.dart';

import 'app_network_image.dart';
import 'package:image_picker/image_picker.dart';

import '../di/service_locator.dart';
import '../storage/image_upload_service.dart';
import '../theme/app_colors.dart';

/// Forme visuelle du sélecteur : rond (avatar/ingrédient) ou carte (photo recette).
enum ImageUploadShape { circle, card }

/// Zone tactile partagée « choisir une image » : ouvre la galerie, envoie le
/// fichier via [ImageUploadService] et affiche un aperçu. Rend [placeholder]
/// tant qu'aucune image n'est choisie, puis l'image envoyée. Notifie le parent
/// de l'URL publique via [onUploaded] (à ranger dans le champ imageUrl/avatarUrl).
class ImageUploadPicker extends StatefulWidget {
  const ImageUploadPicker({
    super.key,
    required this.folder,
    required this.onUploaded,
    required this.placeholder,
    this.initialUrl,
    this.shape = ImageUploadShape.circle,
    this.size = 82,
    this.borderRadius = 22,
  });

  /// Sous-dossier Storage (ex. « ingredients », « avatars », « recipes »).
  final String folder;

  /// Appelé avec l'URL publique après un envoi réussi.
  final ValueChanged<String> onUploaded;

  /// Contenu affiché tant qu'aucune image n'est choisie (garde le style existant).
  final Widget placeholder;

  final String? initialUrl;
  final ImageUploadShape shape;

  /// Diamètre (cercle) ou hauteur (carte).
  final double size;

  /// Rayon des coins pour la forme [ImageUploadShape.card].
  final double borderRadius;

  @override
  State<ImageUploadPicker> createState() => _ImageUploadPickerState();
}

class _ImageUploadPickerState extends State<ImageUploadPicker> {
  final _picker = ImagePicker();
  String? _previewUrl;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _previewUrl = widget.initialUrl;
  }

  Future<void> _pick() async {
    if (_uploading) return;
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1280,
      imageQuality: 82,
    );
    if (file == null) return;

    setState(() => _uploading = true);
    try {
      final url =
          await sl<ImageUploadService>().upload(file, folder: widget.folder);
      if (!mounted) return;
      setState(() {
        _previewUrl = url;
        _uploading = false;
      });
      widget.onUploaded(url);
    } on ImageUploadException catch (e) {
      if (!mounted) return;
      setState(() => _uploading = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCircle = widget.shape == ImageUploadShape.circle;
    final radius = isCircle
        ? BorderRadius.circular(widget.size)
        : BorderRadius.circular(widget.borderRadius);

    return GestureDetector(
      onTap: _pick,
      child: SizedBox(
        width: isCircle ? widget.size : double.infinity,
        height: widget.size,
        child: Stack(
          children: [
            Positioned.fill(
              child: _previewUrl == null
                  ? widget.placeholder
                  : ClipRRect(
                      borderRadius: radius,
                      child: AppNetworkImage(
                        _previewUrl!,
                        decodeWidth: isCircle
                            ? widget.size
                            : MediaQuery.sizeOf(context).width,
                      ),
                    ),
            ),
            if (_uploading)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: radius,
                  child: const ColoredBox(
                    color: Colors.black54,
                    child: Center(
                      child: SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else
              Positioned(
                right: isCircle ? 0 : 12,
                bottom: isCircle ? 0 : 12,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.photo_camera_rounded,
                    size: 15,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
