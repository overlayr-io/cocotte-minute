import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/help_repository.dart';
import '../../domain/faq_entry.dart';

part 'help_center_state.dart';

/// Charge la FAQ du centre d'aide (lecture seule). Échec = page d'erreur avec
/// retry (contenu principal de l'écran).
class HelpCenterCubit extends Cubit<HelpCenterState> {
  HelpCenterCubit({required HelpRepository repository})
    : _repository = repository,
      super(const HelpCenterState());

  final HelpRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: HelpCenterStatus.loading));
    try {
      final entries = await _repository.fetchFaq();
      emit(state.copyWith(status: HelpCenterStatus.success, entries: entries));
    } on HelpRepositoryException catch (e) {
      emit(
        state.copyWith(
          status: HelpCenterStatus.failure,
          errorMessage: e.message,
        ),
      );
    }
  }
}
