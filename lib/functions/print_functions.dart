// import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../data/models/receipt_item.dart';

//bool participate = true  true :참여함  false : 참여하지 않음
Future<void> printKrisoReceipt(
  List<ReceiptItem> items, {
  bool participate = true,
}) async {
  // // 테스트 데이터
  // final List<ReceiptItem> items = [
  //   ReceiptItem('1편 [선박이 위치를 찾는 방법]', 1),
  //   ReceiptItem('2편 [KRISO의 친환경 대체 연료해상실증선박?]', 2),
  //   ReceiptItem('3편 [KRISO의 해양그린수소?]', 1),
  //   ReceiptItem('4편 [KRISO의 전기추진선박?]', 1),
  //   ReceiptItem('5편 [해양생물을 괴롭히는 선박소음?!]', 3),
  //   ReceiptItem('6편 [심해에서도 로봇이 활용되고 있다는 사실]', 1),
  // ];

  print('📦 전달된 아이템 목록 (${items.length}개):');
  for (final item in items) {
    print(' - ${item.title} (수량: ${item.qty})');
  }

  final title = '크리소 이지';

  // ✅ 한글 폰트 로드
  final regularFontData = await rootBundle.load(
    'assets/fonts/Hakgyoansim Allimjang TTF R.ttf',
  );
  final regularFont = pw.Font.ttf(regularFontData);
  final boldFontData = await rootBundle.load(
    'assets/fonts/Hakgyoansim Allimjang TTF B.ttf',
  );
  final boldFont = pw.Font.ttf(boldFontData);

  // ✅ 이미지 로드 (rootBundle 사용)
  final titleImage = (await rootBundle.load(
    'assets/pictures/title.png',
  )).buffer.asUint8List();
  final subtitleImage = (await rootBundle.load(
    'assets/pictures/subtitle.png',
  )).buffer.asUint8List();
  final middle1Image = (await rootBundle.load(
    'assets/pictures/middle1.png',
  )).buffer.asUint8List();
  final middle2Image = (await rootBundle.load(
    'assets/pictures/middle2.png',
  )).buffer.asUint8List();
  final logoImage = (await rootBundle.load(
    'assets/pictures/logo.png',
  )).buffer.asUint8List();

  final doc = pw.Document();

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat(72 * PdfPageFormat.mm, double.infinity),
      margin: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 8),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Center(child: pw.Image(pw.MemoryImage(titleImage), width: 190)),
          pw.SizedBox(height: 5),
          pw.Divider(),
          pw.SizedBox(height: 5),
          pw.Center(child: pw.Image(pw.MemoryImage(subtitleImage), width: 140)),
          pw.SizedBox(height: 3),
          pw.Divider(),
          dashedDivider(color: PdfColors.grey700, dashWidth: 3, dashSpace: 2),
          pw.SizedBox(height: 5),
          pw.Text(
            '주문하신 콘텐츠',
            style: pw.TextStyle(font: regularFont, fontSize: 9),
          ),

          // 제목 및 항목 표
          pw.Text(
            '[$title]',
            style: pw.TextStyle(font: boldFont, fontSize: 10),
          ),
          pw.Table(
            columnWidths: {
              0: pw.FixedColumnWidth(10),
              1: pw.FlexColumnWidth(1),
              2: pw.FixedColumnWidth(22),
            },
            defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
            children: [
              for (var i = 0; i < items.length; i++)
                pw.TableRow(
                  children: [
                    pw.Align(
                      alignment: pw.Alignment.centerRight,
                      child: pw.Text(
                        '${i + 1}.',
                        style: pw.TextStyle(font: boldFont, fontSize: 9),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(
                        left: 4,
                        right: 6,
                        top: 2,
                        bottom: 2,
                      ),
                      child: pw.Text(
                        items[i].title,
                        style: pw.TextStyle(font: boldFont, fontSize: 9),
                        maxLines: 2,
                      ),
                    ),
                    pw.Align(
                      alignment: pw.Alignment.centerRight,
                      child: pw.Text(
                        '${items[i].qty}',
                        style: pw.TextStyle(font: boldFont, fontSize: 9),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          pw.SizedBox(height: 8),
          dashedDivider(color: PdfColors.grey700, dashWidth: 3, dashSpace: 2),
          pw.Divider(),
          pw.SizedBox(height: 8),

          //만약 참여한다면
          if (participate) ...[
            pw.Text(
              '퀴즈 참여 정보',
              style: pw.TextStyle(font: regularFont, fontSize: 9),
            ),
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  child: pw.Text(
                    'Q1. 선박해양플랜트연구소의 연구분야는?',
                    style: pw.TextStyle(font: boldFont, fontSize: 10),
                  ),
                ),
                pw.Text(
                  '[정답 4번]',
                  style: pw.TextStyle(font: boldFont, fontSize: 10),
                ),
              ],
            ),
            pw.Text(
              'KRISO는 차세대 선박 기술 선점, 미래 해양플랜트 기술개발, 해양로봇·ICT 융복합 기술혁신, 해양교통 및 사고대응 기술확산 등의 연구를 수행하고 있습니다.',
              style: pw.TextStyle(font: regularFont, fontSize: 7),
            ),
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  child: pw.Text(
                    'Q2. KRISO는 친환경 대체연료 선박 적용 기술 연구개발, 육·해상 시험평가 및 실증 등을 수행하기 위한 지역거점을 울산시에 구축하고 있다.',
                    style: pw.TextStyle(font: boldFont, fontSize: 10),
                  ),
                ),
                pw.Text(
                  '[정답 X]',
                  style: pw.TextStyle(font: boldFont, fontSize: 10),
                ),
              ],
            ),
            pw.Text(
              'KRISO는 2050 해양탄소중립(Net-Zero) 실현을 목표로, 친환경 대체연료 선박 적용 기술 개발과 육·해상 시험평가를 수행할 수 있는 지역거점을 전남 목포에 구축하고 있습니다. 주요 연구시설 및 장비로는 1) 친환경대체연료, 전기 및 하이브리드 추진시스템 핵심기술 해상실증 및 트랙레코드 확보를 위한 "친환경대체연료 해상실증 선박(K-GTB)", 2) 대용량 선박용 전기추진시스템 기술개발 및 국산화 지원을 위한 "30MW급 전기추진시스템 육상시험평가 설비(LBTS)" 등이 있습니다.',
              style: pw.TextStyle(font: regularFont, fontSize: 7),
            ),
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  child: pw.Text(
                    'Q3. 선박해양플랜트연구소가 2020년부터 개발해 온 지능형 자율항해시스템의 이름은 무엇일까요?',
                    style: pw.TextStyle(font: boldFont, fontSize: 10),
                  ),
                ),
                pw.Text(
                  '[정답 1]',
                  style: pw.TextStyle(font: boldFont, fontSize: 10),
                ),
              ],
            ),
            pw.Text(
              '지능형 자율항해시스템인 NEMO는 자율운항선박의 핵심으로, 1) 원양 항해나 2) 복잡도가 낮은 근해 항해 등의 조건에서 통항 상황을 자율적으로 판단하여 주어진 항로를 추종하고, 안전한 항해를 지속하도록 설계되었습니다. 이 시스템은 KRISO의 해양누리호(자율운항선박 관련 기술, 장비 등을 해상 테스트하기 위한 시험선)에 탑재된 뒤, 다양한 실해역 시험을 거쳐 시스템의 성능과 안정성이 확인되었습니다. ',
              style: pw.TextStyle(font: regularFont, fontSize: 7),
            ),

            pw.SizedBox(height: 10),
            dashedDivider(color: PdfColors.grey700, dashWidth: 3, dashSpace: 2),
            pw.Divider(),
            pw.SizedBox(height: 5),
          ],

          // 중간 이미지 + QR + 로고
          pw.Center(
            child: pw.Column(
              children: [
                if (participate) ...[
                  pw.Image(pw.MemoryImage(middle1Image), width: 140),
                ],
                pw.SizedBox(height: 5),
                pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: 'https://www.youtube.com/@kriso6977',
                  width: 70,
                  height: 70,
                ),
                pw.SizedBox(height: 5),
                pw.Image(pw.MemoryImage(middle2Image), width: 140),
              ],
            ),
          ),

          pw.SizedBox(height: 8),
          pw.Divider(),
          pw.SizedBox(height: 5),
          pw.Center(child: pw.Image(pw.MemoryImage(logoImage), width: 140)),
          pw.Divider(),
          pw.SizedBox(height: 5),
        ],
      ),
    ),
  );

  // 프린터 선택
  final printers = await Printing.listPrinters();
  final printer = printers.firstWhere(
    (p) => p.name.toUpperCase().contains('SEWOO SLK-CB125'),
    orElse: () {
      print('❌ SEWOO SLK-CB125 프린터를 찾을 수 없습니다.');
      return printers.first;
    },
  );

  final pdfBytes = await doc.save();

  await Printing.directPrintPdf(
    printer: printer,
    onLayout: (format) async => pdfBytes,
    format: PdfPageFormat(72 * PdfPageFormat.mm, 3297 * PdfPageFormat.mm),
    usePrinterSettings: true,
    name: 'KRISO_Receipt',
  );

  print('✅ 인쇄 명령 전송 완료: ${printer.name}');
}

pw.Widget dashedDivider({
  PdfColor color = PdfColors.black,
  double thickness = 1,
  double dashWidth = 4,
  double dashSpace = 2,
}) {
  return pw.LayoutBuilder(
    builder: (context, constraints) {
      final dashCount = (constraints!.maxWidth / (dashWidth + dashSpace))
          .floor();
      return pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: List.generate(dashCount, (_) {
          return pw.Container(
            width: dashWidth,
            height: thickness,
            color: color,
          );
        }),
      );
    },
  );
}
