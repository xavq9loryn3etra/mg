import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/game_service.dart';
import '../theme.dart';
import 'game_button.dart';

class GameAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final String roomCode;
  final bool isHost;
  final List<Widget>? actions;

  const GameAppBar({
    super.key,
    required this.title,
    required this.roomCode,
    required this.isHost,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  void _showExitConfirmation(BuildContext context, WidgetRef ref) {
    final gameService = GameService();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isHost ? 'Terminate Game?' : 'Leave Game?',
          style: Theme.of(context).textTheme.displayMedium,
        ),
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
                await gameService.terminateRoom(roomCode);
                if (context.mounted) {
                  // Host goes back to lobby (which resets to lobby state) or home?
                  // Usually terminateRoom sets status to 'lobby' so host stays in lobby flow?
                  // Actually, for a clean restart, we often go to /lobby/roomCode
                  context.go('/lobby/$roomCode');
                }
              } else {
                await gameService.leaveRoom(roomCode);
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
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return AppBar(
      title: Text(
        title.toUpperCase(),
        style: theme.textTheme.displayMedium?.copyWith(fontSize: 24),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: context.canPop() ? IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () => context.pop(),
      ) : null,
      actions: [
        if (actions != null) ...actions!,
        IconButton(
          icon: const Icon(Icons.exit_to_app, color: AppTheme.danger),
          onPressed: () => _showExitConfirmation(context, ref),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
