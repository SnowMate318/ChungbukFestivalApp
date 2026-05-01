import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:greenfestival/routes/app_pages.dart';

class IntroView extends StatelessWidget {
  const IntroView({super.key});

  static const _backgroundAsset = 'assets/images/intro_background.png';
  static const _buttonColor = Color(0xFF3D8F2F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          final panelWidth = (width * 0.66).clamp(310.0, 1260.0);
          final panelVerticalPadding = (height * 0.035).clamp(16.0, 36.0);
          final panelHorizontalPadding = (width * 0.04).clamp(20.0, 64.0);
          final buttonWidth = (panelWidth * 0.76).clamp(230.0, 900.0);
          final buttonHeight = (height * 0.12).clamp(44.0, 126.0);
          final gap = (height * 0.024).clamp(10.0, 28.0);

          final titleFontSize = (width * 0.028).clamp(15.0, 52.0);
          final buttonTopFontSize = (width * 0.014).clamp(8.0, 25.0);
          final buttonMainFontSize = (width * 0.022).clamp(12.0, 42.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                _backgroundAsset,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
              ),
              Align(
                alignment: const Alignment(0, 0.46),
                child: Container(
                  width: panelWidth,
                  padding: EdgeInsets.symmetric(
                    horizontal: panelHorizontalPadding,
                    vertical: panelVerticalPadding,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '당신의 참여가 숲을 만듭니다.\n축제에 참여하고 일상 속 황금씨앗을 모아보세요!',
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.visible,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                      SizedBox(height: gap),
                      SizedBox(
                        width: buttonWidth,
                        height: buttonHeight,
                        child: ElevatedButton(
                          onPressed:
                              () => Get.toNamed(AppPages.PRIVACY_CONSENT),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _buttonColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: EdgeInsets.zero,
                            shape: const StadiumBorder(),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '청주가 그린GREEN 페스티벌',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: buttonTopFontSize,
                                  fontWeight: FontWeight.w600,
                                  height: 1.0,
                                ),
                              ),
                              Text(
                                '참여하기',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: buttonMainFontSize,
                                  fontWeight: FontWeight.w700,
                                  height: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
