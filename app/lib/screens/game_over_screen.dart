import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/room_provider.dart';
import '../providers/game_provider.dart';
import '../providers/player_provider.dart';
import '../services/game_service.dart';
import '../widgets/gamified_screen.dart';
import '../widgets/game_button.dart';
import '../widgets/mafia_loader.dart';
import '../widgets/game_layout.dart';
import '../widgets/game_app_bar.dart';
import '../widgets/glass_card.dart';
import '../theme.dart';


class GameOverScreen extends ConsumerStatefulWidget {
  final String roomCode;
  const GameOverScreen({super.key, required this.roomCode});

  @override
  ConsumerState<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends ConsumerState<GameOverScreen> {
  final _gameService = GameService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currentRoomCodeProvider.notifier).setCode(widget.roomCode);
    });
  }

  @override
  Widget build(BuildContext context) {
    final roomCode = widget.roomCode;
    final roomAsync = ref.watch(roomStreamProvider);
    final myPlayerAsync = ref.watch(myPlayerProvider);
    final isHost = ref.watch(isNarratorProvider);
    var theme = Theme.of(context);

    // Dynamic redirection for all players
    ref.listen(roomStreamProvider, (prev, next) {
      final nextData = next.asData?.value;
      if (nextData == null) {
        context.go('/');
        return;
      }
      
      final status = nextData.status;
      if (status == 'lobby') {
        context.go('/waiting/$roomCode');
      } else if (status == 'game_over_terminated') {
        context.go('/');
      }
    });

    return GameLayout(
      scrollable: true, // Allow scroll for narrator controls or long content
      appBar: GameAppBar(
        title: 'RESULTS',
        roomCode: roomCode,
        isHost: isHost,
      ),
      content: roomAsync.when(
        data: (room) {
          if (room == null) return const Center(child: Text('Loading...'));

          final winnerTeam = room.winner ?? 'Unknown';
          final myPlayer = myPlayerAsync.value;
          final isMafiaTeam = myPlayer != null && (myPlayer.role == 'mafia' || myPlayer.role == 'godfather');
          
          final iWon = (winnerTeam == 'mafia' && isMafiaTeam) || (winnerTeam == 'village' && !isMafiaTeam);

          // Theme data based on winner and current player
          final isMafiaVictory = winnerTeam == 'mafia';
          final accentColor = isMafiaVictory ? AppTheme.primary : AppTheme.success;
          
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                if (!isHost) ...[
                  // Outcome Header (Only for Players)
                  Icon(
                    iWon ? (isMafiaVictory ? Icons.military_tech_rounded : Icons.verified_user_rounded) 
                         : (isMafiaVictory ? Icons.sentiment_very_dissatisfied_rounded : Icons.gavel_rounded),
                    size: 120, 
                    color: iWon ? accentColor : Colors.white38,
                  ),
                  const SizedBox(height: 24),
                  
                  Text(
                    iWon ? 'VICTORY' : 'DEFEAT',
                    style: theme.textTheme.displayLarge?.copyWith(
                      letterSpacing: 8,
                      color: iWon ? accentColor : Colors.white38,
                      shadows: iWon ? [Shadow(color: accentColor.withOpacity(0.5), blurRadius: 30)] : [],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  
                  Text(
                    isMafiaVictory ? 'THE MAFIA REIGNS SUPREME' : 'PURPLE TOWN IS SAFE',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white54,
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                ] else
                   const SizedBox(height: 40),

                // Result Card (For Everyone)
                GlassCard(
                  padding: const EdgeInsets.all(32),
                  borderColor: accentColor.withOpacity(0.3),
                  child: Column(
                    children: [
                      Text(
                        winnerTeam.toUpperCase(),
                        style: theme.textTheme.displayMedium?.copyWith(
                          color: accentColor,
                          fontSize: 56,
                          fontWeight: FontWeight.w900,
                          shadows: [Shadow(color: accentColor.withOpacity(0.8), blurRadius: 40)],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "HAS WON THE GAME",
                        style: theme.textTheme.titleLarge?.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 48),
                Text(
                  "FINAL IDENTITY REVEAL",
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white24,
                    letterSpacing: 4,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                ref.watch(playerNamesProvider).when(
                  data: (playersMap) {
                    final players = playersMap.values.toList();
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: players.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final p = players[index];
                        final roleColor = _getRoleColor(p.role);
                        
                        return GlassCard(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          borderColor: roleColor.withOpacity(0.2),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  p.name,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: p.isAlive ? Colors.white : Colors.white38,
                                    decoration: p.isAlive ? null : TextDecoration.lineThrough,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: roleColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: roleColor.withOpacity(0.4)),
                                ),
                                child: Text(
                                  p.role.toUpperCase().replaceAll('_', ' '),
                                  style: TextStyle(color: roleColor, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const MafiaLoader(),
                  error: (e, st) => Text("Error: $e"),
                ),

                if (isHost) ...[
                  const SizedBox(height: 60),
                  GlassCard(
                    padding: const EdgeInsets.all(24),
                    borderColor: AppTheme.primary.withAlpha(100),
                    child: Column(
                      children: [
                        Text("HOST CONTROLS", style: theme.textTheme.titleSmall?.copyWith(color: AppTheme.primary, letterSpacing: 2, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 24),
                        GameButton(
                          label: "PLAY AGAIN",
                          icon: Icons.replay_rounded,
                          type: GameButtonType.primary,
                          onPressed: () => _gameService.resetRoomToLobby(roomCode),
                        ),
                        const SizedBox(height: 16),
                        GameButton(
                          label: "END SESSION",
                          icon: Icons.power_settings_new_rounded,
                          type: GameButtonType.danger,
                          onPressed: () => _gameService.terminateRoom(roomCode),
                        ),
                        const SizedBox(height: 8),
                        const Text("This will affect all players", style: TextStyle(color: Colors.white38, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 40),
              ],
            ),
          );
        },
        loading: () => const MafiaLoader(message: 'Loading...'),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'godfather':
      case 'mafia':
        return AppTheme.primary;
      case 'doctor':
        return AppTheme.success;
      case 'rabid_dog':
        return Colors.orangeAccent;
      case 'detective':
        return Colors.blueAccent;
      default:
        return AppTheme.accent;
    }
  }
}
