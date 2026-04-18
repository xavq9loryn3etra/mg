import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/player_provider.dart';
import '../providers/game_provider.dart';
import '../widgets/game_button.dart';
import '../widgets/mafia_loader.dart';
import '../widgets/glass_card.dart';
import '../widgets/game_layout.dart';
import '../widgets/game_app_bar.dart';
import '../theme.dart';

import '../providers/auth_provider.dart';
import '../providers/room_provider.dart';
import '../services/game_service.dart';



class RoleRevealScreen extends ConsumerStatefulWidget {
  final String roomCode;
  const RoleRevealScreen({super.key, required this.roomCode});

  @override
  ConsumerState<RoleRevealScreen> createState() => _RoleRevealScreenState();
}

class _RoleRevealScreenState extends ConsumerState<RoleRevealScreen> {
  final _gameService = GameService();
  bool _revealed = false;
  bool _hasRevealed = false;

  @override
  Widget build(BuildContext context) {
    final isHost = ref.watch(isNarratorProvider);
    final myPlayerAsync = ref.watch(myPlayerProvider);
    var theme = Theme.of(context);


    // Listen for room status changes (Reset by Narrator)
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

      // HARDENED IDENTITY CHECK: Use data from stream instead of reactive provider
      final currentUid = ref.read(authStateProvider).value?.uid;
      final isReallyHost = nextData.hostId == currentUid;

      if (newStatus == 'lobby' && !isReallyHost) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Game ended by narrator.')),
          );
          context.go('/waiting/${widget.roomCode}');
        }
      } else if (newStatus == 'game_over') {
        if (context.mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          if (nextData.winner != null) {
            context.go('/gameover/${widget.roomCode}');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Game terminated by host.')),
            );
            context.go('/');
          }
        }
      }
    });





    return GameLayout(
      scrollable: isHost, // Host sees list (scrollable), Player sees reveal (not scrollable)
      appBar: GameAppBar(
        title: isHost ? "ROLES ASSIGNED!" : "YOUR ROLE",
        roomCode: widget.roomCode,
        isHost: isHost,
      ),
      content: isHost 
          ? ref.watch(allPlayersProvider).when(
              data: (playersMap) {
                final players = playersMap.values.toList();
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: players.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final player = players[index];
                    final roleIcon = _getRoleIcon(player.role);
                    final roleColor = _getRoleColor(player.role);

                    return GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      borderColor: player.isAbandoned == true
                          ? Colors.grey.withValues(alpha: 0.3)
                          : player.isReady == true
                          ? AppTheme.success.withValues(alpha: 0.5)
                          : AppTheme.danger.withValues(alpha: 0.3),
                      child: Opacity(
                        opacity: player.isAbandoned == true ? 0.5 : 1.0,
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: roleColor.withValues(alpha: 0.2),
                              child: Icon(roleIcon, color: roleColor, size: 20),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    player.name.toUpperCase(),
                                    style: theme.textTheme.titleMedium?.copyWith(letterSpacing: 1),
                                  ),
                                  Text(
                                    player.role.replaceAll('_', ' ').toUpperCase(),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: player.isAbandoned == true ? Colors.grey : roleColor,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              player.isAbandoned == true
                                  ? Icons.person_off
                                  : player.isReady == true
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color: player.isAbandoned == true
                                  ? Colors.grey
                                  : player.isReady == true
                                  ? AppTheme.success
                                  : AppTheme.danger,
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const MafiaLoader(),
              error: (e, _) => Text("Error loading roles: $e"),
            )
          : myPlayerAsync.when(
              data: (me) {
                if (me == null) return const Center(child: Text("Loading..."));
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onLongPressStart: (_) => setState(() {
                    _revealed = true;
                    _hasRevealed = true;
                  }),
                  onLongPressEnd: (_) => setState(() => _revealed = false),
                  child: SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: Center(
                      child: _revealed
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('YOU ARE', style: theme.textTheme.titleLarge?.copyWith(letterSpacing: 4)),
                                const SizedBox(height: 16),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    me.role.replaceAll('_', ' ').toUpperCase(),
                                    style: theme.textTheme.displayLarge?.copyWith(
                                      color: _getRoleColor(me.role),
                                      fontSize: 64,
                                      shadows: [
                                        Shadow(
                                          color: _getRoleColor(me.role).withValues(alpha: 0.5),
                                          blurRadius: 20,
                                        ),
                                      ],
                                    ),
                                  ),
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
                                      child: const Icon(Icons.fingerprint, size: 100, color: AppTheme.accent),
                                    );
                                  },
                                ),
                                const SizedBox(height: 24),
                                Text('PRESS AND HOLD', style: theme.textTheme.displayMedium),
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

      bottom: isHost 
          ? ref.watch(allPlayersProvider).maybeWhen(
              data: (playersMap) {
                final players = playersMap.values.toList();
                final activePlayers = players.where((p) => p.isAbandoned != true).toList();
                final allReady = activePlayers.every((p) => p.isReady == true);
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      allReady ? "EVERYONE IS READY!" : "Waiting for players...",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: allReady ? AppTheme.success : Colors.white54,
                        fontWeight: allReady ? FontWeight.bold : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    GameButton(
                      label: allReady ? "PROCEED TO NIGHT" : "WAITING FOR ROLES...",
                      icon: allReady ? Icons.dark_mode : Icons.hourglass_empty,
                      type: allReady ? GameButtonType.primary : GameButtonType.warning,
                      onPressed: allReady ? () => context.go('/night/${widget.roomCode}') : null,
                    ),
                  ],
                );
              },
              orElse: () => null,
            )
          : myPlayerAsync.maybeWhen(
              data: (me) => GameButton(
                label: "I'M READY",
                icon: Icons.check,
                type: _hasRevealed ? GameButtonType.success : GameButtonType.warning,
                onPressed: _hasRevealed ? () async {
                  await _gameService.setPlayerReady(widget.roomCode);
                  if (context.mounted) {
                    context.go('/night/${widget.roomCode}');
                  }
                } : null,
              ),
              orElse: () => null,
            ),
    );
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'godfather':
        return Icons.gavel;
      case 'mafia':
        return Icons.masks;
      case 'doctor':
        return Icons.health_and_safety;
      case 'rabid_dog':
        return Icons.pets;
      case 'detective':
        return Icons.search_rounded;
      default:
        return Icons.person;
    }
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
