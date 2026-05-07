import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:greenfestival/data/models/festival_admin_models.dart';
import 'package:greenfestival/services/festival_firestore_service.dart';

import 'display_live_video_background_stub.dart'
    if (dart.library.html) 'display_live_video_background_web.dart';

const double _displayTextScale = 0.61;

class DisplayLiveView extends StatelessWidget {
  const DisplayLiveView({super.key});

  static final _service = FestivalFirestoreService();

  @override
  Widget build(BuildContext context) {
    return _DisplayLiveSurface(service: _service);
  }
}

class _DisplayLiveSurface extends StatelessWidget {
  const _DisplayLiveSurface({required this.service});

  final FestivalFirestoreService service;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<HighlightedUser?>(
      stream: service.watchHighlightedUser(),
      builder: (context, userSnapshot) {
        final highlightedUser = userSnapshot.data;
        return StreamBuilder<int>(
          stream: service.watchTotalSeedCount(),
          builder: (context, totalSnapshot) {
            final totalSeedCount = math.max(0, totalSnapshot.data ?? 0);
            return _DisplayLiveScene(
              user: highlightedUser,
              totalSeedCount: totalSeedCount,
            );
          },
        );
      },
    );
  }
}

class _DisplayLiveScene extends StatelessWidget {
  const _DisplayLiveScene({required this.user, required this.totalSeedCount});

  final HighlightedUser? user;
  final int totalSeedCount;

  @override
  Widget build(BuildContext context) {
    final personalSeedCount = math.max(0, user?.seedCount ?? 0);
    final sky = _skyProfile(personalSeedCount);
    final restartKey = '${sky.asset}-${user?.nickname ?? 'empty'}';

    return Scaffold(
      backgroundColor: const Color(0xFFEAF6F3),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final wide = width >= 980 && height >= 620;

          return Stack(
            fit: StackFit.expand,
            children: [
              DisplayLiveVideoBackground(
                asset: sky.asset,
                restartKey: restartKey,
              ),
              const DecoratedBox(
                decoration: BoxDecoration(color: Color(0x18FFFFFF)),
              ),
              SafeArea(
                child: wide
                    ? _WideDisplayLayout(
                        user: user,
                        command: sky.command,
                        totalSeedCount: totalSeedCount,
                        personalSeedCount: personalSeedCount,
                      )
                    : _CompactDisplayLayout(
                        user: user,
                        command: sky.command,
                        totalSeedCount: totalSeedCount,
                        personalSeedCount: personalSeedCount,
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WideDisplayLayout extends StatelessWidget {
  const _WideDisplayLayout({
    required this.user,
    required this.command,
    required this.totalSeedCount,
    required this.personalSeedCount,
  });

  final HighlightedUser? user;
  final String command;
  final int totalSeedCount;
  final int personalSeedCount;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final sideMargin = (width * 0.016).clamp(20.0, 48.0);
        final cardWidth = (width * 0.15).clamp(180.0, 300.0);
        final cardHeight = (height * 0.36).clamp(220.0, 368.0);
        final cardTop = math.max(
          0.0,
          ((height - cardHeight) / 2) + (height * 0.05),
        );
        final titleTop = ((height * 0.18).clamp(88.0, 210.0)) + (height * 0.08);

        return Stack(
          children: [
            Positioned(
              top: titleTop,
              left: 0,
              right: 0,
              child: _HeroTitle(user: user, command: command),
            ),
            Positioned(
              left: sideMargin,
              top: cardTop,
              width: cardWidth,
              height: cardHeight,
              child: _FestivalSeedCard(seedCount: totalSeedCount),
            ),
            Positioned(
              right: sideMargin,
              top: cardTop,
              width: cardWidth,
              height: cardHeight,
              child: _PersonalSeedCard(seedCount: personalSeedCount),
            ),
          ],
        );
      },
    );
  }
}

class _CompactDisplayLayout extends StatelessWidget {
  const _CompactDisplayLayout({
    required this.user,
    required this.command,
    required this.totalSeedCount,
    required this.personalSeedCount,
  });

  final HighlightedUser? user;
  final String command;
  final int totalSeedCount;
  final int personalSeedCount;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final cardWidth = width >= 720
            ? (width * 0.44).clamp(260.0, 360.0)
            : math.min(width - 32, 360.0);

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            (width * 0.04).clamp(16.0, 28.0),
            (constraints.maxHeight * 0.18).clamp(42.0, 140.0),
            (width * 0.04).clamp(16.0, 28.0),
            28,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 46),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _HeroTitle(user: user, command: command),
                const SizedBox(height: 28),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 24,
                  runSpacing: 24,
                  children: [
                    SizedBox(
                      width: cardWidth,
                      height: 348,
                      child: _FestivalSeedCard(seedCount: totalSeedCount),
                    ),
                    SizedBox(
                      width: cardWidth,
                      height: 348,
                      child: _PersonalSeedCard(seedCount: personalSeedCount),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HeroTitle extends StatelessWidget {
  const _HeroTitle({required this.user, required this.command});

  final HighlightedUser? user;
  final String command;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final seedCount = math.max(0, user?.seedCount ?? 0);
        final nickname = (user?.nickname.trim().isNotEmpty ?? false)
            ? user!.nickname.trim()
            : '참여자';
        final titleSize = (width * 0.038).clamp(31.0, 72.0);
        final quoteSize = (titleSize * 1.25).clamp(42.0, 88.0);
        final quoteGap = width * 0.08;

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: (width * 0.08).clamp(18, 92),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image.asset(
              //   'assets/pictures/logo.png',
              //   width: logoWidth,
              //   fit: BoxFit.contain,
              //   filterQuality: FilterQuality.high,
              // ),
              SizedBox(height: (width * 0.01).clamp(8.0, 18.0)),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Transform.translate(
                    offset: Offset(0, -titleSize * 0.08),
                    child: Text(
                      '“',
                      style: TextStyle(
                        color: const Color(0xFF2E8B50),
                        fontSize: quoteSize,
                        height: 1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(width: quoteGap),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: math.max(
                        0,
                        width - (quoteSize * 2) - (quoteGap * 2) - 36,
                      ),
                    ),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          color: const Color(0xFF4B4E50),
                          fontSize: titleSize,
                          height: 1.12,
                          fontWeight: FontWeight.w600,
                        ),
                        children: [
                          TextSpan(
                            text: '[$nickname]이 오늘 찾은 황금씨앗 [$seedCount]개로\n',
                          ),
                          TextSpan(
                            text: command,
                            style: const TextStyle(color: Color(0xFF2E8B50)),
                          ),
                          const TextSpan(text: ' 하늘이 맑아졌어요.'),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: quoteGap),
                  Transform.translate(
                    offset: Offset(0, -titleSize * 0.08),
                    child: Text(
                      '”',
                      style: TextStyle(
                        color: const Color(0xFF2E8B50),
                        fontSize: quoteSize,
                        height: 1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FestivalSeedCard extends StatelessWidget {
  const _FestivalSeedCard({required this.seedCount});

  final int seedCount;

  @override
  Widget build(BuildContext context) {
    return _SeedCountCard(
      seedCount: seedCount,
      title: const [
        _CardTextPart('청주가 그린'),
        _CardTextPart('Green Festival에서'),
        _CardTextPart('모은 '),
        _CardTextPart('황금씨앗', color: Color(0xFFE95375)),
      ],
      titleFontScale: 0.96,
    );
  }
}

class _PersonalSeedCard extends StatelessWidget {
  const _PersonalSeedCard({required this.seedCount});

  final int seedCount;

  @override
  Widget build(BuildContext context) {
    return _SeedCountCard(
      seedCount: seedCount,
      title: const [
        _CardTextPart('내가 모은'),
        _CardTextPart('황금씨앗', color: Color(0xFFE95375)),
      ],
      titleFontScale: 1.06,
    );
  }
}

class _SeedCountCard extends StatelessWidget {
  const _SeedCountCard({
    required this.seedCount,
    required this.title,
    required this.titleFontScale,
  });

  final int seedCount;
  final List<_CardTextPart> title;
  final double titleFontScale;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final seedSize = math.min(width, height) * 0.19;
        final countSize = (width * 0.102 * titleFontScale).clamp(25.0, 44.0);
        final verticalGap = (height * 0.042).clamp(12.0, 26.0);

        return Container(
          padding: EdgeInsets.fromLTRB(
            (width * 0.065).clamp(16.0, 28.0),
            (height * 0.065).clamp(16.0, 32.0),
            (width * 0.065).clamp(16.0, 28.0),
            (height * 0.06).clamp(16.0, 30.0),
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(26),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A355C5B),
                blurRadius: 30,
                offset: Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/display/seed.png',
                width: seedSize,
                height: seedSize,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
              SizedBox(height: verticalGap),
              _CardTitle(parts: title, fontSize: countSize),
              SizedBox(height: verticalGap * 0.28),
              _BracketSeedCount(seedCount: seedCount, fontSize: countSize),
            ],
          ),
        );
      },
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle({required this.parts, required this.fontSize});

  final List<_CardTextPart> parts;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final children = <InlineSpan>[];
    for (var index = 0; index < parts.length; index += 1) {
      final part = parts[index];
      children.add(
        TextSpan(
          text: part.text,
          style: TextStyle(color: part.color ?? const Color(0xFF2E8B50)),
        ),
      );
      if (index < parts.length - 1 && !part.text.endsWith(' ')) {
        children.add(const TextSpan(text: '\n'));
      }
    }

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: TextStyle(
          fontSize: fontSize,
          height: 1.18,
          fontWeight: FontWeight.w600,
        ),
        children: children,
      ),
    );
  }
}

class _BracketSeedCount extends StatelessWidget {
  const _BracketSeedCount({required this.seedCount, required this.fontSize});

  final int seedCount;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        '[  $seedCount개  ]',
        style: TextStyle(
          color: const Color(0xFF4B4E50),
          fontSize: fontSize,
          height: 1,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}

class _CardTextPart {
  const _CardTextPart(this.text, {this.color});

  final String text;
  final Color? color;
}

class _SkyProfile {
  const _SkyProfile({required this.asset, required this.command});

  final String asset;
  final String command;
}

_SkyProfile _skyProfile(int seedCount) {
  if (seedCount <= 9) {
    return const _SkyProfile(
      asset: 'assets/videos/dungbu.mp4',
      command: '동부창고',
    );
  }
  if (seedCount <= 14) {
    return const _SkyProfile(
      asset: 'assets/videos/cheongju.mp4',
      command: '청주시',
    );
  }
  return const _SkyProfile(asset: 'assets/videos/korea.mp4', command: '대한민국');
}
