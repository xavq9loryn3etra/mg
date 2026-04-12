import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mafia_app/firebase_options.dart';
import 'theme.dart';
import 'router.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Edge-to-edge rendering
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

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

  runApp(
    ProviderScope(
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
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'MAFIA GO',
      theme: AppTheme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
