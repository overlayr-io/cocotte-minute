import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../ingredients/domain/ingredient.dart';
import '../../../ingredients/presentation/widgets/unit_selector.dart';
import '../../domain/shopping_list.dart';

/// Formate « quantité + unité » d'un article de liste de courses.
///
/// L'unité est stockée comme identifiant `wire` (« gramme », « piece », ...) pour
/// les articles issus d'une recette, ou en texte libre pour un article ajouté à
/// la main. Renvoie une chaîne vide si ni quantité ni unité.
String shoppingQuantityLabel(
  AppLocalizations l10n,
  double? quantity,
  String? unit,
) {
  final hasUnit = unit != null && unit.isNotEmpty;
  if (quantity == null) return hasUnit ? unit : '';
  final q = formatQuantity(quantity);
  if (!hasUnit) return q;
  final known = IngredientUnit.values.where((u) => u.wire == unit).toList();
  if (known.isNotEmpty) return '$q ${unitShort(l10n, known.first)}';
  return '$q $unit';
}

/// Représentation texte de la liste (nom + articles à acheter, non cochés),
/// pour le partage natif via la feuille OS.
String shoppingListShareText(AppLocalizations l10n, ShoppingListDetail detail) {
  final buffer = StringBuffer()
    ..writeln(detail.list.name)
    ..writeln();
  for (final item in detail.items.where((i) => !i.isChecked)) {
    final qty = shoppingQuantityLabel(l10n, item.quantity, item.unit);
    buffer.writeln(
      qty.isEmpty ? '- ${item.displayName}' : '- ${item.displayName} · $qty',
    );
  }
  return buffer.toString().trimRight();
}
