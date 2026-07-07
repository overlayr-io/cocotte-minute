import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Notifications locales (pas de push), utilisées pour signaler la fin d'un
/// minuteur du mode pas-à-pas — fonctionne même si l'app est en
/// arrière-plan, sans aucun appel serveur (cf. `docs/features/step-by-step.md`).
class LocalNotificationsService {
  LocalNotificationsService._();

  static final LocalNotificationsService instance = LocalNotificationsService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _permissionRequested = false;

  static const _channelId = 'recipe_player_timers';
  static const _channelName = 'Minuteurs de cuisine';
  static const _channelDescription =
      'Notifications de fin de minuteur pendant le mode pas-à-pas.';

  /// Enregistre les canaux de notification. À appeler une fois au démarrage
  /// de l'app (`main.dart`). Ne demande PAS la permission — celle-ci est
  /// demandée plus tard, contextuellement, au premier minuteur démarré
  /// (cf. [requestPermissionIfNeeded]).
  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
    _initialized = true;
  }

  /// Demande la permission de notifications si ce n'est pas déjà fait.
  /// Appelée lazily au premier minuteur démarré, pas au démarrage de l'app.
  Future<void> requestPermissionIfNeeded() async {
    if (_permissionRequested) return;
    _permissionRequested = true;
    if (Platform.isIOS || Platform.isMacOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } else if (Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
      await android?.requestExactAlarmsPermission();
    }
  }

  /// Programme une notification à [fireAt]. [id] doit être stable pour
  /// permettre l'annulation via [cancel] (dérivé de l'id du `RecipeTimer`).
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime fireAt,
  }) async {
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(fireAt, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancel(int id) => _plugin.cancel(id: id);
}
