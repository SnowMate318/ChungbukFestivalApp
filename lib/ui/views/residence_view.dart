import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:greenfestival/routes/app_pages.dart';
import 'package:greenfestival/ui/controllers/survey_controller.dart';
import 'package:greenfestival/ui/widgets/festival_page_title.dart';
import 'package:greenfestival/ui/widgets/start_over_button.dart';

class ResidenceView extends StatefulWidget {
  const ResidenceView({super.key});

  @override
  State<ResidenceView> createState() => _ResidenceViewState();
}

class _ResidenceViewState extends State<ResidenceView> {
  static const _residences = [
    _ResidenceOption(label: '청주시\n상당구', value: '청주시 상당구'),
    _ResidenceOption(label: '청주시\n서원구', value: '청주시 서원구'),
    _ResidenceOption(label: '청주시\n청원구', value: '청주시 청원구'),
    _ResidenceOption(label: '청주시\n흥덕구', value: '청주시 흥덕구'),
    _ResidenceOption(label: '청주시\n외 지역', value: '청주시 외 지역'),
    _ResidenceOption(label: '해외\n거주', value: '해외 거주'),
  ];

  final SurveyController _surveyController = Get.find<SurveyController>();
  Timer? _navigationTimer;
  String _selectedResidence = '';

  @override
  void initState() {
    super.initState();
    _selectedResidence = _surveyController.residence.value;
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  void _selectResidence(_ResidenceOption residence) {
    setState(() => _selectedResidence = residence.value);
    _surveyController.setResidence(residence.value);

    _navigationTimer?.cancel();
    _navigationTimer = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      Get.toNamed(AppPages.PHONE_NUMBER);
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
              (contentWidth - (buttonGap * (_residences.length - 1))) /
              _residences.length;
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
                        FestivalPageTitle('$displayNickname 님의 거주정보를 입력해 주세요'),
                        SizedBox(height: titleToButtonsGap),
                        SizedBox(
                          width: contentWidth,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (var i = 0; i < _residences.length; i++) ...[
                                _ResidenceOptionButton(
                                  label: _residences[i].label,
                                  width: buttonWidth,
                                  height: buttonHeight,
                                  selected:
                                      _selectedResidence ==
                                      _residences[i].value,
                                  onTap: () => _selectResidence(_residences[i]),
                                ),
                                if (i != _residences.length - 1)
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

class _ResidenceOption {
  const _ResidenceOption({required this.label, required this.value});

  final String label;
  final String value;
}

class _ResidenceOptionButton extends StatelessWidget {
  const _ResidenceOptionButton({
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
            maxLines: 2,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF8C8C8C),
              fontSize: 18,
              fontWeight: FontWeight.w900,
              height: 1.25,
            ),
          ),
        ),
      ),
    );
  }
}
