import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:greenfestival/routes/app_pages.dart';
import 'package:greenfestival/ui/controllers/survey_controller.dart';
import 'package:greenfestival/ui/controllers/survey_ui_controller.dart';
import 'package:greenfestival/ui/widgets/start_over_button.dart';
import 'package:qr/qr.dart';

class EndingView extends StatefulWidget {
  const EndingView({super.key});

  @override
  State<EndingView> createState() => _EndingViewState();
}

class _EndingViewState extends State<EndingView> {
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
    final uid = Get.isRegistered<SurveyController>()
        ? Get.find<SurveyController>().lastCreatedUserUid.value.trim()
        : '';
    final stampTourUrl = uid.isEmpty
        ? ''
        : Uri.https(
            'greenfestival-5320b.web.app',
            '/stamp-tour/$uid',
          ).toString();

    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final qrSize = math
              .min(width * 0.22, height * 0.34)
              .clamp(152.0, 244.0);
          final closeButtonWidth = (width * 0.18).clamp(180.0, 280.0);
          final closeButtonHeight = (height * 0.064).clamp(56.0, 72.0);
          final cardWidth = math.min(
            (width * 0.22).clamp(220.0, 620.0),
            width - 48,
          );
          final titleSize = (width * 0.022).clamp(23.0, 34.0);
          final bodySize = (width * 0.014).clamp(16.0, 22.0);
          final cardPaddingY = (height * 0.028).clamp(20.0, 32.0);
          final hasStampTourUrl = stampTourUrl.isNotEmpty;
          final estimatedCardHeight =
              (cardPaddingY * 2) +
              (titleSize * 1.18 * 2) +
              12 +
              (bodySize * 1.34 * (hasStampTourUrl ? 2 : 1)) +
              (hasStampTourUrl ? 18 + qrSize : 0);
          final cardBottomOffset = math.max(
            24.0,
            (height * 0.38) - (estimatedCardHeight / 2),
          );

          return Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/images/ending_background.png',
                fit: BoxFit.fill,
                filterQuality: FilterQuality.high,
              ),
              SafeArea(
                child: Align(
                  alignment: const Alignment(0.88, 0.36),
                  child: Container(
                    width: cardWidth,
                    padding: EdgeInsets.symmetric(
                      horizontal: (width * 0.03).clamp(22.0, 40.0),
                      vertical: cardPaddingY,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 24,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '스탬프투어 참여 준비가\n완료되었습니다.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFF2E2E2E),
                            fontSize: titleSize,
                            fontWeight: FontWeight.w900,
                            height: 1.18,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          stampTourUrl.isEmpty
                              ? '문자로 발송된 링크를 확인해주세요.'
                              : '문자로 발송된 링크를 확인하거나\n아래 QR코드를 찍어주세요.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFF4F4F4F),
                            fontSize: bodySize,
                            fontWeight: FontWeight.w800,
                            height: 1.34,
                          ),
                        ),
                        if (hasStampTourUrl) ...[
                          const SizedBox(height: 18),
                          _StampTourQrCode(
                            data: stampTourUrl,
                            size: qrSize.toDouble(),
                          ),
                        ],
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
              Positioned(
                left: 0,
                right: 0,
                bottom: cardBottomOffset,
                child: SafeArea(
                  child: Center(
                    child: SizedBox(
                      width: closeButtonWidth,
                      height: closeButtonHeight,
                      child: OutlinedButton(
                        onPressed: _returnToIntro,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: const Color(0xFF4A9638),
                          side: const BorderSide(
                            color: Color(0xFF4A9638),
                            width: 2,
                          ),
                          shape: const StadiumBorder(),
                        ),
                        child: Text(
                          '닫기',
                          style: TextStyle(
                            fontSize: (width * 0.024).clamp(20.0, 28.0),
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StampTourQrCode extends StatelessWidget {
  const _StampTourQrCode({required this.data, required this.size});

  final String data;
  final double size;

  @override
  Widget build(BuildContext context) {
    final qrCode = QrCode.fromData(
      data: data,
      errorCorrectLevel: QrErrorCorrectLevel.M,
    );
    final qrImage = QrImage(qrCode);

    return Semantics(
      label: '스탬프투어 QR 코드',
      child: Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE8E8E8)),
        ),
        child: CustomPaint(
          painter: _QrCodePainter(
            qrImage: qrImage,
            moduleCount: qrCode.moduleCount,
          ),
        ),
      ),
    );
  }
}

class _QrCodePainter extends CustomPainter {
  const _QrCodePainter({required this.qrImage, required this.moduleCount});

  final QrImage qrImage;
  final int moduleCount;

  static const _quietZone = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black;
    final moduleSize = size.shortestSide / (moduleCount + (_quietZone * 2));
    final offset = Offset(
      (size.width - moduleSize * (moduleCount + (_quietZone * 2))) / 2,
      (size.height - moduleSize * (moduleCount + (_quietZone * 2))) / 2,
    );

    for (var y = 0; y < moduleCount; y += 1) {
      for (var x = 0; x < moduleCount; x += 1) {
        if (!qrImage.isDark(y, x)) continue;

        canvas.drawRect(
          Rect.fromLTWH(
            offset.dx + (x + _quietZone) * moduleSize,
            offset.dy + (y + _quietZone) * moduleSize,
            moduleSize,
            moduleSize,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_QrCodePainter oldDelegate) {
    return oldDelegate.qrImage != qrImage ||
        oldDelegate.moduleCount != moduleCount;
  }
}
