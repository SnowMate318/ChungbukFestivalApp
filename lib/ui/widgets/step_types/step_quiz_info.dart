import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../data/models/survey_step_model.dart';
import '../../../config/style.dart';
import '../../controllers/survey_controller.dart';
import '../../controllers/survey_ui_controller.dart';
import 'package:get/get.dart';

class QuizInfoView extends StatelessWidget {
  final SurveyStepModel step;
  final surveyController = Get.find<SurveyController>();
  final uiController = Get.find<SurveyUiController>();

  QuizInfoView({super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    final imageUrl = step.extraData?['imageUrl'];
    final accentColor = _getAccentColor(step.extraData?['accentColor']);

    return Container(
      width: double.infinity, // ✅ 화면 전체 너비
      height: double.infinity, // ✅ 화면 전체 높이
      color: HColor.gray1, // ✅ 원하는 배경색 지정
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              step.title ?? '',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            if (imageUrl != null)
              Image.asset(
                imageUrl,
                width: 250.w,
                fit: BoxFit.contain,
              ),
            SizedBox(height: 20.h),
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
                  if (nextId == 'start') {
                    surveyController.reset();
                    Get.offAllNamed('/intro');
                    print('Navigating to Intro');
                  } else {
                    uiController.onNext(nextId);
                    print('Next step → $nextId');
                  }
                }
              },
              child: Text(
                step.actions?.first.text ?? '다음',
                style: TextStyle(
                  fontSize: 5.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Color _getAccentColor(String? key) {
    switch (key) {
      case 'green':
        return HColor.green2;
      case 'red':
        return const Color.fromARGB(255, 235, 91, 91);
      default:
        return HColor.black;
    }
  }
}
