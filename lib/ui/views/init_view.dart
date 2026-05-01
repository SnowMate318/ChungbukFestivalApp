import 'package:flutter/material.dart';
import 'package:greenfestival/config/style.dart';

class InitView extends StatelessWidget {
  const InitView({super.key});

  Widget _buildTop() {
    return Container();
  }

  Widget _buildMiddle() {
    return Container();
  }

  Widget _buildBottom() {
    return Container();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '습관',
          style: HText.body1SB.copyWith(color: HColor.primary6),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildTop(),
            _buildMiddle(),
            _buildBottom(),
          ],
        ),
      ),
    );
  }
}
