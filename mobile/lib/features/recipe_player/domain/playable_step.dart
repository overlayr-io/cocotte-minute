import 'package:cocotte_minute/features/recipes/domain/recipe.dart';
import 'package:equatable/equatable.dart';

/// Contexte de sous-recette pour une étape provenant d'un bloc référence de
/// base : nom de la sous-recette + position locale (pour le bandeau permanent
/// "Dans : *Nom* · SOUS-RECETTE 2/4", cf. maquette 10d).
class SubRecipeContext extends Equatable {
  const SubRecipeContext({
    required this.baseRecipeName,
    required this.localIndex,
    required this.localTotal,
  });

  final String baseRecipeName;
  final int localIndex;
  final int localTotal;

  @override
  List<Object?> get props => [baseRecipeName, localIndex, localTotal];
}

/// Une étape "jouable" du mode pas-à-pas : unité atomique aplatie à partir de
/// l'arbre `RecipeStep` (une étape texte, ou une sous-étape figée d'un bloc
/// référence de base). Immuable et indépendante du nombre de personnes
/// sélectionné — les quantités affichées sont recalculées à l'affichage.
class PlayableStep extends Equatable {
  const PlayableStep({
    required this.index,
    required this.sourceStepId,
    required this.description,
    this.banner,
    this.ingredients = const [],
    this.subRecipe,
  });

  /// Position 0-based dans la liste aplatie complète.
  final int index;

  /// Id de la `RecipeTextStep` source, ou `'<baseRefId>#<i>'` pour une
  /// sous-étape figée (un `ExpandedStep` ne porte pas d'id propre).
  final String sourceStepId;

  final String description;
  final StepBanner? banner;

  /// Ingrédients bruts (non mis à l'échelle) liés à cette étape.
  final List<RecipeIngredientLine> ingredients;

  /// Non-null si cette étape provient d'un bloc référence de base.
  final SubRecipeContext? subRecipe;

  @override
  List<Object?> get props =>
      [index, sourceStepId, description, banner, ingredients, subRecipe];
}

/// Aplatit l'arbre de `RecipeStep` (étapes texte + sous-étapes figées des
/// blocs référence de base) en une liste ordonnée jouable pas-à-pas.
///
/// Reproduit la logique de numérotation existante (mais dupliquée et privée)
/// de `steps_content.dart` : un `RecipeBaseRefStep` n'est jamais numéroté
/// lui-même, seules ses sous-étapes le sont.
List<PlayableStep> flattenRecipeSteps(List<RecipeStep> steps) {
  final result = <PlayableStep>[];
  for (final step in steps) {
    switch (step) {
      case RecipeTextStep():
        result.add(
          PlayableStep(
            index: result.length,
            sourceStepId: step.id,
            description: step.description,
            banner: step.banner,
            ingredients: step.ingredients,
          ),
        );
      case RecipeBaseRefStep():
        final total = step.steps.length;
        for (var i = 0; i < total; i++) {
          final sub = step.steps[i];
          result.add(
            PlayableStep(
              index: result.length,
              sourceStepId: '${step.id}#$i',
              description: sub.description,
              banner: sub.banner,
              subRecipe: SubRecipeContext(
                baseRecipeName: step.baseRecipeName,
                localIndex: i + 1,
                localTotal: total,
              ),
            ),
          );
        }
    }
  }
  return result;
}
