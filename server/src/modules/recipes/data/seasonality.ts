/**
 * Calendrier de saisonnalité (France métropolitaine, fruits & légumes courants).
 *
 * Permet de marquer une recette « de saison » sans champ dédié en base : une
 * recette est de saison si l'un de ses ingrédients correspond à un produit de
 * saison pour le mois courant. Le rapprochement se fait sur le nom d'ingrédient
 * (normalisé, sans accents), par correspondance de mot-clé.
 *
 * Volontairement conservateur : mieux vaut ne PAS marquer une recette de saison
 * que de la marquer à tort. Les mois sont 1..12 (janvier = 1).
 */

interface SeasonalProduce {
  /** Mots-clés normalisés (sans accents, minuscules) recherchés dans le nom. */
  keywords: string[];
  /** Mois de disponibilité (1..12). */
  months: number[];
}

const ALL = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];

/** Normalise un texte pour le rapprochement : minuscules, sans accents. */
export function normalizeName(value: string): string {
  return value
    .toLowerCase()
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .trim();
}

const PRODUCE: SeasonalProduce[] = [
  // --- Légumes ---
  { keywords: ['courge', 'potiron', 'potimarron', 'butternut'], months: [9, 10, 11, 12, 1] },
  { keywords: ['citrouille'], months: [9, 10, 11] },
  { keywords: ['carotte'], months: ALL },
  { keywords: ['poireau'], months: [1, 2, 3, 4, 9, 10, 11, 12] },
  { keywords: ['tomate'], months: [6, 7, 8, 9, 10] },
  { keywords: ['courgette'], months: [5, 6, 7, 8, 9] },
  { keywords: ['aubergine'], months: [6, 7, 8, 9, 10] },
  { keywords: ['poivron'], months: [7, 8, 9, 10] },
  { keywords: ['concombre'], months: [5, 6, 7, 8, 9] },
  { keywords: ['haricot vert', 'haricots verts'], months: [6, 7, 8, 9] },
  { keywords: ['petit pois', 'petits pois'], months: [4, 5, 6, 7] },
  { keywords: ['asperge'], months: [4, 5, 6] },
  { keywords: ['artichaut'], months: [5, 6, 7, 8, 9] },
  { keywords: ['epinard'], months: [3, 4, 5, 9, 10, 11] },
  { keywords: ['brocoli'], months: [6, 7, 8, 9, 10, 11] },
  { keywords: ['chou-fleur', 'chou fleur', 'choufleur'], months: [9, 10, 11, 12, 1, 2, 3, 4] },
  { keywords: ['chou'], months: [10, 11, 12, 1, 2, 3] },
  { keywords: ['navet'], months: [1, 2, 3, 10, 11, 12] },
  { keywords: ['betterave'], months: [1, 2, 9, 10, 11, 12] },
  { keywords: ['radis'], months: [3, 4, 5, 6, 7, 8, 9] },
  { keywords: ['champignon'], months: [1, 2, 3, 9, 10, 11, 12] },
  { keywords: ['endive'], months: [1, 2, 3, 10, 11, 12] },
  { keywords: ['fenouil'], months: [6, 7, 8, 9, 10] },
  { keywords: ['blette', 'bette'], months: [4, 5, 6, 7, 8, 9, 10] },
  { keywords: ['patate douce'], months: [9, 10, 11, 12, 1] },
  { keywords: ['panais'], months: [1, 2, 10, 11, 12] },
  { keywords: ['topinambour'], months: [1, 2, 3, 10, 11, 12] },
  { keywords: ['mais', 'maïs'], months: [8, 9, 10] },
  { keywords: ['salade', 'laitue', 'roquette', 'mache'], months: ALL },
  // --- Fruits ---
  { keywords: ['fraise'], months: [4, 5, 6, 7] },
  { keywords: ['framboise'], months: [6, 7, 8, 9] },
  { keywords: ['cerise'], months: [5, 6, 7] },
  { keywords: ['abricot'], months: [6, 7, 8] },
  { keywords: ['peche', 'nectarine'], months: [6, 7, 8, 9] },
  { keywords: ['prune', 'mirabelle', 'quetsche'], months: [7, 8, 9] },
  { keywords: ['melon'], months: [6, 7, 8, 9] },
  { keywords: ['pasteque'], months: [7, 8, 9] },
  { keywords: ['raisin'], months: [8, 9, 10] },
  { keywords: ['figue'], months: [8, 9, 10] },
  { keywords: ['pomme'], months: [1, 2, 3, 8, 9, 10, 11, 12] },
  { keywords: ['poire'], months: [1, 2, 8, 9, 10, 11, 12] },
  { keywords: ['coing'], months: [9, 10, 11] },
  { keywords: ['clementine', 'mandarine'], months: [1, 2, 11, 12] },
  { keywords: ['orange'], months: [1, 2, 3, 11, 12] },
  { keywords: ['pamplemousse'], months: [1, 2, 3, 11, 12] },
  { keywords: ['citron'], months: [1, 2, 3, 4, 11, 12] },
  { keywords: ['kiwi'], months: [1, 2, 3, 10, 11, 12] },
  { keywords: ['rhubarbe'], months: [4, 5, 6] },
  { keywords: ['myrtille'], months: [7, 8, 9] },
  { keywords: ['groseille', 'cassis'], months: [6, 7, 8] },
  { keywords: ['chataigne', 'marron'], months: [10, 11, 12] },
  { keywords: ['noix'], months: [10, 11, 12] },
];

/**
 * Une recette est-elle « de saison » pour ce mois ? Vrai dès qu'un de ses
 * ingrédients correspond à un produit de saison. `month` : 1..12.
 */
export function isSeasonal(ingredientNames: string[], month: number): boolean {
  if (month < 1 || month > 12) return false;
  const normalized = ingredientNames.map(normalizeName);
  for (const produce of PRODUCE) {
    if (!produce.months.includes(month)) continue;
    for (const keyword of produce.keywords) {
      if (normalized.some((name) => name.includes(keyword))) {
        return true;
      }
    }
  }
  return false;
}
