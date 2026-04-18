import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_purple_town/firebase_options.dart';
import 'theme.dart';
import 'router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'providers/app_provider.dart';
import 'providers/lifecycle_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Hide system UI (FullScreen / Immersive Sticky)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  bool firebaseInitialized = false;
  String errorMsg = '';
  try {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } on FirebaseException catch (e) {
      // Already initialized (e.g. from google-services.json) — that's fine
      if (e.code != 'duplicate-app') rethrow;
    }
    await FirebaseAuth.instance.signInAnonymously();
    firebaseInitialized = true;
  } catch (e) {
    errorMsg = e.toString();
    debugPrint("Firebase init failed: $e");
  }

  final sharedPrefs = await SharedPreferences.getInstance();

  // App Update Cache Clearing Logic
  final packageInfo = await PackageInfo.fromPlatform();
  final String currentVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
  final String? savedVersion = sharedPrefs.getString('app_build_version');

  if (savedVersion != currentVersion) {
    debugPrint("App updated from $savedVersion to $currentVersion. Clearing caches...");
    
    // 1. Read the settings we want to keep
    final bool? isMuted = sharedPrefs.getBool('isMuted');
    final bool? hasSeenTutorial = sharedPrefs.getBool('has_seen_tutorial');
    
    // 2. Clear old cached data
    await sharedPrefs.clear();
    
    // 3. Restore the important settings
    if (isMuted != null) await sharedPrefs.setBool('isMuted', isMuted);
    if (hasSeenTutorial != null) await sharedPrefs.setBool('has_seen_tutorial', hasSeenTutorial);
    
    // 4. Save the new version
    await sharedPrefs.setString('app_build_version', currentVersion);
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPrefs),
      ],
      child: firebaseInitialized
          ? const MafiaApp()
          : FirebaseErrorApp(error: errorMsg),
    ),
  );
}

class FirebaseErrorApp extends StatelessWidget {
  final String error;
  const FirebaseErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 16),
                const Text(
                  'Firebase Configuration Missing',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "You must create a Firebase project and link it to this Flutter app.",
                  style: TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  "Run 'flutterfire configure' in the app directory, then update main.dart to use DefaultFirebaseOptions.currentPlatform.",
                  style: TextStyle(color: Colors.orange),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Text(
                  error,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MafiaApp extends ConsumerWidget {
  const MafiaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize global app observers
    ref.watch(appLifecycleProvider);
    
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Mafia: Purple Town',
      theme: AppTheme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
