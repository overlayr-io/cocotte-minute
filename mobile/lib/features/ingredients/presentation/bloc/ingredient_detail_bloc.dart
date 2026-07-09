import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/ingredients_repository.dart';
import '../../domain/ingredient.dart';

part 'ingredient_detail_event.dart';
part 'ingredient_detail_state.dart';

/// Bloc de l'écran détail d'un ingrédient (édition, alternatives, suppression).
class IngredientDetailBloc extends Bloc<IngredientDetailEvent, IngredientDetailState> {
  IngredientDetailBloc({required IngredientsRepository repository})
    : _repository = repository,
      super(const IngredientDetailLoading()) {
    on<IngredientDetailRequested>(_onRequested);
    on<IngredientDetailSaveRequested>(_onSave);
    on<IngredientAlternativeAdded>(_onAlternativeAdded);
    on<IngredientAlternativeRemoved>(_onAlternativeRemoved);
    on<IngredientDetailDeleteRequested>(_onDelete);
  }

  final IngredientsRepository _repository;
  late String _id;

  Future<void> _onRequested(
    IngredientDetailRequested event,
    Emitter<IngredientDetailState> emit,
  ) async {
    _id = event.id;
    emit(const IngredientDetailLoading());
    try {
      final detail = await _repository.fetchDetail(_id);
      emit(IngredientDetailLoaded(detail: detail));
    } on IngredientsRepositoryException catch (e) {
      emit(IngredientDetailError(e.message));
    }
  }

  Future<void> _onSave(
    IngredientDetailSaveRequested event,
    Emitter<IngredientDetailState> emit,
  ) async {
    final current = state;
    if (current is! IngredientDetailLoaded) return;
    emit(current.copyWith(mutating: true));
    try {
      await _repository.update(
        _id,
        name: event.name,
        unit: event.unit,
        // Envoie explicitement les deux (null = vidé) : le serveur applique
        // l'exclusivité emoji ↔ image.
        emoji: event.emoji,
        imageUrl: event.imageUrl,
      );
      emit(const IngredientDetailSaved());
    } on IngredientsRepositoryException catch (e) {
      emit(IngredientDetailActionFailure(detail: current.detail, message: e.message));
    }
  }

  Future<void> _onAlternativeAdded(
    IngredientAlternativeAdded event,
    Emitter<IngredientDetailState> emit,
  ) async {
    await _mutateThenReload(
      emit,
      () => _repository.addAlternative(_id, event.alternativeId),
    );
  }

  Future<void> _onAlternativeRemoved(
    IngredientAlternativeRemoved event,
    Emitter<IngredientDetailState> emit,
  ) async {
    await _mutateThenReload(
      emit,
      () => _repository.removeAlternative(_id, event.alternativeId),
    );
  }

  Future<void> _onDelete(
    IngredientDetailDeleteRequested event,
    Emitter<IngredientDetailState> emit,
  ) async {
    final current = state;
    if (current is! IngredientDetailLoaded) return;
    emit(current.copyWith(mutating: true));
    try {
      await _repository.delete(_id);
      emit(const IngredientDetailDeleted());
    } on IngredientsRepositoryException catch (e) {
      emit(IngredientDetailActionFailure(detail: current.detail, message: e.message));
    }
  }

  /// Exécute une mutation d'alternative puis recharge le détail (relation
  /// symétrique gérée côté serveur).
  Future<void> _mutateThenReload(
    Emitter<IngredientDetailState> emit,
    Future<void> Function() mutation,
  ) async {
    final current = state;
    if (current is! IngredientDetailLoaded) return;
    emit(current.copyWith(mutating: true));
    try {
      await mutation();
      final detail = await _repository.fetchDetail(_id);
      emit(IngredientDetailLoaded(detail: detail));
    } on IngredientsRepositoryException catch (e) {
      emit(IngredientDetailActionFailure(detail: current.detail, message: e.message));
    }
  }
}
