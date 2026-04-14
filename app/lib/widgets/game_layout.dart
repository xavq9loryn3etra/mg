import 'package:flutter/material.dart';
import 'gamified_screen.dart';

class GameLayout extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget content;
  final Widget? bottom;
  final EdgeInsetsGeometry contentPadding;
  final bool scrollable;

  const GameLayout({
    super.key,
    this.appBar,
    required this.content,
    this.bottom,
    this.contentPadding = const EdgeInsets.all(24.0),
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    return GamifiedScreen(
      appBar: appBar,
      child: Column(
        children: [
          Expanded(
            child: scrollable 
              ? Scrollbar(
                  child: SingleChildScrollView(
                    padding: contentPadding,
                    child: content,
                  ),
                )
              : Padding(
                  padding: contentPadding,
                  child: content,
                ),
          ),
          if (bottom != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: bottom!,
            ),
        ],
      ),
    );
  }
}
