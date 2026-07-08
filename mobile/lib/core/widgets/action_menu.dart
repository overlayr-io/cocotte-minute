import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';

/// Traitement visuel d'une entrée du menu d'actions « … » (itération 13b).
///
/// - [normal] : action secondaire (label encre, icône grise).
/// - [primary] : action principale de la page (vert), en tête de menu.
/// - [destructive] : action irréversible (corail), isolée en bas du menu.
enum ActionMenuStyle { normal, primary, destructive }

/// Une entrée du menu contextuel « … ». [onSelected] est appelée après la
/// fermeture du popover (le menu se referme, puis l'action s'exécute).
class ActionMenuItem {
  const ActionMenuItem({
    required this.icon,
    required this.label,
    required this.onSelected,
    this.style = ActionMenuStyle.normal,
    this.dividerBefore = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onSelected;
  final ActionMenuStyle style;

  /// Trait de séparation au-dessus de l'entrée (isole l'action destructive).
  final bool dividerBefore;
}

/// Corail des actions destructives dans les menus (fidèle à la maquette 13b).
const Color _kDestructive = Color(0xFFC7503F);

const double _kMenuWidth = 250;
const double _kArrow = 13;
const double _kGap = 7;

/// Ouvre le menu contextuel « … » ancré sous le bouton dont le [context] est
/// passé (typiquement le `BuildContext` d'un `Builder` entourant le bouton).
/// Popover unique de l'app : mêmes actions, même traitement, recette comme
/// liste de courses (remplace les anciens bottom-sheets / PopupMenuButton).
Future<void> showActionMenu({
  required BuildContext context,
  required List<ActionMenuItem> items,
}) {
  final button = context.findRenderObject();
  final overlay = Overlay.of(context).context.findRenderObject();
  Rect anchor;
  if (button is RenderBox && overlay is RenderBox && button.hasSize) {
    final topLeft = button.localToGlobal(Offset.zero, ancestor: overlay);
    anchor = topLeft & button.size;
  } else {
    // Repli : ancrage en haut à droite si le bouton n'est pas mesurable.
    final size = MediaQuery.of(context).size;
    anchor = Rect.fromLTWH(size.width - 56, 40, 40, 40);
  }

  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    // Scrim léger (fidèle à la maquette : la page reste lisible derrière).
    barrierColor: const Color(0x381F2933),
    transitionDuration: const Duration(milliseconds: 150),
    pageBuilder: (_, _, _) => _ActionMenuLayout(anchor: anchor, items: items),
    transitionBuilder: (_, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
          alignment: Alignment.topRight,
          child: child,
        ),
      );
    },
  );
}

class _ActionMenuLayout extends StatelessWidget {
  const _ActionMenuLayout({required this.anchor, required this.items});

  final Rect anchor;
  final List<ActionMenuItem> items;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final size = media.size;
    final width = _kMenuWidth.clamp(0.0, size.width - 24).toDouble();

    // Aligné à droite sous le bouton, borné à l'écran.
    final left = (anchor.right - width).clamp(12.0, size.width - 12 - width);
    final top = anchor.bottom + _kGap;

    // Flèche centrée sur le bouton, bornée dans le popover.
    final arrowCenter =
        (anchor.center.dx - left).clamp(18.0, width - 18).toDouble();

    return Stack(
      children: [
        Positioned(
          left: left,
          top: top,
          width: width,
          child: Material(
            color: Colors.transparent,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppShadows.floating,
                  ),
                  padding: const EdgeInsets.all(7),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final item in items) ...[
                        if (item.dividerBefore)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 3, horizontal: 8),
                            child: Divider(height: 1, color: Color(0xFFF1EEE7)),
                          ),
                        _ActionMenuRow(item: item),
                      ],
                    ],
                  ),
                ),
                // Flèche (petit carré pivoté) pointant vers le bouton.
                Positioned(
                  top: -_kArrow / 2,
                  left: arrowCenter - _kArrow / 2,
                  child: Transform.rotate(
                    angle: 0.7853981633974483, // 45°
                    child: Container(
                      width: _kArrow,
                      height: _kArrow,
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(3),
                        ),
                        border: const Border(
                          left: BorderSide(color: AppColors.border),
                          top: BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionMenuRow extends StatelessWidget {
  const _ActionMenuRow({required this.item});

  final ActionMenuItem item;

  @override
  Widget build(BuildContext context) {
    final (Color labelColor, Color iconColor, FontWeight weight) =
        switch (item.style) {
      ActionMenuStyle.primary => (
          const Color(0xFF5C7A4C),
          const Color(0xFF5C7A4C),
          FontWeight.w700,
        ),
      ActionMenuStyle.destructive => (_kDestructive, _kDestructive, FontWeight.w600),
      ActionMenuStyle.normal => (
          AppColors.textPrimary,
          AppColors.textSecondary,
          FontWeight.w600,
        ),
    };

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.of(context).pop();
        item.onSelected();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 11),
        child: Row(
          children: [
            Icon(item.icon, size: 19, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(fontSize: 14.5, fontWeight: weight, color: labelColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
