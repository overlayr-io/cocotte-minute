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
  /// **'Retrouve tes recettes sur tous tes appareils. C\'est optionnel — tu peux continuer sans compte.'**
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
