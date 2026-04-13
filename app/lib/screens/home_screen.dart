import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/game_service.dart';
import '../providers/room_provider.dart';
import '../widgets/gamified_screen.dart';
import '../widgets/game_button.dart';
import '../widgets/glass_card.dart';
import '../widgets/room_code_input.dart';
import '../widgets/settings_hud.dart';
import '../providers/audio_provider.dart';
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
  final _roomCodeInputKey = GlobalKey<RoomCodeInputState>();
  
  final _gameService = GameService();
  bool _isLoading = false; 
  bool _isSettingsOpen = false; 

  @override
  void initState() {
    super.initState();
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
    
    return GamifiedScreen(
      child: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24.0, 60.0, 24.0, 24.0), // Extra top padding for title
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 50),
                        
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
                    GestureDetector(
                      onTap: () {
                        // Auto-focus the first box when tapping anywhere in the card
                        _roomCodeInputKey.currentState?.focusFirst();
                      },
                      child: GlassCard(
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
                            Center(
                              child: Text(
                                'ROOM CODE',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppTheme.accent,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            RoomCodeInput(
                              key: _roomCodeInputKey,
                              controller: _roomCodeController,
                              onCodeChanged: (code) {
                                // Already handled sync in the widget
                              },
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
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      
      // SETTINGS HUD (Top Panel)
      SettingsHUD(
        isOpen: _isSettingsOpen, 
        onClose: () => setState(() => _isSettingsOpen = false),
        onToggle: () => setState(() => _isSettingsOpen = !_isSettingsOpen),
      ),
    ],
  ),
);
  }
}
