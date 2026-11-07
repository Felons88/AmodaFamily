import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/family_circle_app.dart';
import 'shared/store.dart';

const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
