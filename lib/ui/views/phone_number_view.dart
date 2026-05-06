import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:greenfestival/routes/app_pages.dart';
import 'package:greenfestival/ui/controllers/survey_controller.dart';
import 'package:greenfestival/ui/widgets/festival_page_title.dart';
import 'package:greenfestival/ui/widgets/start_over_button.dart';

class PhoneNumberView extends StatefulWidget {
  const PhoneNumberView({super.key});

  @override
  State<PhoneNumberView> createState() => _PhoneNumberViewState();
}

class _PhoneNumberViewState extends State<PhoneNumberView> {
  final SurveyController _surveyController = Get.find<SurveyController>();
  String _phoneDigits = '';
  bool _showKeypad = false;
  bool _checkingPhone = false;

  @override
  void initState() {
    super.initState();
    _phoneDigits = _digitsOnly(_surveyController.phoneNumber.value);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _openKeypad();
    });
  }

  String get _formattedPhoneNumber => _formatPhoneNumber(_phoneDigits);

  void _openKeypad() {
    setState(() => _showKeypad = true);
  }

  void _closeKeypad() {
    setState(() => _showKeypad = false);
  }

  void _appendDigit(String digit) {
    if (_phoneDigits.length >= 11) return;
    setState(() => _phoneDigits += digit);
  }

  void _removeDigit() {
    if (_phoneDigits.isEmpty) return;
    setState(
      () => _phoneDigits = _phoneDigits.substring(0, _phoneDigits.length - 1),
    );
  }

  void _completeInput() {
    _surveyController.setPhoneNumber(_formattedPhoneNumber);
    _closeKeypad();
  }

  Future<void> _goNext() async {
    if (_checkingPhone) return;

    if (_phoneDigits.length < 10) {
      _openKeypad();
      return;
    }

    if (!_surveyController.isValidPhoneNumber(_formattedPhoneNumber)) {
      Get.snackbar(
        '휴대폰 번호 확인',
        '올바른 휴대폰 번호 형식을 입력해주세요.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      _openKeypad();
      return;
    }

    _surveyController.setPhoneNumber(_formattedPhoneNumber);
    setState(() => _checkingPhone = true);

    try {
      final duplicated = await _surveyController.isPhoneNumberDuplicated(
        _formattedPhoneNumber,
      );
      if (!mounted) return;

      if (duplicated) {
        Get.snackbar(
          '휴대폰 번호 중복',
          '이미 등록된 휴대폰 번호입니다. 다른 번호를 입력해주세요.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
        _openKeypad();
        return;
      }

      Get.toNamed(AppPages.READY);
    } catch (error) {
      if (!mounted) return;
      Get.snackbar(
        '휴대폰 번호 확인 실패',
        '$error',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } finally {
      if (mounted) {
        setState(() => _checkingPhone = false);
      }
    }
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
          final titleToCardGap = (height * 0.045).clamp(28.0, 48.0);
          final maxCardWidth = math.max(280.0, width - 48);
          final cardWidth = math.min(
            (width * 0.52).clamp(468.0, 676.0),
            maxCardWidth,
          );

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
                        FestivalPageTitle(
                          '$displayNickname 님의 휴대폰 번호를 입력해 주세요',
                        ),
                        SizedBox(height: titleToCardGap),
                        _PhoneNumberCard(
                          width: cardWidth,
                          phoneNumber: _formattedPhoneNumber,
                          onInputTap: _openKeypad,
                        ),
                        SizedBox(height: (height * 0.035).clamp(20.0, 34.0)),
                        _NextButton(
                          label: _checkingPhone ? '확인 중...' : '다음',
                          onTap: () {
                            _goNext();
                          },
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
              if (_showKeypad)
                Positioned.fill(
                  child: _PhoneKeypadOverlay(
                    phoneNumber: _formattedPhoneNumber,
                    onDigitTap: _appendDigit,
                    onBackspace: _removeDigit,
                    onPrevious: _closeKeypad,
                    onComplete: _completeInput,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _PhoneNumberCard extends StatelessWidget {
  const _PhoneNumberCard({
    required this.width,
    required this.phoneNumber,
    required this.onInputTap,
  });

  final double width;
  final String phoneNumber;
  final VoidCallback onInputTap;

  @override
  Widget build(BuildContext context) {
    final hasPhoneNumber = phoneNumber.isNotEmpty;

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: const Color(0xEFFFFFFF),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            offset: Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '전화번호를 입력해주세요.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF9B9B9B),
              fontSize: 22,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 30),
          GestureDetector(
            onTap: onInputTap,
            child: Container(
              width: double.infinity,
              height: 68,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E2E2)),
              ),
              child: Text(
                hasPhoneNumber ? phoneNumber : '터치하여 입력',
                style: TextStyle(
                  color: hasPhoneNumber
                      ? const Color(0xFF545454)
                      : const Color(0xFFD5D5D5),
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NextButton extends StatelessWidget {
  const _NextButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF4A9638),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _PhoneKeypadOverlay extends StatelessWidget {
  const _PhoneKeypadOverlay({
    required this.phoneNumber,
    required this.onDigitTap,
    required this.onBackspace,
    required this.onPrevious,
    required this.onComplete,
  });

  final String phoneNumber;
  final ValueChanged<String> onDigitTap;
  final VoidCallback onBackspace;
  final VoidCallback onPrevious;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0x99000000),
      child: Center(
        child: Container(
          width: 429,
          padding: const EdgeInsets.fromLTRB(18, 23, 18, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '전화번호 입력',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 16),
              _PhoneNumberDisplay(phoneNumber: phoneNumber),
              const SizedBox(height: 13),
              _NumberKeypad(onDigitTap: onDigitTap, onBackspace: onBackspace),
              const SizedBox(height: 13),
              Row(
                children: [
                  Expanded(
                    child: _DialogActionButton(
                      label: '이전',
                      color: const Color(0xFFCFCFCF),
                      textColor: Colors.white,
                      onTap: onPrevious,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: _DialogActionButton(
                      label: '완료',
                      color: const Color(0xFF4A9638),
                      textColor: Colors.white,
                      onTap: onComplete,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhoneNumberDisplay extends StatelessWidget {
  const _PhoneNumberDisplay({required this.phoneNumber});

  final String phoneNumber;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 49,
      alignment: Alignment.centerLeft,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF4A9638), width: 4)),
      ),
      child: Row(
        children: [
          Container(width: 3, height: 36, color: const Color(0xFF4A9638)),
          const SizedBox(width: 10),
          Text(
            phoneNumber.isEmpty ? '010-1234-5678' : phoneNumber,
            style: TextStyle(
              color: phoneNumber.isEmpty
                  ? const Color(0xFFB8B8B8)
                  : const Color(0xFF4A4A4A),
              fontSize: 21,
              fontWeight: FontWeight.w500,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberKeypad extends StatelessWidget {
  const _NumberKeypad({required this.onDigitTap, required this.onBackspace});

  final ValueChanged<String> onDigitTap;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(
              children: [
                for (var i = 0; i < row.length; i++) ...[
                  Expanded(
                    child: _NumberKey(
                      label: row[i],
                      onTap: () => onDigitTap(row[i]),
                    ),
                  ),
                  if (i != row.length - 1) const SizedBox(width: 7),
                ],
              ],
            ),
          ),
        Row(
          children: [
            const Expanded(child: SizedBox(height: 47)),
            const SizedBox(width: 7),
            Expanded(
              child: _NumberKey(label: '0', onTap: () => onDigitTap('0')),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: _NumberKey(
                onTap: onBackspace,
                child: const Icon(
                  Icons.backspace,
                  size: 23,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NumberKey extends StatelessWidget {
  const _NumberKey({this.label, this.child, required this.onTap});

  final String? label;
  final Widget? child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 47,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: const Color(0xFFE5E5E5)),
        ),
        child:
            child ??
            Text(
              label ?? '',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 23,
                fontWeight: FontWeight.w500,
                height: 1,
              ),
            ),
      ),
    );
  }
}

class _DialogActionButton extends StatelessWidget {
  const _DialogActionButton({
    required this.label,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 47,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ),
    );
  }
}

String _digitsOnly(String value) => value.replaceAll(RegExp(r'\D'), '');

String _formatPhoneNumber(String digits) {
  final cleanDigits = digits.length > 11 ? digits.substring(0, 11) : digits;

  if (cleanDigits.length <= 3) {
    return cleanDigits;
  }

  if (cleanDigits.length <= 7) {
    return '${cleanDigits.substring(0, 3)}-${cleanDigits.substring(3)}';
  }

  return '${cleanDigits.substring(0, 3)}-${cleanDigits.substring(3, 7)}-${cleanDigits.substring(7)}';
}
