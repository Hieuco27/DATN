import 'package:flutter/material.dart';

class AppGradientBackground extends StatelessWidget {
  final Widget? child;
  final Gradient? gradient;

  const AppGradientBackground({super.key, this.child, this.gradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient:
            gradient ??
            const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color.fromARGB(255, 250, 229, 194), Color(0xFFFFFFFF)],
            ),
      ),
      child: child,
    );
  }
}
