import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A provider that holds the initialized SharedPreferences instance.
/// This MUST be overridden in ProviderScope before the app runs.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

/// A state provider that manages whether the tutorial has been seen.
final tutorialSeenProvider = StateProvider<bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getBool('has_seen_tutorial') ?? false;
});

/// A convenient way to mark the tutorial as seen.
final setTutorialSeenProvider = Provider((ref) {
  return () async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('has_seen_tutorial', true);
    ref.read(tutorialSeenProvider.notifier).state = true;
  };
});

/// Tracks if the cinematic splash sequnce has been completed during this session.
final hasFinishedSplashProvider = StateProvider<bool>((ref) => false);
