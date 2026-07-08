import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../ingredients/data/ingredients_repository.dart';
import '../../../ingredients/domain/ingredient.dart';

/// État de la feuille « Ajouter des ingrédients » (maquettes 8a/8b/8c).
sealed class AddIngredientsState extends Equatable {
  const AddIngredientsState();

  @override
  List<Object?> get props => const [];
}

class AddIngredientsLoading extends AddIngredientsState {
  const AddIngredientsLoading();
}

class AddIngredientsError extends AddIngredientsState {
  const AddIngredientsError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class AddIngredientsReady extends AddIngredientsState {
  const AddIngredientsReady({
    required this.mine,
    required this.system,
    this.selection = const {},
    this.busyImportId,
    this.message,
  });

  final List<Ingredient> mine;
  final List<Ingredient> system;

  /// Ingrédients sélectionnés → quantité choisie (unité = celle de l'ingrédient).
  final Map<String, double> selection;

  /// Import système en cours (id de l'ingrédient système).
  final String? busyImportId;

  /// Message transitoire (snackbar) — erreur d'import/création non bloquante.
  final String? message;

  AddIngredientsReady copyWith({
    List<Ingredient>? mine,
    List<Ingredient>? system,
    Map<String, double>? selection,
    String? busyImportId,
    String? message,
  }) {
    return AddIngredientsReady(
      mine: mine ?? this.mine,
      system: system ?? this.system,
      selection: selection ?? this.selection,
      busyImportId: busyImportId,
      message: message,
    );
  }

  @override
  List<Object?> get props => [mine, system, selection, busyImportId, message];
}

/// Pilote la sélection d'ingrédients à ajouter à une recette : chargement des
/// listes (mes ingrédients / catalogue), import système et création (auto-
/// sélectionnés). La sélection + quantités sont portées par l'état ; le lien
/// réel à la recette est fait par le `RecipeDetailCubit` au retour de la feuille.
class AddIngredientsCubit extends Cubit<AddIngredientsState> {
  AddIngredientsCubit({required IngredientsRepository repository})
    : _repository = repository,
      super(const AddIngredientsLoading());

  final IngredientsRepository _repository;

  Future<void> load() async {
    emit(const AddIngredientsLoading());
    try {
      final (mine, system) = await _fetchLists();
      emit(AddIngredientsReady(mine: mine, system: system));
    } on IngredientsRepositoryException catch (e) {
      emit(AddIngredientsError(e.message));
    }
  }

  /// (Dé)sélectionne un ingrédient. À la première sélection, quantité par défaut.
  void toggle(Ingredient ingredient) {
    final current = state;
    if (current is! AddIngredientsReady) return;
    final selection = Map<String, double>.of(current.selection);
    if (selection.containsKey(ingredient.id)) {
      selection.remove(ingredient.id);
    } else {
      selection[ingredient.id] = ingredient.unit.defaultQuantity;
    }
    emit(current.copyWith(selection: selection));
  }

  void setQuantity(String ingredientId, double quantity) {
    final current = state;
    if (current is! AddIngredientsReady) return;
    if (!current.selection.containsKey(ingredientId)) return;
    final selection = Map<String, double>.of(current.selection)
      ..[ingredientId] = quantity;
    emit(current.copyWith(selection: selection));
  }

  /// Importe un ingrédient système (crée une copie perso) puis le sélectionne.
  Future<void> importSystem(Ingredient systemIngredient) async {
    final current = state;
    if (current is! AddIngredientsReady) return;
    emit(current.copyWith(busyImportId: systemIngredient.id));
    try {
      final copy = await _repository.importSystem(systemIngredient.id);
      final (mine, system) = await _fetchLists();
      final selection = Map<String, double>.of(current.selection)
        ..[copy.id] = copy.unit.defaultQuantity;
      emit(AddIngredientsReady(mine: mine, system: system, selection: selection));
    } on IngredientsRepositoryException catch (e) {
      emit(current.copyWith(message: e.message));
    }
  }

  /// Crée un ingrédient custom puis le sélectionne (maquette 8c).
  Future<void> createAndSelect({
    required String name,
    required IngredientUnit unit,
  }) async {
    final current = state;
    if (current is! AddIngredientsReady) return;
    try {
      final created = await _repository.create(name: name, unit: unit);
      final (mine, system) = await _fetchLists();
      final selection = Map<String, double>.of(current.selection)
        ..[created.id] = created.unit.defaultQuantity;
      emit(AddIngredientsReady(mine: mine, system: system, selection: selection));
    } on IngredientsRepositoryException catch (e) {
      emit(current.copyWith(message: e.message));
    }
  }

  Future<(List<Ingredient>, List<Ingredient>)> _fetchLists() async {
    final results = await Future.wait([
      _repository.fetchMine(),
      _repository.fetchSystem(),
    ]);
    return (results[0], results[1]);
  }
}
