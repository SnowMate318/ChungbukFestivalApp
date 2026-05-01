import 'package:flutter/material.dart';

class FestivalPageTitle extends StatelessWidget {
  const FestivalPageTitle(this.text, {super.key});

  final String text;

  static double topGap(double height) => (height * 0.305).clamp(165.0, 270.0);

  static double fontSize(double width) => (width * 0.0352).clamp(29.0, 42.0);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.black,
            fontSize: fontSize(constraints.maxWidth),
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        );
      },
    );
  }
}
