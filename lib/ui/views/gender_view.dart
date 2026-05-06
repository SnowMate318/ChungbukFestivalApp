import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:greenfestival/routes/app_pages.dart';
import 'package:greenfestival/ui/controllers/survey_controller.dart';
import 'package:greenfestival/ui/widgets/festival_page_title.dart';
import 'package:greenfestival/ui/widgets/start_over_button.dart';

class GenderView extends StatefulWidget {
  const GenderView({super.key});

  @override
  State<GenderView> createState() => _GenderViewState();
}

class _GenderViewState extends State<GenderView> {
  final SurveyController _surveyController = Get.find<SurveyController>();
  Timer? _navigationTimer;
  String _selectedGender = '';

  @override
  void initState() {
    super.initState();
    _selectedGender = _surveyController.gender.value;
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  void _selectGender(String gender) {
    setState(() => _selectedGender = gender);
    _surveyController.setGender(gender);

    _navigationTimer?.cancel();
    _navigationTimer = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      Get.toNamed(AppPages.AGE);
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
          final titleToButtonsGap = (height * 0.07).clamp(38.0, 70.0);
          final contentWidth = (width * 0.82).clamp(680.0, 1120.0);
          final buttonGap = (width * 0.022).clamp(18.0, 34.0);
          final buttonWidth = (contentWidth - buttonGap) / 2;
          final buttonHeight = (height * 0.23).clamp(160.0, 220.0);

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
                        FestivalPageTitle('$displayNickname 님의 성별을 입력해주세요'),
                        SizedBox(height: titleToButtonsGap),
                        SizedBox(
                          width: contentWidth,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _GenderOptionButton(
                                label: '남',
                                width: buttonWidth,
                                height: buttonHeight,
                                selected: _selectedGender == '남',
                                onTap: () => _selectGender('남'),
                              ),
                              SizedBox(width: buttonGap),
                              _GenderOptionButton(
                                label: '여',
                                width: buttonWidth,
                                height: buttonHeight,
                                selected: _selectedGender == '여',
                                onTap: () => _selectGender('여'),
                              ),
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

class _GenderOptionButton extends StatelessWidget {
  const _GenderOptionButton({
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
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black,
            fontSize: 34,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ),
    );
  }
}
