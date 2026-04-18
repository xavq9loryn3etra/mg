import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/room_provider.dart';
import '../providers/player_provider.dart';
import '../models/player.dart';
import '../providers/game_provider.dart';
import '../models/game_config.dart';
import '../providers/auth_provider.dart';
import '../services/game_service.dart';
import '../providers/audio_provider.dart';

import '../widgets/game_button.dart';
import '../widgets/glass_card.dart';
import '../widgets/mafia_loader.dart';
import '../widgets/game_layout.dart';
import '../widgets/game_app_bar.dart';
import '../theme.dart';

class LobbyScreen extends ConsumerStatefulWidget {
  final String roomCode;
  const LobbyScreen({super.key, required this.roomCode});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  final _gameService = GameService();
  bool _isStarting = false;
  bool _initialized = false;

  // Role Toggles
  int _mafiaCount = 2;
  bool _hasGodfather = true;
  bool _hasDoctor = true;
  bool _hasDetective = true;
  bool _hasRabidDog = true;

  void _syncConfig(GameConfig config) {
    if (_initialized) return;
    setState(() {
      _mafiaCount = config.mafiaCount;
      _hasGodfather = config.hasGodfather;
      _hasDoctor = config.hasDoctor;
      _hasDetective = config.hasDetective;
      _hasRabidDog = config.hasRabidDog;
      _initialized = true;
    });
  }

  void _updateConfig() {
    _gameService.configureGame(
      widget.roomCode,
      mafiaCount: _mafiaCount,
      hasGodfather: _hasGodfather,
      hasDoctor: _hasDoctor,
      hasDetective: _hasDetective,
      hasRabidDog: _hasRabidDog,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(soundServiceProvider).stop();
      ref.read(currentRoomCodeProvider.notifier).setCode(widget.roomCode);
    });
  }

  Widget _buildPendingRequests(WidgetRef ref, ThemeData theme) {
    final pendingAsync = ref.watch(pendingPlayersProvider);

    return pendingAsync.when(
      data: (pendingMap) {
        if (pendingMap.isEmpty) return const SizedBox.shrink();

        final pending = pendingMap.entries.toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'PENDING REQUESTS',
              style: theme.textTheme.titleMedium?.copyWith(color: AppTheme.warning),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ...pending.map((entry) {
              final uid = entry.key;
              final player = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.warning.withValues(alpha: 0.5), width: 1),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(child: Text(player.name, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold))),
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: AppTheme.success),
                      onPressed: () => _gameService.approvePlayer(widget.roomCode, uid, player.name),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: AppTheme.danger),
                      onPressed: () => _gameService.rejectPlayer(widget.roomCode, uid),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roomAsync = ref.watch(roomStreamProvider);
    final isHost = ref.watch(isNarratorProvider);
    final uid = ref.watch(authStateProvider).value?.uid;
    final playersAsync = ref.watch(playerNamesProvider);
    var theme = Theme.of(context);

    // Initial sync
    roomAsync.whenData((room) {
       if (room != null && !_initialized) _syncConfig(room.config);
    });

    ref.listen(roomStreamProvider, (prev, next) {
      final nextData = next.asData?.value;
      
      // If the room node is deleted (e.g. host terminated in lobby), go home
      if (nextData == null) {
        if (context.mounted) {
          context.go('/');
        }
        return;
      }
      
      final newStatus = nextData.status;

      if (newStatus == 'night') {
        context.go('/reveal/${widget.roomCode}');
      } else if (newStatus == 'day') {
        context.go('/day/${widget.roomCode}');
      } else if (newStatus == 'game_over') {
        if (context.mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          if (nextData.winner != null) {
            context.go('/gameover/${widget.roomCode}');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Room closed by host.')));
            context.go('/');
          }
        }
      }
    });

    return GameLayout(
      appBar: GameAppBar(
        title: 'ROOM: ${widget.roomCode}',
        roomCode: widget.roomCode,
        isHost: isHost,
      ),
      content: roomAsync.when(
        data: (room) {
          if (room == null) {
            return const Center(child: Text("Room not found"));
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isHost) ...[
                GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('GAME SETTINGS', style: theme.textTheme.titleMedium?.copyWith(color: AppTheme.accent), textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      _buildRoleToggle('Godfather', _hasGodfather, (val) => setState(() { _hasGodfather = val; _updateConfig(); }), theme),
                      _buildMafiaCountSelector(theme),
                      _buildRoleToggle('Doctor', _hasDoctor, (val) => setState(() { _hasDoctor = val; _updateConfig(); }), theme),
                      _buildRoleToggle('Rabid Dog', _hasRabidDog, (val) => setState(() { _hasRabidDog = val; _updateConfig(); }), theme),
                      _buildRoleToggle('Detective', _hasDetective, (val) => setState(() { _hasDetective = val; _updateConfig(); }), theme),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildPendingRequests(ref, theme),
              ],
              playersAsync.when(
                data: (playersMap) {
                  final playersList = playersMap.entries.toList();
                  if (playersList.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32.0),
                        child: Text('Waiting for players...', style: theme.textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic, color: Colors.white54)),
                      ),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('PLAYERS JOINED', style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: playersList.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final entry = playersList[index];
                          final isMe = entry.key == uid;
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white24, width: 2),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            child: Text('${entry.value.name}${isMe ? ' (YOU)' : ''}', style: theme.textTheme.bodyLarge?.copyWith(fontSize: 20)),
                          );
                        },
                      ),
                    ],
                  );
                },
                loading: () => const MafiaLoader(),
                error: (e, st) => Text('Error: $e'),
              ),
            ],
          );
        },
        loading: () => const MafiaLoader(message: 'Loading room...'),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
      bottom: roomAsync.asData?.value != null ? _buildBottomBar(context, isHost, theme, playersAsync) : null,
    );
  }

  Widget _buildRoleToggle(String title, bool value, ValueChanged<bool> onChanged, ThemeData theme) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: theme.textTheme.bodyLarge),
      activeThumbColor: AppTheme.success,
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildMafiaCountSelector(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Mafia Members', style: theme.textTheme.bodyLarge),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  Icons.remove_circle_outline, 
                  color: _mafiaCount > 1 ? AppTheme.warning : Colors.white24
                ),
                onPressed: _mafiaCount > 1 ? () {
                  setState(() { _mafiaCount--; _updateConfig(); });
                } : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('$_mafiaCount', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  Icons.add_circle_outline, 
                  color: _mafiaCount < 5 ? AppTheme.success : Colors.white24
                ),
                onPressed: _mafiaCount < 5 ? () {
                  setState(() { _mafiaCount++; _updateConfig(); });
                } : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, bool isHost, ThemeData theme, AsyncValue<Map<String, PlayerNameItem>> playersAsync) {
    if (!isHost) {
      return SizedBox(
        height: 80,
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Center(child: Text("WAITING FOR HOST...", style: theme.textTheme.titleLarge?.copyWith(color: AppTheme.accent))),
        ),
      );
    }

    return playersAsync.when(
      data: (playersMap) {
        final playersCount = playersMap.length;
        final enabledSpecialRoles = [
          _hasGodfather, _hasDoctor, _hasDetective, _hasRabidDog
        ].where((e) => e).length;
        
        final totalRolesNeeded = enabledSpecialRoles + _mafiaCount;

        final canStart = playersCount >= totalRolesNeeded && totalRolesNeeded > 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!canStart && totalRolesNeeded > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  "Need at least $totalRolesNeeded players for current settings!",
                  style: const TextStyle(color: AppTheme.warning, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            GameButton(
              label: _isStarting ? 'STARTING...' : 'START GAME',
              icon: Icons.play_arrow_rounded,
              isLoading: _isStarting,
              type: canStart ? GameButtonType.primary : GameButtonType.warning,
              onPressed: !canStart || _isStarting ? null : () async {
                setState(() => _isStarting = true);
                try {
                  await _gameService.startGame(widget.roomCode);
                } catch (e) {
                  setState(() => _isStarting = false);
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Start Error'),
                        content: Text(e.toString()),
                        actions: [GameButton(label: 'OK', type: GameButtonType.warning, onPressed: () => Navigator.of(ctx).pop())],
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
      loading: () => const MafiaLoader(isCompact: true),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
