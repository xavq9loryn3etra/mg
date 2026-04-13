import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/player_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/room_provider.dart';
import '../services/game_service.dart';
import '../widgets/gamified_screen.dart';
import '../widgets/glass_card.dart';
import '../widgets/game_button.dart';
import '../theme.dart';

class WaitingScreen extends ConsumerStatefulWidget {
  final String roomCode;

  const WaitingScreen({super.key, required this.roomCode});

  @override
  ConsumerState<WaitingScreen> createState() => _WaitingScreenState();
}

class _WaitingScreenState extends ConsumerState<WaitingScreen> {
  final _gameService = GameService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currentRoomCodeProvider.notifier).setCode(widget.roomCode);
    });
  }

  void _showExitConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Leave Game?', style: Theme.of(context).textTheme.displayMedium),
        content: Text(
          'Are you sure you want to cancel your join request?',
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
            label: 'LEAVE',
            type: GameButtonType.primary,
            onPressed: () async {
              Navigator.of(ctx).pop();
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

    // Also check if we were rejected (removed from pending list)
    ref.listen(pendingPlayersProvider, (prev, next) {
      if (uid != null && next.value != null && prev?.value != null) {
        if (prev!.value!.containsKey(uid) && !next.value!.containsKey(uid)) {
          // If we are no longer pending, but we aren't in players (checked above), maybe we got rejected?
          // The router guard might handle this if our session got deleted, but let's be safe:
          final players = ref.read(playerNamesProvider).value;
          if (players != null && !players.containsKey(uid)) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Your request to join was rejected.')),
            );
            context.go('/');
          }
        }
      }
    });

    return GamifiedScreen(
      appBar: AppBar(
        title: Text('JOINING...', style: theme.textTheme.displayMedium),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: AppTheme.danger),
            onPressed: () => _showExitConfirmation(context),
          ),
        ],
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'MAFIA: PURPLE TOWN',
                style: theme.textTheme.displayLarge?.copyWith(
                  fontSize: 32,
                  letterSpacing: 3,
                ),
                textAlign: TextAlign.center,
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
        ),
      ),
    );
  }
}
