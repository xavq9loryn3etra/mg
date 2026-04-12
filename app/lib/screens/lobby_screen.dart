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

class LobbyScreen extends ConsumerStatefulWidget {
  final String roomCode;
  const LobbyScreen({super.key, required this.roomCode});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  final _gameService = GameService();
  int _mafiaCount = 1;
  bool _hasRabidDog = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
                  color: AppTheme.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.warning.withOpacity(0.5), width: 1),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        player.name,
                        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
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
            }).toList(),
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
    final playersAsync = ref.watch(playerNamesProvider);
    var theme = Theme.of(context);

    ref.listen(roomStreamProvider, (prev, next) {
      if (next.value?.status == 'night') {
        context.go('/reveal/${widget.roomCode}');
      }
    });

    return GamifiedScreen(
      appBar: AppBar(
        title: Text('ROOM: ${widget.roomCode}', style: theme.textTheme.displayMedium),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      child: roomAsync.when(
          data: (room) {
            if (room == null)
              return const Center(child: Text("Room not found"));
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isHost) ...[
                    GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'GAME SETTINGS',
                            style: theme.textTheme.titleMedium?.copyWith(color: AppTheme.accent),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Mafia Count', style: theme.textTheme.bodyLarge),
                              DropdownButton<int>(
                                value: _mafiaCount,
                                dropdownColor: AppTheme.surface,
                                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                                items: const [
                                  DropdownMenuItem(value: 1, child: Text('1')),
                                  DropdownMenuItem(value: 2, child: Text('2')),
                                ],
                                onChanged: (val) {
                                  setState(() => _mafiaCount = val!);
                                  _gameService.configureGame(
                                    widget.roomCode,
                                    _mafiaCount,
                                    _hasRabidDog,
                                  );
                                },
                              ),
                            ],
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text('Include Rabid Dog', style: theme.textTheme.bodyLarge),
                            activeColor: AppTheme.success,
                            value: _hasRabidDog,
                            onChanged: (val) {
                              setState(() => _hasRabidDog = val);
                              _gameService.configureGame(
                                widget.roomCode,
                                _mafiaCount,
                                _hasRabidDog,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildPendingRequests(ref, theme),
                  ],
                  Text(
                    'PLAYERS JOINED',
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: playersAsync.when(
                      data: (playersMap) {
                        final players = playersMap.values.toList();
                        if (players.isEmpty) {
                          return Center(
                            child: Text(
                              'Waiting for players...',
                              style: theme.textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic, color: Colors.white54),
                            )
                          );
                        }
                        return ListView.separated(
                          itemCount: players.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white24, width: 2),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              child: Text(
                                players[index].name,
                                style: theme.textTheme.bodyLarge?.copyWith(fontSize: 20),
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const MafiaLoader(),
                      error: (e, st) => Text('Error: $e'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (isHost)
                    GameButton(
                      label: 'START GAME',
                      icon: Icons.play_arrow_rounded,
                      type: GameButtonType.primary,
                      onPressed: () async {
                        try {
                          await _gameService.startGame(widget.roomCode);
                        } catch (e) {
                          if (context.mounted) {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Start Error'),
                                content: Text(e.toString()),
                                actions: [
                                  GameButton(
                                    label: 'OK',
                                    type: GameButtonType.warning,
                                    onPressed: () => Navigator.of(ctx).pop()
                                  )
                                ],
                              )
                            );
                          }
                        }
                      },
                    )
                  else
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Text(
                          "WAITING FOR HOST...",
                          style: theme.textTheme.titleLarge?.copyWith(color: AppTheme.accent),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
          loading: () => const MafiaLoader(message: 'Loading room...'),
          error: (e, st) => Center(child: Text('Error: $e')),
        ),
    );
  }
}
