// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Cocotte Minute';

  @override
  String get commonRetry => 'Réessayer';

  @override
  String get commonError => 'Une erreur est survenue';

  @override
  String get homeWelcome => 'Bienvenue dans Cocotte Minute';

  @override
  String get homeCreateAccountCta => 'Créer un compte / Se connecter';

  @override
  String get authCreateTitle => 'Crée ton compte';

  @override
  String get authCreateSubtitle =>
      'Retrouve tes recettes sur tous tes appareils.';

  @override
  String get authSignInTitle => 'Content de te revoir';

  @override
  String get authSignInSubtitle => 'Connecte-toi pour retrouver tes recettes.';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authEmailHint => 'ton@email.com';

  @override
  String get authPasswordLabel => 'Mot de passe';

  @override
  String get authPasswordHint => 'Ton mot de passe';

  @override
  String get authCreateAction => 'Créer mon compte';

  @override
  String get authSignInAction => 'Se connecter';

  @override
  String get authDividerOr => 'ou';

  @override
  String get authContinueGoogle => 'Continuer avec Google';

  @override
  String get authContinueApple => 'Continuer avec Apple';

  @override
  String get authAlreadyHaveAccount => 'Déjà un compte ?';

  @override
  String get authNoAccountYet => 'Pas encore de compte ?';

  @override
  String get authSwitchToSignIn => 'Se connecter';

  @override
  String get authSwitchToCreate => 'Créer un compte';

  @override
  String get authEmailInvalid => 'Entre une adresse email valide.';

  @override
  String get authPasswordTooShort => '6 caractères minimum.';

  @override
  String get authLegalPrefix => 'En continuant, tu acceptes nos ';

  @override
  String get authLegalTerms => 'Conditions d\'utilisation';

  @override
  String get authLegalAnd => ' et notre ';

  @override
  String get authLegalPrivacy => 'Politique de confidentialité';

  @override
  String get authLegalSuffix => '.';

  @override
  String get keepDataTitle => 'Compte créé !';

  @override
  String get keepDataDescription =>
      'Tes recettes créées en tant qu\'invité sont prêtes. Que veux-tu en faire ?';

  @override
  String get keepDataKeepTitle => 'Conserver mes recettes';

  @override
  String get keepDataKeepSubtitle => 'Tout reste lié à ce compte';

  @override
  String get keepDataRecommended => 'Conseillé';

  @override
  String get keepDataResetTitle => 'Repartir de zéro';

  @override
  String get keepDataResetSubtitle => 'Efface les données invité';

  @override
  String get keepDataConfirm => 'Continuer';

  @override
  String get keepDataLater => 'Plus tard';
}
