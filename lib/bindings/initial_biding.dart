import 'package:get/get.dart';
import '../ui/controllers/survey_controller.dart';
import '../ui/controllers/survey_ui_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(SurveyController(), permanent: true);
    Get.put(SurveyUiController(), permanent: true);
  }
}
