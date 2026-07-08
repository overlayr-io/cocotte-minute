import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/recipe_timer.dart';
import '../../bloc/recipe_player_cubit.dart';
import 'add_timer_button.dart';
import 'step_timer_card.dart';
import 'timer_chip.dart';

/// Zones minuteur du lecteur : les SEULS sous-arbres abonnés au tick par
/// seconde du chrono. Les vues parentes ignorent les changements de `timers`
/// via [onlyTimersChanged] dans leur `buildWhen` ; ces widgets se réabonnent
/// avec un [BlocSelector] pour que le décompte défile sans reconstruire
/// toute la vue (texte d'instruction, image, panneau ingrédients…).

/// Carte minuteur de l'étape active, ou bouton d'ajout si aucun minuteur
/// n'est rattaché à l'étape.
class StepTimerZone extends StatelessWidget {
  const StepTimerZone({
    super.key,
    required this.cubit,
    required this.stepId,
    required this.description,
  });

  final RecipePlayerCubit cubit;
  final String stepId;
  final String description;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<RecipePlayerCubit, RecipePlayerState, RecipeTimer?>(
      bloc: cubit,
      selector: (state) =>
          state is RecipePlayerLoaded ? state.timerForStep(stepId) : null,
      builder: (context, timer) => timer != null
          ? StepTimerCard(cubit: cubit, timer: timer)
          : AddTimerButton(
              stepId: stepId,
              description: description,
              cubit: cubit,
            ),
    );
  }
}

/// Chip compacte du minuteur en cours quand il concerne une AUTRE étape que
/// celle affichée (top bar, maquettes 10e/10j). Rien n'est rendu sinon.
class RunningTimerChipZone extends StatelessWidget {
  const RunningTimerChipZone({
    super.key,
    required this.cubit,
    required this.currentStepId,
    this.padding = EdgeInsets.zero,
  });

  final RecipePlayerCubit cubit;
  final String currentStepId;

  /// Espacement appliqué uniquement quand la chip est visible.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<RecipePlayerCubit, RecipePlayerState, RecipeTimer?>(
      bloc: cubit,
      selector: (state) {
        if (state is! RecipePlayerLoaded) return null;
        final running = state.runningTimer;
        return running != null && running.stepId != currentStepId
            ? running
            : null;
      },
      builder: (context, timer) => timer == null
          ? const SizedBox.shrink()
          : Padding(padding: padding, child: TimerChip(timer: timer)),
    );
  }
}
