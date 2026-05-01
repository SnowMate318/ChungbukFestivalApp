import 'dart:convert';
import 'dart:io';

import 'package:googleapis_auth/auth_io.dart';

const _datastoreScope = 'https://www.googleapis.com/auth/datastore';
const _databaseId = '(default)';
const _fallbackProjectId = 'greenfestival-5320b';
const _serviceAccountFileCandidates = [
  'service-account.json',
  'firebase-service-account.json',
  'greenfestival-5320b-firebase-adminsdk-fbsvc-d1df188295.json',
  'secrets/service-account.json',
];

const _categoryNameOverrides = <String, String>{'예비QR': '예비 QR'};

const _rawCatalog = '''
(카테고리) 운영부스
일상 속 탄소중립
어린이 환경 사생대회

(카테고리) 홍보
청주시탄소중립지원센터
중소벤처기업진흥공단
청주시 도시공사
탄소중립지원센터

(카테고리) 기부
고급용지, 캔, 플라스틱 기부
플라스틱 장난감 기부
의류기부

(카테고리) 다회용기반납
잔반ZERO
다회용기반납

(카테고리) 대학생 동아리
업사이클 화분제작
오호 물병만들기
나로 알아가는 멸종위기 자연
흙살려, 플라살려
풀뜯어 먹는 소리
폐도자기 새활용

(카테고리) 환경체험
전기에너지 만드는 자전거 체험
제로웨이스트 가드닝 : 상추 한 컵 텃밭
자원순환 체험 “나는 분리배출 마스터
쓰레기 잘 모아야 탄소중립!!
미호강에 사는 미호종개 만들기
쓰레기 섬 대탈출: 플라스틱 아일랜드 보드게임
환경을 위한 우리의 선택, 녹색제품
멋쟁이 곤충 무당벌레 만들기
지:금 버리면 구:하기 어려워요!! 함께 지켜요, 지구
한복 꽃 브로치 만들기
폐전선 새활용 사탕 바구니 만들기
친환경 아로마 주물럭바 만들기
마크라메 매듭팔찌 & 걱정인형 만들기
자투리 가죽 판다 키링 만들기
고래오래 커피박 키링만들기

(카테고리) 38동 전시
참여전시(일상 속 탄소중립선언)

(카테고리) 순환경제프로그램
전시관람
나의 순환경제 다짐
폐의류 및 HOPE 병뚜껑 체험

(카테고리) 판매
사회연대경제 장터이용 1
사회연대경제 장터이용 2
사회연대경제 장터이용 3
사회연대경제 장터이용 4
사회연대경제 장터이용 5
사회연대경제 장터이용 6
사회연대경제 장터이용 7
사회연대경제 장터이용 8
사회연대경제 장터이용 9
사회연대경제 장터이용 10
사회연대경제 장터이용 11
사회연대경제 장터이용 12
사회연대경제 장터이용 13
사회연대경제 장터이용 14
사회연대경제 장터이용 15

(카테고리)가라지세일
중고의류구매
중고가전·가구구매
중고서적구매
기타 중고물품 구매

(카테고리)가족환경골든벨
가족환경골든벨

(카테고리)탄소중립실천교육
탄소중립실천교육

(카테고리)예비QR
내가 실천한 탄소중립 1
내가 실천한 탄소중립 2
내가 실천한 탄소중립 3
내가 실천한 탄소중립 4
내가 실천한 탄소중립 5
내가 실천한 탄소중립 6
내가 실천한 탄소중립 7
내가 실천한 탄소중립 8
내가 실천한 탄소중립 9
내가 실천한 탄소중립 10
''';

Future<void> main(List<String> args) async {
  late final ImportOptions options;
  try {
    options = ImportOptions.parse(args);
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    stderr.writeln('');
    _printUsage();
    exitCode = 64;
    return;
  }

  if (options.help) {
    _printUsage();
    return;
  }

  final categories = _parseCatalog(_rawCatalog);
  _validateCatalog(categories);

  final boothCount = categories.fold<int>(
    0,
    (sum, category) => sum + category.booths.length,
  );
  final writes = _buildWrites('DRY_RUN_PROJECT', categories);

  stdout.writeln('[import_seed_catalog] categories: ${categories.length}');
  stdout.writeln('[import_seed_catalog] booths: $boothCount');
  stdout.writeln('[import_seed_catalog] planned writes: ${writes.length}');
  for (final category in categories) {
    stdout.writeln('  - ${category.name}: ${category.booths.length} booth(s)');
  }

  if (!options.confirm) {
    stdout.writeln('');
    stdout.writeln(
      '[import_seed_catalog] dry-run only. Add --confirm to write to Firestore.',
    );
    return;
  }

  final serviceAccountPath = _resolveServiceAccountPath(options);
  if (serviceAccountPath == null || serviceAccountPath.trim().isEmpty) {
    stderr.writeln('A service account JSON file is required.');
    stderr.writeln(
      'Place service-account.json in the project root or use --service-account.',
    );
    stderr.writeln(
      r'Example: dart run tools/import_seed_catalog.dart --service-account C:\path\service-account.json --confirm',
    );
    exitCode = 64;
    return;
  }

  final serviceAccountFile = File(serviceAccountPath);
  if (!serviceAccountFile.existsSync()) {
    stderr.writeln('Service account file not found: $serviceAccountPath');
    exitCode = 66;
    return;
  }

  final serviceAccountJson =
      jsonDecode(await serviceAccountFile.readAsString())
          as Map<String, dynamic>;
  final projectId =
      options.projectId ??
      Platform.environment['FIREBASE_PROJECT_ID'] ??
      Platform.environment['GCLOUD_PROJECT'] ??
      Platform.environment['GOOGLE_CLOUD_PROJECT'] ??
      _asString(serviceAccountJson['project_id']) ??
      _projectIdFromFirebaseJson() ??
      _fallbackProjectId;

  final credentials = ServiceAccountCredentials.fromJson(serviceAccountJson);
  final client = await clientViaServiceAccount(credentials, [_datastoreScope]);

  try {
    final importer = _FirestoreSeedCatalogImporter(
      client: client,
      projectId: projectId,
      categories: categories,
    );
    await importer.import();
  } finally {
    client.close();
  }
}

class _FirestoreSeedCatalogImporter {
  const _FirestoreSeedCatalogImporter({
    required this.client,
    required this.projectId,
    required this.categories,
  });

  final AuthClient client;
  final String projectId;
  final List<_CategorySpec> categories;

  Future<void> import() async {
    final writes = _buildWrites(projectId, categories);
    stdout.writeln('[import_seed_catalog] project: $projectId');
    stdout.writeln('[import_seed_catalog] writing ${writes.length} documents');

    final chunks = _chunk(writes, 400);
    for (var index = 0; index < chunks.length; index += 1) {
      final chunk = chunks[index];
      stdout.writeln(
        '[import_seed_catalog] commit batch ${index + 1}/${chunks.length} (${chunk.length} writes)',
      );
      await _commit(chunk);
    }

    stdout.writeln('[import_seed_catalog] done');
  }

  Future<void> _commit(List<Map<String, dynamic>> writes) async {
    final uri = Uri.https(
      'firestore.googleapis.com',
      '/v1/projects/$projectId/databases/$_databaseId/documents:commit',
    );
    final response = await client.post(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json; charset=utf-8',
      },
      body: jsonEncode({'writes': writes}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'commit failed with HTTP ${response.statusCode}: ${response.body}',
      );
    }
  }
}

class ImportOptions {
  const ImportOptions({
    required this.help,
    required this.confirm,
    required this.serviceAccountPath,
    required this.projectId,
  });

  final bool help;
  final bool confirm;
  final String? serviceAccountPath;
  final String? projectId;

  static ImportOptions parse(List<String> args) {
    var help = false;
    var confirm = false;
    String? serviceAccountPath;
    String? projectId;

    for (var index = 0; index < args.length; index += 1) {
      final arg = args[index];
      if (arg == '--help' || arg == '-h') {
        help = true;
        continue;
      }
      if (arg == '--confirm') {
        confirm = true;
        continue;
      }
      if (arg.startsWith('--service-account=')) {
        serviceAccountPath = arg.substring('--service-account='.length).trim();
        continue;
      }
      if (arg == '--service-account') {
        if (index + 1 >= args.length) {
          throw const FormatException('Missing value for --service-account.');
        }
        serviceAccountPath = args[++index].trim();
        continue;
      }
      if (arg.startsWith('--project-id=')) {
        projectId = arg.substring('--project-id='.length).trim();
        continue;
      }
      if (arg == '--project-id') {
        if (index + 1 >= args.length) {
          throw const FormatException('Missing value for --project-id.');
        }
        projectId = args[++index].trim();
        continue;
      }

      throw FormatException('Unknown argument: $arg');
    }

    return ImportOptions(
      help: help,
      confirm: confirm,
      serviceAccountPath: serviceAccountPath,
      projectId: projectId,
    );
  }
}

class _CategorySpec {
  const _CategorySpec({required this.name, required this.booths});

  final String name;
  final List<String> booths;
}

List<_CategorySpec> _parseCatalog(String rawCatalog) {
  final categories = <_CategorySpec>[];
  String? currentCategory;
  final currentBooths = <String>[];

  void flush() {
    final categoryName = currentCategory;
    if (categoryName == null) return;
    categories.add(
      _CategorySpec(
        name: categoryName,
        booths: List<String>.unmodifiable(currentBooths),
      ),
    );
    currentBooths.clear();
  }

  for (final rawLine in const LineSplitter().convert(rawCatalog)) {
    final line = rawLine.trim();
    if (line.isEmpty) {
      continue;
    }

    if (line.startsWith('(카테고리)')) {
      flush();
      currentCategory = _normalizeCategoryName(
        line.replaceFirst('(카테고리)', '').trim(),
      );
      continue;
    }

    if (currentCategory == null) {
      throw FormatException('Booth found before category: $line');
    }

    currentBooths.add(line);
  }

  flush();
  return List<_CategorySpec>.unmodifiable(categories);
}

void _validateCatalog(List<_CategorySpec> categories) {
  if (categories.isEmpty) {
    throw const FormatException('No categories were parsed.');
  }

  final categoryNames = <String>{};
  final boothNames = <String>{};

  for (final category in categories) {
    if (category.name.isEmpty) {
      throw const FormatException('A category name is empty.');
    }
    if (!categoryNames.add(category.name)) {
      throw FormatException('Duplicate category name: ${category.name}');
    }
    if (category.booths.isEmpty) {
      throw FormatException('Category has no booths: ${category.name}');
    }

    for (final booth in category.booths) {
      final normalizedBooth = booth.trim();
      if (normalizedBooth.isEmpty) {
        throw FormatException('Empty booth name found in ${category.name}');
      }
      if (!boothNames.add(normalizedBooth)) {
        throw FormatException('Duplicate booth name: $normalizedBooth');
      }
    }
  }
}

String _normalizeCategoryName(String value) {
  final trimmed = value.replaceAll(RegExp(r'\s+'), ' ').trim();
  return _categoryNameOverrides[trimmed] ?? trimmed;
}

List<Map<String, dynamic>> _buildWrites(
  String projectId,
  List<_CategorySpec> categories,
) {
  final timestamp = DateTime.now().toUtc().toIso8601String();
  final writes = <Map<String, dynamic>>[];

  for (final category in categories) {
    final categoryKey = _uniqueKey(category.name);
    final categoryId = 'seed-category-$categoryKey';

    writes.add(
      _setWrite(
        projectId: projectId,
        relativePath: 'seedCategories/$categoryId',
        fields: {
          'uid': _stringField(categoryId),
          'name': _stringField(category.name),
          'createdAt': _timestampField(timestamp),
          'updatedAt': _timestampField(timestamp),
        },
      ),
    );

    writes.add(
      _setWrite(
        projectId: projectId,
        relativePath: 'uniqueCategoryNames/$categoryKey',
        fields: {
          'uid': _stringField(categoryId),
          'value': _stringField(category.name),
          'createdAt': _timestampField(timestamp),
        },
      ),
    );

    for (final booth in category.booths) {
      final boothName = booth.trim();
      final seedKey = _uniqueKey(boothName);
      final seedId = 'seed-$seedKey';

      writes.add(
        _setWrite(
          projectId: projectId,
          relativePath: 'seeds/$seedId',
          fields: {
            'uid': _stringField(seedId),
            'name': _stringField(boothName),
            'categoryUid': _stringField(categoryId),
            'categoryName': _stringField(category.name),
            'seedValue': _integerField(1),
            'createdAt': _timestampField(timestamp),
            'updatedAt': _timestampField(timestamp),
          },
        ),
      );

      writes.add(
        _setWrite(
          projectId: projectId,
          relativePath: 'uniqueSeedNames/$seedKey',
          fields: {
            'uid': _stringField(seedId),
            'value': _stringField(boothName),
            'categoryUid': _stringField(categoryId),
            'createdAt': _timestampField(timestamp),
          },
        ),
      );
    }
  }

  return writes;
}

Map<String, dynamic> _setWrite({
  required String projectId,
  required String relativePath,
  required Map<String, Map<String, dynamic>> fields,
}) {
  return {
    'update': {
      'name': _documentName(projectId, relativePath),
      'fields': fields,
    },
  };
}

String _documentName(String projectId, String relativePath) {
  return 'projects/$projectId/databases/$_databaseId/documents/$relativePath';
}

Map<String, dynamic> _stringField(String value) => {'stringValue': value};

Map<String, dynamic> _integerField(int value) => {
  'integerValue': value.toString(),
};

Map<String, dynamic> _timestampField(String value) => {'timestampValue': value};

String _uniqueKey(String value) {
  return base64Url
      .encode(utf8.encode(value.trim().toLowerCase()))
      .replaceAll('=', '');
}

String? _resolveServiceAccountPath(ImportOptions options) {
  final explicitPath =
      options.serviceAccountPath ??
      Platform.environment['GOOGLE_APPLICATION_CREDENTIALS'];
  if (explicitPath != null && explicitPath.trim().isNotEmpty) {
    return explicitPath.trim();
  }

  for (final candidate in _serviceAccountFileCandidates) {
    if (File(candidate).existsSync()) {
      return candidate;
    }
  }

  return _findFirebaseAdminSdkJson();
}

String? _findFirebaseAdminSdkJson() {
  final files =
      Directory.current
          .listSync(followLinks: false)
          .whereType<File>()
          .map((file) => file.path)
          .where((path) {
            final normalized = path.toLowerCase().replaceAll('\\', '/');
            return normalized.endsWith('.json') &&
                normalized.contains('firebase-adminsdk');
          })
          .toList()
        ..sort();

  if (files.isEmpty) {
    return null;
  }
  return files.first;
}

String? _projectIdFromFirebaseJson() {
  final file = File('firebase.json');
  if (!file.existsSync()) return null;

  try {
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final flutter = json['flutter'];
    if (flutter is! Map) return null;
    final platforms = flutter['platforms'];
    if (platforms is! Map) return null;
    final dart = platforms['dart'];
    if (dart is! Map) return null;
    final options = dart['lib/firebase_options.dart'];
    if (options is! Map) return null;
    return _asString(options['projectId']);
  } catch (_) {
    return null;
  }
}

String? _asString(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

List<List<T>> _chunk<T>(List<T> items, int size) {
  final chunks = <List<T>>[];
  for (var index = 0; index < items.length; index += size) {
    final end = index + size > items.length ? items.length : index + size;
    chunks.add(items.sublist(index, end));
  }
  return chunks;
}

void _printUsage() {
  stdout.writeln('Usage: dart run tools/import_seed_catalog.dart [options]');
  stdout.writeln('');
  stdout.writeln('Options:');
  stdout.writeln('  --confirm                  Actually write to Firestore');
  stdout.writeln('  --service-account <path>   Service account JSON file path');
  stdout.writeln('  --project-id <id>          Override Firebase project ID');
  stdout.writeln('  --help, -h                 Show this help message');
}
