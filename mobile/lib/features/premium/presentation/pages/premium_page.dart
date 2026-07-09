import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/premium/premium_cubit.dart';
import '../../../../core/premium/premium_models.dart';
import '../../../../core/premium/premium_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../account/presentation/pages/privacy_policy_page.dart';
import '../../../account/presentation/pages/terms_page.dart';
import '../../../auth/presentation/pages/auth_page.dart';
import '../bloc/premium_paywall_cubit.dart';

/// Écran d'offre Cocotte Minute Pro (paywall maison) : proposition de valeur,
/// comparatif gratuit vs Pro, sélecteur mensuel/annuel branché sur les
/// Offerings RevenueCat (prix et essai lus du store, jamais codés en dur),
/// achat natif, restauration et liens légaux. En invité : CTA « Créer un
/// compte » à la place de l'achat (le premium exige un compte inscrit).
class PremiumPage extends StatelessWidget {
  const PremiumPage({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const PremiumPage());

  @override
  Widget build(BuildContext context) {
    final isGuest = context.select<PremiumCubit, bool>((c) => c.state.isGuest);
    return BlocProvider(
      create: (_) => PremiumPaywallCubit(
        repository: sl<PremiumRepository>(),
        isGuest: isGuest,
      )..load(),
      child: const _PaywallView(),
    );
  }
}

class _PaywallView extends StatelessWidget {
  const _PaywallView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEBE0C1), Color(0xFFF1EAD6), AppColors.surface],
            stops: [0, 0.28, 0.55],
          ),
        ),
        child: SafeArea(
          child: BlocConsumer<PremiumPaywallCubit, PremiumPaywallState>(
            listenWhen: (p, c) =>
                p.message != c.message || p.phase != c.phase,
            listener: (context, state) {
              if (state.phase == PaywallPhase.success) {
                // Bref état de succès puis retour à l'écran précédent (le
                // statut global est déjà rafraîchi par le PremiumCubit).
                Future<void>.delayed(const Duration(milliseconds: 1600), () {
                  if (context.mounted) Navigator.of(context).maybePop();
                });
                return;
              }
              final message = state.message;
              if (message != null) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text(_messageText(l10n, message))));
              }
            },
            builder: (context, state) {
              if (state.phase == PaywallPhase.success) {
                return const _SuccessView();
              }
              return switch (state.status) {
                PaywallStatus.loading =>
                  const Center(child: CircularProgressIndicator()),
                PaywallStatus.failure => ErrorView(
                    message: l10n.premiumOfferingsError,
                    onRetry: () => context.read<PremiumPaywallCubit>().load(),
                  ),
                PaywallStatus.ready => _Content(state: state, l10n: l10n),
              };
            },
          ),
        ),
      ),
    );
  }

  String _messageText(AppLocalizations l10n, PaywallMessage message) {
    return switch (message) {
      PaywallMessage.purchasePending => l10n.premiumPurchasePending,
      PaywallMessage.purchaseFailed => l10n.premiumPurchaseFailed,
      PaywallMessage.restoreNone => l10n.premiumRestoreNone,
    };
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.state, required this.l10n});

  final PremiumPaywallState state;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final isPremium =
        context.select<PremiumCubit, bool>((c) => c.state.isPremium);
    final isGuest = context.read<PremiumPaywallCubit>().isGuest;

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 32),
      children: [
        const _Header(),
        const SizedBox(height: 4),
        _HeroCard(l10n: l10n),
        const SizedBox(height: 18),
        _CompareCard(l10n: l10n),
        const SizedBox(height: 18),
        if (isPremium)
          _AlreadyProCard(l10n: l10n)
        else if (isGuest)
          _GuestCard(l10n: l10n)
        else
          _PurchaseArea(state: state, l10n: l10n),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: const LinearGradient(
              colors: [AppColors.premiumGold, AppColors.premiumGoldDark],
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.workspace_premium_rounded,
                  size: 14, color: Colors.white),
              const SizedBox(width: 5),
              Text(
                l10n.premiumBadge,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2E3B2A), Color(0xFF42563A)],
        ),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.premiumHeroKicker.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: Color(0xFFD9C48A),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            l10n.premiumHeroTitle,
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontWeight: FontWeight.w700,
              fontSize: 24,
              letterSpacing: -0.4,
              color: Colors.white,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            l10n.premiumHeroBody,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: Colors.white.withValues(alpha: 0.78),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompareCard extends StatelessWidget {
  const _CompareCard({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String, String)>[
      (
        l10n.premiumCompareRowRecipes,
        l10n.premiumCompareUnlimited,
        l10n.premiumCompareUnlimited,
      ),
      (
        l10n.premiumCompareRowBaseRecipes,
        l10n.premiumCompareBaseFree,
        l10n.premiumCompareUnlimited,
      ),
      (
        l10n.premiumCompareRowShoppingLists,
        l10n.premiumCompareListsFree,
        l10n.premiumCompareListsPro,
      ),
      (
        l10n.premiumCompareRowHistory,
        l10n.premiumCompareHistoryFree,
        l10n.premiumCompareHistoryPro,
      ),
      (
        l10n.premiumCompareRowSearch,
        l10n.premiumCompareSearchFree,
        l10n.premiumCompareSearchPro,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text(
                    l10n.premiumCompareTitle,
                    style: const TextStyle(
                      fontFamily: AppFonts.display,
                      fontWeight: FontWeight.w700,
                      fontSize: 15.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    l10n.premiumCompareFreeColumn,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    l10n.premiumCompareProColumn,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.premiumGoldDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1EEE7)),
          for (var i = 0; i < rows.length; i++) ...[
            _CompareRow(
              label: rows[i].$1,
              free: rows[i].$2,
              pro: rows[i].$3,
            ),
            if (i != rows.length - 1)
              const Divider(height: 1, thickness: 1, color: Color(0xFFF1EEE7)),
          ],
        ],
      ),
    );
  }
}

class _CompareRow extends StatelessWidget {
  const _CompareRow({
    required this.label,
    required this.free,
    required this.pro,
  });

  final String label;
  final String free;
  final String pro;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              free,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              pro,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.premiumGoldDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Zone d'achat : sélecteur mensuel/annuel, mention d'essai (lue du store),
/// bouton d'achat natif, restauration et liens légaux.
class _PurchaseArea extends StatelessWidget {
  const _PurchaseArea({required this.state, required this.l10n});

  final PremiumPaywallState state;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PremiumPaywallCubit>();
    final offering = state.offering;
    if (offering == null || offering.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.premiumGoldTint,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          l10n.premiumOfferingsEmpty,
          style: const TextStyle(
            fontSize: 13.5,
            height: 1.5,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    final monthly = offering.monthly;
    final annual = offering.annual;
    final selected = state.selectedPackage;
    final busy = state.phase != PaywallPhase.idle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (monthly != null)
              Expanded(
                child: _PlanCard(
                  title: l10n.premiumPlanMonthly,
                  price: monthly.priceString,
                  priceSuffix: l10n.premiumPerMonthSuffix,
                  selected: !state.annualSelected || annual == null,
                  badge: null,
                  onTap: busy ? null : () => cubit.selectAnnual(false),
                ),
              ),
            if (monthly != null && annual != null) const SizedBox(width: 10),
            if (annual != null)
              Expanded(
                child: _PlanCard(
                  title: l10n.premiumPlanAnnual,
                  price: annual.priceString,
                  priceSuffix: l10n.premiumPerYearSuffix,
                  selected: state.annualSelected || monthly == null,
                  badge: offering.annualSavingsPercent == null
                      ? null
                      : l10n.premiumSavingsBadge(offering.annualSavingsPercent!),
                  onTap: busy ? null : () => cubit.selectAnnual(true),
                ),
              ),
          ],
        ),
        if (selected != null) ...[
          const SizedBox(height: 12),
          Text(
            _priceMention(selected),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
        const SizedBox(height: 14),
        SizedBox(
          height: 56,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.premiumGold, AppColors.premiumGoldDark],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppShadows.glow(AppColors.premiumGold),
            ),
            child: FilledButton(
              onPressed: busy ? null : cubit.purchase,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: state.phase == PaywallPhase.purchasing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      l10n.premiumSubscribeCta,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: busy ? null : cubit.restore,
          child: state.phase == PaywallPhase.restoring
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  l10n.premiumRestore,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegalLink(
              label: l10n.accountRowTerms,
              onTap: () => Navigator.of(context).push(TermsPage.route()),
            ),
            const Text(
              ' · ',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            _LegalLink(
              label: l10n.accountRowPrivacyPolicy,
              onTap: () =>
                  Navigator.of(context).push(PrivacyPolicyPage.route()),
            ),
          ],
        ),
      ],
    );
  }

  /// Mention sous le sélecteur : essai gratuit (durée lue de l'Introductory
  /// Offer du produit) puis prix, ou juste le prix si pas d'essai.
  String _priceMention(PremiumPackage package) {
    final isAnnual = package == state.offering?.annual;
    final priceText = isAnnual
        ? l10n.premiumPricePerYear(package.priceString)
        : l10n.premiumPricePerMonth(package.priceString);
    final trial = package.trial;
    if (trial == null) return priceText;
    final duration = switch (trial.unit) {
      PremiumTrialUnit.day => l10n.premiumDurationDays(trial.units),
      PremiumTrialUnit.week => l10n.premiumDurationWeeks(trial.units),
      PremiumTrialUnit.month => l10n.premiumDurationMonths(trial.units),
      PremiumTrialUnit.year => l10n.premiumDurationYears(trial.units),
    };
    return l10n.premiumTrialMention(duration, priceText);
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.price,
    required this.priceSuffix,
    required this.selected,
    required this.badge,
    required this.onTap,
  });

  final String title;
  final String price;
  final String priceSuffix;
  final bool selected;
  final String? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        decoration: BoxDecoration(
          color: selected ? AppColors.premiumGoldTint : AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.premiumGold : AppColors.border,
            width: selected ? 1.8 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? AppColors.premiumGoldDark
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badge!,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              price,
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontWeight: FontWeight.w700,
                fontSize: 21,
                letterSpacing: -0.3,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              priceSuffix,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalLink extends StatelessWidget {
  const _LegalLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
            decoration: TextDecoration.underline,
            decorationColor: AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

/// Invité : le premium exige un compte inscrit — explication + CTA réutilisant
/// le flux de création de compte existant.
class _GuestCard extends StatelessWidget {
  const _GuestCard({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF5C7A4C)],
        ),
        boxShadow: AppShadows.glow(const Color(0xFF5C7A4C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.premiumGuestTitle,
            style: const TextStyle(
              fontFamily: AppFonts.display,
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.premiumGuestBody,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton(
              onPressed: () => Navigator.of(context).push(AuthPage.route()),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF4E683F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              child: Text(
                l10n.accountGuestCtaButton,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Déjà abonné : rappel + accès direct à la gestion (Customer Center).
class _AlreadyProCard extends StatelessWidget {
  const _AlreadyProCard({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.premiumGoldTint,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.premiumGold.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_rounded,
                  color: AppColors.premiumGoldDark, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.premiumAlreadyProTitle,
                  style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.premiumAlreadyProBody,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton(
              onPressed: () => sl<PremiumRepository>().showCustomerCenter(),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.premiumGoldDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              child: Text(
                l10n.premiumManageSubscription,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bref état de succès après achat/restauration, avant fermeture automatique.
class _SuccessView extends StatelessWidget {
  const _SuccessView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.premiumGold, AppColors.premiumGoldDark],
                ),
                shape: BoxShape.circle,
                boxShadow: AppShadows.glow(AppColors.premiumGold),
              ),
              child:
                  const Icon(Icons.check_rounded, color: Colors.white, size: 38),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.premiumSuccessTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontWeight: FontWeight.w700,
                fontSize: 23,
                letterSpacing: -0.3,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.premiumSuccessBody,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
