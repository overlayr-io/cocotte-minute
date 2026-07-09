import 'dart:async';

import 'package:flutter/material.dart';

import 'app.dart';
import 'core/config/env.dart';
import 'core/di/service_locator.dart';
import 'core/notifications/local_notifications_service.dart';
import 'core/premium/premium_repository.dart';
import 'core/supabase/supabase_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  setupServiceLocator();

  // Supabase n'est initialisé que si les clés sont fournies via --dart-define,
  // pour éviter un crash au tout premier lancement sans configuration.
  if (Env.isConfigured) {
    await SupabaseService.init();
  } else {
    debugPrint(
      'SUPABASE_URL / SUPABASE_ANON_KEY manquants : '
      'lancez avec --dart-define pour activer l\'auth.',
    );
  }

  // RevenueCat (premium) : configuré SANS appUserID (anonyme), le logIn/logOut
  // est synchronisé par le PremiumCubit sur l'AuthBloc. Un échec ne doit
  // jamais bloquer le démarrage — l'app reste simplement « non premium ».
  try {
    await sl<PremiumRepository>().configure();
  } catch (e) {
    debugPrint('RevenueCat non configuré : $e');
  }

  runApp(const CocotteApp());

  // Init non bloquante APRÈS runApp (timezone incluse) : ne retarde plus le
  // premier frame. Aucune notification n'est programmée avant d'entrer dans
  // le lecteur de recette, bien après la fin de cette init.
  unawaited(LocalNotificationsService.instance.init());
}
