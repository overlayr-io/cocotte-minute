import 'package:flutter/material.dart';

import '../../../../../core/i18n/generated/app_localizations.dart';
import '../../../domain/playable_step.dart';

/// Bandeau de contexte permanent affiché quand l'étape active provient d'une
/// référence de recette de base (maquette 10d) : « Dans : *Nom* · SOUS-RECETTE
/// N / total ».
class SubRecipeStrip extends StatelessWidget {
  const SubRecipeStrip({super.key, required this.subRecipe});

  final SubRecipeContext subRecipe;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      color: const Color(0xFFEDF2E7),
      child: Row(
        children: [
          const Icon(Icons.link_rounded, size: 16, color: Color(0xFF5C7A4C)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.playerSubRecipeContext(subRecipe.baseRecipeName),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13.5, color: Color(0xFF4B6340)),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFE2ECD7),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              l10n.playerSubRecipeBadge(subRecipe.localIndex, subRecipe.localTotal),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF5C7A4C),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
