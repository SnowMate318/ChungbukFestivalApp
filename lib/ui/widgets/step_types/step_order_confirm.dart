import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../data/models/survey_step_model.dart';
import '../../controllers/survey_ui_controller.dart';
import '../../controllers/survey_controller.dart';
import '../../../config/style.dart';
import '../../widgets/survey_progress_bar.dart';


class StepOrderConfirm extends StatelessWidget {
  final SurveyStepModel step;

  final uiController = Get.find<SurveyUiController>();
  final surveyController = Get.find<SurveyController>();

  StepOrderConfirm({super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ 왼쪽 주문 내역 박스
            // Expanded(
            //   flex: 10,
            //   child: Container(
            //     padding: EdgeInsets.all(12.w),
            //     decoration: BoxDecoration(
            //       color: Colors.white,
            //       borderRadius: BorderRadius.circular(12.r),
            //       border: Border.all(color: HColor.gray2.withOpacity(0.4)),
            //     ),
            //     child: Obx(() {
            //       final selectedList = uiController.selectedTitles;
            //       final maxLines = 6;

            //       return Stack(
            //         children: [
            //           // ✅ 1️⃣ 줄 배경 (6줄 균등)
            //           CustomPaint(
            //             size: Size(double.infinity, double.infinity),
            //             painter: _LinePainter(lineCount: maxLines, color: HColor.gray2.withOpacity(0.3)),
            //           ),

            //           // ✅ 2️⃣ 텍스트 + 삭제버튼
            //           Column(
            //             crossAxisAlignment: CrossAxisAlignment.start,
            //             children: [
            //               ...List.generate(
            //                 selectedList.length,
            //                 (index) => Padding(
            //                   padding: EdgeInsets.only(top: (index * 28).h), // ✅ 줄 간격 맞춤
            //                   child: Row(
            //                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //                     children: [
            //                       Expanded(
            //                         child: Text(
            //                           '${index + 1}. ${selectedList[index]}',
            //                           style: TextStyle(
            //                             fontSize: 6.sp,
            //                             fontWeight: FontWeight.w600,
            //                             color: HColor.black,
            //                           ),
            //                         ),
            //                       ),
            //                       IconButton(
            //                         icon: Icon(Icons.close, size: 10.sp, color: HColor.gray3),
            //                         padding: EdgeInsets.zero,
            //                         onPressed: () {
            //                           uiController.selectedTitles.removeAt(index);
            //                         },
            //                       ),
            //                     ],
            //                   ),
            //                 ),
            //               ),

            //               const Spacer(),

            //               // ✅ 하단 수량 표시
            //               Row(
            //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //                 children: [
            //                   Text('수량', style: TextStyle(fontSize: 5.sp, color: HColor.gray3)),
            //                   Text(
            //                     '${selectedList.length}개',
            //                     style: TextStyle(fontSize: 5.sp, color: HColor.black),
            //                   ),
            //                 ],
            //               ),
            //             ],
            //           ),
            //         ],
            //       );
            //     }),
            //   ),
            // ),

            Expanded(
              flex: 10,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: HColor.gray2.withOpacity(0.4)),
                ),
                child: Obx(() {
                  final selectedList = uiController.selectedTitles;
                  const int maxLines = 6;

                  return Stack(
                    children: [
                      // ✅ 줄 배경
                      CustomPaint(
                        size: Size(double.infinity, double.infinity),
                        painter: _LinePainter(
                          lineCount: maxLines,
                          color: HColor.gray2.withOpacity(0.3),
                        ),
                      ),

                      // ✅ 전체 콘텐츠 구성
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 🔹 선택된 목록 (스크롤 가능)
                          Expanded(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ...List.generate(
                                    selectedList.length,
                                    (index) => Padding(
                                      padding: EdgeInsets.symmetric(vertical: 16.h),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${index + 1}. ${selectedList[index]}',
                                              style: TextStyle(
                                                fontSize: 6.sp,
                                                fontWeight: FontWeight.w600,
                                                color: HColor.black,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.close,
                                              size: 10.sp,
                                              color: HColor.gray3,
                                            ),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () {
                                              uiController.selectedTitles.removeAt(index);
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: 10.h),

                          // 🔹 하단 수량 표시 (항상 고정)
                          Container(
                            width: 160.w,  // ✅ 너비 제어
                            height: 60.h, // ✅ 높이 제어
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  '수량',
                                  style: TextStyle(
                                    fontSize: 5.sp,
                                    color: HColor.gray3,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${selectedList.length}개',
                                  style: TextStyle(
                                    fontSize: 5.sp,
                                    color: HColor.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )

                        ],
                      ),
                    ],
                  );
                }),
              ),
            ),





            SizedBox(width: 5.w),

            // ✅ 오른쪽 안내 + 버튼 영역
            Expanded(
              flex: 10,
              child: Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: HColor.gray1,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(height: 16.h),
                    Center(
                      child: Text(
                        'STEP ${step.stepNumber ?? ''} [KRISO 콘텐츠 선택]',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 6.sp,
                          fontWeight: FontWeight.bold,
                          color: HColor.black,
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),

                    const SurveyProgressBar(),
                    SizedBox(height: 24.h),
                    

                    Text(
                      '콘텐츠 주문 완료를 위해\n주문 내역을 확인해주세요',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 8.sp,
                        fontWeight: FontWeight.bold,
                        color: HColor.black,
                      ),
                    ),

                    // ✅ 버튼 그룹
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end, // ✅ 아래쪽 정렬
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end, // ✅ Row도 하단 기준 정렬
                            children: [
                              // 🔹 왼쪽 버튼 세트
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.end, // ✅ 세로 버튼도 하단 정렬
                                children: [
                                  OutlinedButton(
                                    onPressed: () {
                                      uiController.selectedTitles.clear();
                                    },
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: HColor.gray2,
                                      minimumSize: Size(45.w, 60.h),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6.r),
                                      ),
                                      side: BorderSide.none,
                                    ),
                                    child: Text(
                                      '전체취소',
                                      style: TextStyle(
                                        fontSize: 6.sp,
                                        color: HColor.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 12.h),
                                  OutlinedButton(
                                    onPressed: () {
                                      uiController.onNext('step2-2');
                                    },
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: HColor.gray2,
                                      minimumSize: Size(45.w, 60.h),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6.r),
                                      ),
                                      side: BorderSide.none,
                                    ),
                                    child: Text(
                                      '뒤로가기',
                                      style: TextStyle(
                                        fontSize: 6.sp,
                                        color: HColor.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(width: 4.w),

                              // 🔹 오른쪽 주문하기 버튼
                              ElevatedButton(
                                onPressed: () {
                                  print('✅ 주문 내용: ${uiController.selectedTitles}');
                                  surveyController.answers['step2-2'] = uiController.selectedTitles;
                                  uiController.onNext('step2-4');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: HColor.blue1,
                                  minimumSize: Size(90.w, 125.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6.r),
                                  ),
                                ),
                                child: Text(
                                  '주문하기',
                                  style: TextStyle(
                                    fontSize: 7.sp,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),


                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  final int lineCount;
  final Color color;

  _LinePainter({required this.lineCount, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    final spacing = size.height / (lineCount + 1);
    for (int i = 1; i <= lineCount; i++) {
      final y = i * spacing;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
