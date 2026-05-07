import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:greenfestival/routes/app_pages.dart';
import 'package:greenfestival/ui/controllers/survey_controller.dart';
import 'package:greenfestival/ui/widgets/festival_page_title.dart';
import 'package:greenfestival/ui/widgets/start_over_button.dart';

class ReadyView extends StatefulWidget {
  const ReadyView({super.key});

  @override
  State<ReadyView> createState() => _ReadyViewState();
}

class _ReadyViewState extends State<ReadyView> {
  static const _buttonColor = Color(0xFF4A9638);
  bool _submitting = false;

  Future<void> _submitParticipant(SurveyController surveyController) async {
    if (_submitting) return;

    setState(() => _submitting = true);
    try {
      await surveyController.sendParticipantInfoToServer();
      if (!mounted) return;
      Get.offAllNamed(AppPages.ENDING);
    } catch (error) {
      if (!mounted) return;
      Get.snackbar(
        '참여자 등록 실패',
        '$error',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final surveyController = Get.find<SurveyController>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final nickname = surveyController.nickname.value;
          final displayNickname = nickname.isEmpty ? '닉네임' : nickname;

          final titleTopGap = FestivalPageTitle.topGap(height);
          final titleToCardGap = (height * 0.035).clamp(18.0, 28.0);
          final maxContentWidth = math.max(320.0, width - 48);
          final contentWidth = math.min(
            (width * 0.84).clamp(516.0, 912.0),
            maxContentWidth,
          );
          final cardPaddingX = (width * 0.043).clamp(31.0, 55.0);
          final cardPaddingY = (height * 0.038).clamp(26.0, 41.0);
          final cardToButtonGap = (height * 0.029).clamp(19.0, 29.0);
          final buttonWidth = (contentWidth * 0.62).clamp(324.0, 516.0);
          final buttonHeight = (height * 0.089).clamp(70.0, 89.0);
          final bodyFontSize = (width * 0.024).clamp(24.0, 34.0);
          final highlightFontSize = (width * 0.030).clamp(29.0, 41.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/images/background.png',
                fit: BoxFit.fill,
                filterQuality: FilterQuality.high,
              ),
              SafeArea(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: titleTopGap,
                      bottom: buttonHeight + 64,
                    ),
                    child: Column(
                      children: [
                        FestivalPageTitle('$displayNickname 님 준비가 완료되었습니다.'),
                        SizedBox(height: titleToCardGap),
                        Container(
                          width: contentWidth,
                          padding: EdgeInsets.symmetric(
                            horizontal: cardPaddingX,
                            vertical: cardPaddingY,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.86),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '지금부터 일상 속 숨어있는\n황금씨앗을 모아 숲을 완성해주세요!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: bodyFontSize,
                                  fontWeight: FontWeight.w500,
                                  height: 1.35,
                                ),
                              ),
                              SizedBox(
                                height: (height * 0.012).clamp(8.0, 14.0),
                              ),
                              Text(
                                '스탬프투어\n“일상속 황금씨앗모으기”',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: highlightFontSize,
                                  fontWeight: FontWeight.w500,
                                  height: 1.15,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: cardToButtonGap),
                        SizedBox(
                          width: buttonWidth,
                          height: buttonHeight,
                          child: ElevatedButton(
                            onPressed: _submitting
                                ? null
                                : () => _submitParticipant(surveyController),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _buttonColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: EdgeInsets.zero,
                              shape: const StadiumBorder(),
                            ),
                            child: Text(
                              _submitting ? '등록 중...' : '시작하기',
                              style: TextStyle(
                                fontSize: (width * 0.023).clamp(24.0, 32.0),
                                fontWeight: FontWeight.w500,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Positioned(
                left: 18,
                bottom: 18,
                child: SafeArea(child: StartOverButton()),
              ),
            ],
          );
        },
      ),
    );
  }
}
