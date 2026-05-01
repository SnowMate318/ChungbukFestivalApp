import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../controllers/survey_controller.dart';
import '../controllers/survey_ui_controller.dart';
import '../../config/style.dart';
import '../widgets/nickname_badge.dart';
import '../widgets/start_over_button.dart';
import 'survey_step_content.dart';

class SurveyView extends StatelessWidget {
  final surveyController = Get.put(SurveyController());
  final uiController = Get.put(SurveyUiController());

  SurveyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HColor.white,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: 24.h),

                // ===== 상단 KRISO 로고 =====
                Center(
                  child: Image.asset(
                    'assets/images/title_logo.png',
                    height: 40.h,
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(height: 16.h),

                // ===== 설문 본문 =====
                Expanded(
                  child: Obx(() {
                    final currentStep = surveyController.currentStep;
                    // ✅ 현재 스텝 ID 출력 (step 변경 시마다 한 번만 찍힘)
                    debugPrint('🟩 Current Step ID: ${currentStep.id}');

                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: SurveyStepContent(
                        key: ValueKey(currentStep.id),
                        step: currentStep,
                      ),
                    );
                  }),
                ),

                // ===== 하단 KRISO 바 =====
                Container(
                  height: 60.h,
                  color: HColor.pink1,
                  alignment: Alignment.center,
                  child: Image.asset(
                    'assets/images/kriso_logo.png',
                    height: 40.h,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
            top: 18,
            right: 18,
            child: SafeArea(child: NicknameBadge()),
          ),
          const Positioned(
            left: 18,
            bottom: 18,
            child: SafeArea(child: StartOverButton()),
          ),
        ],
      ),
    );
  }
}
