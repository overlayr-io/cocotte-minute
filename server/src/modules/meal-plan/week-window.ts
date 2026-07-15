/**
 * Calculs de semaines calendaires (lundi → dimanche) du planning de repas,
 * en jours civils Europe/Paris (cf. features/planification-repas.md).
 *
 * Tout est manipulé en chaînes `YYYY-MM-DD` (colonne `date` Postgres) :
 * l'arithmétique passe par des Date UTC pour éviter les surprises DST.
 */

const DAY_MS = 86_400_000;

/** Jour civil courant à Paris (le serveur tourne en UTC chez Render). */
export function todayInParis(now: Date = new Date()): string {
  // en-CA formate en YYYY-MM-DD.
  return new Intl.DateTimeFormat('en-CA', { timeZone: 'Europe/Paris' }).format(now);
}

export function addDays(day: string, n: number): string {
  const d = new Date(`${day}T00:00:00Z`);
  return new Date(d.getTime() + n * DAY_MS).toISOString().slice(0, 10);
}

/** Lundi de la semaine contenant `day`. */
export function mondayOfWeek(day: string): string {
  const dow = new Date(`${day}T00:00:00Z`).getUTCDay(); // 0 = dimanche
  return addDays(day, -((dow + 6) % 7));
}

export function isMonday(day: string): boolean {
  return new Date(`${day}T00:00:00Z`).getUTCDay() === 1;
}

/**
 * Fenêtres du planning autour de la semaine courante T :
 * - rétention/lecture : T-1 → T+2 (4 semaines glissantes, purge au-delà) ;
 * - écriture gratuit : T et T+1 (au-delà : lecture seule → upsell) ;
 * - écriture premium : toute la fenêtre de rétention.
 * Bornes de fin **exclusives** (lundi de la semaine suivante).
 */
export interface MealPlanWindow {
  currentMonday: string;
  retentionStart: string;
  retentionEndExclusive: string;
  freeWriteStart: string;
  freeWriteEndExclusive: string;
}

export function mealPlanWindow(now: Date = new Date()): MealPlanWindow {
  const currentMonday = mondayOfWeek(todayInParis(now));
  return {
    currentMonday,
    retentionStart: addDays(currentMonday, -7),
    retentionEndExclusive: addDays(currentMonday, 21),
    freeWriteStart: currentMonday,
    freeWriteEndExclusive: addDays(currentMonday, 14),
  };
}
