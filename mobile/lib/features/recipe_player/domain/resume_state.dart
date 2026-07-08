import 'package:equatable/equatable.dart';

import 'recipe_timer.dart';

/// Version sérialisable d'un [RecipeTimer], pour la persistance locale.
class PersistedTimer extends Equatable {
  const PersistedTimer({
    required this.id,
    required this.stepId,
    required this.totalDurationSeconds,
    required this.status,
    this.label,
    this.endTimeMillis,
  });

  final String id;
  final String stepId;
  final int totalDurationSeconds;
  final TimerStatus status;
  final String? label;

  /// Horodatage absolu (epoch ms) auquel le minuteur se termine, `null` si
  /// non démarré ou en pause.
  final int? endTimeMillis;

  factory PersistedTimer.fromJson(Map<String, dynamic> json) => PersistedTimer(
        id: json['id'] as String,
        stepId: json['stepId'] as String,
        totalDurationSeconds: json['totalDurationSeconds'] as int,
        status: TimerStatus.values.byName(json['status'] as String),
        label: json['label'] as String?,
        endTimeMillis: json['endTimeMillis'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'stepId': stepId,
        'totalDurationSeconds': totalDurationSeconds,
        'status': status.name,
        'label': label,
        'endTimeMillis': endTimeMillis,
      };

  @override
  List<Object?> get props =>
      [id, stepId, totalDurationSeconds, status, label, endTimeMillis];
}

/// État de reprise persisté localement (un seul emplacement global — une
/// seule session de cuisson à la fois, cf. `docs/features/step-by-step.md`).
///
/// Contient [recipeName] (et non seulement [recipeId]) pour pouvoir afficher
/// l'avertissement de conflit inter-recettes sans requête réseau.
class ResumeState extends Equatable {
  const ResumeState({
    required this.recipeId,
    required this.recipeName,
    required this.selectedServings,
    required this.currentIndex,
    required this.sessionStartedAtMillis,
    this.timers = const [],
  });

  final String recipeId;
  final String recipeName;

  /// Nombre de personnes choisi au lancement — conservé pour que la reprise
  /// affiche les mêmes quantités que la session interrompue.
  final int selectedServings;
  final int currentIndex;
  final int sessionStartedAtMillis;
  final List<PersistedTimer> timers;

  factory ResumeState.fromJson(Map<String, dynamic> json) => ResumeState(
        recipeId: json['recipeId'] as String,
        recipeName: json['recipeName'] as String,
        selectedServings: json['selectedServings'] as int,
        currentIndex: json['currentIndex'] as int,
        sessionStartedAtMillis: json['sessionStartedAtMillis'] as int,
        timers: ((json['timers'] as List<dynamic>?) ?? const [])
            .cast<Map<String, dynamic>>()
            .map(PersistedTimer.fromJson)
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'recipeId': recipeId,
        'recipeName': recipeName,
        'selectedServings': selectedServings,
        'currentIndex': currentIndex,
        'sessionStartedAtMillis': sessionStartedAtMillis,
        'timers': timers.map((t) => t.toJson()).toList(),
      };

  @override
  List<Object?> get props => [
        recipeId,
        recipeName,
        selectedServings,
        currentIndex,
        sessionStartedAtMillis,
        timers,
      ];
}
