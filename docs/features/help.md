---
feature: aide
status: in-progress   # planned | in-progress | done
scope: v1             # v1 | v2 | later
depends_on: [auth]
order: 12
---

# Aide (Centre d'aide & Nous contacter)

## Problème résolu
Donner à l'utilisateur un moyen autonome de trouver des réponses aux questions
fréquentes (sans solliciter le support), et un canal simple pour nous écrire
quand il ne trouve pas — le tout accessible depuis l'onglet Compte, section
« Aide ».

## Comportement attendu

### Centre d'aide (FAQ)
- Liste de questions/réponses présentées en **accordéon** (une réponse se
  déplie au tap).
- Contenu **éditorial**, modifiable sans redéploiement de schéma : servi par le
  serveur depuis un fichier JSON versionné.
- Un lien « Nous contacter » en bas de l'écran pour rebondir vers le formulaire.
- Chargement bloquant (le contenu vient du serveur) avec action de **retry** en
  cas d'échec (cf. `ENGINEERING_CONSTRAINTS.md`).

### Nous contacter
- Formulaire simple : **sujet** + **message** (validés, non vides).
- À l'envoi, la **version de l'app** est jointe automatiquement (confort de
  support), sans que l'utilisateur ait à la renseigner.
- Succès → confirmation discrète (snackbar) + retour à l'écran précédent.
- Échec → message non bloquant (snackbar), le formulaire reste rempli.

## Impact technique

### Server — `modules/help/`
- `GET /help/faq` : renvoie les entrées de FAQ **publiées**, triées par `order`,
  débarrassées des champs internes. Source = `data/faq.json` (fichier versionné,
  éditable à la main), importé au build (`resolveJsonModule`) — pas de table ni
  de migration. Forme d'une entrée : `id`, `category`, `order`, `published`,
  `question`, `answer`.
- `POST /help/contact` : reçoit `subject`, `message`, `appVersion` (optionnelle),
  validés par `class-validator`. Le message est **journalisé** avec l'`userId` et
  le statut anonyme. Répond `202 Accepted`.
- Les deux routes sont protégées par `SupabaseAuthGuard` (l'app a toujours au
  moins une session anonyme).

### Mobile — `features/help/`
- `HelpRepository` : `fetchFaq()` (`GET /help/faq`) et `sendContact()`
  (`POST /help/contact`), enregistré dans le service locator.
- `HelpCenterPage` + `HelpCenterCubit` : FAQ en `ExpansionTile` dans une carte à
  élévation douce (`AppShadows.card`).
- `ContactPage` + `ContactCubit` : formulaire ; la version d'app est lue via
  `package_info_plus` au moment de l'envoi.
- Les deux entrées de la section « Aide » de l'onglet Compte ne pointent plus
  vers l'écran « bientôt disponible ».

## Réalisation (2026-07-08)
- Livré server + mobile. Décisions prises avec le PO : FAQ = **fichier JSON
  statique** servi par le serveur (édition manuelle, pas de base) ; contact =
  **formulaire → endpoint NestJS** journalisé (pas de `mailto:`), l'envoi
  d'e-mail réel au support restant à brancher plus tard.
- **Une seule entrée de FAQ** pour l'instant (générer une liste de courses) ;
  les autres seront ajoutées au fil de l'eau directement dans `faq.json`.

## Guides de concepts (#13)

Pages explicatives simples, une par concept clé, accessibles depuis l'onglet
Compte > Aide > « Comprendre l'app ».

- **Contenu** : 100 % i18n (pas de serveur), catalogue statique de 6 guides —
  recettes de base & sous-recettes, dossiers, tags, personnes & famille, liste
  de courses, planification. Chaque guide = une intro + 2 sections titre/texte,
  sans jargon.
- **Structure mobile** (`features/help/`) :
  - `domain/concept_guide.dart` : modèle `ConceptGuide` (+ `videoUrl` optionnel)
    et `ConceptSection`.
  - `domain/concept_guides_catalog.dart` : `conceptGuides(l10n)` construit la
    liste depuis l'i18n.
  - `presentation/pages/concept_guides_page.dart` : liste (tuiles carte).
  - `presentation/pages/concept_guide_page.dart` : détail (bloc vidéo + intro +
    sections, même esprit que `LegalPage`).
  - `presentation/widgets/concept_video_box.dart` : emplacement vidéo.
- **Vidéo** : décision produit = une vidéo par concept (embed YouTube ou package
  vidéo, avec vidéo de test aléatoire en dev). Pour l'instant, `ConceptVideoBox`
  affiche un état **« Vidéo bientôt disponible »** ; c'est le **point de bascule
  unique** quand le lecteur réel sera branché (chaque guide porte déjà un
  `videoUrl` optionnel, tous `null` aujourd'hui).

### Reste à faire (vidéos)
- Brancher le **lecteur vidéo réel** (package + config plateforme) et remplir les
  `videoUrl` des guides. En dev, une URL de vidéo d'exemple suffit pour valider
  la mise en page.

## Reste à faire (raison du statut `in-progress`)
- **Envoi e-mail réel** du message de contact au support (aujourd'hui simplement
  journalisé côté serveur).
- **Contenu FAQ** : enrichir `faq.json` (une seule Q/R pour l'instant).
- Éventuel regroupement par `category` dans l'UI si la FAQ grossit.
