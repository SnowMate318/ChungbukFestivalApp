import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:googleapis_auth/auth_io.dart';

const _datastoreScope = 'https://www.googleapis.com/auth/datastore';
const _databaseId = '(default)';
const _fallbackProjectId = 'greenfestival-5320b';
const _smsCollectionId = 'smsRequests';
const _serviceAccountFileCandidates = [
  'service-account.json',
  'firebase-service-account.json',
  'greenfestival-5320b-firebase-adminsdk-fbsvc-d1df188295.json',
  'secrets/service-account.json',
];

Future<void> main(List<String> args) async {
  late final SmsRequestOptions options;
  try {
    options = SmsRequestOptions.parse(args);
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

  if (options.retry && !options.confirm) {
    stderr.writeln('재시도는 --retry --confirm을 함께 붙여야 실행됩니다.');
    exitCode = 64;
    return;
  }

  final serviceAccountPath = _resolveServiceAccountPath(options.serviceAccount);
  if (serviceAccountPath == null) {
    stderr.writeln('서비스 계정 JSON 파일을 찾을 수 없습니다.');
    stderr.writeln('프로젝트 루트에 *firebase-adminsdk*.json 파일을 두거나');
    stderr.writeln('--service-account 옵션을 사용해주세요.');
    exitCode = 64;
    return;
  }

  final serviceAccountJson =
      jsonDecode(await File(serviceAccountPath).readAsString())
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
    final tool = SmsRequestTool(client: client, projectId: projectId);
    final requests = await tool.fetchRecent(limit: options.limit);
    if (requests.isEmpty) {
      stdout.writeln('smsRequests 문서가 없습니다.');
      return;
    }

    stdout.writeln('최근 smsRequests ${requests.length}건');
    stdout.writeln('');
    for (final request in requests) {
      request.printSummary();
    }

    if (!options.retry) {
      stdout.writeln('');
      stdout.writeln('failed/skipped 요청을 재시도하려면:');
      stdout.writeln('  dart run tool/sms_requests.dart --retry --confirm');
      return;
    }

    final retryTargets = requests
        .where(
          (request) =>
              request.status == 'failed' || request.status == 'skipped',
        )
        .toList();

    if (retryTargets.isEmpty) {
      stdout.writeln('');
      stdout.writeln('재시도할 failed/skipped 요청이 없습니다.');
      return;
    }

    stdout.writeln('');
    stdout.writeln('${retryTargets.length}건을 pending으로 되돌립니다.');
    for (final request in retryTargets) {
      await tool.markPending(request);
      stdout.writeln('retry queued: ${request.id}');
    }
  } finally {
    client.close();
  }
}

class SmsRequestTool {
  const SmsRequestTool({required this.client, required this.projectId});

  final AuthClient client;
  final String projectId;

  Future<List<SmsRequest>> fetchRecent({required int limit}) async {
    final queriedRequests = await _fetchRecentByCreatedAt(limit: limit);
    if (queriedRequests.isNotEmpty) {
      return queriedRequests;
    }
    return _fetchByCollectionList(limit: limit);
  }

  Future<List<SmsRequest>> _fetchRecentByCreatedAt({required int limit}) async {
    final uri = _documentsUri(action: 'runQuery');
    final response = await client.post(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json; charset=utf-8',
      },
      body: jsonEncode({
        'structuredQuery': {
          'from': [
            {'collectionId': _smsCollectionId},
          ],
          'orderBy': [
            {
              'field': {'fieldPath': 'createdAt'},
              'direction': 'DESCENDING',
            },
          ],
          'limit': limit,
        },
      }),
    );
    _ensureSuccess(response.statusCode, response.body, 'runQuery');

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      return const [];
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map((row) => row['document'])
        .whereType<Map<String, dynamic>>()
        .map(SmsRequest.fromFirestoreDocument)
        .toList();
  }

  Future<List<SmsRequest>> _fetchByCollectionList({required int limit}) async {
    final response = await client.get(
      _documentsUri(
        relativePath: _smsCollectionId,
        queryParameters: {'pageSize': '$limit'},
      ),
      headers: {'Accept': 'application/json'},
    );
    _ensureSuccess(response.statusCode, response.body, 'list smsRequests');

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
        .map(SmsRequest.fromFirestoreDocument)
        .toList();
  }

  Future<void> markPending(SmsRequest request) async {
    final uri = _documentsUri(relativePath: request.path).replace(
      query: [
        'updateMask.fieldPaths=status',
        'updateMask.fieldPaths=error',
        'updateMask.fieldPaths=retryRequestedAt',
      ].join('&'),
    );
    final response = await client.patch(
      uri,
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode({
        'fields': {
          'status': {'stringValue': 'pending'},
          'error': {'nullValue': null},
          'retryRequestedAt': {
            'timestampValue': DateTime.now().toUtc().toIso8601String(),
          },
        },
      }),
    );
    _ensureSuccess(response.statusCode, response.body, 'retry ${request.id}');
  }

  Uri _documentsUri({
    String relativePath = '',
    String? action,
    Map<String, String>? queryParameters,
  }) {
    final normalizedRelativePath = relativePath
        .split('/')
        .where((segment) => segment.trim().isNotEmpty)
        .join('/');
    final path =
        '/v1/projects/$projectId/databases/$_databaseId/documents'
        '${normalizedRelativePath.isEmpty ? '' : '/$normalizedRelativePath'}'
        '${action == null ? '' : ':$action'}';

    return Uri.https('firestore.googleapis.com', path, queryParameters);
  }

  void _ensureSuccess(int statusCode, String body, String operation) {
    if (statusCode >= 200 && statusCode < 300) return;
    throw HttpException('$operation failed with HTTP $statusCode: $body');
  }
}

class SmsRequest {
  const SmsRequest({
    required this.path,
    required this.id,
    required this.status,
    required this.receiver,
    required this.error,
    required this.createdAt,
    required this.updatedAt,
  });

  final String path;
  final String id;
  final String status;
  final String receiver;
  final String error;
  final String createdAt;
  final String updatedAt;

  factory SmsRequest.fromFirestoreDocument(Map<String, dynamic> document) {
    final name = _asString(document['name']) ?? '';
    final fields = document['fields'] as Map<String, dynamic>? ?? {};
    final decoded = fields.map((key, value) {
      return MapEntry(key, _decodeFirestoreValue(value));
    });
    return SmsRequest(
      path: _relativeDocumentPath(name),
      id: name.split('/').last,
      status: _asString(decoded['status']) ?? '-',
      receiver: _asString(decoded['receiver']) ?? '',
      error: _asString(decoded['error']) ?? '',
      createdAt: _asString(decoded['createdAt']) ?? '',
      updatedAt: _asString(decoded['updatedAt']) ?? '',
    );
  }

  void printSummary() {
    stdout.writeln('id: $id');
    stdout.writeln('  status: $status');
    stdout.writeln('  receiver: ${_maskPhone(receiver)}');
    if (error.isNotEmpty) {
      stdout.writeln('  error: $error');
    }
    if (createdAt.isNotEmpty) {
      stdout.writeln('  createdAt: $createdAt');
    }
    if (updatedAt.isNotEmpty) {
      stdout.writeln('  updatedAt: $updatedAt');
    }
    stdout.writeln('');
  }
}

class SmsRequestOptions {
  const SmsRequestOptions({
    required this.help,
    required this.retry,
    required this.confirm,
    required this.limit,
    this.projectId,
    this.serviceAccount,
  });

  final bool help;
  final bool retry;
  final bool confirm;
  final int limit;
  final String? projectId;
  final String? serviceAccount;

  static SmsRequestOptions parse(List<String> args) {
    var help = false;
    var retry = false;
    var confirm = false;
    var limit = 10;
    String? projectId;
    String? serviceAccount;

    for (var i = 0; i < args.length; i += 1) {
      final arg = args[i];
      switch (arg) {
        case '--help':
        case '-h':
          help = true;
          break;
        case '--retry':
          retry = true;
          break;
        case '--confirm':
        case '--yes':
          confirm = true;
          break;
        case '--limit':
          limit = math.min(
            math.max(int.tryParse(_readValue(args, ++i, arg)) ?? 10, 1),
            100,
          );
          break;
        case '--project':
          projectId = _readValue(args, ++i, arg);
          break;
        case '--service-account':
          serviceAccount = _readValue(args, ++i, arg);
          break;
        default:
          throw FormatException('알 수 없는 옵션입니다: $arg');
      }
    }

    return SmsRequestOptions(
      help: help,
      retry: retry,
      confirm: confirm,
      limit: limit,
      projectId: projectId,
      serviceAccount: serviceAccount,
    );
  }

  static String _readValue(List<String> args, int index, String optionName) {
    if (index >= args.length) {
      throw FormatException('$optionName 값이 필요합니다.');
    }
    return args[index];
  }
}

String? _resolveServiceAccountPath(String? explicitPath) {
  final envPath = Platform.environment['GOOGLE_APPLICATION_CREDENTIALS'];
  final selectedPath = explicitPath ?? envPath;
  if (selectedPath != null &&
      selectedPath.trim().isNotEmpty &&
      File(selectedPath.trim()).existsSync()) {
    return selectedPath.trim();
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
  if (value.containsKey('arrayValue')) {
    final values = value['arrayValue']?['values'];
    if (values is! List) return const <dynamic>[];
    return values.map(_decodeFirestoreValue).toList();
  }
  return null;
}

String _relativeDocumentPath(String documentName) {
  const marker = '/documents/';
  final index = documentName.indexOf(marker);
  if (index == -1) return documentName;
  return documentName.substring(index + marker.length);
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

void _printUsage() {
  stdout.writeln('Usage: dart run tool/sms_requests.dart [options]');
  stdout.writeln('');
  stdout.writeln('Options:');
  stdout.writeln('  --limit <1-100>           조회할 최근 요청 수');
  stdout.writeln(
    '  --retry --confirm         failed/skipped 요청을 pending으로 재시도',
  );
  stdout.writeln('  --project <id>            Firebase project id');
  stdout.writeln('  --service-account <path>  서비스 계정 JSON 파일 경로');
}
