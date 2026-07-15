/**
 * Espaces de noms des verrous consultatifs Postgres (`pg_advisory_xact_lock`).
 *
 * Ils protègent les semis paresseux « lire puis insérer si absent », qui sont
 * tous vulnérables à la même course : deux requêtes concurrentes lisent « rien »
 * et insèrent chacune le jeu par défaut, produisant des doublons. Aucune
 * contrainte unique ne peut servir de repli sur ces tables (des homonymes
 * légitimes existent), d'où le verrou.
 *
 * Le 1er argument de `pg_advisory_xact_lock(int4, int4)` est l'espace de noms,
 * le 2e la clé (typiquement `hashtext(userId)`). Ne jamais réutiliser une valeur
 * pour deux usages distincts : ce serait une exclusion mutuelle non voulue.
 */
export const ADVISORY_LOCK_NS = {
  /** Semis des 4 dossiers par défaut, par utilisateur. */
  categoryDefaults: 1,
  /** Semis des recettes d'exemple d'onboarding (#12), par utilisateur. */
  sampleRecipes: 2,
  /** Semis du catalogue de tags système — global (clé fixe). */
  systemTags: 3,
} as const;

/** Clé fixe des verrous globaux (non scopés à un utilisateur). */
export const ADVISORY_LOCK_GLOBAL_KEY = 0;
