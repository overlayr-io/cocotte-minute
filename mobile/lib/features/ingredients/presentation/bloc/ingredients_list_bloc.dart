import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/ingredients_repository.dart';
import '../../domain/ingredient.dart';

part 'ingredients_list_event.dart';
part 'ingredients_list_state.dart';

/// Bloc de l'écran "Mes ingrédients" (onglets mine/catalogue + import/suppression).
class IngredientsListBloc extends Bloc<IngredientsListEvent, IngredientsListState> {
  IngredientsListBloc({required IngredientsRepository repository})
    : _repository = repository,
      super(const IngredientsListInitial()) {
    on<IngredientsRequested>(_onRequested);
    on<IngredientSystemImported>(_onImported);
    on<IngredientDeleted>(_onDeleted);
    on<IngredientCreated>(_onCreated);
  }

  final IngredientsRepository _repository;

  Future<void> _onRequested(
    IngredientsRequested event,
    Emitter<IngredientsListState> emit,
  ) async {
    emit(const IngredientsListLoading());
    try {
      final data = await _load();
      emit(data);
    } on IngredientsRepositoryException catch (e) {
      emit(IngredientsListError(e.message));
    }
  }

  Future<void> _onImported(
    IngredientSystemImported event,
    Emitter<IngredientsListState> emit,
  ) async {
    final current = state;
    if (current is! IngredientsListLoaded) return;
    emit(current.copyWith(busyId: event.systemId));
    try {
      await _repository.importSystem(event.systemId);
      emit(await _load());
    } on IngredientsRepositoryException catch (e) {
      emit(
        IngredientsListActionFailure(
          mine: current.mine,
          system: current.system,
          message: e.message,
        ),
      );
    }
  }

  Future<void> _onDeleted(
    IngredientDeleted event,
    Emitter<IngredientsListState> emit,
  ) async {
    final current = state;
    if (current is! IngredientsListLoaded) return;
    emit(current.copyWith(busyId: event.id));
    try {
      await _repository.delete(event.id);
      emit(await _load());
    } on IngredientsRepositoryException catch (e) {
      emit(
        IngredientsListActionFailure(
          mine: current.mine,
          system: current.system,
          message: e.message,
        ),
      );
    }
  }

  Future<void> _onCreated(
    IngredientCreated event,
    Emitter<IngredientsListState> emit,
  ) async {
    final current = state;
    if (current is! IngredientsListLoaded) return;
    emit(current.copyWith());
    try {
      await _repository.create(
        name: event.name,
        unit: event.unit,
        imageUrl: event.imageUrl,
        emoji: event.emoji,
      );
      emit(await _load());
    } on IngredientsRepositoryException catch (e) {
      emit(
        IngredientsListActionFailure(
          mine: current.mine,
          system: current.system,
          message: e.message,
        ),
      );
    }
  }

  Future<IngredientsListLoaded> _load() async {
    final results = await Future.wait([
      _repository.fetchMine(),
      _repository.fetchSystem(),
    ]);
    return IngredientsListLoaded(
      mine: results[0],
      system: results[1],
    );
  }
}
