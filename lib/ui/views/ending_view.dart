import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:greenfestival/routes/app_pages.dart';
import 'package:greenfestival/ui/controllers/survey_controller.dart';
import 'package:greenfestival/ui/controllers/survey_ui_controller.dart';
import 'package:greenfestival/ui/widgets/start_over_button.dart';

class EndingView extends StatefulWidget {
  const EndingView({super.key});

  @override
  State<EndingView> createState() => _EndingViewState();
}

class _EndingViewState extends State<EndingView> {
  Timer? _returnTimer;

  @override
  void initState() {
    super.initState();
    _returnTimer = Timer(const Duration(seconds: 4), _returnToIntro);
  }

  @override
  void dispose() {
    _returnTimer?.cancel();
    super.dispose();
  }

  void _returnToIntro() {
    if (!mounted) return;

    if (Get.isRegistered<SurveyController>()) {
      Get.find<SurveyController>().reset();
    }

    if (Get.isRegistered<SurveyUiController>()) {
      final uiController = Get.find<SurveyUiController>();
      uiController.selectedIndexes.clear();
      uiController.selectedTitles.clear();
      uiController.currentPage.value = 0;
      uiController.resetUiState();
    }

    Get.offAllNamed(AppPages.INTRO);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/ending_background.png',
            fit: BoxFit.fill,
            filterQuality: FilterQuality.high,
          ),
          const Positioned(
            left: 18,
            bottom: 18,
            child: SafeArea(child: StartOverButton()),
          ),
        ],
      ),
    );
  }
}
