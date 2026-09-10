import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';

/// Suggestion d'image (Unsplash) pour la couverture d'une recette (#4).
/// [authorUrl] porte déjà les paramètres `utm_*` requis par les conditions
/// d'attribution Unsplash (ajoutés côté serveur).
class ImageSuggestion {
  const ImageSuggestion({
    required this.id,
    required this.thumbUrl,
    required this.fullUrl,
    required this.authorName,
    required this.authorUrl,
    required this.downloadLocation,
  });

  final String id;
  final String thumbUrl;
  final String fullUrl;
  final String authorName;
  final String authorUrl;

  /// URL de tracking à transmettre à [RecipeImageSearchRepository.trackDownload]
  /// dès que cette suggestion est effectivement utilisée.
  final String downloadLocation;

  factory ImageSuggestion.fromJson(Map<String, dynamic> json) {
    return ImageSuggestion(
      id: json['id'] as String,
      thumbUrl: json['thumbUrl'] as String,
      fullUrl: json['fullUrl'] as String,
      authorName: json['authorName'] as String,
      authorUrl: json['authorUrl'] as String,
      downloadLocation: json['downloadLocation'] as String,
    );
  }
}

/// Recherche d'images libres de droits par mot-clé (feature #4) : seule l'URL
/// choisie est enregistrée (hotlink), aucun upload. Best-effort — une erreur
/// réseau renvoie une liste vide plutôt que de bloquer la création de recette.
class RecipeImageSearchRepository {
  RecipeImageSearchRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<ImageSuggestion>> search(String query) async {
    try {
      final res = await _apiClient.raw.get<List<dynamic>>(
        '/images/search',
        queryParameters: {'query': query},
      );
      return (res.data ?? const [])
          .cast<Map<String, dynamic>>()
          .map(ImageSuggestion.fromJson)
          .toList();
    } on DioException {
      return const [];
    }
  }

  /// Signale l'usage d'une suggestion (condition d'accès production de l'API
  /// Unsplash). Best-effort et silencieux : ne doit jamais bloquer ni alerter
  /// l'utilisateur en cas d'échec réseau.
  Future<void> trackDownload(String downloadLocation) async {
    try {
      await _apiClient.raw.post<void>(
        '/images/track-download',
        data: {'downloadLocation': downloadLocation},
      );
    } on DioException {
      // Best-effort : cf. docstring.
    }
  }
}
