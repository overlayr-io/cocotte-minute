import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../data/help_repository.dart';

part 'contact_state.dart';

/// Pilote l'envoi d'un message « Nous contacter ». Joint la version d'app au
/// message (confort de support). Échec = message non bloquant (snackbar).
class ContactCubit extends Cubit<ContactState> {
  ContactCubit({required HelpRepository repository})
    : _repository = repository,
      super(const ContactState());

  final HelpRepository _repository;

  Future<void> send({required String subject, required String message}) async {
    emit(state.copyWith(status: ContactStatus.sending));
    try {
      String? appVersion;
      try {
        final info = await PackageInfo.fromPlatform();
        appVersion = '${info.version}+${info.buildNumber}';
      } on Object {
        appVersion = null; // version indisponible : on envoie quand même
      }
      await _repository.sendContact(
        subject: subject,
        message: message,
        appVersion: appVersion,
      );
      emit(state.copyWith(status: ContactStatus.success));
    } on HelpRepositoryException catch (e) {
      emit(
        state.copyWith(status: ContactStatus.failure, errorMessage: e.message),
      );
    }
  }
}
