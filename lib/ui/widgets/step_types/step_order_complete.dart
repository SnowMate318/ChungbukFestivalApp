import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../data/models/survey_step_model.dart';
import '../../../config/style.dart';
import '../../controllers/survey_ui_controller.dart';

class StepOrderComplete extends StatelessWidget {
  final SurveyStepModel step;
  final uiController = Get.find<SurveyUiController>();

  StepOrderComplete({super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    final imageUrl = step.extraData?['imageUrl'];

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 10.w),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 20.w),

          // === 콘텐츠 구조 ===
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                step.title ?? '',
                style: TextStyle(
                  fontSize: 8.sp,
                  fontWeight: FontWeight.bold,
                  color: HColor.black,
                ),
              ),
              SizedBox(height: 30.h),
              if (imageUrl != null)
                Image.asset(
                  imageUrl,
                  width: 200.w,
                  fit: BoxFit.contain,
                ),

              SizedBox(height: 80.h),
              // === 버튼 그룹 ===
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ✅ 첫 번째 버튼 (예: "네 참여할게요")
                  _buildActionButton(
                    step.actions?[0].text ?? '',
                    HColor.blue1,
                    Colors.white,
                    onPressed: () {
                      final nextStepId = step.actions?[0].nextStepId;
                      if (nextStepId != null && nextStepId.isNotEmpty) {
                        uiController.onNext(nextStepId);
                      }
                    },
                  ),

                  SizedBox(width: 16.w),

                  // ✅ 두 번째 버튼 (예: "아니요 괜찮아요")
                  _buildActionButton(
                    step.actions?[1].text ?? '',
                    HColor.gray3,
                    HColor.white,
                    onPressed: () {
                      final nextStepId = step.actions?[1].nextStepId;
                      if (nextStepId != null && nextStepId.isNotEmpty) {
                        uiController.onNext(nextStepId);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // === 재사용 버튼 위젯 ===
  Widget _buildActionButton(
    String text,
    Color bg,
    Color textColor, {
    VoidCallback? onPressed,
    double? width,
  }) {
    return SizedBox(
      width: width ?? 100.w,
      height: 52.h,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: 5.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

}
