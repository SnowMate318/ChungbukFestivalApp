import 'dart:collection';
import 'dart:async';
import 'dart:math' as math;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:greenfestival/data/models/festival_admin_models.dart';
import 'package:greenfestival/data/models/seed_qr_payload.dart';
import 'package:greenfestival/platform/external_url_launcher.dart';
import 'package:greenfestival/platform/web_camera_context.dart';
import 'package:greenfestival/services/festival_firestore_service.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart' as qr_plus;

class SeedStampTourPage extends StatefulWidget {
  const SeedStampTourPage({required this.uid, super.key});

  final String uid;

  @override
  State<SeedStampTourPage> createState() => _SeedStampTourPageState();
}

class _SeedStampTourPageState extends State<SeedStampTourPage> {
  final FestivalFirestoreService _service = FestivalFirestoreService();
  final WebCameraContext _webCameraContext = getWebCameraContext();
  final Map<String, int> _counts = {};
  String? _loadedStamp;
  bool _saving = false;
  bool _isScanning = false;
  bool _handlingDetectedCode = false;
  int _scannerSessionId = 0;

  void _openScanner(FestivalUser user) {
    if (_saving) {
      return;
    }

    if (user.lastSubmittedAt != null) {
      unawaited(_showQrErrorDialog('이미 제출완료되어 QR 적립을 추가할 수 없어요.'));
      return;
    }

    setState(() {
      _isScanning = true;
      _scannerSessionId += 1;
    });
  }

  void _closeScanner() {
    if (!_isScanning) {
      return;
    }

    setState(() => _isScanning = false);
  }

  String _leafletImageUrl() {
    if (_webCameraContext.isWeb) {
      return Uri.base.resolve('/openfiles/introduce2.jpg').toString();
    }
    return 'https://greenfestival-5320b.web.app/openfiles/introduce2.jpg';
  }

  Future<void> _showLeafletMessage() async {
    if (!mounted) return;
    final opened = await openExternalUrl(_leafletImageUrl());
    if (opened || !mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => _LeafletImagePage(imageUrl: _leafletImageUrl()),
      ),
    );
  }

  Future<void> _showQrErrorDialog(String message) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QR 코드 오류'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  String _seedUpdateErrorMessage(Object error) {
    if (_isNetworkError(error)) {
      return '네트워크 연결이 불안정해서 씨앗 적립에 실패했어요. 연결을 확인한 뒤 다시 시도해 주세요.';
    }

    return '예상하지 못한 오류가 발생했어요. 다시 시도해 주세요.';
  }

  String _submitErrorMessage(Object error) {
    if (_isNetworkError(error)) {
      return '네트워크 연결이 불안정해서 제출에 실패했어요. 연결을 확인한 뒤 다시 시도해 주세요.';
    }

    return '예상하지 못한 오류가 발생했어요. 다시 시도해 주세요.';
  }

  bool _isNetworkError(Object error) {
    if (error is FirebaseException) {
      final code = error.code.toLowerCase();
      return code == 'unavailable' ||
          code == 'deadline-exceeded' ||
          code == 'network-request-failed';
    }

    final message = error.toString().toLowerCase();
    return message.contains('network') ||
        message.contains('offline') ||
        message.contains('unavailable') ||
        message.contains('deadline-exceeded') ||
        message.contains('failed to fetch') ||
        message.contains('converted future');
  }

  Future<bool> _handleDetectedQrCode(
    String rawValue,
    FestivalUser user,
    Map<String, SeedItem> seedByUid,
  ) async {
    if (_handlingDetectedCode || !_isScanning) {
      return false;
    }

    _handlingDetectedCode = true;
    try {
      if (user.lastSubmittedAt != null) {
        await _showQrErrorDialog('이미 제출완료되어 QR 적립을 추가할 수 없어요.');
        if (mounted) setState(() => _isScanning = false);
        return true;
      }

      final rawSeedUid = rawValue.trim();
      final payload = SeedQrPayload.tryParse(rawSeedUid);
      final seed =
          seedByUid[rawSeedUid] ??
          (payload == null ? null : seedByUid[payload.seedUid]);
      if (seed == null && payload == null) {
        await _showQrErrorDialog('인식한 QR 코드가 부스 등록용 형식이 아니에요.');
        return false;
      }

      if (seed == null) {
        await _showQrErrorDialog('등록되지 않은 부스 QR 코드예요. 최신 QR 코드인지 확인해 주세요.');
        return false;
      }

      if (await _scanBooth(seed, user) && mounted) {
        setState(() => _isScanning = false);
        return true;
      } else {
        return false;
      }
    } finally {
      _handlingDetectedCode = false;
    }
  }

  Future<void> _submitUser(FestivalUser user) async {
    if (_saving || user.lastSubmittedAt != null) return;

    setState(() => _saving = true);

    try {
      await _service.markUserSubmitted(uid: user.uid);
      if (!mounted) return;
      setState(() => _isScanning = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('제출이 완료되었어요.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_submitErrorMessage(error))));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _syncCountsIfNeeded(FestivalUser user, SeedCatalog catalog) {
    final stamp =
        '${user.uid}-${user.updatedAt?.toIso8601String()}-${catalog.seeds.length}';
    if (_loadedStamp == stamp) return;
    final participantLimit = user.participantCount < 1
        ? 1
        : user.participantCount;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _loadedStamp == stamp) return;

      final nextCounts = <String, int>{};
      for (final seed in catalog.seeds) {
        nextCounts[seed.uid] = math.min(
          user.seedCounts[seed.uid] ?? 0,
          participantLimit,
        );
      }

      setState(() {
        _counts
          ..clear()
          ..addAll(nextCounts);
        _loadedStamp = stamp;
      });
    });
  }

  List<_CategoryBoothData> _buildCategoryBooths(SeedCatalog catalog) {
    final groupedSeeds = catalog.seedsByCategory;
    final categories = LinkedHashMap<String, _CategoryBoothData>();
    for (final category in catalog.categories) {
      final seeds = groupedSeeds[category.uid] ?? const <SeedItem>[];
      categories[category.uid] = _CategoryBoothData(
        booth: Booth(
          name: category.name,
          earnedSeedLines: _earnedSeedLines(seeds),
        ),
        visitCount: _categoryVisitCount(seeds),
        totalSeeds: _categorySeedTotal(seeds),
        seeds: seeds,
      );
    }
    for (final entry in groupedSeeds.entries) {
      if (categories.containsKey(entry.key) || entry.value.isEmpty) {
        continue;
      }
      final seeds = entry.value;
      final categoryName = seeds.first.categoryName.trim().isEmpty
          ? '미분류'
          : seeds.first.categoryName.trim();
      categories[entry.key] = _CategoryBoothData(
        booth: Booth(
          name: categoryName,
          earnedSeedLines: _earnedSeedLines(seeds),
        ),
        visitCount: _categoryVisitCount(seeds),
        totalSeeds: _categorySeedTotal(seeds),
        seeds: seeds,
      );
    }
    return categories.values.toList();
  }

  List<SeedItem> _buildScannerSeeds(SeedCatalog catalog) {
    final items = <SeedItem>[];
    final seen = <String>{};
    final groupedSeeds = catalog.seedsByCategory;

    for (final category in catalog.categories) {
      for (final seed in groupedSeeds[category.uid] ?? const <SeedItem>[]) {
        if (seen.add(seed.uid)) {
          items.add(seed);
        }
      }
    }

    for (final seed in catalog.seeds) {
      if (seen.add(seed.uid)) {
        items.add(seed);
      }
    }

    return items;
  }

  int _categoryVisitCount(List<SeedItem> seeds) {
    return seeds.fold<int>(
      0,
      (sum, seed) => sum + math.max(0, _counts[seed.uid] ?? 0),
    );
  }

  int _categorySeedTotal(List<SeedItem> seeds) {
    return seedTotalFromCounts(<String, int>{
      for (final seed in seeds) seed.uid: math.max(0, _counts[seed.uid] ?? 0),
    }, seeds);
  }

  List<String> _earnedSeedLines(List<SeedItem> seeds) {
    return seeds
        .where((seed) => math.max(0, _counts[seed.uid] ?? 0) > 0)
        .map((seed) => '-${seed.name} ${seed.seedValue}SEED')
        .toList();
  }

  Future<bool> _scanBooth(SeedItem seed, FestivalUser user) async {
    final limit = math.max(1, user.participantCount);
    final currentCount = _counts[seed.uid] ?? 0;
    if (currentCount >= limit) {
      await _showQrErrorDialog('${seed.name} 부스는 최대 $limit회까지만 적립할 수 있어요.');
      return false;
    }

    final nextCounts = Map<String, int>.from(_counts)
      ..[seed.uid] = currentCount + 1;

    try {
      await _service.updateUserSeedCounts(
        uid: user.uid,
        seedCounts: nextCounts,
        requireUnsubmitted: true,
      );
      if (!mounted) return false;
      setState(() {
        _counts
          ..clear()
          ..addAll(nextCounts);
      });
      return true;
    } catch (error) {
      await _showQrErrorDialog(_seedUpdateErrorMessage(error));
      return false;
    }
  }

  Future<void> _openSubmitPage(FestivalUser user, int totalSeeds) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SubmitPage(
          userName: user.nickname,
          phoneNumber: user.phoneNumber,
          totalSeeds: totalSeeds,
          isSubmitted: user.lastSubmittedAt != null || _saving,
          onSubmit: () => _submitUser(user),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = widget.uid.trim();
    if (uid.isEmpty) {
      return const _StateShell(
        title: '참여자 정보를 찾을 수 없어요',
        message: '올바른 참여 링크인지 확인한 뒤 다시 접속해 주세요.',
      );
    }

    return StreamBuilder<SeedCatalog>(
      stream: _service.watchSeedCatalog(),
      builder: (context, catalogSnapshot) {
        final catalog =
            catalogSnapshot.data ??
            const SeedCatalog(
              categories: <SeedCategory>[],
              seeds: <SeedItem>[],
            );

        return StreamBuilder<FestivalUser?>(
          stream: _service.watchUser(uid),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting &&
                !userSnapshot.hasData) {
              return const _StateShell(
                title: '참여자 정보를 불러오는 중이에요',
                message: '잠시만 기다리면 등록된 참여자 정보를 확인할 수 있어요.',
              );
            }

            final user = userSnapshot.data;
            if (user == null) {
              return const _StateShell(
                title: '참여자 정보를 찾을 수 없어요',
                message: '등록된 참여자 정보가 없거나 삭제되었어요. 다시 확인해 주세요.',
              );
            }

            _syncCountsIfNeeded(user, catalog);

            final categoryBooths = _buildCategoryBooths(catalog);
            final scannerSeeds = _buildScannerSeeds(catalog);
            final scannerSeedByUid = <String, SeedItem>{
              for (final seed in scannerSeeds) seed.uid: seed,
            };
            final totalSeeds = categoryBooths.fold<int>(
              0,
              (sum, item) => sum + item.totalSeeds,
            );
            final isSubmitted = user.lastSubmittedAt != null || _saving;

            return Scaffold(
              backgroundColor: Colors.white,
              body: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final panelTop = _festivalPanelTopOffset(constraints);

                      return Stack(
                        children: [
                          const Positioned.fill(child: FestivalBackground()),
                          Column(
                            children: [
                              SizedBox(height: panelTop),
                              Expanded(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 220),
                                  child: _isScanning
                                      ? ScannerPanel(
                                          key: ValueKey(
                                            'scanner-$_scannerSessionId',
                                          ),
                                          onClose: _closeScanner,
                                          onCodeDetected: (rawValue) =>
                                              _handleDetectedQrCode(
                                                rawValue,
                                                user,
                                                scannerSeedByUid,
                                              ),
                                        )
                                      : MainPanel(
                                          key: const ValueKey('main'),
                                          userName: user.nickname,
                                          totalSeeds: totalSeeds,
                                          booths: categoryBooths
                                              .map((item) => item.booth)
                                              .toList(),
                                          seedCounts: categoryBooths
                                              .map((item) => item.totalSeeds)
                                              .toList(),
                                          isSubmitted: isSubmitted,
                                          onOpenScanner: () =>
                                              _openScanner(user),
                                          onOpenSubmit: () =>
                                              _openSubmitPage(user, totalSeeds),
                                          onShowLeaflet: _showLeafletMessage,
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _CategoryBoothData {
  const _CategoryBoothData({
    required this.booth,
    required this.visitCount,
    required this.totalSeeds,
    required this.seeds,
  });
  final Booth booth;
  final int visitCount;
  final int totalSeeds;
  final List<SeedItem> seeds;
}

double _festivalPanelTopOffset(BoxConstraints constraints) {
  final widthBasedTop = constraints.maxWidth * 0.62;
  final minTop = constraints.maxHeight * 0.29;
  final maxTop = constraints.maxHeight * 0.38;

  return math.min(math.max(widthBasedTop, minTop), maxTop);
}

double _contentHorizontalPadding(double width) {
  if (width <= 340) {
    return 14;
  }

  if (width >= 410) {
    return 20;
  }

  return 18;
}

class Booth {
  const Booth({required this.name, required this.earnedSeedLines});
  final String name;
  final List<String> earnedSeedLines;
}

class FestivalBackground extends StatelessWidget {
  const FestivalBackground({super.key});

  static const String assetPath = 'assets/images/main_background.png';

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      fit: BoxFit.fitWidth,
      alignment: Alignment.topCenter,
      errorBuilder: (context, error, stackTrace) {
        return const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xffc8e7d7), Color(0xffdff0ee), Color(0xffeff7f6)],
            ),
          ),
        );
      },
    );
  }
}

class LeafBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final topPaint = Paint()
      ..color = const Color(0xff79bf5b).withValues(alpha: 0.58);
    final darkPaint = Paint()
      ..color = const Color(0xff4f9c42).withValues(alpha: 0.38);
    final lightPaint = Paint()
      ..color = const Color(0xffa2d97b).withValues(alpha: 0.48);

    final leaves = [
      _LeafSpot(0.01, -0.02, 54, 32, -0.5, topPaint),
      _LeafSpot(0.12, 0.00, 44, 28, -0.2, lightPaint),
      _LeafSpot(0.23, -0.01, 62, 30, 0.3, topPaint),
      _LeafSpot(0.36, 0.00, 52, 26, -0.25, darkPaint),
      _LeafSpot(0.49, -0.02, 65, 31, 0.2, lightPaint),
      _LeafSpot(0.63, 0.00, 50, 28, -0.35, topPaint),
      _LeafSpot(0.76, -0.01, 62, 30, 0.4, darkPaint),
      _LeafSpot(0.91, 0.01, 54, 30, -0.25, topPaint),
      _LeafSpot(0.06, 0.07, 48, 25, 0.25, lightPaint),
      _LeafSpot(0.2, 0.08, 56, 28, -0.55, darkPaint),
      _LeafSpot(0.82, 0.08, 48, 24, 0.45, lightPaint),
      _LeafSpot(0.96, 0.07, 56, 30, -0.45, darkPaint),
    ];

    for (final leaf in leaves) {
      canvas.save();
      canvas.translate(size.width * leaf.x, size.height * leaf.y);
      canvas.rotate(leaf.rotation);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: leaf.width,
          height: leaf.height,
        ),
        leaf.paint,
      );
      canvas.restore();
    }

    final washPaint = Paint()..color = Colors.white.withValues(alpha: 0.22);
    for (var i = 0; i < 16; i += 1) {
      final x = size.width * ((i * 37) % 100) / 100;
      final y = 96 + (i % 5) * 28.0;
      canvas.drawCircle(Offset(x, y), 18 + (i % 4) * 7.0, washPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LeafSpot {
  const _LeafSpot(
    this.x,
    this.y,
    this.width,
    this.height,
    this.rotation,
    this.paint,
  );

  final double x;
  final double y;
  final double width;
  final double height;
  final double rotation;
  final Paint paint;
}

class FestivalHeader extends StatelessWidget {
  const FestivalHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Column(
        children: [
          Transform.rotate(
            angle: -0.025,
            child: CustomPaint(
              painter: BannerPainter(),
              child: SizedBox(
                width: 214,
                height: 66,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '충북',
                          style: TextStyle(
                            color: Color(0xff287c42),
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            height: 0.95,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xff287c42),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '2026',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      'Green Festival',
                      style: TextStyle(
                        color: Color(0xffd45f72),
                        fontSize: 19,
                        fontWeight: FontWeight.w500,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '일상속 황금씨앗 모으기',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xff4c8d62),
              fontSize: 25,
              fontWeight: FontWeight.w500,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'STAMP TOUR',
            style: TextStyle(
              color: Color(0xff536b52),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class BannerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final clothPaint = Paint()..color = const Color(0xfffffae8);
    final shadowPaint = Paint()
      ..color = const Color(0xffb7b092).withValues(alpha: 0.18);
    final linePaint = Paint()
      ..color = const Color(0xffcbc5a7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path()
      ..moveTo(14, 11)
      ..quadraticBezierTo(size.width * 0.5, 0, size.width - 14, 11)
      ..lineTo(size.width - 7, size.height - 8)
      ..quadraticBezierTo(size.width * 0.5, size.height - 1, 7, size.height - 8)
      ..close();

    canvas.drawPath(path.shift(const Offset(0, 3)), shadowPaint);
    canvas.drawPath(path, clothPaint);
    canvas.drawPath(path, linePaint);

    final stringPaint = Paint()
      ..color = const Color(0xff948c72)
      ..strokeWidth = 1.4;
    canvas.drawLine(const Offset(18, 15), Offset(0, 0), stringPaint);
    canvas.drawLine(
      Offset(size.width - 18, 15),
      Offset(size.width, 0),
      stringPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MainPanel extends StatelessWidget {
  const MainPanel({
    required this.userName,
    required this.totalSeeds,
    required this.booths,
    required this.seedCounts,
    required this.isSubmitted,
    required this.onOpenScanner,
    required this.onOpenSubmit,
    required this.onShowLeaflet,
    super.key,
  });

  final String userName;
  final int totalSeeds;
  final List<Booth> booths;
  final List<int> seedCounts;
  final bool isSubmitted;
  final VoidCallback onOpenScanner;
  final VoidCallback onOpenSubmit;
  final VoidCallback onShowLeaflet;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = _contentHorizontalPadding(
          constraints.maxWidth,
        );
        final bottomInset = MediaQuery.of(context).viewPadding.bottom;

        return WhitePanel(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  22,
                  horizontalPadding,
                  0,
                ),
                child: SeedSummaryHeader(
                  userName: userName,
                  totalSeeds: totalSeeds,
                  onCollectSeed: isSubmitted ? null : onOpenScanner,
                ),
              ),
              const SizedBox(height: 13),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: const DottedDivider(),
              ),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    9,
                    horizontalPadding,
                    8,
                  ),
                  itemCount: booths.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final seedCount = index < seedCounts.length
                        ? seedCounts[index]
                        : 0;

                    return BoothSeedCard(
                      booth: booths[index],
                      seedCount: seedCount,
                    );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  4,
                  horizontalPadding,
                  math.max(14, bottomInset + 10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedActionButton(
                        label: '행사 리플렛보기',
                        onPressed: onShowLeaflet,
                      ),
                    ),
                    const SizedBox(width: 22),
                    Expanded(
                      child: FilledActionButton(
                        label: isSubmitted ? '제출완료' : '제출하기',
                        onPressed: isSubmitted ? null : onOpenSubmit,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class SeedSummaryHeader extends StatelessWidget {
  const SeedSummaryHeader({
    required this.userName,
    required this.totalSeeds,
    required this.onCollectSeed,
    super.key,
  });

  final String userName;
  final int totalSeeds;
  final VoidCallback? onCollectSeed;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '[$userName]',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                '현재까지 모은 황금씨앗 SEED',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                '부스에서 QR 코드를 찍고 황금씨앗을 모아보세요',
                style: TextStyle(
                  color: Color(0xff343434),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SizedBox(
              width: 112,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SeedIcon(size: 34),
                    const SizedBox(width: 3),
                    Text(
                      '$totalSeeds개',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 94,
              height: 30,
              child: FilledActionButton(
                label: 'SEED모으기',
                fontSize: 16,
                onPressed: onCollectSeed,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class BoothSeedCard extends StatelessWidget {
  const BoothSeedCard({
    required this.booth,
    required this.seedCount,
    super.key,
  });

  final Booth booth;
  final int seedCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xffefefef),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booth.name,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 3),
                for (final earnedSeedLine in booth.earnedSeedLines)
                  Text(
                    earnedSeedLine,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 92),
            child: Wrap(
              spacing: 2,
              runSpacing: 2,
              alignment: WrapAlignment.end,
              children: [
                for (var i = 0; i < seedCount; i += 1)
                  SeedIcon(
                    size: seedCount >= 3 ? 24 : 28,
                    rotation: -0.65 + (i % 3) * 0.08,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ScannerPanel extends StatefulWidget {
  const ScannerPanel({
    required this.onClose,
    required this.onCodeDetected,
    super.key,
  });

  final VoidCallback onClose;
  final Future<bool> Function(String rawValue) onCodeDetected;

  @override
  State<ScannerPanel> createState() => _ScannerPanelState();
}

class _ScannerPanelState extends State<ScannerPanel>
    with WidgetsBindingObserver {
  qr_plus.QRViewController? _controller;
  StreamSubscription<qr_plus.Barcode>? _scanSubscription;
  Timer? _startupTimer;
  bool _isShowingIssueDialog = false;
  bool _didHandleScan = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _armStartupTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || kIsWeb) {
      return;
    }

    switch (state) {
      case AppLifecycleState.resumed:
        if (!_isShowingIssueDialog) {
          unawaited(controller.resumeCamera());
        }
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        unawaited(controller.pauseCamera());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _startupTimer?.cancel();
    unawaited(_scanSubscription?.cancel());
    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      unawaited(_controller?.pauseCamera());
    }
    unawaited(_controller?.resumeCamera());
  }

  void _armStartupTimer() {
    _startupTimer?.cancel();
    _startupTimer = Timer(const Duration(seconds: 10), () {
      if (!mounted || _controller != null) {
        return;
      }

      unawaited(_showScannerIssueDialog('카메라를 시작하지 못했어요. 다시 시도해 주세요.'));
    });
  }

  Future<void> _showScannerIssueDialog(String message) async {
    if (!mounted || _isShowingIssueDialog) return;

    _isShowingIssueDialog = true;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QR 코드 오류'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
    _isShowingIssueDialog = false;
  }

  void _onQrViewCreated(qr_plus.QRViewController controller) {
    _startupTimer?.cancel();
    _controller = controller;
    _scanSubscription?.cancel();

    _scanSubscription = controller.scannedDataStream.listen((scanData) async {
      final rawValue = scanData.code?.trim() ?? '';
      if (rawValue.isEmpty || _didHandleScan) {
        return;
      }

      _didHandleScan = true;
      if (!kIsWeb) {
        await controller.pauseCamera();
      }
      final handled = await widget.onCodeDetected(rawValue);
      if (!handled && mounted) {
        _didHandleScan = false;
        if (!kIsWeb) {
          await controller.resumeCamera();
        }
      }
    });
  }

  void _handlePermissionSet(
    qr_plus.QRViewController controller,
    bool isGranted,
  ) {
    if (isGranted) {
      return;
    }

    unawaited(_showScannerIssueDialog('카메라 권한을 허용한 뒤 다시 시도해 주세요.'));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = _contentHorizontalPadding(
          constraints.maxWidth,
        );
        final bottomInset = MediaQuery.of(context).viewPadding.bottom;

        return WhitePanel(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(horizontalPadding, 16, 10, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'QR 코드 스캔',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: '닫기',
                      onPressed: widget.onClose,
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    0,
                    horizontalPadding,
                    math.max(14, bottomInset + 14),
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: ColoredBox(
                              color: const Color(0xff1f2d25),
                              child: qr_plus.QRView(
                                key: const ValueKey('qr-view'),
                                onQRViewCreated: _onQrViewCreated,
                                onPermissionSet: _handlePermissionSet,
                                cameraFacing: qr_plus.CameraFacing.back,
                                formatsAllowed: const <qr_plus.BarcodeFormat>[
                                  qr_plus.BarcodeFormat.qrcode,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ScannerBoothButton extends StatelessWidget {
  const ScannerBoothButton({
    required this.seed,
    required this.count,
    required this.limit,
    required this.onPressed,
    super.key,
  });

  final SeedItem seed;
  final int count;
  final int limit;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final completed = count >= limit;
    final currentTotal = count * seed.seedValue;
    final maxTotal = limit * seed.seedValue;

    return Material(
      color: const Color(0xfff0f3ef),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: completed ? null : onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      seed.name,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '$currentTotal / $maxTotal SEED',
                      style: TextStyle(
                        color: completed
                            ? const Color(0xff8c8c8c)
                            : const Color(0xff3f8f35),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              SeedIcon(size: completed ? 22 : 26),
              const SizedBox(width: 8),
              Text(
                completed ? '완료' : '+ ${seed.seedValue}SEED',
                style: TextStyle(
                  color: completed
                      ? const Color(0xff8c8c8c)
                      : const Color(0xff3f8f35),
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SubmitPage extends StatelessWidget {
  const SubmitPage({
    required this.userName,
    required this.phoneNumber,
    required this.totalSeeds,
    required this.isSubmitted,
    required this.onSubmit,
    super.key,
  });

  final String userName;
  final String phoneNumber;
  final int totalSeeds;
  final bool isSubmitted;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final panelTop = _festivalPanelTopOffset(constraints);

              return Stack(
                children: [
                  const Positioned.fill(child: FestivalBackground()),
                  Column(
                    children: [
                      SizedBox(height: panelTop),
                      Expanded(
                        child: WhitePanel(
                          child: LayoutBuilder(
                            builder: (context, panelConstraints) {
                              final horizontalPadding =
                                  _contentHorizontalPadding(
                                    panelConstraints.maxWidth,
                                  ) +
                                  4;
                              final bottomInset = MediaQuery.of(
                                context,
                              ).viewPadding.bottom;
                              final seedSize = panelConstraints.maxWidth <= 340
                                  ? 27.0
                                  : 30.0;

                              return SingleChildScrollView(
                                padding: EdgeInsets.fromLTRB(
                                  horizontalPadding,
                                  28,
                                  horizontalPadding,
                                  math.max(22, bottomInset + 22),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      '[$userName]',
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const Text(
                                      '현재까지 모은 황금씨앗 SEED',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Wrap(
                                      alignment: WrapAlignment.center,
                                      spacing: 3,
                                      runSpacing: 4,
                                      children: [
                                        for (var i = 0; i < totalSeeds; i += 1)
                                          SeedIcon(size: seedSize),
                                      ],
                                    ),
                                    const SizedBox(height: 13),
                                    Text(
                                      '총 $totalSeeds개',
                                      style: const TextStyle(
                                        color: Color(0xff303030),
                                        fontSize: 32,
                                        fontWeight: FontWeight.w500,
                                        height: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 21),
                                    const DottedDivider(),
                                    const SizedBox(height: 12),
                                    const Text(
                                      '부스에서 QR코드 적립을 마친 뒤 제출을 완료해 주세요',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      phoneNumber,
                                      style: const TextStyle(
                                        color: Color(0xff3f8f35),
                                        fontSize: 20,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 32),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: SizedBox(
                                            height: 34,
                                            child: OutlinedActionButton(
                                              label: '뒤로가기',
                                              onPressed: () =>
                                                  Navigator.of(context).pop(),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: SizedBox(
                                            height: 34,
                                            child: FilledActionButton(
                                              label: isSubmitted
                                                  ? '제출완료'
                                                  : '제출하기',
                                              onPressed: isSubmitted
                                                  ? null
                                                  : () async {
                                                      await onSubmit();
                                                      if (!context.mounted) {
                                                        return;
                                                      }
                                                      Navigator.of(
                                                        context,
                                                      ).pop();
                                                    },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StateShell extends StatelessWidget {
  const _StateShell({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final panelTop = _festivalPanelTopOffset(constraints);

              return Stack(
                children: [
                  const Positioned.fill(child: FestivalBackground()),
                  Column(
                    children: [
                      SizedBox(height: panelTop),
                      Expanded(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.96),
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SeedIcon(size: 40),
                                  const SizedBox(height: 14),
                                  Text(
                                    title,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    message,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Color(0xff4f4f4f),
                                      fontSize: 20,
                                      fontWeight: FontWeight.w500,
                                      height: 1.45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class WhitePanel extends StatelessWidget {
  const WhitePanel({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: double.infinity, child: child);
  }
}

class FilledActionButton extends StatelessWidget {
  const FilledActionButton({
    required this.label,
    required this.onPressed,
    this.fontSize = 20,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;

    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: disabled
            ? const Color(0xffc7c7c7)
            : const Color(0xff4b9637),
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xffc7c7c7),
        disabledForegroundColor: Colors.white,
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w300),
        ),
      ),
    );
  }
}

class OutlinedActionButton extends StatelessWidget {
  const OutlinedActionButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xff4b9637),
          side: const BorderSide(color: Color(0xff84bd70), width: 1.4),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w300),
          ),
        ),
      ),
    );
  }
}

class DottedDivider extends StatelessWidget {
  const DottedDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: double.infinity,
      height: 1,
      child: CustomPaint(painter: DottedDividerPainter()),
    );
  }
}

class _LeafletImagePage extends StatelessWidget {
  const _LeafletImagePage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('행사 리플렛'),
      ),
      body: InteractiveViewer(
        minScale: 1,
        maxScale: 4,
        child: Center(
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    '리플렛 이미지를 불러오지 못했어요.\n배포 후 다시 확인해 주세요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class DottedDividerPainter extends CustomPainter {
  const DottedDividerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xffd5d5d5)
      ..strokeWidth = 1;
    const dashWidth = 3.0;
    const dashGap = 3.0;
    var x = 0.0;

    while (x < size.width) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(math.min(x + dashWidth, size.width), 0),
        paint,
      );
      x += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SeedIcon extends StatelessWidget {
  const SeedIcon({this.size = 28, this.rotation = -0.65, super.key});

  final double size;
  final double rotation;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 1.25,
      child: Transform.rotate(
        angle: rotation,
        child: CustomPaint(painter: SeedPainter()),
      ),
    );
  }
}

class SeedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = Path()
      ..moveTo(size.width * 0.5, size.height * 0.04)
      ..cubicTo(
        size.width * 1.02,
        size.height * 0.26,
        size.width * 0.92,
        size.height * 0.78,
        size.width * 0.5,
        size.height * 0.96,
      )
      ..cubicTo(
        size.width * 0.08,
        size.height * 0.78,
        -size.width * 0.02,
        size.height * 0.26,
        size.width * 0.5,
        size.height * 0.04,
      )
      ..close();

    final shadowPath = path.shift(
      Offset(size.width * 0.07, size.height * 0.06),
    );
    canvas.drawPath(
      shadowPath,
      Paint()..color = const Color(0xff9b6a16).withValues(alpha: 0.28),
    );

    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xffffd76c), Color(0xffe5a329), Color(0xffc57913)],
      ).createShader(rect);
    canvas.drawPath(path, paint);

    final edgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, size.width * 0.06)
      ..color = const Color(0xffc87813).withValues(alpha: 0.35);
    canvas.drawPath(path, edgePaint);

    final highlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.38)
      ..strokeWidth = math.max(1, size.width * 0.08)
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.34, size.height * 0.26),
      Offset(size.width * 0.48, size.height * 0.66),
      highlight,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
