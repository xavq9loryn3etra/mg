import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/room_provider.dart';
import '../providers/player_provider.dart';
import '../providers/game_provider.dart';
import '../services/game_service.dart';
import '../widgets/game_button.dart';
import '../widgets/glass_card.dart';
import '../widgets/mafia_loader.dart';
import '../widgets/game_layout.dart';
import '../widgets/game_app_bar.dart';
import '../widgets/day_header.dart';
import '../providers/auth_provider.dart';
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

      if (newStatus == 'night') {
        context.go('/night/$roomCode');
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







    return GameLayout(
      scrollable: isHost || roomAsync.asData?.value?.status == 'voting',
      appBar: GameAppBar(
        title: isHost ? 'TOWN CONTROL' : 'THE DAY',
        roomCode: widget.roomCode,
        isHost: isHost,
      ),
      content: roomAsync.when(
        data: (room) {
          if (room == null) return const Center(child: Text("Loading..."));

          final votesRaw = room.votes;
          final voteCount = votesRaw.length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              const Center(child: DayHeader()),
              const SizedBox(height: 32),
              
              GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                borderColor: AppTheme.accent.withValues(alpha: 0.5),
                child: Column(
                  children: [
                    Text(
                      "MORNING REPORT",
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppTheme.accent,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      room.morningAnnouncement ?? 'THE SUN RISES OVER PURPLE TOWN',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              if (room.status == 'voting') ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('TOWN HALL MEETING', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    if (isHost)
                      playersAsync.maybeWhen(
                        data: (players) {
                          final aliveCount = players.values.where((p) => p.isAlive).length;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.5)),
                            ),
                            child: Text(
                              "VOTES: $voteCount / $aliveCount",
                              style: theme.textTheme.labelLarge?.copyWith(color: AppTheme.primary, fontWeight: FontWeight.bold),
                            ),
                          );
                        },
                        orElse: () => const SizedBox.shrink(),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Cast your vote on who to exile from the village.', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white54)),
                const SizedBox(height: 24),
                playersAsync.when(
                  data: (playersMap) {
                    final alivePlayers = playersMap.values.where((p) => p.isAlive).toList();
                    final myPlayer = ref.watch(myPlayerProvider).value;
                    final isAlive = myPlayer?.isAlive ?? true;
                    final currentUid = ref.read(authStateProvider).value?.uid;
                    final myVoteTargetId = votesRaw[currentUid];

                    // Tally votes and group voter names
                    final tallies = <String, List<String>>{};
                    for (var entry in votesRaw.entries) {
                      final voterId = entry.key;
                      final targetId = entry.value;
                      final voterName = playersMap[voterId]?.name ?? "Unknown";
                      tallies.putIfAbsent(targetId, () => []).add(voterName);
                    }

                    // Find who is leading (for Narrator/Drama)
                    String? leaderId;
                    int maxVotes = 0;
                    tallies.forEach((id, voters) {
                      if (voters.length > maxVotes) {
                        maxVotes = voters.length;
                        leaderId = id;
                      } else if (voters.length == maxVotes) {
                         leaderId = null; // Tie
                      }
                    });

                    return Column(
                      children: [
                        if (!isAlive) ...[
                          Text('SPECTATING', style: theme.textTheme.displaySmall?.copyWith(color: Colors.white24, letterSpacing: 4)),
                          const SizedBox(height: 16),
                          GlassCard(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              "You are observing the Town Hall from beyond the grave. You cannot vote, but you can watch the fallout.",
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: alivePlayers.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final player = alivePlayers[index];
                            final isMe = player.id == currentUid;
                            final isMyChoice = myVoteTargetId == player.id;
                            final voters = tallies[player.id] ?? [];
                            final hasVotes = voters.isNotEmpty;
                            final isLeading = player.id == leaderId && hasVotes;

                            return GestureDetector(
                              onTap: (isMe || myVoteTargetId != null || isHost || !isAlive) ? null : () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text("CONFIRM VOTE", style: theme.textTheme.displayMedium),
                                    content: Text("Are you sure you want to vote to exile ${player.name}?", textAlign: TextAlign.center),
                                    actions: [
                                      GameButton(label: "CANCEL", type: GameButtonType.warning, onPressed: () => Navigator.pop(ctx, false)),
                                      GameButton(label: "YES, EXILE", type: GameButtonType.danger, onPressed: () => Navigator.pop(ctx, true)),
                                    ],
                                  )
                                );

                                if (confirmed != true) return;

                                try {
                                  await _gameService.submitVote(roomCode, player.id);
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                                  }
                                }
                              },
                              child: GlassCard(
                                padding: const EdgeInsets.all(16),
                                borderColor: isMyChoice 
                                    ? AppTheme.success 
                                    : (isLeading ? AppTheme.primary : Colors.white10),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                player.name,
                                                style: theme.textTheme.titleLarge?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: isMe ? Colors.white38 : Colors.white,
                                                ),
                                              ),
                                              if (isMe) ...[
                                                const SizedBox(width: 8),
                                                const Text("(YOU)", style: TextStyle(color: Colors.white24, fontSize: 12)),
                                              ],
                                              if (isMyChoice) ...[
                                                const SizedBox(width: 12),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.success.withValues(alpha: 0.2),
                                                    borderRadius: BorderRadius.circular(4),
                                                    border: Border.all(color: AppTheme.success.withValues(alpha: 0.5)),
                                                  ),
                                                  child: const Text("YOUR CHOICE", style: TextStyle(color: AppTheme.success, fontSize: 10, fontWeight: FontWeight.bold)),
                                                ),
                                              ],
                                            ],
                                          ),
                                          if (hasVotes) ...[
                                            const SizedBox(height: 8),
                                            Wrap(
                                              spacing: 4,
                                              runSpacing: 4,
                                              children: voters.map((v) => Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withValues(alpha: 0.05),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(v, style: const TextStyle(color: Colors.white38, fontSize: 10)),
                                              )).toList(),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    if (hasVotes)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: isLeading ? AppTheme.primary.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: isLeading ? AppTheme.primary.withValues(alpha: 0.5) : Colors.transparent),
                                        ),
                                        child: Column(
                                          children: [
                                            Text(
                                              "${voters.length}",
                                              style: theme.textTheme.headlineSmall?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: isLeading ? AppTheme.primary : Colors.white70,
                                              ),
                                            ),
                                            Text(
                                              voters.length == 1 ? "VOTE" : "VOTES",
                                              style: TextStyle(
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold,
                                                color: isLeading ? AppTheme.primary : Colors.white38,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        if (!isAlive) ...[
                          const SizedBox(height: 32),
                          GameButton(
                            label: "LEAVE SESSION",
                            icon: Icons.logout,
                            type: GameButtonType.danger,
                            onPressed: () => _gameService.leaveSession(),
                          ),
                          const SizedBox(height: 48),
                        ],
                      ],
                    );
                  },
                  loading: () => const MafiaLoader(),
                  error: (e, st) => Text('Error: $e'),
                ),
              ] else if (!isHost) ...[
                const SizedBox(height: 40),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.forum_rounded, size: 80, color: Colors.white24),
                      const SizedBox(height: 24),
                      Text("OPEN DISCUSSION", style: theme.textTheme.displaySmall),
                      const SizedBox(height: 12),
                      const Text(
                        "Talk amongst yourselves. Narrator will open the voting session when ready.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
        loading: () => const MafiaLoader(message: 'Loading day...'),
        error: (e, st) => Text('Error: $e'),
      ),
      bottom: isHost ? roomAsync.maybeWhen(
        data: (room) {
          if (room == null) return null;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (room.status == 'day') ...[
                GameButton(
                  label: 'OPEN VILLAGE VOTING',
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
                  label: 'RESOLVE & END DAY',
                  icon: Icons.gavel,
                  type: GameButtonType.danger,
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text("RESOLVE VOTES", style: theme.textTheme.displayMedium),
                        content: const Text("Ending the day will eliminate the player with the most votes. Proceed?", textAlign: TextAlign.center),
                        actions: [
                          GameButton(label: "WAIT", type: GameButtonType.warning, onPressed: () => Navigator.pop(ctx, false)),
                          GameButton(label: "RESOLVE", type: GameButtonType.primary, onPressed: () => Navigator.pop(ctx, true)),
                        ],
                      )
                    );
                    if (confirmed == true) {
                      _gameService.resolveVotes(roomCode);
                    }
                  },
                ),
              ],
            ],
          );
        },
        orElse: () => null,
      ) : null,
    );

  }
}
