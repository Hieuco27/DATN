import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

Route<T> buildSharedAxisDetailRoute<T>({
  required Widget page,
  SharedAxisTransitionType type = SharedAxisTransitionType.horizontal,
}) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SharedAxisTransition(
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        transitionType: type,
        child: child,
      );
    },
  );
}
