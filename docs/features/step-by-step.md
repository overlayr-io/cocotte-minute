---
feature: mode-pas-a-pas
status: done        # planned | in-progress | done
scope: v1           # v1 | v2 | later
depends_on: [recette-base, recette-etapes]
order: 7
---

# Mode pas-à-pas (jouer la recette)

## Problème résolu
Offrir une exécution guidée de la recette en cuisine, inspirée des interfaces
type Thermomix/Posha (timing précis, guidage visuel, mains libres), mais
purement logicielle — pas de matériel connecté.

## Comportement attendu

### Fonctionnement général
- Mode 100% client : au lancement, le mobile récupère une seule fois toutes
  les données nécessaires (recette + étapes + sous-recettes déjà résolues
  en cascade, cf. `recette-etapes.md`). Aucun autre appel serveur pendant
  toute l'exécution du mode.
- Navigation entre étapes (suivant/précédent).
- Repère de progression (ex: "étape 3/12").
- Écran maintenu allumé en permanence pendant l'exécution (wakelock, pas
  de mise en veille).
- Ajustement des quantités d'ingrédients affichées selon le nombre de
  personnes choisi au lancement du mode (recalcul proportionnel à partir
  du nombre de personnes par défaut de la recette).
- Vue "ingrédients de l'étape en cours" : n'affiche que les ingrédients liés
  à l'étape active (via `step_ingredients`, cf. mise à jour recette-etapes.md),
  pas la liste complète de la recette.

### Minuteurs
- Un seul minuteur actif à la fois pour le v1 (pas de multi-minuteurs
  simultanés opérationnels dans cette v1).
- La structure de données doit néanmoins être conçue pour ne pas fermer la
  porte à plusieurs minuteurs en parallèle plus tard (ne pas modéliser le
  minuteur comme un singleton global, mais comme une liste, même si un seul
  élément est actif en pratique pour l'instant).
- Notification locale à la fin d'un minuteur (fonctionne même si l'app est
  en arrière-plan).
- Reprise possible de la recette à l'étape N après une notification/interruption
  (l'utilisateur retrouve l'étape en cours, pas obligé de tout reprendre
  depuis le début).

## Impact technique
- Server : aucun endpoint dédié à l'exécution elle-même — uniquement
  l'endpoint déjà existant de récupération de recette (avec résolution des
  sous-recettes en cascade). Le serveur ne fait que fournir les données,
  jamais de logique d'exécution.
- Mobile :
    - Feature `recipe_player/` (Bloc dédié), état local complet (étape courante,
      minuteur actif, progression) — aucune dépendance réseau pendant l'exécution.
    - Gestion du wakelock (package `wakelock_plus` ou équivalent).
    - Notifications locales (package `flutter_local_notifications` ou équivalent).
    - Persistance locale de l'état en cours (étape N, minuteur en cours) pour
      permettre la reprise après interruption/fermeture de l'app.
- DB : `step_ingredients` (ajouté à `recette-etapes.md`), aucune nouvelle
  table côté server pour l'exécution elle-même (tout est état local mobile).

## Règles métier spécifiques
- Aucune donnée d'exécution (minuteur, étape courante) n'est envoyée ou
  persistée côté server — tout reste local à l'appareil.
- L'ajustement de quantité par nombre de personnes est un calcul d'affichage
  uniquement, ne modifie jamais les données réelles de la recette en base.

## Hors scope pour cette feature
- Minuteurs multiples réellement simultanés et actifs en même temps (prévu
  dans la structure, mais pas opérationnel en v1).
- Mode voix / lecture à voix haute (accessibilité mains occupées) — non retenu
  pour le v1.
- Toute connexion à du matériel physique (four connecté, balance, etc.).

## Décisions livrées
- Persistance locale de l'état d'exécution : snapshot complet (étape courante,
  portions, minuteurs avec échéances absolues) via `RecipePlayerStorage` /
  `ResumeState`.
- Abandon avant la fin : quitter en cours de route (bouton X **ou** retour
  système via `PopScope`) **conserve** la session et propose « Reprendre » au
  prochain lancement ; la purge n'a lieu qu'à la fin réelle (ou quand une autre
  recette écrase la session).