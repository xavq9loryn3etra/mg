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
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currentRoomCodeProvider.notifier).setCode(widget.roomCode);
    });
  }

  void _showExitConfirmation(BuildContext context, bool isHost) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isHost ? 'Terminate Game?' : 'Leave Game?', style: Theme.of(context).textTheme.displayMedium),
        content: Text(
          isHost 
            ? 'Are you sure? This will terminate the room for everyone.' 
            : 'Are you sure you want to leave this game?',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        actions: [
          GameButton(
            label: 'CANCEL',
            type: GameButtonType.warning,
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          GameButton(
            label: isHost ? 'TERMINATE' : 'LEAVE',
            type: GameButtonType.primary,
            onPressed: () async {
              Navigator.of(ctx).pop();
              if (isHost) {
                await _gameService.terminateRoom(widget.roomCode);
              }
              await _gameService.leaveSession();
              if (context.mounted) {
                context.go('/');
              }
            },
          ),
        ],
      ),
    );
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
          actions: [
            IconButton(
              icon: const Icon(Icons.exit_to_app, color: AppTheme.danger),
              onPressed: () => _showExitConfirmation(context, true),
            ),
          ],
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
                      Expanded(child: GameButton(label: 'WAKE', type: GameButtonType.primary, onPressed: _currentStep == 0 ? () {
                        _gameService.advanceNightRole(roomCode, 'wake_mafia');
                        setState(() => _currentStep = 1);
                      } : null)),
                      const SizedBox(width: 16),
                      Expanded(child: GameButton(label: 'SLEEP', type: GameButtonType.warning, onPressed: _currentStep == 1 ? () {
                        _gameService.advanceNightRole(roomCode, 'sleep_mafia');
                        setState(() => _currentStep = 2);
                      } : null)),
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
                      Expanded(child: GameButton(label: 'WAKE', type: GameButtonType.primary, onPressed: _currentStep == 2 ? () {
                        _gameService.advanceNightRole(roomCode, 'wake_doctor');
                        setState(() => _currentStep = 3);
                      } : null)),
                      const SizedBox(width: 16),
                      Expanded(child: GameButton(label: 'SLEEP', type: GameButtonType.warning, onPressed: _currentStep == 3 ? () {
                        _gameService.advanceNightRole(roomCode, 'sleep_doctor');
                        setState(() => _currentStep = 4);
                      } : null)),
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
                      Expanded(child: GameButton(label: 'WAKE', type: GameButtonType.primary, onPressed: _currentStep == 4 ? () {
                        _gameService.advanceNightRole(roomCode, 'wake_rabid_dog');
                        setState(() => _currentStep = 5);
                      } : null)),
                      const SizedBox(width: 16),
                      Expanded(child: GameButton(label: 'SLEEP', type: GameButtonType.warning, onPressed: _currentStep == 5 ? () {
                        _gameService.advanceNightRole(roomCode, 'sleep_rabid_dog');
                        setState(() => _currentStep = 6);
                      } : null)),
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
                      Expanded(child: GameButton(label: 'WAKE', type: GameButtonType.primary, onPressed: _currentStep == 6 ? () {
                        _gameService.advanceNightRole(roomCode, 'wake_detective');
                        setState(() => _currentStep = 7);
                      } : null)),
                      const SizedBox(width: 16),
                      Expanded(child: GameButton(label: 'SLEEP', type: GameButtonType.warning, onPressed: _currentStep == 7 ? () {
                        _gameService.advanceNightRole(roomCode, 'sleep_detective');
                        setState(() => _currentStep = 8);
                      } : null)),
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
              onPressed: _currentStep == 8 ? () => _gameService.revealMorning(roomCode) : null,
            ),
            const SizedBox(height: 32),
          ],
        ),
      );
    }

    return GamifiedScreen(
      appBar: AppBar(
        title: Text('THE NIGHT', style: theme.textTheme.displayMedium),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: AppTheme.danger),
            onPressed: () => _showExitConfirmation(context, false),
          ),
        ],
      ),
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
                            final allPlayers = playersMap.values.toList();
                            final mafiaTeam = ref.watch(mafiaTeamProvider).value ?? {};
                            
                            return ListView.separated(
                              itemCount: allPlayers.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final target = allPlayers[index];
                                final isDead = !target.isAlive;
                                
                                bool isMyTeam = false;
                                String? teamBadge;
                                if ((me.role == 'mafia' || me.role == 'godfather') && 
                                    mafiaTeam.containsKey(target.id)) {
                                  isMyTeam = true;
                                  teamBadge = mafiaTeam[target.id]!.toUpperCase(); // 'MAFIA' or 'GODFATHER'
                                }

                                final canSelect = !isDead && !isMyTeam;
                                
                                String buttonLabel = target.name;
                                if (isDead) {
                                  buttonLabel += ' (DEAD)';
                                } else if (teamBadge != null) {
                                  buttonLabel += ' ($teamBadge)';
                                }

                                return GameButton(
                                  label: buttonLabel,
                                  type: isDead ? GameButtonType.warning : 
                                        isMyTeam ? GameButtonType.warning : GameButtonType.primary,
                                  onPressed: !canSelect ? null : () async {
                                    if (me.role == 'mafia' || me.role == 'godfather') {
                                      await _gameService.submitMafiaVote(roomCode, target.id);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).clearSnackBars();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Target locked.'), backgroundColor: AppTheme.primary),
                                        );
                                      }
                                    } else {
                                      final res = await _gameService.submitNightAction(roomCode, target.id);
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
                                        ScaffoldMessenger.of(context).clearSnackBars();
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
