import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';

class GamifiedScreen extends StatelessWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? drawer;

  const GamifiedScreen({
    super.key,
    required this.child,
    this.appBar,
    this.drawer,
  });

  @override
  Widget build(BuildContext context) {
    // Re-assert immersive mode on every build to keep the app full-screen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    // Explicitly set system overlays to transparent
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Colors.transparent,
    ));

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: AppTheme.bgGradient,
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true, 
          extendBody: true,
          appBar: appBar,
          drawer: drawer,
          body: SafeArea(
            // Protect content while allowing background to bleed
            child: child,
          ),
        ),
      ),
    );
  }
}
