import 'package:flutter/material.dart';
import '../theme.dart';

/// A mafia-themed loading indicator with a pulsing crosshair icon.
class MafiaLoader extends StatefulWidget {
  final String? message;
  const MafiaLoader({super.key, this.message});

  @override
  State<MafiaLoader> createState() => _MafiaLoaderState();
}

class _MafiaLoaderState extends State<MafiaLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _scaleAnim = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _opacityAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnim.value,
                child: Opacity(
                  opacity: _opacityAnim.value,
                  child: const Icon(
                    Icons.track_changes,
                    size: 80,
                    color: AppTheme.accent,
                  ),
                ),
              );
            },
          ),
          if (widget.message != null) ...[
            const SizedBox(height: 24),
            Text(
              widget.message!,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white70,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
