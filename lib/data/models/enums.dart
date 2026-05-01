enum StepType {
  singleRowSelection,   // 1줄 카드 선택
  doubleRowSelection,   // 2줄 카드 선택
  multiRowSelection,    // 다중 선택
  quizSelection,        // 퀴즈 선택
  quizInfo,             // 퀴즈 정답 정보
  contentOrderSelection,// 콘텐츠 주문
  orderConfirm,         // 주문 확인
  orderComplete,        // 주문 완료
  finalComplete,        // 최종 완료
}

enum ButtonLayoutType {
  spaced,   // 좌우로 떨어진 (이전 / 다음)
  centered, // 중앙 배치 (네 참여할게요 / 아니요)
}
