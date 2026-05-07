import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../controllers/survey_ui_controller.dart';
import '../../../data/models/survey_step_model.dart';
import '../../../config/style.dart';
import '../../../data/models/enums.dart';

class SurveyBottomButtons extends StatelessWidget {
  final SurveyStepModel step;
  final uiController = Get.find<SurveyUiController>();

  SurveyBottomButtons({super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    final actions = step.actions ?? [];

    final layout = step.buttonLayout == ButtonLayoutType.centered
        ? MainAxisAlignment.center
        : MainAxisAlignment.spaceBetween;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: layout,
        children: actions.map((action) {
          final isPrimary = action.isPrimary;
          final bgColor = isPrimary ? HColor.blue1 : HColor.gray3;
          final textColor = isPrimary ? HColor.white : HColor.gray1;

          // ✅ Obx를 버튼 하나씩 감싸기 (isNextEnabled가 관여하는 버튼만)
          return SizedBox(
            width: 60.w,
            height: 50.h,
            child: isPrimary
                ? Obx(
                    () => ElevatedButton(
                      onPressed: uiController.isNextEnabled.value
                          ? () {
                              print(action.id);
                              if (action.id == 'prev') {
                                uiController.onNext(
                                  action.nextStepId,
                                  actionId: action.id,
                                );
                              } else {
                                uiController.onNext(
                                  action.nextStepId,
                                  actionId: action.id,
                                );
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: bgColor,
                        disabledBackgroundColor: HColor.gray2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        action.text,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 10.sp,
                        ),
                      ),
                    ),
                  )
                : ElevatedButton(
                    onPressed: () {
                      if (action.id == 'prev') {
                        uiController.onNext(
                          action.nextStepId,
                          actionId: action.id,
                        );
                      } else {
                        uiController.onNext(
                          action.nextStepId,
                          actionId: action.id,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: bgColor,
                      disabledBackgroundColor: HColor.gray2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      action.text,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 10.sp,
                      ),
                    ),
                  ),
          );
        }).toList(),
      ),
    );
  }
}
