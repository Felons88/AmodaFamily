import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/family_circle_app.dart';
import 'shared/notifications.dart';
import 'shared/store.dart';

const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase/FCM is Android-only in this build; failure is non-fatal.
  try {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(fcmBackgroundHandler);
    }
  } catch (_) {}
  await NotificationService.init();
  if (_supabaseUrl.isNotEmpty && _supabaseAnonKey.isNotEmpty) {
    try {
      await Supabase.initialize(
        url: _supabaseUrl,
        publishableKey: _supabaseAnonKey,
      );
      // Sync real Supabase auth sessions into the app store.
      Supabase.instance.client.auth.onAuthStateChange.listen((state) {
        AppStore.instanceFromAuth?.syncSupabaseSession(state.session);
      });
    } catch (_) {}
  }
  runApp(const ProviderScope(child: FamilyCircleApp()));
}
