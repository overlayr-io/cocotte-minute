import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/auth/auth_bloc.dart';
import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/i18n/locale_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/coming_soon_page.dart';
import '../../../auth/presentation/pages/auth_page.dart';
import '../../../categories/presentation/pages/categories_page.dart';
import '../../../ingredients/presentation/pages/ingredients_page.dart';
import '../../../people/presentation/pages/famille_page.dart';
import '../../../tags/presentation/pages/tags_page.dart';
import '../widgets/account_section.dart';
import 'delete_account_page.dart';
import 'language_page.dart';

/// Onglet Compte : profil invité/connecté + accès au contenu, à la famille,
/// à la gestion du compte, à l'aide et à la confidentialité.
class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authState = context.watch<AuthBloc>().state;
    final isGuest = authState is AuthAuthenticated && authState.isAnonymous;
    final email = authState is AuthAuthenticated ? authState.user.email : null;
    // Rappel J+14 : basé sur la date de création du compte anonyme
    // (`currentUser.createdAt`), jamais sur un stockage local séparé.
    final createdAt = authState is AuthAuthenticated
        ? DateTime.tryParse(authState.user.createdAt)
        : null;
    final showReminder = isGuest &&
        createdAt != null &&
        DateTime.now().difference(createdAt) >= const Duration(days: 14);

    // Écoute la langue courante pour rafraîchir le sous-titre de la tuile.
    context.watch<LocaleCubit>();

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 6, 2, 16),
            child: Text(
              l10n.accountTitle,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
            ),
          ),
          _ProfileCard(isGuest: isGuest, email: email),
          if (showReminder) ...[
            const SizedBox(height: 14),
            _GuestReminder(
              onCreateAccount: () => Navigator.of(context).push(AuthPage.route()),
            ),
          ],

          // Mon contenu — ingrédients / tags / dossiers
          AccountSection(
            title: l10n.accountSectionContent,
            tiles: [
              AccountTile(
                icon: Icons.eco_outlined,
                label: l10n.accountRowIngredients,
                onTap: () => Navigator.of(context).push(IngredientsPage.route()),
              ),
              AccountTile(
                icon: Icons.sell_outlined,
                label: l10n.accountRowTags,
                onTap: () => Navigator.of(context).push(TagsPage.route()),
              ),
              AccountTile(
                icon: Icons.folder_outlined,
                label: l10n.accountRowFolders,
                onTap: () => Navigator.of(context).push(CategoriesPage.route()),
              ),
            ],
          ),

          // Ma famille — personnes
          AccountSection(
            title: l10n.accountSectionFamily,
            tiles: [
              AccountTile(
                icon: Icons.groups_outlined,
                label: l10n.accountRowPersons,
                onTap: () => Navigator.of(context).push(FamillePage.route()),
              ),
            ],
          ),

          // Application — préférences transverses (langue…)
          AccountSection(
            title: l10n.accountSectionApp,
            tiles: [
              AccountTile(
                icon: Icons.translate_rounded,
                iconColor: const Color(0xFF5B6774),
                iconBackground: const Color(0xFFEDF0F3),
                label: l10n.accountRowLanguage,
                trailing: Text(
                  _currentLanguageLabel(context, l10n),
                  style: const TextStyle(
                      fontSize: 13.5, color: AppColors.textMuted),
                ),
                onTap: () => Navigator.of(context).push(LanguagePage.route()),
              ),
            ],
          ),

          // Compte (uniquement connecté) — gérer / déconnexion / suppression
          if (!isGuest)
            AccountSection(
              title: l10n.accountSectionAccount,
              tiles: [
                AccountTile(
                  icon: Icons.settings_outlined,
                  iconColor: const Color(0xFF5B6774),
                  iconBackground: const Color(0xFFEDF0F3),
                  label: l10n.accountRowManage,
                  onTap: () => Navigator.of(context)
                      .push(ComingSoonPage.route(l10n.accountRowManage)),
                ),
                AccountTile(
                  icon: Icons.logout_rounded,
                  iconColor: const Color(0xFF5B6774),
                  iconBackground: const Color(0xFFEDF0F3),
                  label: l10n.accountRowLogout,
                  showChevron: false,
                  onTap: () => context.read<AuthBloc>().add(const AuthSignedOut()),
                ),
                AccountTile(
                  icon: Icons.delete_outline_rounded,
                  iconColor: const Color(0xFFE0554A),
                  iconBackground: const Color(0xFFFBE9E7),
                  labelColor: const Color(0xFFE0554A),
                  label: l10n.accountRowDelete,
                  onTap: () =>
                      Navigator.of(context).push(DeleteAccountPage.route()),
                ),
              ],
            ),

          // Aide
          AccountSection(
            title: l10n.accountSectionHelp,
            tiles: [
              AccountTile(
                icon: Icons.help_outline_rounded,
                iconColor: const Color(0xFF5B6774),
                iconBackground: const Color(0xFFEDF0F3),
                label: l10n.accountRowHelpCenter,
                onTap: () => Navigator.of(context)
                    .push(ComingSoonPage.route(l10n.accountRowHelpCenter)),
              ),
              AccountTile(
                icon: Icons.mail_outline_rounded,
                iconColor: const Color(0xFF5B6774),
                iconBackground: const Color(0xFFEDF0F3),
                label: l10n.accountRowContact,
                onTap: () => Navigator.of(context)
                    .push(ComingSoonPage.route(l10n.accountRowContact)),
              ),
            ],
          ),

          // Confidentialité
          AccountSection(
            title: l10n.accountSectionPrivacy,
            tiles: [
              AccountTile(
                icon: Icons.shield_outlined,
                iconColor: const Color(0xFF5B6774),
                iconBackground: const Color(0xFFEDF0F3),
                label: l10n.accountRowPrivacyPolicy,
                onTap: () => Navigator.of(context)
                    .push(ComingSoonPage.route(l10n.accountRowPrivacyPolicy)),
              ),
              AccountTile(
                icon: Icons.description_outlined,
                iconColor: const Color(0xFF5B6774),
                iconBackground: const Color(0xFFEDF0F3),
                label: l10n.accountRowTerms,
                onTap: () => Navigator.of(context)
                    .push(ComingSoonPage.route(l10n.accountRowTerms)),
              ),
              AccountTile(
                icon: Icons.privacy_tip_outlined,
                iconColor: const Color(0xFF5B6774),
                iconBackground: const Color(0xFFEDF0F3),
                label: l10n.accountRowManageData,
                onTap: () => Navigator.of(context)
                    .push(ComingSoonPage.route(l10n.accountRowManageData)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Libellé de la langue actuellement sélectionnée (pour le sous-titre de la tuile).
String _currentLanguageLabel(BuildContext context, AppLocalizations l10n) {
  final locale = context.read<LocaleCubit>().state;
  return switch (locale?.languageCode) {
    'fr' => l10n.languageFrench,
    'en' => l10n.languageEnglish,
    _ => l10n.languageSystem,
  };
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.isGuest, required this.email});

  final bool isGuest;
  final String? email;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final displayName = isGuest
        ? l10n.accountGuestName
        : (email != null && email!.contains('@') ? email!.split('@').first : l10n.navAccount);
    final initial = (!isGuest && email != null && email!.isNotEmpty)
        ? email!.substring(0, 1).toUpperCase()
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _Avatar(isGuest: isGuest, initial: initial),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isGuest ? l10n.accountGuestSubtitle : (email ?? ''),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          if (isGuest) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF1EAD6),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                l10n.accountGuestBadge,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF8A7A4E),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.isGuest, this.initial});

  final bool isGuest;
  final String? initial;

  @override
  Widget build(BuildContext context) {
    if (isGuest || initial == null) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFFF1EEE4),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFC9C3B4), width: 2),
        ),
        child: const Icon(Icons.person_outline_rounded, color: Color(0xFFA79F8B)),
      );
    }
    return Container(
      width: 56,
      height: 56,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8FAE7C), AppColors.primary],
        ),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial!,
        style: const TextStyle(
          fontFamily: AppFonts.display,
          fontWeight: FontWeight.w700,
          fontSize: 20,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _GuestReminder extends StatelessWidget {
  const _GuestReminder({required this.onCreateAccount});

  final VoidCallback onCreateAccount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF6F61), Color(0xFFF0574A)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6F61).withValues(alpha: 0.5),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.access_time_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.accountReminderTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            l10n.accountReminderBody,
            style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.45),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton(
              onPressed: onCreateAccount,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFF0574A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              child: Text(
                l10n.accountReminderCta,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
