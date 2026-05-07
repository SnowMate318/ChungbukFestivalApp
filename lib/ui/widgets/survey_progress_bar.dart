import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../config/style.dart';
import '../controllers/survey_controller.dart';

/// 🔹 진행도 바 (Progress Bar)
/// - stepNumber (1~4) 기준으로 활성화 표시
class SurveyProgressBar extends StatelessWidget {
  const SurveyProgressBar({super.key});

  @override
  Widget build(BuildContext context) {
    final surveyController = Get.find<SurveyController>();

    return Obx(() {
      final currentStep = surveyController.currentStep;
      final currentLevel = currentStep.stepNumber ?? 1;
      const totalLevels = 4; // ✅ 고정값

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(totalLevels, (index) {
          final level = index + 1;
          final bool isActive = level <= currentLevel;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 20.w,
            height: 3.h,
            margin: EdgeInsets.symmetric(horizontal: 1.5.w),
            decoration: BoxDecoration(
              color: isActive ? HColor.blue1 : HColor.gray3.withOpacity(0.3),
              borderRadius: BorderRadius.circular(6.r),
            ),
          );
        }),
      );
    });
  }
}
