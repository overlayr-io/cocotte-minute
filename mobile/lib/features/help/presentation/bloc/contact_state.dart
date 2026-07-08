part of 'contact_cubit.dart';

enum ContactStatus { initial, sending, success, failure }

class ContactState extends Equatable {
  const ContactState({this.status = ContactStatus.initial, this.errorMessage});

  final ContactStatus status;
  final String? errorMessage;

  bool get isSending => status == ContactStatus.sending;

  ContactState copyWith({ContactStatus? status, String? errorMessage}) {
    return ContactState(
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage];
}
