import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../people/presentation/widgets/person_avatar.dart';
import '../../../tags/presentation/widgets/tag_colors.dart';
import '../../domain/search_token.dart';
import 'search_colors.dart';

/// Pastille d'un critère posé, affichée sous la ligne de saisie. Le style dépend
/// de la dimension : dossier = pastille verte pleine, tag = pastille blanche +
/// point coloré, personne = pastille blanche + mini-avatar.
class SearchPastille extends StatelessWidget {
  const SearchPastille({super.key, required this.token, required this.onRemove});

  final SearchToken token;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return switch (token) {
      FolderToken(:final category) => _shell(
          background: SearchColors.folderTint,
          border: SearchColors.folderBorder,
          closeColor: SearchColors.folderText,
          leading: Text(
            '/',
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontWeight: FontWeight.w800,
              fontSize: 13.5,
              color: SearchColors.folderText,
            ),
          ),
          label: category.name,
          labelColor: SearchColors.folderText,
        ),
      TagToken(:final tag) => _shell(
          background: Colors.white,
          border: AppColors.border,
          closeColor: AppColors.textMuted,
          leading: Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: TagColors.parse(tag.color),
              shape: BoxShape.circle,
            ),
          ),
          label: tag.name,
          labelColor: AppColors.textPrimary,
        ),
      PersonToken(:final person) => _shell(
          background: Colors.white,
          border: AppColors.border,
          closeColor: AppColors.textMuted,
          leading: PersonAvatar(
            name: person.displayName,
            imageUrl: person.avatarUrl,
            size: 20,
          ),
          label: person.firstName,
          labelColor: AppColors.textPrimary,
        ),
    };
  }

  Widget _shell({
    required Color background,
    required Color border,
    required Color closeColor,
    required Widget leading,
    required String label,
    required Color labelColor,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 5, 8, 5),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading,
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: labelColor,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            behavior: HitTestBehavior.opaque,
            child: Icon(Icons.close_rounded, size: 14, color: closeColor),
          ),
        ],
      ),
    );
  }
}
