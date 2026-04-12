import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';

class GamifiedScreen extends StatelessWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;

  const GamifiedScreen({super.key, required this.child, this.appBar});

  @override
  Widget build(BuildContext context) {
    // Make system bars transparent so gradient flows edge-to-edge
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    return Container(
      decoration: AppTheme.bgGradient,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.transparent,
        appBar: appBar,
        body: SafeArea(child: child),
      ),
    );
  }
}
