import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme.dart';

class RoomCodeInput extends StatefulWidget {
  final Function(String) onCodeChanged;
  final TextEditingController controller;

  const RoomCodeInput({
    super.key,
    required this.onCodeChanged,
    required this.controller,
  });

  @override
  State<RoomCodeInput> createState() => RoomCodeInputState();
}

class RoomCodeInputState extends State<RoomCodeInput> {
  late List<FocusNode> _focusNodes;
  late List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(5, (_) => FocusNode());
    _controllers = List.generate(5, (_) => TextEditingController());

    // Initialize with current controller value if any
    for (int i = 0; i < widget.controller.text.length && i < 5; i++) {
        _controllers[i].text = widget.controller.text[i];
    }
  }

  @override
  void dispose() {
    for (var node in _focusNodes) {
      node.dispose();
    }
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void focusFirst() {
    _focusNodes[0].requestFocus();
  }

  void _updateParent() {
    final code = _controllers.map((c) => c.text).join();
    widget.controller.text = code;
    widget.onCodeChanged(code);
  }

  void _onChanged(String value, int index) {
    if (value.isNotEmpty) {
      // Force uppercase
      final upper = value.toUpperCase();
      
      // Filter ambiguous characters (I, O, 0, 1)
      if (RegExp(r'[A-HJ-NP-Z2-9]').hasMatch(upper)) {
        setState(() {
          _controllers[index].text = upper;
        });
        
        if (index < 4) {
          _focusNodes[index + 1].requestFocus();
        }
      } else {
        // Clear if invalid
        _controllers[index].clear();
      }
    }
    _updateParent();
  }

  void _handleKeyPress(KeyEvent event, int index) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_controllers[index].text.isEmpty && index > 0) {
        _focusNodes[index - 1].requestFocus();
        _controllers[index - 1].clear();
        _updateParent();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(5, (index) {
        return Container(
          width: 50,
          height: 60,
          decoration: BoxDecoration(
            color: AppTheme.surface.withValues(alpha: 0.51),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _focusNodes[index].hasFocus ? AppTheme.accent : AppTheme.surfaceStroke.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          child: KeyboardListener(
            focusNode: FocusNode(), // Dummy for listeneing backspace even when TextField hasn't focused
            onKeyEvent: (event) => _handleKeyPress(event, index),
            child: TextField(
              focusNode: _focusNodes[index],
              controller: _controllers[index],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0,
              ),
              maxLength: 1,
              decoration: const InputDecoration(
                counterText: "",
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                filled: false, // Ensure we don't use the theme's default fill
              ),
              onChanged: (val) => _onChanged(val, index),
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.characters,
            ),
          ),
        );
      }),
    );
  }
}
