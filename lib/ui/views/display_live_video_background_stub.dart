import 'package:flutter/material.dart';

class DisplayLiveVideoBackground extends StatelessWidget {
  const DisplayLiveVideoBackground({
    super.key,
    required this.asset,
    required this.restartKey,
  });

  final String asset;
  final String restartKey;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/display/background.png',
      key: ValueKey(restartKey),
      fit: BoxFit.cover,
      filterQuality: FilterQuality.high,
    );
  }
}
