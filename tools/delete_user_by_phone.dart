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

Future<void> main(List<String> args) async {
  late final DeleteUserByPhoneOptions options;
  try {
    options = DeleteUserByPhoneOptions.parse(args);
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

  if (options.phoneNumber == null) {
    stderr.writeln('삭제할 전화번호가 필요합니다.');
    stderr.writeln('');
    _printUsage();
    exitCode = 64;
    return;
  }

  final normalizedPhoneNumber = _normalizePhoneNumber(options.phoneNumber!);
  if (normalizedPhoneNumber.length < 10) {
    stderr.writeln('전화번호 형식을 확인해주세요: ${options.phoneNumber}');
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
    final tool = DeleteUserByPhoneTool(
      client: client,
      projectId: projectId,
      phoneNumber: normalizedPhoneNumber,
      confirm: options.confirm,
    );
    await tool.run();
  } finally {
    client.close();
  }
}

class DeleteUserByPhoneTool {
  const DeleteUserByPhoneTool({
    required this.client,
    required this.projectId,
    required this.phoneNumber,
    required this.confirm,
  });

  final AuthClient client;
  final String projectId;
  final String phoneNumber;
  final bool confirm;

  Future<void> run() async {
    stdout.writeln('[delete_user_by_phone] project: $projectId');
    stdout.writeln('[delete_user_by_phone] phone: ${_maskPhone(phoneNumber)}');
    stdout.writeln(
      '[delete_user_by_phone] mode: ${confirm ? 'delete' : 'dry-run'}',
    );
    stdout.writeln('');

    final users = await _findUsersByPhoneNumber();
    final phoneUniqueDocs = <FirestoreDocument>{
      ...await _findUniquePhoneDocs(
        users.map((user) => user.uid).whereType<String>().toSet(),
      ),
    };
    final userUids = <String>{
      ...users.map((user) => user.uid).whereType<String>(),
      ...phoneUniqueDocs
          .map((doc) => _asString(doc.fields['uid']))
          .whereType<String>(),
    };
    final nicknameKeys = <String>{
      for (final user in users)
        if (user.nickname != null) _uniqueKey(user.nickname!),
    };

    final nicknameUniqueDocs = <FirestoreDocument>{
      ...await _findUniqueNicknameDocsByUids(userUids),
      ...await _findUniqueNicknameDocsByKeys(nicknameKeys),
    };
    final smsDocs = <FirestoreDocument>{
      ...await _queryByString('smsRequests', 'receiver', phoneNumber),
      ...await _queryByString('smsRequests', 'phoneNumber', phoneNumber),
      for (final uid in userUids)
        ...await _queryByString('smsRequests', 'uid', uid),
    };
    final highlighted = await _highlightedUserDoc(userUids);

    final deletePaths = <String>{
      for (final user in users) user.path,
      for (final doc in phoneUniqueDocs) doc.path,
      for (final doc in nicknameUniqueDocs) doc.path,
      for (final doc in smsDocs) doc.path,
      if (highlighted != null) highlighted.path,
    }.toList()..sort();

    _printPlan(
      users: users,
      phoneUniqueDocs: phoneUniqueDocs,
      nicknameUniqueDocs: nicknameUniqueDocs,
      smsDocs: smsDocs,
      highlighted: highlighted,
      deletePaths: deletePaths,
    );

    if (!confirm) {
      stdout.writeln('');
      stdout.writeln('실제로 삭제하려면 --confirm을 붙여 다시 실행하세요.');
      stdout.writeln(
        '  dart run tools/delete_user_by_phone.dart $phoneNumber --confirm',
      );
      return;
    }

    if (deletePaths.isEmpty) {
      stdout.writeln('');
      stdout.writeln('삭제할 문서가 없습니다.');
      return;
    }

    stdout.writeln('');
    stdout.writeln(
      '[delete_user_by_phone] deleting ${deletePaths.length} docs',
    );
    for (final path in deletePaths) {
      await _deleteDocument(path);
      stdout.writeln('deleted: $path');
    }
    stdout.writeln('[delete_user_by_phone] done');
  }

  Future<List<FestivalUserDoc>> _findUsersByPhoneNumber() async {
    final docs = <FirestoreDocument>{
      ...await _queryByString('festivalUsers', 'phoneNumber', phoneNumber),
      ...await _queryByString('festivalUsers', 'phone_number', phoneNumber),
    };
    return docs.map(FestivalUserDoc.fromDocument).toList()
      ..sort((a, b) => a.path.compareTo(b.path));
  }

  Future<Set<FirestoreDocument>> _findUniquePhoneDocs(
    Set<String> userUids,
  ) async {
    final docs = <FirestoreDocument>{};
    final keyDoc = await _getDocument(
      'uniquePhoneNumbers/${_uniqueKey(phoneNumber)}',
    );
    if (keyDoc != null) docs.add(keyDoc);
    docs.addAll(
      await _queryByString('uniquePhoneNumbers', 'value', phoneNumber),
    );
    for (final uid in userUids) {
      docs.addAll(await _queryByString('uniquePhoneNumbers', 'uid', uid));
    }
    return docs;
  }

  Future<Set<FirestoreDocument>> _findUniqueNicknameDocsByUids(
    Set<String> userUids,
  ) async {
    final docs = <FirestoreDocument>{};
    for (final uid in userUids) {
      docs.addAll(await _queryByString('uniqueNicknames', 'uid', uid));
    }
    return docs;
  }

  Future<Set<FirestoreDocument>> _findUniqueNicknameDocsByKeys(
    Set<String> keys,
  ) async {
    final docs = <FirestoreDocument>{};
    for (final key in keys) {
      final doc = await _getDocument('uniqueNicknames/$key');
      if (doc != null) docs.add(doc);
    }
    return docs;
  }

  Future<FirestoreDocument?> _highlightedUserDoc(Set<String> userUids) async {
    final doc = await _getDocument('settings/highlight');
    if (doc == null) return null;

    final highlightedUid = _asString(doc.fields['userUid']);
    final highlightedPhone = _normalizePhoneNumber(
      _asString(doc.fields['phoneNumber']) ?? '',
    );
    if ((highlightedUid != null && userUids.contains(highlightedUid)) ||
        highlightedPhone == phoneNumber) {
      return doc;
    }
    return null;
  }

  Future<List<FirestoreDocument>> _queryByString(
    String collectionId,
    String fieldPath,
    String value,
  ) async {
    final response = await client.post(
      _documentsUri(action: 'runQuery'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json; charset=utf-8',
      },
      body: jsonEncode({
        'structuredQuery': {
          'from': [
            {'collectionId': collectionId},
          ],
          'where': {
            'fieldFilter': {
              'field': {'fieldPath': fieldPath},
              'op': 'EQUAL',
              'value': {'stringValue': value},
            },
          },
        },
      }),
    );
    _ensureSuccess(
      response.statusCode,
      response.body,
      'query $collectionId.$fieldPath',
    );

    final decoded = jsonDecode(response.body);
    if (decoded is! List) return const [];

    return decoded
        .whereType<Map<String, dynamic>>()
        .map((row) => row['document'])
        .whereType<Map<String, dynamic>>()
        .map(FirestoreDocument.fromJson)
        .toList();
  }

  Future<FirestoreDocument?> _getDocument(String relativePath) async {
    final response = await client.get(
      _documentsUri(relativePath: relativePath),
      headers: {'Accept': 'application/json'},
    );
    if (response.statusCode == HttpStatus.notFound) {
      return null;
    }
    _ensureSuccess(response.statusCode, response.body, 'get $relativePath');
    return FirestoreDocument.fromJson(jsonDecode(response.body));
  }

  Future<void> _deleteDocument(String relativePath) async {
    final response = await client.delete(
      _documentsUri(relativePath: relativePath),
    );
    if (response.statusCode == HttpStatus.notFound) {
      return;
    }
    _ensureSuccess(response.statusCode, response.body, 'delete $relativePath');
  }

  void _printPlan({
    required List<FestivalUserDoc> users,
    required Set<FirestoreDocument> phoneUniqueDocs,
    required Set<FirestoreDocument> nicknameUniqueDocs,
    required Set<FirestoreDocument> smsDocs,
    required FirestoreDocument? highlighted,
    required List<String> deletePaths,
  }) {
    stdout.writeln('대상 사용자: ${users.length}건');
    for (final user in users) {
      stdout.writeln(
        '  - ${user.path} nickname=${user.nickname ?? '-'} phone=${_maskPhone(user.phoneNumber ?? '')} seedCount=${user.seedCount ?? 0}',
      );
    }
    stdout.writeln('전화번호 중복 방지 문서: ${phoneUniqueDocs.length}건');
    for (final doc in phoneUniqueDocs) {
      stdout.writeln('  - ${doc.path}');
    }
    stdout.writeln('닉네임 중복 방지 문서: ${nicknameUniqueDocs.length}건');
    for (final doc in nicknameUniqueDocs) {
      stdout.writeln('  - ${doc.path}');
    }
    stdout.writeln('SMS 요청 문서: ${smsDocs.length}건');
    for (final doc in smsDocs) {
      stdout.writeln('  - ${doc.path}');
    }
    stdout.writeln('display live 강조 설정: ${highlighted == null ? 0 : 1}건');
    if (highlighted != null) {
      stdout.writeln('  - ${highlighted.path}');
    }
    stdout.writeln('');
    stdout.writeln('삭제 예정 문서: ${deletePaths.length}건');
    for (final path in deletePaths) {
      stdout.writeln('  - $path');
    }
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
    if (statusCode >= 200 && statusCode < 300) {
      return;
    }
    throw HttpException(
      '$operation failed with HTTP $statusCode${body.isEmpty ? '' : ': $body'}',
    );
  }
}

class FestivalUserDoc {
  const FestivalUserDoc({
    required this.path,
    required this.fields,
    this.uid,
    this.nickname,
    this.phoneNumber,
    this.seedCount,
  });

  final String path;
  final Map<String, dynamic> fields;
  final String? uid;
  final String? nickname;
  final String? phoneNumber;
  final int? seedCount;

  factory FestivalUserDoc.fromDocument(FirestoreDocument doc) {
    return FestivalUserDoc(
      path: doc.path,
      fields: doc.fields,
      uid: _asString(doc.fields['uid']) ?? doc.path.split('/').last,
      nickname: _asString(doc.fields['nickname']),
      phoneNumber: _asString(
        doc.fields['phoneNumber'] ?? doc.fields['phone_number'],
      ),
      seedCount: _asInt(doc.fields['seedCount'] ?? doc.fields['seed_count']),
    );
  }
}

class FirestoreDocument {
  const FirestoreDocument({
    required this.name,
    required this.path,
    required this.fields,
  });

  final String name;
  final String path;
  final Map<String, dynamic> fields;

  factory FirestoreDocument.fromJson(Map<String, dynamic> json) {
    final name = _asString(json['name']) ?? '';
    final rawFields = json['fields'];
    final fields = rawFields is Map<String, dynamic>
        ? rawFields.map(
            (key, value) => MapEntry(key, _decodeFirestoreValue(value)),
          )
        : const <String, dynamic>{};
    return FirestoreDocument(
      name: name,
      path: _relativeDocumentPath(name),
      fields: fields,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FirestoreDocument &&
          runtimeType == other.runtimeType &&
          path == other.path;

  @override
  int get hashCode => path.hashCode;
}

class DeleteUserByPhoneOptions {
  const DeleteUserByPhoneOptions({
    required this.confirm,
    required this.help,
    this.phoneNumber,
    this.projectId,
    this.serviceAccount,
  });

  final bool confirm;
  final bool help;
  final String? phoneNumber;
  final String? projectId;
  final String? serviceAccount;

  static DeleteUserByPhoneOptions parse(List<String> args) {
    var confirm = false;
    var help = false;
    String? phoneNumber;
    String? projectId;
    String? serviceAccount;

    for (var i = 0; i < args.length; i += 1) {
      final arg = args[i];
      switch (arg) {
        case '--confirm':
        case '-confirm':
        case '--yes':
        case '-y':
          confirm = true;
          break;
        case '--help':
        case '-h':
          help = true;
          break;
        case '--phone':
        case '--phone-number':
          phoneNumber = _readValue(args, ++i, arg);
          break;
        case '--project':
        case '--project-id':
          projectId = _readValue(args, ++i, arg);
          break;
        case '--service-account':
          serviceAccount = _readValue(args, ++i, arg);
          break;
        default:
          if (arg.startsWith('-')) {
            throw FormatException('Unknown option: $arg');
          }
          if (phoneNumber != null) {
            throw FormatException('Unexpected extra argument: $arg');
          }
          phoneNumber = arg;
      }
    }

    return DeleteUserByPhoneOptions(
      confirm: confirm,
      help: help,
      phoneNumber: phoneNumber,
      projectId: projectId,
      serviceAccount: serviceAccount,
    );
  }

  static String _readValue(List<String> args, int index, String optionName) {
    if (index >= args.length) {
      throw FormatException('Missing value for $optionName');
    }
    return args[index];
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

String? _resolveServiceAccountPath(String? explicitPath) {
  final resolvedExplicitPath =
      explicitPath ?? Platform.environment['GOOGLE_APPLICATION_CREDENTIALS'];
  if (resolvedExplicitPath != null && resolvedExplicitPath.trim().isNotEmpty) {
    return resolvedExplicitPath.trim();
  }

  for (final candidate in _serviceAccountFileCandidates) {
    if (File(candidate).existsSync()) {
      return candidate;
    }
  }

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

  return files.isEmpty ? null : files.first;
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

String _relativeDocumentPath(String documentName) {
  const marker = '/documents/';
  final index = documentName.indexOf(marker);
  if (index == -1) {
    throw StateError('Invalid Firestore document name: $documentName');
  }
  return documentName.substring(index + marker.length);
}

String _normalizePhoneNumber(String phoneNumber) {
  return phoneNumber.replaceAll(RegExp(r'\D'), '');
}

String _uniqueKey(String value) {
  return base64Url
      .encode(utf8.encode(value.trim().toLowerCase()))
      .replaceAll('=', '');
}

String _maskPhone(String phone) {
  final digits = _normalizePhoneNumber(phone);
  if (digits.length < 7) return phone.isEmpty ? '-' : phone;
  return '${digits.substring(0, 3)}****${digits.substring(digits.length - 4)}';
}

String? _asString(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

void _printUsage() {
  stdout.writeln(
    'Usage: dart run tools/delete_user_by_phone.dart <phone> [options]',
  );
  stdout.writeln('');
  stdout.writeln('Examples:');
  stdout.writeln('  dart run tools/delete_user_by_phone.dart 010-1234-5678');
  stdout.writeln(
    '  dart run tools/delete_user_by_phone.dart 010-1234-5678 --confirm',
  );
  stdout.writeln(
    r'  dart run tools/delete_user_by_phone.dart --phone 01012345678 --service-account C:\path\service-account.json --confirm',
  );
  stdout.writeln('');
  stdout.writeln('Options:');
  stdout.writeln(
    '  --confirm, --yes, -y           Actually delete matching documents',
  );
  stdout.writeln('  --phone, --phone-number <num>  Phone number to delete');
  stdout.writeln('  --project, --project-id <id>   Firebase project id');
  stdout.writeln(
    '  --service-account <path>       Service account JSON file path',
  );
  stdout.writeln('  --help, -h                     Show this help');
}
