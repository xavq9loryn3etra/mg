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

class NightScreen extends ConsumerStatefulWidget {
  final String roomCode;
  const NightScreen({super.key, required this.roomCode});

  @override
  ConsumerState<NightScreen> createState() => _NightScreenState();
}

class _NightScreenState extends ConsumerState<NightScreen> {
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
    final isHost = ref.watch(isNarratorProvider);
    final myPlayerAsync = ref.watch(myPlayerProvider);
    final isMyTurn = ref.watch(isMyTurnProvider);
    final playersAsync = ref.watch(playerNamesProvider);
    var theme = Theme.of(context);

    ref.listen(roomStreamProvider, (prev, next) {
      if (next.value?.status == 'day') {
        context.go('/day/$roomCode');
      } else if (next.value?.status == 'game_over') {
        context.go('/gameover/$roomCode');
      }
    });

    if (isHost) {
      return GamifiedScreen(
        appBar: AppBar(
          title: Text('NIGHT CONTROL', style: theme.textTheme.displayMedium),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('MAFIA', style: theme.textTheme.titleLarge?.copyWith(color: AppTheme.primary)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: GameButton(label: 'WAKE', type: GameButtonType.primary, onPressed: () => _gameService.advanceNightRole(roomCode, 'wake_mafia'))),
                      const SizedBox(width: 16),
                      Expanded(child: GameButton(label: 'SLEEP', type: GameButtonType.warning, onPressed: () => _gameService.advanceNightRole(roomCode, 'sleep_mafia'))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('DOCTOR', style: theme.textTheme.titleLarge?.copyWith(color: AppTheme.success)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: GameButton(label: 'WAKE', type: GameButtonType.primary, onPressed: () => _gameService.advanceNightRole(roomCode, 'wake_doctor'))),
                      const SizedBox(width: 16),
                      Expanded(child: GameButton(label: 'SLEEP', type: GameButtonType.warning, onPressed: () => _gameService.advanceNightRole(roomCode, 'sleep_doctor'))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('RABID DOG', style: theme.textTheme.titleLarge?.copyWith(color: AppTheme.accent)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: GameButton(label: 'WAKE', type: GameButtonType.primary, onPressed: () => _gameService.advanceNightRole(roomCode, 'wake_rabid_dog'))),
                      const SizedBox(width: 16),
                      Expanded(child: GameButton(label: 'SLEEP', type: GameButtonType.warning, onPressed: () => _gameService.advanceNightRole(roomCode, 'sleep_rabid_dog'))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('DETECTIVE', style: theme.textTheme.titleLarge?.copyWith(color: Colors.blueAccent)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: GameButton(label: 'WAKE', type: GameButtonType.primary, onPressed: () => _gameService.advanceNightRole(roomCode, 'wake_detective'))),
                      const SizedBox(width: 16),
                      Expanded(child: GameButton(label: 'SLEEP', type: GameButtonType.warning, onPressed: () => _gameService.advanceNightRole(roomCode, 'sleep_detective'))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            GameButton(
              label: 'REVEAL MORNING',
              icon: Icons.wb_sunny,
              type: GameButtonType.success,
              onPressed: () => _gameService.revealMorning(roomCode),
            ),
            const SizedBox(height: 32),
          ],
        ),
      );
    }

    return GamifiedScreen(
      child: myPlayerAsync.when(
          data: (me) {
            if (me == null) return const Center(child: Text('Loading...'));
            if (!me.isAlive) {
              return Center(
                child: GlassCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.sentiment_very_dissatisfied, size: 80, color: Colors.white54),
                      const SizedBox(height: 24),
                      Text("YOU ARE DEAD", style: theme.textTheme.displayMedium?.copyWith(color: AppTheme.primary)),
                      const SizedBox(height: 16),
                      Text("Observing the night...", style: theme.textTheme.titleLarge),
                    ],
                  ),
                )
              );
            }

            if (isMyTurn) {
              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      'YOUR TURN!',
                      style: theme.textTheme.displayLarge?.copyWith(color: AppTheme.accent),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'SELECT YOUR TARGET',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: playersAsync.when(
                        data: (playersMap) {
                          var alivePlayers = playersMap.values.where((p) => p.isAlive).toList();
                          
                          // Mafia and Godfather cannot kill each other
                          if (me.role == 'mafia' || me.role == 'godfather') {
                            alivePlayers = alivePlayers.where((p) => p.role != 'mafia' && p.role != 'godfather').toList();
                          }

                          return ListView.separated(
                            itemCount: alivePlayers.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              return GameButton(
                                label: alivePlayers[index].name,
                                type: GameButtonType.primary,
                                onPressed: () async {
                                  if (me.role == 'mafia' || me.role == 'godfather') {
                                    await _gameService.submitMafiaVote(roomCode, alivePlayers[index].id);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Target locked.'), backgroundColor: AppTheme.primary),
                                      );
                                    }
                                  } else {
                                    final res = await _gameService.submitNightAction(roomCode, alivePlayers[index].id);
                                    if (res != null && context.mounted) {
                                       showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: Text('Result', style: theme.textTheme.displayMedium),
                                          content: Text(res, style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
                                          actions: [
                                            GameButton(label: 'OK', type: GameButtonType.success, onPressed: () => Navigator.of(ctx).pop())
                                          ],
                                        )
                                      );
                                    } else if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Action confirmed.'), backgroundColor: AppTheme.success),
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
                ),
              );
            }

            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimateSleepMoon(),
                  const SizedBox(height: 32),
                  Text(
                    'SHHH... SLEEPING',
                    style: theme.textTheme.displayMedium?.copyWith(color: AppTheme.accent),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'WAITING FOR SUNRISE',
                    style: theme.textTheme.titleLarge,
                  ),
                ],
              ),
            );
          },
          loading: () => const MafiaLoader(message: 'Loading...'),
          error: (e, st) => Center(child: Text('Error: $e')),
        ),
    );
  }
}

class AnimateSleepMoon extends StatefulWidget {
  @override
  _AnimateSleepMoonState createState() => _AnimateSleepMoonState();
}

class _AnimateSleepMoonState extends State<AnimateSleepMoon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _animation = Tween<double>(begin: -10.0, end: 10.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: const Icon(Icons.nightlight_round, size: 120, color: AppTheme.accent),
        );
      },
    );
  }
}
