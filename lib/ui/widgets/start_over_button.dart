import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:greenfestival/routes/app_pages.dart';
import 'package:greenfestival/ui/controllers/survey_controller.dart';

class StartOverButton extends StatelessWidget {
  const StartOverButton({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        if (Get.isRegistered<SurveyController>()) {
          Get.find<SurveyController>().reset();
        }
        Get.offAllNamed(AppPages.INTRO);
      },
      style: TextButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        foregroundColor: const Color(0xFF347C2A),
        minimumSize: const Size(88, 40),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(21),
          side: const BorderSide(color: Color(0xFF4B9238), width: 1.2),
        ),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      child: const Text('처음으로'),
    );
  }
}
