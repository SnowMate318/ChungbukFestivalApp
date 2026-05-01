import 'package:flutter/material.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/survey_step_model.dart';
import '../widgets/step_types/step_single_row.dart';
import '../widgets/step_types/step_double_row.dart';
import '../widgets/step_types/step_order_complete.dart';
import '../widgets/step_types/step_content_order.dart';
import '../widgets/step_types/step_order_confirm.dart';
import '../widgets/step_types/step_quiz_info.dart';
import '../widgets/step_types/step_final_complete.dart';

/// 🧭 Survey Step 라우팅 허브
/// 각 Step의 type에 맞는 위젯을 반환
Widget getStepWidget(SurveyStepModel step, {String? previousStepId}) {
  switch (step.type) {
    case StepType.singleRowSelection:
    case StepType.multiRowSelection:
    case StepType.quizSelection:
      return StepSingleRow(step: step);

    case StepType.doubleRowSelection:
      return StepDoubleRow(step: step);

    case StepType.contentOrderSelection:
      return StepContentOrder(step: step);

    case StepType.orderConfirm:
      return StepOrderConfirm(step: step);

    case StepType.orderComplete:
      return StepOrderComplete(step: step);

    case StepType.quizInfo:
      return QuizInfoView(step: step);

    case StepType.finalComplete:
      // ✅ 이전 스텝 ID를 전달
      return StepFinalCompleteView(
        step: step,
        previousStepId: previousStepId ?? '',
      );

    default:
      return const SizedBox.shrink();
  }
}
