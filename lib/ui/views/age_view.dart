import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:greenfestival/routes/app_pages.dart';
import 'package:greenfestival/ui/controllers/survey_controller.dart';
import 'package:greenfestival/ui/widgets/festival_page_title.dart';
import 'package:greenfestival/ui/widgets/start_over_button.dart';

class AgeView extends StatefulWidget {
  const AgeView({super.key});

  @override
  State<AgeView> createState() => _AgeViewState();
}

class _AgeViewState extends State<AgeView> {
  static const _ages = [
    '0~12세',
    '13~18세',
    '20대',
    '30대',
    '40대',
    '50대',
    '60대',
    '60대이상',
  ];

  final SurveyController _surveyController = Get.find<SurveyController>();
  Timer? _navigationTimer;
  String _selectedAge = '';

  @override
  void initState() {
    super.initState();
    _selectedAge = _surveyController.age.value;
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  void _selectAge(String age) {
    setState(() => _selectedAge = age);
    _surveyController.setAge(age);

    _navigationTimer?.cancel();
    _navigationTimer = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      Get.toNamed(AppPages.PARTICIPANT_COUNT);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final nickname = _surveyController.nickname.value;
          final displayNickname = nickname.isEmpty ? '닉네임' : nickname;

          final titleTopGap = FestivalPageTitle.topGap(height);
          final titleToButtonsGap = (height * 0.05).clamp(28.0, 48.0);
          final contentWidth = (width * 0.86).clamp(760.0, 1160.0);
          final buttonGap = (width * 0.008).clamp(8.0, 13.0);
          final buttonWidth =
              (contentWidth - (buttonGap * (_ages.length - 1))) / _ages.length;
          final buttonHeight = (height * 0.372).clamp(246.0, 350.0);

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
                    padding: EdgeInsets.only(top: titleTopGap, bottom: 92),
                    child: Column(
                      children: [
                        FestivalPageTitle('$displayNickname 님의 연령을 입력해 주세요'),
                        SizedBox(height: titleToButtonsGap),
                        SizedBox(
                          width: contentWidth,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (var i = 0; i < _ages.length; i++) ...[
                                _AgeOptionButton(
                                  label: _ages[i],
                                  width: buttonWidth,
                                  height: buttonHeight,
                                  selected: _selectedAge == _ages[i],
                                  onTap: () => _selectAge(_ages[i]),
                                ),
                                if (i != _ages.length - 1)
                                  SizedBox(width: buttonGap),
                              ],
                            ],
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

class _AgeOptionButton extends StatelessWidget {
  const _AgeOptionButton({
    required this.label,
    required this.width,
    required this.height,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final double width;
  final double height;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: width,
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF4A9638) : const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(8),
          border: selected ? null : Border.all(color: const Color(0xFFF2F2F2)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              offset: Offset(0, 2),
              blurRadius: 5,
            ),
          ],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF8C8C8C),
              fontSize: 18,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}
