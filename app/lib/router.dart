import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/auth_provider.dart';
import 'providers/room_provider.dart';
import 'screens/home_screen.dart';
import 'screens/lobby_screen.dart';
import 'screens/role_reveal_screen.dart';
import 'screens/night_screen.dart';
import 'screens/day_screen.dart';
import 'screens/game_over_screen.dart';
import 'screens/waiting_screen.dart';
import 'screens/tutorial_screen.dart';
import 'providers/app_provider.dart';

/// Dramatic fade + scale transition for major phase changes
CustomTransitionPage<void> _buildTransition({
  required LocalKey key,
  required Widget child,
  Duration duration = const Duration(milliseconds: 500),
  bool slideUp = false,
}) {
  return CustomTransitionPage<void>(
    key: key,
    transitionDuration: duration,
    reverseTransitionDuration: const Duration(milliseconds: 300),
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      
      if (slideUp) {
        // Slide up from bottom + fade (for lobby, reveals)
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.15),
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      }

      // Scale + fade (for phase transitions like night→day)
      return ScaleTransition(
        scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
        child: FadeTransition(opacity: curved, child: child),
      );
    },
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final hasSeenTutorial = ref.watch(tutorialSeenProvider);

  return GoRouter(
    initialLocation: hasSeenTutorial ? '/' : '/tutorial',
    redirect: (context, state) {
      final isLoading = authState.isLoading;

      if (isLoading) return null; // Wait for auth init

      return null; // For simplicity, let guards handle logic in screens or here
    },
    routes: [
      GoRoute(
        path: '/tutorial',
        pageBuilder: (context, state) => _buildTransition(
          key: state.pageKey,
          child: const TutorialScreen(),
          slideUp: true,
        ),
      ),
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => _buildTransition(
          key: state.pageKey,
          child: const HomeScreen(),
        ),
      ),
      GoRoute(
        path: '/lobby/:roomCode',
        pageBuilder: (context, state) {
          final roomCode = state.pathParameters['roomCode']!;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(currentRoomCodeProvider.notifier).setCode(roomCode);
          });
          return _buildTransition(
            key: state.pageKey,
            child: LobbyScreen(roomCode: roomCode),
            slideUp: true,
          );
        },
      ),
      GoRoute(
        path: '/reveal/:roomCode',
        pageBuilder: (context, state) => _buildTransition(
          key: state.pageKey,
          child: RoleRevealScreen(roomCode: state.pathParameters['roomCode']!),
          slideUp: true,
          duration: const Duration(milliseconds: 700),
        ),
      ),
      GoRoute(
        path: '/night/:roomCode',
        pageBuilder: (context, state) => _buildTransition(
          key: state.pageKey,
          child: NightScreen(roomCode: state.pathParameters['roomCode']!),
          duration: const Duration(milliseconds: 800),
        ),
      ),
      GoRoute(
        path: '/day/:roomCode',
        pageBuilder: (context, state) => _buildTransition(
          key: state.pageKey,
          child: DayScreen(roomCode: state.pathParameters['roomCode']!),
          duration: const Duration(milliseconds: 800),
        ),
      ),
      GoRoute(
        path: '/gameover/:roomCode',
        pageBuilder: (context, state) => _buildTransition(
          key: state.pageKey,
          child: GameOverScreen(roomCode: state.pathParameters['roomCode']!),
          duration: const Duration(milliseconds: 1000),
        ),
      ),
      GoRoute(
        path: '/waiting/:roomCode',
        pageBuilder: (context, state) => _buildTransition(
          key: state.pageKey,
          child: WaitingScreen(roomCode: state.pathParameters['roomCode']!),
          slideUp: true,
        ),
      ),
    ],
  );
});
