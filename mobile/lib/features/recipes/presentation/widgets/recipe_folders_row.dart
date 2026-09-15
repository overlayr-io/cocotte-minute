import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../categories/data/categories_repository.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/presentation/widgets/category_path.dart';

/// Section « Rangée dans » (#1) : chemin complet de chaque dossier associé à
/// la recette, sous la description. Ne rend rien tant que rien n'est chargé
/// ou si la recette n'est dans aucun dossier.
class RecipeFoldersRow extends StatelessWidget {
  const RecipeFoldersRow({super.key, required this.categoryIds});

  final List<String> categoryIds;

  @override
  Widget build(BuildContext context) {
    if (categoryIds.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return FutureBuilder<List<Category>>(
      future: sl<CategoriesRepository>().fetchMine(),
      builder: (context, snapshot) {
        final all = snapshot.data;
        if (all == null) return const SizedBox.shrink();
        final byId = {for (final c in all) c.id: c};
        final folders = categoryIds
            .map((id) => byId[id])
            .whereType<Category>()
            .toList(growable: false);
        if (folders.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.recipeFoldersInlineLabel.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: Color(0xFFA79F8B),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final folder in folders)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.folder_outlined,
                            size: 14, color: AppColors.primary),
                        const SizedBox(width: 5),
                        Text(
                          categoryPath(folder, all),
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}
