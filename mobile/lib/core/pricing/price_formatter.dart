/// Formate un montant en euros, arrondi à 2 décimales, convention FR (virgule,
/// symbole après le nombre) — quelle que soit la précision de stockage (3
/// décimales, cf. `docs/features/prix-estime.md`). Toujours 2 décimales
/// affichées : un prix montre "3,00 €", jamais "3 €" (contrairement à
/// `formatQuantity`, qui retire les zéros de fin).
String formatPrice(double value) {
  final formatted = value.toStringAsFixed(2).replaceAll('.', ',');
  return '$formatted €';
}

/// Variante "estimation partielle" (recette dont un ou plusieurs ingrédients
/// n'ont pas de prix renseigné, ou combinaison d'unités inconvertible) :
/// préfixe `≈` devant le montant, cf. doc — jamais de fourchette bas/haut
/// affichée au niveau recette, même en premium.
String formatPriceEstimate(double value, {required bool isPartial}) {
  final formatted = formatPrice(value);
  return isPartial ? '≈ $formatted' : formatted;
}

/// Parse une saisie utilisateur (virgule ou point, espaces ignorés) en
/// montant. `null` si la chaîne est vide ou invalide (champ vidé → prix
/// inconnu, jamais une erreur bloquante).
double? parsePriceInput(String input) {
  final trimmed = input.trim().replaceAll(',', '.');
  if (trimmed.isEmpty) return null;
  return double.tryParse(trimmed);
}
