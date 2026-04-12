import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/player_provider.dart';
import '../providers/game_provider.dart';
import '../widgets/gamified_screen.dart';
import '../widgets/game_button.dart';
import '../widgets/mafia_loader.dart';
import '../theme.dart';

class RoleRevealScreen extends ConsumerStatefulWidget {
  final String roomCode;
  const RoleRevealScreen({super.key, required this.roomCode});

  @override
  ConsumerState<RoleRevealScreen> createState() => _RoleRevealScreenState();
}

class _RoleRevealScreenState extends ConsumerState<RoleRevealScreen> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final isHost = ref.watch(isNarratorProvider);
    final myPlayerAsync = ref.watch(myPlayerProvider);
    var theme = Theme.of(context);

    if (isHost) {
      return GamifiedScreen(
        child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.visibility_off, size: 80, color: AppTheme.accent),
                  const SizedBox(height: 24),
                  Text(
                    "ROLES ASSIGNED!",
                    style: theme.textTheme.displayMedium?.copyWith(color: AppTheme.accent),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Waiting for players to acknowledge their roles...",
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  GameButton(
                    label: "PROCEED TO NIGHT",
                    icon: Icons.dark_mode,
                    type: GameButtonType.primary,
                    onPressed: () => context.go('/night/${widget.roomCode}'),
                  ),
                ],
              ),
            ),
          ),
      );
    }

    return GamifiedScreen(
      child: myPlayerAsync.when(
          data: (me) {
            if (me == null) return const Center(child: Text("Loading..."));
            return GestureDetector(
              onLongPressStart: (_) => setState(() => _revealed = true),
              onLongPressEnd: (_) => setState(() => _revealed = false),
              child: Container(
                color: Colors.transparent, // Touch target filling
                child: Center(
                  child: _revealed
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'YOU ARE',
                              style: theme.textTheme.titleLarge?.copyWith(letterSpacing: 4),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              me.role.toUpperCase(),
                              style: theme.textTheme.displayLarge?.copyWith(
                                color: me.role == 'mafia' ? AppTheme.primary : AppTheme.success,
                                fontSize: 64,
                                shadows: [
                                  Shadow(
                                    color: (me.role == 'mafia' ? AppTheme.primary : AppTheme.success).withOpacity(0.5),
                                    blurRadius: 20,
                                  )
                                ]
                              ),
                            ),
                            const SizedBox(height: 48),
                            GameButton(
                              label: "I'M READY",
                              icon: Icons.check,
                              type: GameButtonType.success,
                              onPressed: () => context.go('/night/${widget.roomCode}'),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TweenAnimationBuilder(
                              tween: Tween<double>(begin: 0.8, end: 1.0),
                              duration: const Duration(seconds: 1),
                              builder: (context, val, child) {
                                return Transform.scale(
                                  scale: val,
                                  child: Icon(Icons.fingerprint, size: 100, color: AppTheme.accent),
                                );
                              },
                              onEnd: () {
                                // Add pulsing by reversing tween if desired
                              },
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'PRESS AND HOLD',
                              style: theme.textTheme.displayMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'TO REVEAL ROLE',
                              style: theme.textTheme.titleLarge?.copyWith(color: AppTheme.accent),
                            ),
                          ],
                        ),
                ),
              ),
            );
          },
          loading: () => const MafiaLoader(message: 'Loading role...'),
          error: (e, st) => Text('Error: $e'),
        ),
    );
  }
}
