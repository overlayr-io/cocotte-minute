---
name: spec-driven-feature
description: Cadre un besoin de fonctionnalité, de concept métier ou d'une contrainte transverse par questions-réponses fermées, puis rédige docs/features/<slug>.md — sans jamais déduire ou supposer un comportement non confirmé explicitement par l'utilisateur. Se déclenche dès que l'utilisateur veut définir, spécifier, cadrer ou documenter une nouvelle feature ("on va faire X", "je veux définir le besoin pour Y", "aide-moi à cadrer Z", "il faudrait qu'on gère..."), même sur une description libre et non structurée d'une idée. À utiliser AVANT toute implémentation ou tout plan de code (avant /feature) dès qu'un point du comportement attendu n'est pas déjà explicite — préférer poser les questions plutôt que de foncer sur une implémentation ou un plan basé sur une interprétation supposée.
---

# Spec-driven feature

Une mauvaise supposition sur un comportement coûte plus cher à corriger après
implémentation qu'une question posée avant. Ce skill sert à produire un
document de cadrage fiable — chaque ligne du document doit être traçable à
une réponse explicite de l'utilisateur, jamais à une déduction raisonnable.

## Règle d'or : ne jamais déduire

Dès qu'un point du besoin est ambigu, sous-entendu, ou admet plusieurs
interprétations raisonnables : poser une question fermée avant d'écrire quoi
que ce soit. Ne jamais choisir silencieusement l'interprétation la plus
probable, même si elle semble évidente.

- Poser les questions par lots de 2 à 4 maximum. Privilégier des options
  courtes et mutuellement exclusives plutôt qu'une question ouverte quand un
  choix fermé suffit.
- Si la réponse reste ambiguë ou partielle, reposer une question de
  clarification — ne jamais combler le vide par une supposition.
- Si une réponse contredit ou impacte un document déjà écrit (dans cette
  session ou dans `docs/features/*.md`), le signaler explicitement avant de
  continuer : *« Attention, ça contredit ce qu'on avait acté dans X.md — je
  le mets à jour ? »*. Ne jamais laisser une incohérence silencieuse
  s'installer entre deux documents.

## Déroulé

### 1. Cadrage initial

Poser les questions nécessaires pour comprendre :
- le problème résolu (pas la solution — le besoin derrière)
- le comportement attendu précis, pas une intention vague
- les propriétés/données concernées
- qui peut faire quoi (permissions, rôles)
- les dépendances avec des features déjà documentées dans `docs/features/*.md`

### 2. Détection proactive des angles morts

Avant de considérer le cadrage terminé, identifier et questionner activement
les angles morts fréquents sur ce type de fonctionnalité — même si
l'utilisateur ne les a pas mentionnés. Ne pas se limiter à cette liste, mais
au minimum vérifier :

- **Réseau** : comportement en cas d'absence de connexion
- **Cascade** : comportement en cas de suppression/modification d'une donnée
  liée ailleurs (cascade, soft delete, blocage)
- **Limites** : plafonds (nombre, taille, fréquence) et ce qui se passe une
  fois atteints
- **Relations** : symétrie ou directionnalité d'une relation entre deux
  entités
- **Portée des données** : ce qui est propre à un utilisateur vs
  partagé/global
- **Freemium** : impact sur le modèle premium si la feature y touche (vérifier
  `docs/features/limite-freemium.md` et `docs/features/premium-version.md`)
- **Cas limites** : première utilisation, donnée vide, valeur par défaut

Mieux vaut une question de trop qu'une supposition fausse découverte à
l'implémentation.

### 3. Signaler les décisions d'architecture transverse

Si le sujet touche une décision qui dépasse la feature isolée — stratégie
offline, choix de stack, modèle économique, refonte d'un concept déjà
répandu dans le code — le signaler explicitement à l'utilisateur et proposer
d'exposer risques et bénéfices avant de trancher, plutôt que de documenter
une décision structurante sans avoir pesé le pour et le contre.

### 4. Rédaction du document

Une fois le cadrage suffisamment précis (plus de zone d'ombre sur les points
ci-dessus, ou explicitement laissée en « question ouverte » si l'utilisateur
préfère trancher plus tard), rédiger `docs/features/<slug>.md`.

Convention du projet (alignée sur les fichiers déjà présents dans
`docs/features/`) :

```markdown
---
feature: <slug>
status: planned        # planned | in-progress | done
scope: v1               # v1 | v2 | later
depends_on: [<autres features>]
order: <position dans l'ordre de dépendance>
---

# <Nom de la feature>

## Problème résolu
## Comportement attendu
## Impact technique
(Server / Mobile / DB — adapté à ce qui est réellement concerné)
## Règles métier spécifiques
## Hors scope pour cette feature
## Questions ouvertes / à trancher
```

Rester concis : pas de paragraphes redondants, le document doit rester
lisible en une seule passe. Ne documenter que ce qui a été confirmé — la
section « Questions ouvertes / à trancher » existe précisément pour ce qui
reste incertain, pas pour être vidée par supposition.

### 5. Mise à jour des documents impactés

Si la nouvelle feature modifie ou précise le comportement d'une feature déjà
documentée, éditer le document existant concerné avec une section clairement
identifiée `## Ajout — <raison>`. Ne jamais dupliquer l'information à un
autre endroit sans le signaler.

### 6. Signaler l'index

Le projet tient à jour `docs/features-manquantes.md`, un état des lieux
manuel des chantiers restants — il n'existe aujourd'hui aucun script ou hook
qui le régénère automatiquement. Une fois le document de cadrage rédigé,
simplement rappeler à l'utilisateur que ce fichier peut nécessiter une mise à
jour manuelle ; ne pas l'éditer soi-même sans confirmation, et ne pas
supposer qu'un mécanisme d'automatisation existe.

## Fin de cadrage

Une fois le document rédigé, le présenter à l'utilisateur et rappeler les
points laissés en « Questions ouvertes ». Ne pas enchaîner automatiquement
sur l'implémentation (`/feature`) sans confirmation explicite — cadrer le
besoin et l'implémenter sont deux étapes distinctes.
