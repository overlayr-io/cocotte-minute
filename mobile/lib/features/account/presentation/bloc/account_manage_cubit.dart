import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../auth/data/auth_repository.dart';

/// Dernière action réussie, pour afficher la confirmation adaptée côté UI.
enum AccountManageOutcome { none, emailUpdated, passwordUpdated }

class AccountManageState extends Equatable {
  const AccountManageState({
    this.savingEmail = false,
    this.savingPassword = false,
    this.message,
    this.outcome = AccountManageOutcome.none,
  });

  final bool savingEmail;
  final bool savingPassword;

  /// Message d'échec transitoire (snackbar), consommé puis remis à null.
  final String? message;

  /// Issue transitoire de la dernière opération réussie (snackbar de succès).
  final AccountManageOutcome outcome;

  AccountManageState copyWith({
    bool? savingEmail,
    bool? savingPassword,
    String? message,
    AccountManageOutcome? outcome,
  }) {
    return AccountManageState(
      savingEmail: savingEmail ?? this.savingEmail,
      savingPassword: savingPassword ?? this.savingPassword,
      message: message,
      outcome: outcome ?? AccountManageOutcome.none,
    );
  }

  @override
  List<Object?> get props => [savingEmail, savingPassword, message, outcome];
}

/// Cubit de la page « Gérer le compte » (utilisateur connecté) : modification
/// de l'e-mail et du mot de passe via Supabase Auth. Chaque opération est
/// indépendante (deux boutons d'enregistrement distincts).
class AccountManageCubit extends Cubit<AccountManageState> {
  AccountManageCubit(this._auth) : super(const AccountManageState());

  final AuthRepository _auth;

  String? get currentEmail => _auth.currentEmail;

  Future<void> updateEmail(String email) async {
    emit(state.copyWith(savingEmail: true));
    try {
      await _auth.updateEmail(email);
      emit(state.copyWith(
        savingEmail: false,
        outcome: AccountManageOutcome.emailUpdated,
      ));
    } on AuthRepositoryException catch (e) {
      emit(state.copyWith(savingEmail: false, message: e.message));
    }
  }

  Future<void> updatePassword(String password) async {
    emit(state.copyWith(savingPassword: true));
    try {
      await _auth.updatePassword(password);
      emit(state.copyWith(
        savingPassword: false,
        outcome: AccountManageOutcome.passwordUpdated,
      ));
    } on AuthRepositoryException catch (e) {
      emit(state.copyWith(savingPassword: false, message: e.message));
    }
  }
}
