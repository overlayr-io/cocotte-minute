import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../ingredient_prices/data/ingredient_prices_repository.dart';
import '../../data/recipes_repository.dart';
import '../bloc/recipe_detail_cubit.dart';
import '../widgets/recipe_detail_view.dart';

/// Fiche détail d'une recette. Même page pour une recette normale et une recette
/// de base — les sections varient selon `isBase`. Renvoie `true` au pop si la
/// recette a été modifiée/supprimée, pour que la liste se rafraîchisse.
class RecipeDetailPage extends StatelessWidget {
  const RecipeDetailPage({super.key, required this.recipeId});

  final String recipeId;

  static Route<bool> route(String recipeId) {
    return MaterialPageRoute<bool>(
      builder: (_) => RecipeDetailPage(recipeId: recipeId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RecipeDetailCubit(
        repository: sl<RecipesRepository>(),
        pricesRepository: sl<IngredientPricesRepository>(),
        recipeId: recipeId,
      )..load(),
      child: const RecipeDetailView(),
    );
  }
}
