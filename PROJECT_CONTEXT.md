# Cocotte Minute — Contexte produit

## Pitch
App de recettes de cuisine, pensée pour un usage "chef moderne" : création de
recettes, avec un système de recettes de base réutilisables ("sous-recettes"),
tags/catégories, ingrédients avec alternatives, photos. Exécution étape par
étape pensée pour la cuisine.

## Concepts clés
- **Recette** : créée par un utilisateur. Composée d'étapes, d'ingrédients,
  de tags, de catégories, d'une image. Peut inclure des sous-recettes comme composants.
- **Sous-recette (= "recette de base")** : type de recette marqué `is_base = true`,
  réutilisable comme composant dans d'autres recettes. Une fois utilisée comme
  composant ailleurs, ce flag est **verrouillé** (ne peut plus repasser à false).
- **Recette normale** : ne peut jamais être utilisée comme composant ailleurs.
- **Ingrédient** : nom, image, unité fixe (choisie à la création, modifiable ensuite).
  Catalogue système + copies personnalisées par import utilisateur. Soft delete uniquement.
- **Alternative d'ingrédient** : relation symétrique entre deux ingrédients.
- **Tag** : libre, propre à un compte, utilisé sur recette/sous-recette/personne.
- **Catégorie** : dossier de rangement, imbricable, une recette peut appartenir à plusieurs.
- **Personne** : membre de la famille (nom, avatar), propre à un compte, 0 à n tags.
- **Étape** : description obligatoire + optionnellement bannière (icône+couleur) OU référence à une recette de base (jamais les deux). Résolution récursive des sous-recettes en cascade, jamais de duplication de texte.

## Qui crée le contenu
- V1 : recettes créées uniquement par les utilisateurs (UGC).
- V2 (pas maintenant) : marketplace de recettes "chef" + backoffice admin.

## Périmètre v1 (v1)
- Auth (compte anonyme dès l'installation + email/Google/Apple, cf. `docs/features/auth.md`)
- CRUD Recette + Sous-recette + Étapes
- Ingrédients (système + personnalisés) + alternatives
- Tags + Personnes
- Catégories (dossiers imbricables)
- Mode pas-à-pas (exécution guidée, 100% client)
- Liste de courses automatique (offline-first)
- Recherche avancée (nom, tags, personnes, ingrédients, scope catégorie)
- Limite freemium (documentée, implémentation de paiement reportée)

## Hors scope V1
- Export PDF, suggestions intelligentes, marketplace, backoffice, IA locale opérationnelle (architecture prévue seulement), paiement réel (Stripe/RevenueCat).

## Modèle économique
- Gratuit : illimité sauf 5 sous-recettes max, 1 liste de courses active (à clear), recherche limitée à 6-8 critères cumulés (à trancher), pas d'IA locale.
- Premium (3,99€/mois, essai 15 jours) : tout illimité + IA locale + plusieurs listes de courses + historique.
- Deux offres prévues : abonnement ET achat unique à vie (statut premium simple type `premium_type: 'none'|'subscription'|'lifetime'`, indépendant du mode de paiement).
- ⚠️ Paiement réel non intégré dans le v1 — uniquement la logique de comptage/limite, statut premium modifiable manuellement en DB pour les tests.

## Décision d'architecture — offline / cache (juillet 2026)
- Offline-first (écriture hors-ligne + sync + conflit) : **limité à la liste
  de courses**, volontairement.
- Cache passif (lecture hors-ligne, pas d'écriture) : appliqué aux recettes,
  ingrédients, tags, catégories — permet de consulter le contenu déjà chargé
  sans connexion, mais pas de créer/modifier sans réseau.
- Ne pas généraliser l'offline-first ailleurs sans revalidation explicite :
  complexité de synchronisation + risque de perte de données jugés trop
  élevés pour le reste du v1.

## Documents de référence
- Contraintes transverses d'ingénierie (cache, erreurs, i18n, RGPD, tests, git) :
  voir `docs/ENGINEERING_CONSTRAINTS.md` — s'applique à toutes les features.
- Détail de chaque feature : `docs/features/*.md`
