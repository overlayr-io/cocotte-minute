---
feature: assistant-ia-recettes
status: planned        # planned | in-progress | done
scope: v2
depends_on: [recherche-avancee, premium-version, limite-freemium, recipes, ingredients, categories, tags-personnes]
order: 18
---

# Assistant IA de recettes (recherche vocale + génération)

## Problème résolu
Certains utilisateurs ne trouvent pas leur bonheur dans la barre de recherche
`/#@`, ou ont la « flemme » de la construire critère par critère. Ils veulent
décrire une envie en langage naturel (à la voix ou en une phrase) et se faire
proposer des recettes — et si rien n'existe, se faire **inventer** une recette
qu'ils peuvent enregistrer comme une vraie fiche Cocotte Minute.

Prolongement direct de la barre façon Notion (cf. `recherche-avancee.md`,
itération 12 de la maquette).

## Comportement attendu

Parcours (maquette 12a → 12n) :

1. **Entrée** — depuis la barre de recherche : bouton micro *ou* saisie d'une
   phrase libre (texte non-commande, sans `/ # @`). Un texte libre propose
   « Laisser l'assistant comprendre » vs « Chercher dans les titres ».
2. **Vocal** — on enregistre l'audio et on l'envoie à un service de
   transcription (l'audio n'est pas traité sur l'appareil). Retour texte.
3. **Compréhension** — la phrase est transformée par l'IA en **pastilles
   éditables** (dossier, tags, personnes, ingrédients, portions, critères).
4. **Recherche intelligente** — approche hybride : un **pré-filtre
   déterministe** (le `GET /search/recipes` existant, élargi) réduit le
   catalogue à un ensemble de candidats, puis on envoie **ces candidats + la
   phrase** à l'IA qui comprend et **classe** le top 3 (« Ça devrait te
   plaire », en slider) + des « autres idées ».
5. **Aucun résultat** — l'IA propose d'assouplir un critère, ou un bouton
   **« Générer cette recette »**.
6. **Génération** — au clic, l'IA « chef » invente une recette (simple :
   nom, portions, durée, ingrédients, étapes). Affichée en aperçu avec la
   mention « Suggérée par l'assistant — vérifie les quantités ».
7. **Régénérer / liste à la volée** — « Régénérer » produit une **nouvelle**
   recette **ajoutée à une liste empilée en mémoire de session** ; les
   précédentes sont conservées à l'écran. Rien n'est persisté en base tant
   qu'on n'enregistre pas. Quitter l'écran perd les brouillons non
   enregistrés.
8. **Enregistrement (conversion)** — « Enregistrer dans mes recettes » ouvre
   une confirmation nom + dossier + tags (12m), puis crée une **recette
   normale** (pas de base, `is_base = false`), pré-remplie et **entièrement
   éditable** comme les autres (12n).

## Impact technique

### Architecture (décision transverse)
Tous les appels IA passent en **proxy via NestJS** : `Mobile → NestJS →
Ollama (dev) / API IA (prod)`. La clé API et l'URL de l'IA vivent dans le
**.env du server**, jamais dans le mobile. Le server gère aussi le quota et
l'entitlement Premium. Le mobile n'a qu'un flag on/off.

Le provider IA est abstrait derrière une interface (ex. `ChefAiProvider`)
sélectionnée par variable d'environnement — `ollama` en dev, provider distant
en prod — pour brancher SIMPLEMENT une autre IA sans toucher au code métier.
Idem pour le service de **transcription** (audio → texte), configurable par
.env server.

### Server (NestJS)
- Nouveau module IA exposant, a minima :
  - transcription audio → texte,
  - compréhension phrase → critères (pastilles),
  - classement des candidats (top 3 + autres),
  - génération de recette (sortie JSON).
- Réutilise/élargit le pré-filtre `GET /search/recipes`.
- Applique le **quota** (voir Règles métier) et l'**entitlement Premium**
  avant chaque appel IA.
- **Format de génération : JSON structuré** demandé dans le prompt et
  **validé côté serveur** (nom, portions, durée, `ingredients[{qty, unit,
  name}]`, `steps[]`). Rejet/erreur propre si non conforme.

### Mobile (Flutter)
- Extension de la barre de recherche (micro + phrase libre), écran d'écoute,
  état « l'IA réfléchit », résultats 2 niveaux, écran recette générée + liste
  de brouillons en mémoire, écran de confirmation avant création.
- **Flag d'activation au build (`dart-define`, ex. `AI_ENABLED`)** : quand la
  fonction est désactivée, toute l'UI IA (micro, entrée assistant, écrans)
  **disparaît complètement** de l'app.
- Conversion du JSON généré vers le modèle recette existant.

### DB
- Aucune nouvelle table pour les brouillons (mémoire de session uniquement).
- Compteur de quota IA côté serveur (mécanisme à préciser à l'implémentation ;
  s'aligner sur l'existant `limite-freemium` / `premium-version`).
- La recette enregistrée passe par le flux de création de recette existant
  (aucun schéma nouveau).

## Règles métier spécifiques
- **Accès Premium uniquement** (« V2 · Abonnement »). Les utilisateurs
  gratuits voient un paywall (réutiliser le paywall maison existant).
- **Quota côté serveur** : **toute requête IA compte** (transcription/
  compréhension **et** génération). La **valeur et la période sont laissées
  ouvertes** dans ce doc, à fixer une fois le coût réel des appels connu.
- **Recette générée = recette normale** : `is_base = false`, éditable, rangée
  dans le dossier choisi à l'enregistrement, avec les tags confirmés.
- **Ingrédients générés** : on n'utilise **pas** la détection auto / emoji.
  Chaque ingrédient non renseigné par l'utilisateur reçoit une **valeur par
  défaut « manquant »** (marqueur visuel uniforme, identique pour tous). Ils
  restent enrichissables manuellement ensuite.
- **Hors-ligne / IA indisponible** : sans réseau, le **micro et l'entrée IA
  sont masqués** ; la barre `/#@` classique reste pleinement utilisable.

## Hors scope pour cette feature
- Persistance des brouillons IA en base (session-only pour la V2).
- Détection auto d'ingrédients / emoji sur les recettes générées.
- Reconnaissance vocale on-device (on envoie l'audio à un service).
- Toggle IA distant / sans rebuild (le flag est au build).
- Personnalisation fine du prompt chef par l'utilisateur.

## Questions ouvertes / à trancher
- **Valeur et période du quota** IA Premium (ex. X/jour vs X/mois).
- Choix concret du **service de transcription** en prod (et son coût).
- Faut-il **compter séparément** transcription vs génération dans les futurs
  chiffres de quota, ou un compteur unique ?
- Comportement si l'IA renvoie un JSON invalide côté génération (retry auto
  silencieux ? message + bouton « Régénérer » ?).
