import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../controllers/survey_ui_controller.dart';
import '../../../data/models/option_model.dart';
import '../../../data/models/enums.dart';
import '../../../config/style.dart';

class SurveyOptionCard extends StatelessWidget {
  final String stepId;
  final OptionModel option;
  final StepType stepType;
  final uiController = Get.find<SurveyUiController>();

  SurveyOptionCard({
    super.key,
    required this.stepId,
    required this.option,
    required this.stepType,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final bool isSelected =
          uiController.selectedOption.value == option.id ||
          uiController.selectedOptions.contains(option.id);

      // ✅ 카드 형태 구분
      final bool isDoubleRow = stepType == StepType.doubleRowSelection;

      return GestureDetector(
        onTap: () {
          uiController.onSelectOption(stepId, option);
          if (stepType == StepType.doubleRowSelection) {
            // ✅ doubleRow일 때만 오버레이(팝업) 표시
            Get.dialog(
              Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
                insetPadding: EdgeInsets.symmetric(horizontal: 100.w),
                child: Padding(
                  padding: EdgeInsets.all(10.w),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 제목
                      Text(
                        option.text,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w500,
                          color: HColor.black,
                        ),
                      ),
                      SizedBox(height: 36.h),

                      // ✅ 설명 텍스트 (option.id에 따라 다르게 표시)
                      Builder(
                        builder: (_) {
                          final Map<String, String> descMap = {
                            'content1':
                                '선박해양플랜트연구소(KRISO)의\n'
                                '특별한 연구주제들을 So-Easy하게\n'
                                '설명해주는 크리소~이지!\n'
                                '"크리소이지"시리즈가 여러분들을\n'
                                '해양 지식 전문가로 만들어드립니다!',
                            'content2':
                                '연구소 안팎의 모든 순간을 한눈에!\n'
                                '행사 현장부터\n'
                                '연구소 직원들의 일상을\n'
                                '생생한 이야기로 전해드립니다!',
                            'content3':
                                'KRISO의 다양한\n'
                                '연구 분야와 직무 이야기까지!\n'
                                '연구원들의 목소리로 전하는\n'
                                'KRISO 인터뷰를 확인해보세요!',
                            'content4':
                                'KRISO의 연구시설과\n'
                                '주요 연구 성과, 지역거점,\n'
                                '설립 50년 간의 발자취 등을\n'
                                '한 곳에서 만나보세요!',
                          };

                          final description =
                              descMap[option.id] ??
                              '선박해양플랜트연구소(KRISO)의 특별한 연구주제들을 So~Easy하게 설명해주는 크리소~이지!21\n'
                                  '“크리소이지” 시리즈가 여러분을 해양 지식 전문가로 만들어드립니다!';

                          return Text(
                            description,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 6.sp,
                              color: HColor.black,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        },
                      ),

                      SizedBox(height: 20.h),

                      // 닫기 버튼
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HColor.blue1,
                          minimumSize: Size(double.infinity, 60.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        onPressed: () => Get.back(),
                        child: Text(
                          '닫기',
                          style: TextStyle(color: Colors.white, fontSize: 5.sp),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              barrierDismissible: true, // 바깥 탭 시 닫힘
            );
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),

          // ✅ 단계 타입별로 다르게 적용
          decoration: isDoubleRow
              ? const BoxDecoration()
              : BoxDecoration(
                  color: isSelected ? HColor.blue1 : HColor.gray1, // ✅ 회색 배경
                  borderRadius: BorderRadius.circular(
                    option.borderRadius ?? 20.r,
                  ),
                  boxShadow: [
                    // if (isSelected)
                    //   BoxShadow(
                    //     color: Colors.black.withOpacity(0.12),
                    //     blurRadius: 6,
                    //     offset: const Offset(0, 2),
                    //   ),
                  ],
                ),

          // 내부 위젯
          width: isDoubleRow ? 140.w : double.infinity,
          height: isDoubleRow ? 150.h : 220.h,
          child: SizedBox.expand(
            child: isDoubleRow
                ? _buildThumbnailCard(isSelected)
                : _buildTextCard(isSelected),
          ),
        ),
      );
    });
  }

  // 🟦 텍스트 중심 카드 (singleRowSelection)
  Widget _buildTextCard(bool isSelected) {
    String toCircledNumber(int number) {
      const baseCode = 0x2460; // ①
      if (number < 1 || number > 20) return number.toString();
      return String.fromCharCode(baseCode + number - 1);
    }

    String displayNumber = toCircledNumber(
      int.tryParse(option.id.toString()) ?? 1,
    );

    return SizedBox(
      height: 220.h, // ✅ 모든 카드 높이를 통일 (필요 시 200~240.h로 조절)
      child: Container(
        alignment: Alignment.center,
        padding:
            option.padding ??
            EdgeInsets.symmetric(horizontal: 5.w, vertical: 6.h),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center, // ✅ 가로 중앙 정렬
          children: [
            SizedBox(height: 32.h),

            // 🔹 번호
            Text(
              displayNumber,
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w500,
                color: isSelected ? HColor.white : HColor.gray3,
              ),
            ),

            SizedBox(height: 10.h),

            // 🔹 제목
            Text(
              option.text,
              textAlign: TextAlign.center, // ✅ 가운데 정렬
              textHeightBehavior: const TextHeightBehavior(
                applyHeightToFirstAscent: false,
                applyHeightToLastDescent: false,
              ),
              style: TextStyle(
                fontSize: option.fontSize ?? 5.sp,
                fontWeight: FontWeight.w500,
                color: isSelected ? HColor.white : HColor.gray3,
                height: 1.3,
              ),
            ),

            SizedBox(height: 10.h),

            // 🔹 서브텍스트
            if (option.subtitleList != null && option.subtitleList!.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 5.h),
                child: Align(
                  alignment: Alignment.centerLeft, // ✅ 왼쪽 정렬
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: option.subtitleList!.map((line) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: 2.h),
                        child: Text(
                          line,
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontSize: (option.fontSize ?? 5.sp) - 0.5.sp,
                            fontWeight: FontWeight.w500,
                            color: (isSelected ? HColor.white : HColor.gray3)
                                .withOpacity(0.9),
                            height: 1.3,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              )
            else if (option.subtitle != null)
              Padding(
                padding: EdgeInsets.only(top: 5.h),
                child: Align(
                  alignment: Alignment.centerLeft, // ✅ 왼쪽 정렬
                  child: Text(
                    option.subtitle!,
                    textAlign: TextAlign.left,
                    textHeightBehavior: const TextHeightBehavior(
                      applyHeightToFirstAscent: false,
                      applyHeightToLastDescent: false,
                    ),
                    style: TextStyle(
                      fontSize: (option.fontSize ?? 5.sp) - 1.sp,
                      fontWeight: FontWeight.w500,
                      color: (isSelected ? HColor.white : HColor.gray3)
                          .withOpacity(0.8),
                      height: 1.3,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 🟩 이미지 + 텍스트 카드 (doubleRowSelection)
  Widget _buildThumbnailCard(bool isSelected) {
    // 제목 박스의 고정 높이 (필요하면 24~30.h 사이에서 미세 조정)
    final double titleHeight = 50.h;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 1) 이미지: 남는 높이를 모두 사용 (셀 높이 초과 방지)
        Expanded(
          flex: 10, // ✅ 이미지가 차지하는 비중을 크게 (기본 1보다 큼)
          child: ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(option.borderRadius ?? 10.r),
              topRight: Radius.circular(option.borderRadius ?? 10.r),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Padding(
                  // 이미지가 제목 박스와 겹치지 않도록 아주 살짝만 띄움(선택)
                  padding: EdgeInsets.only(bottom: 2.h),
                  child: FittedBox(
                    fit: BoxFit.contain, // ✅ 비율 유지, 부모 영역 안에서 최대
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      child: Image.asset(
                        option.imageUrl ?? '',
                        fit: BoxFit.contain, // 안전하게 contain 유지
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.broken_image, size: 30),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // 2) 제목 박스: 고정 높이
        Container(
          height: titleHeight,
          width: double.infinity,
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: 6.w),
          decoration: BoxDecoration(
            color: isSelected ? HColor.blue1 : HColor.white,

            // ✅ 테두리 제거
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(option.borderRadius ?? 10.r),
              bottomRight: Radius.circular(option.borderRadius ?? 10.r),
            ),

            // ✅ 그림자 추가 (살짝 띄워보이게)
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            option.text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 7.sp,
              fontWeight: FontWeight.w500,
              color: isSelected ? HColor.white : HColor.gray4,
            ),
          ),
        ),
      ],
    );
  }

  // ================================
  // 🔧 Alignment 헬퍼 함수들
  // ================================
  CrossAxisAlignment _getCrossAlignment(Alignment? alignment) {
    if (alignment == Alignment.centerLeft) return CrossAxisAlignment.start;
    if (alignment == Alignment.centerRight) return CrossAxisAlignment.end;
    return CrossAxisAlignment.center;
  }

  MainAxisAlignment _getMainAlignment(Alignment? alignment) {
    if (alignment == Alignment.topCenter ||
        alignment == Alignment.topLeft ||
        alignment == Alignment.topRight) {
      return MainAxisAlignment.start;
    }
    if (alignment == Alignment.bottomCenter ||
        alignment == Alignment.bottomLeft ||
        alignment == Alignment.bottomRight) {
      return MainAxisAlignment.end;
    }
    return MainAxisAlignment.center;
  }

  TextAlign _getTextAlign(Alignment? alignment) {
    if (alignment == Alignment.centerLeft) return TextAlign.left;
    if (alignment == Alignment.centerRight) return TextAlign.right;
    return TextAlign.center;
  }
}
