import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../tags/data/tags_repository.dart';
import '../../../tags/domain/tag.dart';
import '../../../tags/presentation/widgets/tag_colors.dart';

/// Puces des tags associés à la recette (#1) — affichées sur la photo de
/// couverture, au-dessus du titre. Charge le catalogue de tags du compte (mis
/// en cache) puis filtre sur [tagIds] ; ne rend rien tant que rien n'est
/// chargé ou si la recette n'a aucun tag, pour ne jamais décaler la mise en page.
class RecipeTagsRow extends StatelessWidget {
  const RecipeTagsRow({super.key, required this.tagIds});

  final List<String> tagIds;

  @override
  Widget build(BuildContext context) {
    if (tagIds.isEmpty) return const SizedBox.shrink();
    return FutureBuilder<List<Tag>>(
      future: sl<TagsRepository>().fetchMine(),
      builder: (context, snapshot) {
        final all = snapshot.data;
        if (all == null) return const SizedBox.shrink();
        final byId = {for (final t in all) t.id: t};
        final tags =
            tagIds.map((id) => byId[id]).whereType<Tag>().toList(growable: false);
        if (tags.isEmpty) return const SizedBox.shrink();
        return Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final tag in tags)
              _TagPill(name: tag.name, color: TagColors.parse(tag.color)),
          ],
        );
      },
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
