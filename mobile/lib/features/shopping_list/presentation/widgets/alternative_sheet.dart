import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../ingredients/data/ingredients_repository.dart';
import '../../../ingredients/domain/ingredient.dart';
import '../../domain/shopping_list.dart';

/// Choix retourné par la feuille d'alternative. `alternativeId == null` = retour
/// à l'ingrédient d'origine. Un retour `null` (pop nu) = annulation.
class AlternativeChoice {
  const AlternativeChoice({this.alternativeId, this.alternativeName});
  final String? alternativeId;
  final String? alternativeName;
}

/// Feuille 5h — « Introuvable en magasin ? » : choisir une alternative déclarée
/// pour l'ingrédient. Ne modifie que l'affichage de la liste, jamais la recette.
Future<AlternativeChoice?> showAlternativeSheet(
  BuildContext context,
  ShoppingListItem item,
) {
  return showModalBottomSheet<AlternativeChoice>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
    ),
    builder: (_) => _AlternativeSheet(item: item),
  );
}

class _AlternativeSheet extends StatefulWidget {
  const _AlternativeSheet({required this.item});
  final ShoppingListItem item;

  @override
  State<_AlternativeSheet> createState() => _AlternativeSheetState();
}

class _AlternativeSheetState extends State<_AlternativeSheet> {
  bool _loading = true;
  String? _error;
  List<Ingredient> _alternatives = const [];
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.item.replacedByAlternativeId;
    _load();
  }

  Future<void> _load() async {
    try {
      final detail = await sl<IngredientsRepository>().fetchDetail(
        widget.item.ingredientId!,
      );
      if (!mounted) return;
      setState(() {
        _alternatives = detail.alternatives;
        _loading = false;
      });
    } on IngredientsRepositoryException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 22,
        right: 22,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 26,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFD8D3C7),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accentTint,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.production_quantity_limits_rounded,
                    color: Color(0xFFE1584A), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.shoppingAltTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      l10n.shoppingAltSubtitle(widget.item.name),
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.45,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _body(context, l10n),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, AppLocalizations l10n) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return _hint(Icons.cloud_off_rounded, _error!);
    }
    if (_alternatives.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _hint(Icons.info_outline_rounded, l10n.shoppingAltNone,
              detail: l10n.shoppingAltNoneHint),
          if (widget.item.isReplaced) ...[
            const SizedBox(height: 14),
            _resetButton(context, l10n),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.shoppingAltSection.toUpperCase(),
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: Color(0xFFB0AB9B),
          ),
        ),
        const SizedBox(height: 10),
        for (final alt in _alternatives) ...[
          _AlternativeTile(
            name: alt.name,
            selected: _selectedId == alt.id,
            onTap: () => setState(() => _selectedId = alt.id),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          decoration: BoxDecoration(
            color: AppColors.pill,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 17, color: Color(0xFF8A7A4E)),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  l10n.shoppingAltNote,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 54,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              disabledBackgroundColor: const Color(0xFFF3B7B0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
            ),
            onPressed: _selectedId == null
                ? null
                : () {
                    final alt =
                        _alternatives.firstWhere((a) => a.id == _selectedId);
                    Navigator.of(context).pop(
                      AlternativeChoice(
                        alternativeId: alt.id,
                        alternativeName: alt.name,
                      ),
                    );
                  },
            child: Text(l10n.shoppingAltConfirm),
          ),
        ),
        const SizedBox(height: 8),
        _resetButton(context, l10n),
      ],
    );
  }

  Widget _resetButton(BuildContext context, AppLocalizations l10n) {
    return SizedBox(
      height: 44,
      child: TextButton(
        onPressed: () =>
            Navigator.of(context).pop(const AlternativeChoice()),
        style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
        child: Text(
          widget.item.isReplaced
              ? l10n.shoppingAltReset
              : l10n.shoppingAltKeepOriginal,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
    );
  }

  Widget _hint(IconData icon, String text, {String? detail}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.textMuted),
          const SizedBox(height: 10),
          Text(text, textAlign: TextAlign.center),
          if (detail != null) ...[
            const SizedBox(height: 4),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

class _AlternativeTile extends StatelessWidget {
  const _AlternativeTile({
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF3F7EF) : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFEAF0E4) : AppColors.pill,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                Icons.eco_rounded,
                size: 20,
                color: selected ? AppColors.primary : AppColors.textMuted,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Text(
                name,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.primary : Colors.transparent,
                border: selected
                    ? null
                    : Border.all(color: AppColors.radioIdle, width: 2),
              ),
              child: selected
                  ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
