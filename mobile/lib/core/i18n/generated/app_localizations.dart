import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// Nom de l'application
  ///
  /// In fr, this message translates to:
  /// **'Cocotte Minute'**
  String get appTitle;

  /// No description provided for @commonRetry.
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

  /// Titre de la page de gestion du compte connecté
  ///
  /// In fr, this message translates to:
  /// **'Gérer le compte'**
  String get accountManageTitle;

  /// No description provided for @accountManageEmailSection.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail'**
  String get accountManageEmailSection;

  /// No description provided for @accountManageEmailHelp.
  ///
  /// In fr, this message translates to:
  /// **'Un e-mail de confirmation te sera envoyé pour valider le changement.'**
  String get accountManageEmailHelp;

  /// No description provided for @accountManageEmailUnchanged.
  ///
  /// In fr, this message translates to:
  /// **'C\'est déjà ton adresse e-mail actuelle.'**
  String get accountManageEmailUnchanged;

  /// No description provided for @accountManageEmailSent.
  ///
  /// In fr, this message translates to:
  /// **'E-mail de confirmation envoyé. Vérifie ta boîte de réception.'**
  String get accountManageEmailSent;

  /// No description provided for @accountManagePasswordSection.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get accountManagePasswordSection;

  /// No description provided for @accountManagePasswordHelp.
  ///
  /// In fr, this message translates to:
  /// **'Choisis un nouveau mot de passe d\'au moins 6 caractères.'**
  String get accountManagePasswordHelp;

  /// No description provided for @accountManageNewPassword.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau mot de passe'**
  String get accountManageNewPassword;

  /// No description provided for @accountManageConfirmPassword.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le mot de passe'**
  String get accountManageConfirmPassword;

  /// No description provided for @accountManageConfirmPasswordHint.
  ///
  /// In fr, this message translates to:
  /// **'Retape ton mot de passe'**
  String get accountManageConfirmPasswordHint;

  /// No description provided for @accountManagePasswordMismatch.
  ///
  /// In fr, this message translates to:
  /// **'Les deux mots de passe ne correspondent pas.'**
  String get accountManagePasswordMismatch;

  /// No description provided for @accountManagePasswordUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe modifié.'**
  String get accountManagePasswordUpdated;

  /// Entrée de menu pour exporter la fiche recette en PDF
  ///
  /// In fr, this message translates to:
  /// **'Exporter en PDF'**
  String get pdfExportAction;

  /// No description provided for @pdfExportError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de générer le PDF.'**
  String get pdfExportError;

  /// Entrée de menu de la fiche : ouvre la feuille de partage
  ///
  /// In fr, this message translates to:
  /// **'Partager'**
  String get shareRecipeAction;

  /// Entrée de menu de la fiche : ajoute la recette à une liste de courses
  ///
  /// In fr, this message translates to:
  /// **'Ajouter aux courses'**
  String get recipeMenuAddToShopping;

  /// Entrée de menu de la fiche : export PDF direct
  ///
  /// In fr, this message translates to:
  /// **'Télécharger en PDF'**
  String get recipeMenuDownloadPdf;

  /// No description provided for @shareRecipeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Partager la recette'**
  String get shareRecipeTitle;

  /// No description provided for @shareSectionExport.
  ///
  /// In fr, this message translates to:
  /// **'Exporter'**
  String get shareSectionExport;

  /// No description provided for @shareSectionShare.
  ///
  /// In fr, this message translates to:
  /// **'Partager'**
  String get shareSectionShare;

  /// No description provided for @shareExportPdfSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Feuille A4, prête à imprimer'**
  String get shareExportPdfSubtitle;

  /// No description provided for @shareCopyLink.
  ///
  /// In fr, this message translates to:
  /// **'Copier le lien'**
  String get shareCopyLink;

  /// No description provided for @shareCopyLinkSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Lien de partage vers la recette'**
  String get shareCopyLinkSubtitle;

  /// No description provided for @shareCopyLinkDone.
  ///
  /// In fr, this message translates to:
  /// **'Lien copié dans le presse-papiers.'**
  String get shareCopyLinkDone;

  /// No description provided for @shareVia.
  ///
  /// In fr, this message translates to:
  /// **'Partager…'**
  String get shareVia;

  /// No description provided for @shareViaSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer le lien via une autre app'**
  String get shareViaSubtitle;

  /// No description provided for @shareLinkError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de générer le lien de partage.'**
  String get shareLinkError;

  /// No description provided for @pdfRecipeBadge.
  ///
  /// In fr, this message translates to:
  /// **'Recette'**
  String get pdfRecipeBadge;

  /// No description provided for @pdfBaseBadge.
  ///
  /// In fr, this message translates to:
  /// **'Recette de base'**
  String get pdfBaseBadge;

  /// No description provided for @pdfRefBadge.
  ///
  /// In fr, this message translates to:
  /// **'référence'**
  String get pdfRefBadge;

  /// No description provided for @pdfPrep.
  ///
  /// In fr, this message translates to:
  /// **'Prépa {duration}'**
  String pdfPrep(String duration);

  /// No description provided for @pdfCook.
  ///
  /// In fr, this message translates to:
  /// **'Cuisson {duration}'**
  String pdfCook(String duration);

  /// No description provided for @pdfRest.
  ///
  /// In fr, this message translates to:
  /// **'Repos {duration}'**
  String pdfRest(String duration);

  /// No description provided for @pdfServingsSuffix.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{personne} other{personnes}}'**
  String pdfServingsSuffix(int count);

  /// Libellé de la tuile méta (temps de préparation) sur le PDF
  ///
  /// In fr, this message translates to:
  /// **'Préparation'**
  String get pdfMetaPrep;

  /// No description provided for @pdfMetaCook.
  ///
  /// In fr, this message translates to:
  /// **'Cuisson'**
  String get pdfMetaCook;

  /// No description provided for @pdfMetaRest.
  ///
  /// In fr, this message translates to:
  /// **'Repos'**
  String get pdfMetaRest;

  /// No description provided for @pdfSectionIngredients.
  ///
  /// In fr, this message translates to:
  /// **'Ingrédients'**
  String get pdfSectionIngredients;

  /// No description provided for @pdfNoIngredients.
  ///
  /// In fr, this message translates to:
  /// **'Aucun ingrédient.'**
  String get pdfNoIngredients;

  /// No description provided for @pdfSectionSteps.
  ///
  /// In fr, this message translates to:
  /// **'Étapes'**
  String get pdfSectionSteps;

  /// No description provided for @pdfNoSteps.
  ///
  /// In fr, this message translates to:
  /// **'Aucune étape.'**
  String get pdfNoSteps;

  /// No description provided for @pdfSectionSubRecipes.
  ///
  /// In fr, this message translates to:
  /// **'Sous-recettes utilisées'**
  String get pdfSectionSubRecipes;

  /// No description provided for @pdfBannerTip.
  ///
  /// In fr, this message translates to:
  /// **'Astuce'**
  String get pdfBannerTip;

  /// No description provided for @pdfBannerWarning.
  ///
  /// In fr, this message translates to:
  /// **'Attention'**
  String get pdfBannerWarning;

  /// No description provided for @pdfBannerDanger.
  ///
  /// In fr, this message translates to:
  /// **'Attention'**
  String get pdfBannerDanger;

  /// No description provided for @pdfBannerLearn.
  ///
  /// In fr, this message translates to:
  /// **'Référence'**
  String get pdfBannerLearn;

  /// Titre de la carte permanente invitant un invité à créer un compte
  ///
  /// In fr, this message translates to:
  /// **'Garde tes recettes pour toujours'**
  String get accountGuestCtaTitle;

  /// No description provided for @accountGuestCtaBody.
  ///
  /// In fr, this message translates to:
  /// **'Crée un compte gratuit pour sauvegarder tes recettes et les retrouver sur tous tes appareils.'**
  String get accountGuestCtaBody;

  /// No description provided for @accountGuestCtaButton.
  ///
  /// In fr, this message translates to:
  /// **'Créer ton compte'**
  String get accountGuestCtaButton;

  /// Titre du dialogue d'avertissement de déconnexion en compte invité
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter ?'**
  String get accountGuestLogoutTitle;

  /// No description provided for @accountGuestLogoutBody.
  ///
  /// In fr, this message translates to:
  /// **'Tu es en compte invité : après déconnexion, tu ne pourras plus retrouver tes recettes ni tes listes. Crée d\'abord un compte pour les conserver.'**
  String get accountGuestLogoutBody;

  /// No description provided for @accountGuestLogoutConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter quand même'**
  String get accountGuestLogoutConfirm;

  /// No description provided for @accountGuestLogoutSublabel.
  ///
  /// In fr, this message translates to:
  /// **'En invité : tes données seront perdues'**
  String get accountGuestLogoutSublabel;

  /// No description provided for @accountRowDeleteGuest.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer mes données'**
  String get accountRowDeleteGuest;

  /// No description provided for @accountGuestDeleteSublabel.
  ///
  /// In fr, this message translates to:
  /// **'Effacement immédiat et définitif'**
  String get accountGuestDeleteSublabel;

  /// No description provided for @privacyPolicyIntro.
  ///
  /// In fr, this message translates to:
  /// **'Cocotte Minute respecte tes données. Voici, simplement, ce que l\'app collecte et pourquoi.'**
  String get privacyPolicyIntro;

  /// No description provided for @privacyPolicyS1Title.
  ///
  /// In fr, this message translates to:
  /// **'Ce que nous collectons'**
  String get privacyPolicyS1Title;

  /// No description provided for @privacyPolicyS1Body.
  ///
  /// In fr, this message translates to:
  /// **'Tes recettes, dossiers, tags, personnes et listes de courses, ainsi que l\'adresse e-mail de ton compte si tu en as créé un. En compte invité, seul un identifiant technique anonyme est utilisé.'**
  String get privacyPolicyS1Body;

  /// No description provided for @privacyPolicyS2Title.
  ///
  /// In fr, this message translates to:
  /// **'Pourquoi nous les utilisons'**
  String get privacyPolicyS2Title;

  /// No description provided for @privacyPolicyS2Body.
  ///
  /// In fr, this message translates to:
  /// **'Uniquement pour faire fonctionner l\'app : sauvegarder ton contenu, le synchroniser entre tes appareils et générer tes listes de courses. Aucune revente de données, aucune publicité ciblée.'**
  String get privacyPolicyS2Body;

  /// No description provided for @privacyPolicyS3Title.
  ///
  /// In fr, this message translates to:
  /// **'Où elles sont stockées'**
  String get privacyPolicyS3Title;

  /// No description provided for @privacyPolicyS3Body.
  ///
  /// In fr, this message translates to:
  /// **'Sur des serveurs sécurisés hébergés dans l\'Union européenne. Tes listes de courses sont aussi conservées sur ton appareil pour fonctionner hors connexion.'**
  String get privacyPolicyS3Body;

  /// No description provided for @privacyPolicyS4Title.
  ///
  /// In fr, this message translates to:
  /// **'Combien de temps'**
  String get privacyPolicyS4Title;

  /// No description provided for @privacyPolicyS4Body.
  ///
  /// In fr, this message translates to:
  /// **'Tant que ton compte existe. Si tu supprimes ton compte, tes données sont anonymisées immédiatement puis définitivement effacées sous 30 jours. Pour un compte invité, l\'effacement est immédiat.'**
  String get privacyPolicyS4Body;

  /// No description provided for @privacyPolicyS5Title.
  ///
  /// In fr, this message translates to:
  /// **'Tes droits'**
  String get privacyPolicyS5Title;

  /// No description provided for @privacyPolicyS5Body.
  ///
  /// In fr, this message translates to:
  /// **'Tu peux consulter, corriger ou supprimer tes données à tout moment depuis l\'app (Compte → Gérer mes données). Pour toute question, écris-nous via « Nous contacter ».'**
  String get privacyPolicyS5Body;

  /// No description provided for @termsIntro.
  ///
  /// In fr, this message translates to:
  /// **'En utilisant Cocotte Minute, tu acceptes ces quelques règles de bon sens.'**
  String get termsIntro;

  /// No description provided for @termsS1Title.
  ///
  /// In fr, this message translates to:
  /// **'Le service'**
  String get termsS1Title;

  /// No description provided for @termsS1Body.
  ///
  /// In fr, this message translates to:
  /// **'Cocotte Minute te permet de créer, organiser et cuisiner tes recettes, et de générer des listes de courses. Le service évolue régulièrement ; certaines fonctionnalités peuvent changer.'**
  String get termsS1Body;

  /// No description provided for @termsS2Title.
  ///
  /// In fr, this message translates to:
  /// **'Ton contenu'**
  String get termsS2Title;

  /// No description provided for @termsS2Body.
  ///
  /// In fr, this message translates to:
  /// **'Tes recettes t\'appartiennent. Tu nous autorises simplement à les stocker et à les afficher pour te fournir le service — rien d\'autre.'**
  String get termsS2Body;

  /// No description provided for @termsS3Title.
  ///
  /// In fr, this message translates to:
  /// **'Compte invité'**
  String get termsS3Title;

  /// No description provided for @termsS3Body.
  ///
  /// In fr, this message translates to:
  /// **'Sans compte, tes données sont liées à cet appareil. Crée un compte à tout moment pour les sécuriser : tout est conservé lors de la conversion.'**
  String get termsS3Body;

  /// No description provided for @termsS4Title.
  ///
  /// In fr, this message translates to:
  /// **'Usage acceptable'**
  String get termsS4Title;

  /// No description provided for @termsS4Body.
  ///
  /// In fr, this message translates to:
  /// **'N\'utilise pas l\'app pour publier des contenus illégaux ou porter atteinte aux droits d\'autrui, et ne tente pas de perturber le service.'**
  String get termsS4Body;

  /// No description provided for @termsS5Title.
  ///
  /// In fr, this message translates to:
  /// **'Suppression'**
  String get termsS5Title;

  /// No description provided for @termsS5Body.
  ///
  /// In fr, this message translates to:
  /// **'Tu peux supprimer ton compte et tes données à tout moment depuis Compte → Gérer mes données.'**
  String get termsS5Body;

  /// No description provided for @termsS6Title.
  ///
  /// In fr, this message translates to:
  /// **'Responsabilité'**
  String get termsS6Title;

  /// No description provided for @termsS6Body.
  ///
  /// In fr, this message translates to:
  /// **'Le service est fourni « en l\'état ». Nous faisons le maximum pour qu\'il soit fiable, sans pouvoir garantir une disponibilité permanente.'**
  String get termsS6Body;

  /// No description provided for @manageDataStoredSection.
  ///
  /// In fr, this message translates to:
  /// **'Ce que Cocotte conserve'**
  String get manageDataStoredSection;

  /// No description provided for @manageDataStoredRecipes.
  ///
  /// In fr, this message translates to:
  /// **'Recettes, dossiers et tags'**
  String get manageDataStoredRecipes;

  /// No description provided for @manageDataStoredRecipesSub.
  ///
  /// In fr, this message translates to:
  /// **'Stockés sur nos serveurs sécurisés (Union européenne)'**
  String get manageDataStoredRecipesSub;

  /// No description provided for @manageDataStoredShopping.
  ///
  /// In fr, this message translates to:
  /// **'Listes de courses'**
  String get manageDataStoredShopping;

  /// No description provided for @manageDataStoredShoppingSub.
  ///
  /// In fr, this message translates to:
  /// **'Sur cet appareil, synchronisées avec ton compte'**
  String get manageDataStoredShoppingSub;

  /// No description provided for @manageDataStoredAccount.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get manageDataStoredAccount;

  /// No description provided for @manageDataStoredAccountSub.
  ///
  /// In fr, this message translates to:
  /// **'Ton e-mail si tu as créé un compte, un identifiant anonyme sinon'**
  String get manageDataStoredAccountSub;

  /// No description provided for @manageDataRightsSection.
  ///
  /// In fr, this message translates to:
  /// **'Tes droits'**
  String get manageDataRightsSection;

  /// No description provided for @manageDataDeleteLabel.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer mon compte et mes données'**
  String get manageDataDeleteLabel;

  /// No description provided for @manageDataDeleteSub.
  ///
  /// In fr, this message translates to:
  /// **'Compte : effacement définitif sous 30 jours · Invité : immédiat'**
  String get manageDataDeleteSub;

  /// No description provided for @helpCenterIntro.
  ///
  /// In fr, this message translates to:
  /// **'Trouve rapidement une réponse aux questions les plus fréquentes.'**
  String get helpCenterIntro;

  /// No description provided for @helpCenterEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune question pour l\'instant. Reviens bientôt !'**
  String get helpCenterEmpty;

  /// No description provided for @helpCenterContactTitle.
  ///
  /// In fr, this message translates to:
  /// **'Tu ne trouves pas ta réponse ?'**
  String get helpCenterContactTitle;

  /// No description provided for @helpCenterContactSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Écris-nous, on te répond vite'**
  String get helpCenterContactSubtitle;

  /// No description provided for @contactIntro.
  ///
  /// In fr, this message translates to:
  /// **'Une question, un bug, une idée ? Dis-nous tout, on lit chaque message.'**
  String get contactIntro;

  /// No description provided for @contactSubjectLabel.
  ///
  /// In fr, this message translates to:
  /// **'Sujet'**
  String get contactSubjectLabel;

  /// No description provided for @contactSubjectHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex : Problème avec ma liste de courses'**
  String get contactSubjectHint;

  /// No description provided for @contactSubjectError.
  ///
  /// In fr, this message translates to:
  /// **'Indique un sujet.'**
  String get contactSubjectError;

  /// No description provided for @contactMessageLabel.
  ///
  /// In fr, this message translates to:
  /// **'Message'**
  String get contactMessageLabel;

  /// No description provided for @contactMessageHint.
  ///
  /// In fr, this message translates to:
  /// **'Décris ta demande le plus précisément possible.'**
  String get contactMessageHint;

  /// No description provided for @contactMessageError.
  ///
  /// In fr, this message translates to:
  /// **'Écris ton message.'**
  String get contactMessageError;

  /// No description provided for @contactSendAction.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer'**
  String get contactSendAction;

  /// No description provided for @contactSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Message envoyé. Merci, on te répond au plus vite !'**
  String get contactSuccess;

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

  /// No description provided for @categoriesSubfolderCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 sous-dossier} other{{count} sous-dossiers}}'**
  String categoriesSubfolderCount(int count);

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

  /// No description provided for @recipesOtherFolderTitle.
  ///
  /// In fr, this message translates to:
  /// **'Autres'**
  String get recipesOtherFolderTitle;

  /// No description provided for @recipesOtherFolderEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune recette sans dossier. Tout est bien rangé !'**
  String get recipesOtherFolderEmpty;

  /// No description provided for @recipeMenuAssignFolders.
  ///
  /// In fr, this message translates to:
  /// **'Associer des dossiers'**
  String get recipeMenuAssignFolders;

  /// No description provided for @recipeMenuAssignTags.
  ///
  /// In fr, this message translates to:
  /// **'Associer des tags'**
  String get recipeMenuAssignTags;

  /// No description provided for @recipeMenuAssignPerson.
  ///
  /// In fr, this message translates to:
  /// **'Associer une personne'**
  String get recipeMenuAssignPerson;

  /// No description provided for @recipePeopleSheetTitle.
  ///
  /// In fr, this message translates to:
  /// **'Associer une personne'**
  String get recipePeopleSheetTitle;

  /// No description provided for @recipePeopleSheetSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionne les personnes pour qui cette recette est pensée.'**
  String get recipePeopleSheetSubtitle;

  /// No description provided for @recipePeopleSheetEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune personne pour l\'instant. Ajoute des membres de ta famille depuis l\'onglet Compte.'**
  String get recipePeopleSheetEmpty;

  /// No description provided for @personRecipesLabel.
  ///
  /// In fr, this message translates to:
  /// **'Ses recettes'**
  String get personRecipesLabel;

  /// No description provided for @personRecipesAddTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter des recettes'**
  String get personRecipesAddTooltip;

  /// No description provided for @personRecipesRemoveTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Retirer la recette'**
  String get personRecipesRemoveTooltip;

  /// No description provided for @personRecipesEmptyHint.
  ///
  /// In fr, this message translates to:
  /// **'Aucune recette associée. Ajoute ses plats préférés avec le bouton +.'**
  String get personRecipesEmptyHint;

  /// No description provided for @personRecipesPickTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter des recettes'**
  String get personRecipesPickTitle;

  /// No description provided for @personRecipesPickSearchHint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher une recette…'**
  String get personRecipesPickSearchHint;

  /// No description provided for @personRecipesPickEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune recette à ajouter.'**
  String get personRecipesPickEmpty;

  /// No description provided for @personRecipesPickAdd.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Ajouter} =1{Ajouter 1 recette} other{Ajouter {count} recettes}}'**
  String personRecipesPickAdd(num count);

  /// No description provided for @recipesViewList.
  ///
  /// In fr, this message translates to:
  /// **'Vue liste'**
  String get recipesViewList;

  /// No description provided for @recipesViewFolders.
  ///
  /// In fr, this message translates to:
  /// **'Vue dossiers'**
  String get recipesViewFolders;

  /// No description provided for @recipesListFilterHint.
  ///
  /// In fr, this message translates to:
  /// **'Filtrer les recettes…'**
  String get recipesListFilterHint;

  /// No description provided for @recipesListEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune recette ne correspond.'**
  String get recipesListEmpty;

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

  /// No description provided for @recipesSearchHint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher dans tes recettes'**
  String get recipesSearchHint;

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

  /// No description provided for @recipeComponentsAddCta.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une sous-recette'**
  String get recipeComponentsAddCta;

  /// No description provided for @recipeComponentRemove.
  ///
  /// In fr, this message translates to:
  /// **'Retirer la sous-recette'**
  String get recipeComponentRemove;

  /// No description provided for @recipeTagsSection.
  ///
  /// In fr, this message translates to:
  /// **'Tags'**
  String get recipeTagsSection;

  /// No description provided for @recipeTagsNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucun tag'**
  String get recipeTagsNone;

  /// No description provided for @recipeTagsEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier les tags'**
  String get recipeTagsEdit;

  /// No description provided for @recipeTagsSheetTitle.
  ///
  /// In fr, this message translates to:
  /// **'Étiqueter la recette'**
  String get recipeTagsSheetTitle;

  /// No description provided for @recipeTagsSheetSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisis les tags à associer à cette recette.'**
  String get recipeTagsSheetSubtitle;

  /// No description provided for @recipeTagsSheetEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Tu n\'as pas encore de tag. Crée-en depuis Compte → Tags.'**
  String get recipeTagsSheetEmpty;

  /// No description provided for @recipeFoldersSection.
  ///
  /// In fr, this message translates to:
  /// **'Dossiers'**
  String get recipeFoldersSection;

  /// No description provided for @recipeFoldersNone.
  ///
  /// In fr, this message translates to:
  /// **'Dans aucun dossier'**
  String get recipeFoldersNone;

  /// No description provided for @recipeFoldersEdit.
  ///
  /// In fr, this message translates to:
  /// **'Ranger dans un dossier'**
  String get recipeFoldersEdit;

  /// No description provided for @recipeFoldersSheetTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ranger la recette'**
  String get recipeFoldersSheetTitle;

  /// No description provided for @recipeFoldersSheetSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisis un ou plusieurs dossiers.'**
  String get recipeFoldersSheetSubtitle;

  /// No description provided for @recipeFoldersSheetEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun dossier. Crée-en depuis Compte → Catégories.'**
  String get recipeFoldersSheetEmpty;

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

  /// No description provided for @recipeRestShort.
  ///
  /// In fr, this message translates to:
  /// **'Repos {min} min'**
  String recipeRestShort(int min);

  /// Bandeau d'une recette ouverte via un lien de partage (lecture seule)
  ///
  /// In fr, this message translates to:
  /// **'Recette partagée'**
  String get sharedRecipeBadge;

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

  /// Badge de la recette hero de l'accueil Découverte
  ///
  /// In fr, this message translates to:
  /// **'À la une'**
  String get homeHeroBadge;

  /// No description provided for @homeSeasonBadge.
  ///
  /// In fr, this message translates to:
  /// **'De saison'**
  String get homeSeasonBadge;

  /// No description provided for @homeSeeAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout voir'**
  String get homeSeeAll;

  /// No description provided for @homeRowSeasonalIn.
  ///
  /// In fr, this message translates to:
  /// **'De saison en {month}'**
  String homeRowSeasonalIn(String month);

  /// No description provided for @homeRowQuick.
  ///
  /// In fr, this message translates to:
  /// **'Prêt en 30 min'**
  String get homeRowQuick;

  /// No description provided for @homeRowRecent.
  ///
  /// In fr, this message translates to:
  /// **'Récemment ajoutées'**
  String get homeRowRecent;

  /// No description provided for @homeRowPerson.
  ///
  /// In fr, this message translates to:
  /// **'Pour {name}'**
  String homeRowPerson(String name);

  /// No description provided for @homeRowBase.
  ///
  /// In fr, this message translates to:
  /// **'Tes recettes de base'**
  String get homeRowBase;

  /// No description provided for @homeRowLarge.
  ///
  /// In fr, this message translates to:
  /// **'Pour la tablée'**
  String get homeRowLarge;

  /// No description provided for @homeRowSolo.
  ///
  /// In fr, this message translates to:
  /// **'En solo ou à deux'**
  String get homeRowSolo;

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

  /// No description provided for @commonEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get commonEdit;

  /// No description provided for @commonRename.
  ///
  /// In fr, this message translates to:
  /// **'Renommer'**
  String get commonRename;

  /// No description provided for @shoppingTabEyebrow.
  ///
  /// In fr, this message translates to:
  /// **'Courses'**
  String get shoppingTabEyebrow;

  /// No description provided for @shoppingTabTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes courses'**
  String get shoppingTabTitle;

  /// No description provided for @shoppingFreeBadge.
  ///
  /// In fr, this message translates to:
  /// **'Gratuit · 1/1'**
  String get shoppingFreeBadge;

  /// No description provided for @shoppingDefaultListName.
  ///
  /// In fr, this message translates to:
  /// **'Liste de la semaine'**
  String get shoppingDefaultListName;

  /// No description provided for @shoppingCreateFromRecipes.
  ///
  /// In fr, this message translates to:
  /// **'Créer depuis mes recettes'**
  String get shoppingCreateFromRecipes;

  /// No description provided for @shoppingLockedSectionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Historique & listes multiples'**
  String get shoppingLockedSectionTitle;

  /// No description provided for @shoppingPremiumKicker.
  ///
  /// In fr, this message translates to:
  /// **'Cocotte Premium'**
  String get shoppingPremiumKicker;

  /// No description provided for @shoppingPremiumTitle.
  ///
  /// In fr, this message translates to:
  /// **'Listes illimitées + historique'**
  String get shoppingPremiumTitle;

  /// No description provided for @shoppingPremiumBody.
  ///
  /// In fr, this message translates to:
  /// **'Crée autant de listes que tu veux et retrouve toutes les précédentes.'**
  String get shoppingPremiumBody;

  /// No description provided for @shoppingPremiumCta.
  ///
  /// In fr, this message translates to:
  /// **'Débloquer Premium'**
  String get shoppingPremiumCta;

  /// No description provided for @shoppingEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune liste en cours'**
  String get shoppingEmptyTitle;

  /// No description provided for @shoppingEmptyBody.
  ///
  /// In fr, this message translates to:
  /// **'Génère ta liste de courses à partir de tes recettes.'**
  String get shoppingEmptyBody;

  /// No description provided for @shoppingLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger tes courses.'**
  String get shoppingLoadError;

  /// No description provided for @shoppingItemsCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun article} =1{1 article} other{{count} articles}}'**
  String shoppingItemsCount(int count);

  /// No description provided for @shoppingRecipesCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucune recette} =1{1 recette} other{{count} recettes}}'**
  String shoppingRecipesCount(int count);

  /// No description provided for @shoppingServingsCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 pers.} other{{count} pers.}}'**
  String shoppingServingsCount(int count);

  /// No description provided for @shoppingListSummary.
  ///
  /// In fr, this message translates to:
  /// **'{items} · {recipes} · {servings} pers.'**
  String shoppingListSummary(String items, String recipes, int servings);

  /// No description provided for @shoppingStepLabel.
  ///
  /// In fr, this message translates to:
  /// **'Étape {current} / {total}'**
  String shoppingStepLabel(int current, int total);

  /// No description provided for @shoppingStep1Title.
  ///
  /// In fr, this message translates to:
  /// **'Quelles recettes cuisines-tu ?'**
  String get shoppingStep1Title;

  /// No description provided for @shoppingStep1Subtitle.
  ///
  /// In fr, this message translates to:
  /// **'On assemblera la liste de courses à partir de ta sélection.'**
  String get shoppingStep1Subtitle;

  /// No description provided for @shoppingSearchRecipe.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher une recette'**
  String get shoppingSearchRecipe;

  /// No description provided for @shoppingContinue.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get shoppingContinue;

  /// No description provided for @shoppingContinueWithCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Continuer · 1 recette} other{Continuer · {count} recettes}}'**
  String shoppingContinueWithCount(int count);

  /// No description provided for @shoppingStep2Title.
  ///
  /// In fr, this message translates to:
  /// **'Pour combien de parts ?'**
  String get shoppingStep2Title;

  /// No description provided for @shoppingStep2Subtitle.
  ///
  /// In fr, this message translates to:
  /// **'On multiplie les ingrédients de chaque recette en conséquence.'**
  String get shoppingStep2Subtitle;

  /// No description provided for @shoppingBaseServings.
  ///
  /// In fr, this message translates to:
  /// **'Recette de base : {count} pers.'**
  String shoppingBaseServings(int count);

  /// No description provided for @shoppingTotalServings.
  ///
  /// In fr, this message translates to:
  /// **'Total : {parts} parts sur {recipes} recettes.'**
  String shoppingTotalServings(int parts, int recipes);

  /// No description provided for @shoppingStep3Title.
  ///
  /// In fr, this message translates to:
  /// **'Qu\'as-tu déjà chez toi ?'**
  String get shoppingStep3Title;

  /// No description provided for @shoppingStep3Subtitle.
  ///
  /// In fr, this message translates to:
  /// **'Coche les ingrédients que tu as déjà.'**
  String get shoppingStep3Subtitle;

  /// No description provided for @shoppingInStock.
  ///
  /// In fr, this message translates to:
  /// **'En stock'**
  String get shoppingInStock;

  /// No description provided for @shoppingGenerateWithCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Générer ma liste} =1{Générer ma liste · 1 article} other{Générer ma liste · {count} articles}}'**
  String shoppingGenerateWithCount(int count);

  /// No description provided for @shoppingNoRecipesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune recette'**
  String get shoppingNoRecipesTitle;

  /// No description provided for @shoppingNoRecipesBody.
  ///
  /// In fr, this message translates to:
  /// **'Crée d\'abord une recette pour générer une liste.'**
  String get shoppingNoRecipesBody;

  /// No description provided for @shoppingGenerateOfflineError.
  ///
  /// In fr, this message translates to:
  /// **'La génération d\'une liste nécessite une connexion.'**
  String get shoppingGenerateOfflineError;

  /// No description provided for @shoppingListEyebrow.
  ///
  /// In fr, this message translates to:
  /// **'Liste auto'**
  String get shoppingListEyebrow;

  /// No description provided for @shoppingViewByRecipe.
  ///
  /// In fr, this message translates to:
  /// **'Par recette'**
  String get shoppingViewByRecipe;

  /// No description provided for @shoppingViewByAisle.
  ///
  /// In fr, this message translates to:
  /// **'Par rayon'**
  String get shoppingViewByAisle;

  /// No description provided for @shoppingViewAz.
  ///
  /// In fr, this message translates to:
  /// **'A–Z'**
  String get shoppingViewAz;

  /// No description provided for @shoppingOtherItems.
  ///
  /// In fr, this message translates to:
  /// **'Autres articles'**
  String get shoppingOtherItems;

  /// No description provided for @shoppingOtherItemsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutés à la main · hors recette'**
  String get shoppingOtherItemsSubtitle;

  /// No description provided for @shoppingRecipeMeta.
  ///
  /// In fr, this message translates to:
  /// **'{servings} parts · {items}'**
  String shoppingRecipeMeta(int servings, String items);

  /// No description provided for @shoppingAddItem.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un article'**
  String get shoppingAddItem;

  /// No description provided for @shoppingAddItemTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouvel article'**
  String get shoppingAddItemTitle;

  /// No description provided for @shoppingAddItemHint.
  ///
  /// In fr, this message translates to:
  /// **'Nom de l\'article'**
  String get shoppingAddItemHint;

  /// No description provided for @shoppingAddItemQtyHint.
  ///
  /// In fr, this message translates to:
  /// **'Quantité (optionnel)'**
  String get shoppingAddItemQtyHint;

  /// No description provided for @shoppingAltAvailable.
  ///
  /// In fr, this message translates to:
  /// **'alt. dispo'**
  String get shoppingAltAvailable;

  /// No description provided for @shoppingRename.
  ///
  /// In fr, this message translates to:
  /// **'Renommer la liste'**
  String get shoppingRename;

  /// No description provided for @shoppingClear.
  ///
  /// In fr, this message translates to:
  /// **'Vider la liste'**
  String get shoppingClear;

  /// No description provided for @shoppingClearConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vider cette liste ?'**
  String get shoppingClearConfirmTitle;

  /// No description provided for @shoppingClearConfirmBody.
  ///
  /// In fr, this message translates to:
  /// **'La liste sera supprimée. En gratuit, l\'historique n\'est pas conservé.'**
  String get shoppingClearConfirmBody;

  /// No description provided for @shoppingShareList.
  ///
  /// In fr, this message translates to:
  /// **'Partager la liste'**
  String get shoppingShareList;

  /// No description provided for @shoppingClearChecked.
  ///
  /// In fr, this message translates to:
  /// **'Vider les cochés'**
  String get shoppingClearChecked;

  /// No description provided for @shoppingClearCheckedConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vider les articles cochés ?'**
  String get shoppingClearCheckedConfirmTitle;

  /// No description provided for @shoppingClearCheckedConfirmBody.
  ///
  /// In fr, this message translates to:
  /// **'Les articles déjà cochés seront retirés de la liste. Les autres sont conservés.'**
  String get shoppingClearCheckedConfirmBody;

  /// No description provided for @shoppingClearCheckedEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun article coché à retirer.'**
  String get shoppingClearCheckedEmpty;

  /// No description provided for @shoppingProgress.
  ///
  /// In fr, this message translates to:
  /// **'{checked}/{total}'**
  String shoppingProgress(int checked, int total);

  /// No description provided for @shoppingDetailSummary.
  ///
  /// In fr, this message translates to:
  /// **'{items} · {recipes} · {added} ajouts'**
  String shoppingDetailSummary(String items, String recipes, int added);

  /// No description provided for @shoppingExportTitle.
  ///
  /// In fr, this message translates to:
  /// **'Exporter'**
  String get shoppingExportTitle;

  /// No description provided for @shoppingExportSection.
  ///
  /// In fr, this message translates to:
  /// **'Exporter'**
  String get shoppingExportSection;

  /// No description provided for @shoppingExportPdf.
  ///
  /// In fr, this message translates to:
  /// **'Exporter en PDF'**
  String get shoppingExportPdf;

  /// No description provided for @shoppingExportPdfSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Liste prête à imprimer'**
  String get shoppingExportPdfSubtitle;

  /// No description provided for @shoppingExportNote.
  ///
  /// In fr, this message translates to:
  /// **'Convertir en note'**
  String get shoppingExportNote;

  /// No description provided for @shoppingExportNoteSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Copier la liste comme texte'**
  String get shoppingExportNoteSubtitle;

  /// No description provided for @shoppingExportHint.
  ///
  /// In fr, this message translates to:
  /// **'Les articles cochés (déjà en stock) n\'apparaissent pas dans l\'export.'**
  String get shoppingExportHint;

  /// No description provided for @shoppingExportCopied.
  ///
  /// In fr, this message translates to:
  /// **'Liste copiée dans le presse-papiers.'**
  String get shoppingExportCopied;

  /// No description provided for @shoppingExportPdfSoon.
  ///
  /// In fr, this message translates to:
  /// **'L\'export PDF arrive prochainement.'**
  String get shoppingExportPdfSoon;

  /// No description provided for @shoppingAltTitle.
  ///
  /// In fr, this message translates to:
  /// **'Introuvable en magasin ?'**
  String get shoppingAltTitle;

  /// No description provided for @shoppingAltSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Remplace {name} par une alternative. Ta recette n\'est pas modifiée.'**
  String shoppingAltSubtitle(String name);

  /// No description provided for @shoppingAltSection.
  ///
  /// In fr, this message translates to:
  /// **'Alternatives définies'**
  String get shoppingAltSection;

  /// No description provided for @shoppingAltNote.
  ///
  /// In fr, this message translates to:
  /// **'Le remplacement ne s\'applique qu\'à cette liste de courses.'**
  String get shoppingAltNote;

  /// No description provided for @shoppingAltConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Remplacer dans la liste'**
  String get shoppingAltConfirm;

  /// No description provided for @shoppingAltKeepOriginal.
  ///
  /// In fr, this message translates to:
  /// **'Garder l\'original'**
  String get shoppingAltKeepOriginal;

  /// No description provided for @shoppingAltReset.
  ///
  /// In fr, this message translates to:
  /// **'Revenir à l\'original'**
  String get shoppingAltReset;

  /// No description provided for @shoppingAltNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucune alternative définie pour cet ingrédient.'**
  String get shoppingAltNone;

  /// No description provided for @shoppingAltNoneHint.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute des alternatives depuis la fiche de l\'ingrédient.'**
  String get shoppingAltNoneHint;

  /// No description provided for @shoppingAltOffline.
  ///
  /// In fr, this message translates to:
  /// **'Connexion nécessaire pour charger les alternatives.'**
  String get shoppingAltOffline;

  /// No description provided for @shoppingPremiumBadge.
  ///
  /// In fr, this message translates to:
  /// **'Premium'**
  String get shoppingPremiumBadge;

  /// No description provided for @shoppingPremiumNewList.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle liste depuis mes recettes'**
  String get shoppingPremiumNewList;

  /// No description provided for @shoppingPremiumActiveLists.
  ///
  /// In fr, this message translates to:
  /// **'Listes actives'**
  String get shoppingPremiumActiveLists;

  /// No description provided for @shoppingPremiumUnlimited.
  ///
  /// In fr, this message translates to:
  /// **'Illimité'**
  String get shoppingPremiumUnlimited;

  /// No description provided for @shoppingPremiumHistory.
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get shoppingPremiumHistory;

  /// No description provided for @shoppingPremiumReopen.
  ///
  /// In fr, this message translates to:
  /// **'Rouvrir'**
  String get shoppingPremiumReopen;

  /// No description provided for @shoppingPremiumPreviewBanner.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu Premium — non actif en version gratuite.'**
  String get shoppingPremiumPreviewBanner;

  /// No description provided for @shoppingAisleFruitsLegumes.
  ///
  /// In fr, this message translates to:
  /// **'Fruits & légumes'**
  String get shoppingAisleFruitsLegumes;

  /// No description provided for @shoppingAisleFrais.
  ///
  /// In fr, this message translates to:
  /// **'Crémerie & frais'**
  String get shoppingAisleFrais;

  /// No description provided for @shoppingAisleViandesPoissons.
  ///
  /// In fr, this message translates to:
  /// **'Viandes & poissons'**
  String get shoppingAisleViandesPoissons;

  /// No description provided for @shoppingAisleEpicerieSalee.
  ///
  /// In fr, this message translates to:
  /// **'Épicerie salée'**
  String get shoppingAisleEpicerieSalee;

  /// No description provided for @shoppingAisleEpicerieSucree.
  ///
  /// In fr, this message translates to:
  /// **'Épicerie sucrée'**
  String get shoppingAisleEpicerieSucree;

  /// No description provided for @shoppingAisleBoulangerie.
  ///
  /// In fr, this message translates to:
  /// **'Boulangerie'**
  String get shoppingAisleBoulangerie;

  /// No description provided for @shoppingAisleBoissons.
  ///
  /// In fr, this message translates to:
  /// **'Boissons'**
  String get shoppingAisleBoissons;

  /// No description provided for @shoppingAisleSurgeles.
  ///
  /// In fr, this message translates to:
  /// **'Surgelés'**
  String get shoppingAisleSurgeles;

  /// No description provided for @shoppingAisleMaison.
  ///
  /// In fr, this message translates to:
  /// **'Maison & entretien'**
  String get shoppingAisleMaison;

  /// No description provided for @shoppingAisleAutres.
  ///
  /// In fr, this message translates to:
  /// **'Autres'**
  String get shoppingAisleAutres;

  /// No description provided for @playerModeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Mode cuisine'**
  String get playerModeLabel;

  /// No description provided for @playerReadyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Prêt à cuisiner ?'**
  String get playerReadyTitle;

  /// No description provided for @playerStepsBadge.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{0 étape} =1{1 étape} other{{count} étapes}}'**
  String playerStepsBadge(int count);

  /// No description provided for @playerSubRecipesBadge.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{0 sous-recette} =1{1 sous-recette} other{{count} sous-recettes}}'**
  String playerSubRecipesBadge(int count);

  /// No description provided for @playerTimersBadge.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{0 minuteur} =1{1 minuteur} other{{count} minuteurs}}'**
  String playerTimersBadge(int count);

  /// No description provided for @playerServingsQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Pour combien de personnes ?'**
  String get playerServingsQuestion;

  /// No description provided for @playerServingsHint.
  ///
  /// In fr, this message translates to:
  /// **'Recette prévue pour {base} — les quantités sont recalculées automatiquement.'**
  String playerServingsHint(int base);

  /// No description provided for @playerServingsUnit.
  ///
  /// In fr, this message translates to:
  /// **'personnes'**
  String get playerServingsUnit;

  /// No description provided for @playerStartCta.
  ///
  /// In fr, this message translates to:
  /// **'Commencer à cuisiner'**
  String get playerStartCta;

  /// No description provided for @playerWakelockNotice.
  ///
  /// In fr, this message translates to:
  /// **'L\'écran restera allumé pendant toute la cuisson.'**
  String get playerWakelockNotice;

  /// No description provided for @playerStepProgress.
  ///
  /// In fr, this message translates to:
  /// **'Étape {current} / {total}'**
  String playerStepProgress(int current, int total);

  /// No description provided for @playerNextStep.
  ///
  /// In fr, this message translates to:
  /// **'Étape suivante'**
  String get playerNextStep;

  /// No description provided for @playerNext.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get playerNext;

  /// No description provided for @playerAddTimerCta.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un minuteur'**
  String get playerAddTimerCta;

  /// No description provided for @playerNoTimerDetected.
  ///
  /// In fr, this message translates to:
  /// **'Aucun minuteur détecté sur cette étape'**
  String get playerNoTimerDetected;

  /// No description provided for @playerTimerDetectedHint.
  ///
  /// In fr, this message translates to:
  /// **'Minuteur détecté : « {text} »'**
  String playerTimerDetectedHint(String text);

  /// No description provided for @playerIngredientsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ingrédients de l\'étape'**
  String get playerIngredientsTitle;

  /// No description provided for @playerForServings.
  ///
  /// In fr, this message translates to:
  /// **'pour {count} pers.'**
  String playerForServings(int count);

  /// No description provided for @playerSubRecipeContext.
  ///
  /// In fr, this message translates to:
  /// **'Dans : {name}'**
  String playerSubRecipeContext(String name);

  /// No description provided for @playerSubRecipeBadge.
  ///
  /// In fr, this message translates to:
  /// **'SOUS-RECETTE · {index} / {total}'**
  String playerSubRecipeBadge(int index, int total);

  /// No description provided for @playerSubRecipeLabel.
  ///
  /// In fr, this message translates to:
  /// **'SOUS-RECETTE'**
  String get playerSubRecipeLabel;

  /// No description provided for @playerTimerLabel.
  ///
  /// In fr, this message translates to:
  /// **'Minuteur'**
  String get playerTimerLabel;

  /// No description provided for @playerTimerStart.
  ///
  /// In fr, this message translates to:
  /// **'Démarrer'**
  String get playerTimerStart;

  /// No description provided for @playerTimerReset.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser'**
  String get playerTimerReset;

  /// No description provided for @playerTimerDetectedAdjustable.
  ///
  /// In fr, this message translates to:
  /// **'Détecté dans l\'étape · ajustable'**
  String get playerTimerDetectedAdjustable;

  /// No description provided for @playerTimerSheetTitle.
  ///
  /// In fr, this message translates to:
  /// **'Régler le minuteur'**
  String get playerTimerSheetTitle;

  /// No description provided for @playerTimerSheetDetected.
  ///
  /// In fr, this message translates to:
  /// **'Détecté dans l\'étape : « {text} »'**
  String playerTimerSheetDetected(String text);

  /// No description provided for @playerTimerSheetCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get playerTimerSheetCancel;

  /// No description provided for @playerTimerSheetStart.
  ///
  /// In fr, this message translates to:
  /// **'Démarrer le minuteur'**
  String get playerTimerSheetStart;

  /// No description provided for @playerFinishTitle.
  ///
  /// In fr, this message translates to:
  /// **'C\'est prêt !'**
  String get playerFinishTitle;

  /// No description provided for @playerFinishSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'{name} · {steps, plural, =1{1 étape} other{{steps} étapes}} en {minutes} min. Bon appétit !'**
  String playerFinishSubtitle(String name, int steps, int minutes);

  /// No description provided for @playerFinishBackToRecipe.
  ///
  /// In fr, this message translates to:
  /// **'Revenir à la recette'**
  String get playerFinishBackToRecipe;

  /// No description provided for @playerFinishRedo.
  ///
  /// In fr, this message translates to:
  /// **'Refaire'**
  String get playerFinishRedo;

  /// No description provided for @playerResumeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre la cuisson ?'**
  String get playerResumeTitle;

  /// No description provided for @playerResumeBody.
  ///
  /// In fr, this message translates to:
  /// **'Tu t\'es arrêté à l\'étape {step} sur {total}, il y a {minutes} min.'**
  String playerResumeBody(int step, int total, int minutes);

  /// No description provided for @playerResumeRestart.
  ///
  /// In fr, this message translates to:
  /// **'Recommencer'**
  String get playerResumeRestart;

  /// No description provided for @playerResumeContinue.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre à l\'étape {step}'**
  String playerResumeContinue(int step);

  /// No description provided for @playerQuitTitle.
  ///
  /// In fr, this message translates to:
  /// **'Quitter le mode cuisine ?'**
  String get playerQuitTitle;

  /// No description provided for @playerQuitBody.
  ///
  /// In fr, this message translates to:
  /// **'Ta progression (étape {step} / {total}) sera enregistrée : tu pourras reprendre cette recette là où tu t\'es arrêté.'**
  String playerQuitBody(int step, int total);

  /// No description provided for @playerQuitContinue.
  ///
  /// In fr, this message translates to:
  /// **'Continuer la cuisson'**
  String get playerQuitContinue;

  /// No description provided for @playerQuitConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Quitter'**
  String get playerQuitConfirm;

  /// No description provided for @playerSwitchTitle.
  ///
  /// In fr, this message translates to:
  /// **'Une autre recette est en cours'**
  String get playerSwitchTitle;

  /// No description provided for @playerSwitchBody.
  ///
  /// In fr, this message translates to:
  /// **'{name}, étape {step} — la quitter et commencer celle-ci ?'**
  String playerSwitchBody(String name, int step);

  /// No description provided for @playerSwitchCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get playerSwitchCancel;

  /// No description provided for @playerSwitchConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get playerSwitchConfirm;

  /// No description provided for @playerSummaryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les étapes'**
  String get playerSummaryTitle;

  /// No description provided for @playerSummaryHint.
  ///
  /// In fr, this message translates to:
  /// **'appuie pour sauter'**
  String get playerSummaryHint;

  /// No description provided for @playerResumeStepCta.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre l\'étape {step}'**
  String playerResumeStepCta(int step);

  /// No description provided for @playerProgressLabel.
  ///
  /// In fr, this message translates to:
  /// **'Progression'**
  String get playerProgressLabel;

  /// Tooltip du bouton qui lance le mode pas-à-pas depuis la fiche recette
  ///
  /// In fr, this message translates to:
  /// **'Cuisiner cette recette'**
  String get recipePlayCta;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer mon compte'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountGuestHeading.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer définitivement ce compte invité ?'**
  String get deleteAccountGuestHeading;

  /// No description provided for @deleteAccountGuestBody.
  ///
  /// In fr, this message translates to:
  /// **'Toutes tes données (recettes, ingrédients, tags, personnes, listes) seront supprimées définitivement et immédiatement. Cette action est irréversible. Un nouveau compte invité vierge sera créé.'**
  String get deleteAccountGuestBody;

  /// No description provided for @deleteAccountFullHeading.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer mon compte ?'**
  String get deleteAccountFullHeading;

  /// No description provided for @deleteAccountFullBody.
  ///
  /// In fr, this message translates to:
  /// **'Ton compte est immédiatement anonymisé, puis définitivement supprimé après un délai de 30 jours. Pendant ce délai, tu peux annuler la suppression et récupérer ton compte en te reconnectant. Tu vas être déconnecté(e).'**
  String get deleteAccountFullBody;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer mon compte'**
  String get deleteAccountConfirm;

  /// No description provided for @deleteAccountCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get deleteAccountCancel;

  /// No description provided for @deleteAccountGuestDone.
  ///
  /// In fr, this message translates to:
  /// **'Ton compte a été supprimé. Nouveau compte invité créé.'**
  String get deleteAccountGuestDone;

  /// No description provided for @deleteAccountPendingDone.
  ///
  /// In fr, this message translates to:
  /// **'Suppression enregistrée. Tu as 30 jours pour l\'annuler en te reconnectant.'**
  String get deleteAccountPendingDone;

  /// No description provided for @cancelDeletionBannerTitle.
  ///
  /// In fr, this message translates to:
  /// **'Suppression de compte en attente'**
  String get cancelDeletionBannerTitle;

  /// No description provided for @cancelDeletionBannerBody.
  ///
  /// In fr, this message translates to:
  /// **'Ton compte sera définitivement supprimé à la fin du délai de 30 jours. Tu peux encore l\'annuler.'**
  String get cancelDeletionBannerBody;

  /// No description provided for @cancelDeletionBannerCta.
  ///
  /// In fr, this message translates to:
  /// **'Annuler la suppression'**
  String get cancelDeletionBannerCta;

  /// No description provided for @cancelDeletionSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Suppression annulée. Ton compte est de nouveau actif.'**
  String get cancelDeletionSuccess;

  /// No description provided for @guestReminderDialogDismiss.
  ///
  /// In fr, this message translates to:
  /// **'Plus tard'**
  String get guestReminderDialogDismiss;

  /// No description provided for @searchHint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher…'**
  String get searchHint;

  /// No description provided for @searchTriggerFolder.
  ///
  /// In fr, this message translates to:
  /// **'Dossier'**
  String get searchTriggerFolder;

  /// No description provided for @searchTriggerTag.
  ///
  /// In fr, this message translates to:
  /// **'Tag'**
  String get searchTriggerTag;

  /// No description provided for @searchTriggerPerson.
  ///
  /// In fr, this message translates to:
  /// **'Personne'**
  String get searchTriggerPerson;

  /// No description provided for @searchSectionFolders.
  ///
  /// In fr, this message translates to:
  /// **'Dossiers'**
  String get searchSectionFolders;

  /// No description provided for @searchSectionTags.
  ///
  /// In fr, this message translates to:
  /// **'Tags'**
  String get searchSectionTags;

  /// No description provided for @searchSectionPeople.
  ///
  /// In fr, this message translates to:
  /// **'Famille'**
  String get searchSectionPeople;

  /// No description provided for @searchCreateTag.
  ///
  /// In fr, this message translates to:
  /// **'Créer le tag « {name} »'**
  String searchCreateTag(String name);

  /// No description provided for @searchManageFamily.
  ///
  /// In fr, this message translates to:
  /// **'Gérer les membres de la famille'**
  String get searchManageFamily;

  /// No description provided for @searchClearAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout effacer'**
  String get searchClearAll;

  /// No description provided for @searchResultsCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 résultat} other{{count} résultats}}'**
  String searchResultsCount(int count);

  /// No description provided for @searchFolderRecipes.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucune recette} =1{1 recette} other{{count} recettes}}'**
  String searchFolderRecipes(int count);

  /// No description provided for @searchFolderSubfolders.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 sous-dossier} other{{count} sous-dossiers}}'**
  String searchFolderSubfolders(int count);

  /// No description provided for @searchMinutesShort.
  ///
  /// In fr, this message translates to:
  /// **'{min} min'**
  String searchMinutesShort(int min);

  /// No description provided for @searchEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune recette'**
  String get searchEmptyTitle;

  /// No description provided for @searchNoSuggestion.
  ///
  /// In fr, this message translates to:
  /// **'Aucune proposition'**
  String get searchNoSuggestion;

  /// No description provided for @searchIdleHint.
  ///
  /// In fr, this message translates to:
  /// **'Tape « / » pour un dossier, « # » pour un tag, « @ » pour une personne.'**
  String get searchIdleHint;

  /// No description provided for @accountSectionApp.
  ///
  /// In fr, this message translates to:
  /// **'Application'**
  String get accountSectionApp;

  /// No description provided for @accountRowLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get accountRowLanguage;

  /// No description provided for @languageTitle.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get languageTitle;

  /// No description provided for @languageIntro.
  ///
  /// In fr, this message translates to:
  /// **'Choisis la langue de l\'application.'**
  String get languageIntro;

  /// No description provided for @languageSystem.
  ///
  /// In fr, this message translates to:
  /// **'Système (automatique)'**
  String get languageSystem;

  /// No description provided for @languageSystemSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Suit la langue de ton téléphone'**
  String get languageSystemSubtitle;

  /// No description provided for @languageFrench.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get languageFrench;

  /// No description provided for @languageEnglish.
  ///
  /// In fr, this message translates to:
  /// **'English'**
  String get languageEnglish;
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
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
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
