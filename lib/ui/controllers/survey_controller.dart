// ignore_for_file: avoid_print

import 'package:get/get.dart';
import '../../data/models/survey_step_model.dart';
import '../../data/models/option_model.dart';
import '../../data/models/sample_survey_data.dart';
import 'package:greenfestival/routes/app_pages.dart';
import 'package:greenfestival/services/festival_firestore_service.dart';

class SurveyController extends GetxController {
  final FestivalFirestoreService _festivalService = FestivalFirestoreService();

  static const nicknameAnswerKey = 'nickname';
  static const genderAnswerKey = 'gender';
  static const ageAnswerKey = 'age';
  static const participantCountAnswerKey = 'participantCount';
  static const residenceAnswerKey = 'residence';
  static const phoneNumberAnswerKey = 'phoneNumber';

  /// ✅ Firestore 인스턴스 추가
  // final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 전체 단계 리스트
  final List<SurveyStepModel> steps = sampleSurveySteps;

  /// 현재 단계 인덱스
  RxInt currentStepIndex = 0.obs;

  /// 이전 단계 ID (final 구분용)
  var previousStepId = ''.obs;

  /// 사용자 응답 저장소 (stepId: value)
  RxMap<String, dynamic> answers = <String, dynamic>{}.obs;

  /// 축제 참여 닉네임
  RxString nickname = ''.obs;

  /// 사용자 성별
  RxString gender = ''.obs;

  /// 사용자 연령대
  RxString age = ''.obs;

  /// 스탬프 투어 참여 인원
  RxString participantCount = ''.obs;

  /// 사용자 거주정보
  RxString residence = ''.obs;

  /// 사용자 휴대폰 번호
  RxString phoneNumber = ''.obs;

  /// 서버 전송 직전 payload 확인용
  RxMap<String, dynamic> pendingParticipantPayload = <String, dynamic>{}.obs;

  /// 마지막으로 Firestore에 생성된 참여자 uid
  RxString lastCreatedUserUid = ''.obs;

  /// 현재 단계 반환
  SurveyStepModel get currentStep => steps[currentStepIndex.value];

  /// 현재 단계 ID
  String get currentStepId => currentStep.id;

  /// 총 단계 수
  int get totalSteps => steps.length;

  var hasSubmitted = false.obs;

  // step2-1에서 선택된 콘텐츠 제목 저장
  var selectedContentTitle = ''.obs;

  void setNickname(String value) {
    final trimmedNickname = value.trim();
    nickname.value = trimmedNickname;

    if (trimmedNickname.isEmpty) {
      answers.remove(nicknameAnswerKey);
    } else {
      answers[nicknameAnswerKey] = trimmedNickname;
    }

    update();
  }

  void setGender(String value) {
    gender.value = value;

    if (value.isEmpty) {
      answers.remove(genderAnswerKey);
    } else {
      answers[genderAnswerKey] = value;
    }

    update();
  }

  void setAge(String value) {
    age.value = value;

    if (value.isEmpty) {
      answers.remove(ageAnswerKey);
    } else {
      answers[ageAnswerKey] = value;
    }

    update();
  }

  void setParticipantCount(String value) {
    participantCount.value = value;

    if (value.isEmpty) {
      answers.remove(participantCountAnswerKey);
    } else {
      answers[participantCountAnswerKey] = value;
    }

    update();
  }

  void setResidence(String value) {
    residence.value = value;

    if (value.isEmpty) {
      answers.remove(residenceAnswerKey);
    } else {
      answers[residenceAnswerKey] = value;
    }

    update();
  }

  void setPhoneNumber(String value) {
    phoneNumber.value = value;

    if (value.isEmpty) {
      answers.remove(phoneNumberAnswerKey);
    } else {
      answers[phoneNumberAnswerKey] = value;
    }

    update();
  }

  Map<String, dynamic> buildParticipantPayload() {
    return {
      nicknameAnswerKey: nickname.value,
      genderAnswerKey: gender.value,
      ageAnswerKey: age.value,
      participantCountAnswerKey: participantCount.value,
      residenceAnswerKey: residence.value,
      phoneNumberAnswerKey: phoneNumber.value,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  Future<String> sendParticipantInfoToServer() async {
    final payload = buildParticipantPayload();
    pendingParticipantPayload.assignAll(payload);

    return sendParticipantPayloadToServer(payload);
  }

  Future<String> sendParticipantPayloadToServer(
    Map<String, dynamic> payload,
  ) async {
    try {
      return _sendParticipantPayload(payload);
    } catch (e) {
      print('Failed to send participant payload: $e');
      rethrow;
    }
  }

  Future<String> _sendParticipantPayload(Map<String, dynamic> payload) async {
    final uid = await _festivalService.createUserFromSurveyPayload(payload);
    lastCreatedUserUid.value = uid;
    print('Participant stored in Firestore: $uid');
    return uid;
  }

  Future<bool> isNicknameDuplicated(String value) {
    return _festivalService.isNicknameDuplicated(value);
  }

  Future<bool> isPhoneNumberDuplicated(String value) {
    return _festivalService.isPhoneNumberDuplicated(value);
  }

  bool isValidPhoneNumber(String value) {
    return _festivalService.isValidPhoneNumber(value);
  }

  void startSurveyWithNickname(String value) {
    currentStepIndex.value = 0;
    previousStepId.value = '';
    selectedContentTitle.value = '';
    hasSubmitted.value = false;
    answers.clear();
    gender.value = '';
    age.value = '';
    participantCount.value = '';
    residence.value = '';
    phoneNumber.value = '';
    pendingParticipantPayload.clear();
    lastCreatedUserUid.value = '';
    setNickname(value);
  }

  /// 다음 단계로 이동
  void nextStep() {
    if (currentStepIndex.value < totalSteps - 1) {
      previousStepId.value = currentStepId;
      currentStepIndex.value++;
    }
  }

  /// 이전 단계로 이동
  void prevStep() {
    if (currentStepIndex.value > 0) {
      previousStepId.value = currentStepId;
      currentStepIndex.value--;
    } else {
      Get.toNamed(AppPages.INTRO);
    }
  }

  /// 특정 stepId로 이동
  void goToStep(String stepId) {
    print('answers: $answers');
    previousStepId.value = currentStepId;
    final index = steps.indexWhere((s) => s.id == stepId);
    if (index != -1) currentStepIndex.value = index;
  }

  /// 옵션 선택 시 호출
  void selectOption(String stepId, String optionId) {
    final step = steps.firstWhere((s) => s.id == stepId);
    final isMulti = step.options?.any((o) => o.isMultipleSelectable) ?? false;

    if (isMulti) {
      final currentList = List<String>.from(answers[stepId] ?? []);
      final selectedOption = step.options?.firstWhere(
        (o) => o.id == optionId,
        orElse: () => OptionModel(id: '', text: ''),
      );

      final maxSelectable = selectedOption?.maxSelectable ?? 2;

      if (currentList.contains(optionId)) {
        // ✅ 이미 선택된 경우 → 해제
        currentList.remove(optionId);
      } else {
        // ✅ 아직 선택되지 않은 경우
        if (currentList.length < maxSelectable) {
          currentList.add(optionId);
        } else {
          // 🚫 초과 선택 방지
          Get.snackbar(
            '선택 제한',
            '최대 $maxSelectable개까지만 선택할 수 있습니다.',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 2),
          );
        }
      }

      answers[stepId] = currentList;
    } else {
      // ✅ 단일 선택일 때도 다시 누르면 해제 가능하도록
      if (answers[stepId] == optionId) {
        answers.remove(stepId);
      } else {
        answers[stepId] = optionId;
      }
    }

    update(); // ✅ GetX 상태 갱신
  }

  /// 현재 단계의 응답이 유효한지 확인
  bool canProceedToNextStep() {
    final step = currentStep;
    // 선택지 있는 단계라면 최소 1개 선택되어야 함
    if (step.options != null && step.options!.isNotEmpty) {
      return answers.containsKey(step.id) &&
          (answers[step.id] is List
              ? (answers[step.id] as List).isNotEmpty
              : answers[step.id] != null);
    }
    return true;
  }

  Future<void> submitSurveyOnce() async {
    if (hasSubmitted.value) return;
    hasSubmitted.value = true;
    print('Survey JSON storage disabled. Skipping local survey save.');
  }

  void reset() {
    print('🧩 Resetting SurveyController...');
    currentStepIndex.value = 0;
    previousStepId.value = '';
    answers.clear();
    nickname.value = '';
    gender.value = '';
    age.value = '';
    participantCount.value = '';
    residence.value = '';
    phoneNumber.value = '';
    pendingParticipantPayload.clear();
    lastCreatedUserUid.value = '';
    selectedContentTitle.value = '';
    hasSubmitted.value = false;

    // ✅ 필요 시 다른 상태도 초기화
    update(); // GetBuilder 위젯 강제 갱신

    print('✅ SurveyController reset complete.');
  }
}
