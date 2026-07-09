import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/premium/premium_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../premium/presentation/pages/premium_page.dart';
import '../../data/shopping_list_repository.dart';
import '../../data/shopping_sync_service.dart';
import '../../domain/shopping_list.dart';
import '../bloc/shopping_lists_cubit.dart';
import 'generate_flow_page.dart';
import 'shopping_list_detail_page.dart';

const Color _gold = Color(0xFF8A7A4E);

/// Onglet « Courses » (écran 5a) — version gratuite : une seule liste active,
/// historique & listes multiples verrouillés (Premium).
class ShoppingPage extends StatefulWidget {
  const ShoppingPage({super.key});

  @override
  State<ShoppingPage> createState() => _ShoppingPageState();
}

class _ShoppingPageState extends State<ShoppingPage> {
  @override
  void initState() {
    super.initState();
    // Démarre l'écoute réseau pour rejouer la file de sync au retour en ligne.
    sl<ShoppingSyncService>().start();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          ShoppingListsCubit(repository: sl<ShoppingListRepository>()),
      child: const _ShoppingView(),
    );
  }
}

class _ShoppingView extends StatelessWidget {
  const _ShoppingView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFEEE4CB), Color(0xFFF3ECD9), AppColors.surface],
          stops: [0, 0.28, 0.55],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: BlocBuilder<ShoppingListsCubit, ShoppingListsState>(
          builder: (context, state) {
            if (state is! ShoppingListsLoaded) {
              return const Center(child: CircularProgressIndicator());
            }
            final active = state.active;
            return RefreshIndicator(
              onRefresh: () => context.read<ShoppingListsCubit>().refresh(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 6, 22, 140),
                children: [
                  _header(context, l10n, hasActive: active != null),
                  const SizedBox(height: 20),
                  if (active != null)
                    _ActiveListCard(list: active)
                  else
                    _EmptyState(l10n: l10n),
                  const SizedBox(height: 14),
                  _CreateButton(hasActive: active != null),
                  // Upsell Premium : jamais montré à un abonné Pro.
                  if (!context.select<PremiumCubit, bool>(
                      (c) => c.state.isPremium)) ...[
                    const SizedBox(height: 26),
                    _LockedHistory(l10n: l10n),
                    const SizedBox(height: 18),
                    const _UpgradeCard(),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _header(
    BuildContext context,
    AppLocalizations l10n, {
    required bool hasActive,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.shoppingTabEyebrow,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _gold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.shoppingTabTitle,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _gold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            l10n.shoppingFreeBadge,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _gold,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActiveListCard extends StatelessWidget {
  const _ActiveListCard({required this.list});

  final ShoppingList list;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () =>
              Navigator.of(context).push(ShoppingListDetailPage.route(list.id)),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primaryTint,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.shopping_cart_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        list.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        l10n.shoppingListSummary(
                          l10n.shoppingItemsCount(list.itemCount),
                          l10n.shoppingRecipesCount(list.recipeCount),
                          0,
                        ),
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 9),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: list.progress,
                          minHeight: 6,
                          backgroundColor: AppColors.pill,
                          valueColor: const AlwaysStoppedAnimation(
                            AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFC4BEAD),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CreateButton extends StatelessWidget {
  const _CreateButton({required this.hasActive});

  final bool hasActive;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: 54,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          backgroundColor: Colors.white.withValues(alpha: 0.55),
          side: const BorderSide(color: Color(0xFFC7BFA9), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: () => Navigator.of(
          context,
        ).push(GenerateFlowPage.route(hasActive: hasActive)),
        icon: const Icon(Icons.add_rounded, size: 20),
        label: Text(
          l10n.shoppingCreateFromRecipes,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    // Pas de carte blanche : l'état vide se fond dans la page.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primaryTint,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.shopping_cart_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.shoppingEmptyTitle,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.shoppingEmptyBody,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _LockedHistory extends StatelessWidget {
  const _LockedHistory({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              size: 16,
              color: Color(0xFFB0AB9B),
            ),
            const SizedBox(width: 8),
            Text(
              l10n.shoppingLockedSectionTitle,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: 0.55,
              child: Column(
                children: const [
                  _GhostRow(),
                  SizedBox(height: 10),
                  _GhostRow(),
                ],
              ),
            ),
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textPrimary.withValues(alpha: 0.25),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(Icons.lock_rounded, color: _gold),
            ),
          ],
        ),
      ],
    );
  }
}

class _GhostRow extends StatelessWidget {
  const _GhostRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 66,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(13),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.pill,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 120, height: 12, color: AppColors.pill),
              const SizedBox(height: 8),
              Container(width: 80, height: 10, color: AppColors.pill),
            ],
          ),
        ],
      ),
    );
  }
}

class _UpgradeCard extends StatelessWidget {
  const _UpgradeCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2E3B2A), Color(0xFF42563A)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.shoppingPremiumKicker.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: Color(0xFFD9C48A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.shoppingPremiumTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.shoppingPremiumBody,
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 13),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () =>
                Navigator.of(context).push(PremiumPage.route()),
            child: Text(
              l10n.shoppingPremiumCta,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
