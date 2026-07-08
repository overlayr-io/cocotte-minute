import 'package:flutter/material.dart';

import '../../../../core/widgets/app_network_image.dart';

/// Avatar d'une personne. Si aucune image n'est fournie, on dérive un avatar par
/// défaut : initiale du prénom sur une couleur stable choisie d'après le nom.
/// (L'upload d'image réel sera branché plus tard.)
class PersonAvatar extends StatelessWidget {
  const PersonAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 46,
  });

  final String name;
  final String? imageUrl;
  final double size;

  static const List<(Color bg, Color fg)> _palette = [
    (Color(0xFFEAD9C4), Color(0xFF8A6A3E)),
    (Color(0xFFD8E0D2), Color(0xFF5C7A4C)),
    (Color(0xFFE1DCEB), Color(0xFF6E5A8F)),
    (Color(0xFFE1EAF5), Color(0xFF3D6DA8)),
    (Color(0xFFFBE4E1), Color(0xFFB14A3F)),
    (Color(0xFFF6EEDD), Color(0xFFB8862F)),
  ];

  String get _initial {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '?' : trimmed.characters.first.toUpperCase();
  }

  (Color, Color) get _colors {
    final key = name.trim().isEmpty ? 0 : name.trim().toLowerCase().hashCode.abs();
    return _palette[key % _palette.length];
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: cachedImageProvider(context, imageUrl!, logicalWidth: size),
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    final (bg, fg) = _colors;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Text(
        _initial,
        style: TextStyle(
          fontFamily: 'Bricolage Grotesque',
          fontWeight: FontWeight.w700,
          fontSize: size * 0.4,
          color: fg,
        ),
      ),
    );
  }
}
