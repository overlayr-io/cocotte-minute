import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/recipe_player_cubit.dart';
import '../mobile/mobile_finish_view.dart';
import '../shared/resume_dialog.dart';
import '../shared/switch_recipe_warning_dialog.dart';
import 'tablet_active_step_view.dart';
import 'tablet_launch_view.dart';
import 'tablet_summary_view.dart';

/// Point d'entrée tablette (split-écran) du mode pas-à-pas : bascule entre
/// lancement (10a), cuisson active (10b) et fin, avec un sommaire des étapes
/// (10c) accessible à tout moment pendant la cuisson.
class TabletPlayerView extends StatefulWidget {
  const TabletPlayerView({super.key, required this.cubit});

  final RecipePlayerCubit cubit;

  @override
  State<TabletPlayerView> createState() => _TabletPlayerViewState();
}

class _TabletPlayerViewState extends State<TabletPlayerView> {
  bool _showSummary = false;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RecipePlayerCubit, RecipePlayerState>(
      bloc: widget.cubit,
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
        final cubit = widget.cubit;

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
          PlayerPhase.launch =>
            TabletLaunchView(cubit: widget.cubit, state: state),
          PlayerPhase.playing => _showSummary
              ? TabletSummaryView(
                  cubit: widget.cubit,
                  state: state,
                  onClose: () => setState(() => _showSummary = false),
                )
              : TabletActiveStepView(
                  cubit: widget.cubit,
                  state: state,
                  onOpenSummary: () => setState(() => _showSummary = true),
                ),
          PlayerPhase.finished =>
            MobileFinishView(cubit: widget.cubit, state: state),
        };
      },
    );
  }
}
