import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('fr')];

  /// Nom de l'application
  ///
  /// In fr, this message translates to:
  /// **'Cocotte Minute'**
  String get appTitle;

  /// Bouton de nouvelle tentative sur une page d'erreur
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get commonRetry;

  /// Message d'erreur générique
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue'**
  String get commonError;

  /// Message d'accueil sur la page d'accueil
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue dans Cocotte Minute'**
  String get homeWelcome;

  /// Bouton temporaire depuis l'accueil vers l'écran d'auth
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte / Se connecter'**
  String get homeCreateAccountCta;

  /// Titre de l'écran en mode inscription
  ///
  /// In fr, this message translates to:
  /// **'Crée ton compte'**
  String get authCreateTitle;

  /// Sous-titre en mode inscription
  ///
  /// In fr, this message translates to:
  /// **'Retrouve tes recettes sur tous tes appareils.'**
  String get authCreateSubtitle;

  /// Titre de l'écran en mode connexion
  ///
  /// In fr, this message translates to:
  /// **'Content de te revoir'**
  String get authSignInTitle;

  /// Sous-titre en mode connexion
  ///
  /// In fr, this message translates to:
  /// **'Connecte-toi pour retrouver tes recettes.'**
  String get authSignInSubtitle;

  /// No description provided for @authEmailLabel.
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get authEmailLabel;

  /// No description provided for @authEmailHint.
  ///
  /// In fr, this message translates to:
  /// **'ton@email.com'**
  String get authEmailHint;

  /// No description provided for @authPasswordLabel.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get authPasswordLabel;

  /// No description provided for @authPasswordHint.
  ///
  /// In fr, this message translates to:
  /// **'Ton mot de passe'**
  String get authPasswordHint;

  /// Bouton principal en mode inscription
  ///
  /// In fr, this message translates to:
  /// **'Créer mon compte'**
  String get authCreateAction;

  /// Bouton principal en mode connexion
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get authSignInAction;

  /// No description provided for @authDividerOr.
  ///
  /// In fr, this message translates to:
  /// **'ou'**
  String get authDividerOr;

  /// No description provided for @authContinueGoogle.
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec Google'**
  String get authContinueGoogle;

  /// No description provided for @authContinueApple.
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec Apple'**
  String get authContinueApple;

  /// No description provided for @authAlreadyHaveAccount.
  ///
  /// In fr, this message translates to:
  /// **'Déjà un compte ?'**
  String get authAlreadyHaveAccount;

  /// No description provided for @authNoAccountYet.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de compte ?'**
  String get authNoAccountYet;

  /// Lien pour basculer vers le mode connexion
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get authSwitchToSignIn;

  /// Lien pour basculer vers le mode inscription
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte'**
  String get authSwitchToCreate;

  /// No description provided for @authEmailInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Entre une adresse email valide.'**
  String get authEmailInvalid;

  /// No description provided for @authPasswordTooShort.
  ///
  /// In fr, this message translates to:
  /// **'6 caractères minimum.'**
  String get authPasswordTooShort;

  /// Texte des mentions légales avant le lien CGU
  ///
  /// In fr, this message translates to:
  /// **'En continuant, tu acceptes nos '**
  String get authLegalPrefix;

  /// No description provided for @authLegalTerms.
  ///
  /// In fr, this message translates to:
  /// **'Conditions d\'utilisation'**
  String get authLegalTerms;

  /// No description provided for @authLegalAnd.
  ///
  /// In fr, this message translates to:
  /// **' et notre '**
  String get authLegalAnd;

  /// No description provided for @authLegalPrivacy.
  ///
  /// In fr, this message translates to:
  /// **'Politique de confidentialité'**
  String get authLegalPrivacy;

  /// No description provided for @authLegalSuffix.
  ///
  /// In fr, this message translates to:
  /// **'.'**
  String get authLegalSuffix;

  /// Titre de la modal post-création
  ///
  /// In fr, this message translates to:
  /// **'Compte créé !'**
  String get keepDataTitle;

  /// No description provided for @keepDataDescription.
  ///
  /// In fr, this message translates to:
  /// **'Tes recettes créées en tant qu\'invité sont prêtes. Que veux-tu en faire ?'**
  String get keepDataDescription;

  /// No description provided for @keepDataKeepTitle.
  ///
  /// In fr, this message translates to:
  /// **'Conserver mes recettes'**
  String get keepDataKeepTitle;

  /// No description provided for @keepDataKeepSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Tout reste lié à ce compte'**
  String get keepDataKeepSubtitle;

  /// No description provided for @keepDataRecommended.
  ///
  /// In fr, this message translates to:
  /// **'Conseillé'**
  String get keepDataRecommended;

  /// No description provided for @keepDataResetTitle.
  ///
  /// In fr, this message translates to:
  /// **'Repartir de zéro'**
  String get keepDataResetTitle;

  /// No description provided for @keepDataResetSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Efface les données invité'**
  String get keepDataResetSubtitle;

  /// No description provided for @keepDataConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get keepDataConfirm;

  /// No description provided for @keepDataLater.
  ///
  /// In fr, this message translates to:
  /// **'Plus tard'**
  String get keepDataLater;

  /// Onglet de navigation Accueil
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get navHome;

  /// No description provided for @navRecipes.
  ///
  /// In fr, this message translates to:
  /// **'Recettes'**
  String get navRecipes;

  /// No description provided for @navShopping.
  ///
  /// In fr, this message translates to:
  /// **'Courses'**
  String get navShopping;

  /// No description provided for @navAccount.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get navAccount;

  /// Titre d'un écran placeholder
  ///
  /// In fr, this message translates to:
  /// **'Bientôt disponible'**
  String get comingSoonTitle;

  /// No description provided for @comingSoonBody.
  ///
  /// In fr, this message translates to:
  /// **'Cette fonctionnalité arrive prochainement.'**
  String get comingSoonBody;

  /// No description provided for @accountTitle.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get accountTitle;

  /// No description provided for @accountGuestName.
  ///
  /// In fr, this message translates to:
  /// **'Compte invité'**
  String get accountGuestName;

  /// No description provided for @accountGuestSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Tes données vivent sur cet appareil'**
  String get accountGuestSubtitle;

  /// No description provided for @accountGuestBadge.
  ///
  /// In fr, this message translates to:
  /// **'Anonyme'**
  String get accountGuestBadge;

  /// No description provided for @accountReminderTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ton compte invité a 2 semaines'**
  String get accountReminderTitle;

  /// No description provided for @accountReminderBody.
  ///
  /// In fr, this message translates to:
  /// **'Crée un compte gratuit pour sécuriser tes recettes et les retrouver sur tous tes appareils.'**
  String get accountReminderBody;

  /// No description provided for @accountReminderCta.
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte / Se connecter'**
  String get accountReminderCta;

  /// No description provided for @accountSectionContent.
  ///
  /// In fr, this message translates to:
  /// **'Mon contenu'**
  String get accountSectionContent;

  /// No description provided for @accountSectionFamily.
  ///
  /// In fr, this message translates to:
  /// **'Ma famille'**
  String get accountSectionFamily;

  /// No description provided for @accountSectionAccount.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get accountSectionAccount;

  /// No description provided for @accountSectionHelp.
  ///
  /// In fr, this message translates to:
  /// **'Aide'**
  String get accountSectionHelp;

  /// No description provided for @accountSectionPrivacy.
  ///
  /// In fr, this message translates to:
  /// **'Confidentialité'**
  String get accountSectionPrivacy;

  /// No description provided for @accountRowIngredients.
  ///
  /// In fr, this message translates to:
  /// **'Mes ingrédients'**
  String get accountRowIngredients;

  /// No description provided for @accountRowTags.
  ///
  /// In fr, this message translates to:
  /// **'Tags'**
  String get accountRowTags;

  /// No description provided for @accountRowFolders.
  ///
  /// In fr, this message translates to:
  /// **'Dossiers'**
  String get accountRowFolders;

  /// No description provided for @accountRowPersons.
  ///
  /// In fr, this message translates to:
  /// **'Personnes'**
  String get accountRowPersons;

  /// No description provided for @accountRowManage.
  ///
  /// In fr, this message translates to:
  /// **'Gérer le compte'**
  String get accountRowManage;

  /// No description provided for @accountRowLogout.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get accountRowLogout;

  /// No description provided for @accountRowDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer mon compte'**
  String get accountRowDelete;

  /// No description provided for @accountRowHelpCenter.
  ///
  /// In fr, this message translates to:
  /// **'Centre d\'aide'**
  String get accountRowHelpCenter;

  /// No description provided for @accountRowContact.
  ///
  /// In fr, this message translates to:
  /// **'Nous contacter'**
  String get accountRowContact;

  /// No description provided for @accountRowPrivacyPolicy.
  ///
  /// In fr, this message translates to:
  /// **'Politique de confidentialité'**
  String get accountRowPrivacyPolicy;

  /// No description provided for @accountRowTerms.
  ///
  /// In fr, this message translates to:
  /// **'Conditions d\'utilisation'**
  String get accountRowTerms;

  /// No description provided for @accountRowManageData.
  ///
  /// In fr, this message translates to:
  /// **'Gérer mes données'**
  String get accountRowManageData;

  /// No description provided for @ingredientsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes ingrédients'**
  String get ingredientsTitle;

  /// No description provided for @ingredientsTabMine.
  ///
  /// In fr, this message translates to:
  /// **'Mes ingrédients'**
  String get ingredientsTabMine;

  /// No description provided for @ingredientsTabCatalog.
  ///
  /// In fr, this message translates to:
  /// **'Catalogue'**
  String get ingredientsTabCatalog;

  /// No description provided for @ingredientsSearchHint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un ingrédient'**
  String get ingredientsSearchHint;

  /// No description provided for @ingredientsCatalogSearchHint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher dans le catalogue'**
  String get ingredientsCatalogSearchHint;

  /// No description provided for @ingredientsEmptyMine.
  ///
  /// In fr, this message translates to:
  /// **'Aucun ingrédient pour l\'instant. Crée-en un ou importe depuis le catalogue.'**
  String get ingredientsEmptyMine;

  /// No description provided for @ingredientsEmptyCatalog.
  ///
  /// In fr, this message translates to:
  /// **'Aucun ingrédient dans le catalogue.'**
  String get ingredientsEmptyCatalog;

  /// No description provided for @ingredientsNoSearchResult.
  ///
  /// In fr, this message translates to:
  /// **'Aucun résultat.'**
  String get ingredientsNoSearchResult;

  /// No description provided for @ingredientsCreateCta.
  ///
  /// In fr, this message translates to:
  /// **'Créer un ingrédient'**
  String get ingredientsCreateCta;

  /// No description provided for @ingredientsImport.
  ///
  /// In fr, this message translates to:
  /// **'Importer'**
  String get ingredientsImport;

  /// No description provided for @ingredientsAlreadyImported.
  ///
  /// In fr, this message translates to:
  /// **'Déjà importé'**
  String get ingredientsAlreadyImported;

  /// No description provided for @ingredientsImportInfo.
  ///
  /// In fr, this message translates to:
  /// **'Importer crée une copie personnelle, modifiable librement, sans toucher à l\'ingrédient système.'**
  String get ingredientsImportInfo;

  /// No description provided for @ingredientBadgeSystem.
  ///
  /// In fr, this message translates to:
  /// **'système'**
  String get ingredientBadgeSystem;

  /// No description provided for @ingredientImportedToast.
  ///
  /// In fr, this message translates to:
  /// **'Ingrédient importé'**
  String get ingredientImportedToast;

  /// No description provided for @ingredientDeletedToast.
  ///
  /// In fr, this message translates to:
  /// **'Ingrédient supprimé'**
  String get ingredientDeletedToast;

  /// No description provided for @ingredientCreatedToast.
  ///
  /// In fr, this message translates to:
  /// **'Ingrédient créé'**
  String get ingredientCreatedToast;

  /// No description provided for @ingredientSavedToast.
  ///
  /// In fr, this message translates to:
  /// **'Modifications enregistrées'**
  String get ingredientSavedToast;

  /// No description provided for @ingredientDetailTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ingrédient'**
  String get ingredientDetailTitle;

  /// No description provided for @ingredientFieldName.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get ingredientFieldName;

  /// No description provided for @ingredientFieldUnit.
  ///
  /// In fr, this message translates to:
  /// **'Unité de mesure'**
  String get ingredientFieldUnit;

  /// No description provided for @ingredientFromSystem.
  ///
  /// In fr, this message translates to:
  /// **'Provient du catalogue système · copie personnelle'**
  String get ingredientFromSystem;

  /// No description provided for @ingredientSectionAlternatives.
  ///
  /// In fr, this message translates to:
  /// **'Alternatives'**
  String get ingredientSectionAlternatives;

  /// No description provided for @ingredientAlternativesHint.
  ///
  /// In fr, this message translates to:
  /// **'relation symétrique'**
  String get ingredientAlternativesHint;

  /// No description provided for @ingredientNoAlternatives.
  ///
  /// In fr, this message translates to:
  /// **'Aucune alternative pour l\'instant.'**
  String get ingredientNoAlternatives;

  /// No description provided for @ingredientAddAlternative.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get ingredientAddAlternative;

  /// No description provided for @ingredientSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get ingredientSave;

  /// No description provided for @ingredientDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer l\'ingrédient'**
  String get ingredientDelete;

  /// No description provided for @ingredientDeleteConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer cet ingrédient ?'**
  String get ingredientDeleteConfirmTitle;

  /// No description provided for @ingredientDeleteConfirmBody.
  ///
  /// In fr, this message translates to:
  /// **'Il sera masqué mais conservé pour ne pas casser les recettes qui l\'utilisent.'**
  String get ingredientDeleteConfirmBody;

  /// No description provided for @ingredientCreateTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouvel ingrédient'**
  String get ingredientCreateTitle;

  /// No description provided for @ingredientEditTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier l\'ingrédient'**
  String get ingredientEditTitle;

  /// No description provided for @ingredientCreateAction.
  ///
  /// In fr, this message translates to:
  /// **'Créer l\'ingrédient'**
  String get ingredientCreateAction;

  /// No description provided for @ingredientNameHint.
  ///
  /// In fr, this message translates to:
  /// **'ex : Levure chimique'**
  String get ingredientNameHint;

  /// No description provided for @ingredientNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Donne un nom à l\'ingrédient.'**
  String get ingredientNameRequired;

  /// No description provided for @ingredientPickAlternativeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une alternative'**
  String get ingredientPickAlternativeTitle;

  /// No description provided for @ingredientNoCandidate.
  ///
  /// In fr, this message translates to:
  /// **'Aucun autre ingrédient disponible.'**
  String get ingredientNoCandidate;

  /// No description provided for @unitGramme.
  ///
  /// In fr, this message translates to:
  /// **'gramme'**
  String get unitGramme;

  /// No description provided for @unitMilligramme.
  ///
  /// In fr, this message translates to:
  /// **'mg'**
  String get unitMilligramme;

  /// No description provided for @unitPiece.
  ///
  /// In fr, this message translates to:
  /// **'pièce'**
  String get unitPiece;

  /// No description provided for @unitCuillereCafe.
  ///
  /// In fr, this message translates to:
  /// **'c.à.c'**
  String get unitCuillereCafe;

  /// No description provided for @unitCuillereSoupe.
  ///
  /// In fr, this message translates to:
  /// **'c.à.s'**
  String get unitCuillereSoupe;

  /// No description provided for @unitShortGramme.
  ///
  /// In fr, this message translates to:
  /// **'g'**
  String get unitShortGramme;

  /// No description provided for @unitShortMilligramme.
  ///
  /// In fr, this message translates to:
  /// **'mg'**
  String get unitShortMilligramme;

  /// No description provided for @unitShortPiece.
  ///
  /// In fr, this message translates to:
  /// **'pce'**
  String get unitShortPiece;

  /// No description provided for @unitShortCuillereCafe.
  ///
  /// In fr, this message translates to:
  /// **'c.à.c'**
  String get unitShortCuillereCafe;

  /// No description provided for @unitShortCuillereSoupe.
  ///
  /// In fr, this message translates to:
  /// **'c.à.s'**
  String get unitShortCuillereSoupe;

  /// No description provided for @unitDescriptionGramme.
  ///
  /// In fr, this message translates to:
  /// **'en grammes'**
  String get unitDescriptionGramme;

  /// No description provided for @unitDescriptionMilligramme.
  ///
  /// In fr, this message translates to:
  /// **'en milligrammes'**
  String get unitDescriptionMilligramme;

  /// No description provided for @unitDescriptionPiece.
  ///
  /// In fr, this message translates to:
  /// **'à la pièce'**
  String get unitDescriptionPiece;

  /// No description provided for @unitDescriptionCuillereCafe.
  ///
  /// In fr, this message translates to:
  /// **'en cuillères à café'**
  String get unitDescriptionCuillereCafe;

  /// No description provided for @unitDescriptionCuillereSoupe.
  ///
  /// In fr, this message translates to:
  /// **'en cuillères à soupe'**
  String get unitDescriptionCuillereSoupe;

  /// No description provided for @tagsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Tags'**
  String get tagsTitle;

  /// No description provided for @tagsIntro.
  ///
  /// In fr, this message translates to:
  /// **'Qualifie tes recettes, sous-recettes et personnes. Utilisables comme filtres dans la recherche.'**
  String get tagsIntro;

  /// No description provided for @tagsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun tag pour l\'instant. Crée ton premier tag pour qualifier tes recettes.'**
  String get tagsEmpty;

  /// No description provided for @tagsCreateCta.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau tag'**
  String get tagsCreateCta;

  /// No description provided for @tagsRecipeCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{0 recette} =1{1 recette} other{{count} recettes}}'**
  String tagsRecipeCount(int count);

  /// No description provided for @tagCreateTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau tag'**
  String get tagCreateTitle;

  /// No description provided for @tagEditTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le tag'**
  String get tagEditTitle;

  /// No description provided for @tagFieldName.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get tagFieldName;

  /// No description provided for @tagNameHint.
  ///
  /// In fr, this message translates to:
  /// **'ex : Épicé'**
  String get tagNameHint;

  /// No description provided for @tagNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Donne un nom au tag.'**
  String get tagNameRequired;

  /// No description provided for @tagFieldColor.
  ///
  /// In fr, this message translates to:
  /// **'Couleur'**
  String get tagFieldColor;

  /// No description provided for @tagPreview.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu'**
  String get tagPreview;

  /// No description provided for @tagPreviewPlaceholder.
  ///
  /// In fr, this message translates to:
  /// **'Nom du tag'**
  String get tagPreviewPlaceholder;

  /// No description provided for @tagCreateAction.
  ///
  /// In fr, this message translates to:
  /// **'Créer le tag'**
  String get tagCreateAction;

  /// No description provided for @tagDeleteConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce tag ?'**
  String get tagDeleteConfirmTitle;

  /// No description provided for @tagDeleteConfirmBody.
  ///
  /// In fr, this message translates to:
  /// **'« {name} » sera retiré des recettes et des personnes associées.'**
  String tagDeleteConfirmBody(String name);

  /// No description provided for @familleTitle.
  ///
  /// In fr, this message translates to:
  /// **'Famille'**
  String get familleTitle;

  /// No description provided for @familleIntro.
  ///
  /// In fr, this message translates to:
  /// **'Associe des tags à chaque personne pour mettre en avant les recettes qui lui conviennent.'**
  String get familleIntro;

  /// No description provided for @familleEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune personne pour l\'instant. Ajoute les membres de ta famille pour leur associer des tags.'**
  String get familleEmpty;

  /// No description provided for @personCreateCta.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une personne'**
  String get personCreateCta;

  /// No description provided for @personCreateTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle personne'**
  String get personCreateTitle;

  /// No description provided for @personEditTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get personEditTitle;

  /// No description provided for @personFieldFirstName.
  ///
  /// In fr, this message translates to:
  /// **'Prénom'**
  String get personFieldFirstName;

  /// No description provided for @personFieldLastName.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get personFieldLastName;

  /// No description provided for @personFirstNameHint.
  ///
  /// In fr, this message translates to:
  /// **'ex : Emma'**
  String get personFirstNameHint;

  /// No description provided for @personLastNameHint.
  ///
  /// In fr, this message translates to:
  /// **'ex : Martin'**
  String get personLastNameHint;

  /// No description provided for @personFirstNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Donne un prénom à la personne.'**
  String get personFirstNameRequired;

  /// No description provided for @personTagsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Tags associés'**
  String get personTagsLabel;

  /// No description provided for @personTagsEmptyHint.
  ///
  /// In fr, this message translates to:
  /// **'Crée d\'abord des tags pour pouvoir les associer à cette personne.'**
  String get personTagsEmptyHint;

  /// No description provided for @personNoTags.
  ///
  /// In fr, this message translates to:
  /// **'Aucun tag associé'**
  String get personNoTags;

  /// No description provided for @personDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la personne'**
  String get personDelete;

  /// No description provided for @personDeleteConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer cette personne ?'**
  String get personDeleteConfirmTitle;

  /// No description provided for @personDeleteConfirmBody.
  ///
  /// In fr, this message translates to:
  /// **'{name} et ses associations de tags seront supprimés.'**
  String personDeleteConfirmBody(String name);

  /// No description provided for @categoriesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Catégories'**
  String get categoriesTitle;

  /// No description provided for @categoriesIntro.
  ///
  /// In fr, this message translates to:
  /// **'Range tes recettes en dossiers. Touche un dossier pour l\'ouvrir.'**
  String get categoriesIntro;

  /// No description provided for @categoriesEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun dossier pour l\'instant.'**
  String get categoriesEmpty;

  /// No description provided for @categoriesEmptyFolder.
  ///
  /// In fr, this message translates to:
  /// **'Aucun sous-dossier ici. Ajoute-en un avec le bouton +.'**
  String get categoriesEmptyFolder;

  /// No description provided for @categoriesSubfoldersLabel.
  ///
  /// In fr, this message translates to:
  /// **'Sous-dossiers'**
  String get categoriesSubfoldersLabel;

  /// No description provided for @categoriesRecipesLabel.
  ///
  /// In fr, this message translates to:
  /// **'Recettes du dossier'**
  String get categoriesRecipesLabel;

  /// No description provided for @categoriesRecipesEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Les recettes rangées dans ce dossier apparaîtront ici.'**
  String get categoriesRecipesEmpty;

  /// No description provided for @categoriesRecipeCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{0 recette} =1{1 recette} other{{count} recettes}}'**
  String categoriesRecipeCount(int count);

  /// No description provided for @categoryDefaultBadge.
  ///
  /// In fr, this message translates to:
  /// **'Défaut'**
  String get categoryDefaultBadge;

  /// No description provided for @categoryCreateTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau dossier'**
  String get categoryCreateTitle;

  /// No description provided for @categoryEditTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le dossier'**
  String get categoryEditTitle;

  /// No description provided for @categoryFieldIcon.
  ///
  /// In fr, this message translates to:
  /// **'Emoji'**
  String get categoryFieldIcon;

  /// No description provided for @categoryIconHint.
  ///
  /// In fr, this message translates to:
  /// **'Touche pour ouvrir le clavier et choisir un emoji.'**
  String get categoryIconHint;

  /// No description provided for @categoryIconClear.
  ///
  /// In fr, this message translates to:
  /// **'Retirer l\'emoji'**
  String get categoryIconClear;

  /// No description provided for @categoryFieldName.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get categoryFieldName;

  /// No description provided for @categoryNameHint.
  ///
  /// In fr, this message translates to:
  /// **'ex : Pâtes'**
  String get categoryNameHint;

  /// No description provided for @categoryNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Donne un nom au dossier.'**
  String get categoryNameRequired;

  /// No description provided for @categoryFieldParent.
  ///
  /// In fr, this message translates to:
  /// **'Dossier parent'**
  String get categoryFieldParent;

  /// No description provided for @categoryParentRoot.
  ///
  /// In fr, this message translates to:
  /// **'À la racine'**
  String get categoryParentRoot;

  /// No description provided for @categoryDeleteConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce dossier ?'**
  String get categoryDeleteConfirmTitle;

  /// No description provided for @categoryDeleteConfirmBody.
  ///
  /// In fr, this message translates to:
  /// **'« {name} » sera supprimé. Les recettes qu\'il contient ne sont pas supprimées.'**
  String categoryDeleteConfirmBody(String name);

  /// No description provided for @recipesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Recettes'**
  String get recipesTitle;

  /// No description provided for @recipesEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Tu n\'as pas encore de recette. Appuie sur + pour en créer une.'**
  String get recipesEmpty;

  /// No description provided for @recipeCreateTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle recette'**
  String get recipeCreateTitle;

  /// No description provided for @recipeCreateAction.
  ///
  /// In fr, this message translates to:
  /// **'Créer la recette'**
  String get recipeCreateAction;

  /// No description provided for @recipeFieldName.
  ///
  /// In fr, this message translates to:
  /// **'Nom de la recette'**
  String get recipeFieldName;

  /// No description provided for @recipeNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex. Lasagnes maison'**
  String get recipeNameHint;

  /// No description provided for @recipeNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le nom est obligatoire.'**
  String get recipeNameRequired;

  /// No description provided for @recipeNameHelper.
  ///
  /// In fr, this message translates to:
  /// **'Seul champ obligatoire pour démarrer.'**
  String get recipeNameHelper;

  /// No description provided for @recipePhotoTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une photo'**
  String get recipePhotoTitle;

  /// No description provided for @recipePhotoHint.
  ///
  /// In fr, this message translates to:
  /// **'Optionnel · modifiable plus tard'**
  String get recipePhotoHint;

  /// No description provided for @recipeBaseToggleTitle.
  ///
  /// In fr, this message translates to:
  /// **'Recette de base'**
  String get recipeBaseToggleTitle;

  /// No description provided for @recipeBaseToggleSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Réutilisable comme composant'**
  String get recipeBaseToggleSubtitle;

  /// No description provided for @recipeBaseToggleHint.
  ///
  /// In fr, this message translates to:
  /// **'Une béchamel ou une pâte brisée réutilisée dans plusieurs recettes.'**
  String get recipeBaseToggleHint;

  /// No description provided for @recipeBaseBadge.
  ///
  /// In fr, this message translates to:
  /// **'Recette de base'**
  String get recipeBaseBadge;

  /// No description provided for @recipeBaseLockedHint.
  ///
  /// In fr, this message translates to:
  /// **'Verrouillée : utilisée comme composant.'**
  String get recipeBaseLockedHint;

  /// No description provided for @recipeEditTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la recette'**
  String get recipeEditTitle;

  /// No description provided for @recipeDeleteAction.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la recette'**
  String get recipeDeleteAction;

  /// No description provided for @recipeDeleteConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer cette recette ?'**
  String get recipeDeleteConfirmTitle;

  /// No description provided for @recipeDeleteConfirmBody.
  ///
  /// In fr, this message translates to:
  /// **'« {name} » sera supprimée.'**
  String recipeDeleteConfirmBody(String name);

  /// No description provided for @recipeFieldDescription.
  ///
  /// In fr, this message translates to:
  /// **'Description'**
  String get recipeFieldDescription;

  /// No description provided for @recipeDescriptionHint.
  ///
  /// In fr, this message translates to:
  /// **'Quelques mots sur cette recette…'**
  String get recipeDescriptionHint;

  /// No description provided for @recipeFieldPrep.
  ///
  /// In fr, this message translates to:
  /// **'Prépa (min)'**
  String get recipeFieldPrep;

  /// No description provided for @recipeFieldCook.
  ///
  /// In fr, this message translates to:
  /// **'Cuisson (min)'**
  String get recipeFieldCook;

  /// No description provided for @recipeFieldRest.
  ///
  /// In fr, this message translates to:
  /// **'Repos (min)'**
  String get recipeFieldRest;

  /// No description provided for @recipeFieldServings.
  ///
  /// In fr, this message translates to:
  /// **'Personnes'**
  String get recipeFieldServings;

  /// No description provided for @recipeIngredientsSection.
  ///
  /// In fr, this message translates to:
  /// **'Ingrédients'**
  String get recipeIngredientsSection;

  /// No description provided for @recipeIngredientsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun ingrédient pour l\'instant.'**
  String get recipeIngredientsEmpty;

  /// No description provided for @recipeComponentsSection.
  ///
  /// In fr, this message translates to:
  /// **'Sous-recettes utilisées'**
  String get recipeComponentsSection;

  /// No description provided for @recipeUsedInSection.
  ///
  /// In fr, this message translates to:
  /// **'Utilisée dans'**
  String get recipeUsedInSection;

  /// No description provided for @recipeCreatorLabel.
  ///
  /// In fr, this message translates to:
  /// **'Recette de'**
  String get recipeCreatorLabel;

  /// No description provided for @recipeCreatorSelf.
  ///
  /// In fr, this message translates to:
  /// **'Toi'**
  String get recipeCreatorSelf;

  /// No description provided for @recipeServingsShort.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 pers.} other{{count} pers.}}'**
  String recipeServingsShort(int count);

  /// No description provided for @recipePrepShort.
  ///
  /// In fr, this message translates to:
  /// **'Prépa {min} min'**
  String recipePrepShort(int min);

  /// No description provided for @recipeCookShort.
  ///
  /// In fr, this message translates to:
  /// **'Cuisson {min} min'**
  String recipeCookShort(int min);

  /// No description provided for @recipeStepsTab.
  ///
  /// In fr, this message translates to:
  /// **'Étapes'**
  String get recipeStepsTab;

  /// No description provided for @recipeStepsEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune étape pour l\'instant'**
  String get recipeStepsEmptyTitle;

  /// No description provided for @recipeStepsEmptyBody.
  ///
  /// In fr, this message translates to:
  /// **'Décris le déroulé de ta recette. Colle un texte d\'un coup, ou ajoute les étapes une par une.'**
  String get recipeStepsEmptyBody;

  /// No description provided for @recipeStepsPasteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Coller un texte'**
  String get recipeStepsPasteTitle;

  /// No description provided for @recipeStepsPasteSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Chaque paragraphe devient une étape'**
  String get recipeStepsPasteSubtitle;

  /// No description provided for @recipeStepsOneByOneTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une par une'**
  String get recipeStepsOneByOneTitle;

  /// No description provided for @recipeStepsOneByOneSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Composer chaque étape, avec bannière ou sous-recette'**
  String get recipeStepsOneByOneSubtitle;

  /// No description provided for @recipeStepsAddCta.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une étape'**
  String get recipeStepsAddCta;

  /// No description provided for @recipeStepIngredientsChip.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 ingrédient} other{{count} ingrédients}}'**
  String recipeStepIngredientsChip(int count);

  /// No description provided for @recipeStepBaseRefLabel.
  ///
  /// In fr, this message translates to:
  /// **'{name} · recette de base'**
  String recipeStepBaseRefLabel(String name);

  /// No description provided for @recipeStepFrozenNote.
  ///
  /// In fr, this message translates to:
  /// **'Étapes figées, modifiables depuis leur recette'**
  String get recipeStepFrozenNote;

  /// No description provided for @recipeStepRemoveRef.
  ///
  /// In fr, this message translates to:
  /// **'Retirer la référence'**
  String get recipeStepRemoveRef;

  /// No description provided for @recipeStepsImportTitle.
  ///
  /// In fr, this message translates to:
  /// **'Importer des étapes'**
  String get recipeStepsImportTitle;

  /// No description provided for @recipeStepsImportHint.
  ///
  /// In fr, this message translates to:
  /// **'Sépare chaque étape par une ligne vide. Ce mode ne crée que des étapes texte (pas de sous-recette).'**
  String get recipeStepsImportHint;

  /// No description provided for @recipeStepsImportPlaceholder.
  ///
  /// In fr, this message translates to:
  /// **'Colle ton texte ici…'**
  String get recipeStepsImportPlaceholder;

  /// No description provided for @recipeStepsDetected.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucune étape détectée} =1{1 étape détectée} other{{count} étapes détectées}}'**
  String recipeStepsDetected(int count);

  /// No description provided for @recipeStepsImportCta.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Créer les étapes} =1{Créer 1 étape} other{Créer {count} étapes}}'**
  String recipeStepsImportCta(int count);

  /// No description provided for @recipeStepAddTitle.
  ///
  /// In fr, this message translates to:
  /// **'Étape {number}'**
  String recipeStepAddTitle(int number);

  /// No description provided for @recipeStepEditTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier l\'étape {number}'**
  String recipeStepEditTitle(int number);

  /// No description provided for @recipeStepAlreadyAdded.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucune étape ajoutée} =1{1 étape déjà ajoutée} other{{count} étapes déjà ajoutées}}'**
  String recipeStepAlreadyAdded(int count);

  /// No description provided for @recipeStepFieldDescription.
  ///
  /// In fr, this message translates to:
  /// **'Description'**
  String get recipeStepFieldDescription;

  /// No description provided for @recipeStepDescriptionHint.
  ///
  /// In fr, this message translates to:
  /// **'Décris cette étape…'**
  String get recipeStepDescriptionHint;

  /// No description provided for @recipeStepAddOptional.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter (optionnel)'**
  String get recipeStepAddOptional;

  /// No description provided for @recipeStepBannerOption.
  ///
  /// In fr, this message translates to:
  /// **'Une bannière'**
  String get recipeStepBannerOption;

  /// No description provided for @recipeStepBannerOptionHint.
  ///
  /// In fr, this message translates to:
  /// **'Warning, info, danger ou learn'**
  String get recipeStepBannerOptionHint;

  /// No description provided for @recipeStepBaseRefOption.
  ///
  /// In fr, this message translates to:
  /// **'Une recette de base'**
  String get recipeStepBaseRefOption;

  /// No description provided for @recipeStepBaseRefOptionHint.
  ///
  /// In fr, this message translates to:
  /// **'Insère ses étapes par référence'**
  String get recipeStepBaseRefOptionHint;

  /// No description provided for @recipeStepBannerLabel.
  ///
  /// In fr, this message translates to:
  /// **'Bannière'**
  String get recipeStepBannerLabel;

  /// No description provided for @recipeStepBannerRemove.
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get recipeStepBannerRemove;

  /// No description provided for @recipeStepBannerTextHint.
  ///
  /// In fr, this message translates to:
  /// **'Texte de la bannière'**
  String get recipeStepBannerTextHint;

  /// No description provided for @recipeStepBaseRefUnavailableLabel.
  ///
  /// In fr, this message translates to:
  /// **'Référence recette de base'**
  String get recipeStepBaseRefUnavailableLabel;

  /// No description provided for @recipeStepBaseRefUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'indispo. avec une bannière'**
  String get recipeStepBaseRefUnavailable;

  /// No description provided for @recipeStepIngredientsSectionLabel.
  ///
  /// In fr, this message translates to:
  /// **'Ingrédients de l\'étape'**
  String get recipeStepIngredientsSectionLabel;

  /// No description provided for @recipeStepSelect.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner'**
  String get recipeStepSelect;

  /// No description provided for @recipeStepAddNext.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter et suivant'**
  String get recipeStepAddNext;

  /// No description provided for @recipeStepFinish.
  ///
  /// In fr, this message translates to:
  /// **'Terminer'**
  String get recipeStepFinish;

  /// No description provided for @recipeStepDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer l\'étape'**
  String get recipeStepDelete;

  /// No description provided for @recipeStepDescriptionRequired.
  ///
  /// In fr, this message translates to:
  /// **'Décris l\'étape avant de l\'ajouter.'**
  String get recipeStepDescriptionRequired;

  /// No description provided for @stepBannerWarning.
  ///
  /// In fr, this message translates to:
  /// **'Warning'**
  String get stepBannerWarning;

  /// No description provided for @stepBannerInfo.
  ///
  /// In fr, this message translates to:
  /// **'Info'**
  String get stepBannerInfo;

  /// No description provided for @stepBannerDanger.
  ///
  /// In fr, this message translates to:
  /// **'Danger'**
  String get stepBannerDanger;

  /// No description provided for @stepBannerLearn.
  ///
  /// In fr, this message translates to:
  /// **'Learn'**
  String get stepBannerLearn;

  /// No description provided for @recipeStepIngredientsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ingrédients de l\'étape'**
  String get recipeStepIngredientsTitle;

  /// No description provided for @recipeStepIngredientsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Parmi ceux de la recette'**
  String get recipeStepIngredientsSubtitle;

  /// No description provided for @recipeStepIngredientsInfo.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionne uniquement les ingrédients utilisés à cette étape.'**
  String get recipeStepIngredientsInfo;

  /// No description provided for @recipeStepIngredientsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute d\'abord des ingrédients à la recette.'**
  String get recipeStepIngredientsEmpty;

  /// No description provided for @recipeStepIngredientsValidate.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Valider} =1{Valider · 1 sélectionné} other{Valider · {count} sélectionnés}}'**
  String recipeStepIngredientsValidate(int count);

  /// No description provided for @recipeStepBasePickerTitle.
  ///
  /// In fr, this message translates to:
  /// **'Recette de base'**
  String get recipeStepBasePickerTitle;

  /// No description provided for @recipeStepBasePickerSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Ses étapes seront insérées par référence'**
  String get recipeStepBasePickerSubtitle;

  /// No description provided for @recipeStepBasePickerEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune recette de base disponible.'**
  String get recipeStepBasePickerEmpty;

  /// No description provided for @commonClose.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get commonClose;

  /// No description provided for @recipeServingsSectionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Portions'**
  String get recipeServingsSectionTitle;

  /// No description provided for @recipeServingsScaleHint.
  ///
  /// In fr, this message translates to:
  /// **'Les quantités s\'adaptent'**
  String get recipeServingsScaleHint;

  /// No description provided for @recipeIngredientsAddCta.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter des ingrédients'**
  String get recipeIngredientsAddCta;

  /// No description provided for @recipeIngredientQuantityTitle.
  ///
  /// In fr, this message translates to:
  /// **'Quantité'**
  String get recipeIngredientQuantityTitle;

  /// No description provided for @recipeIngredientRemove.
  ///
  /// In fr, this message translates to:
  /// **'Retirer de la recette'**
  String get recipeIngredientRemove;

  /// No description provided for @recipeIngredientAddedToast.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 ingrédient ajouté} other{{count} ingrédients ajoutés}}'**
  String recipeIngredientAddedToast(int count);

  /// No description provided for @addIngredientsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter des ingrédients'**
  String get addIngredientsTitle;

  /// No description provided for @addIngredientsSearchHint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un ingrédient'**
  String get addIngredientsSearchHint;

  /// No description provided for @addIngredientsTabCatalog.
  ///
  /// In fr, this message translates to:
  /// **'Catalogue système'**
  String get addIngredientsTabCatalog;

  /// No description provided for @addIngredientsCreateCta.
  ///
  /// In fr, this message translates to:
  /// **'Créer un nouvel ingrédient'**
  String get addIngredientsCreateCta;

  /// No description provided for @addIngredientsCatalogInfo.
  ///
  /// In fr, this message translates to:
  /// **'Importe un ingrédient système pour l\'ajouter à tes ingrédients, puis à la recette.'**
  String get addIngredientsCatalogInfo;

  /// No description provided for @addIngredientsEmptyMine.
  ///
  /// In fr, this message translates to:
  /// **'Aucun ingrédient. Crée ou importe-en un depuis le catalogue.'**
  String get addIngredientsEmptyMine;

  /// No description provided for @addIngredientsCta.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Sélectionne un ingrédient} =1{Ajouter 1 ingrédient} other{Ajouter {count} ingrédients}}'**
  String addIngredientsCta(int count);

  /// No description provided for @homeGreetingQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Que veux-tu préparer aujourd\'hui ?'**
  String get homeGreetingQuestion;

  /// No description provided for @homeSearchHint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher une recette'**
  String get homeSearchHint;

  /// No description provided for @homeSearchComingSoon.
  ///
  /// In fr, this message translates to:
  /// **'Recherche bientôt disponible'**
  String get homeSearchComingSoon;

  /// No description provided for @homeCategoryAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout'**
  String get homeCategoryAll;

  /// No description provided for @homeSuggestionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Suggestion du jour'**
  String get homeSuggestionTitle;

  /// No description provided for @homeSuggestionBadge.
  ///
  /// In fr, this message translates to:
  /// **'Suggestion'**
  String get homeSuggestionBadge;

  /// No description provided for @homeFeaturedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mises en avant'**
  String get homeFeaturedTitle;

  /// No description provided for @homeFeaturedHint.
  ///
  /// In fr, this message translates to:
  /// **'Glisse'**
  String get homeFeaturedHint;

  /// No description provided for @homeEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rien à cuisiner… pour l\'instant'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptyBody.
  ///
  /// In fr, this message translates to:
  /// **'Crée ta première recette avec le bouton +.'**
  String get homeEmptyBody;

  /// No description provided for @commonCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get commonSave;

  /// No description provided for @commonDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get commonDelete;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
