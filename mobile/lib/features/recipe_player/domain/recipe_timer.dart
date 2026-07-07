import 'package:equatable/equatable.dart';

/// Statut d'un minuteur du mode pas-à-pas.
enum TimerStatus { idle, running, paused, done }

/// Un minuteur du mode pas-à-pas, rattaché à une étape via [stepId].
///
/// Toujours manipulé comme un élément d'une **liste** côté état (jamais un
/// singleton), même si un seul minuteur est actif à la fois en v1 — cf.
/// `docs/features/step-by-step.md` (ne pas fermer la porte au multi-minuteurs).
/// [endTime] est un horodatage absolu (pas un simple décompte) pour que le
/// temps restant reste correct après une mise en arrière-plan ou un kill de
/// l'app.
class RecipeTimer extends Equatable {
  const RecipeTimer({
    required this.id,
    required this.stepId,
    required this.totalDuration,
    required this.status,
    this.label,
    this.remaining,
    this.endTime,
  });

  final String id;
  final String stepId;
  final Duration totalDuration;
  final TimerStatus status;
  final String? label;

  /// Temps restant, recalculé à chaque tick depuis [endTime]. `null` tant que
  /// le minuteur n'a jamais démarré.
  final Duration? remaining;

  /// Horodatage cible pendant que le minuteur tourne. `null` si `idle`/`done`
  /// ou en pause (le temps restant est alors figé dans [remaining]).
  final DateTime? endTime;

  RecipeTimer copyWith({
    TimerStatus? status,
    Duration? remaining,
    DateTime? endTime,
    bool clearEndTime = false,
  }) {
    return RecipeTimer(
      id: id,
      stepId: stepId,
      totalDuration: totalDuration,
      label: label,
      status: status ?? this.status,
      remaining: remaining ?? this.remaining,
      endTime: clearEndTime ? null : (endTime ?? this.endTime),
    );
  }

  @override
  List<Object?> get props =>
      [id, stepId, totalDuration, status, label, remaining, endTime];
}
