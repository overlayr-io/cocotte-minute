import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/account_repository.dart';
import '../../domain/account_deletion.dart';

part 'account_status_state.dart';

/// Pilote la bannière d'annulation de suppression (RGPD).
///
/// Lit le statut du compte (`GET /account/status`) au démarrage : si le compte
/// est `pending_deletion`, la bannière s'affiche et propose d'annuler la
/// suppression (`cancelDeletion`). Statut purement informatif/non bloquant : en
/// cas d'échec de lecture, on masque simplement la bannière (jamais de page
/// d'erreur).
class AccountStatusCubit extends Cubit<AccountStatusState> {
  AccountStatusCubit({required AccountRepository accountRepository})
      : _accountRepository = accountRepository,
        super(const AccountStatusHidden());

  final AccountRepository _accountRepository;

  /// Charge le statut courant. Idempotent : peut être rappelé (ex: refresh).
  Future<void> load() async {
    try {
      final result = await _accountRepository.getStatus();
      if (result.status == AccountStatus.pendingDeletion) {
        emit(AccountStatusPending(
          deletionScheduledAt: result.deletionScheduledAt,
        ));
      } else {
        emit(const AccountStatusHidden());
      }
    } on AccountRepositoryException {
      // Bannière non critique : on la masque en silence si la lecture échoue.
      emit(const AccountStatusHidden());
    }
  }

  /// Annule la suppression en attente puis masque la bannière.
  Future<void> cancelDeletion() async {
    final current = state;
    if (current is! AccountStatusPending) return;
    emit(current.copyWith(cancelling: true));
    try {
      await _accountRepository.cancelDeletion();
      emit(const AccountStatusCancelSuccess());
      emit(const AccountStatusHidden());
    } on AccountRepositoryException catch (e) {
      emit(AccountStatusCancelFailure(e.message));
      // On garde la bannière visible pour permettre une nouvelle tentative.
      emit(current.copyWith(cancelling: false));
    }
  }
}
