import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:greenfestival/routes/app_pages.dart';
import 'package:greenfestival/ui/widgets/festival_page_title.dart';
import 'package:greenfestival/ui/widgets/start_over_button.dart';

class PrivacyConsentView extends StatelessWidget {
  const PrivacyConsentView({super.key});

  static const _backgroundAsset = 'assets/images/background.png';
  static const _buttonColor = Color(0xFF4A9638);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          final contentWidth = (width * 0.82).clamp(330.0, 1180.0);
          final titleTopGap = FestivalPageTitle.topGap(height);
          final titleToCardGap = (height * 0.04).clamp(18.0, 30.0);
          final cardToButtonGap = (height * 0.042).clamp(20.0, 34.0);
          final cardPaddingX = (width * 0.038).clamp(22.0, 46.0);
          final cardPaddingY = (height * 0.03).clamp(18.0, 30.0);
          final buttonWidth = (contentWidth * 0.56).clamp(260.0, 560.0);
          final buttonHeight = (height * 0.112).clamp(60.0, 84.0);

          final bodyFontSize = (width * 0.017).clamp(15.0, 21.0);
          final buttonFontSize = (width * 0.03).clamp(26.0, 36.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                _backgroundAsset,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.high,
              ),
              SafeArea(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: titleTopGap,
                      bottom: buttonHeight + 52,
                    ),
                    child: Column(
                      children: [
                        const FestivalPageTitle('개인정보활용 동의서'),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '2026 청주가 그린 GREEN 페스티벌은 친환경 축제로, 축제 정보 리플렛 및 스탬프 투어를 모바일로 제공합니다.\n'
                                '휴대폰 번호를 입력하시면 축제 리플렛, 스탬프투어 참여 링크, 오픈채팅방 안내가 문자로 발송됩니다.',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: bodyFontSize * 1.05,
                                  fontWeight: FontWeight.w900,
                                  height: 1.65,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '· 수집 항목: 닉네임, 연락처, 성별, 거주지(동), 휴대폰 번호\n'
                                '· 이용 목적: 축제 운영(리플렛 및 스탬프투어 링크 발송, 만족도 조사 안내)\n'
                                '· 보유 기간: 2026년 5월 31일까지 보관 후 전량 폐기\n'
                                '※ 개인정보 수집 및 이용에 동의하지 않을 경우 서비스 이용이 제한될 수 있습니다.',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: bodyFontSize,
                                  fontWeight: FontWeight.w800,
                                  height: 1.65,
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
                            onPressed: () => Get.toNamed(AppPages.NICKNAME),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _buttonColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: EdgeInsets.zero,
                              shape: const StadiumBorder(),
                            ),
                            child: Text(
                              '동의합니다.',
                              style: TextStyle(
                                fontSize: buttonFontSize,
                                fontWeight: FontWeight.w800,
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
