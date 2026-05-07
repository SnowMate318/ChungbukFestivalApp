import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../data/models/survey_step_model.dart';
import '../../widgets/survey_option_card.dart';
import '../../../config/style.dart';

class StepDoubleRow extends StatelessWidget {
  final SurveyStepModel step;

  const StepDoubleRow({super.key, required this.step});

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
              fontSize: 6.sp,
              fontWeight: FontWeight.w500,
              color: HColor.black,
            ),
          ),
        ),

        SizedBox(height: 20.h),

        // ===== 카드 그리드 (한 줄에 4개 고정) =====
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(), // ✅ 상위 스크롤과 겹치지 않게
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4, // ✅ 한 줄에 4개 고정
              crossAxisSpacing: 6.w, // 카드 간 간격
              mainAxisSpacing: 4.h, // 위아래 줄 간 간격
              childAspectRatio: 1.2, // ✅ 카드 비율 (1.2~1.4가 적당)
            ),
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options[index];
              return SurveyOptionCard(
                stepId: step.id,
                option: option,
                stepType: step.type,
              );
            },
          ),
        ),
      ],
    );
  }
}
