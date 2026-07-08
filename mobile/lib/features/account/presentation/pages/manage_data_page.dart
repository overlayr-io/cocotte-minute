import 'package:flutter/material.dart';

import '../../../../core/i18n/generated/app_localizations.dart';
import '../widgets/account_section.dart';
import 'delete_account_page.dart';

/// « Gérer mes données » (RGPD) : ce que l'app conserve, où, et les droits de
/// l'utilisateur (suppression). Accessible connecté comme invité.
class ManageDataPage extends StatelessWidget {
  const ManageDataPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const ManageDataPage());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountRowManageData)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        children: [
          AccountSection(
            title: l10n.manageDataStoredSection,
            tiles: [
              AccountTile(
                icon: Icons.restaurant_menu_rounded,
                label: l10n.manageDataStoredRecipes,
                sublabel: l10n.manageDataStoredRecipesSub,
                showChevron: false,
              ),
              AccountTile(
                icon: Icons.shopping_cart_outlined,
                label: l10n.manageDataStoredShopping,
                sublabel: l10n.manageDataStoredShoppingSub,
                showChevron: false,
              ),
              AccountTile(
                icon: Icons.person_outline_rounded,
                label: l10n.manageDataStoredAccount,
                sublabel: l10n.manageDataStoredAccountSub,
                showChevron: false,
              ),
            ],
          ),
          AccountSection(
            title: l10n.manageDataRightsSection,
            tiles: [
              AccountTile(
                icon: Icons.delete_outline_rounded,
                iconColor: const Color(0xFFE0554A),
                iconBackground: const Color(0xFFFBE9E7),
                labelColor: const Color(0xFFE0554A),
                label: l10n.manageDataDeleteLabel,
                sublabel: l10n.manageDataDeleteSub,
                onTap: () =>
                    Navigator.of(context).push(DeleteAccountPage.route()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
