import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'package:greenfestival/data/models/festival_admin_models.dart';
import 'package:greenfestival/data/models/festival_admin_reports.dart';
import 'package:intl/intl.dart';

class FestivalExcelExporter {
  const FestivalExcelExporter._();

  static final DateFormat _fileStampFormat = DateFormat('yyyyMMdd_HHmm');
  static final DateFormat _dateFormat = DateFormat(
    'yyyy. M. d. HH:mm',
    'ko_KR',
  );

  static Future<void> saveUsers(List<FestivalUser> users) async {
    final excel = Excel.createExcel();
    final userSheet = excel['유저 정보'];
    final summarySheet = excel['유저 요약'];
    excel.delete('Sheet1');
    excel.setDefaultSheet('유저 정보');

    _appendRow(userSheet, [
      '닉네임',
      '휴대폰번호',
      '성별',
      '연령',
      '참여인원',
      '거주정보',
      '시드 갯수',
      '최근 제출',
    ]);
    for (final user in users) {
      _appendRow(userSheet, [
        user.nickname,
        user.phoneNumber,
        reportGenderLabel(user),
        reportAgeLabel(user),
        user.participantCount,
        reportResidenceLabel(user),
        user.seedCount,
        _formatDate(user.lastSubmittedAt),
      ]);
    }

    _appendRow(summarySheet, ['구분', '값', '참여인원', '시드 갯수']);
    for (final row in buildFestivalUserSummaryRows(users)) {
      _appendRow(summarySheet, [
        row.groupName,
        row.label,
        row.participantCount,
        row.seedCount,
      ]);
    }
    _autoFitColumns(userSheet, 8);
    _autoFitColumns(summarySheet, 4);

    await _saveExcel(
      excel,
      'festival_users_${_fileStampFormat.format(DateTime.now())}',
    );
  }

  static Future<void> saveBooths(List<FestivalBoothSummaryRow> rows) async {
    final excel = Excel.createExcel();
    final boothSheet = excel['부스 정보'];
    final summarySheet = excel['카테고리 요약'];
    excel.delete('Sheet1');
    excel.setDefaultSheet('부스 정보');

    _appendRow(boothSheet, ['카테고리 명', '부스 명', '부스 별 시드 발행 갯수']);
    for (final row in rows) {
      _appendRow(boothSheet, [
        row.categoryName,
        row.boothName,
        row.issuedSeedCount,
      ]);
    }

    _appendRow(summarySheet, ['카테고리 명', '시드 발행 갯수']);
    for (final row in buildFestivalCategorySummaryRows(rows)) {
      _appendRow(summarySheet, [row.categoryName, row.issuedSeedCount]);
    }
    _autoFitColumns(boothSheet, 3);
    _autoFitColumns(summarySheet, 2);

    await _saveExcel(
      excel,
      'festival_booths_${_fileStampFormat.format(DateTime.now())}',
    );
  }

  static Future<void> _saveExcel(Excel excel, String fileName) async {
    final encoded = excel.encode();
    if (encoded == null) {
      throw Exception('Excel 파일을 생성할 수 없습니다.');
    }
    await FileSaver.instance.saveFile(
      name: fileName,
      bytes: Uint8List.fromList(encoded),
      fileExtension: 'xlsx',
      mimeType: MimeType.microsoftExcel,
    );
  }

  static void _appendRow(Sheet sheet, List<Object?> values) {
    sheet.appendRow(values.map(_cellValue).toList());
  }

  static void _autoFitColumns(Sheet sheet, int columnCount) {
    for (var index = 0; index < columnCount; index += 1) {
      sheet.setColumnAutoFit(index);
    }
  }

  static CellValue _cellValue(Object? value) {
    if (value is int) return IntCellValue(value);
    if (value is double) return DoubleCellValue(value);
    if (value is bool) return BoolCellValue(value);
    return TextCellValue(value?.toString() ?? '');
  }

  static String _formatDate(DateTime? value) {
    if (value == null) return '미제출';
    return _dateFormat.format(value);
  }
}
