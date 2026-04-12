import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/room_provider.dart';
import '../widgets/gamified_screen.dart';
import '../widgets/game_button.dart';
import '../widgets/mafia_loader.dart';
import '../theme.dart';

class GameOverScreen extends ConsumerWidget {
  final String roomCode;
  const GameOverScreen({super.key, required this.roomCode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomAsync = ref.watch(roomStreamProvider);
    var theme = Theme.of(context);

    return GamifiedScreen(
      child: roomAsync.when(
          data: (room) {
            if (room == null) return const Center(child: Text('Loading...'));

            final winner = room.winner ?? 'Unknown';
            final color = winner == 'mafia' ? AppTheme.primary : AppTheme.success;
            final icon = winner == 'mafia' ? Icons.warning_rounded : Icons.emoji_events_rounded;

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 100, color: color),
                    const SizedBox(height: 24),
                    Text(
                      'GAME OVER',
                      style: theme.textTheme.displayLarge?.copyWith(letterSpacing: 4),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '$winner won!'.toUpperCase(),
                      style: theme.textTheme.displayMedium?.copyWith(
                        color: color,
                        shadows: [
                          Shadow(
                            color: color.withOpacity(0.5),
                            blurRadius: 20,
                          )
                        ],
                        fontSize: 48,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 60),
                    GameButton(
                      label: 'BACK TO HOME',
                      icon: Icons.home_rounded,
                      type: GameButtonType.primary,
                      onPressed: () => context.go('/'),
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => const MafiaLoader(message: 'Loading...'),
          error: (e, st) => Center(child: Text('Error: $e')),
        ),
    );
  }
}
