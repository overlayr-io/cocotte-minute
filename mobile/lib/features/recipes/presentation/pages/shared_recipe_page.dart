import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/supabase/supabase_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../ingredients/domain/ingredient.dart';
import '../../../ingredients/presentation/widgets/unit_selector.dart';
import '../../domain/recipe.dart';
import '../bloc/shared_recipe_cubit.dart';
import '../widgets/step_banner.dart';
import 'recipe_detail_page.dart';

/// Écran d'une recette ouverte via un lien de partage (deep link). Chargée en
/// lecture seule depuis son token public. Si la recette appartient à
/// l'utilisateur courant, on bascule vers la fiche complète (édition possible).
class SharedRecipePage extends StatelessWidget {
  const SharedRecipePage({super.key, required this.token});

  final String token;

  static Route<void> route(String token) {
    return MaterialPageRoute<void>(
      builder: (_) => SharedRecipePage(token: token),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          SharedRecipeCubit(repository: sl(), token: token)..load(),
      child: const _SharedRecipeScaffold(),
    );
  }
}

class _SharedRecipeScaffold extends StatelessWidget {
  const _SharedRecipeScaffold();

  String? get _currentUserId {
    try {
      return SupabaseService.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<SharedRecipeCubit, SharedRecipeState>(
        listenWhen: (_, curr) => curr is SharedRecipeLoaded,
        listener: (context, state) {
          if (state is! SharedRecipeLoaded) return;
          // Recette possédée par l'utilisateur courant → fiche complète éditable.
          if (state.detail.authorId == _currentUserId) {
            Navigator.of(context)
                .pushReplacement(RecipeDetailPage.route(state.detail.id));
          }
        },
        builder: (context, state) {
          return switch (state) {
            SharedRecipeLoading() =>
              const Center(child: CircularProgressIndicator()),
            SharedRecipeError(:final message) => ErrorView(
              message: message,
              onRetry: () => context.read<SharedRecipeCubit>().load(),
            ),
            SharedRecipeLoaded(:final detail) =>
              _SharedRecipeView(detail: detail, l10n: l10n),
          };
        },
      ),
    );
  }
}

class _SharedRecipeView extends StatelessWidget {
  const _SharedRecipeView({required this.detail, required this.l10n});

  final RecipeDetail detail;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _Hero(detail: detail)),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          sliver: SliverList.list(
            children: [
              _badge(),
              const SizedBox(height: 12),
              Text(
                detail.name,
                style: const TextStyle(
                  fontFamily: AppFonts.display,
                  fontWeight: FontWeight.w700,
                  fontSize: 28,
                  height: 1.05,
                  letterSpacing: -0.5,
                  color: AppColors.textPrimary,
                ),
              ),
              if (detail.description != null &&
                  detail.description!.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  detail.description!,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.55,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              _metaChips(),
              const SizedBox(height: 26),
              _sectionTitle(l10n.recipeIngredientsSection, detail.ingredients.length),
              const SizedBox(height: 12),
              ..._ingredientRows(context),
              const SizedBox(height: 26),
              _sectionTitle(l10n.recipeStepsTab, _flatSteps().length),
              const SizedBox(height: 14),
              ..._stepRows(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _badge() => Container(
    padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
    decoration: BoxDecoration(
      color: AppColors.primaryTint,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.link_rounded, size: 15, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          l10n.sharedRecipeBadge.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: AppColors.primary,
          ),
        ),
      ],
    ),
  );

  Widget _metaChips() {
    final chips = <Widget>[
      _metaChip(Icons.people_alt_outlined,
          l10n.recipeServingsShort(detail.summary.servings)),
    ];
    if (detail.summary.prepTime > 0) {
      chips.add(_metaChip(
          Icons.schedule_rounded, l10n.recipePrepShort(detail.summary.prepTime)));
    }
    if (detail.summary.cookTime > 0) {
      chips.add(_metaChip(Icons.local_fire_department_outlined,
          l10n.recipeCookShort(detail.summary.cookTime)));
    }
    if (detail.summary.restTime > 0) {
      chips.add(_metaChip(
          Icons.bedtime_outlined, l10n.recipeRestShort(detail.summary.restTime)));
    }
    return Wrap(spacing: 8, runSpacing: 8, children: chips);
  }

  Widget _metaChip(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 7),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    ),
  );

  Widget _sectionTitle(String title, int count) => Row(
    crossAxisAlignment: CrossAxisAlignment.baseline,
    textBaseline: TextBaseline.alphabetic,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontFamily: AppFonts.display,
          fontWeight: FontWeight.w700,
          fontSize: 21,
          letterSpacing: -0.2,
          color: AppColors.textPrimary,
        ),
      ),
      const SizedBox(width: 8),
      Text(
        '$count',
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textMuted,
        ),
      ),
    ],
  );

  List<Widget> _ingredientRows(BuildContext context) {
    if (detail.ingredients.isEmpty) {
      return [
        Text(l10n.pdfNoIngredients,
            style: const TextStyle(color: AppColors.textMuted)),
      ];
    }
    return [
      for (final line in detail.ingredients)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 2),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.divider)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(
                  color: AppColors.pill,
                  shape: BoxShape.circle,
                ),
                child: line.imageUrl != null
                    ? AppNetworkImage(line.imageUrl!, width: 40, height: 40)
                    : const Icon(Icons.egg_alt_outlined,
                        size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  line.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                formatQuantityWithUnit(
                    l10n, line.quantity, IngredientUnit.fromWire(line.unit)),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4B5563),
                ),
              ),
            ],
          ),
        ),
    ];
  }

  /// Étapes aplaties (texte + sous-étapes de base dépliées), numérotées en continu.
  List<({int number, String description, StepBanner? banner})> _flatSteps() {
    final out = <({int number, String description, StepBanner? banner})>[];
    var n = 0;
    for (final step in detail.steps) {
      switch (step) {
        case RecipeTextStep():
          out.add((number: ++n, description: step.description, banner: step.banner));
        case RecipeBaseRefStep():
          for (final s in step.steps) {
            out.add((number: ++n, description: s.description, banner: s.banner));
          }
      }
    }
    return out;
  }

  List<Widget> _stepRows() {
    final steps = _flatSteps();
    if (steps.isEmpty) {
      return [
        Text(l10n.pdfNoSteps, style: const TextStyle(color: AppColors.textMuted)),
      ];
    }
    return [
      for (final step in steps)
        Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.textPrimary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${step.number}',
                  style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        step.description,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.55,
                          color: Color(0xFF33404B),
                        ),
                      ),
                    ),
                    if (step.banner != null) StepBannerBox(banner: step.banner!),
                  ],
                ),
              ),
            ],
          ),
        ),
    ];
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.detail});

  final RecipeDetail detail;

  @override
  Widget build(BuildContext context) {
    final photoUrl = detail.summary.photoUrl;
    return Stack(
      children: [
        SizedBox(
          height: 260,
          width: double.infinity,
          child: photoUrl != null
              ? AppNetworkImage(photoUrl, width: double.infinity, height: 260)
              : const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFEAD9BE), Color(0xFFCBB48C)],
                    ),
                  ),
                ),
        ),
        Positioned(
          top: 0,
          left: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.of(context).maybePop(),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.chevron_left_rounded,
                        color: AppColors.textPrimary),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
