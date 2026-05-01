import 'survey_step_model.dart';
import 'option_model.dart';
import 'action_button_model.dart';
import 'enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../config/style.dart';

final List<SurveyStepModel> sampleSurveySteps = [
  // 🟦 STEP 1-1
  SurveyStepModel(
    id: 'step1-1',
    type: StepType.singleRowSelection,

    stepNumber: 1,
    stepLabel: '[KRISO 인지도 - 인식]',

    title: '1. 선박해양플랜트연구소(이하 KRISO)에 대해 알고 계신가요?',
    subtitle: 'STEP 1 | [KRISO 인지도 - 인식]',

    options: [
      OptionModel(
        id: '1',
        text: '전혀 모른다',
        fontSize: 10.sp,
        textColor: HColor.gray3,
        alignment: Alignment.center,
        fontWeight: FontWeight.bold,
        borderRadius: 10.r,
        backgroundColor: HColor.gray1,
        padding: EdgeInsets.symmetric(vertical: 10.h),
      ),
      OptionModel(
        id: '2',
        text: '이름은 들어봤다',
        fontSize: 10.sp,
        textColor: HColor.gray3,
        alignment: Alignment.center,
        fontWeight: FontWeight.bold,
        borderRadius: 10.r,
        backgroundColor: HColor.gray1,
        padding: EdgeInsets.symmetric(vertical: 10.h),
      ),
      OptionModel(
        id: '3',
        text: '기관 성격을\n알고 있다',
        fontSize: 10.sp,
        textColor: HColor.gray3,
        alignment: Alignment.center,
        fontWeight: FontWeight.bold,
        borderRadius: 10.r,
        backgroundColor: HColor.gray1,
        padding: EdgeInsets.symmetric(vertical: 10.h),
      ),
      OptionModel(
        id: '4',
        text: '연구분야까지\n자세히 알고 있다',
        fontSize: 10.sp,
        textColor: HColor.gray3,
        alignment: Alignment.center,
        fontWeight: FontWeight.bold,
        borderRadius: 10.r,
        backgroundColor: HColor.gray1,
        padding: EdgeInsets.symmetric(vertical: 10.h),
      ),
    ],

    actions: [
      ActionButtonModel(
        id: 'start',
        text: '이전',
        nextStepId: 'start',
        isPrimary: false,
      ),
      ActionButtonModel(
        id: 'next',
        text: '다음',
        nextStepId: 'step1-2',
        isPrimary: true,
      ),
    ],

    buttonLayout: ButtonLayoutType.spaced,
  ),


  // 🟦 STEP 1-2
  SurveyStepModel(
    id: 'step1-2',
    type: StepType.multiRowSelection,
    //type: StepType.singleRowSelection,

    stepNumber: 1,
    stepLabel: '[KRISO 인지도 - 인식]',
    title: '2. KRISO SNS를 통해 얻고 싶은 정보를 선택해주세요! (최대 2개 선택 가능)',
    subtitle: 'STEP 1 | [KRISO 인지도 - 인식]',
    options: [
      OptionModel(
        id: '1',
        text: '연구성과·기술동향',
        subtitleList: [
          '- KRISO 최신\n연구성과 소개',
          '- 탈단소·디지털화 등\n  조선해양산업의\n  기술 트렌드',
        ],
        fontSize: 6.sp,
        isMultipleSelectable: true,
        maxSelectable: 2,
        alignment: Alignment.topLeft,
        textAlign: TextAlign.left,
        
      ),
      OptionModel(
        id: '2',
        text: '진로·커리어 정보',
        subtitleList: [
          '- 채용 소식',
          '- 연구·연구지원\n  현직 종사자 이야기',
        ],
        fontSize: 6.sp,
        isMultipleSelectable: true,
        maxSelectable: 2,
        alignment: Alignment.topLeft,
        textAlign: TextAlign.left,
      ),
      OptionModel(
        id: '3',
        text: '해양과학',
        subtitleList: [
          '- 재미있는 해양과학 상식',
          '- 해양심층수·기후변동 등 흥미 해결 연구 사례',
        ],
        fontSize: 5.sp,
        isMultipleSelectable: true,
        maxSelectable: 2,
        alignment: Alignment.topLeft,
        textAlign: TextAlign.left,
      ),
      OptionModel(
        id: '4',
        text: '소식·이벤트 안내',
        subtitleList: [
          '- KRISO 주최 행사\n  (세미나, 포럼 등)',
          '- 이벤트 소식',
        ],
        fontSize: 6.sp,
        isMultipleSelectable: true,
        maxSelectable: 2,
        alignment: Alignment.topLeft,
        textAlign: TextAlign.left,
      ),
      OptionModel(
        id: '5',
        text: '국제협력·네트워킹',
        subtitleList: [
          '- 국제학회·국제협력 소식',
          '- 타 연구기관,\n  기업과의 협업 사례',
        ],
        fontSize: 6.sp,
        isMultipleSelectable: true,
        maxSelectable: 2,
        alignment: Alignment.topLeft,
        textAlign: TextAlign.left,
      ),
      OptionModel(
        id: '6',
        text: '대학생 참여 기회',
        subtitleList: [
          '- 연구소 견학, 공모전 및\n 아이디어 경진대회 소식',
        ],
        fontSize: 5.5.sp,
        isMultipleSelectable: true,
        maxSelectable: 2,
        alignment: Alignment.topLeft,
        textAlign: TextAlign.left,
      ),
      OptionModel(
        id: '7',
        text: '연구소 일상\n·비하인드',
        subtitleList: [
          '- 연구원들의 하루,\n  실험실·현장 스케치',
          '- 연구장비, 시설 소개',
        ],
        fontSize: 6.sp,
        isMultipleSelectable: true,
        maxSelectable: 2,
        alignment: Alignment.topLeft,
        textAlign: TextAlign.left,
      ),
    ],
    actions: [
      ActionButtonModel(
        id: 'prev',
        text: '이전',
        nextStepId: 'step1-1',
        isPrimary: false,
      ),
      ActionButtonModel(
        id: 'next',
        text: '다음',
        nextStepId: 'step2-1',
        isPrimary: true,
      ),
    ],
    buttonLayout: ButtonLayoutType.spaced,
  ),


  // 🟩 STEP 2-1
  SurveyStepModel(
    id: 'step2-1',
    type: StepType.doubleRowSelection,

    stepNumber: 2,
    stepLabel: '[KRISO 콘텐츠 선택]',

    title: '관심 있는 콘텐츠를 선택해주세요',
    subtitle: 'STEP 2 | [KRISO 콘텐츠 선택]',

    options: [
      OptionModel(
        id: 'content1',
        text: '[크리소이지] 시리즈',
        imageUrl: 'assets/images/content/content1.png',
      ),
      OptionModel(
        id: 'content2',
        text: 'KRISO 이야기',
        imageUrl: 'assets/images/content/content2.png',
      ),
      OptionModel(
        id: 'content3',
        text: 'KRISO 인터뷰',
        imageUrl: 'assets/images/content/content3.png',
      ),
      OptionModel(
        id: 'content4',
        text: 'KRISO 연구 및 소개',
        imageUrl: 'assets/images/content/content4.png',
      ),
      // OptionModel(
      //   id: 'content5',
      //   text: 'KRISO Research',
      //   imageUrl: 'assets/images/content/content5.png',
      // ),
      // OptionModel(
      //   id: 'content6',
      //   text: '[크리소이지] 시리즈',
      //   imageUrl: 'assets/images/content/content6.png',
      // ),
      // OptionModel(
      //   id: 'content7',
      //   text: '[만약에] 시리즈',
      //   imageUrl: 'assets/images/content/content7.png',
      // ),
      // OptionModel(
      //   id: 'content8',
      //   text: '실험 & 교육 콘텐츠',
      //   imageUrl: 'assets/images/content/content8.png',
      // ),
      // OptionModel(
      //   id: 'content9',
      //   text: 'KRISO 소개',
      //   imageUrl: 'assets/images/content/content9.png',
      // ),
    ],

    actions: [
      ActionButtonModel(
        id: 'prev',
        text: '이전',
        nextStepId: 'step1-2',
        isPrimary: false,
      ),
      ActionButtonModel(
        id: 'next',
        text: '다음',
        nextStepId: 'step2-2',
        isPrimary: true,
      ),
    ],

    buttonLayout: ButtonLayoutType.spaced,
  ),



  // STEP 2-2
  SurveyStepModel(
    id: 'step2-2',
    type: StepType.contentOrderSelection,

    // ✅ 새 필드 추가
    stepNumber: 2,
    stepLabel: '[KRISO 챌린지 완료]',
    buttonLayout: ButtonLayoutType.centered,
  ),

  // STEP 2-3
  SurveyStepModel(
    id: 'step2-3',
    type: StepType.orderConfirm,

    // ✅ 새 필드 추가
    stepNumber: 2,
    stepLabel: '[KRISO 챌린지 완료]',
    buttonLayout: ButtonLayoutType.centered,
  ),

  // STEP 2-4
  SurveyStepModel(
    id: 'step2-4',
    type: StepType.orderComplete,

    stepNumber: 2,
    stepLabel: '[KRISO 콘텐츠 선택]',

    title: '주문 완료!',

    // 추가 데이터 (이미지 등)
    extraData: {
      'imageUrl': 'assets/images/order_complete.png',
    },

    // 버튼 액션
    actions: [
      ActionButtonModel(
        id: 'yes',
        text: '네 참여할게요',
        nextStepId: 'step3-1',
        isPrimary: false,
      ),
      ActionButtonModel(
        id: 'no',
        text: '아니요 괜찮아요',
        nextStepId: 'final',
        isPrimary: false,
      ),
    ],

    buttonLayout: ButtonLayoutType.centered,
  ),

  // STEP 3-1
  SurveyStepModel(
    id: 'step3-1',
    type: StepType.quizSelection,
    stepNumber: 3,
    stepLabel: '[KRISO 콘텐츠 퀴즈]',
    title: 'Q1. 다음 중 선박해양플랜트연구소(KRISO)의 주요 연구분야가 아닌 것은?',
    subtitle: null,
    
    options: [
      OptionModel(
        id: '1',
        text: '선박 성능 핵심기술 고도화,\n환경 친화적 선박 기술 혁신,\n지능형 선박 기술 선점',
        fontSize: 8.sp,
        textColor: HColor.gray3,
        alignment: Alignment.center,
        fontWeight: FontWeight.bold,
        backgroundColor: HColor.gray1,
      ),
      OptionModel(
        id: '2',
        text: '신개념 해양플랜트 기술 개발, 해양플랜트 기반 그린에너지·자원 기술개발 및 복합활용',
        fontSize: 8.sp,
        textColor: HColor.gray3,
        alignment: Alignment.center,
        fontWeight: FontWeight.bold,
        backgroundColor: HColor.gray1,
      ),
      OptionModel(
        id: '3',
        text: '스마트 해양 장비·로봇 기술 선도,\n해양디지털·ICT 융복합 기술 혁신',
        fontSize: 7.sp,
        textColor: HColor.gray3,
        alignment: Alignment.center,
        fontWeight: FontWeight.bold,
        backgroundColor: HColor.gray1,
      ),
      OptionModel(
        id: '4',
        text: '극지 미탐지(과학영토) 개척 및 탐사 기술 개발',
        fontSize: 8.sp,
        textColor: HColor.gray3,
        alignment: Alignment.center,
        fontWeight: FontWeight.bold,
        backgroundColor: HColor.gray1,
      ),
    ],

    // ✅ 정답 정보
    extraData: {
      'correctOptionId': '4',
      'correctNextStepId': 'step3-1-o',
      'wrongNextStepId': 'step3-1-x',
    },

    // ✅ 버튼 구성
    actions: [
      ActionButtonModel(
        id: 'prev',
        text: '이전',
        nextStepId: 'step2-3',
        isPrimary: false,
      ),
      ActionButtonModel(
        id: 'next',
        text: '다음',
        nextStepId: '', // 실제 이동은 onNext()에서 정답에 따라 동적 처리
        isPrimary: true,
      ),
    ],

    // ✅ 버튼 위치
    buttonLayout: ButtonLayoutType.spaced,
  ),

  // STEP 3-1-o
  SurveyStepModel(
    id: 'step3-1-o',
    type: StepType.quizInfo,

    stepNumber: 3,
    stepLabel: '[KRISO 콘텐츠 퀴즈]',

    title: '축 정답입니다!',
    extraData: {
      'imageUrl': 'assets/images/quiz/step_3-1-o_info.png',
      'accentColor': 'green',
    },
    actions: [
      ActionButtonModel(
        id: 'next',
        text: '다음',
        nextStepId: 'step3-2',
        isPrimary: false,
      ),
    ],
  ),

  // STEP 3-1-x
  SurveyStepModel(
    id: 'step3-1-x',
    type: StepType.quizInfo,

    stepNumber: 3,
    stepLabel: '[KRISO 콘텐츠 퀴즈]',

    title: '아쉽지만, 틀렸어요!',
    extraData: {
      'imageUrl': 'assets/images/quiz/step_3-1-x_info.png',
      'accentColor': 'red',
    },
    actions: [
      ActionButtonModel(
        id: 'next',
        text: '다음',
        nextStepId: 'step3-2',
        isPrimary: false,
      ),
    ],
  ),

  // STEP 3-2
  SurveyStepModel(
    id: 'step3-2',
    type: StepType.quizSelection,
    stepNumber: 3,
    stepLabel: '[KRISO 콘텐츠 퀴즈]',
    title: 'Q2. KRISO는 친환경 대체연료 선박 적용 기술 연구개발, 육·해상 시험평가 및 실증 등을\n수행하기 위한 지역거점을 울산시에 구축하고 있다.',
    subtitle: null,
    
    options: [
      OptionModel(
        id: '1',
        text: 'O',
        fontSize: 24.sp,
        textColor: HColor.gray3,
        alignment: Alignment.center,
        fontWeight: FontWeight.bold,
        backgroundColor: HColor.gray1,

      ),
      OptionModel(
        id: '2',
        text: 'X',
        fontSize: 24.sp,
        textColor: HColor.gray3,
        alignment: Alignment.center,
        fontWeight: FontWeight.bold,
        backgroundColor: HColor.gray1,
      ),
    ],

    // ✅ 정답 정보
    extraData: {
      'correctOptionId': '2',
      'correctNextStepId': 'step3-2-o',
      'wrongNextStepId': 'step3-2-x',
    },

    // ✅ 버튼 구성
    actions: [
      ActionButtonModel(
        id: 'prev',
        text: '이전',
        nextStepId: 'step3-1',
        isPrimary: false,
      ),
      ActionButtonModel(
        id: 'next',
        text: '다음',
        nextStepId: '', // 실제 이동은 onNext()에서 정답에 따라 동적 처리
        isPrimary: true,
      ),
    ],

    // ✅ 버튼 위치
    buttonLayout: ButtonLayoutType.spaced,
  ),

  // STEP 3-2-o
  SurveyStepModel(
    id: 'step3-2-o',
    type: StepType.quizInfo,

    stepNumber: 3,
    stepLabel: '[KRISO 콘텐츠 퀴즈]',

    title: '축 정답입니다!',
    extraData: {
      'imageUrl': 'assets/images/quiz/step_3-2-o_info.png',
      'accentColor': 'green',
    },
    actions: [
      ActionButtonModel(
        id: 'next',
        text: '다음',
        nextStepId: 'step3-3',
        isPrimary: false,
      ),
    ],
  ),

  // STEP 3-2-x
  SurveyStepModel(
    id: 'step3-2-x',
    type: StepType.quizInfo,

    stepNumber: 3,
    stepLabel: '[KRISO 콘텐츠 퀴즈]',

    title: '아쉽지만, 틀렸어요!',
    extraData: {
      'imageUrl': 'assets/images/quiz/step_3-2-x_info.png',
      'accentColor': 'red',
    },
    actions: [
      ActionButtonModel(
        id: 'next',
        text: '다음',
        nextStepId: 'step3-3',
        isPrimary: false,
      ),
    ],
  ),

  // STEP 3-3
  SurveyStepModel(
    id: 'step3-3',
    type: StepType.quizSelection,
    stepNumber: 3,
    stepLabel: '[KRISO 콘텐츠 퀴즈]',
    title: 'Q3. 선박해양플랜트연구소가 2020년부터 개발해 온 지능형 자율항해시스템의 이름은\n무엇일까요?',
    subtitle: null,
    
    options: [
      OptionModel(
        id: '1',
        text: 'NEMO',
        fontSize: 12.sp,
        textColor: HColor.gray3,
        alignment: Alignment.center,
        fontWeight: FontWeight.bold,
        backgroundColor: HColor.gray1,
      ),
      OptionModel(
        id: '2',
        text: '크랩스터\nCR6000',
        fontSize: 12.sp,
        textColor: HColor.gray3,
        alignment: Alignment.center,
        fontWeight: FontWeight.bold,
        backgroundColor: HColor.gray1,
      ),
      OptionModel(
        id: '3',
        text: 'CPSO',
        fontSize: 12.sp,
        textColor: HColor.gray3,
        alignment: Alignment.center,
        fontWeight: FontWeight.bold,
        backgroundColor: HColor.gray1,
      ),
      OptionModel(
        id: '4',
        text: '디지털트윈',
        fontSize: 12.sp,
        textColor: HColor.gray3,
        alignment: Alignment.center,
        fontWeight: FontWeight.bold,
        backgroundColor: HColor.gray1,
      ),
    ],

    // ✅ 정답 정보
    extraData: {
      'correctOptionId': '1',
      'correctNextStepId': 'step3-3-o',
      'wrongNextStepId': 'step3-3-x',
    },

    // ✅ 버튼 구성
    actions: [
      ActionButtonModel(
        id: 'prev',
        text: '이전',
        nextStepId: 'step3-2',
        isPrimary: false,
      ),
      ActionButtonModel(
        id: 'next',
        text: '다음',
        nextStepId: '', // 실제 이동은 onNext()에서 정답에 따라 동적 처리
        isPrimary: true,
      ),
    ],

    // ✅ 버튼 위치
    buttonLayout: ButtonLayoutType.spaced,
  ),

  // STEP 3-3-o
  SurveyStepModel(
    id: 'step3-3-o',
    type: StepType.quizInfo,

    stepNumber: 3,
    stepLabel: '[KRISO 콘텐츠 퀴즈]',

    title: '축 정답입니다!',
    extraData: {
      'imageUrl': 'assets/images/quiz/step_3-3-o_info.png',
      'accentColor': 'green',
    },
    actions: [
      ActionButtonModel(
        id: 'next',
        text: '다음',
        nextStepId: 'step3-4',
        isPrimary: false,
      ),
    ],
  ),

  // STEP 3-3-x
  SurveyStepModel(
    id: 'step3-3-x',
    type: StepType.quizInfo,

    stepNumber: 3,
    stepLabel: '[KRISO 콘텐츠 퀴즈]',

    title: '아쉽지만, 틀렸어요!',
    extraData: {
      'imageUrl': 'assets/images/quiz/step_3-3-x_info.png',
      'accentColor': 'red',
    },
    actions: [
      ActionButtonModel(
        id: 'next',
        text: '다음',
        nextStepId: 'step3-4',
        isPrimary: false,
      ),
    ],
  ),

  // STEP 3-4
  SurveyStepModel(
    id: 'step3-4',
    type: StepType.quizInfo,

    stepNumber: 3,
    stepLabel: '[KRISO 콘텐츠 퀴즈]',

    title: '퀴즈 완료!',
    extraData: {
      'imageUrl': 'assets/images/quiz/step_3-4_info.png',
    },
    actions: [
      ActionButtonModel(
        id: 'next',
        text: '완료',
        nextStepId: 'step4-1',
        isPrimary: false,
      ),
    ],
  ),

  // STEP 4-1
  SurveyStepModel(
    id: 'step4-1',
    type: StepType.singleRowSelection,

    stepNumber: 4,
    stepLabel: '[KRISO 수요조사]',

    title: '1. KRISO를 처음 접하게 된 경로는 무엇입니까?',

    options: [
      OptionModel(
        id: '1',
        text: '교수·강의·학과 소개',
        fontSize: 11.sp,
        textColor: HColor.gray3,
        alignment: Alignment.center,
        fontWeight: FontWeight.bold,
        borderRadius: 10.r,
        backgroundColor: HColor.gray1,
        padding: EdgeInsets.symmetric(vertical: 10.h),
      ),
      OptionModel(
        id: '2',
        text: '뉴스·언론 기사',
        fontSize: 11.sp,
        textColor: HColor.gray3,
        alignment: Alignment.center,
        fontWeight: FontWeight.bold,
        borderRadius: 10.r,
        backgroundColor: HColor.gray1,
        padding: EdgeInsets.symmetric(vertical: 10.h),
      ),
      OptionModel(
        id: '3',
        text: '학회·학술대회',
        fontSize: 11.sp,
        textColor: HColor.gray3,
        alignment: Alignment.center,
        fontWeight: FontWeight.bold,
        borderRadius: 10.r,
        backgroundColor: HColor.gray1,
        padding: EdgeInsets.symmetric(vertical: 10.h),
      ),
      OptionModel(
        id: '4',
        text: '인터넷 검색\n·\n홈페이지',
        fontSize: 11.sp,
        textColor: HColor.gray3,
        alignment: Alignment.center,
        fontWeight: FontWeight.bold,
        borderRadius: 10.r,
        backgroundColor: HColor.gray1,
        padding: EdgeInsets.symmetric(vertical: 10.h),
      ),
      OptionModel(
        id: '5',
        text: '친구·선후배',
        fontSize: 11.sp,
        textColor: HColor.gray3,
        alignment: Alignment.center,
        fontWeight: FontWeight.bold,
        borderRadius: 10.r,
        backgroundColor: HColor.gray1,
        padding: EdgeInsets.symmetric(vertical: 10.h),
      ),
    ],

    actions: [
      ActionButtonModel(
        id: 'prev',
        text: '이전',
        nextStepId: 'step3-4',
        isPrimary: false,
      ),
      ActionButtonModel(
        id: 'next',
        text: '다음',
        nextStepId: 'step4-2',
        isPrimary: true,
      ),
    ],

    buttonLayout: ButtonLayoutType.spaced,
  ),

  // STEP 4-2
  SurveyStepModel(
    id: 'step4-2',
    type: StepType.multiRowSelection,

    stepNumber: 4,
    stepLabel: '[KRISO 수요조사]',

    title: '2. KRISO에 대해 떠오르는 이미지는 무엇입니까? (복수 선택 가능)',

    options: [
      OptionModel(
        id: '1',
        text: '국가 연구기관',
        fontSize: 11.sp,
        textColor: HColor.gray3,
        alignment: Alignment.center,
        fontWeight: FontWeight.bold,
        borderRadius: 10.r,
        backgroundColor: HColor.gray1,
        padding: EdgeInsets.symmetric(vertical: 10.h),
        isMultipleSelectable: true,
        maxSelectable: 5,
      ),
      OptionModel(
        id: '2',
        text: '미래형 선박\n·\n조선 연구소',
        fontSize: 11.sp,
        textColor: HColor.gray3,
        alignment: Alignment.center,
        fontWeight: FontWeight.bold,
        borderRadius: 10.r,
        backgroundColor: HColor.gray1,
        padding: EdgeInsets.symmetric(vertical: 10.h),
        isMultipleSelectable: true,
        maxSelectable: 5,
      ),
      OptionModel(
        id: '3',
        text: '해양에너지·친환경 연구소',
        fontSize: 11.sp,
        textColor: HColor.gray3,
        alignment: Alignment.center,
        fontWeight: FontWeight.bold,
        borderRadius: 10.r,
        backgroundColor: HColor.gray1,
        padding: EdgeInsets.symmetric(vertical: 10.h),
        isMultipleSelectable: true,
        maxSelectable: 5,
      ),
      OptionModel(
        id: '4',
        text: '국제 협력 연구기관',
        fontSize: 11.sp,
        textColor: HColor.gray3,
        alignment: Alignment.center,
        fontWeight: FontWeight.bold,
        borderRadius: 10.r,
        backgroundColor: HColor.gray1,
        padding: EdgeInsets.symmetric(vertical: 10.h),
        isMultipleSelectable: true,
        maxSelectable: 5,
      ),
      OptionModel(
        id: '5',
        text: '취업·연구 기회\n제공기관',
        fontSize: 11.sp,
        textColor: HColor.gray3,
        alignment: Alignment.center,
        fontWeight: FontWeight.bold,
        borderRadius: 10.r,
        backgroundColor: HColor.gray1,
        padding: EdgeInsets.symmetric(vertical: 10.h),
        isMultipleSelectable: true,
        maxSelectable: 5,
      ),
    ],

    actions: [
      ActionButtonModel(
        id: 'prev',
        text: '이전',
        nextStepId: 'step4-1',
        isPrimary: false,
      ),
      ActionButtonModel(
        id: 'next',
        text: '다음',
        nextStepId: 'step4-3',
        isPrimary: true,
      ),
    ],

    buttonLayout: ButtonLayoutType.spaced,
  ),

  // STEP 4-3
  SurveyStepModel(
    id: 'step4-3',
    type: StepType.singleRowSelection,

    stepNumber: 4,
    stepLabel: '[KRISO 수요조사]',

    title: '3. KRISO의 대표 연구분야 중 가장 관심 있는 분야는 무엇입니까?',

    options: [
      OptionModel(
        id: '1',
        text: '친환경 선박·탄소중립 추진 기술',
        fontSize: 10.sp,
        textColor: HColor.gray3,
        alignment: Alignment.center,
        fontWeight: FontWeight.bold,
        borderRadius: 10.r,
        backgroundColor: HColor.gray1,
        padding: EdgeInsets.symmetric(vertical: 10.h),
      ),
      OptionModel(
        id: '2',
        text: '자율운항선박',
        fontSize: 10.sp,
        textColor: HColor.gray3,
        alignment: Alignment.center,
        fontWeight: FontWeight.bold,
        borderRadius: 10.r,
        backgroundColor: HColor.gray1,
        padding: EdgeInsets.symmetric(vertical: 10.h),
      ),
      OptionModel(
        id: '3',
        text: '해양로봇·통신,\n스마트 해양 플랫폼',
        fontSize: 9.sp,
        textColor: HColor.gray3,
        alignment: Alignment.center,
        fontWeight: FontWeight.bold,
        borderRadius: 10.r,
        backgroundColor: HColor.gray1,
        padding: EdgeInsets.symmetric(vertical: 10.h),
      ),
      OptionModel(
        id: '4',
        text: '해양 재난\n·\n사고 대응',
        fontSize: 10.sp,
        textColor: HColor.gray3,
        alignment: Alignment.center,
        fontWeight: FontWeight.bold,
        borderRadius: 10.r,
        backgroundColor: HColor.gray1,
        padding: EdgeInsets.symmetric(vertical: 10.h),
      ),
      OptionModel(
        id: '5',
        text: '해양에너지\n·\n해양플랜트',
        fontSize: 10.sp,
        textColor: HColor.gray3,
        alignment: Alignment.center,
        fontWeight: FontWeight.bold,
        borderRadius: 10.r,
        backgroundColor: HColor.gray1,
        padding: EdgeInsets.symmetric(vertical: 10.h),
      ),
      OptionModel(
        id: '6',
        text: '선형·선박 구조',
        fontSize: 10.sp,
        textColor: HColor.gray3,
        alignment: Alignment.center,
        fontWeight: FontWeight.bold,
        borderRadius: 10.r,
        backgroundColor: HColor.gray1,
        padding: EdgeInsets.symmetric(vertical: 10.h),
      ),
    ],

    actions: [
      ActionButtonModel(
        id: 'prev',
        text: '이전',
        nextStepId: 'step4-2',
        isPrimary: false,
      ),
      ActionButtonModel(
        id: 'next',
        text: '다음',
        nextStepId: 'step4-4',
        isPrimary: true,
      ),
    ],

    buttonLayout: ButtonLayoutType.spaced,
  ),

  // STEP 20: 수요조사 4-4
  SurveyStepModel(
    id: 'step4-4',
    type: StepType.multiRowSelection,

    stepNumber: 4,
    stepLabel: '[KRISO 수요조사]',

    title: '4. KRISO 연구분야 중 미래세대를 위해 가장 꼭 필요한 연구 분야는 무엇이라고 생각하십니까? (복수 선택 3개 가능)',

    options: [
      OptionModel(
        id: '1',
        text: '선박 성능\n고도화 및 미래\n선박 핵심\n원천 기술\n(SMR선박,\n쇄빙선, 이산화탄소\n포집선 등)',
        fontSize: 6.sp,
        textColor: HColor.gray3,
        alignment: Alignment.center,
        fontWeight: FontWeight.bold,
        borderRadius: 10.r,
        backgroundColor: HColor.gray1,
        padding: EdgeInsets.symmetric(vertical: 10.h),
        isMultipleSelectable: true,
        maxSelectable: 3,
      ),
      OptionModel(
        id: '2',
        text: '친환경 선박\n기술',
        fontSize: 8.sp,
        textColor: HColor.gray3,
        alignment: Alignment.center,
        fontWeight: FontWeight.bold,
        borderRadius: 10.r,
        backgroundColor: HColor.gray1,
        padding: EdgeInsets.symmetric(vertical: 10.h),
        isMultipleSelectable: true,
        maxSelectable: 3,
      ),
      OptionModel(
        id: '3',
        text: '자율운항 선박 기술',
        fontSize: 8.sp,
        textColor: HColor.gray3,
        alignment: Alignment.center,
        fontWeight: FontWeight.bold,
        borderRadius: 10.r,
        backgroundColor: HColor.gray1,
        padding: EdgeInsets.symmetric(vertical: 10.h),
        isMultipleSelectable: true,
        maxSelectable: 3,
      ),
      OptionModel(
        id: '4',
        text: '신개념\n해양플랜트\n기술',
        fontSize: 8.sp,
        textColor: HColor.gray3,
        alignment: Alignment.center,
        fontWeight: FontWeight.bold,
        borderRadius: 10.r,
        backgroundColor: HColor.gray1,
        padding: EdgeInsets.symmetric(vertical: 10.h),
        isMultipleSelectable: true,
        maxSelectable: 3,
      ),
      OptionModel(
        id: '5',
        text: '친환경연료\n저장 및 이송\n기술',
        fontSize: 8.sp,
        textColor: HColor.gray3,
        alignment: Alignment.center,
        fontWeight: FontWeight.bold,
        borderRadius: 10.r,
        backgroundColor: HColor.gray1,
        padding: EdgeInsets.symmetric(vertical: 10.h),
        isMultipleSelectable: true,
        maxSelectable: 3,
      ),
      OptionModel(
        id: '6',
        text: '해양 그린 에너지\n및\n수소 생산기술',
        fontSize: 7.sp,
        textColor: HColor.gray3,
        alignment: Alignment.center,
        fontWeight: FontWeight.bold,
        borderRadius: 10.r,
        backgroundColor: HColor.gray1,
        padding: EdgeInsets.symmetric(vertical: 10.h),
        isMultipleSelectable: true,
        maxSelectable: 3,
      ),
      OptionModel(
        id: '7',
        text: '군집(집단)해양\n무인 체계 및\n로봇·센싱\n기술',
        fontSize: 8.sp,
        textColor: HColor.gray3,
        alignment: Alignment.center,
        fontWeight: FontWeight.bold,
        borderRadius: 10.r,
        backgroundColor: HColor.gray1,
        padding: EdgeInsets.symmetric(vertical: 10.h),
        isMultipleSelectable: true,
        maxSelectable: 3,
      ),
      OptionModel(
        id: '8',
        text: '해양 데이터\n통신 활용\n안전관리 · 에측',
        fontSize: 8.sp,
        textColor: HColor.gray3,
        alignment: Alignment.center,
        fontWeight: FontWeight.bold,
        borderRadius: 10.r,
        backgroundColor: HColor.gray1,
        padding: EdgeInsets.symmetric(vertical: 10.h),
        isMultipleSelectable: true,
        maxSelectable: 3,
      ),
    ],

    actions: [
      ActionButtonModel(
        id: 'prev',
        text: '이전',
        nextStepId: 'step4-3',
        isPrimary: false,
      ),
      ActionButtonModel(
        id: 'next',
        text: '다음',
        nextStepId: 'step4-5',
        isPrimary: true,
      ),
    ],

    buttonLayout: ButtonLayoutType.spaced,
  ),

  // STEP 21: 수요조사 4-5
  SurveyStepModel(
    id: 'step4-5',
    type: StepType.singleRowSelection,

    stepNumber: 4,
    stepLabel: '[KRISO 수요조사]',

    title: '5. KRISO와 함께 하고 싶은 청년·대학생 지원 프로그램은 무엇입니까?',

    options: [
      OptionModel(
        id: '1',
        text: '연구소 시설\n체험 및 견학',
        fontSize: 7.sp,
        textColor: HColor.gray3,
        alignment: Alignment.center,
        fontWeight: FontWeight.bold,
        borderRadius: 10.r,
        backgroundColor: HColor.gray1,
        padding: EdgeInsets.symmetric(vertical: 10.h),
      ),
      OptionModel(
        id: '2',
        text: '인턴십·현장\n실습',
        fontSize: 7.sp,
        textColor: HColor.gray3,
        alignment: Alignment.center,
        fontWeight: FontWeight.bold,
        borderRadius: 10.r,
        backgroundColor: HColor.gray1,
        padding: EdgeInsets.symmetric(vertical: 10.h),
      ),
      OptionModel(
        id: '3',
        text: '자격증·\n전문교육\n과정 지원',
        fontSize: 7.sp,
        textColor: HColor.gray3,
        alignment: Alignment.center,
        fontWeight: FontWeight.bold,
        borderRadius: 10.r,
        backgroundColor: HColor.gray1,
        padding: EdgeInsets.symmetric(vertical: 10.h),
      ),
      OptionModel(
        id: '4',
        text: '창업·스타트업\n지원',
        fontSize: 7.sp,
        textColor: HColor.gray3,
        alignment: Alignment.center,
        fontWeight: FontWeight.bold,
        borderRadius: 10.r,
        backgroundColor: HColor.gray1,
        padding: EdgeInsets.symmetric(vertical: 10.h),
      ),
      OptionModel(
        id: '5',
        text: '연구과제 참여\n(캡스톤디자인,\n공동연구)',
        fontSize: 7.sp,
        textColor: HColor.gray3,
        alignment: Alignment.center,
        fontWeight: FontWeight.bold,
        borderRadius: 10.r,
        backgroundColor: HColor.gray1,
        padding: EdgeInsets.symmetric(vertical: 10.h),
      ),
      OptionModel(
        id: '6',
        text: '멘토링·네트워킹\n프로그램',
        fontSize: 7.sp,
        textColor: HColor.gray3,
        alignment: Alignment.center,
        fontWeight: FontWeight.bold,
        borderRadius: 10.r,
        backgroundColor: HColor.gray1,
        padding: EdgeInsets.symmetric(vertical: 10.h),
      ),
      OptionModel(
        id: '7',
        text: '해양기술\n공모전·\n아이디어톤',
        fontSize: 7.sp,
        textColor: HColor.gray3,
        alignment: Alignment.center,
        fontWeight: FontWeight.bold,
        borderRadius: 10.r,
        backgroundColor: HColor.gray1,
        padding: EdgeInsets.symmetric(vertical: 10.h),
      ),
      OptionModel(
        id: '8',
        text: '국제 교류·\n연수 프로그램',
        fontSize: 7.sp,
        textColor: HColor.gray3,
        alignment: Alignment.center,
        fontWeight: FontWeight.bold,
        borderRadius: 10.r,
        backgroundColor: HColor.gray1,
        padding: EdgeInsets.symmetric(vertical: 10.h),
      ),
    ],

    actions: [
      ActionButtonModel(
        id: 'prev',
        text: '이전',
        nextStepId: 'step4-4',
        isPrimary: false,
      ),
      ActionButtonModel(
        id: 'next',
        text: '다음',
        nextStepId: 'step4-6',
        isPrimary: true,
      ),
    ],

    buttonLayout: ButtonLayoutType.spaced,
  ),

  // STEP 24: 수요조사 4-6
  SurveyStepModel(
    id: 'step4-6',
    type: StepType.singleRowSelection,

    stepNumber: 4,
    stepLabel: '[KRISO 수요조사]',

    title: '6. KRISO 연구 성과를 접하는 방식으로 가장 선호하는 것은 무엇입니까?',

    options: [
      OptionModel(
        id: '1',
        text: '유튜브·인스타그램 등 SNS 콘텐츠',
        fontSize: 11.sp,
        textColor: HColor.gray3,
        alignment: Alignment.center,
        fontWeight: FontWeight.bold,
        borderRadius: 10.r,
        backgroundColor: HColor.gray1,
        padding: EdgeInsets.symmetric(vertical: 10.h),
      ),
      OptionModel(
        id: '2',
        text: '오프라인 체험·전시',
        fontSize: 11.sp,
        textColor: HColor.gray3,
        alignment: Alignment.center,
        fontWeight: FontWeight.bold,
        borderRadius: 10.r,
        backgroundColor: HColor.gray1,
        padding: EdgeInsets.symmetric(vertical: 10.h),
      ),
      OptionModel(
        id: '3',
        text: '웹·앱 기반 인터랙티브\n콘텐츠',
        fontSize: 11.sp,
        textColor: HColor.gray3,
        alignment: Alignment.center,
        fontWeight: FontWeight.bold,
        borderRadius: 10.r,
        backgroundColor: HColor.gray1,
        padding: EdgeInsets.symmetric(vertical: 10.h),
      ),
      OptionModel(
        id: '4',
        text: '연구자 강연·세미나',
        fontSize: 11.sp,
        textColor: HColor.gray3,
        alignment: Alignment.center,
        fontWeight: FontWeight.bold,
        borderRadius: 10.r,
        backgroundColor: HColor.gray1,
        padding: EdgeInsets.symmetric(vertical: 10.h),
      ),
    ],

    actions: [
      ActionButtonModel(
        id: 'prev',
        text: '이전',
        nextStepId: 'step4-5',
        isPrimary: false,
      ),
      ActionButtonModel(
        id: 'next',
        text: '다음',
        nextStepId: 'final',
        isPrimary: true,
      ),
    ],

    buttonLayout: ButtonLayoutType.spaced,
  ),

  // STEP final: 참여완료 페이지
  SurveyStepModel(
    id: 'final',
    type: StepType.finalComplete,

    stepNumber: 4,
    stepLabel: 'FINISH',

    title: '참여 완료!',
    extraData: {
      'imageUrl': 'assets/images/content_complete.png',
    },
    actions: [
      ActionButtonModel(
        id: 'submit',
        text: '처음으로',
        nextStepId: 'submit',
        isPrimary: false,
      ),
    ],
  ),

];

final List<Map<String, String>> seriesA = [
  {'num': '1편', 'title': '선박이 위치를\n찾는 방법', 'img': 'assets/images/A_1.png'},
  {'num': '2편', 'title': 'KRISO의 친환경대체\n연료해상실증선박?', 'img': 'assets/images/A_2.png'},
  {'num': '3편', 'title': 'KRISO의\n해양그린수소?', 'img': 'assets/images/A_3.png'},
  {'num': '4편', 'title': 'KRISO의\n전기추진선박?', 'img': 'assets/images/A_4.png'},
  {'num': '5편', 'title': '해양생물을 괴롭히는\n선박소음 !?', 'img': 'assets/images/A_5.png'},
  {'num': '6편', 'title': '심해에서도 로봇이\n활용되고 있다는 사실', 'img': 'assets/images/A_6.png'},
  {'num': '7편', 'title': '바다 위의 테슬라?\n자율운항선박\n쉽게 알려드림', 'img': 'assets/images/A_7.png'},
  {'num': '8편~9편', 'title': '질문에 답하다', 'img': 'assets/images/A_8.png'},
  {'num': '10편', 'title': "'꿈의 항로'\n북극이 현실로!\n지금 상황 총정리", 'img': 'assets/images/A_9.png'},
];

final List<Map<String, String>> seriesB = [
  {'num': '1편', 'title': '여름방학,\n바다로 떠난 하루', 'img': 'assets/images/B_1.png'},
  {'num': '2편', 'title': '벚꽃운동회\n현장 속으로', 'img': 'assets/images/B_2.png'},
  {'num': '3편', 'title': '책향기 동아리의\n전통시장 탐방', 'img': 'assets/images/B_3.png'},
  {'num': '4편', 'title': '선박해양플랜트연구소\n밸런스게임', 'img': 'assets/images/B_4.png'},
  {'num': '5편', 'title': '해양플랜트 서비스산업\n아이디어 경진대회', 'img': 'assets/images/B_5.png'},
  {'num': '6편', 'title': 'KRISO\n해양과학카페', 'img': 'assets/images/B_6.png'},
  {'num': '7편', 'title': '크리소의 동호회를\n소개합니다!', 'img': 'assets/images/B_7.png'},
  
];

final List<Map<String, String>> seriesC = [
  {'num': '1편', 'title': '배가 스스로 운전하면,\n우리는 뭐해요?', 'img': 'assets/images/C_1.png'},
  {'num': '2편', 'title': '거제의 숨은 보물!\n해양플랜트산업지원센터\n소개', 'img': 'assets/images/C_2.png'},
  {'num': '3편', 'title': '구조디지털 트윈으로\n20년 후 해양플랜트 상\n태를 알 수 있다', 'img': 'assets/images/C_3.png'},
  {'num': '4편', 'title': '바다에서\n초고속 무선통신이\n가능하다?!', 'img': 'assets/images/C_4.png'},
  {'num': '5편', 'title': '지금 전기추진\n차도선은?', 'img': 'assets/images/C_5.png'},
  {'num': '6편', 'title': '해양에너지?\n해양구조물?', 'img': 'assets/images/C_6.png'},
  {'num': '7편', 'title': '자율운항선박\n궁금해?', 'img': 'assets/images/C_7.png'},
  {'num': '8편', 'title': 'KRISO 신입사원 인터뷰\n크리소 입사했소!\n어떻게 입사했소?', 'img': 'assets/images/C_8.png'},
  {'num': '9편', 'title': '실패를 두려워 하지 않는\n올해의 KRISO인\n홍사영 책임연구원', 'img': 'assets/images/C_9.png'},
  {'num': '10편', 'title': '해양플랜트산업지원센터\n거세 센터에서는\n무슨일을 할까?1편', 'img': 'assets/images/C_10.png'},
  {'num': '11편', 'title': '해양플랜트산업지원센터\n거세 센터에서는\n무슨일을 할까?2편', 'img': 'assets/images/C_11.png'},
  
];

final List<Map<String, String>> seriesD = [
  {'num': '1편', 'title': 'KRISO 설립\n50주년 기념영상', 'img': 'assets/images/D_1.png'},
  {'num': '2편', 'title': 'KRISO 50년 성과\n및 비전 선포 영상', 'img': 'assets/images/D_2.png'},
  {'num': '3편', 'title': '선박해양플랜트연구소\n홍보 및 브랜드 영상', 'img': 'assets/images/D_3.png'},
  {'num': '4편', 'title': '해양플랜트산업지원센터\n- 거제', 'img': 'assets/images/D_4.png'},
  {'num': '5편', 'title': '해수에너지연구센터\n- 고성', 'img': 'assets/images/D_5.png'},
  {'num': '6편', 'title': '자율운항선박실증연구센터\n- 울산', 'img': 'assets/images/D_6.png'},
  {'num': '7편', 'title': '심해공학연구센터\n- 부산', 'img': 'assets/images/D_7.png'},
  {'num': '8편', 'title': 'KRISO 북극 연구\n홍보영상', 'img': 'assets/images/D_8.png'},
  {'num': '9편', 'title': '전기추진 차도선\n홍보영상', 'img': 'assets/images/D_9.png'},
];
