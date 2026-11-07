/// Local notification delivery — makes NotificationPrefs real.
/// Schedules device-local reminders for pantry expiry, open votes,
/// shopping trips and meal prep, honoring quiet hours and the master
/// push switch. No server or push token involved; Android only.
library;

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'catalog.dart' as catalog;
import 'models.dart';
import 'store.dart';

/// FCM background isolate entry point — notification messages are posted to
/// the system tray by the plugin automatically; data-only messages are
/// acknowledged here for future handling.
@pragma('vm:entry-point')
Future<void> fcmBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
}

class NotificationService {
  NotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;
  static FirebaseMessaging? _messaging;

  /// Latest FCM registration token, if Firebase initialized.
  static String? pushToken;

  static const _channelId = 'kinplora_reminders';
  static const _pushChannelId = 'kinplora_push';

  /// Call once at startup (main). Safe on non-Android platforms.
  static Future<void> init() async {
    if (_ready || kIsWeb) return;
    tzdata.initializeTimeZones();
    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      await _plugin.initialize(const InitializationSettings(android: android));
      _ready = true;
    } catch (_) {}
    _initPush();
  }

  /// Wires Firebase Cloud Messaging: foreground messages are re-posted as
  /// local notifications; the registration token is fetched so it can be
  /// registered server-side in [sync].
  static void _initPush() {
    if (kIsWeb || !defaultTargetPlatformIsAndroid()) return;
    try {
      if (Firebase.apps.isEmpty) return;
      _messaging = FirebaseMessaging.instance;
      FirebaseMessaging.onMessage.listen(_showForegroundMessage);
      unawaited(_registerForPush());
    } catch (_) {}
  }

  static bool defaultTargetPlatformIsAndroid() {
    try {
      return defaultTargetPlatform == TargetPlatform.android;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _registerForPush() async {
    try {
      final messaging = _messaging;
      if (messaging == null) return;
      messaging.onRegistered.listen((token) => pushToken = token);
      await messaging.requestPermission();
      await messaging.register();
    } catch (_) {}
  }

  static Future<void> _showForegroundMessage(RemoteMessage message) async {
    if (!_ready) return;
    final n = message.notification;
    final title = n?.title ?? message.data['title'] as String? ?? 'Kinplora';
    final body = n?.body ?? message.data['body'] as String? ?? '';
    try {
      await _plugin.show(
        message.hashCode,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _pushChannelId,
            'Updates',
            channelDescription: 'Family updates and reminders',
            importance: Importance.high,
          ),
        ),
      );
    } catch (_) {}
  }

  static Future<bool> _permissionGranted() async {
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await android?.areNotificationsEnabled() ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _ensurePermission() async {
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await android?.requestNotificationsPermission();
    } catch (_) {}
  }

  /// Rebuilds the whole schedule from current store state. Cheap enough to
  /// run on every state change — pending notifications are replaced, never
  /// duplicated.
  static Future<void> sync(AppStore store) async {
    if (!_ready || kIsWeb) return;
    final prefs = store.notifPrefs;
    try {
      await _registerPushToken(store);
      await _plugin.cancelAll();
      if (!prefs.pushEnabled || !store.isSignedIn) return;
      if (!await _permissionGranted()) {
        await _ensurePermission();
        if (!await _permissionGranted()) return;
      }
      var id = 0;
      void schedule(DateTime at, String title, String body) {
        final local = _outsideQuiet(at, prefs);
        if (local.isBefore(DateTime.now())) return;
        unawaited(
          _plugin.zonedSchedule(
            id++,
            title,
            body,
            tz.TZDateTime.from(local, tz.local),
            const NotificationDetails(
              android: AndroidNotificationDetails(
                _channelId,
                'Reminders',
                channelDescription: 'Meal planning reminders',
                importance: Importance.defaultImportance,
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          ),
        );
      }

      // Pantry items expiring within 3 days -> heads-up the day before,
      // at 9am local.
      if (prefs.pantryExpiry) {
        final now = DateTime.now();
        for (final item in store.pantry) {
          final exp = item.expiresAt;
          if (exp == null || !item.confirmed) continue;
          final daysLeft = exp.difference(now).inDays;
          if (daysLeft < 0 || daysLeft > 3) continue;
          final name =
              catalog.ingredients[item.ingredientId]?.name ?? item.ingredientId;
          schedule(
            DateTime(exp.year, exp.month, exp.day, 9),
            daysLeft == 0
                ? '$name expires today'
                : '$name expires in $daysLeft day${daysLeft == 1 ? '' : 's'}',
            'Check your pantry and plan a meal that uses it.',
          );
        }
      }

      // Open vote rounds -> reminder when they close.
      if (prefs.voteReminders) {
        for (final v in store.voteRounds) {
          if (v.status != VoteRoundStatus.open) continue;
          if (v.closesAt.difference(DateTime.now()).inHours > 48) continue;
          schedule(
            v.closesAt,
            'Vote closing soon: ${v.title}',
            'Cast your pick before the round closes.',
          );
        }
      }

      // Shopping trip -> next scheduled shop day.
      if (prefs.tripReminders) {
        final unchecked = store.groceryList.where((g) => !g.checked).length;
        if (unchecked > 0) {
          schedule(
            DateTime.now().add(
              Duration(days: store.shoppingIntervalDays.clamp(1, 30)),
            ),
            'Shopping day is coming',
            '$unchecked item${unchecked == 1 ? '' : 's'} on the grocery list.',
          );
        }
      }

      // Meal prep -> tonight's dinner if a plan is approved.
      if (prefs.mealPrep && store.plan?.status == PlanStatus.approved) {
        final today = DateTime.now().weekday - 1;
        final slot = store.plan!.slots
            .where((s) => s.day == today && s.meal == MealType.dinner)
            .firstOrNull;
        final recipe = slot == null
            ? null
            : catalog.recipes[slot.recipeId]?.title;
        if (recipe != null) {
          final at = DateTime.now().add(const Duration(hours: 3));
          schedule(at, 'Dinner tonight: $recipe', 'From this week\'s plan.');
        }
      }
    } catch (_) {}
  }

  /// Sends a real FCM push to this account's registered devices via the
  /// `send-push` edge function. Returns true if the function accepted it.
  /// No-op (false) when Supabase or sign-in is unavailable.
  static Future<bool> sendPush(
    String title,
    String body, {
    Map<String, String> data = const {},
  }) async {
    if (kIsWeb || !Supabase.instance.isInitialized) return false;
    final client = Supabase.instance.client;
    if (client.auth.currentUser == null) return false;
    try {
      await client.functions.invoke(
        'send-push',
        body: {'title': title, 'body': body, 'data': data},
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Upserts the FCM token into `push_tokens` so a server-side sender can
  /// reach this device. No-op when signed out, offline of Supabase, or
  /// Firebase is unavailable.
  static Future<void> _registerPushToken(AppStore store) async {
    final token = pushToken;
    final uid = store.supabaseUserId;
    if (token == null || token.isEmpty || uid == null) return;
    if (!Supabase.instance.isInitialized) return;
    try {
      await Supabase.instance.client.from('push_tokens').upsert({
        'user_id': uid,
        'token': token,
        'platform': 'android',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {}
  }

  /// Shifts a notification out of quiet hours (defaults 21:00-08:00).
  static DateTime _outsideQuiet(DateTime at, NotificationPrefs prefs) {
    final hour = at.hour;
    final inQuiet = prefs.quietStartHour > prefs.quietEndHour
        ? hour >= prefs.quietStartHour || hour < prefs.quietEndHour
        : hour >= prefs.quietStartHour && hour < prefs.quietEndHour;
    if (!inQuiet) return at;
    // Move to the end of quiet hours on the same day.
    return DateTime(
      at.year,
      at.month,
      at.day,
      prefs.quietEndHour,
    ).add(const Duration(days: 1));
  }
}
