import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/notifications/local_notifications_service.dart';
import '../../../recipes/data/recipes_repository.dart';
import '../../data/recipe_player_storage.dart';
import '../bloc/recipe_player_cubit.dart';
import '../widgets/shared/quit_dialog.dart';
import '../widgets/mobile/mobile_player_view.dart';
import '../widgets/tablet/tablet_player_view.dart';

/// Tablette à partir de cette largeur logique la plus courte (indépendant de
/// l'orientation, contrairement à `width` seul — cf. convention Material).
const _tabletShortestSideThreshold = 600.0;

/// Page du mode pas-à-pas : verrouille le paysage et garde l'écran allumé
/// tant qu'elle est affichée, quel que soit l'appareil (mobile ou tablette —
/// le choix de layout se fait plus bas dans l'arbre de widgets).
class RecipePlayerPage extends StatefulWidget {
  const RecipePlayerPage({super.key, required this.recipeId});

  final String recipeId;

  static Route<void> route(String recipeId) {
    return MaterialPageRoute<void>(
      builder: (_) => RecipePlayerPage(recipeId: recipeId),
    );
  }

  @override
  State<RecipePlayerPage> createState() => _RecipePlayerPageState();
}

class _RecipePlayerPageState extends State<RecipePlayerPage> {
  late final RecipePlayerCubit _cubit = RecipePlayerCubit(
    repository: sl<RecipesRepository>(),
    storage: sl<RecipePlayerStorage>(),
    notifications: LocalNotificationsService.instance,
    recipeId: widget.recipeId,
  )..load();

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    // Reverrouille en portrait (pas juste « déverrouiller ») : sans ça
    // l'appareil reste libre de rester en paysage à la sortie du mode
    // pas-à-pas, ce qui déroute sur le reste de l'app (portrait-only).
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    WakelockPlus.disable();
    _cubit.close();
    super.dispose();
  }

  /// Retour système (geste iOS / bouton Android) : même comportement que le
  /// bouton X. En pleine cuisson, on confirme puis on quitte en conservant la
  /// reprise ; sinon (écran de lancement ou fin), sortie directe.
  Future<void> _handleSystemBack(BuildContext context) async {
    final navigator = Navigator.of(context);
    final state = _cubit.state;
    if (state is! RecipePlayerLoaded || state.phase != PlayerPhase.playing) {
      navigator.pop();
      return;
    }
    final confirmed = await showQuitDialog(
      context,
      stepIndex: state.currentIndex,
      totalSteps: state.totalSteps,
    );
    if (!confirmed) return;
    await _cubit.quitSession();
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          _handleSystemBack(context);
        },
        child: Scaffold(
          body: BlocBuilder<RecipePlayerCubit, RecipePlayerState>(
          // Le tick par seconde des minuteurs ne doit pas reconstruire la
          // page : seules les zones minuteur s'y abonnent (timer_zones.dart).
          buildWhen: (previous, current) =>
              !onlyTimersChanged(previous, current),
          builder: (context, state) {
            return switch (state) {
              RecipePlayerLoading() =>
                const Center(child: CircularProgressIndicator()),
              RecipePlayerError(:final message) => _ErrorView(
                  message: message,
                  onRetry: _cubit.load,
                ),
              RecipePlayerLoaded() => MediaQuery.sizeOf(context).shortestSide >=
                      _tabletShortestSideThreshold
                  ? TabletPlayerView(cubit: _cubit)
                  : MobilePlayerView(cubit: _cubit),
            };
          },
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: Text(l10n.commonRetry)),
          ],
        ),
      ),
    );
  }
}
