import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:greenfestival/ui/controllers/survey_controller.dart';

class NicknameBadge extends StatelessWidget {
  const NicknameBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SurveyController>();

    return Obx(() {
      final nickname = controller.nickname.value;
      if (nickname.isEmpty) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF4B9238), width: 1.2),
        ),
        child: Text(
          '$nickname님',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF347C2A),
            fontSize: 14,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
      );
    });
  }
}
