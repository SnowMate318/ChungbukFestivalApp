import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../config/style.dart';
import '../../../data/models/survey_step_model.dart';
import '../../controllers/survey_ui_controller.dart';
import '../../controllers/survey_controller.dart';
import '../../widgets/survey_progress_bar.dart';
import '../../../data/models/option_model.dart';

class StepContentOrder extends StatelessWidget {
  final SurveyStepModel step;
  final uiController = Get.find<SurveyUiController>();
  final surveyController = Get.find<SurveyController>();

  StepContentOrder({super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    final options = step.options ?? [];

    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 20.h),
      child: Obx(() {
        // ✅ 현재 페이지 상태는 전역 컨트롤러에서 관리
        final currentPage = uiController.currentPage.value;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🟦 좌측 콘텐츠 영역
            Expanded(
              flex: 10,
              child: Container(
                decoration: BoxDecoration(
                  color: HColor.gray1,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 10,
                      // ✅ LeftPanel은 내부에서 시리즈 / 페이지 / 분할 처리 담당
                      child: _buildLeftPanel(),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(width: 5.w),

            // 🟩 우측 주문 패널
            Expanded(
              flex: 10,
              child: Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: HColor.gray1, // ✅ 동일한 배경색
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: _buildRightPanel(),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildLeftPanel() {
    final uiController = Get.find<SurveyUiController>();
    final surveyController = Get.find<SurveyController>();

    return Container(
      decoration: BoxDecoration(
        color: HColor.gray1,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              child: Builder(
                builder: (context) {
                  final title = surveyController.selectedContentTitle.value;

                  // ✅ 선택된 콘텐츠에 따라 시리즈 매칭
                  List<Map<String, String>> episodeList = [];
                  if (title.contains('크리소이지')) {
                    episodeList = seriesA;
                  } else if (title.contains('KRISO 이야기')) {
                    episodeList = seriesB;
                  } else if (title.contains('KRISO 인터뷰')) {
                    episodeList = seriesC;
                  } else if (title.contains('KRISO 연구 및 소개')) {
                    episodeList = seriesD;
                  }

                  // ✅ 총 페이지 수 계산
                  final int itemsPerPage = 9;
                  final int totalPages = (episodeList.length / itemsPerPage)
                      .ceil();

                  // ✅ 현재 페이지 인덱스 및 보여줄 아이템 구하기
                  final int currentPage = uiController.currentPage.value;
                  final int startIndex = currentPage * itemsPerPage;
                  final int endIndex = (startIndex + itemsPerPage).clamp(
                    0,
                    episodeList.length,
                  );
                  final visibleItems = episodeList.sublist(
                    startIndex,
                    endIndex,
                  );

                  // ✅ GridView 빌드
                  return Column(
                    children: [
                      Expanded(
                        child: GridView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: visibleItems.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: 1.5,
                              ),
                          itemBuilder: (context, index) {
                            final item = visibleItems[index];
                            final episodeNum = item['num']!;
                            final cleanTitle = (item['title'] ?? '').replaceAll(
                              '\n',
                              ' ',
                            );
                            final combined =
                                '$episodeNum [$cleanTitle]'; // ✅ "1편 [제목]" 포맷

                            return Obx(() {
                              final isSelected = uiController.selectedTitles
                                  .contains(combined); // ✅ 여기 변경!

                              return _buildEpisodeCard(
                                index: index,
                                imagePath: item['img']!,
                                episodeNum: episodeNum,
                                episodeTitle: cleanTitle,
                                isSelected: isSelected,
                                onTap: () {
                                  if (uiController.selectedTitles.contains(
                                    combined,
                                  )) {
                                    uiController.selectedTitles.remove(
                                      combined,
                                    );
                                  } else if (uiController
                                          .selectedTitles
                                          .length <
                                      6) {
                                    uiController.selectedTitles.add(combined);
                                  }
                                },
                              );
                            });
                          },
                        ),
                      ),

                      // ✅ 페이지 네비게이션
                      SizedBox(height: 10.h),
                      Container(
                        width: 60.w,
                        height: 48.h,
                        alignment: Alignment.center,
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
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // ◀ 왼쪽 화살표
                            IconButton(
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                Icons.chevron_left,
                                color: HColor.blue1,
                                size: 10.sp,
                              ),
                              onPressed: uiController.prevPage,
                            ),

                            // ✅ 페이지 번호 버튼들
                            Obx(() {
                              final currentPage =
                                  uiController.currentPage.value;
                              return Row(
                                children: List.generate(totalPages, (index) {
                                  final isActive = index == currentPage;
                                  return Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 1.w,
                                    ),
                                    child: GestureDetector(
                                      onTap: () =>
                                          uiController.currentPage.value =
                                              index,
                                      child: Container(
                                        width: 10.w,
                                        height: 34.h,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: isActive
                                              ? HColor.blue1
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            4.r,
                                          ),
                                          border: isActive
                                              ? Border.all(
                                                  color: HColor.blue1,
                                                  width: 1,
                                                )
                                              : null,
                                        ),
                                        child: Text(
                                          '${index + 1}',
                                          style: TextStyle(
                                            color: isActive
                                                ? Colors.white
                                                : HColor.black,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 5.sp,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              );
                            }),

                            // ▶ 오른쪽 화살표
                            IconButton(
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                Icons.chevron_right,
                                color: HColor.blue1,
                                size: 10.sp,
                              ),
                              onPressed: () =>
                                  uiController.nextPage(totalPages),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ 오른쪽 패널
  Widget _buildRightPanel() {
    return Obx(() {
      final selectedId = uiController.selectedOption.value;
      final selectedText =
          step.options?.firstWhereOrNull((opt) => opt.id == selectedId)?.text ??
          '';

      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 🔹 STEP 타이틀
          Center(
            child: Text(
              'STEP ${step.stepNumber ?? ''} [KRISO 콘텐츠 선택]',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 6.sp,
                fontWeight: FontWeight.w500,
                color: HColor.black,
              ),
            ),
          ),
          SizedBox(height: 4.h),

          const SurveyProgressBar(),
          SizedBox(height: 16.h),

          // 🔹 제목/안내 문구
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: '${surveyController.selectedContentTitle.value} ',
                  style: TextStyle(
                    fontSize: 8.sp,
                    color: HColor.blue1,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextSpan(
                  text: ' 중에서 가장\n관심있는 영상을 선택해주세요.\n',
                  style: TextStyle(
                    fontSize: 8.sp,
                    color: HColor.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextSpan(
                  text: '※ 중복 선택 가능합니다.',
                  style: TextStyle(
                    fontSize: 6.sp,
                    color: HColor.blue1,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 20.h),

          // 🔹 선택 정보 & 버튼 영역
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 왼쪽 영역 — 영상 목록
              Expanded(
                flex: 1,
                child: Obx(() {
                  final selectedList = uiController.selectedTitles;

                  return Container(
                    padding: EdgeInsets.all(8.w),
                    height: 180.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: HColor.gray2.withOpacity(0.4)),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: selectedList.isEmpty
                        ? Column(
                            children: List.generate(
                              6,
                              (i) => Divider(
                                color: HColor.gray2.withOpacity(0.3),
                                thickness: 1,
                                height: 20.h,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: selectedList.length,
                            itemBuilder: (context, i) {
                              return Padding(
                                padding: EdgeInsets.symmetric(vertical: 4.h),
                                child: Text(
                                  '${selectedList[i]}',
                                  maxLines: 1, // ✅ 한 줄만 표시
                                  overflow:
                                      TextOverflow.ellipsis, // ✅ 넘치면 ... 으로 표시
                                  style: TextStyle(
                                    fontSize: 3.sp,
                                    color: HColor.black,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            },
                          ),
                  );
                }),
              ),

              SizedBox(width: 10.w),

              // 오른쪽 버튼 영역
              Expanded(
                flex: 1, // ✅ 비율로 좁게 조정
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // 전체취소 버튼
                            OutlinedButton(
                              onPressed: () {
                                uiController.selectedIndexes.clear();
                                uiController.selectedTitles.clear();
                                uiController.update();
                                print('🧹 전체 취소 완료 — 선택된 인덱스 및 타이틀 초기화됨');
                              },
                              style: OutlinedButton.styleFrom(
                                backgroundColor: HColor.gray2, // ✅ 배경색 추가
                                side: BorderSide.none, // ✅ 테두리 제거
                                minimumSize: Size(32.w, 50.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    8.r,
                                  ), // ✅ 모서리 부드럽게
                                ),
                              ),
                              child: Text(
                                '전체취소',
                                style: TextStyle(
                                  fontSize: 5.sp,
                                  color: Colors.white, // ✅ 흰색 텍스트
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),

                            SizedBox(width: 8.w),

                            // 뒤로가기 버튼
                            OutlinedButton(
                              onPressed: () {
                                uiController.selectedIndexes.clear();
                                uiController.selectedTitles.clear();
                                uiController.onNext('step2-1');
                              },
                              style: OutlinedButton.styleFrom(
                                backgroundColor: HColor.gray2, // ✅ 배경색 동일
                                side: BorderSide.none, // ✅ 테두리 제거
                                minimumSize: Size(32.w, 50.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                              ),
                              child: Text(
                                '뒤로가기',
                                style: TextStyle(
                                  fontSize: 5.sp,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    // ✅ 수량 박스
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 10.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white, // ✅ 배경 흰색
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
                        children: [
                          Text(
                            '수량',
                            style: TextStyle(
                              fontSize: 5.sp,
                              color: HColor.gray3,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Obx(
                            () => Text(
                              '${uiController.selectedTitles.length}개', // ✅ 선택된 개수
                              style: TextStyle(
                                fontSize: 5.sp,
                                color: HColor.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 8.h),

                    // ✅ 주문하기 버튼
                    ElevatedButton(
                      onPressed: () {
                        print(uiController.selectedTitles);
                        uiController.onNext('step2-3');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: HColor.blue1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        minimumSize: Size(double.infinity, 80.h),
                        elevation: 0,
                      ),
                      child: Text(
                        '주문하기',
                        style: TextStyle(
                          fontSize: 6.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    });
  }

  // ✅ 카드 빌더
  Widget _buildOptionCard(OptionModel? option, String imagePath) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        image: DecorationImage(image: AssetImage(imagePath), fit: BoxFit.cover),
      ),
      child: option == null
          ? const SizedBox.shrink()
          : Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 2.h),
                color: Colors.black.withOpacity(0.4),
                child: Text(
                  option.text,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 5.sp,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
    );
  }

  Widget _buildEpisodeCard({
    required int index,
    required String imagePath,
    required String episodeNum,
    required String episodeTitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          // ✅ 배경 이미지
          ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),

          // ✅ 오버레이
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              color: Colors.black.withOpacity(0.55),
            ),
          ),

          // ✅ 상단 텍스트 (N편 + 제목)
          Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  episodeNum,
                  style: TextStyle(
                    color: isSelected ? Colors.pink[100] : Colors.white,
                    fontSize: 3.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                // SizedBox(height: 3.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: Text(
                    episodeTitle,
                    textAlign: TextAlign.center,
                    softWrap: true, // ✅ 자동 줄바꿈 활성화
                    maxLines: 3, // ✅ 개행 포함 3줄까지 표시 (필요 시 늘리세요)
                    overflow: TextOverflow.visible, // ✅ 줄바꿈 시 잘림 방지
                    style: TextStyle(
                      color: isSelected ? Colors.pink[100] : Colors.white,
                      fontSize: 4.sp,
                      fontWeight: FontWeight.w500,
                      height: 1.2, // ✅ 줄 간격 조정 (조금 더 조밀하게)
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ 빈 셀
  Widget _buildEmptyCell() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10.r),
      ),
    );
  }
}

final List<Map<String, String>> seriesA = [
  {'num': '1편', 'title': '선박이 위치를\n찾는 방법', 'img': 'assets/images/A_1.png'},
  {
    'num': '2편',
    'title': 'KRISO의 친환경대체\n연료해상실증선박?',
    'img': 'assets/images/A_2.png',
  },
  {'num': '3편', 'title': 'KRISO의\n해양그린수소?', 'img': 'assets/images/A_3.png'},
  {'num': '4편', 'title': 'KRISO의\n전기추진선박?', 'img': 'assets/images/A_4.png'},
  {'num': '5편', 'title': '해양생물을 괴롭히는\n선박소음 !?', 'img': 'assets/images/A_5.png'},
  {
    'num': '6편',
    'title': '심해에서도 로봇이\n활용되고 있다는 사실',
    'img': 'assets/images/A_6.png',
  },
  {
    'num': '7편',
    'title': '바다 위의 테슬라?\n자율운항선박\n쉽게 알려드림',
    'img': 'assets/images/A_7.png',
  },
  {'num': '8편~9편', 'title': '질문에 답하다', 'img': 'assets/images/A_8.png'},
  {
    'num': '10편',
    'title': "'꿈의 항로'\n북극이 현실로!\n지금 상황 총정리",
    'img': 'assets/images/A_9.png',
  },
];

final List<Map<String, String>> seriesB = [
  {'num': '1편', 'title': '여름방학,\n바다로 떠난 하루', 'img': 'assets/images/B_1.png'},
  {'num': '2편', 'title': '벚꽃운동회\n현장 속으로', 'img': 'assets/images/B_2.png'},
  {'num': '3편', 'title': '책향기 동아리의\n전통시장 탐방', 'img': 'assets/images/B_3.png'},
  {'num': '4편', 'title': '선박해양플랜트연구소\n밸런스게임', 'img': 'assets/images/B_4.png'},
  {
    'num': '5편',
    'title': '해양플랜트 서비스산업\n아이디어 경진대회',
    'img': 'assets/images/B_5.png',
  },
  {'num': '6편', 'title': 'KRISO\n해양과학카페', 'img': 'assets/images/B_6.png'},
  {'num': '7편', 'title': '크리소의 동호회를\n소개합니다!', 'img': 'assets/images/B_7.png'},
];

final List<Map<String, String>> seriesC = [
  {
    'num': '1편',
    'title': '배가 스스로 운전하면,\n우리는 뭐해요?',
    'img': 'assets/images/C_1.png',
  },
  {
    'num': '2편',
    'title': '거제의 숨은 보물!\n해양플랜트산업지원센터\n소개',
    'img': 'assets/images/C_2.png',
  },
  {
    'num': '3편',
    'title': '구조디지털 트윈으로\n20년 후 해양플랜트 상\n태를 알 수 있다',
    'img': 'assets/images/C_3.png',
  },
  {
    'num': '4편',
    'title': '바다에서\n초고속 무선통신이\n가능하다?!',
    'img': 'assets/images/C_4.png',
  },
  {'num': '5편', 'title': '지금 전기추진\n차도선은?', 'img': 'assets/images/C_5.png'},
  {'num': '6편', 'title': '해양에너지?\n해양구조물?', 'img': 'assets/images/C_6.png'},
  {'num': '7편', 'title': '자율운항선박\n궁금해?', 'img': 'assets/images/C_7.png'},
  {
    'num': '8편',
    'title': 'KRISO 신입사원 인터뷰\n크리소 입사했소!\n어떻게 입사했소?',
    'img': 'assets/images/C_8.png',
  },
  {
    'num': '9편',
    'title': '실패를 두려워 하지 않는\n올해의 KRISO인\n홍사영 책임연구원',
    'img': 'assets/images/C_9.png',
  },
  {
    'num': '10편',
    'title': '해양플랜트산업지원센터\n거세 센터에서는\n무슨일을 할까?1편',
    'img': 'assets/images/C_10.png',
  },
  {
    'num': '11편',
    'title': '해양플랜트산업지원센터\n거세 센터에서는\n무슨일을 할까?2편',
    'img': 'assets/images/C_11.png',
  },
];

final List<Map<String, String>> seriesD = [
  {'num': '1편', 'title': 'KRISO 설립\n50주년 기념영상', 'img': 'assets/images/D_1.png'},
  {
    'num': '2편',
    'title': 'KRISO 50년 성과\n및 비전 선포 영상',
    'img': 'assets/images/D_2.png',
  },
  {
    'num': '3편',
    'title': '선박해양플랜트연구소\n홍보 및 브랜드 영상',
    'img': 'assets/images/D_3.png',
  },
  {'num': '4편', 'title': '해양플랜트산업지원센터\n- 거제', 'img': 'assets/images/D_4.png'},
  {'num': '5편', 'title': '해수에너지연구센터\n- 고성', 'img': 'assets/images/D_5.png'},
  {'num': '6편', 'title': '자율운항선박실증연구센터\n- 울산', 'img': 'assets/images/D_6.png'},
  {'num': '7편', 'title': '심해공학연구센터\n- 부산', 'img': 'assets/images/D_7.png'},
  {'num': '8편', 'title': 'KRISO 북극 연구\n홍보영상', 'img': 'assets/images/D_8.png'},
  {'num': '9편', 'title': '전기추진 차도선\n홍보영상', 'img': 'assets/images/D_9.png'},
];
