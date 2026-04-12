import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/game_service.dart';
import '../providers/room_provider.dart';
import '../widgets/gamified_screen.dart';
import '../widgets/game_button.dart';
import '../widgets/glass_card.dart';
import '../theme.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _createNameController = TextEditingController();
  final _joinNameController = TextEditingController();
  final _roomCodeController = TextEditingController();
  final _gameService = GameService();
  bool _isLoading = true; // start loading while checking session

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    try {
      final code = await _gameService.checkActiveSession();
      if (code != null && mounted) {
        ref.read(currentRoomCodeProvider.notifier).setCode(code);
        context.go('/lobby/$code');
        return;
      }
    } catch (e) {
      debugPrint("Session check failed: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createRoom() async {
    final name = _createNameController.text.trim();
    if (name.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your host name')),
        );
      }
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      final code = await _gameService.createRoom(name);
      if (mounted) {
        ref.read(currentRoomCodeProvider.notifier).setCode(code);
        context.go('/lobby/$code');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _joinRoom() async {
    final name = _joinNameController.text.trim();
    final code = _roomCodeController.text.trim().toUpperCase();
    
    if (name.isEmpty || code.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter both name and room code')),
        );
      }
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      await _gameService.joinRoom(code, name);
      if (mounted) {
        ref.read(currentRoomCodeProvider.notifier).setCode(code);
        context.go('/waiting/$code');
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Join Error', textAlign: TextAlign.center),
            content: Text(e.toString(), textAlign: TextAlign.center),
            actions: [
              GameButton(
                label: 'OK', 
                onPressed: () => Navigator.of(ctx).pop(),
                type: GameButtonType.warning,
              )
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    
    if (_isLoading) {
      return const GamifiedScreen(
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.accent),
        ),
      );
    }

    return GamifiedScreen(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'MAFIA GO',
                      style: theme.textTheme.displayLarge?.copyWith(
                        letterSpacing: 8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    
                    // CREATE ROOM CARD
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'HOST A NEW GAME',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppTheme.accent,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _createNameController,
                            decoration: const InputDecoration(
                              labelText: 'Your Host Name',
                              prefixIcon: Icon(Icons.person, color: Colors.white70),
                            ),
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 24),
                          GameButton(
                            icon: Icons.add_circle_outline,
                            onPressed: _isLoading ? null : _createRoom,
                            label: 'CREATE ROOM',
                            type: GameButtonType.primary,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // JOIN ROOM CARD
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'JOIN EXISTING GAME',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppTheme.success,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _joinNameController,
                            decoration: const InputDecoration(
                              labelText: 'Your Player Name',
                              prefixIcon: Icon(Icons.person_outline, color: Colors.white70),
                            ),
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _roomCodeController,
                            decoration: const InputDecoration(
                              labelText: 'Room Code (e.g. ABCDE)',
                              prefixIcon: Icon(Icons.meeting_room, color: Colors.white70),
                            ),
                            textCapitalization: TextCapitalization.characters,
                            maxLength: 5,
                          ),
                          const SizedBox(height: 16),
                          GameButton(
                            icon: Icons.login,
                            onPressed: _isLoading ? null : _joinRoom,
                            label: 'JOIN ROOM',
                            type: GameButtonType.success,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: TextButton.icon(
                        onPressed: () => context.push('/tutorial'),
                        icon: const Icon(Icons.help_outline, size: 18),
                        label: const Text('How to Play'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ); // Closes GamifiedScreen
} // Closes build method
} // Closes class
