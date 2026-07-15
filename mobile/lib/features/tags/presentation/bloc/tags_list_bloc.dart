import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/tags_repository.dart';
import '../../domain/tag.dart';

part 'tags_list_event.dart';
part 'tags_list_state.dart';

/// Bloc de l'écran "Tags" : onglets mine/catalogue + création / édition /
/// suppression / import.
class TagsListBloc extends Bloc<TagsListEvent, TagsListState> {
  TagsListBloc({required TagsRepository repository})
    : _repository = repository,
      super(const TagsListInitial()) {
    on<TagsRequested>(_onRequested);
    on<TagCreated>(_onCreated);
    on<TagUpdated>(_onUpdated);
    on<TagDeleted>(_onDeleted);
    on<TagSystemImported>(_onImported);
  }

  final TagsRepository _repository;

  Future<void> _onRequested(
    TagsRequested event,
    Emitter<TagsListState> emit,
  ) async {
    emit(const TagsListLoading());
    try {
      emit(await _load());
    } on TagsRepositoryException catch (e) {
      emit(TagsListError(e.message));
    }
  }

  Future<void> _onCreated(TagCreated event, Emitter<TagsListState> emit) async {
    final current = state;
    if (current is! TagsListLoaded) return;
    emit(current.copyWith(creating: true));
    try {
      await _repository.create(name: event.name, color: event.color);
      emit(await _load());
    } on TagsRepositoryException catch (e) {
      emit(
        TagsListActionFailure(
          mine: current.mine,
          system: current.system,
          message: e.message,
        ),
      );
    }
  }

  Future<void> _onUpdated(TagUpdated event, Emitter<TagsListState> emit) async {
    final current = state;
    if (current is! TagsListLoaded) return;
    emit(current.copyWith(busyId: event.id));
    try {
      await _repository.update(event.id, name: event.name, color: event.color);
      emit(await _load());
    } on TagsRepositoryException catch (e) {
      emit(
        TagsListActionFailure(
          mine: current.mine,
          system: current.system,
          message: e.message,
        ),
      );
    }
  }

  Future<void> _onDeleted(TagDeleted event, Emitter<TagsListState> emit) async {
    final current = state;
    if (current is! TagsListLoaded) return;
    emit(current.copyWith(busyId: event.id));
    try {
      await _repository.delete(event.id);
      emit(await _load());
    } on TagsRepositoryException catch (e) {
      emit(
        TagsListActionFailure(
          mine: current.mine,
          system: current.system,
          message: e.message,
        ),
      );
    }
  }

  Future<void> _onImported(
    TagSystemImported event,
    Emitter<TagsListState> emit,
  ) async {
    final current = state;
    if (current is! TagsListLoaded) return;
    emit(current.copyWith(busyId: event.systemId));
    try {
      await _repository.importSystem(event.systemId);
      emit(await _load());
    } on TagsRepositoryException catch (e) {
      emit(
        TagsListActionFailure(
          mine: current.mine,
          system: current.system,
          message: e.message,
        ),
      );
    }
  }

  Future<TagsListLoaded> _load() async {
    final results = await Future.wait([
      _repository.fetchMine(),
      _repository.fetchSystem(),
    ]);
    return TagsListLoaded(mine: results[0], system: results[1]);
  }
}
