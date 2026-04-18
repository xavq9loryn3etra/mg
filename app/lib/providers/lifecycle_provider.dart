import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'audio_provider.dart';
import '../router.dart';

final appLifecycleProvider = Provider((ref) {
  final observer = _AppLifecycleObserver(ref);
  WidgetsBinding.instance.addObserver(observer);
  ref.onDispose(() => WidgetsBinding.instance.removeObserver(observer));
  return observer;
});

class _AppLifecycleObserver extends WidgetsBindingObserver {
  final Ref _ref;
  _AppLifecycleObserver(this._ref);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint("App Lifecycle State: $state");
    
    final soundService = _ref.read(soundServiceProvider);
    
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // App minimized: Stop audio
      soundService.stop();
    } else if (state == AppLifecycleState.resumed) {
      // App returned: Resume audio ONLY if on a music-appropriate screen
      // We check the router's current location to be safe
      try {
        final router = _ref.read(routerProvider);
        final location = router.state.uri.path;
        
        // Music only on Splash (/) or Home (/) - EntranceWrapper handles both
        if (location == '/' || location == '/tutorial') {
           soundService.playAmbient();
        }
      } catch (e) {
        // Fallback: If we can't determine route, we favor silence to be safe
      }
    }
  }
}
