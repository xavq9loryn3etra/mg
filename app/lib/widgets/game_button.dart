import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum GameButtonType { primary, success, danger, warning }

class GameButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final GameButtonType type;
  final IconData? icon;

  const GameButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.type = GameButtonType.primary,
    this.icon,
  });

  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton> {
  bool _isPressed = false;

  Color get _topColor {
    if (widget.onPressed == null) return Colors.grey.shade400;
    switch (widget.type) {
      case GameButtonType.success: return const Color(0xFF2ECC71);
      case GameButtonType.danger: return const Color(0xFFD90429);
      case GameButtonType.warning: return const Color(0xFFFFB703);
      case GameButtonType.primary:
      default: return const Color(0xFF9D4EDD); 
    }
  }

  Color get _bottomColor {
    if (widget.onPressed == null) return Colors.grey.shade600;
    switch (widget.type) {
      case GameButtonType.success: return const Color(0xFF27AE60);
      case GameButtonType.danger: return const Color(0xFF8D0801);
      case GameButtonType.warning: return const Color(0xFFE5989B); 
      case GameButtonType.primary:
      default: return const Color(0xFF5A189A); 
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.type == GameButtonType.warning ? Colors.black87 : Colors.white;
    const double pushDepth = 6.0;

    return GestureDetector(
      onTapDown: widget.onPressed != null ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: widget.onPressed != null ? (_) {
        setState(() => _isPressed = false);
        widget.onPressed!();
      } : null,
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        margin: EdgeInsets.only(top: _isPressed ? pushDepth : 0, bottom: _isPressed ? 0 : pushDepth),
        decoration: BoxDecoration(
          color: _bottomColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: widget.onPressed != null && !_isPressed
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    offset: const Offset(0, 4),
                    blurRadius: 4,
                  )
                ]
              : [],
        ),
        child: Container(
          decoration: BoxDecoration(
            color: _topColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
          ),
           padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
           child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: textColor, size: 28),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                textAlign: TextAlign.center,
                style: GoogleFonts.lilitaOne(
                  fontSize: 22,
                  color: textColor,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
