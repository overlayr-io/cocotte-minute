import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/auth/auth_bloc.dart';
import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/i18n/locale_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/widgets/coming_soon_page.dart';
import '../../../auth/presentation/pages/auth_page.dart';
import '../../../categories/presentation/pages/categories_page.dart';
import '../../../help/presentation/pages/contact_page.dart';
import '../../../help/presentation/pages/help_center_page.dart';
import '../../../ingredients/presentation/pages/ingredients_page.dart';
import '../../../people/presentation/pages/famille_page.dart';
import '../../../tags/presentation/pages/tags_page.dart';
import '../widgets/account_section.dart';
import 'delete_account_page.dart';
import 'language_page.dart';
import 'manage_data_page.dart';
import 'privacy_policy_page.dart';
import 'terms_page.dart';

/// Onglet Compte : profil invité/connecté + accès au contenu, à la famille,
/// à la gestion du compte, à l'aide et à la confidentialité.
class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // select : ne reconstruit la page que si ces valeurs changent,
    // pas à chaque émission de l'AuthBloc (refresh de session, etc.).
    final (isGuest, email) = context.select<AuthBloc, (bool, String?)>((bloc) {
      final s = bloc.state;
      return s is AuthAuthenticated
          ? (s.isAnonymous, s.user.email)
          : (false, null);
    });

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
          // Invitation permanente à créer un compte (remplace le rappel J+14).
          if (isGuest) ...[
            const SizedBox(height: 14),
            _GuestCta(
              onCreateAccount: () =>
                  Navigator.of(context).push(AuthPage.route()),
            ),
          ],

          // Mon contenu — ingrédients / tags / dossiers
          AccountSection(
            title: l10n.accountSectionContent,
            tiles: [
              AccountTile(
                icon: Icons.eco_outlined,
                label: l10n.accountRowIngredients,
                onTap: () =>
                    Navigator.of(context).push(IngredientsPage.route()),
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
                    fontSize: 13.5,
                    color: AppColors.textMuted,
                  ),
                ),
                onTap: () => Navigator.of(context).push(LanguagePage.route()),
              ),
            ],
          ),

          // Compte — gérer (connecté) / déconnexion / suppression. Visible aussi
          // en invité : la déconnexion prévient de la perte de données et la
          // suppression passe par le circuit anonyme (purge immédiate).
          AccountSection(
            title: l10n.accountSectionAccount,
            tiles: [
              if (!isGuest)
                AccountTile(
                  icon: Icons.settings_outlined,
                  iconColor: const Color(0xFF5B6774),
                  iconBackground: const Color(0xFFEDF0F3),
                  label: l10n.accountRowManage,
                  onTap: () => Navigator.of(
                    context,
                  ).push(ComingSoonPage.route(l10n.accountRowManage)),
                ),
              AccountTile(
                icon: Icons.logout_rounded,
                iconColor: const Color(0xFF5B6774),
                iconBackground: const Color(0xFFEDF0F3),
                label: l10n.accountRowLogout,
                sublabel: isGuest ? l10n.accountGuestLogoutSublabel : null,
                showChevron: false,
                onTap: () => _signOut(context, isGuest: isGuest),
              ),
              AccountTile(
                icon: Icons.delete_outline_rounded,
                iconColor: const Color(0xFFE0554A),
                iconBackground: const Color(0xFFFBE9E7),
                labelColor: const Color(0xFFE0554A),
                label: isGuest
                    ? l10n.accountRowDeleteGuest
                    : l10n.accountRowDelete,
                sublabel: isGuest ? l10n.accountGuestDeleteSublabel : null,
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
                onTap: () => Navigator.of(context).push(HelpCenterPage.route()),
              ),
              AccountTile(
                icon: Icons.mail_outline_rounded,
                iconColor: const Color(0xFF5B6774),
                iconBackground: const Color(0xFFEDF0F3),
                label: l10n.accountRowContact,
                onTap: () => Navigator.of(context).push(ContactPage.route()),
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
                onTap: () =>
                    Navigator.of(context).push(PrivacyPolicyPage.route()),
              ),
              AccountTile(
                icon: Icons.description_outlined,
                iconColor: const Color(0xFF5B6774),
                iconBackground: const Color(0xFFEDF0F3),
                label: l10n.accountRowTerms,
                onTap: () => Navigator.of(context).push(TermsPage.route()),
              ),
              AccountTile(
                icon: Icons.privacy_tip_outlined,
                iconColor: const Color(0xFF5B6774),
                iconBackground: const Color(0xFFEDF0F3),
                label: l10n.accountRowManageData,
                onTap: () => Navigator.of(context).push(ManageDataPage.route()),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _VersionFooter(),
        ],
      ),
    );
  }

  /// Déconnexion. En invité : dialogue d'avertissement (la session anonyme et
  /// ses données ne seront plus accessibles), avec « créer un compte » mis en
  /// avant comme alternative.
  Future<void> _signOut(BuildContext context, {required bool isGuest}) async {
    final bloc = context.read<AuthBloc>();
    if (!isGuest) {
      bloc.add(const AuthSignedOut());
      return;
    }
    final l10n = AppLocalizations.of(context);
    final action = await showDialog<_GuestLogoutAction>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.accountGuestLogoutTitle),
        content: Text(l10n.accountGuestLogoutBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(_GuestLogoutAction.signOut),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(l10n.accountGuestLogoutConfirm),
          ),
          FilledButton(
            onPressed: () => Navigator.of(
              dialogContext,
            ).pop(_GuestLogoutAction.createAccount),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(l10n.accountGuestCtaButton),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    switch (action) {
      case _GuestLogoutAction.createAccount:
        Navigator.of(context).push(AuthPage.route());
      case _GuestLogoutAction.signOut:
        bloc.add(const AuthSignedOut());
      case null:
        break;
    }
  }
}

enum _GuestLogoutAction { signOut, createAccount }

/// Numéro de version/build de l'app, affiché en bas de la page compte.
class _VersionFooter extends StatelessWidget {
  const _VersionFooter();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final info = snapshot.data;
        if (info == null) return const SizedBox.shrink();
        return Center(
          child: Text(
            'Cocotte Minute · v${info.version} (${info.buildNumber})',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        );
      },
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
        : (email != null && email!.contains('@')
              ? email!.split('@').first
              : l10n.navAccount);
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
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
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
        child: const Icon(
          Icons.person_outline_rounded,
          color: Color(0xFFA79F8B),
        ),
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

/// Carte permanente d'invitation à créer un compte (mode invité) : titre,
/// sous-titre et un unique bouton « Créer ton compte ».
class _GuestCta extends StatelessWidget {
  const _GuestCta({required this.onCreateAccount});

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
          colors: [AppColors.primary, Color(0xFF5C7A4C)],
        ),
        boxShadow: AppShadows.glow(const Color(0xFF5C7A4C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.accountGuestCtaTitle,
            style: const TextStyle(
              fontFamily: AppFonts.display,
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.accountGuestCtaBody,
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
              onPressed: onCreateAccount,
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
