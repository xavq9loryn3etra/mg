import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_provider.dart';

final audioPlayerProvider = Provider<AudioPlayer>((ref) {
  final player = AudioPlayer();
  ref.onDispose(() => player.dispose());
  return player;
});

final isMutedProvider = StateNotifierProvider<MuteNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return MuteNotifier(prefs);
});

class MuteNotifier extends StateNotifier<bool> {
  final SharedPreferences _prefs;
  MuteNotifier(this._prefs) : super(_prefs.getBool('isMuted') ?? false);

  void toggle() {
    state = !state;
    _prefs.setBool('isMuted', state);
  }
}

final soundServiceProvider = Provider<SoundService>((ref) {
  final service = SoundService(ref);
  
  // High-performance listener: Automatically triggers a fade whenever the mute state changes
  ref.listen(isMutedProvider, (previous, next) {
    service.updateVolume(fade: true);
  });
  
  return service;
});

class SoundService {
  final Ref _ref;
  Timer? _fadeTimer;
  
  SoundService(this._ref);

  AudioPlayer get _player => _ref.read(audioPlayerProvider);

  Future<void> playAmbient() async {
    // If we're muted, we don't even start playing to save resources
    if (_ref.read(isMutedProvider)) {
      await _player.stop();
      return;
    }
    
    try {
      await _player.setAsset('assets/intro-audio.mp3');
      await _player.setLoopMode(LoopMode.all);
      
      // Initially sync volume instantly without fade for the very first play
      updateVolume(fade: false); 
      
      _player.play();
    } catch (e) {
      debugPrint("Gapless Audio Playback Error: $e");
    }
  }

  /// Updates the volume, optionally with a smooth fade in/out effect.
  Future<void> updateVolume({bool fade = true}) async {
    final isMuted = _ref.read(isMutedProvider);
    final targetVolume = isMuted ? 0.0 : 0.6;
    
    if (!fade) {
      _cancelCurrentFade();
      _player.setVolume(targetVolume);
      return;
    }

    await _fadeTo(targetVolume);
  }

  void _cancelCurrentFade() {
    _fadeTimer?.cancel();
    _fadeTimer = null;
  }

  Future<void> _fadeTo(double target) async {
    _cancelCurrentFade();
    
    const duration = Duration(milliseconds: 1000);
    const steps = 20;
    final stepDuration = Duration(milliseconds: duration.inMilliseconds ~/ steps);
    
    final startVolume = _player.volume;
    final volumeDelta = (target - startVolume) / steps;
    
    int currentStep = 0;
    
    _fadeTimer = Timer.periodic(stepDuration, (timer) {
      currentStep++;
      final newVolume = (startVolume + (volumeDelta * currentStep)).clamp(0.0, 1.0);
      _player.setVolume(newVolume);
      
      if (currentStep >= steps) {
        _player.setVolume(target); // Ensure we hit the exact target
        _cancelCurrentFade();
      }
    });
  }

  void stop() {
    _cancelCurrentFade();
    _player.stop();
  }
}
