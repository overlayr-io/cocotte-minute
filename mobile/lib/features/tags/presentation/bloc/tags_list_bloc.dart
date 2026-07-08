import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/tags_repository.dart';
import '../../domain/tag.dart';

part 'tags_list_event.dart';
part 'tags_list_state.dart';

/// Bloc de l'écran "Tags" : liste + création / édition / suppression.
class TagsListBloc extends Bloc<TagsListEvent, TagsListState> {
  TagsListBloc({required TagsRepository repository})
    : _repository = repository,
      super(const TagsListInitial()) {
    on<TagsRequested>(_onRequested);
    on<TagCreated>(_onCreated);
    on<TagUpdated>(_onUpdated);
    on<TagDeleted>(_onDeleted);
  }

  final TagsRepository _repository;

  Future<void> _onRequested(
    TagsRequested event,
    Emitter<TagsListState> emit,
  ) async {
    emit(const TagsListLoading());
    try {
      final tags = await _repository.fetchMine();
      emit(TagsListLoaded(tags: tags));
    } on TagsRepositoryException catch (e) {
      emit(TagsListError(e.message));
    }
  }

  Future<void> _onCreated(TagCreated event, Emitter<TagsListState> emit) async {
    final current = state;
    if (current is! TagsListLoaded) return;
    try {
      await _repository.create(name: event.name, color: event.color);
      emit(TagsListLoaded(tags: await _repository.fetchMine()));
    } on TagsRepositoryException catch (e) {
      emit(TagsListActionFailure(tags: current.tags, message: e.message));
    }
  }

  Future<void> _onUpdated(TagUpdated event, Emitter<TagsListState> emit) async {
    final current = state;
    if (current is! TagsListLoaded) return;
    emit(current.copyWith(busyId: event.id));
    try {
      await _repository.update(event.id, name: event.name, color: event.color);
      emit(TagsListLoaded(tags: await _repository.fetchMine()));
    } on TagsRepositoryException catch (e) {
      emit(TagsListActionFailure(tags: current.tags, message: e.message));
    }
  }

  Future<void> _onDeleted(TagDeleted event, Emitter<TagsListState> emit) async {
    final current = state;
    if (current is! TagsListLoaded) return;
    emit(current.copyWith(busyId: event.id));
    try {
      await _repository.delete(event.id);
      emit(TagsListLoaded(tags: await _repository.fetchMine()));
    } on TagsRepositoryException catch (e) {
      emit(TagsListActionFailure(tags: current.tags, message: e.message));
    }
  }
}
