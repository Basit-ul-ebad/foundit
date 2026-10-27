import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/firebase_storage_impl.dart';
import 'data/local_storage.dart';
import 'data/seed.dart';
import 'data/store.dart';
import 'firebase_options.dart';
import 'screens/onboarding.dart';
import 'screens/shell.dart';
import 'theme.dart';
import 'widgets.dart';

/// Connects to Firebase when the build has its settings, otherwise uses
/// phone-only storage so the app still works end to end.
Future<AppStore> bootstrap() async {
  final options = firebaseOptions;
  if (options != null) {
    try {
      await Firebase.initializeApp(options: options);
      final store = AppStore(FirebaseAuthService(), FirestoreStorage(),
          localMode: false);
      await store.init();
      return store;
    } catch (_) {
      // Fall through to local mode if Firebase cannot start.
    }
  }
  final local = await LocalStorage.open();
  if (local.isEmpty) await seedLocalData(local);
  final prefs = await SharedPreferences.getInstance();
  final store = AppStore(LocalAuth(prefs), local, localMode: true);
  await store.init();
  return store;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(FounditApp(store: await bootstrap()));
}

class FounditApp extends StatelessWidget {
  const FounditApp({super.key, required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      store: store,
      child: MaterialApp(
        title: 'Foundit',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        home: store.signedIn ? const AppShell() : const OnboardingScreen(),
      ),
    );
  }
}
