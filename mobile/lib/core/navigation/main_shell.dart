import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/account/data/account_repository.dart';
import '../../features/account/presentation/bloc/account_status_cubit.dart';
import '../../features/account/presentation/pages/account_page.dart';
import '../../features/account/presentation/widgets/cancel_deletion_banner.dart';
import '../../features/auth/presentation/pages/auth_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/meal_plan/presentation/pages/planning_page.dart';
import '../../features/onboarding/data/onboarding_service.dart';
import '../../features/recipes/presentation/pages/recipes_page.dart';
import '../../features/shopping_list/data/shopping_sync_service.dart';
import '../../features/shopping_list/presentation/pages/shopping_page.dart';
import '../auth/auth_bloc.dart';
import '../di/service_locator.dart';
import '../i18n/generated/app_localizations.dart';
import '../theme/app_colors.dart';

/// Coquille de navigation principale : 5 onglets (Accueil, Recettes, Planning,
/// Courses, Compte) sous une barre flottante, façon maquette Cocotte Minute.
///
/// Pas de routeur dédié pour l'instant : un simple [IndexedStack] conserve
/// l'état de chaque onglet. Les sous-écrans (ingrédients, etc.) sont poussés via
/// [Navigator] par-dessus la coquille.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0; // Accueil par défaut.

  @override
  void initState() {
    super.initState();
    // La sync des courses au retour réseau doit vivre dès le boot, même si
    // l'onglet Courses (désormais chargé à la première visite) n'est jamais
    // ouvert. Idempotent — l'appel de shopping_page reste sans effet.
    sl<ShoppingSyncService>().start();
    // Onboarding (#12) : au 1er lancement de CE compte, semer des recettes
    // d'exemple pour montrer le but de l'app. Idempotent (serveur) + gardé par
    // un flag local par compte ; non bloquant. La session Supabase est prête
    // ici (MainShell n'est monté qu'après `AuthAuthenticated`), et ce
    // `initState` précède le build de l'accueil, qui attend `pending`.
    _startOnboarding();
    // Rappel J+14 (informatif, jamais bloquant) : à chaque lancement, si le
    // compte anonyme a plus de 2 semaines, on invite à créer un compte.
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowGuestReminder());
  }

  /// Le semis est scopé au compte courant : l'id vient de l'`AuthBloc` (état
  /// déjà authentifié, cf. `_AuthGate`), pas d'un flag global à l'appareil.
  void _startOnboarding() {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    sl<OnboardingService>().start(authState.user.id);
  }

  void _maybeShowGuestReminder() {
    if (!mounted) return;
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated || !authState.isAnonymous) return;
    // Date de création du compte anonyme = `currentUser.createdAt`
    // (pas de stockage local séparé, cf. auth.md).
    final createdAt = DateTime.tryParse(authState.user.createdAt);
    if (createdAt == null ||
        DateTime.now().difference(createdAt) < const Duration(days: 14)) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.accountReminderTitle),
        content: Text(l10n.accountReminderBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.guestReminderDialogDismiss),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).push(AuthPage.route());
            },
            child: Text(l10n.accountReminderCta),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      const HomePage(),
      const RecipesPage(),
      const PlanningPage(),
      const ShoppingPage(),
      const AccountPage(),
    ];

    // Bannière d'annulation RGPD : globale à tous les onglets, chargée au
    // démarrage. N'affiche rien tant que le compte n'est pas `pending_deletion`.
    return BlocProvider<AccountStatusCubit>(
      create: (_) =>
          AccountStatusCubit(accountRepository: sl<AccountRepository>())..load(),
      child: Scaffold(
        extendBody: true,
        backgroundColor: AppColors.surface,
        body: Column(
          children: [
            const CancelDeletionBanner(),
            Expanded(child: _LazyIndexedStack(index: _index, children: tabs)),
          ],
        ),
        bottomNavigationBar: _CocotteNavBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
        ),
      ),
    );
  }
}

/// IndexedStack paresseux : un onglet n'est construit (et son cubit chargé)
/// qu'à sa première visite, puis reste monté comme avec un IndexedStack
/// classique. Évite 4 chargements réseau/DB simultanés au premier frame.
class _LazyIndexedStack extends StatefulWidget {
  const _LazyIndexedStack({required this.index, required this.children});

  final int index;
  final List<Widget> children;

  @override
  State<_LazyIndexedStack> createState() => _LazyIndexedStackState();
}

class _LazyIndexedStackState extends State<_LazyIndexedStack> {
  late final List<bool> _visited =
      List<bool>.filled(widget.children.length, false);

  @override
  Widget build(BuildContext context) {
    _visited[widget.index] = true;
    return IndexedStack(
      index: widget.index,
      children: [
        for (var i = 0; i < widget.children.length; i++)
          _visited[i] ? widget.children[i] : const SizedBox.shrink(),
      ],
    );
  }
}

class _CocotteNavBar extends StatelessWidget {
  const _CocotteNavBar({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = <_NavItemData>[
      _NavItemData(Icons.home_outlined, Icons.home_rounded, l10n.navHome),
      _NavItemData(Icons.menu_book_outlined, Icons.menu_book_rounded, l10n.navRecipes),
      _NavItemData(
          Icons.calendar_month_outlined, Icons.calendar_month_rounded, l10n.navPlanning),
      _NavItemData(
          Icons.shopping_cart_outlined, Icons.shopping_cart_rounded, l10n.navShopping),
      _NavItemData(Icons.person_outline_rounded, Icons.person_rounded, l10n.navAccount),
    ];

    // Barre flottante calée tout en bas comme la maquette : marge fixe de 16px
    // sous la barre (mesurée depuis le bas de l'écran).
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppColors.textPrimary.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.16),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (var i = 0; i < items.length; i++)
              _NavItem(
                data: items[i],
                selected: i == currentIndex,
                onTap: () => onTap(i),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItemData {
  const _NavItemData(this.icon, this.activeIcon, this.label);

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.data, required this.selected, required this.onTap});

  final _NavItemData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : const Color(0xFFB0B4B8);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? data.activeIcon : data.icon, color: color, size: 24),
            const SizedBox(height: 3),
            Text(
              data.label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
