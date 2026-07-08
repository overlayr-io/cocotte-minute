part of 'help_center_cubit.dart';

enum HelpCenterStatus { initial, loading, success, failure }

class HelpCenterState extends Equatable {
  const HelpCenterState({
    this.status = HelpCenterStatus.initial,
    this.entries = const [],
    this.errorMessage,
  });

  final HelpCenterStatus status;
  final List<FaqEntry> entries;
  final String? errorMessage;

  HelpCenterState copyWith({
    HelpCenterStatus? status,
    List<FaqEntry>? entries,
    String? errorMessage,
  }) {
    return HelpCenterState(
      status: status ?? this.status,
      entries: entries ?? this.entries,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, entries, errorMessage];
}
