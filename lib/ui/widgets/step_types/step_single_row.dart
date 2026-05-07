import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../data/models/survey_step_model.dart';
import '../../widgets/survey_option_card.dart';
import '../../../config/style.dart';

class StepSingleRow extends StatelessWidget {
  final SurveyStepModel step;

  const StepSingleRow({super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    final options = step.options ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ===== 질문 제목 =====
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Text(
            step.title ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 8.sp,
              fontWeight: FontWeight.w500,
              color: HColor.black,
            ),
          ),
        ),

        SizedBox(height: 28.h),

        // ===== 옵션 카드 (좌우 여백만 있고, 내부는 균등 분할) =====
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 2.w),
          child: Row(
            children: List.generate(options.length, (index) {
              final option = options[index];
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 3.w),
                  child: SizedBox(
                    height: 280.h,
                    child: SurveyOptionCard(
                      stepId: step.id,
                      option: option,
                      stepType: step.type,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
