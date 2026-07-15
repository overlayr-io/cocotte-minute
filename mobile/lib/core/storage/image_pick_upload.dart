import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../di/service_locator.dart';
import '../theme/app_colors.dart';
import '../widgets/image_upload_picker.dart' show ImageCropAspect;
import 'image_upload_service.dart';

/// Taille maximale d'une photo de galerie (feature galerie-recette), vérifiée
/// sur le fichier **original** avant compression (rejet immédiat).
const int kGalleryMaxBytes = 5 * 1024 * 1024;

/// Sélectionne une image en galerie, la recadre/compresse (JPEG 82, ≤1600px —
/// même pipeline que [ImageUploadPicker]), l'envoie sur Storage et renvoie son
/// URL publique. Renvoie `null` si l'utilisateur annule à n'importe quelle étape
/// ou si un contrôle échoue (un snackbar est alors affiché). Version « sans
/// widget d'aperçu » : déclenchée par un bouton (galerie recette, changer la
/// couverture) plutôt que par une zone tactile persistante.
Future<String?> pickCropUploadImage(
  BuildContext context, {
  required String folder,
  ImageCropAspect cropAspect = ImageCropAspect.free,
  int? maxBytes,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  void warn(String message) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  final XFile? file =
      await ImagePicker().pickImage(source: ImageSource.gallery);
  if (file == null) return null;

  // Contrôle de taille sur l'original (avant compression) — rejet immédiat.
  if (maxBytes != null && await file.length() > maxBytes) {
    warn('Image trop lourde (max ${maxBytes ~/ (1024 * 1024)} Mo).');
    return null;
  }

  final CroppedFile? cropped = await ImageCropper().cropImage(
    sourcePath: file.path,
    compressFormat: ImageCompressFormat.jpg,
    compressQuality: 82,
    maxWidth: 1600,
    maxHeight: 1600,
    aspectRatio: switch (cropAspect) {
      ImageCropAspect.square => const CropAspectRatio(ratioX: 1, ratioY: 1),
      ImageCropAspect.ratio4x3 => const CropAspectRatio(ratioX: 4, ratioY: 3),
      ImageCropAspect.free => null,
    },
    uiSettings: [
      AndroidUiSettings(
        toolbarTitle: 'Recadrer',
        toolbarColor: AppColors.primary,
        toolbarWidgetColor: Colors.white,
        activeControlsWidgetColor: AppColors.primary,
        lockAspectRatio: cropAspect != ImageCropAspect.free,
        hideBottomControls: cropAspect != ImageCropAspect.free,
      ),
      IOSUiSettings(
        title: 'Recadrer',
        aspectRatioLockEnabled: cropAspect != ImageCropAspect.free,
        resetAspectRatioEnabled: cropAspect == ImageCropAspect.free,
      ),
    ],
  );
  if (cropped == null) return null;

  try {
    return await sl<ImageUploadService>()
        .upload(XFile(cropped.path), folder: folder);
  } on ImageUploadException catch (e) {
    warn(e.message);
    return null;
  }
}
