import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:greenfestival/data/models/festival_admin_models.dart';

class FestivalAdminException implements Exception {
  const FestivalAdminException(this.message);

  final String message;

  @override
  String toString() => message;
}

class FestivalFirestoreService {
  FestivalFirestoreService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('festivalUsers');

  CollectionReference<Map<String, dynamic>> get _seedCategories =>
      _db.collection('seedCategories');

  CollectionReference<Map<String, dynamic>> get _seeds =>
      _db.collection('seeds');

  CollectionReference<Map<String, dynamic>> get _smsRequests =>
      _db.collection('smsRequests');

  CollectionReference<Map<String, dynamic>> get _uniqueNicknames =>
      _db.collection('uniqueNicknames');

  CollectionReference<Map<String, dynamic>> get _uniquePhoneNumbers =>
      _db.collection('uniquePhoneNumbers');

  CollectionReference<Map<String, dynamic>> get _uniqueSeedNames =>
      _db.collection('uniqueSeedNames');

  CollectionReference<Map<String, dynamic>> get _uniqueCategoryNames =>
      _db.collection('uniqueCategoryNames');

  DocumentReference<Map<String, dynamic>> get _highlightSettings =>
      _db.collection('settings').doc('highlight');

  DocumentReference<Map<String, dynamic>> get _summaryMetrics =>
      _db.collection('metrics').doc('summary');

  Stream<List<FestivalUser>> watchUsers() {
    final controller = StreamController<List<FestivalUser>>();
    QuerySnapshot<Map<String, dynamic>>? latestUsers;
    String? highlightedUid;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? usersSub;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? highlightSub;

    void emit() {
      final snapshot = latestUsers;
      if (snapshot == null || controller.isClosed) return;

      final users =
          snapshot.docs
              .map(
                (doc) => FestivalUser.fromSnapshot(
                  doc,
                  highlightedUid: highlightedUid,
                ),
              )
              .toList()
            ..sort(_compareUsersForAdmin);
      controller.add(users);
    }

    controller.onListen = () {
      usersSub = _users.snapshots().listen((snapshot) {
        latestUsers = snapshot;
        emit();
      }, onError: controller.addError);

      highlightSub = _highlightSettings.snapshots().listen((snapshot) {
        highlightedUid = _asString(snapshot.data()?['userUid']);
        emit();
      }, onError: controller.addError);
    };

    controller.onCancel = () async {
      await usersSub?.cancel();
      await highlightSub?.cancel();
    };

    return controller.stream;
  }

  Stream<List<FestivalUser>> watchSubmittedUsers() {
    return watchUsers().map(
      (users) =>
          users.where((user) => user.lastSubmittedAt != null).take(20).toList(),
    );
  }

  Stream<int> watchTotalSeedCount() {
    return _users.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => FestivalUser.fromSnapshot(doc).seedCount)
          .fold<int>(0, (total, value) => total + value);
    });
  }

  Stream<HighlightedUser?> watchHighlightedUser() {
    final controller = StreamController<HighlightedUser?>();
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? settingsSub;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? userSub;

    controller.onListen = () {
      settingsSub = _highlightSettings.snapshots().listen((snapshot) {
        final userUid = _asString(snapshot.data()?['userUid']);
        final previousUserSub = userSub;
        userSub = null;
        unawaited(previousUserSub?.cancel() ?? Future<void>.value());

        if (userUid.isEmpty) {
          controller.add(null);
          return;
        }

        userSub = _users.doc(userUid).snapshots().listen((userSnapshot) {
          if (!userSnapshot.exists) {
            controller.add(null);
            return;
          }

          final user = FestivalUser.fromSnapshot(userSnapshot);
          controller.add(
            HighlightedUser(nickname: user.nickname, seedCount: user.seedCount),
          );
        }, onError: controller.addError);
      }, onError: controller.addError);
    };

    controller.onCancel = () async {
      await settingsSub?.cancel();
      await userSub?.cancel();
    };

    return controller.stream;
  }

  Stream<SeedCatalog> watchSeedCatalog() {
    final controller = StreamController<SeedCatalog>();
    List<SeedCategory>? latestCategories;
    List<SeedItem>? latestSeeds;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? categorySub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? seedSub;

    void emit() {
      final categories = latestCategories;
      final seeds = latestSeeds;
      if (categories == null || seeds == null || controller.isClosed) return;

      controller.add(SeedCatalog(categories: categories, seeds: seeds));
    }

    controller.onListen = () {
      categorySub = _seedCategories.snapshots().listen((snapshot) {
        latestCategories = snapshot.docs.map(SeedCategory.fromSnapshot).toList()
          ..sort((a, b) => a.name.compareTo(b.name));
        emit();
      }, onError: controller.addError);

      seedSub = _seeds.snapshots().listen((snapshot) {
        latestSeeds = snapshot.docs.map(SeedItem.fromSnapshot).toList()
          ..sort((a, b) {
            final categoryCompare = a.categoryName.compareTo(b.categoryName);
            if (categoryCompare != 0) return categoryCompare;
            return a.name.compareTo(b.name);
          });
        emit();
      }, onError: controller.addError);
    };

    controller.onCancel = () async {
      await categorySub?.cancel();
      await seedSub?.cancel();
    };

    return controller.stream;
  }

  Stream<FestivalUser?> watchUser(String uid) {
    return _users.doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return FestivalUser.fromSnapshot(snapshot);
    });
  }

  Future<bool> isNicknameDuplicated(String nickname) async {
    final trimmed = nickname.trim();
    if (trimmed.isEmpty) return false;
    final snapshot = await _uniqueNicknames.doc(_uniqueKey(trimmed)).get();
    return snapshot.exists;
  }

  Future<bool> isPhoneNumberDuplicated(String phoneNumber) async {
    final normalized = normalizePhoneNumber(phoneNumber);
    if (normalized.isEmpty) return false;
    final snapshot = await _uniquePhoneNumbers
        .doc(_uniqueKey(normalized))
        .get();
    return snapshot.exists;
  }

  Future<String> createUser({
    required String nickname,
    required int gender,
    required int ageGroup,
    required int participantCount,
    required int residence,
    required String phoneNumber,
    String source = 'admin',
    Map<String, dynamic>? rawPayload,
  }) async {
    final normalizedNickname = nickname.trim();
    final normalizedPhoneNumber = normalizePhoneNumber(phoneNumber);

    _validateUserInput(
      nickname: normalizedNickname,
      phoneNumber: normalizedPhoneNumber,
      participantCount: participantCount,
    );

    if (!_isKnownOption(festivalGenderOptions, gender)) {
      throw const FestivalAdminException('성별 값을 다시 확인해 주세요.');
    }
    if (!_isKnownOption(festivalAgeOptions, ageGroup)) {
      throw const FestivalAdminException('연령 값을 다시 확인해 주세요.');
    }
    if (!_isKnownOption(festivalResidenceOptions, residence)) {
      throw const FestivalAdminException('거주 정보를 다시 확인해 주세요.');
    }

    final userRef = _users.doc();
    final userUid = userRef.id;
    final nicknameUniqueRef = _uniqueNicknames.doc(
      _uniqueKey(normalizedNickname),
    );
    final phoneUniqueRef = _uniquePhoneNumbers.doc(
      _uniqueKey(normalizedPhoneNumber),
    );
    final smsRef = _smsRequests.doc();
    final serverNow = FieldValue.serverTimestamp();

    return _db.runTransaction<String>((transaction) async {
      final nicknameSnapshot = await transaction.get(nicknameUniqueRef);
      if (nicknameSnapshot.exists) {
        throw const FestivalAdminException('이미 사용 중인 닉네임입니다.');
      }

      final phoneSnapshot = await transaction.get(phoneUniqueRef);
      if (phoneSnapshot.exists) {
        throw const FestivalAdminException('이미 등록된 휴대폰 번호입니다.');
      }

      transaction.set(userRef, {
        'uid': userUid,
        'nickname': normalizedNickname,
        'nicknameKey': normalizedNickname.toLowerCase(),
        'gender': gender,
        'genderLabel': genderLabelByCode(gender),
        'ageGroup': ageGroup,
        'ageGroupLabel': ageLabelByCode(ageGroup),
        'participantCount': participantCount,
        'residence': residence,
        'residenceLabel': residenceLabelByCode(residence),
        'phoneNumber': normalizedPhoneNumber,
        'seedCount': 0,
        'seedCounts': <String, int>{},
        'lastSubmittedAt': null,
        'source': source,
        'rawPayload': rawPayload,
        'createdAt': serverNow,
        'updatedAt': serverNow,
      });

      transaction.set(nicknameUniqueRef, {
        'uid': userUid,
        'value': normalizedNickname,
        'createdAt': serverNow,
      });
      transaction.set(phoneUniqueRef, {
        'uid': userUid,
        'value': normalizedPhoneNumber,
        'createdAt': serverNow,
      });

      _queueWelcomeSmsInTransaction(
        transaction,
        smsRef,
        uid: userUid,
        nickname: normalizedNickname,
        phoneNumber: normalizedPhoneNumber,
        serverNow: serverNow,
      );

      return userUid;
    });
  }

  Future<String> createUserFromSurveyPayload(Map<String, dynamic> payload) {
    return createUser(
      nickname: _asString(payload['nickname']),
      gender: _genderCodeFromValue(payload['gender']),
      ageGroup: _ageGroupCodeFromValue(payload['age']),
      participantCount: _participantCountFromValue(payload['participantCount']),
      residence: _residenceCodeFromValue(payload['residence']),
      phoneNumber: _asString(payload['phoneNumber']),
      source: 'kiosk',
      rawPayload: payload,
    );
  }

  Future<FestivalUser> findUserByPhoneNumber(String phoneNumber) async {
    final normalizedPhoneNumber = normalizePhoneNumber(phoneNumber);
    final snapshot = await _users
        .where('phoneNumber', isEqualTo: normalizedPhoneNumber)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      throw const FestivalAdminException('등록된 참여자를 찾을 수 없습니다.');
    }

    return FestivalUser.fromSnapshot(snapshot.docs.first);
  }

  Future<void> updateHighlightedUserByPhoneNumber(String phoneNumber) async {
    final user = await findUserByPhoneNumber(phoneNumber);
    await _highlightSettings.set({
      'userUid': user.uid,
      'phoneNumber': user.phoneNumber,
      'nickname': user.nickname,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> createSeed({
    required String seedName,
    int seedValue = 1,
    String? categoryUid,
    String? newCategoryName,
  }) async {
    final normalizedSeedName = seedName.trim();
    final resolvedSeedValue = normalizedSeedValue(seedValue);
    final normalizedCategoryUid = categoryUid?.trim() ?? '';
    final normalizedNewCategoryName = newCategoryName?.trim() ?? '';

    if (normalizedSeedName.isEmpty) {
      throw const FestivalAdminException('부스 이름을 입력해 주세요.');
    }
    if (normalizedSeedName.length > 100) {
      throw const FestivalAdminException('부스 이름은 100자 이하로 입력해 주세요.');
    }
    if (normalizedCategoryUid.isEmpty == normalizedNewCategoryName.isEmpty) {
      throw const FestivalAdminException(
        '기존 카테고리 선택 또는 새 카테고리 입력 중 하나만 사용해 주세요.',
      );
    }

    final seedRef = _seeds.doc();
    final seedUniqueRef = _uniqueSeedNames.doc(_uniqueKey(normalizedSeedName));
    final serverNow = FieldValue.serverTimestamp();

    await _db.runTransaction<void>((transaction) async {
      final seedSnapshot = await transaction.get(seedUniqueRef);
      if (seedSnapshot.exists) {
        throw const FestivalAdminException('이미 등록된 부스 이름입니다.');
      }

      late final DocumentReference<Map<String, dynamic>> categoryRef;
      late final String resolvedCategoryUid;
      late final String resolvedCategoryName;

      if (normalizedNewCategoryName.isNotEmpty) {
        if (normalizedNewCategoryName.length > 100) {
          throw const FestivalAdminException('카테고리 이름은 100자 이하로 입력해 주세요.');
        }

        final categoryUniqueRef = _uniqueCategoryNames.doc(
          _uniqueKey(normalizedNewCategoryName),
        );
        final categorySnapshot = await transaction.get(categoryUniqueRef);
        if (categorySnapshot.exists) {
          throw const FestivalAdminException('이미 등록된 카테고리입니다.');
        }

        categoryRef = _seedCategories.doc();
        resolvedCategoryUid = categoryRef.id;
        resolvedCategoryName = normalizedNewCategoryName;

        transaction.set(categoryRef, {
          'uid': resolvedCategoryUid,
          'name': resolvedCategoryName,
          'createdAt': serverNow,
          'updatedAt': serverNow,
        });
        transaction.set(categoryUniqueRef, {
          'uid': resolvedCategoryUid,
          'value': resolvedCategoryName,
          'createdAt': serverNow,
        });
      } else {
        categoryRef = _seedCategories.doc(normalizedCategoryUid);
        final categorySnapshot = await transaction.get(categoryRef);
        if (!categorySnapshot.exists) {
          throw const FestivalAdminException('선택한 카테고리를 찾을 수 없습니다.');
        }

        final category = SeedCategory.fromSnapshot(categorySnapshot);
        resolvedCategoryUid = category.uid;
        resolvedCategoryName = category.name;
      }

      transaction.set(seedRef, {
        'uid': seedRef.id,
        'name': normalizedSeedName,
        'categoryUid': resolvedCategoryUid,
        'categoryName': resolvedCategoryName,
        'seedValue': resolvedSeedValue,
        'createdAt': serverNow,
        'updatedAt': serverNow,
      });
      transaction.set(seedUniqueRef, {
        'uid': seedRef.id,
        'value': normalizedSeedName,
        'categoryUid': resolvedCategoryUid,
        'createdAt': serverNow,
      });
    });
  }

  Future<void> createSeedWithCategoryDescriptions({
    required String seedName,
    int seedValue = 1,
    String? categoryUid,
    String? newCategoryName,
    List<String>? newCategoryDescriptions,
  }) async {
    await createSeed(
      seedName: seedName,
      seedValue: seedValue,
      categoryUid: categoryUid,
      newCategoryName: newCategoryName,
    );
  }

  Future<void> deleteSeed(String seedUid) async {
    final normalizedSeedUid = seedUid.trim();
    if (normalizedSeedUid.isEmpty) {
      throw const FestivalAdminException('삭제할 부스를 찾을 수 없습니다.');
    }

    final seedSnapshot = await _seeds.doc(normalizedSeedUid).get();
    if (!seedSnapshot.exists) {
      throw const FestivalAdminException('삭제할 부스를 찾을 수 없습니다.');
    }

    final seed = SeedItem.fromSnapshot(seedSnapshot);
    final usersSnapshot = await _users.get();
    var removedTotal = 0;

    for (final userSnapshot in usersSnapshot.docs) {
      final user = FestivalUser.fromSnapshot(userSnapshot);
      final removedCount = user.seedCounts[seed.uid] ?? 0;
      if (removedCount <= 0) continue;

      final nextSeedCounts = Map<String, int>.from(user.seedCounts)
        ..remove(seed.uid);
      final nextTotal = user.seedCount - (removedCount * seed.seedValue);

      await userSnapshot.reference.update({
        'seedCounts': nextSeedCounts,
        'seedCount': nextTotal < 0 ? 0 : nextTotal,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      removedTotal += removedCount * seed.seedValue;
    }

    await _seeds.doc(seed.uid).delete();
    await _uniqueSeedNames.doc(_uniqueKey(seed.name)).delete();
    await _summaryMetrics.set({
      'totalSeedCount': FieldValue.increment(-removedTotal),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteCategory(String categoryUid) async {
    final normalizedCategoryUid = categoryUid.trim();
    if (normalizedCategoryUid.isEmpty) {
      throw const FestivalAdminException('삭제할 카테고리를 찾을 수 없습니다.');
    }

    final categorySnapshot = await _seedCategories
        .doc(normalizedCategoryUid)
        .get();
    if (!categorySnapshot.exists) {
      throw const FestivalAdminException('삭제할 카테고리를 찾을 수 없습니다.');
    }

    final category = SeedCategory.fromSnapshot(categorySnapshot);
    final seedsSnapshot = await _seeds
        .where('categoryUid', isEqualTo: category.uid)
        .get();
    final seeds = seedsSnapshot.docs.map(SeedItem.fromSnapshot).toList();
    final usersSnapshot = await _users.get();
    var removedTotal = 0;

    for (final userSnapshot in usersSnapshot.docs) {
      final user = FestivalUser.fromSnapshot(userSnapshot);
      final nextSeedCounts = Map<String, int>.from(user.seedCounts);
      var changed = false;
      var userRemoved = 0;

      for (final seed in seeds) {
        final removedCount = nextSeedCounts.remove(seed.uid) ?? 0;
        if (removedCount > 0) {
          changed = true;
          userRemoved += removedCount * seed.seedValue;
        }
      }

      if (!changed) continue;

      final nextTotal = user.seedCount - userRemoved;
      await userSnapshot.reference.update({
        'seedCounts': nextSeedCounts,
        'seedCount': nextTotal < 0 ? 0 : nextTotal,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      removedTotal += userRemoved;
    }

    for (final seed in seeds) {
      await _seeds.doc(seed.uid).delete();
      await _uniqueSeedNames.doc(_uniqueKey(seed.name)).delete();
    }

    await _seedCategories.doc(category.uid).delete();
    await _uniqueCategoryNames.doc(_uniqueKey(category.name)).delete();
    await _summaryMetrics.set({
      'totalSeedCount': FieldValue.increment(-removedTotal),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateUserSeedCounts({
    required String uid,
    required Map<String, int> seedCounts,
  }) async {
    final userRef = _users.doc(uid);
    final seedValueByUid = await _loadSeedValueByUid();
    final normalizedSeedCounts = <String, int>{};

    for (final entry in seedCounts.entries) {
      final count = entry.value < 0 ? 0 : entry.value;
      if (count > 0) {
        normalizedSeedCounts[entry.key] = count;
      }
    }

    await _db.runTransaction<void>((transaction) async {
      final userSnapshot = await transaction.get(userRef);
      if (!userSnapshot.exists) {
        throw const FestivalAdminException('등록된 참여자를 찾을 수 없습니다.');
      }

      final user = FestivalUser.fromSnapshot(userSnapshot);
      final participantLimit = user.participantCount < 1
          ? 1
          : user.participantCount;
      final boundedSeedCounts = <String, int>{};
      for (final entry in normalizedSeedCounts.entries) {
        final boundedCount = entry.value > participantLimit
            ? participantLimit
            : entry.value;
        if (boundedCount > 0) {
          boundedSeedCounts[entry.key] = boundedCount;
        }
      }
      final serverNow = FieldValue.serverTimestamp();
      final nextTotal = seedTotalFromSeedValues(
        boundedSeedCounts,
        seedValueByUid,
      );
      final diff = nextTotal - user.seedCount;

      if (_mapEquals(user.seedCounts, boundedSeedCounts)) {
        transaction.update(userRef, {
          'lastSubmittedAt': serverNow,
          'updatedAt': serverNow,
        });
        return;
      }

      transaction.update(userRef, {
        'seedCounts': boundedSeedCounts,
        'seedCount': nextTotal,
        'lastSubmittedAt': serverNow,
        'updatedAt': serverNow,
      });

      transaction.set(_summaryMetrics, {
        'totalSeedCount': FieldValue.increment(diff),
        'updatedAt': serverNow,
      }, SetOptions(merge: true));
    });
  }

  Future<Map<String, int>> _loadSeedValueByUid() async {
    final snapshot = await _seeds.get();
    return <String, int>{
      for (final doc in snapshot.docs)
        doc.id: normalizedSeedValue(
          int.tryParse(
            '${doc.data()['seedValue'] ?? doc.data()['seed_value'] ?? 1}',
          ),
        ),
    };
  }

  String normalizePhoneNumber(String phoneNumber) {
    return phoneNumber.replaceAll(RegExp(r'\D'), '');
  }

  bool isValidPhoneNumber(String phoneNumber) {
    return RegExp(r'^01\d{8,9}$').hasMatch(normalizePhoneNumber(phoneNumber));
  }

  void _queueWelcomeSmsInTransaction(
    Transaction transaction,
    DocumentReference<Map<String, dynamic>> smsRef, {
    required String uid,
    required String nickname,
    required String phoneNumber,
    required FieldValue serverNow,
  }) {
    transaction.set(smsRef, {
      'uid': uid,
      'nickname': nickname,
      'receiver': phoneNumber,
      'status': 'pending',
      'createdAt': serverNow,
      'updatedAt': serverNow,
    });
  }

  void _validateUserInput({
    required String nickname,
    required String phoneNumber,
    required int participantCount,
  }) {
    if (nickname.isEmpty || nickname.length > 20) {
      throw const FestivalAdminException('닉네임은 1자 이상 20자 이하로 입력해 주세요.');
    }
    if (!isValidPhoneNumber(phoneNumber)) {
      throw const FestivalAdminException('휴대폰 번호 형식이 올바르지 않습니다.');
    }
    if (participantCount < 1 || participantCount > 99) {
      throw const FestivalAdminException('참여 인원은 1명 이상 99명 이하로 입력해 주세요.');
    }
  }

  bool _isKnownOption(List<FestivalSelectOption> options, int value) {
    return options.any((option) => option.value == value);
  }

  String _uniqueKey(String value) {
    return base64Url
        .encode(utf8.encode(value.trim().toLowerCase()))
        .replaceAll('=', '');
  }

  int _genderCodeFromValue(Object? value) {
    final intValue = _intFromValue(value);
    if (intValue == 1 || intValue == 2) return intValue;

    final text = _asString(value).toLowerCase();
    if (<String>[
      '2',
      'f',
      'female',
      'woman',
      'women',
      '여',
      '여성',
    ].contains(text)) {
      return 2;
    }
    if (<String>['1', 'm', 'male', 'man', 'men', '남', '남성'].contains(text)) {
      return 1;
    }

    throw const FestivalAdminException('성별 값을 알 수 없습니다.');
  }

  int _ageGroupCodeFromValue(Object? value) {
    final intValue = _intFromValue(value);
    if (intValue >= 1 && intValue <= 8) return intValue;

    final text = _asString(value);
    if (text.contains('0~12')) return 1;
    if (text.contains('13')) return 2;
    if (text.contains('20')) return 3;
    if (text.contains('30')) return 4;
    if (text.contains('40')) return 5;
    if (text.contains('50')) return 6;
    if (text.contains('70') || text.contains('이상') || text.contains('고령')) {
      return 8;
    }
    if (text.contains('60')) return 7;

    throw const FestivalAdminException('연령 값을 확인할 수 없습니다.');
  }

  int _residenceCodeFromValue(Object? value) {
    final intValue = _intFromValue(value);
    if (intValue >= 1 && intValue <= 6) return intValue;

    final text = _asString(value).toLowerCase();
    if (text.contains('상당')) return 1;
    if (text.contains('서원')) return 2;
    if (text.contains('청원')) return 3;
    if (text.contains('흥덕')) return 4;
    if (text.contains('청주') || text.contains('cheongju')) return 1;
    if (text.contains('충북') ||
        text.contains('세종') ||
        text.contains('대전') ||
        text.contains('외 지역') ||
        text.contains('기타') ||
        text.contains('other')) {
      return 5;
    }
    if (text.contains('해외') ||
        text.contains('외국') ||
        text.contains('foreign')) {
      return 6;
    }
    if (text.isNotEmpty) return 5;

    throw const FestivalAdminException('거주 정보를 알 수 없습니다.');
  }

  int _participantCountFromValue(Object? value) {
    final intValue = _intFromValue(value);
    if (intValue > 0) return intValue;

    final digits = RegExp(r'\d+').firstMatch(_asString(value))?.group(0);
    final parsed = int.tryParse(digits ?? '');
    if (parsed != null && parsed > 0) return parsed;

    return 1;
  }

  int _intFromValue(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  String _asString(Object? value) {
    return value?.toString().trim() ?? '';
  }

  int _compareUsersForAdmin(FestivalUser a, FestivalUser b) {
    final aSubmitted = a.lastSubmittedAt;
    final bSubmitted = b.lastSubmittedAt;

    if (aSubmitted == null && bSubmitted != null) return 1;
    if (aSubmitted != null && bSubmitted == null) return -1;
    if (aSubmitted != null && bSubmitted != null) {
      final submittedCompare = bSubmitted.compareTo(aSubmitted);
      if (submittedCompare != 0) return submittedCompare;
    }

    final aCreated = a.createdAt;
    final bCreated = b.createdAt;
    if (aCreated != null && bCreated != null) {
      return bCreated.compareTo(aCreated);
    }
    return a.nickname.compareTo(b.nickname);
  }

  bool _mapEquals(Map<String, int> a, Map<String, int> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}
