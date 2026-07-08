import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/widgets/error_view.dart';
import '../../data/help_repository.dart';
import '../../domain/faq_entry.dart';
import '../bloc/help_center_cubit.dart';
import 'contact_page.dart';

/// Centre d'aide : FAQ en accordéon (contenu servi par le serveur) + accès à
/// « Nous contacter ».
class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const HelpCenterPage());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocProvider(
      create: (_) => HelpCenterCubit(repository: sl<HelpRepository>())..load(),
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.accountRowHelpCenter)),
        body: BlocBuilder<HelpCenterCubit, HelpCenterState>(
          builder: (context, state) {
            return switch (state.status) {
              HelpCenterStatus.failure => ErrorView(
                message: state.errorMessage ?? l10n.commonRetry,
                onRetry: () => context.read<HelpCenterCubit>().load(),
              ),
              HelpCenterStatus.success => _Content(entries: state.entries),
              _ => const Center(child: CircularProgressIndicator()),
            };
          },
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.entries});

  final List<FaqEntry> entries;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Text(
          l10n.helpCenterIntro,
          style: const TextStyle(
            fontSize: 13.5,
            height: 1.5,
            color: Color(0xFF8A8574),
          ),
        ),
        const SizedBox(height: 16),
        if (entries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              l10n.helpCenterEmpty,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
            ),
          )
        else
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(18),
              boxShadow: AppShadows.card,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Column(
                children: [
                  for (var i = 0; i < entries.length; i++) ...[
                    _FaqTile(entry: entries[i]),
                    if (i != entries.length - 1)
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFF1EEE7),
                      ),
                  ],
                ],
              ),
            ),
          ),
        const SizedBox(height: 22),
        _ContactCard(
          onTap: () => Navigator.of(context).push(ContactPage.route()),
        ),
      ],
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.entry});

  final FaqEntry entry;

  @override
  Widget build(BuildContext context) {
    return Theme(
      // Retire les séparateurs internes par défaut de l'ExpansionTile.
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        iconColor: AppColors.primary,
        collapsedIconColor: AppColors.textMuted,
        title: Text(
          entry.question,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        children: [
          Text(
            entry.answer,
            style: const TextStyle(
              fontSize: 14,
              height: 1.55,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryTint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.mail_outline_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.helpCenterContactTitle,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.helpCenterContactSubtitle,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: Color(0xFFCBC7BB),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
