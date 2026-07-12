import 'package:equatable/equatable.dart';

import '../../recipes/domain/recipe.dart';

/// Créneaux fixes d'une journée (cf. features/planification-repas.md).
enum MealSlot {
  matin('matin'),
  midi('midi'),
  soir('soir');

  const MealSlot(this.wire);

  /// Valeur échangée avec l'API (enum Postgres `meal_slot`).
  final String wire;

  static MealSlot fromWire(String value) =>
      MealSlot.values.firstWhere((s) => s.wire == value);
}

/// Types d'entrée d'un créneau : recette, « manger dehors » ou note libre.
enum MealEntryType {
  recipe('recipe'),
  eatingOut('eating_out'),
  note('note');

  const MealEntryType(this.wire);

  final String wire;

  static MealEntryType fromWire(String value) =>
      MealEntryType.values.firstWhere((t) => t.wire == value);
}

/// Entrée du planning de repas, hydratée par le serveur ([recipe] renseignée
/// uniquement pour le type [MealEntryType.recipe]).
class MealPlanEntry extends Equatable {
  const MealPlanEntry({
    required this.id,
    required this.day,
    required this.slot,
    required this.type,
    this.recipe,
    this.noteText,
    this.position = 0,
  });

  final String id;

  /// Jour planifié, `YYYY-MM-DD`.
  final String day;
  final MealSlot slot;
  final MealEntryType type;
  final RecipeSummary? recipe;
  final String? noteText;
  final int position;

  factory MealPlanEntry.fromJson(Map<String, dynamic> json) {
    final recipeJson = json['recipe'] as Map<String, dynamic>?;
    return MealPlanEntry(
      id: json['id'] as String,
      day: json['day'] as String,
      slot: MealSlot.fromWire(json['slot'] as String),
      type: MealEntryType.fromWire(json['entryType'] as String),
      recipe: recipeJson == null ? null : RecipeSummary.fromJson(recipeJson),
      noteText: json['noteText'] as String?,
      position: json['position'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'day': day,
    'slot': slot.wire,
    'entryType': type.wire,
    'recipe': switch (recipe) {
      null => null,
      final r => {
        'id': r.id,
        'name': r.name,
        'photoUrl': r.photoUrl,
        'isBase': r.isBase,
        'prepTime': r.prepTime,
        'cookTime': r.cookTime,
        'restTime': r.restTime,
        'servings': r.servings,
      },
    },
    'noteText': noteText,
    'position': position,
  };

  @override
  List<Object?> get props => [id, day, slot, type, recipe, noteText, position];
}
