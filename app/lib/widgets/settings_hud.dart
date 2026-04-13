import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/audio_provider.dart';
import '../theme.dart';

class SettingsHUD extends ConsumerWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final VoidCallback onToggle;

  const SettingsHUD({
    super.key,
    required this.isOpen,
    required this.onClose,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMuted = ref.watch(isMutedProvider);
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    // Sync with GlassCard's radius and closed position
    // Adjusted so the higher banner remains as the handle peek
    final closedTop = -165.0;

    return Stack(
      children: [
        // LAYER 1: THE SCRIM
        IgnorePointer(
          ignoring: !isOpen,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 400),
            opacity: isOpen ? 1 : 0,
            child: GestureDetector(
              onTap: onClose,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black.withOpacity(0.6),
              ),
            ),
          ),
        ),

        // LAYER 2: THE HUD PANEL
        AnimatedPositioned(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutQuart,
          top: isOpen ? 0 : closedTop,
          left: 0,
          right: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: onToggle,
                onVerticalDragUpdate: (details) {
                  if (details.primaryDelta! > 5 && !isOpen) onToggle();
                  if (details.primaryDelta! < -5 && isOpen) onToggle();
                },
                behavior: HitTestBehavior.opaque,
                child: CustomPaint(
                  painter: _HUDBorderPainter(
                    color: AppTheme.surfaceStroke,
                    radius: 24,
                    width: 3,
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(24),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        width: screenWidth,
                        padding: EdgeInsets.fromLTRB(
                          24,
                          MediaQuery.of(context).padding.top + 16,
                          24,
                          12,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surface.withOpacity(0.85),
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(24),
                          ),
                        ),
                        child: Column(
                          children: [
                            // Setting Items
                            _HUDItem(
                              icon: isMuted
                                  ? Icons.volume_off_rounded
                                  : Icons.volume_up_rounded,
                              label: 'Ambient Sound',
                              trailing: Switch(
                                value: !isMuted,
                                onChanged: (_) {
                                  ref.read(isMutedProvider.notifier).toggle();
                                  ref.read(soundServiceProvider).updateVolume();
                                },
                                activeThumbColor: AppTheme.accent,
                              ),
                              onTap: () {
                                ref.read(isMutedProvider.notifier).toggle();
                                ref.read(soundServiceProvider).updateVolume();
                              },
                            ),

                            _HUDItem(
                              icon: Icons.help_outline_rounded,
                              label: 'How to Play',
                              onTap: () {
                                onClose();
                                context.push('/tutorial');
                              },
                            ),

                            const SizedBox(height: 16),

                            // BRANDED BANNER
                            Image.asset(
                              'assets/banner.png',
                              height: 60,
                              fit: BoxFit.contain,
                            ),

                            const SizedBox(height: 12),

                            // The Handle Pill UI
                            Center(
                              child: Container(
                                width: 36,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            ],
          ),
        ),
      ],
    );
  }
}

class _HUDBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double width;

  _HUDBorderPainter({
    required this.color,
    required this.radius,
    required this.width,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;

    final path = Path();
    // Start at bottom-left curve start
    path.moveTo(0, size.height - radius);
    // Curve to bottom
    path.arcToPoint(
      Offset(radius, size.height),
      radius: Radius.circular(radius),
      clockwise: false,
    );
    // Line to bottom-right curve start
    path.lineTo(size.width - radius, size.height);
    // Curve to bottom-right side
    path.arcToPoint(
      Offset(size.width, size.height - radius),
      radius: Radius.circular(radius),
      clockwise: false,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HUDBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.radius != radius ||
        oldDelegate.width != width;
  }
}

class _HUDItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback onTap;

  const _HUDItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.surfaceStroke.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: Colors.white70, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}
