import 'package:flutter/material.dart';

import 'app.dart';
import 'core/config/env.dart';
import 'core/di/service_locator.dart';
import 'core/notifications/local_notifications_service.dart';
import 'core/supabase/supabase_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  setupServiceLocator();
  await LocalNotificationsService.instance.init();

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

  runApp(const CocotteApp());
}
