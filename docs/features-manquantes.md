# Ce qu'il manque — du plus petit au plus gros chantier

État des lieux basé sur `PROJECT_CONTEXT.md`, `docs/features/*.md` et le code réel (mobile + server). Dernière révision : **2026-07-08**.

Constat général : le socle v1 est désormais **quasi complet** (auth + compte invité + gestion du compte, ingrédients, tags/personnes, catégories, recettes, étapes, mode pas-à-pas, liste de courses, recherche avancée, Accueil « Découverte », export PDF, **partage de recette + deep links**, suppression RGPD, centre d'aide). Le seul vrai chantier non démarré restant est **limites freemium**. Il n'y a plus d'écart réglementaire ouvert (la suppression de compte RGPD est livrée).

## ✅ Résolu depuis la dernière édition (2026-07-08)

Ces points étaient listés comme manquants et ont été vérifiés livrés dans le code :

- **Uploads d'image réels** (ingrédient, avatar personne, photo recette) : widget partagé `ImageUploadPicker` + `ImageUploadService` (Supabase Storage), branché dans `ingredient_form_sheet`, `person_edit_page` et `recipe_create_page`.
- **Recettes — picker composant/sous-recette** : `showBaseRecipePicker` appelé depuis la fiche recette (`recipe_detail_view`).
- **Recettes — UI d'assignation tag/catégorie** : `RecipeOrganizationSection` (+ `tag_assign_sheet`, `category_assign_sheet`) dans la fiche recette.
- **Catégories — suppression d'un dossier non vide bloquée** : `softDelete` refuse désormais si sous-dossiers ou recettes présents (`ConflictException`). Plus aucun `TODO`/`FIXME` dans `server/src` ni `mobile/lib`.
- **`list-courses-auto.md`** : frontmatter repassé à `status: done`.
- **Auth — rappel J+14** : remplacé par une **carte d'invitation permanente** « Créer ton compte » (onglet Compte, visible dès le 1er jour en invité) — tracking temporel J+14 sans objet.
- **Auth — RGPD suppression de compte** : livrée (endpoints `request-deletion`/`status`/`cancel-deletion`, anonymisation + `pending_deletion` J+30, CRON de purge, `DeleteAccountPage`) et rendue **accessible en mode invité** + via la page « Gérer mes données ». Pages Confidentialité réelles (politique, CGU, gérer mes données).
- **Centre d'aide & Nous contacter** : livrés ([help.md](../docs/features/help.md)) — FAQ éditoriale (`GET /help/faq` depuis `faq.json`) + formulaire de contact (`POST /help/contact`).
- **Auth — « Gérer le compte » (connecté)** : livré — page d'édition e-mail + mot de passe via Supabase `updateUser` (`account_manage_page.dart` + `AccountManageCubit`), remplace le placeholder « bientôt ».
- **Mode pas-à-pas — comportement d'abandon** : tranché et livré — quitter en cours de route (bouton X **ou** retour système via `PopScope`) **conserve** la session et propose « Reprendre » au prochain lancement ; purge uniquement à la fin réelle.
- **Recettes — vue « Découverte »** : livrée — l'Accueil est un flux Découverte (`GET /discovery/home`) : hero « à la une » + rangées (de saison, prêt en 30 min, récemment ajoutées, par personne, recettes de base, portions). Le « de saison » est **dérivé des ingrédients** via une table de saisonnalité FR, **sans migration** ni champ serveur.
- **Export PDF — fiche recette** : livré — `RecipePdfService` (packages `pdf`/`printing`), PDF A4 imprimable **2 colonnes** fidèle à la maquette « Recette Web » (en-tête titre + photo, bandeau méta, ingrédients à gauche, préparation à droite, sous-recettes), partage/impression depuis le menu de la fiche.
- **Partage de recette + deep links** : livré ([partage-recette.md](features/partage-recette.md)) — module serveur `shares` (table `recipe_shares`, `POST /recipes/:id/share`, `GET /share/:token` JSON, `GET /r/:token` page web responsive, fichiers `.well-known`), feuille mobile « Partager » (copier le lien via `share_plus`), et deep linking (`app_links` : universal/app links + scheme `cocotteminute://`, `SharedRecipePage` en lecture seule, bascule vers la fiche complète si propriétaire). **Prérequis déploiement** : domaine public + TeamID iOS + SHA256 Android (placeholders `TODO_*`).

## 🟢 Petit (finition / correctif ciblé)

1. **Aide — enrichir la FAQ** : une seule Q/R dans `server/src/modules/help/data/faq.json` pour l'instant (le reste sera ajouté au fil de l'eau).

## 🟡 Petit à moyen

2. **Aide — envoi e-mail réel du message de contact** : `POST /help/contact` **journalise** le message (avec user id + version d'app) mais n'envoie pas encore d'e-mail au support. À brancher (service mail / webhook).
3. **Auth — OAuth Google/Apple en prod** : câblage Supabase fait, boutons visibles seulement en `kDebugMode` ; il manque la config externe (deep link iOS, Sign in with Apple, redirect URLs) — peu de code mais dépend d'accès à des consoles tierces.

## 🟠 Moyen

4. **Limites freemium** ([limite-freemium.md](../docs/features/limite-freemium.md)) : **pas commencée** — seul vrai chantier v1 restant. Nécessite un champ statut premium simple + 3 vérifications serveur (compteur sous-recettes, limite 1 liste active, plafond critères de recherche) + UI d'incitation. La recherche avancée dont ça dépend est livrée ([advanced-search.md](../docs/features/advanced-search.md)) ; reste à trancher le plafond exact de critères cumulés (6 ou 8). Le paiement réel (Stripe/RevenueCat) reste hors scope v1.
5. **Mode sombre (dark mode)** : différé volontairement en chantier dédié. Le `darkTheme` actuel est un stub (renvoie le thème clair) et ~80 fichiers d'UI utilisent des couleurs figées (`AppColors.*` const ou hex en dur) plutôt que `Theme.of(context)`. Prérequis : tokeniser les couleurs via le thème / un `ThemeExtension`. Les composants récents (`AppShadows`, états vides) sont déjà pensés en tokens.

## Hors scope v1 (mentionné pour mémoire, aucun doc dédié)

- **Suggestions intelligentes** : gros (modèle de recommandation).
- **Marketplace de recettes "chef" + backoffice admin (V2)** : gros (rôles, back-office, modération).
- **IA locale pour la recherche en langage naturel** : architecture seulement pensée dans `advanced-search.md`, pas de feature à part. Gros si un jour lancée.
- **Paiement réel (Stripe/RevenueCat)** : moyen à gros selon le provider, dépendance différée de `limite-freemium.md`.
