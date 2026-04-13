import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'home_screen.dart';
import 'tutorial_screen.dart';
import '../services/game_service.dart';
import '../providers/room_provider.dart';
import '../providers/audio_provider.dart';
import '../providers/app_provider.dart';
import '../theme.dart';

class EntranceWrapper extends ConsumerStatefulWidget {
  const EntranceWrapper({super.key});

  @override
  ConsumerState<EntranceWrapper> createState() => _EntranceWrapperState();
}

class _EntranceWrapperState extends ConsumerState<EntranceWrapper> with TickerProviderStateMixin {
  late AnimationController _phase1Controller;
  late AnimationController _phase2Controller;
  
  late Animation<double> _phase1Opacity;
  late Animation<double> _phase1Scale;
  
  late Animation<double> _phase2Opacity;
  late Animation<double> _phase2Scale;

  final _gameService = GameService();
  Future<String?>? _sessionCheckFuture;
  
  bool _showLogos = true;
  bool _isTransitioning = false;

  @override
  void initState() {
    super.initState();
    
    // Check if splash has already played in this session
    final hasFinishedSplash = ref.read(hasFinishedSplashProvider);
    if (hasFinishedSplash) {
      _showLogos = false;
      _isTransitioning = false;
    }

    _sessionCheckFuture = _gameService.checkActiveSession();

    // Phase 1: Company Logo (800 / 1000 / 600)
    _phase1Controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));
    _phase1Opacity = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 800),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 1000),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 600),
    ]).animate(_phase1Controller);
    _phase1Scale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 800),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 1600),
    ]).animate(_phase1Controller);

    // Phase 2: Game Logo
    _phase2Controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));
    _phase2Opacity = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 800),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 1000),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 600),
    ]).animate(_phase2Controller);
    _phase2Scale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 800),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 1600),
    ]).animate(_phase2Controller);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (!hasFinishedSplash) {
          ref.read(soundServiceProvider).playAmbient();
          _runSequence();
        } else {
          // Even if we skip the splash, we are now on Home/Tutorial, so play music
          ref.read(soundServiceProvider).playAmbient();
        }
      }
    });
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      // Execute Splash sequence
      await _phase1Controller.forward();
      
      // Phase 2 Hold logic
      await _phase2Controller.animateTo(0.75);
      final activeRoomCode = await _sessionCheckFuture;
      
      // If we found a session, don't even show the Home fade—just jump to lobby
      if (activeRoomCode != null && mounted) {
        ref.read(currentRoomCodeProvider.notifier).setCode(activeRoomCode);
        ref.read(hasFinishedSplashProvider.notifier).state = true;
        context.go('/lobby/$activeRoomCode');
        return;
      }

      // No session: Finish logo fade and then reveal Home seamlessly
      await _phase2Controller.forward();
      
      if (mounted) {
        setState(() {
          _isTransitioning = true;
          _showLogos = false;
        });
        // Mark as finished for next time we visit "/" in this session
        ref.read(hasFinishedSplashProvider.notifier).state = true;
      }
    }
  }

  @override
  void dispose() {
    _phase1Controller.dispose();
    _phase2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch for tutorial state changes
    final hasSeenTutorial = ref.watch(tutorialSeenProvider);
    final nextView = hasSeenTutorial ? const HomeScreen() : const TutorialScreen();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // LAYER 1: THE HOME SCREEN (Sits at the bottom)
          IgnorePointer(
            ignoring: _showLogos,
            child: AnimatedOpacity(
              opacity: _showLogos ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOut,
              child: nextView,
            ),
          ),

          // LAYER 2: THE LOGO OVERLAYS (Sits on top and dissolves)
          IgnorePointer(
            ignoring: !_showLogos,
            child: AnimatedOpacity(
              opacity: _showLogos ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOut,
              onEnd: () {
                if (!_showLogos) {
                  setState(() => _isTransitioning = false);
                }
              },
              child: Container(
                decoration: AppTheme.bgGradient,
                child: Stack(
                  children: [
                    Center(
                      child: FadeTransition(
                        opacity: _phase1Opacity,
                        child: ScaleTransition(
                          scale: _phase1Scale,
                          child: Image.asset('assets/company-logo.png', width: 160, fit: BoxFit.contain),
                        ),
                      ),
                    ),
                    Center(
                      child: FadeTransition(
                        opacity: _phase2Opacity,
                        child: ScaleTransition(
                          scale: _phase2Scale,
                          child: Image.asset(
                            'assets/banner.png',
                            width: 280,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
