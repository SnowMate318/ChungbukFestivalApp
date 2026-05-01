import 'package:cloud_firestore/cloud_firestore.dart';

class FestivalSelectOption {
  const FestivalSelectOption({
    required this.value,
    required this.label,
    this.description = '',
  });

  final int value;
  final String label;
  final String description;
}

const festivalGenderOptions = [
  FestivalSelectOption(value: 1, label: '남성', description: '남성 참여자로 등록합니다.'),
  FestivalSelectOption(value: 2, label: '여성', description: '여성 참여자로 등록합니다.'),
];

const festivalAgeOptions = [
  FestivalSelectOption(value: 1, label: '0~12세', description: '어린이 참여자입니다.'),
  FestivalSelectOption(value: 2, label: '13~19세', description: '청소년 참여자입니다.'),
  FestivalSelectOption(value: 3, label: '20대', description: '20대 참여자입니다.'),
  FestivalSelectOption(value: 4, label: '30대', description: '30대 참여자입니다.'),
  FestivalSelectOption(value: 5, label: '40대', description: '40대 참여자입니다.'),
  FestivalSelectOption(value: 6, label: '50대', description: '50대 참여자입니다.'),
  FestivalSelectOption(value: 7, label: '60대', description: '60대 참여자입니다.'),
  FestivalSelectOption(
    value: 8,
    label: '70대 이상',
    description: '70대 이상 참여자입니다.',
  ),
];

const festivalResidenceOptions = [
  FestivalSelectOption(
    value: 1,
    label: '청주시 상당구',
    description: '청주시 상당구 거주자입니다.',
  ),
  FestivalSelectOption(
    value: 2,
    label: '청주시 서원구',
    description: '청주시 서원구 거주자입니다.',
  ),
  FestivalSelectOption(
    value: 3,
    label: '청주시 청원구',
    description: '청주시 청원구 거주자입니다.',
  ),
  FestivalSelectOption(
    value: 4,
    label: '청주시 흥덕구',
    description: '청주시 흥덕구 거주자입니다.',
  ),
  FestivalSelectOption(
    value: 5,
    label: '청주시 외 지역',
    description: '청주시 외 지역 거주자입니다.',
  ),
  FestivalSelectOption(value: 6, label: '해외 거주', description: '해외 거주 참여자입니다.'),
];

String genderLabelByCode(int? code) =>
    _labelByCode(festivalGenderOptions, code);

String ageLabelByCode(int? code) => _labelByCode(festivalAgeOptions, code);

String residenceLabelByCode(int? code) =>
    _labelByCode(festivalResidenceOptions, code);

String _labelByCode(List<FestivalSelectOption> options, int? code) {
  for (final option in options) {
    if (option.value == code) {
      return option.label;
    }
  }
  return '-';
}

class FestivalUser {
  const FestivalUser({
    required this.uid,
    required this.nickname,
    required this.gender,
    required this.genderLabel,
    required this.ageGroup,
    required this.ageGroupLabel,
    required this.participantCount,
    required this.residence,
    required this.residenceLabel,
    required this.phoneNumber,
    required this.seedCount,
    required this.seedCounts,
    required this.isHighlighted,
    this.lastSubmittedAt,
    this.createdAt,
    this.updatedAt,
    this.source = 'admin',
  });

  final String uid;
  final String nickname;
  final int gender;
  final String genderLabel;
  final int ageGroup;
  final String ageGroupLabel;
  final int participantCount;
  final int residence;
  final String residenceLabel;
  final String phoneNumber;
  final int seedCount;
  final Map<String, int> seedCounts;
  final DateTime? lastSubmittedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isHighlighted;
  final String source;

  factory FestivalUser.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot, {
    String? highlightedUid,
  }) {
    final data = snapshot.data() ?? {};
    final gender = _asInt(data['gender']) ?? 0;
    final ageGroup = _asInt(data['ageGroup']) ?? _asInt(data['age_group']) ?? 0;
    final residence = _asInt(data['residence']) ?? 0;

    return FestivalUser(
      uid: _asString(data['uid'], fallback: snapshot.id),
      nickname: _asString(data['nickname']),
      gender: gender,
      genderLabel: _asString(
        data['genderLabel'] ?? data['gender_label'],
        fallback: genderLabelByCode(gender),
      ),
      ageGroup: ageGroup,
      ageGroupLabel: _asString(
        data['ageGroupLabel'] ?? data['age_group_label'],
        fallback: ageLabelByCode(ageGroup),
      ),
      participantCount:
          _asInt(data['participantCount'] ?? data['participant_count']) ?? 1,
      residence: residence,
      residenceLabel: _asString(
        data['residenceLabel'] ?? data['residence_label'],
        fallback: residenceLabelByCode(residence),
      ),
      phoneNumber: _asString(data['phoneNumber'] ?? data['phone_number']),
      seedCount: _asInt(data['seedCount'] ?? data['seed_count']) ?? 0,
      seedCounts: _asIntMap(data['seedCounts'] ?? data['seed_counts']),
      lastSubmittedAt: _asDateTime(
        data['lastSubmittedAt'] ?? data['last_submitted_at'],
      ),
      createdAt: _asDateTime(data['createdAt'] ?? data['created_at']),
      updatedAt: _asDateTime(data['updatedAt'] ?? data['updated_at']),
      isHighlighted:
          highlightedUid != null &&
          highlightedUid == _asString(data['uid'], fallback: snapshot.id),
      source: _asString(data['source'], fallback: 'admin'),
    );
  }

  FestivalUser copyWith({bool? isHighlighted}) {
    return FestivalUser(
      uid: uid,
      nickname: nickname,
      gender: gender,
      genderLabel: genderLabel,
      ageGroup: ageGroup,
      ageGroupLabel: ageGroupLabel,
      participantCount: participantCount,
      residence: residence,
      residenceLabel: residenceLabel,
      phoneNumber: phoneNumber,
      seedCount: seedCount,
      seedCounts: seedCounts,
      lastSubmittedAt: lastSubmittedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isHighlighted: isHighlighted ?? this.isHighlighted,
      source: source,
    );
  }
}

class SeedCategory {
  const SeedCategory({
    required this.uid,
    required this.name,
    this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String name;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory SeedCategory.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};
    return SeedCategory(
      uid: _asString(data['uid'], fallback: snapshot.id),
      name: _asString(data['name']),
      createdAt: _asDateTime(data['createdAt']),
      updatedAt: _asDateTime(data['updatedAt']),
    );
  }
}

class SeedItem {
  const SeedItem({
    required this.uid,
    required this.name,
    required this.categoryUid,
    required this.categoryName,
    this.seedValue = 1,
    this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String name;
  final String categoryUid;
  final String categoryName;
  final int seedValue;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory SeedItem.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};
    return SeedItem(
      uid: _asString(data['uid'], fallback: snapshot.id),
      name: _asString(data['name']),
      categoryUid: _asString(data['categoryUid'] ?? data['category_uid']),
      categoryName: _asString(data['categoryName'] ?? data['category_name']),
      seedValue: normalizedSeedValue(
        _asInt(data['seedValue'] ?? data['seed_value']),
      ),
      createdAt: _asDateTime(data['createdAt']),
      updatedAt: _asDateTime(data['updatedAt']),
    );
  }
}

class SeedCatalog {
  const SeedCatalog({required this.categories, required this.seeds});

  final List<SeedCategory> categories;
  final List<SeedItem> seeds;

  Map<String, List<SeedItem>> get seedsByCategory {
    final grouped = <String, List<SeedItem>>{};
    for (final seed in seeds) {
      grouped.putIfAbsent(seed.categoryUid, () => []).add(seed);
    }
    return grouped;
  }
}

class HighlightedUser {
  const HighlightedUser({required this.nickname, required this.seedCount});

  final String nickname;
  final int seedCount;
}

class SeedCountRow {
  const SeedCountRow({required this.seed, required this.count});

  final SeedItem seed;
  final int count;
}

int normalizedSeedValue(int? value) {
  if (value == null || value <= 0) {
    return 1;
  }
  return value;
}

int seedTotalFromCounts(Map<String, int> seedCounts, Iterable<SeedItem> seeds) {
  final seedValueByUid = <String, int>{
    for (final seed in seeds) seed.uid: seed.seedValue,
  };
  return seedTotalFromSeedValues(seedCounts, seedValueByUid);
}

int seedTotalFromSeedValues(
  Map<String, int> seedCounts,
  Map<String, int> seedValueByUid,
) {
  var total = 0;
  for (final entry in seedCounts.entries) {
    final count = entry.value;
    if (count <= 0) {
      continue;
    }
    final seedValue = normalizedSeedValue(seedValueByUid[entry.key]);
    total += count * seedValue;
  }
  return total;
}

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

String _asString(Object? value, {String fallback = ''}) {
  if (value == null) return fallback;
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

DateTime? _asDateTime(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

Map<String, int> _asIntMap(Object? value) {
  if (value is! Map) return const {};
  return value.map((key, mapValue) {
    return MapEntry(key.toString(), _asInt(mapValue) ?? 0);
  });
}
