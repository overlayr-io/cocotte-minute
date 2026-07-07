import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/recipe_player_cubit.dart';
import '../shared/resume_dialog.dart';
import '../shared/switch_recipe_warning_dialog.dart';
import 'mobile_active_step_view.dart';
import 'mobile_finish_view.dart';
import 'mobile_launch_view.dart';

/// Point d'entrée mobile paysage du mode pas-à-pas : bascule entre lancement
/// (10a), cuisson active (10d-10j) et fin (10g) selon la phase, et affiche
/// les dialogs de reprise (10h) / conflit inter-recettes dès qu'ils
/// deviennent pertinents.
class MobilePlayerView extends StatelessWidget {
  const MobilePlayerView({super.key, required this.cubit});

  final RecipePlayerCubit cubit;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RecipePlayerCubit, RecipePlayerState>(
      bloc: cubit,
      listenWhen: (previous, current) {
        if (current is! RecipePlayerLoaded) return false;
        final hadPending = previous is RecipePlayerLoaded &&
            (previous.pendingResume != null ||
                previous.pendingSwitchWarning != null);
        return !hadPending &&
            (current.pendingResume != null ||
                current.pendingSwitchWarning != null);
      },
      listener: (context, state) async {
        if (state is! RecipePlayerLoaded) return;
        final switchWarning = state.pendingSwitchWarning;
        if (switchWarning != null) {
          final confirmed = await showSwitchRecipeWarningDialog(
            context,
            otherRecipeName: switchWarning.recipeName,
            otherStepIndex: switchWarning.stepIndex,
          );
          if (confirmed) {
            await cubit.confirmSwitchRecipe();
          } else if (context.mounted) {
            Navigator.of(context).pop();
          }
          return;
        }

        final resume = state.pendingResume;
        if (resume != null) {
          final minutesAgo = DateTime.now()
              .difference(
                DateTime.fromMillisecondsSinceEpoch(resume.sessionStartedAtMillis),
              )
              .inMinutes;
          final shouldResume = await showResumeDialog(
            context,
            stepIndex: resume.currentIndex,
            totalSteps: state.totalSteps,
            minutesAgo: minutesAgo,
          );
          if (shouldResume) {
            await cubit.resumeSession();
          } else {
            cubit.dismissResume();
          }
        }
      },
      builder: (context, state) {
        if (state is! RecipePlayerLoaded) return const SizedBox.shrink();
        return switch (state.phase) {
          PlayerPhase.launch => MobileLaunchView(cubit: cubit, state: state),
          PlayerPhase.playing =>
            MobileActiveStepView(cubit: cubit, state: state),
          PlayerPhase.finished => MobileFinishView(cubit: cubit, state: state),
        };
      },
    );
  }
}
