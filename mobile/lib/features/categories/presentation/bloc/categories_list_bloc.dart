import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/categories_repository.dart';
import '../../domain/category.dart';

part 'categories_list_event.dart';
part 'categories_list_state.dart';

/// Bloc de la feature "Catégories" : liste à plat de l'arborescence + création
/// / édition / suppression. Un seul bloc alimente l'écran racine et les pages
/// de dossier (poussées en `BlocProvider.value`), qui filtrent par parent.
class CategoriesListBloc extends Bloc<CategoriesListEvent, CategoriesListState> {
  CategoriesListBloc({required CategoriesRepository repository})
    : _repository = repository,
      super(const CategoriesListInitial()) {
    on<CategoriesRequested>(_onRequested);
    on<CategoryCreated>(_onCreated);
    on<CategoryUpdated>(_onUpdated);
    on<CategoryDeleted>(_onDeleted);
  }

  final CategoriesRepository _repository;

  Future<void> _onRequested(
    CategoriesRequested event,
    Emitter<CategoriesListState> emit,
  ) async {
    // Ne montre le spinner qu'au premier chargement : un refresh garde la
    // liste affichée (cache-first + données re-émises à l'arrivée).
    if (state is! CategoriesListLoaded) emit(const CategoriesListLoading());
    try {
      final categories = await _repository.fetchMine(
        forceRefresh: event.forceRefresh,
      );
      emit(CategoriesListLoaded(categories: categories));
    } on CategoriesRepositoryException catch (e) {
      if (state is! CategoriesListLoaded) emit(CategoriesListError(e.message));
    }
  }

  Future<void> _onCreated(
    CategoryCreated event,
    Emitter<CategoriesListState> emit,
  ) async {
    final current = state;
    if (current is! CategoriesListLoaded) return;
    emit(current.copyWith(creating: true));
    try {
      await _repository.create(
        name: event.name,
        icon: event.icon,
        parentCategoryId: event.parentCategoryId,
      );
      emit(CategoriesListLoaded(categories: await _repository.fetchMine()));
    } on CategoriesRepositoryException catch (e) {
      emit(
        CategoriesListActionFailure(
          categories: current.categories,
          message: e.message,
        ),
      );
    }
  }

  Future<void> _onUpdated(
    CategoryUpdated event,
    Emitter<CategoriesListState> emit,
  ) async {
    final current = state;
    if (current is! CategoriesListLoaded) return;
    emit(current.copyWith(busyId: event.id));
    try {
      await _repository.update(event.id, name: event.name, icon: event.icon);
      emit(CategoriesListLoaded(categories: await _repository.fetchMine()));
    } on CategoriesRepositoryException catch (e) {
      emit(
        CategoriesListActionFailure(
          categories: current.categories,
          message: e.message,
        ),
      );
    }
  }

  Future<void> _onDeleted(
    CategoryDeleted event,
    Emitter<CategoriesListState> emit,
  ) async {
    final current = state;
    if (current is! CategoriesListLoaded) return;
    emit(current.copyWith(busyId: event.id));
    try {
      await _repository.delete(event.id);
      emit(CategoriesListLoaded(categories: await _repository.fetchMine()));
    } on CategoriesRepositoryException catch (e) {
      emit(
        CategoriesListActionFailure(
          categories: current.categories,
          message: e.message,
        ),
      );
    }
  }
}
