---
description: Workflow Explore-Plan-Code autonome pour une nouvelle fonctionnalité
---

Tâche demandée : $ARGUMENTS

## Étape 0 — Clarification (UNE seule fois)
Pose entre 3 et 5 questions fermées maximum si des points sont ambigus
au regard de PROJECT_CONTEXT.md, docs/features/*.md et docs/ENGINEERING_CONSTRAINTS.md.
Si tout est déjà clair, ne pose AUCUNE question et passe directement à l'étape 1.

## Étape 1 — Explore (sous-agent)
Sous-agent Task dédié : explore uniquement les fichiers pertinents (rg, pas de
lecture exhaustive), identifie les conventions déjà en place, retourne un
résumé de 15 lignes max. Ne pas afficher le détail à l'utilisateur.

## Étape 2 — Plan
Plan concis : fichiers à créer/modifier, ordre d'exécution (server avant mobile
si l'API est un prérequis), points de risque. Affiché en 10 lignes max, puis
continue automatiquement — sauf si le plan touche une règle métier critique
(sous-recette, limite freemium, suppression de compte), auquel cas demander
confirmation.

## Étape 3 — Code (sous-agents parallélisables)
Un sous-agent par module indépendant, appliquant les skills pertinents
(nestjs-module, flutter-feature, sous-recette-rules, supabase-auth-check).
Formatage géré par les hooks, pas besoin de le faire manuellement.

## Étape 4 — Rapport final
5-10 lignes max : fichiers créés/modifiés, commandes à lancer, points d'attention.