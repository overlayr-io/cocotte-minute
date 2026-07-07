# Ce qu'il manque — du plus petit au plus gros chantier

État des lieux basé sur `PROJECT_CONTEXT.md`, `docs/features/*.md` et le code réel (mobile + server).
Constat général : le socle v1 (auth de base, ingrédients, tags/personnes, catégories, recettes, étapes, mode pas-à-pas, liste de courses, recherche avancée) est très avancé. Le vrai chantier non démarré restant est **limites freemium** ; le seul écart réglementaire est la **suppression de compte RGPD**.

## 🟢 Petit (finition / correctif ciblé)

1. **Mode pas-à-pas — finitions persistance de reprise** ([step-by-step.md](../docs/features/step-by-step.md)) : format de persistance et comportement en cas d'abandon avant la fin pas totalement tranchés.
2. **`list-courses-auto.md` — doc obsolète** : frontmatter marqué `planned` alors que le code (server + mobile) est quasi complet. À remettre à `done`/`in-progress`.
3. **Catégories — TODO de blocage non levé** (`server/src/modules/categories/categories.service.ts:171`) : la suppression d'un dossier contenant des recettes n'est pas bloquée alors que `recipe_categories` existe désormais. Écart réel entre doc et code.
4. **Ingrédients — upload d'image réel** : champ `imageUrl` existe mais pas de widget d'upload (URL externe seulement).
5. **Tags & Personnes — upload avatar réel** : avatar dérivé par défaut, pas de vrai upload.
6. **Recettes — upload de photo réel** : même pattern que l'ingrédient, non branché.
7. **Recettes — picker composant/sous-recette côté mobile** : endpoint serveur déjà prêt, juste l'UI de sélection manque.
8. **Auth — rappel J+14** : carte statique existe, pas de tracking réel de la date de création du compte ni de déclenchement temporel.

## 🟡 Petit à moyen

9. **Recettes — UI d'assignation tag/catégorie** : endpoints serveur déjà prêts (`POST/DELETE :id/categories`, `:id/tags`), mais aucun écran mobile pour les utiliser.
10. **Auth — OAuth Google/Apple en prod** : câblage Supabase fait, boutons visibles seulement en debug ; il manque la config externe (deep link iOS, Sign in with Apple, redirect URLs) — peu de code mais dépend d'accès à des consoles tierces.

## 🟠 Moyen

11. **Auth — RGPD suppression de compte (délai 30 jours)** : **seul écart de conformité réglementaire**, explicitement requis par `docs/ENGINEERING_CONSTRAINTS.md` mais totalement absent du code (pas de champ `account_status`/`deletion_requested_at`, pas d'endpoint, pas de job CRON, écran "bientôt disponible"). Périmètre clair : migration DB + 2 endpoints + `@nestjs/schedule` + écran mobile + anonymisation.
12. **Limites freemium** ([limite-freemium.md](../docs/features/limite-freemium.md)) : pas commencée. Nécessite un champ statut premium simple + 3 vérifications serveur (compteur sous-recettes, limite 1 liste active, plafond critères de recherche) + UI d'incitation. La recherche avancée dont ça dépend est désormais livrée ([advanced-search.md](../docs/features/advanced-search.md)) ; reste à trancher le plafond exact de critères cumulés (6 ou 8). Le paiement réel (Stripe/RevenueCat) reste hors scope v1.

## ⚫ Gros

13. **Recettes — vue "Découverte"** (maquette 7b : bascule Dossiers/Découverte, hero à la une, rangées par saison/temps/personne) : non construite, décision explicite de différer. Nécessite de nouveaux champs serveur (saison) et de nouvelles requêtes (par personne/temps) + un nouvel écran à plusieurs rangées.

## Hors scope v1 (mentionné pour mémoire, aucun doc dédié)

- **Export PDF** : placeholder "à venir" déjà visible dans `export_sheet.dart`. Taille si repris : petit à moyen.
- **Suggestions intelligentes** : gros (modèle de recommandation).
- **Marketplace de recettes "chef" + backoffice admin (V2)** : gros (rôles, back-office, modération).
- **IA locale pour la recherche en langage naturel** : architecture seulement pensée dans `advanced-search.md`, pas de feature à part. Gros si un jour lancée.
- **Paiement réel (Stripe/RevenueCat)** : moyen à gros selon le provider, dépendance différée de `limite-freemium.md`.
