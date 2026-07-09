import 'package:cocotte_minute/core/premium/premium_limit_error.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fabrique une DioException 403 avec le corps structuré du serveur
/// (`{ statusCode, timestamp, path, message, code, limit, current }`).
DioException _dio403(Map<String, dynamic> body) {
  final options = RequestOptions(path: '/recipes');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response(requestOptions: options, statusCode: 403, data: body),
  );
}

void main() {
  test('parse un 403 PREMIUM_LIMIT_BASE_RECIPES complet', () {
    final e = _dio403({
      'statusCode': 403,
      'timestamp': '2026-07-09T10:00:00Z',
      'path': '/recipes',
      'message': 'Limite de recettes de base atteinte.',
      'code': 'PREMIUM_LIMIT_BASE_RECIPES',
      'limit': 5,
      'current': 5,
    });

    final error = PremiumLimitError.fromResponseData(e.response?.data);

    expect(error, isNotNull);
    expect(error!.code, PremiumLimitError.baseRecipes);
    expect(error.limit, 5);
    expect(error.current, 5);
    expect(error.message, 'Limite de recettes de base atteinte.');
  });

  test('parse les autres codes PREMIUM_LIMIT_*', () {
    for (final code in [
      PremiumLimitError.shoppingLists,
      PremiumLimitError.searchCriteria,
    ]) {
      final e = _dio403({'message': 'Limite atteinte.', 'code': code});
      final error = PremiumLimitError.fromResponseData(e.response?.data);
      expect(error?.code, code);
      expect(error?.limit, isNull);
    }
  });

  test('403 classique sans code premium → null', () {
    final e = _dio403({
      'statusCode': 403,
      'message': 'Cette recette ne t\'appartient pas.',
    });
    expect(PremiumLimitError.fromResponseData(e.response?.data), isNull);
  });

  test('code non premium ou corps non-Map → null', () {
    expect(
      PremiumLimitError.fromResponseData({'code': 'FORBIDDEN'}),
      isNull,
    );
    expect(PremiumLimitError.fromResponseData('Forbidden'), isNull);
    expect(PremiumLimitError.fromResponseData(null), isNull);
  });

  test('limit/current numériques non-int (json num) sont convertis', () {
    final error = PremiumLimitError.fromResponseData({
      'code': 'PREMIUM_LIMIT_SEARCH_CRITERIA',
      'limit': 6.0,
      'current': 7.0,
    });
    expect(error?.limit, 6);
    expect(error?.current, 7);
  });
}
