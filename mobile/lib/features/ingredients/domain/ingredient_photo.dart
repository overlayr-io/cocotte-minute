import 'package:equatable/equatable.dart';

/// Une photo « Mes produits » (#14) attachée à un ingrédient.
class IngredientPhoto extends Equatable {
  const IngredientPhoto({required this.id, required this.imageUrl});

  final String id;
  final String imageUrl;

  factory IngredientPhoto.fromJson(Map<String, dynamic> json) {
    return IngredientPhoto(
      id: json['id'] as String,
      imageUrl: json['imageUrl'] as String,
    );
  }

  @override
  List<Object?> get props => [id, imageUrl];
}
