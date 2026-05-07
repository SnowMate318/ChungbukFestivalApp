import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:greenfestival/data/models/festival_admin_models.dart';
import 'package:greenfestival/services/festival_firestore_service.dart';

class DisplayLiveView extends StatelessWidget {
  const DisplayLiveView({super.key});

  static final _service = FestivalFirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          return Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/display/background.png',
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.10),
                      Colors.white.withValues(alpha: 0.42),
                      Colors.white.withValues(alpha: 0.68),
                    ],
                    stops: const [0, 0.58, 1],
                  ),
                ),
              ),
              SafeArea(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: height),
                    child: Padding(
                      padding: EdgeInsets.all((width * 0.018).clamp(12, 30)),
                      child: Center(child: _LiveStage(service: _service)),
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

class _LiveStage extends StatelessWidget {
  const _LiveStage({required this.service});

  final FestivalFirestoreService service;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final totalCard = StreamBuilder<int>(
          stream: service.watchTotalSeedCount(),
          builder: (context, snapshot) {
            return _DisplayMetricCard(
              chip: '황금씨앗 누적집계',
              chipColor: const Color(0xFFF05C80),
              count: '${snapshot.data ?? 0}개',
              image: 'assets/display/seed.png',
              accentColor: const Color(0xFFF05C80),
            );
          },
        );

        final personalCard = StreamBuilder<HighlightedUser?>(
          stream: service.watchHighlightedUser(),
          builder: (context, snapshot) {
            return _PersonalSeedCard(seedCount: snapshot.data?.seedCount ?? 0);
          },
        );

        final center = StreamBuilder<HighlightedUser?>(
          stream: service.watchHighlightedUser(),
          builder: (context, snapshot) {
            return _CenterMessage(user: snapshot.data);
          },
        );

        if (width > 1180) {
          return Row(
            children: [
              SizedBox(width: math.min(width * 0.22, 360), child: totalCard),
              SizedBox(width: (width * 0.055).clamp(42, 118)),
              Expanded(child: center),
              SizedBox(width: (width * 0.055).clamp(42, 118)),
              SizedBox(width: math.min(width * 0.22, 360), child: personalCard),
            ],
          );
        }

        if (width > 760) {
          return Column(
            children: [
              center,
              SizedBox(height: (width * 0.04).clamp(34, 64)),
              Row(
                children: [
                  Expanded(child: totalCard),
                  const SizedBox(width: 24),
                  Expanded(child: personalCard),
                ],
              ),
            ],
          );
        }

        return Column(
          children: [
            center,
            const SizedBox(height: 22),
            totalCard,
            const SizedBox(height: 22),
            personalCard,
          ],
        );
      },
    );
  }
}

class _CenterMessage extends StatelessWidget {
  const _CenterMessage({required this.user});

  final HighlightedUser? user;

  @override
  Widget build(BuildContext context) {
    final seedCount = _clampSeedCount(user?.seedCount ?? 0);
    final profile = _carbonProfile(seedCount);
    final hasUser = user?.nickname.isNotEmpty ?? false;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final message = hasUser
            ? '${user!.nickname}님이 모은 황금씨앗으로\n${profile.text}\n만큼의 이동을 아꼈어요.'
            : '지금 막 참여자가 등장하면 여기에 반영됩니다!';
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: math.min(width, 980)),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF1F2C18),
                  fontWeight: FontWeight.w500,
                  height: 1.14,
                  letterSpacing: -1.8,
                  fontSize: (width * 0.055).clamp(26, 58),
                ),
              ),
            ),
            SizedBox(height: (width * 0.026).clamp(18, 30)),
            SizedBox(
              width: (width * 0.30).clamp(156, 286),
              height: (width * 0.30).clamp(156, 286),
              child: Image.asset(
                hasUser ? profile.asset : 'assets/display/seed.png',
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DisplayMetricCard extends StatelessWidget {
  const _DisplayMetricCard({
    required this.chip,
    required this.chipColor,
    required this.count,
    required this.image,
    required this.accentColor,
  });

  final String chip;
  final Color chipColor;
  final String count;
  final String image;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _CardChip(label: chip, color: chipColor),
          const SizedBox(height: 34),
          Image.asset(
            image,
            width: 116,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
          const SizedBox(height: 20),
          Text(
            count,
            style: TextStyle(
              color: accentColor,
              fontSize: 48,
              height: 1,
              fontWeight: FontWeight.w500,
              letterSpacing: -1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonalSeedCard extends StatelessWidget {
  const _PersonalSeedCard({required this.seedCount});

  final int seedCount;

  @override
  Widget build(BuildContext context) {
    final visibleCount = math.min(_clampSeedCount(seedCount), 9);
    return _GlassCard(
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const _CardChip(label: '내가 모은 황금 씨앗', color: Color(0xFF5E9733)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 58),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '+${_clampSeedCount(seedCount)}개',
                  style: const TextStyle(
                    color: Color(0xFF27301A),
                    fontSize: 48,
                    height: 1,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -1.2,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 210,
                  child: Wrap(
                    spacing: 14,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      for (var i = 0; i < visibleCount; i++)
                        Image.asset(
                          'assets/display/seed.png',
                          width: 38,
                          height: 54,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 300),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0x2945622D)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2454542A),
            blurRadius: 60,
            offset: Offset(0, 24),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CardChip extends StatelessWidget {
  const _CardChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22364728),
              blurRadius: 22,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
}

class _CarbonProfile {
  const _CarbonProfile({required this.text, required this.asset});

  final String text;
  final String asset;
}

_CarbonProfile _carbonProfile(int seedCount) {
  if (seedCount <= 7) {
    return const _CarbonProfile(
      text: '승용차 대신 가까운 거리를 걸은 셈',
      asset: 'assets/display/car.png',
    );
  }
  if (seedCount <= 10) {
    return const _CarbonProfile(
      text: '버스 한 번쯤은 덜 탄 만큼',
      asset: 'assets/display/bus.png',
    );
  }
  if (seedCount <= 15) {
    return const _CarbonProfile(
      text: '기차 이동 한 구간을 아낀 셈',
      asset: 'assets/display/train.png',
    );
  }
  return const _CarbonProfile(
    text: '비행 대신 오래 남는 선택을 했어요',
    asset: 'assets/display/airplane.png',
  );
}

int _clampSeedCount(int value) => value < 0 ? 0 : value;
