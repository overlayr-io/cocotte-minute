import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../ingredient_prices/data/ingredient_prices_repository.dart';
import '../../../ingredient_prices/domain/ingredient_price.dart';
import '../../data/ingredients_repository.dart';
import '../../domain/ingredient.dart';

part 'ingredient_detail_event.dart';
part 'ingredient_detail_state.dart';

/// Bloc de l'écran détail d'un ingrédient (édition, alternatives, suppression,
/// prix — feature prix-estime).
class IngredientDetailBloc extends Bloc<IngredientDetailEvent, IngredientDetailState> {
  IngredientDetailBloc({
    required IngredientsRepository repository,
    required IngredientPricesRepository pricesRepository,
  }) : _repository = repository,
       _pricesRepository = pricesRepository,
       super(const IngredientDetailLoading()) {
    on<IngredientDetailRequested>(_onRequested);
    on<IngredientDetailSaveRequested>(_onSave);
    on<IngredientAlternativeAdded>(_onAlternativeAdded);
    on<IngredientAlternativeRemoved>(_onAlternativeRemoved);
    on<IngredientDetailDeleteRequested>(_onDelete);
  }

  final IngredientsRepository _repository;
  final IngredientPricesRepository _pricesRepository;
  late String _id;

  Future<void> _onRequested(
    IngredientDetailRequested event,
    Emitter<IngredientDetailState> emit,
  ) async {
    _id = event.id;
    emit(const IngredientDetailLoading());
    try {
      final detail = await _repository.fetchDetail(_id);
      final price = await _fetchPrice();
      emit(IngredientDetailLoaded(detail: detail, price: price));
    } on IngredientsRepositoryException catch (e) {
      emit(IngredientDetailError(e.message));
    }
  }

  /// Le prix est secondaire à la fiche : un échec de chargement n'empêche pas
  /// d'afficher l'ingrédient (état neutre "prix inconnu").
  Future<IngredientPrice?> _fetchPrice() async {
    try {
      final prices = await _pricesRepository.fetchMine();
      for (final p in prices) {
        if (p.ingredientId == _id) return p;
      }
      return null;
    } on IngredientPricesRepositoryException {
      return null;
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
      if (event.savePrice) {
        // bas/haut envoyés ensemble seulement s'ils sont tous les deux connus
        // (palier premium) : ne jamais écraser une fourchette déjà enregistrée
        // quand seule la moyenne est renvoyée (gratuit, ou premium désabonné).
        if (event.lowPrice != null && event.highPrice != null) {
          await _pricesRepository.upsert(
            _id,
            priceReferenceUnit: event.priceReferenceUnit!,
            averagePrice: event.averagePrice,
            lowPrice: event.lowPrice,
            highPrice: event.highPrice,
          );
        } else {
          await _pricesRepository.upsert(
            _id,
            priceReferenceUnit: event.priceReferenceUnit!,
            averagePrice: event.averagePrice,
          );
        }
      }
      emit(const IngredientDetailSaved());
    } on IngredientsRepositoryException catch (e) {
      emit(IngredientDetailActionFailure(
        detail: current.detail,
        price: current.price,
        message: e.message,
      ));
    } on IngredientPricesRepositoryException catch (e) {
      emit(IngredientDetailActionFailure(
        detail: current.detail,
        price: current.price,
        message: e.message,
      ));
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
      emit(IngredientDetailActionFailure(
        detail: current.detail,
        price: current.price,
        message: e.message,
      ));
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
      emit(IngredientDetailLoaded(detail: detail, price: current.price));
    } on IngredientsRepositoryException catch (e) {
      emit(IngredientDetailActionFailure(
        detail: current.detail,
        price: current.price,
        message: e.message,
      ));
    }
  }
}
