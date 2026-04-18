import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/player_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/room_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/game_layout.dart';
import '../widgets/game_app_bar.dart';
import '../theme.dart';


class WaitingScreen extends ConsumerStatefulWidget {
  final String roomCode;

  const WaitingScreen({super.key, required this.roomCode});

  @override
  ConsumerState<WaitingScreen> createState() => _WaitingScreenState();
}

class _WaitingScreenState extends ConsumerState<WaitingScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currentRoomCodeProvider.notifier).setCode(widget.roomCode);
    });
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    final uid = ref.watch(authStateProvider).value?.uid;
    
    // Listen to the players list to see if we got approved
    ref.listen(playerNamesProvider, (prev, next) {
      if (uid != null && next.value != null) {
        if (next.value!.containsKey(uid)) {
          // We were approved! 
          context.go('/lobby/${widget.roomCode}');
        }
      }
    });

    // Handle room termination
    ref.listen(roomStreamProvider, (prev, next) {
      final nextData = next.asData?.value;
      if (nextData == null) return;
      
      final prevData = prev?.asData?.value;
      if (prevData == null) return;

      final oldStatus = prevData.status;
      final newStatus = nextData.status;

      if (oldStatus == newStatus) return; // No change, don't spam

      if (newStatus == 'game_over') {
        if (context.mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          if (nextData.winner != null) {
            context.go('/gameover/${widget.roomCode}');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Host cancelled the room.')),
            );
            context.go('/');
          }
        }
      }
    });





    // Also check if we were rejected (removed from pending list)
    ref.listen(pendingPlayersProvider, (prev, next) {
      if (uid != null && next.value != null && prev?.value != null) {
        if (prev!.value!.containsKey(uid) && !next.value!.containsKey(uid)) {
          // If we are no longer pending, but we aren't in players (checked above), maybe we got rejected?
          final players = ref.read(playerNamesProvider).value;
          final room = ref.read(roomStreamProvider).value;
          final isHost = room?.hostId == uid;

          if (players != null && !players.containsKey(uid) && !isHost) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Your request to join was rejected.')),
              );
              context.go('/');
            }
          }
        }
      }
    });


    return GameLayout(
      scrollable: false,
      appBar: GameAppBar(
        title: 'JOINING...',
        roomCode: widget.roomCode,
        isHost: false, // Players are waiting to join, not the host
      ),
      content: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Image.asset(
            'assets/banner.png',
            height: 120,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 32),
          GlassCard(
            child: Column(
              children: [
                const SizedBox(height: 16),
                const CircularProgressIndicator(color: AppTheme.accent),
                const SizedBox(height: 24),
                Text(
                  'WAITING FOR HOST',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.accent,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'The host must approve your request to join room ${widget.roomCode}.',
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );

  }
}
