import 'package:flutter/material.dart';
import '../theme.dart';

class DayHeader extends StatefulWidget {
  const DayHeader({super.key});

  @override
  State<DayHeader> createState() => _DayHeaderState();
}

class _DayHeaderState extends State<DayHeader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2).chain(CurveTween(curve: Curves.easeInOut)), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 50),
    ]).animate(_controller);

    _rotationAnimation = Tween<double>(begin: 0, end: 2 * 3.14159).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Glow effect
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accent.withValues(alpha: 0.3 * _pulseAnimation.value),
                    blurRadius: 40 * _pulseAnimation.value,
                    spreadRadius: 10 * _pulseAnimation.value,
                  ),
                ],
              ),
            ),
            // Rotating rays / outer shine
            Transform.rotate(
              angle: _rotationAnimation.value,
              child: Icon(
                Icons.wb_sunny_outlined,
                size: 90 * _pulseAnimation.value,
                color: AppTheme.accent.withValues(alpha: 0.5),
              ),
            ),
            // The Sun core
            Icon(
              Icons.wb_sunny_rounded,
              size: 70 * _pulseAnimation.value,
              color: AppTheme.accent,
            ),
          ],
        );
      },
    );
  }
}
