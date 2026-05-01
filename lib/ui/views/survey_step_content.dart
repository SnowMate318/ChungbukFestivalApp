
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../controllers/survey_controller.dart';
import '../../../data/models/survey_step_model.dart';
import '../../../data/models/enums.dart';
import 'survey_step_router.dart';
import '../widgets/survey_bottom_buttons.dart';
import '../widgets/survey_progress_bar.dart';
import '../../../config/style.dart';

class SurveyStepContent extends StatelessWidget {
  final SurveyStepModel step;
  final surveyController = Get.find<SurveyController>();

  SurveyStepContent({super.key, required this.step});

  @override
  Widget build(BuildContext context) {

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [

          // ===== STEP 라벨 =====
          if (step.id != 'step2-2' && step.id != 'step2-3')
            Text(
              'STEP ${step.stepNumber ?? (surveyController.currentStepIndex.value + 1)} ${step.stepLabel ?? ""}',
              style: TextStyle(
                color: HColor.black,
                fontSize: 5.sp,
                fontWeight: FontWeight.w600,
              ),
            ),

          
          SizedBox(height: 8.h),

          // ===== 진행도 바 =====
          if (step.id != 'step2-2' && step.id != 'step2-3')
            const SurveyProgressBar(),

          SizedBox(height: 16.h),

          // ===== 메인 콘텐츠 (StepType별 위젯 호출) =====
          Flexible(
            fit: FlexFit.loose,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: getStepWidget(
                  step,
                  previousStepId: surveyController.previousStepId.value, // ✅ 추가
                ),
              ),
            ),
          ),



          // ===== 하단 버튼 =====
          if (!_shouldHideBottomButtons(step))
            SafeArea(
              minimum: EdgeInsets.only(bottom: 8.h),
              child: Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: SurveyBottomButtons(step: step),
              ),
            ),
        ],
      ),
    );
  }
}

bool _shouldHideBottomButtons(SurveyStepModel step) {
  // 🔸 버튼을 숨겨야 하는 StepType 정의 (필요 시 계속 추가)
  const hiddenTypes = {
    StepType.orderConfirm,
    StepType.orderComplete,
    StepType.quizInfo,
    StepType.finalComplete,
    // StepType.resultSummary,   // 예: 나중에 결과 요약 단계도 추가될 경우
    // StepType.customEndScreen, // 예: 맞춤형 엔딩 스크린 등
  };

  return hiddenTypes.contains(step.type);
}
