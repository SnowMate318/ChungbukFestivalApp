import 'dart:convert';
import 'dart:io';

import 'package:googleapis_auth/auth_io.dart';
import 'package:greenfestival/data/models/seed_qr_payload.dart';
import 'package:image/image.dart' as img;
import 'package:qr/qr.dart';

const _datastoreScope = 'https://www.googleapis.com/auth/datastore';
const _databaseId = '(default)';
const _fallbackProjectId = 'greenfestival-5320b';
const _serviceAccountFileCandidates = <String>[
  'service-account.json',
  'firebase-service-account.json',
  'greenfestival-5320b-firebase-adminsdk-fbsvc-d1df188295.json',
  'secrets/service-account.json',
];

Future<void> main(List<String> args) async {
  late final _Options options;
  try {
    options = _Options.parse(args);
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

  final serviceAccountPath = _resolveServiceAccountPath(options);
  if (serviceAccountPath == null || serviceAccountPath.trim().isEmpty) {
    stderr.writeln('A service account JSON file is required.');
    stderr.writeln(
      'Place service-account.json in the project root or use --service-account.',
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
    final generator = _BoothQrCodeGenerator(
      client: client,
      projectId: projectId,
      outputDirectory: options.outputDirectory,
    );
    await generator.run(confirm: options.confirm);
  } finally {
    client.close();
  }
}

class _BoothQrCodeGenerator {
  const _BoothQrCodeGenerator({
    required this.client,
    required this.projectId,
    required this.outputDirectory,
  });

  final AuthClient client;
  final String projectId;
  final String outputDirectory;

  Future<void> run({required bool confirm}) async {
    final seeds = await _fetchSeeds();
    if (seeds.isEmpty) {
      stdout.writeln('[generate_booth_qrcodes] no booth documents found.');
      return;
    }

    stdout.writeln('[generate_booth_qrcodes] project: $projectId');
    stdout.writeln('[generate_booth_qrcodes] booths: ${seeds.length}');
    stdout.writeln('[generate_booth_qrcodes] output: $outputDirectory');
    for (final seed in seeds.take(8)) {
      stdout.writeln('  - ${seed.categoryName}_${seed.name}.png');
    }
    if (seeds.length > 8) {
      stdout.writeln('  ... ${seeds.length - 8} more');
    }

    if (!confirm) {
      stdout.writeln('');
      stdout.writeln(
        '[generate_booth_qrcodes] dry-run only. Add --confirm to create PNG files.',
      );
      return;
    }

    final directory = Directory(outputDirectory);
    directory.createSync(recursive: true);

    var writtenCount = 0;
    for (final seed in seeds) {
      final payload = SeedQrPayload(seedUid: seed.uid).encode();
      final fileName =
          '${_safeFileComponent(seed.categoryName)}_${_safeFileComponent(seed.name)}.png';
      final filePath = '${directory.path}${Platform.pathSeparator}$fileName';
      final pngBytes = _buildQrPng(payload);
      await File(filePath).writeAsBytes(pngBytes, flush: true);
      writtenCount += 1;
    }

    stdout.writeln(
      '[generate_booth_qrcodes] done. wrote $writtenCount PNG files.',
    );
  }

  Future<List<_SeedQrSpec>> _fetchSeeds() async {
    final items = <_SeedQrSpec>[];
    String? pageToken;

    do {
      final queryParameters = <String, String>{'pageSize': '500'};
      if (pageToken != null && pageToken.isNotEmpty) {
        queryParameters['pageToken'] = pageToken;
      }
      final uri = Uri.https(
        'firestore.googleapis.com',
        '/v1/projects/$projectId/databases/$_databaseId/documents/seeds',
        queryParameters,
      );
      final response = await client.get(
        uri,
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'Failed to fetch seeds: HTTP ${response.statusCode} ${response.body}',
        );
      }

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final documents = (payload['documents'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>();
      for (final document in documents) {
        final fields =
            (document['fields'] as Map<String, dynamic>? ?? const {});
        final uid =
            _fieldString(fields['uid']) ??
            document['name']?.toString().split('/').last ??
            '';
        final name = _fieldString(fields['name']) ?? '';
        final categoryName = _fieldString(fields['categoryName']) ?? '';
        if (uid.isEmpty || name.isEmpty || categoryName.isEmpty) {
          continue;
        }
        items.add(
          _SeedQrSpec(uid: uid, name: name, categoryName: categoryName),
        );
      }
      pageToken = _asString(payload['nextPageToken']);
    } while (pageToken != null && pageToken.isNotEmpty);

    items.sort((a, b) {
      final categoryCompare = a.categoryName.compareTo(b.categoryName);
      if (categoryCompare != 0) {
        return categoryCompare;
      }
      return a.name.compareTo(b.name);
    });
    return items;
  }
}

class _SeedQrSpec {
  const _SeedQrSpec({
    required this.uid,
    required this.name,
    required this.categoryName,
  });

  final String uid;
  final String name;
  final String categoryName;
}

class _Options {
  const _Options({
    required this.help,
    required this.confirm,
    required this.serviceAccountPath,
    required this.projectId,
    required this.outputDirectory,
  });

  final bool help;
  final bool confirm;
  final String? serviceAccountPath;
  final String? projectId;
  final String outputDirectory;

  static _Options parse(List<String> args) {
    var help = false;
    var confirm = false;
    String? serviceAccountPath;
    String? projectId;
    var outputDirectory = 'qrcodes';

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
      if (arg.startsWith('--output=')) {
        outputDirectory = arg.substring('--output='.length).trim();
        continue;
      }
      if (arg == '--output') {
        if (index + 1 >= args.length) {
          throw const FormatException('Missing value for --output.');
        }
        outputDirectory = args[++index].trim();
        continue;
      }

      throw FormatException('Unknown argument: $arg');
    }

    return _Options(
      help: help,
      confirm: confirm,
      serviceAccountPath: serviceAccountPath,
      projectId: projectId,
      outputDirectory: outputDirectory,
    );
  }
}

List<int> _buildQrPng(String payload) {
  final qrCode = QrCode.fromData(
    data: payload,
    errorCorrectLevel: QrErrorCorrectLevel.M,
  );
  final qrImage = QrImage(qrCode);
  const pixelsPerModule = 12;
  const quietZone = 4;

  final moduleCount = qrCode.moduleCount;
  final imageSize = (moduleCount + (quietZone * 2)) * pixelsPerModule;
  final image = img.Image(width: imageSize, height: imageSize);
  img.fill(image, color: img.ColorRgb8(255, 255, 255));

  for (var y = 0; y < moduleCount; y += 1) {
    for (var x = 0; x < moduleCount; x += 1) {
      if (!qrImage.isDark(y, x)) {
        continue;
      }

      final left = (x + quietZone) * pixelsPerModule;
      final top = (y + quietZone) * pixelsPerModule;
      img.fillRect(
        image,
        x1: left,
        y1: top,
        x2: left + pixelsPerModule - 1,
        y2: top + pixelsPerModule - 1,
        color: img.ColorRgb8(0, 0, 0),
      );
    }
  }

  return img.encodePng(image);
}

String _safeFileComponent(String value) {
  final normalized = value
      .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (normalized.isEmpty) {
    return 'unnamed';
  }
  return normalized.replaceAll(RegExp(r'[. ]+$'), '');
}

String? _fieldString(Object? field) {
  if (field is! Map) {
    return null;
  }

  final stringValue = _asString(field['stringValue']);
  if (stringValue != null && stringValue.isNotEmpty) {
    return stringValue;
  }

  return _asString(field['integerValue']);
}

String? _resolveServiceAccountPath(_Options options) {
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
  if (!file.existsSync()) {
    return null;
  }

  try {
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final flutter = json['flutter'];
    if (flutter is! Map) {
      return null;
    }
    final platforms = flutter['platforms'];
    if (platforms is! Map) {
      return null;
    }
    final dart = platforms['dart'];
    if (dart is! Map) {
      return null;
    }
    final options = dart['lib/firebase_options.dart'];
    if (options is! Map) {
      return null;
    }
    return _asString(options['projectId']);
  } catch (_) {
    return null;
  }
}

String? _asString(Object? value) {
  if (value == null) {
    return null;
  }

  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

void _printUsage() {
  stdout.writeln('Usage: dart run tools/generate_booth_qrcodes.dart [options]');
  stdout.writeln('');
  stdout.writeln('Options:');
  stdout.writeln('  --confirm                  Actually create PNG files');
  stdout.writeln(
    '  --output <path>            Output directory (default: qrcodes)',
  );
  stdout.writeln('  --service-account <path>   Service account JSON file path');
  stdout.writeln('  --project-id <id>          Override Firebase project ID');
  stdout.writeln('  --help, -h                 Show this help message');
}
