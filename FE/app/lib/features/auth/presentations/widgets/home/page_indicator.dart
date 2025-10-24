import 'package:flutter/material.dart';

class PageIndicator extends StatelessWidget {
  final int currentPage;
  final int totolPages;
  final Color activeColor;
  final Color inactiveColor;
  final double dotSize;
  final double spacing;

  const PageIndicator({
    super.key,
    required this.currentPage,
    required this.totolPages,
    this.activeColor = const Color.fromARGB(255, 27, 157, 244),
    this.inactiveColor = const Color.fromARGB(135, 100, 109, 118),
    this.dotSize = 8.0,
    this.spacing = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        totolPages,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(horizontal: spacing / 2),
          width: currentPage == index ? dotSize * 2 : dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            color: currentPage == index ? activeColor : inactiveColor,
            borderRadius: BorderRadius.circular(dotSize / 2),
          ),
        ),
      ),
    );
  }
}
