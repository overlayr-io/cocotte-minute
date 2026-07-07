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
import '../widgets/mobile/mobile_player_view.dart';

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
    SystemChrome.setPreferredOrientations([]);
    WakelockPlus.disable();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        body: BlocBuilder<RecipePlayerCubit, RecipePlayerState>(
          builder: (context, state) {
            return switch (state) {
              RecipePlayerLoading() =>
                const Center(child: CircularProgressIndicator()),
              RecipePlayerError(:final message) => _ErrorView(
                  message: message,
                  onRetry: _cubit.load,
                ),
              RecipePlayerLoaded() => MobilePlayerView(cubit: _cubit),
            };
          },
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
