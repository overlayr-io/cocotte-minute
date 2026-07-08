import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/i18n/locale_cubit.dart';
import '../../../../core/theme/app_colors.dart';

/// Écran de sélection de la langue de l'application.
///
/// Propose « Système (automatique) » (suit la langue du téléphone), Français et
/// English. Le choix est appliqué et persisté immédiatement via [LocaleCubit].
class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const LanguagePage());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<LocaleCubit>();
    final current = context.watch<LocaleCubit>().state;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(l10n.languageTitle),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
              child: Text(
                l10n.languageIntro,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  _LanguageOption(
                    label: l10n.languageSystem,
                    subtitle: l10n.languageSystemSubtitle,
                    selected: current == null,
                    onTap: () => cubit.setLocale(null),
                  ),
                  const Divider(
                      height: 1, thickness: 1, color: Color(0xFFF1EEE7)),
                  _LanguageOption(
                    label: l10n.languageFrench,
                    selected: current?.languageCode == 'fr',
                    onTap: () => cubit.setLocale(const Locale('fr')),
                  ),
                  const Divider(
                      height: 1, thickness: 1, color: Color(0xFFF1EEE7)),
                  _LanguageOption(
                    label: l10n.languageEnglish,
                    selected: current?.languageCode == 'en',
                    onTap: () => cubit.setLocale(const Locale('en')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.label,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  final String label;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                          fontSize: 12.5, color: AppColors.textMuted),
                    ),
                  ],
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_rounded,
                  size: 22, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
