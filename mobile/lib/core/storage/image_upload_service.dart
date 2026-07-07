import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase/supabase_client.dart';

/// Échec d'un envoi d'image, avec un message exploitable pour l'UI (snackbar).
class ImageUploadException implements Exception {
  const ImageUploadException(this.message);

  final String message;

  @override
  String toString() => 'ImageUploadException($message)';
}

/// Service partagé d'upload d'image vers Supabase Storage.
///
/// Flutter parle directement à Supabase pour le Storage (cf. mobile/CLAUDE.md) :
/// on envoie l'image ici, on récupère l'URL publique, puis on la range dans le
/// champ `imageUrl`/`avatarUrl` envoyé à l'API NestJS. Aucun changement serveur.
///
/// PRÉ-REQUIS CONSOLE SUPABASE : un bucket public nommé [bucket] (« images »)
/// doit exister, avec une policy autorisant l'`insert` pour les utilisateurs
/// authentifiés (et anonymes si le compte anonyme est utilisé).
class ImageUploadService {
  const ImageUploadService({this.bucket = _defaultBucket});

  static const String _defaultBucket = 'images';

  /// Nom du bucket Supabase Storage cible.
  final String bucket;

  /// Envoie [file] dans le sous-dossier [folder] du bucket et renvoie l'URL
  /// publique. Lève [ImageUploadException] en cas d'échec.
  Future<String> upload(XFile file, {required String folder}) async {
    try {
      final bytes = await file.readAsBytes();
      final extension = _extensionOf(file);
      final userId = SupabaseService.auth.currentUser?.id ?? 'anon';
      final path =
          '$folder/$userId/${DateTime.now().millisecondsSinceEpoch}.$extension';

      final storage = SupabaseService.client.storage.from(bucket);
      await storage.uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(
          contentType: file.mimeType ?? _mimeOf(extension),
          upsert: true,
        ),
      );
      return storage.getPublicUrl(path);
    } on StorageException catch (e) {
      throw ImageUploadException(e.message);
    } on ImageUploadException {
      rethrow;
    } catch (_) {
      throw const ImageUploadException("Impossible d'envoyer l'image.");
    }
  }

  String _extensionOf(XFile file) {
    final name = file.name;
    final dot = name.lastIndexOf('.');
    if (dot == -1 || dot == name.length - 1) return 'jpg';
    return name.substring(dot + 1).toLowerCase();
  }

  String _mimeOf(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'heic':
        return 'image/heic';
      default:
        return 'image/jpeg';
    }
  }
}
