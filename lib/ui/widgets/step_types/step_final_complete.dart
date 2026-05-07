import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../data/models/survey_step_model.dart';
import '../../../config/style.dart';
import '../../controllers/survey_controller.dart';
import '../../controllers/survey_ui_controller.dart';
import 'package:get/get.dart';
import 'package:greenfestival/routes/app_pages.dart';
import '../../../functions/print_functions.dart';
import '../../../data/models/receipt_item.dart';

class StepFinalCompleteView extends StatelessWidget {
  final SurveyStepModel step;
  final String previousStepId;

  final surveyController = Get.find<SurveyController>();
  final uiController = Get.find<SurveyUiController>();

  // ✅ 생성자
  StepFinalCompleteView({
    super.key,
    required this.step,
    required this.previousStepId,
  });

  // ✅ 실행 여부를 static으로 관리 (모든 인스턴스 간 공유)

  @override
  Widget build(BuildContext context) {
    // ✅ 프레임이 완료된 뒤에 한 번만 실행
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!surveyController.hasSubmitted.value) {
        try {
          final middleSteps = ['step2-1', 'step2-2', 'step2-3', 'step2-4'];
          final isFinalStep = !middleSteps.contains(previousStepId);

          print('1');

          final selectedTitles = uiController.selectedTitles;

          final items = selectedTitles.asMap().entries.map((entry) {
            final index = entry.key + 1;
            final title = entry.value.isNotEmpty ? entry.value : '제목 없음';
            return ReceiptItem('$title', 1);
          }).toList();

          for (final item in items) {
            print('${item.title} (수량: ${item.qty})');
          }
          await printKrisoReceipt(items, participate: isFinalStep);

          print('3');
          print('Receipt printed. Survey JSON storage is disabled.');
        } catch (e) {
          print('Error - Firesotre: $e');
        }
      }
    });

    final imageUrl = step.extraData?['imageUrl'];
    final accentColor = _getAccentColor(step.extraData?['accentColor']);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ✅ 제목
          Text(
            step.title ?? '',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: accentColor,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2.h),

          // ✅ 이미지
          if (imageUrl != null)
            Image.asset(imageUrl, width: 250.w, fit: BoxFit.contain),

          SizedBox(height: 20.h),

          // ✅ 완료 버튼
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: HColor.blue1,
              foregroundColor: HColor.white,
              minimumSize: Size(120.w, 60.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
              ),
            ),

            onPressed: () {
              final nextId = step.actions?.first.nextStepId;
              if (nextId != null && nextId.isNotEmpty) {
                if (nextId == 'submit') {
                  surveyController.reset();
                  uiController.selectedIndexes.clear();
                  uiController.selectedTitles.clear();
                  uiController.currentPage.value = 0;
                  Get.offAllNamed(AppPages.ENDING);
                  print('Navigating to Ending after auto receipt print');
                } else {
                  uiController.onNext(nextId);
                  print('Next step → $nextId');
                }
              }
            },
            child: Text(
              step.actions?.first.text ?? '처음으로',
              style: TextStyle(fontSize: 5.sp, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Color _getAccentColor(String? key) {
    switch (key) {
      case 'green':
        return HColor.green3;
      case 'red':
        return HColor.red3;
      default:
        return HColor.black;
    }
  }
}
