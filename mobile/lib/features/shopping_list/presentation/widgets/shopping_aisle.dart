import '../../../../core/i18n/generated/app_localizations.dart';

/// Rayons de courses (vue « par rayon » de l'écran 5e).
///
/// ⚠️ Heuristique **côté client** : les ingrédients ne portent pas de rayon en
/// base (seulement nom + unité). On déduit le rayon par mots-clés sur le nom.
/// C'est volontairement imparfait — la version exacte demanderait un champ
/// `rayon` sur l'ingrédient côté serveur. Le fallback est « Autres ».
enum ShoppingAisle {
  fruitsLegumes,
  viandesPoissons,
  boulangerie,
  boissons,
  surgeles,
  maison,
  epicerieSucree,
  epicerieSalee,
  frais,
  autres,
}

/// Ordre d'affichage des rayons (parcours type d'un magasin).
const List<ShoppingAisle> kAisleOrder = [
  ShoppingAisle.fruitsLegumes,
  ShoppingAisle.frais,
  ShoppingAisle.viandesPoissons,
  ShoppingAisle.boulangerie,
  ShoppingAisle.epicerieSalee,
  ShoppingAisle.epicerieSucree,
  ShoppingAisle.surgeles,
  ShoppingAisle.boissons,
  ShoppingAisle.maison,
  ShoppingAisle.autres,
];

/// Mots-clés par rayon. L'ordre de test (cf. [aisleOf]) fait gagner le plus
/// spécifique (ex: « lait de coco » → épicerie via « coco » avant « lait »).
const Map<ShoppingAisle, List<String>> _keywords = {
  ShoppingAisle.viandesPoissons: [
    'poulet', 'boeuf', 'porc', 'agneau', 'jambon', 'lardon', 'saucisse',
    'steak', 'poisson', 'saumon', 'thon', 'crevette', 'viande', 'dinde',
    'veau', 'merguez', 'bacon',
  ],
  ShoppingAisle.fruitsLegumes: [
    'tomate', 'oignon', 'ail', 'carotte', 'courge', 'courgette', 'salade',
    'pomme', 'banane', 'citron', 'orange', 'poireau', 'epinard', 'champignon',
    'patate', 'echalote', 'poivron', 'concombre', 'aubergine', 'brocoli',
    'chou', 'fraise', 'legume', 'persil', 'basilic', 'coriandre', 'menthe',
    'gingembre', 'avocat', 'courg', 'haricot vert', 'petit pois',
  ],
  ShoppingAisle.boulangerie: ['pain', 'baguette', 'brioche', 'viennoiserie'],
  ShoppingAisle.boissons: [
    'eau', 'jus', 'vin', 'biere', 'soda', 'limonade', 'boisson', 'sirop',
  ],
  ShoppingAisle.surgeles: ['surgele', 'glace', 'congele'],
  ShoppingAisle.maison: [
    'eponge', 'papier', 'savon', 'lessive', 'nettoyant', 'essuie', 'sac',
    'mouchoir',
  ],
  ShoppingAisle.epicerieSucree: [
    'sucre', 'chocolat', 'miel', 'confiture', 'biscuit', 'vanille', 'levure',
    'cafe', 'the ', 'cereale', 'nutella', 'compote',
  ],
  ShoppingAisle.epicerieSalee: [
    'pate', 'riz', 'lentille', 'farine', 'huile', 'sel', 'poivre', 'epice',
    'sauce', 'conserve', 'coco', 'pois chiche', 'semoule', 'bouillon',
    'moutarde', 'vinaigre', 'pelee', 'olive', 'boulgour', 'quinoa', 'polenta',
  ],
  ShoppingAisle.frais: [
    'lait', 'creme', 'beurre', 'yaourt', 'fromage', 'oeuf', 'mozzarella',
    'parmesan', 'ricotta', 'tofu', 'jambon blanc',
  ],
};

/// Normalise pour la comparaison : minuscules + accents FR retirés.
String _normalize(String input) {
  var s = input.toLowerCase();
  const accents = {
    'à': 'a', 'â': 'a', 'ä': 'a',
    'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
    'î': 'i', 'ï': 'i',
    'ô': 'o', 'ö': 'o',
    'ù': 'u', 'û': 'u', 'ü': 'u',
    'ç': 'c', 'œ': 'oe',
  };
  accents.forEach((k, v) => s = s.replaceAll(k, v));
  return s;
}

/// Déduit le rayon d'un article à partir de son nom (heuristique, cf. en-tête).
ShoppingAisle aisleOf(String name) {
  final n = _normalize(name);
  // On teste dans l'ordre spécifique→générique de [_keywords].
  for (final entry in _keywords.entries) {
    for (final kw in entry.value) {
      if (n.contains(kw)) return entry.key;
    }
  }
  return ShoppingAisle.autres;
}

/// Libellé i18n d'un rayon.
String aisleLabel(AppLocalizations l10n, ShoppingAisle aisle) {
  return switch (aisle) {
    ShoppingAisle.fruitsLegumes => l10n.shoppingAisleFruitsLegumes,
    ShoppingAisle.frais => l10n.shoppingAisleFrais,
    ShoppingAisle.viandesPoissons => l10n.shoppingAisleViandesPoissons,
    ShoppingAisle.epicerieSalee => l10n.shoppingAisleEpicerieSalee,
    ShoppingAisle.epicerieSucree => l10n.shoppingAisleEpicerieSucree,
    ShoppingAisle.boulangerie => l10n.shoppingAisleBoulangerie,
    ShoppingAisle.boissons => l10n.shoppingAisleBoissons,
    ShoppingAisle.surgeles => l10n.shoppingAisleSurgeles,
    ShoppingAisle.maison => l10n.shoppingAisleMaison,
    ShoppingAisle.autres => l10n.shoppingAisleAutres,
  };
}
