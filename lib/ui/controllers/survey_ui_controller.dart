import 'package:get/get.dart';
import 'package:greenfestival/routes/app_pages.dart';
import '../../data/models/option_model.dart';
import 'survey_controller.dart';
import '../../config/style.dart';
import '../../data/models/enums.dart';

class SurveyUiController extends GetxController {
  final SurveyController surveyController = Get.find();

  /// 현재 화면의 선택된 옵션 id
  RxString selectedOption = ''.obs;

  /// 여러 개 선택 가능할 경우 (optionId 리스트)
  RxList<String> selectedOptions = <String>[].obs;

  /// 다음 버튼 활성화 여부
  RxBool isNextEnabled = false.obs;

  /// 화면 전환 중 애니메이션 상태
  RxBool isTransitioning = false.obs;

  /// 현재 단계의 버튼 위치 형태 (spaced or centered)
  RxString buttonLayout = 'spaced'.obs;

  /// 색상 상태 (디자인 제어용)
  final activeColor = HColor.blue1;
  final inactiveColor = HColor.gray3;

  RxInt currentPage = 0.obs;

  // 선택된 이미지 index 리스트
  final selectedIndexes = <int>[].obs;

  final selectedTitles = <String>[].obs;

  void nextPage(int totalPages) {
    if (currentPage.value < totalPages - 1) {
      currentPage.value++;
    }
  }

  void prevPage() {
    if (currentPage.value > 0) {
      currentPage.value--;
    }
  }

  void resetPage() {
    currentPage.value = 0;
  }

  // === 선택 로직 ===
  void onSelectOption(String stepId, OptionModel option) {
    final step = surveyController.steps.firstWhere((s) => s.id == stepId);

    // ✅ multiRowSelection 또는 Option 자체의 다중 선택 속성 확인
    final bool isMulti =
        option.isMultipleSelectable || step.type == StepType.multiRowSelection;

    if (isMulti) {
      // ✅ 현재 선택 상태 복사
      final currentSelections = List<String>.from(selectedOptions);

      // ✅ 이미 선택된 경우 → 해제
      if (currentSelections.contains(option.id)) {
        currentSelections.remove(option.id);
      } else {
        // ✅ 최대 선택 개수 제한
        final maxSelectable = option.maxSelectable ?? 2;
        if (currentSelections.length < maxSelectable) {
          currentSelections.add(option.id);
        } else {
          Get.snackbar(
            '선택 제한',
            '최대 $maxSelectable개까지만 선택할 수 있습니다.',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 2),
          );
          return; // 🚫 초과 시 리턴
        }
      }

      // ✅ 상태 반영
      selectedOptions.assignAll(currentSelections);
      surveyController.answers[stepId] = currentSelections;
      isNextEnabled.value = currentSelections.isNotEmpty;
    } else {
      // ✅ 단일 선택
      if (selectedOption.value == option.id) {
        // ✅ 같은 항목 클릭 시 해제
        selectedOption.value = '';
        surveyController.answers.remove(stepId);
        isNextEnabled.value = false;
      } else {
        // ✅ 새 항목 선택
        selectedOption.value = option.id;
        surveyController.answers[stepId] = option.id;
        isNextEnabled.value = true;

        // ✅ step2-1일 때, 선택된 option의 텍스트를 SurveyController에 저장
        if (stepId == 'step2-1') {
          surveyController.selectedContentTitle.value = option.text;
          print('🔹 step2-1 선택: ${option.text}');
        }
      }
    }

    // ✅ SurveyController에도 갱신 명령
    surveyController.update();
    update();
  }

  // === 다음 버튼 클릭 ===
  Future<void> onNext(String? nextStepId, {String? actionId}) async {
    if (isTransitioning.value) return;

    print('nextStepId: $nextStepId, actionId: $actionId');

    surveyController.previousStepId.value = surveyController.currentStepId;

    // ✅ 1️⃣ 뒤로가기(prev) 버튼이면 바로 이동
    if (actionId == 'prev') {
      surveyController.goToStep(nextStepId ?? '');
      resetUiState();
      return;
    }

    if (actionId == 'start') {
      surveyController.reset();
      Get.offAllNamed('/intro');
      print('Navigating to Intro');
      resetUiState();
      return;
    }

    if (actionId == 'submit' || nextStepId == 'submit') {
      surveyController.reset();
      Get.offAllNamed(AppPages.ENDING);
      print('Submit and Navigating to Ending');
      resetUiState();
      return;
    }

    // ✅ 2️⃣ quizSelection 전용 정답 분기
    final currentStep = surveyController.currentStep;
    if (currentStep.type == StepType.quizSelection) {
      final correctId = currentStep.extraData?['correctOptionId'];
      final correctNext = currentStep.extraData?['correctNextStepId'];
      final wrongNext = currentStep.extraData?['wrongNextStepId'];

      final selectedId = selectedOption.value;

      final nextId = (selectedId == correctId) ? correctNext : wrongNext;

      if (nextId != null && nextId.isNotEmpty) {
        surveyController.goToStep(nextId);
      }
    }
    // ✅ 3️⃣ 일반 이동 처리 (기존 nextStepId 우선)
    else if (nextStepId != null && nextStepId.isNotEmpty) {
      surveyController.goToStep(nextStepId);
    } else {
      surveyController.nextStep();
    }

    resetUiState();
  }

  // === 이전 버튼 클릭 ===
  void onPrev() {
    if (isTransitioning.value) return;
    surveyController.previousStepId.value = surveyController.currentStepId;

    surveyController.prevStep();
    resetUiState();
  }

  // === UI 상태 초기화 ===
  void resetUiState() {
    selectedOption.value = '';
    selectedOptions.clear();
    isNextEnabled.value = false;

    // 다음 단계의 레이아웃 정보 업데이트
    final layoutType = surveyController.currentStep.buttonLayout.name;
    buttonLayout.value = layoutType;
  }

  // === UI 색상 헬퍼 ===
  dynamic getOptionColor(String optionId) {
    return selectedOption.value == optionId ||
            selectedOptions.contains(optionId)
        ? activeColor
        : inactiveColor;
  }
}
