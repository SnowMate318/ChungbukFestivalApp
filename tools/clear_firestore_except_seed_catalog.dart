import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

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

const _preservedCollectionIds = <String>{
  'seedCategories',
  'seeds',
  'uniqueCategoryNames',
  'uniqueSeedNames',
};

Future<void> main(List<String> args) async {
  late final ClearOptions options;
  try {
    options = ClearOptions.parse(args);
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

  if (!options.confirm) {
    _printDryRun();
    return;
  }

  final serviceAccountPath = _resolveServiceAccountPath(options);
  if (serviceAccountPath == null || serviceAccountPath.trim().isEmpty) {
    stderr.writeln('A service account JSON file is required.');
    stderr.writeln(
      'Place service-account.json in the project root or use --service-account.',
    );
    stderr.writeln(
      r'Example: dart run tools/clear_firestore_except_seed_catalog.dart --service-account C:\path\service-account.json --confirm',
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
    final clearer = FirestoreRuntimeDataClearer(
      client: client,
      projectId: projectId,
      batchSize: options.batchSize,
    );
    await clearer.clear();
  } finally {
    client.close();
  }
}

class FirestoreRuntimeDataClearer {
  const FirestoreRuntimeDataClearer({
    required this.client,
    required this.projectId,
    required this.batchSize,
  });

  final AuthClient client;
  final String projectId;
  final int batchSize;

  Future<void> clear() async {
    stdout.writeln('[clear_firestore_except_seed_catalog] project: $projectId');
    stdout.writeln(
      '[clear_firestore_except_seed_catalog] preserved: ${_preservedCollectionIds.join(', ')}',
    );

    final collectionIds = await _listCollectionIds();
    if (collectionIds.isEmpty) {
      stdout.writeln(
        '[clear_firestore_except_seed_catalog] no top-level collections found',
      );
      return;
    }

    final preserved =
        collectionIds.where(_preservedCollectionIds.contains).toList()..sort();
    final targets =
        collectionIds
            .where(
              (collectionId) => !_preservedCollectionIds.contains(collectionId),
            )
            .toList()
          ..sort();

    stdout.writeln(
      '[clear_firestore_except_seed_catalog] existing collections: ${collectionIds.join(', ')}',
    );
    stdout.writeln(
      '[clear_firestore_except_seed_catalog] keeping: ${preserved.isEmpty ? '(none present)' : preserved.join(', ')}',
    );

    if (targets.isEmpty) {
      stdout.writeln(
        '[clear_firestore_except_seed_catalog] nothing to delete outside preserved collections',
      );
      return;
    }

    stdout.writeln(
      '[clear_firestore_except_seed_catalog] deleting: ${targets.join(', ')}',
    );

    var totalDeleted = 0;
    for (final collectionId in targets) {
      final deleted = await _deleteCollection(collectionId);
      totalDeleted += deleted;
      stdout.writeln(
        '[clear_firestore_except_seed_catalog] $collectionId: $deleted docs deleted',
      );
    }

    stdout.writeln(
      '[clear_firestore_except_seed_catalog] done: $totalDeleted docs deleted',
    );
  }

  Future<int> _deleteCollection(String collectionPath) async {
    var deleted = 0;

    while (true) {
      final documentNames = await _listDocuments(collectionPath);
      if (documentNames.isEmpty) {
        return deleted;
      }

      for (final documentName in documentNames) {
        deleted += await _deleteDocumentTree(
          _relativeDocumentPath(documentName),
        );
      }
    }
  }

  Future<int> _deleteDocumentTree(String documentPath) async {
    var deleted = 0;
    final childCollectionIds = await _listCollectionIds(
      parentDocumentPath: documentPath,
    );

    for (final childCollectionId in childCollectionIds) {
      deleted += await _deleteCollection('$documentPath/$childCollectionId');
    }

    await _deleteDocument(documentPath);
    return deleted + 1;
  }

  Future<List<String>> _listCollectionIds({
    String parentDocumentPath = '',
  }) async {
    final collectionIds = <String>[];
    String? pageToken;

    do {
      final uri = _documentsUri(
        relativePath: parentDocumentPath,
        action: 'listCollectionIds',
      );
      final body = <String, Object>{
        'pageSize': batchSize,
        ...?pageToken == null ? null : {'pageToken': pageToken},
      };
      final payload = await _postJson(uri, body);
      final ids = payload['collectionIds'];
      if (ids is List) {
        collectionIds.addAll(ids.map((value) => value.toString()));
      }
      pageToken = _asString(payload['nextPageToken']);
    } while (pageToken != null);

    collectionIds.sort();
    return collectionIds;
  }

  Future<List<String>> _listDocuments(String collectionPath) async {
    final uri = _documentsUri(
      relativePath: collectionPath,
      queryParameters: {'pageSize': '$batchSize'},
    );
    final payload = await _getJson(uri);
    final documents = payload['documents'];
    if (documents is! List) {
      return const [];
    }

    return documents
        .whereType<Map>()
        .map((document) => _asString(document['name']))
        .whereType<String>()
        .toList();
  }

  Future<void> _deleteDocument(String documentPath) async {
    final response = await client.delete(
      _documentsUri(relativePath: documentPath),
    );
    if (response.statusCode == HttpStatus.notFound) {
      return;
    }
    _ensureSuccess(response.statusCode, response.body, 'DELETE $documentPath');
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final response = await client.get(
      uri,
      headers: {'Accept': 'application/json'},
    );
    _ensureSuccess(response.statusCode, response.body, 'GET $uri');
    return _decodeObject(response.body);
  }

  Future<Map<String, dynamic>> _postJson(
    Uri uri,
    Map<String, Object> body,
  ) async {
    final response = await client.post(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json; charset=utf-8',
      },
      body: jsonEncode(body),
    );
    _ensureSuccess(response.statusCode, response.body, 'POST $uri');
    return _decodeObject(response.body);
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

  String _relativeDocumentPath(String documentName) {
    const marker = '/documents/';
    final index = documentName.indexOf(marker);
    if (index == -1) {
      throw StateError('Invalid Firestore document name: $documentName');
    }
    return documentName.substring(index + marker.length);
  }

  Map<String, dynamic> _decodeObject(String body) {
    if (body.trim().isEmpty) {
      return const {};
    }
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return const {};
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

class ClearOptions {
  const ClearOptions({
    required this.confirm,
    required this.help,
    required this.batchSize,
    this.projectId,
    this.serviceAccountPath,
  });

  final bool confirm;
  final bool help;
  final int batchSize;
  final String? projectId;
  final String? serviceAccountPath;

  static ClearOptions parse(List<String> args) {
    var confirm = false;
    var help = false;
    var batchSize = 250;
    String? projectId;
    String? serviceAccountPath;

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
        case '--project':
        case '--project-id':
          projectId = _readValue(args, ++i, arg);
          break;
        case '--service-account':
          serviceAccountPath = _readValue(args, ++i, arg);
          break;
        case '--batch-size':
          final rawValue = _readValue(args, ++i, arg);
          batchSize = math.min(math.max(int.tryParse(rawValue) ?? 250, 1), 500);
          break;
        default:
          throw FormatException('Unknown option: $arg');
      }
    }

    return ClearOptions(
      confirm: confirm,
      help: help,
      batchSize: batchSize,
      projectId: projectId,
      serviceAccountPath: serviceAccountPath,
    );
  }

  static String _readValue(List<String> args, int index, String optionName) {
    if (index >= args.length) {
      throw FormatException('Missing value for $optionName');
    }
    return args[index];
  }
}

String? _resolveServiceAccountPath(ClearOptions options) {
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

void _printDryRun() {
  stdout.writeln(
    'This script deletes all Firestore top-level collections except the seed catalog collections.',
  );
  stdout.writeln('');
  stdout.writeln('Preserved collections:');
  for (final collectionId in _preservedCollectionIds) {
    stdout.writeln('  - $collectionId');
  }
  stdout.writeln('');
  stdout.writeln('Everything else will be deleted recursively.');
  stdout.writeln('');
  stdout.writeln('Add --confirm or -y to actually delete data.');
  stdout.writeln('');
  stdout.writeln('Examples:');
  stdout.writeln('  dart run tools/clear_firestore_except_seed_catalog.dart');
  stdout.writeln(
    '  dart run tools/clear_firestore_except_seed_catalog.dart --confirm',
  );
  stdout.writeln(
    r'  dart run tools/clear_firestore_except_seed_catalog.dart --service-account C:\path\service-account.json --confirm',
  );
}

void _printUsage() {
  stdout.writeln(
    'Usage: dart run tools/clear_firestore_except_seed_catalog.dart [options]',
  );
  stdout.writeln('');
  stdout.writeln('Options:');
  stdout.writeln(
    '  --confirm, -confirm, --yes, -y  Actually delete all non-catalog collections',
  );
  stdout.writeln('  --project, --project-id <id>     Firebase project id');
  stdout.writeln(
    '  --service-account <path>         Service account JSON file path',
  );
  stdout.writeln(
    '  --batch-size <1-500>             Number of docs to fetch per request',
  );
  stdout.writeln('  --help, -h                       Show this help');
}
