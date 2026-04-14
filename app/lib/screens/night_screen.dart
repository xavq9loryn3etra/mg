import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/room_provider.dart';
import '../providers/player_provider.dart';
import '../models/player.dart';
import '../providers/game_provider.dart';

import '../services/game_service.dart';
import '../models/night_actions.dart';
import '../providers/night_actions_provider.dart';
import '../widgets/gamified_screen.dart';
import '../widgets/game_button.dart';
import '../widgets/glass_card.dart';
import '../widgets/mafia_loader.dart';
import '../widgets/game_layout.dart';
import '../widgets/game_app_bar.dart';
import '../providers/auth_provider.dart';
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
                if (context.mounted) {
                  // Host goes back to lobby
                  context.go('/lobby/${widget.roomCode}');
                }
              } else {
                await _gameService.leaveRoom(widget.roomCode);
                if (context.mounted) {
                  context.go('/');
                }
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
    final roomAsync = ref.watch(roomStreamProvider);
    final isHost = ref.watch(isNarratorProvider);
    final myPlayerAsync = ref.watch(myPlayerProvider);
    final isMyTurn = ref.watch(isMyTurnProvider);
    final playersAsync = ref.watch(playerNamesProvider);
    final nightActionsAsync = ref.watch(nightActionsProvider);
    var theme = Theme.of(context);

    ref.listen(roomStreamProvider, (prev, next) {
      // 1. Only act if we have confirmed NEW data
      final nextData = next.asData?.value;
      if (nextData == null) return;
      
      // 2. Only act if this is a transition from a PREVIOUS confirmed data state
      final prevData = prev?.asData?.value;
      if (prevData == null) return;

      final oldStatus = prevData.status;
      final newStatus = nextData.status;
      
      if (oldStatus == newStatus) return; // No change, don't spam

      // HARDENED IDENTITY CHECK
      final currentUid = ref.read(authStateProvider).value?.uid;
      final isReallyHost = nextData.hostId == currentUid;

      if (newStatus == 'day') {
        context.go('/day/$roomCode');
      } else if (newStatus == 'lobby' && !isReallyHost) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Game ended by narrator.')),
          );
          context.go('/waiting/$roomCode');
        }
      } else if (newStatus == 'game_over') {
        if (context.mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          if (nextData.winner != null) {
            context.go('/gameover/$roomCode');
          } else if (!isReallyHost) {
             // Do NOT navigate home immediately; wait for the winner field to arrive in the next stream update
             // but if it stays null for too long, then it was a termination.
             Future.delayed(const Duration(milliseconds: 500), () {
               if (context.mounted) {
                 final currentRoom = ref.read(roomStreamProvider).asData?.value;
                 if (currentRoom?.status == 'game_over' && currentRoom?.winner == null) {
                   ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(content: Text('Game terminated by host.')),
                   );
                   context.go('/');
                 } else if (currentRoom?.winner != null) {
                   context.go('/gameover/$roomCode');
                 }
               }
             });
          } else {
            // As Host, we stay in the room and wait for the results screen
            // Host is never automatically kicked to /
          }
        }
      }
    });







    // Determine if we should allow scrolling (usually true for narrator or when picking targets)
    bool isSingleCardState = !isHost && (roomAsync.value?.status == 'night');
    
    // Check if player is dead or has locked their target
    if (!isHost) {
      final me = myPlayerAsync.value;
      if (me != null) {
        if (!me.isAlive) isSingleCardState = true;
        else if (isMyTurn) {
          final nightActions = nightActionsAsync.value;
          bool hasTarget = false;
          if (me.role == 'doctor') hasTarget = nightActions?.doctorTarget != null;
          else if (me.role == 'rabid_dog') hasTarget = nightActions?.dogTarget != null;
          else if (me.role == 'detective') hasTarget = nightActions?.detectiveScan != null;
          else if (me.role == 'mafia' || me.role == 'godfather') hasTarget = nightActions?.mafiaVotes[me.id] != null;
          
          if (hasTarget) isSingleCardState = true;
          else isSingleCardState = false; // Picking targets needs scrolling
        } else {
          isSingleCardState = true; // Sleeping
        }
      }
    }

    return GameLayout(
      scrollable: isHost || !isSingleCardState,
      appBar: GameAppBar(
        title: isHost ? 'NIGHT CONTROL' : 'THE NIGHT',
        roomCode: widget.roomCode,
        isHost: isHost,
      ),
      content: roomAsync.when(
        data: (room) {
          if (room == null) return const Center(child: Text('Room not found'));
          
          if (isHost) {
            final config = room.config;
            
            return playersAsync.when(
              data: (playersMap) {
                final players = playersMap.values.toList();
                
                List<PlayerNameItem> getMembers(String role) {
                  if (role == 'mafia') {
                    return players.where((p) => p.role == 'mafia' || p.role == 'godfather').toList();
                  }
                  return players.where((p) => p.role == role).toList();
                }

                final nightActions = nightActionsAsync.value;

                return Column(
                  children: [
                    if (config.hasMafia1 || config.hasMafia2 || config.hasGodfather)
                      _buildControlCard(
                        theme: theme,
                        title: 'MAFIA',
                        members: getMembers('mafia'),
                        targetName: nightActions?.mafiaTarget != null ? playersMap[nightActions!.mafiaTarget]?.name : null,
                        color: AppTheme.primary,
                        currentActiveRole: room.activeRole,
                        canSleep: nightActions?.mafiaTarget != null,
                        onWake: () => _gameService.advanceNightRole(roomCode, 'wake_mafia'),
                        onSleep: () async {
                          await _gameService.advanceNightRole(roomCode, 'sleep_mafia');
                        },
                      ),
                    const SizedBox(height: 16),
                    if (config.hasDoctor)
                      _buildControlCard(
                        theme: theme,
                        title: 'DOCTOR',
                        members: getMembers('doctor'),
                        targetName: nightActions?.doctorTarget != null ? playersMap[nightActions!.doctorTarget]?.name : null,
                        color: AppTheme.success,
                        currentActiveRole: room.activeRole,
                        canSleep: nightActions?.doctorTarget != null,
                        onWake: () => _gameService.advanceNightRole(roomCode, 'wake_doctor'),
                        onSleep: () async {
                          await _gameService.advanceNightRole(roomCode, 'sleep_doctor');
                        },
                      ),
                    const SizedBox(height: 16),
                    if (config.hasRabidDog)
                      _buildControlCard(
                        theme: theme,
                        title: 'RABID DOG',
                        members: getMembers('rabid_dog'),
                        targetName: nightActions?.dogTarget != null ? playersMap[nightActions!.dogTarget]?.name : null,
                        color: AppTheme.accent,
                        currentActiveRole: room.activeRole,
                        canSleep: nightActions?.dogTarget != null,
                        onWake: () => _gameService.advanceNightRole(roomCode, 'wake_rabid_dog'),
                        onSleep: () async {
                          await _gameService.advanceNightRole(roomCode, 'sleep_rabid_dog');
                        },
                      ),
                    const SizedBox(height: 16),
                    if (config.hasDetective)
                      _buildControlCard(
                        theme: theme,
                        title: 'DETECTIVE',
                        members: getMembers('detective'),
                        targetName: nightActions?.detectiveScan != null ? playersMap[nightActions!.detectiveScan]?.name : null,
                        color: Colors.blueAccent,
                        currentActiveRole: room.activeRole,
                        showReveal: nightActions?.detectiveScan != null && !nightActions!.detectiveScanResolved,
                        canSleep: nightActions?.detectiveScan != null && nightActions!.detectiveScanResolved,
                        onReveal: () => _gameService.resolveDetectiveScan(roomCode),
                        onWake: () => _gameService.advanceNightRole(roomCode, 'wake_detective'),
                        onSleep: () async {
                          await _gameService.advanceNightRole(roomCode, 'sleep_detective');
                        },
                      ),
                  ],
                );
              },
              loading: () => const MafiaLoader(),
              error: (e, st) => Text('Error loading players: $e'),
            );
          }

          // Player View
          return myPlayerAsync.when(
            data: (me) {
              if (me == null) return const Center(child: Text('Loading...'));
              
              if (!me.isAlive) {
                return Column(
                  children: [
                    const SizedBox(height: 24),
                    Text('SPECTATING', style: theme.textTheme.displaySmall?.copyWith(color: Colors.white24, letterSpacing: 4)),
                    const SizedBox(height: 16),
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        "You were eliminated, but you can still watch the night unfold. Dead men tell no tales!",
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                      ),
                    ),
                    const SizedBox(height: 24),
                    playersAsync.when(
                      data: (playersMap) {
                        final allPlayers = playersMap.values.toList();
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: allPlayers.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final p = allPlayers[index];
                            return GameButton(
                              label: p.name + (p.isAlive ? "" : " (DEAD)"),
                              type: p.id == me.id ? GameButtonType.warning : GameButtonType.primary,
                              onPressed: null, // Spectators cannot interact
                            );
                          },
                        );
                      },
                      loading: () => const MafiaLoader(),
                      error: (e, st) => Text("Error: $e"),
                    ),
                    const SizedBox(height: 32),
                    GameButton(
                      label: "LEAVE SESSION",
                      icon: Icons.logout,
                      type: GameButtonType.danger,
                      onPressed: () => _gameService.leaveSession(),
                    ),
                    const SizedBox(height: 40),
                  ],
                );
              }

              if (isMyTurn) {
                return playersAsync.when(
                  data: (playersMap) {
                    final nightActions = nightActionsAsync.value;
                    String? myTargetId;
                    bool isResolved = false;

                    if (me.role == 'doctor') myTargetId = nightActions?.doctorTarget;
                    else if (me.role == 'rabid_dog') myTargetId = nightActions?.dogTarget;
                    else if (me.role == 'detective') {
                       myTargetId = nightActions?.detectiveScan;
                       isResolved = nightActions?.detectiveScanResolved ?? false;
                    } else if (me.role == 'mafia' || me.role == 'godfather') {
                      myTargetId = nightActions?.mafiaVotes[me.id];
                    }

                    if (myTargetId != null) {
                      final targetName = playersMap[myTargetId]?.name ?? "Unknown";
                      
                      // Specific logic for Detective reveal
                      if (me.role == 'detective' && !isResolved) {
                        return Center(
                          child: GlassCard(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.hourglass_empty, size: 64, color: Colors.blueAccent),
                                const SizedBox(height: 24),
                                Text("SCANNED: ${targetName.toUpperCase()}", style: theme.textTheme.titleLarge),
                                const SizedBox(height: 12),
                                Text("WAITING FOR NARRATOR TO REVEAL...", style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white54, letterSpacing: 1)),
                              ],
                            ),
                          ),
                        );
                      }

                      if (me.role == 'detective' && isResolved) {
                        final target = playersMap[myTargetId];
                        final targetRole = target?.role ?? 'villager';
                        // Detective only identifies 'mafia'. Everything else (villager, doctor, dog, and Godfather) is 'villager'.
                        final isMafia = targetRole == 'mafia';
                        final result = isMafia ? 'MAFIA' : 'VILLAGER';

                        return Center(
                          child: GlassCard(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isMafia ? Icons.warning_amber_rounded : Icons.verified_user_outlined, 
                                  size: 80, 
                                  color: isMafia ? AppTheme.primary : AppTheme.success
                                ),
                                const SizedBox(height: 24),
                                Text(targetName.toUpperCase(), style: theme.textTheme.displayMedium),
                                const SizedBox(height: 8),
                                Text(
                                  "RESULT: $result", 
                                  style: theme.textTheme.displayLarge?.copyWith(
                                    color: isMafia ? AppTheme.primary : AppTheme.success,
                                    fontWeight: FontWeight.w900,
                                  )
                                ),
                                const SizedBox(height: 32),
                                const Text("Stay silent until morning.", style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic)),
                              ],
                            ),
                          ),
                        );
                      }

                      return Center(
                        child: GlassCard(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.lock_clock, size: 64, color: AppTheme.accent),
                              const SizedBox(height: 24),
                              Text("TARGET LOCKED", style: theme.textTheme.titleLarge?.copyWith(color: AppTheme.accent)),
                              const SizedBox(height: 12),
                              Text(targetName.toUpperCase(), style: theme.textTheme.displayLarge),
                              const SizedBox(height: 24),
                              const Text("You cannot change your choice.", style: TextStyle(color: Colors.white54)),
                            ],
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: [
                        const SizedBox(height: 24),
                        Text('YOUR TURN!', style: theme.textTheme.displayLarge?.copyWith(color: AppTheme.accent)),
                        const SizedBox(height: 8),
                        Text('SELECT YOUR TARGET', style: theme.textTheme.titleLarge),
                        const SizedBox(height: 24),
                        Builder(
                          builder: (context) {
                            final allPlayers = playersMap.values.toList();
                            final mafiaTeam = ref.watch(mafiaTeamProvider).value ?? {};
                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: allPlayers.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final target = allPlayers[index];
                                final isDead = !target.isAlive;
                                bool isMyTeam = false;
                                String? teamBadge;
                                final iWon = (ref.read(roomStreamProvider).value?.winner == 'mafia' && (me.role == 'mafia' || me.role == 'godfather')) || (ref.read(roomStreamProvider).value?.winner == 'village' && !(me.role == 'mafia' || me.role == 'godfather'));
                                if ((me.role == 'mafia' || me.role == 'godfather') && mafiaTeam.containsKey(target.id)) {
                                  isMyTeam = true;
                                  teamBadge = mafiaTeam[target.id]!.toUpperCase();
                                }
                                final isSelf = target.id == me.id;
                                final canTargetSelf = me.role == 'doctor';
                                final canSelect = !isDead && !isMyTeam && (!isSelf || canTargetSelf);

                                String buttonLabel = target.name;
                                if (isDead) buttonLabel += ' (DEAD)';
                                else if (teamBadge != null) buttonLabel += ' ($teamBadge)';
                                else if (isSelf) buttonLabel += ' (YOU)';

                                return GameButton(
                                  label: buttonLabel,
                                  type: isDead ? GameButtonType.warning : isMyTeam ? GameButtonType.warning : GameButtonType.primary,
                                  onPressed: !canSelect ? null : () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: Text("CONFIRM ACTION", style: theme.textTheme.displayMedium),
                                        content: Text("Are you sure you want to target ${target.name}? This cannot be undone.", textAlign: TextAlign.center),
                                        actions: [
                                          GameButton(label: "CANCEL", type: GameButtonType.warning, onPressed: () => Navigator.pop(ctx, false)),
                                          GameButton(label: "YES, POINT", type: GameButtonType.primary, onPressed: () => Navigator.pop(ctx, true)),
                                        ],
                                      )
                                    );

                                    if (confirmed != true) return;

                                    if (me.role == 'mafia' || me.role == 'godfather') {
                                      await _gameService.submitMafiaVote(roomCode, target.id);
                                    } else {
                                      await _gameService.submitNightAction(roomCode, target.id);
                                    }
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ],
                    );
                  },
                  loading: () => const MafiaLoader(),
                  error: (e, st) => Text('Error: $e'),
                );
              }

              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimateSleepMoon(),
                    const SizedBox(height: 32),
                    Text('SHHH... SLEEPING', style: theme.textTheme.displayMedium?.copyWith(color: AppTheme.accent)),
                    const SizedBox(height: 16),
                    Text('WAITING FOR SUNRISE', style: theme.textTheme.titleLarge),
                  ],
                ),
              );
            },
            loading: () => const MafiaLoader(message: 'Loading...'),
            error: (e, st) => Center(child: Text('Error: $e')),
          );
        },
        loading: () => const MafiaLoader(message: 'Loading...'),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
      bottom: isHost ? GameButton(
          label: 'REVEAL MORNING',
          icon: Icons.wb_sunny,
          type: GameButtonType.success,
          onPressed: () => _gameService.revealMorning(roomCode),
        ) : null,
    );

  }

  Widget _buildControlCard({
    required ThemeData theme,
    required String title,
    required List<PlayerNameItem> members,
    required Color color,
    required String? currentActiveRole,
    required VoidCallback onWake,
    required VoidCallback onSleep,
    String? targetName,
    bool showReveal = false,
    bool canSleep = true,
    VoidCallback? onReveal,
  }) {
    final bool isAwake = currentActiveRole == title.toLowerCase().replaceAll(' ', '_');

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(title, style: theme.textTheme.titleLarge?.copyWith(color: color, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              if (members.isNotEmpty)
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ...members.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final p = entry.value;
                        final roleColor = _getRoleColor(p.role);
                        final isLast = idx == members.length - 1;
                        final displayName = p.role == 'godfather' ? '${p.name} (GF)' : p.name;
                        
                        return Text(
                          "${displayName.toUpperCase()}${isLast ? '' : ', '}",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: p.isAlive ? roleColor : Colors.white24,
                            fontWeight: p.isAlive ? FontWeight.bold : FontWeight.normal,
                            decoration: p.isAlive ? null : TextDecoration.lineThrough,
                            letterSpacing: 1,
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
            ],
          ),
          if (targetName != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.gps_fixed, size: 16, color: color),
                  const SizedBox(width: 8),
                  Text("TARGET: ", style: theme.textTheme.bodySmall?.copyWith(color: color, fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Text(
                      targetName.toUpperCase(),
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (showReveal) ...[
            const SizedBox(height: 12),
            GameButton(
              label: 'REVEAL RESULT TO DETECTIVE',
              icon: Icons.visibility,
              type: GameButtonType.success,
              isCompact: true,
              onPressed: onReveal,
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GameButton(
                  label: 'WAKE',
                  type: GameButtonType.primary,
                  isCompact: true,
                  onPressed: !isAwake ? onWake : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GameButton(
                  label: (isAwake && !canSleep) ? 'WAITING...' : 'SLEEP',
                  type: GameButtonType.warning,
                  isCompact: true,
                  isLoading: isAwake && !canSleep,
                  onPressed: (isAwake && canSleep) ? onSleep : null,
                ),
              ),
            ],
          ),
        ],
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
