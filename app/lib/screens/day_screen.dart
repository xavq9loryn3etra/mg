import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/room_provider.dart';
import '../providers/player_provider.dart';
import '../providers/game_provider.dart';
import '../services/game_service.dart';
import '../widgets/gamified_screen.dart';
import '../widgets/game_button.dart';
import '../widgets/glass_card.dart';
import '../widgets/mafia_loader.dart';
import '../theme.dart';

class DayScreen extends ConsumerStatefulWidget {
  final String roomCode;
  const DayScreen({super.key, required this.roomCode});

  @override
  ConsumerState<DayScreen> createState() => _DayScreenState();
}

class _DayScreenState extends ConsumerState<DayScreen> {
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
    final isHost = ref.watch(isNarratorProvider);
    final playersAsync = ref.watch(playerNamesProvider);
    var theme = Theme.of(context);

    ref.listen(roomStreamProvider, (prev, next) {
      if (next.value?.status == 'night') {
        context.go('/night/$roomCode');
      } else if (next.value?.status == 'game_over') {
        context.go('/gameover/$roomCode');
      }
    });

    return GamifiedScreen(
      appBar: AppBar(
        title: Text('DAY PHASE', style: theme.textTheme.displayMedium),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      child: roomAsync.when(
          data: (room) {
            if (room == null) return const Center(child: Text("Loading..."));

            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    borderColor: AppTheme.accent,
                    child: Column(
                      children: [
                        const Icon(Icons.wb_sunny, size: 64, color: AppTheme.accent),
                        const SizedBox(height: 16),
                        Text(
                          room.morningAnnouncement ?? 'MORNING HAS ARRIVED',
                          style: theme.textTheme.titleLarge?.copyWith(height: 1.5),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  if (isHost) ...[
                    const Spacer(),
                    if (room.status == 'day') ...[
                      GameButton(
                        label: 'START VOTING',
                        icon: Icons.how_to_vote,
                        type: GameButtonType.primary,
                        onPressed: () => _gameService.startVoting(roomCode),
                      ),
                      const SizedBox(height: 16),
                      GameButton(
                        label: 'SKIP TO NIGHT',
                        icon: Icons.nightlight_round,
                        type: GameButtonType.warning,
                        onPressed: () => _gameService.skipToNight(roomCode),
                      ),
                    ] else if (room.status == 'voting') ...[
                      GameButton(
                        label: 'RESOLVE VOTES',
                        icon: Icons.gavel,
                        type: GameButtonType.danger,
                        onPressed: () => _gameService.resolveVotes(roomCode),
                      ),
                    ],
                  ],

                  if (!isHost && room.status == 'voting') ...[
                    Text(
                      'TOWN HALL MEETING',
                      style: theme.textTheme.displayMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cast your vote on who to exile',
                      style: theme.textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: playersAsync.when(
                        data: (playersMap) {
                          final alivePlayers = playersMap.values.where((p) => p.isAlive).toList();
                          return ListView.separated(
                            itemCount: alivePlayers.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              return GameButton(
                                label: alivePlayers[index].name,
                                type: GameButtonType.primary,
                                onPressed: () async {
                                  try {
                                    await _gameService.submitVote(roomCode, alivePlayers[index].id);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Vote cast!'), backgroundColor: AppTheme.primary),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                       showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: Text('Voting Error', style: theme.textTheme.displayMedium),
                                          content: Text(e.toString(), style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
                                          actions: [
                                            GameButton(label: 'OK', type: GameButtonType.warning, onPressed: () => Navigator.of(ctx).pop())
                                          ],
                                        )
                                      );
                                    }
                                  }
                                },
                              );
                            },
                          );
                        },
                        loading: () => const MafiaLoader(),
                        error: (e, st) => Text('Error: $e'),
                      ),
                    ),
                  ],

                  if (!isHost && room.status != 'voting')
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.forum, size: 80, color: Colors.white54),
                            const SizedBox(height: 24),
                            Text("DISCUSS...", style: theme.textTheme.displayMedium),
                            const SizedBox(height: 16),
                            Text("Waiting for Host to start voting.", style: theme.textTheme.titleLarge),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
          loading: () => const MafiaLoader(message: 'Loading day...'),
          error: (e, st) => Text('Error: $e'),
        ),
    );
  }
}
