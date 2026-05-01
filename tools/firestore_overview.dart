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

const _collections = [
  'festivalUsers',
  'smsRequests',
  'seedCategories',
  'seeds',
  'settings',
  'metrics',
];

Future<void> main(List<String> args) async {
  final serviceAccountPath = _resolveServiceAccountPath();
  if (serviceAccountPath == null) {
    stderr.writeln('서비스 계정 JSON 파일을 찾을 수 없습니다.');
    exitCode = 64;
    return;
  }

  final serviceAccountJson =
      jsonDecode(await File(serviceAccountPath).readAsString())
          as Map<String, dynamic>;
  final projectId =
      _asString(serviceAccountJson['project_id']) ??
      _projectIdFromFirebaseJson() ??
      _fallbackProjectId;
  final credentials = ServiceAccountCredentials.fromJson(serviceAccountJson);
  final client = await clientViaServiceAccount(credentials, [_datastoreScope]);

  try {
    stdout.writeln('project: $projectId');
    stdout.writeln('serviceAccount: $serviceAccountPath');
    stdout.writeln('');

    for (final collection in _collections) {
      final documents = await _listDocuments(client, projectId, collection);
      stdout.writeln('$collection: ${documents.length} visible doc(s)');
      for (final doc in documents.take(3)) {
        stdout.writeln('  - ${doc.id} ${doc.summary}');
      }
    }
  } finally {
    client.close();
  }
}

Future<List<_DocumentSummary>> _listDocuments(
  AuthClient client,
  String projectId,
  String collectionId,
) async {
  final response = await client.get(
    Uri.https(
      'firestore.googleapis.com',
      '/v1/projects/$projectId/databases/$_databaseId/documents/$collectionId',
      {'pageSize': '5'},
    ),
    headers: {'Accept': 'application/json'},
  );

  if (response.statusCode == HttpStatus.notFound) {
    return const [];
  }
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw HttpException(
      'list $collectionId failed with HTTP ${response.statusCode}: ${response.body}',
    );
  }

  final decoded = jsonDecode(response.body);
  if (decoded is! Map<String, dynamic>) {
    return const [];
  }
  final documents = decoded['documents'];
  if (documents is! List) {
    return const [];
  }

  return documents
      .whereType<Map<String, dynamic>>()
      .map(_DocumentSummary.fromFirestoreDocument)
      .toList();
}

class _DocumentSummary {
  const _DocumentSummary({required this.id, required this.summary});

  final String id;
  final String summary;

  factory _DocumentSummary.fromFirestoreDocument(Map<String, dynamic> doc) {
    final name = _asString(doc['name']) ?? '';
    final fields = doc['fields'] as Map<String, dynamic>? ?? {};
    final decoded = fields.map((key, value) {
      return MapEntry(key, _decodeFirestoreValue(value));
    });
    final interesting = [
      'status',
      'error',
      'nickname',
      'receiver',
      'phoneNumber',
      'seedCount',
      'totalSeedCount',
      'name',
      'userUid',
    ];
    final parts = <String>[];
    for (final key in interesting) {
      final value = decoded[key];
      if (value == null) continue;
      final displayValue = key == 'receiver' || key == 'phoneNumber'
          ? _maskPhone(value.toString())
          : value.toString();
      parts.add('$key=$displayValue');
    }

    return _DocumentSummary(
      id: name.split('/').last,
      summary: parts.isEmpty ? '' : '(${parts.join(', ')})',
    );
  }
}

String? _resolveServiceAccountPath() {
  final envPath = Platform.environment['GOOGLE_APPLICATION_CREDENTIALS'];
  if (envPath != null &&
      envPath.trim().isNotEmpty &&
      File(envPath.trim()).existsSync()) {
    return envPath.trim();
  }

  for (final candidate in _serviceAccountFileCandidates) {
    if (File(candidate).existsSync()) {
      return candidate;
    }
  }

  final candidates =
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
  return candidates.isEmpty ? null : candidates.first;
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

dynamic _decodeFirestoreValue(Object? value) {
  if (value is! Map) return null;
  if (value.containsKey('stringValue')) return value['stringValue'];
  if (value.containsKey('integerValue')) {
    return int.tryParse(value['integerValue'].toString()) ?? 0;
  }
  if (value.containsKey('doubleValue')) return value['doubleValue'];
  if (value.containsKey('booleanValue')) return value['booleanValue'];
  if (value.containsKey('timestampValue')) return value['timestampValue'];
  if (value.containsKey('nullValue')) return null;
  if (value.containsKey('mapValue')) {
    final fields = value['mapValue']?['fields'];
    if (fields is! Map) return const <String, dynamic>{};
    return fields.map((key, nested) {
      return MapEntry(key.toString(), _decodeFirestoreValue(nested));
    });
  }
  return null;
}

String? _asString(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

String _maskPhone(String phone) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 7) return phone.isEmpty ? '-' : phone;
  return '${digits.substring(0, 3)}****${digits.substring(digits.length - 4)}';
}
