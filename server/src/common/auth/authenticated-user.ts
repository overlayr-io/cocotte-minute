/**
 * Représentation minimale de l'utilisateur authentifié, extraite du JWT Supabase.
 * Les services métier ne connaissent que cette abstraction, pas la structure brute
 * du token Supabase.
 */
export interface AuthenticatedUser {
  /** UUID Supabase (claim `sub`) — clé étrangère de tout le contenu utilisateur. */
  id: string;
  email?: string;
  /** `authenticated` pour un compte réel, `anon` pour un compte anonyme. */
  role?: string;
  /** true si le compte est anonyme (claim `is_anonymous`). */
  isAnonymous: boolean;
}
