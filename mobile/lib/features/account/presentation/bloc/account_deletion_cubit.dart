import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../auth/data/auth_repository.dart';
import '../../data/account_repository.dart';

part 'account_deletion_state.dart';

/// Pilote le flux de suppression de compte (RGPD) depuis l'écran dédié.
///
/// Enchaîne l'appel serveur (`AccountRepository.requestDeletion`) puis l'action
/// d'auth qui en découle :
/// - compte anonyme → recrée une session anonyme vierge (fresh install) ;
/// - compte complet → déconnexion (retour à l'écran d'auth).
class AccountDeletionCubit extends Cubit<AccountDeletionState> {
  AccountDeletionCubit({
    required AccountRepository accountRepository,
    required AuthRepository authRepository,
  })  : _accountRepository = accountRepository,
        _authRepository = authRepository,
        super(const AccountDeletionInitial());

  final AccountRepository _accountRepository;
  final AuthRepository _authRepository;

  Future<void> requestDeletion() async {
    emit(const AccountDeletionInProgress());
    try {
      final result = await _accountRepository.requestDeletion();
      if (result.anonymous) {
        // Compte anonyme : supprimé côté serveur → on repart sur un compte neuf.
        await _authRepository.recreateAnonymousSession();
        emit(const AccountDeletionGuestRecreated());
      } else {
        // Compte complet : anonymisé + délai de 30 jours → on déconnecte.
        await _authRepository.signOut();
        emit(AccountDeletionPending(
          deletionScheduledAt: result.deletionScheduledAt,
        ));
      }
    } on AccountRepositoryException catch (e) {
      emit(AccountDeletionFailure(e.message));
    } on AuthRepositoryException catch (e) {
      emit(AccountDeletionFailure(e.message));
    }
  }
}
