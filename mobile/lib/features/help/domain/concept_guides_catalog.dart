import 'package:flutter/material.dart';

import '../../../core/i18n/generated/app_localizations.dart';
import 'concept_guide.dart';

/// Catalogue des guides de concepts (#13), construit depuis l'i18n. L'ordre suit
/// la logique d'apprentissage : la brique la plus structurante (recettes de
/// base) d'abord, puis rangement, foyer, courses, planning.
List<ConceptGuide> conceptGuides(AppLocalizations l10n) => [
      ConceptGuide(
        id: 'base',
        icon: Icons.blender_outlined,
        title: l10n.conceptBaseTitle,
        summary: l10n.conceptBaseSummary,
        intro: l10n.conceptBaseIntro,
        sections: [
          ConceptSection(l10n.conceptBaseS1Title, l10n.conceptBaseS1Body),
          ConceptSection(l10n.conceptBaseS2Title, l10n.conceptBaseS2Body),
        ],
      ),
      ConceptGuide(
        id: 'folders',
        icon: Icons.folder_outlined,
        title: l10n.conceptFoldersTitle,
        summary: l10n.conceptFoldersSummary,
        intro: l10n.conceptFoldersIntro,
        sections: [
          ConceptSection(l10n.conceptFoldersS1Title, l10n.conceptFoldersS1Body),
          ConceptSection(l10n.conceptFoldersS2Title, l10n.conceptFoldersS2Body),
        ],
      ),
      ConceptGuide(
        id: 'tags',
        icon: Icons.sell_outlined,
        title: l10n.conceptTagsTitle,
        summary: l10n.conceptTagsSummary,
        intro: l10n.conceptTagsIntro,
        sections: [
          ConceptSection(l10n.conceptTagsS1Title, l10n.conceptTagsS1Body),
          ConceptSection(l10n.conceptTagsS2Title, l10n.conceptTagsS2Body),
        ],
      ),
      ConceptGuide(
        id: 'people',
        icon: Icons.groups_outlined,
        title: l10n.conceptPeopleTitle,
        summary: l10n.conceptPeopleSummary,
        intro: l10n.conceptPeopleIntro,
        sections: [
          ConceptSection(l10n.conceptPeopleS1Title, l10n.conceptPeopleS1Body),
          ConceptSection(l10n.conceptPeopleS2Title, l10n.conceptPeopleS2Body),
        ],
      ),
      ConceptGuide(
        id: 'shopping',
        icon: Icons.shopping_cart_outlined,
        title: l10n.conceptShoppingTitle,
        summary: l10n.conceptShoppingSummary,
        intro: l10n.conceptShoppingIntro,
        sections: [
          ConceptSection(
              l10n.conceptShoppingS1Title, l10n.conceptShoppingS1Body),
          ConceptSection(
              l10n.conceptShoppingS2Title, l10n.conceptShoppingS2Body),
        ],
      ),
      ConceptGuide(
        id: 'planning',
        icon: Icons.calendar_month_outlined,
        title: l10n.conceptPlanningTitle,
        summary: l10n.conceptPlanningSummary,
        intro: l10n.conceptPlanningIntro,
        sections: [
          ConceptSection(
              l10n.conceptPlanningS1Title, l10n.conceptPlanningS1Body),
          ConceptSection(
              l10n.conceptPlanningS2Title, l10n.conceptPlanningS2Body),
        ],
      ),
    ];
