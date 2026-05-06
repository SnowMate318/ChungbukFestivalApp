import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:greenfestival/routes/app_pages.dart';
import 'package:greenfestival/ui/controllers/survey_controller.dart';
import 'package:greenfestival/ui/widgets/festival_page_title.dart';
import 'package:greenfestival/ui/widgets/start_over_button.dart';

class ParticipantCountView extends StatefulWidget {
  const ParticipantCountView({super.key});

  @override
  State<ParticipantCountView> createState() => _ParticipantCountViewState();
}

class _ParticipantCountViewState extends State<ParticipantCountView> {
  static const _counts = ['1명', '2명', '3명', '4명', '5명', '6명', '7명', '8명 이상'];
  static const _customCountLabel = '8명 이상';

  final SurveyController _surveyController = Get.find<SurveyController>();
  Timer? _navigationTimer;

  String _selectedCount = '';
  String _customCountDigits = '';
  bool _showCustomCountKeypad = false;

  @override
  void initState() {
    super.initState();

    final savedCount = _surveyController.participantCount.value;
    _selectedCount = savedCount;
    _customCountDigits = _extractDigits(savedCount);

    final customCount = int.tryParse(_customCountDigits);
    if (customCount != null && customCount >= 8) {
      _selectedCount = _customCountLabel;
    }
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  void _selectCount(String count) {
    if (count == _customCountLabel) {
      _navigationTimer?.cancel();
      setState(() {
        _selectedCount = _customCountLabel;
        _showCustomCountKeypad = true;
      });
      return;
    }

    _saveAndGoNext(count);
  }

  void _saveAndGoNext(String count) {
    setState(() => _selectedCount = count);
    _surveyController.setParticipantCount(count);

    _navigationTimer?.cancel();
    _navigationTimer = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      Get.toNamed(AppPages.RESIDENCE);
    });
  }

  void _closeCustomCountKeypad() {
    setState(() => _showCustomCountKeypad = false);
  }

  void _appendCustomCountDigit(String digit) {
    if (_customCountDigits.length >= 2) return;
    setState(() => _customCountDigits += digit);
  }

  void _removeCustomCountDigit() {
    if (_customCountDigits.isEmpty) return;
    setState(() {
      _customCountDigits = _customCountDigits.substring(
        0,
        _customCountDigits.length - 1,
      );
    });
  }

  void _completeCustomCountInput() {
    final customCount = int.tryParse(_customCountDigits);
    if (customCount == null || customCount < 8 || customCount > 99) {
      Get.snackbar(
        '참여 인원 입력',
        '8명부터 99명까지 입력할 수 있습니다.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    _closeCustomCountKeypad();
    _saveAndGoNext('$customCount명');
  }

  String get _customCountDisplay =>
      _customCountDigits.isEmpty ? '8 ~ 99' : _customCountDigits;

  bool get _isCustomCountSelected {
    if (_selectedCount == _customCountLabel) return true;
    final customCount = int.tryParse(_extractDigits(_selectedCount));
    return customCount != null && customCount >= 8;
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
          final displayNickname = nickname.isEmpty ? '고객님' : nickname;

          final titleTopGap = FestivalPageTitle.topGap(height);
          final titleToButtonsGap = (height * 0.05).clamp(28.0, 48.0);
          final contentWidth = (width * 0.86).clamp(760.0, 1160.0);
          final buttonGap = (width * 0.008).clamp(8.0, 13.0);
          final buttonWidth =
              (contentWidth - (buttonGap * (_counts.length - 1))) /
              _counts.length;
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
                        FestivalPageTitle(
                          '스탬프 투어 참여 인원은 몇 명인가요?',
                        ),
                        SizedBox(height: titleToButtonsGap),
                        SizedBox(
                          width: contentWidth,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (var i = 0; i < _counts.length; i++) ...[
                                _ParticipantCountOptionButton(
                                  label: _counts[i],
                                  width: buttonWidth,
                                  height: buttonHeight,
                                  selected:
                                      _counts[i] == _customCountLabel
                                          ? _isCustomCountSelected
                                          : _selectedCount == _counts[i],
                                  onTap: () => _selectCount(_counts[i]),
                                ),
                                if (i != _counts.length - 1)
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
              if (_showCustomCountKeypad)
                Positioned.fill(
                  child: _ParticipantCountKeypadOverlay(
                    countText: _customCountDisplay,
                    onDigitTap: _appendCustomCountDigit,
                    onBackspace: _removeCustomCountDigit,
                    onPrevious: _closeCustomCountKeypad,
                    onComplete: _completeCustomCountInput,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ParticipantCountOptionButton extends StatelessWidget {
  const _ParticipantCountOptionButton({
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
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
      ),
    );
  }
}

class _ParticipantCountKeypadOverlay extends StatelessWidget {
  const _ParticipantCountKeypadOverlay({
    required this.countText,
    required this.onDigitTap,
    required this.onBackspace,
    required this.onPrevious,
    required this.onComplete,
  });

  final String countText;
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
                '참여 인원 입력',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 16),
              _ParticipantCountDisplay(countText: countText),
              const SizedBox(height: 13),
              _ParticipantCountKeypad(
                onDigitTap: onDigitTap,
                onBackspace: onBackspace,
              ),
              const SizedBox(height: 13),
              Row(
                children: [
                  Expanded(
                    child: _ParticipantCountDialogActionButton(
                      label: '이전',
                      color: const Color(0xFFCFCFCF),
                      textColor: Colors.white,
                      onTap: onPrevious,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: _ParticipantCountDialogActionButton(
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

class _ParticipantCountDisplay extends StatelessWidget {
  const _ParticipantCountDisplay({required this.countText});

  final String countText;

  @override
  Widget build(BuildContext context) {
    final isPlaceholder = countText == '8 ~ 99';

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
            isPlaceholder ? '8 ~ 99명' : '$countText명',
            style: TextStyle(
              color:
                  isPlaceholder
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

class _ParticipantCountKeypad extends StatelessWidget {
  const _ParticipantCountKeypad({
    required this.onDigitTap,
    required this.onBackspace,
  });

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
                    child: _ParticipantCountNumberKey(
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
              child: _ParticipantCountNumberKey(
                label: '0',
                onTap: () => onDigitTap('0'),
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: _ParticipantCountNumberKey(
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

class _ParticipantCountNumberKey extends StatelessWidget {
  const _ParticipantCountNumberKey({
    this.label,
    this.child,
    required this.onTap,
  });

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

class _ParticipantCountDialogActionButton extends StatelessWidget {
  const _ParticipantCountDialogActionButton({
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

String _extractDigits(String value) => value.replaceAll(RegExp(r'\D'), '');
