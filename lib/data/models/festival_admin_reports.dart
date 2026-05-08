import 'package:greenfestival/data/models/festival_admin_models.dart';

enum FestivalSortDirection { ascending, descending }

enum FestivalSubmittedFilter { all, submittedOnly }

enum FestivalUserFilterField { gender, age, residence, submitted }

enum FestivalBoothFilterField { category, submitted }

enum FestivalUserSortMode {
  current,
  nickname,
  gender,
  age,
  participantCount,
  residence,
  submitted,
}

enum FestivalBoothSortMode { categoryName, boothName }

class FestivalUserFilterCondition {
  const FestivalUserFilterCondition({
    required this.field,
    this.intValue = 0,
    this.submitted = FestivalSubmittedFilter.all,
  });

  final FestivalUserFilterField field;
  final int intValue;
  final FestivalSubmittedFilter submitted;

  bool get isActive {
    return switch (field) {
      FestivalUserFilterField.gender ||
      FestivalUserFilterField.age ||
      FestivalUserFilterField.residence => intValue != 0,
      FestivalUserFilterField.submitted =>
        submitted == FestivalSubmittedFilter.submittedOnly,
    };
  }
}

class FestivalBoothFilterCondition {
  const FestivalBoothFilterCondition({
    required this.field,
    this.categoryUid = '',
    this.submitted = FestivalSubmittedFilter.all,
  });

  final FestivalBoothFilterField field;
  final String categoryUid;
  final FestivalSubmittedFilter submitted;

  bool get isActive {
    return switch (field) {
      FestivalBoothFilterField.category => categoryUid.isNotEmpty,
      FestivalBoothFilterField.submitted =>
        submitted == FestivalSubmittedFilter.submittedOnly,
    };
  }
}

class FestivalUserSortCondition {
  const FestivalUserSortCondition({
    required this.mode,
    required this.direction,
  });

  final FestivalUserSortMode mode;
  final FestivalSortDirection direction;
}

class FestivalBoothSortCondition {
  const FestivalBoothSortCondition({
    required this.mode,
    required this.direction,
  });

  final FestivalBoothSortMode mode;
  final FestivalSortDirection direction;
}

class FestivalUserReportFilters {
  const FestivalUserReportFilters({
    this.query = '',
    this.filters = const [],
    this.sorts = const [
      FestivalUserSortCondition(
        mode: FestivalUserSortMode.current,
        direction: FestivalSortDirection.descending,
      ),
    ],
  });

  final String query;
  final List<FestivalUserFilterCondition> filters;
  final List<FestivalUserSortCondition> sorts;
}

class FestivalBoothReportFilters {
  const FestivalBoothReportFilters({
    this.filters = const [],
    this.sorts = const [
      FestivalBoothSortCondition(
        mode: FestivalBoothSortMode.categoryName,
        direction: FestivalSortDirection.ascending,
      ),
      FestivalBoothSortCondition(
        mode: FestivalBoothSortMode.boothName,
        direction: FestivalSortDirection.ascending,
      ),
    ],
  });

  final List<FestivalBoothFilterCondition> filters;
  final List<FestivalBoothSortCondition> sorts;
}

class FestivalBoothSummaryRow {
  const FestivalBoothSummaryRow({
    required this.categoryUid,
    required this.categoryName,
    required this.seedUid,
    required this.boothName,
    required this.issuedSeedCount,
    this.genderSeedCounts = const {},
    this.ageSeedCounts = const {},
    this.residenceSeedCounts = const {},
  });

  final String categoryUid;
  final String categoryName;
  final String seedUid;
  final String boothName;
  final int issuedSeedCount;
  final Map<String, int> genderSeedCounts;
  final Map<String, int> ageSeedCounts;
  final Map<String, int> residenceSeedCounts;
}

class FestivalUserSummaryRow {
  const FestivalUserSummaryRow({
    required this.groupName,
    required this.label,
    required this.participantCount,
    required this.seedCount,
  });

  final String groupName;
  final String label;
  final int participantCount;
  final int seedCount;
}

class FestivalCategorySummaryRow {
  const FestivalCategorySummaryRow({
    required this.categoryName,
    required this.issuedSeedCount,
  });

  final String categoryName;
  final int issuedSeedCount;
}

List<FestivalUser> filterAndSortFestivalUsers(
  List<FestivalUser> users,
  FestivalUserReportFilters filters,
) {
  final query = filters.query.trim().toLowerCase();
  final filtered = users.where((user) {
    for (final condition in filters.filters) {
      if (!_matchesUserFilter(user, condition)) return false;
    }
    if (query.isEmpty) return true;

    return [
      user.nickname,
      user.uid,
      user.phoneNumber,
      reportGenderLabel(user),
      reportAgeLabel(user),
      reportResidenceLabel(user),
    ].join(' ').toLowerCase().contains(query);
  }).toList();

  final indexed =
      [
        for (var index = 0; index < filtered.length; index += 1)
          _IndexedUser(filtered[index], index),
      ]..sort((a, b) {
        for (final condition in filters.sorts) {
          final result = _compareIndexedUsers(a, b, condition);
          if (result != 0) return result;
        }
        return a.index.compareTo(b.index);
      });

  return indexed.map((item) => item.user).toList();
}

List<FestivalBoothSummaryRow> buildFestivalBoothSummaryRows(
  List<FestivalUser> users,
  SeedCatalog catalog,
  FestivalBoothReportFilters filters,
) {
  final reportUsers = _filterUsersForBoothReport(users, filters);
  final rows = catalog.seeds
      .where((seed) => _matchesBoothFilters(seed, filters.filters))
      .map((seed) {
        var issuedSeedCount = 0;
        final genderSeedCounts = <String, int>{};
        final ageSeedCounts = <String, int>{};
        final residenceSeedCounts = <String, int>{};

        for (final user in reportUsers) {
          final userIssuedSeedCount = _issuedSeedCountForUser(user, seed);
          if (userIssuedSeedCount <= 0) continue;

          issuedSeedCount += userIssuedSeedCount;
          _addSeedCount(
            genderSeedCounts,
            reportGenderLabel(user),
            userIssuedSeedCount,
          );
          _addSeedCount(
            ageSeedCounts,
            reportAgeLabel(user),
            userIssuedSeedCount,
          );
          _addSeedCount(
            residenceSeedCounts,
            reportResidenceLabel(user),
            userIssuedSeedCount,
          );
        }

        return FestivalBoothSummaryRow(
          categoryUid: seed.categoryUid,
          categoryName: _resolvedCategoryName(seed),
          seedUid: seed.uid,
          boothName: seed.name,
          issuedSeedCount: issuedSeedCount,
          genderSeedCounts: genderSeedCounts,
          ageSeedCounts: ageSeedCounts,
          residenceSeedCounts: residenceSeedCounts,
        );
      })
      .toList();

  final indexed =
      [
        for (var index = 0; index < rows.length; index += 1)
          _IndexedBooth(rows[index], index),
      ]..sort((a, b) {
        for (final condition in filters.sorts) {
          final result = _compareIndexedBooths(a, b, condition);
          if (result != 0) return result;
        }
        return a.index.compareTo(b.index);
      });

  return indexed.map((item) => item.row).toList();
}

List<FestivalUserSummaryRow> buildFestivalUserSummaryRows(
  List<FestivalUser> users,
) {
  final summaries = <FestivalUserSummaryRow>[];
  summaries.addAll(_summarizeUsers(users, '성별', reportGenderLabel));
  summaries.addAll(_summarizeUsers(users, '거주정보', reportResidenceLabel));
  summaries.addAll(_summarizeUsers(users, '연령', reportAgeLabel));
  return summaries;
}

List<FestivalCategorySummaryRow> buildFestivalCategorySummaryRows(
  List<FestivalBoothSummaryRow> rows,
) {
  final grouped = <String, int>{};
  for (final row in rows) {
    grouped[row.categoryName] =
        (grouped[row.categoryName] ?? 0) + row.issuedSeedCount;
  }
  final summaries =
      grouped.entries
          .map(
            (entry) => FestivalCategorySummaryRow(
              categoryName: entry.key,
              issuedSeedCount: entry.value,
            ),
          )
          .toList()
        ..sort((a, b) => a.categoryName.compareTo(b.categoryName));
  return summaries;
}

String reportGenderLabel(FestivalUser user) {
  if (user.genderLabel.trim().isNotEmpty && user.genderLabel != '-') {
    return user.genderLabel;
  }
  return genderLabelByCode(user.gender);
}

String reportAgeLabel(FestivalUser user) {
  if (user.ageGroupLabel.trim().isNotEmpty && user.ageGroupLabel != '-') {
    return user.ageGroupLabel;
  }
  return ageLabelByCode(user.ageGroup);
}

String reportResidenceLabel(FestivalUser user) {
  if (user.residenceLabel.trim().isNotEmpty && user.residenceLabel != '-') {
    return user.residenceLabel;
  }
  return residenceLabelByCode(user.residence);
}

bool _matchesUserFilter(
  FestivalUser user,
  FestivalUserFilterCondition condition,
) {
  return switch (condition.field) {
    FestivalUserFilterField.gender =>
      condition.intValue == 0 || user.gender == condition.intValue,
    FestivalUserFilterField.age =>
      condition.intValue == 0 || user.ageGroup == condition.intValue,
    FestivalUserFilterField.residence =>
      condition.intValue == 0 || user.residence == condition.intValue,
    FestivalUserFilterField.submitted =>
      condition.submitted == FestivalSubmittedFilter.all ||
          user.lastSubmittedAt != null,
  };
}

List<FestivalUser> _filterUsersForBoothReport(
  List<FestivalUser> users,
  FestivalBoothReportFilters filters,
) {
  final submittedOnly = filters.filters.any(
    (condition) =>
        condition.field == FestivalBoothFilterField.submitted &&
        condition.submitted == FestivalSubmittedFilter.submittedOnly,
  );
  if (!submittedOnly) return users;
  return users.where((user) => user.lastSubmittedAt != null).toList();
}

bool _matchesBoothFilters(
  SeedItem seed,
  List<FestivalBoothFilterCondition> filters,
) {
  for (final condition in filters) {
    switch (condition.field) {
      case FestivalBoothFilterField.category:
        if (condition.categoryUid.isNotEmpty &&
            seed.categoryUid != condition.categoryUid) {
          return false;
        }
      case FestivalBoothFilterField.submitted:
        break;
    }
  }
  return true;
}

int _issuedSeedCountForUser(FestivalUser user, SeedItem seed) {
  final count = user.seedCounts[seed.uid] ?? 0;
  if (count <= 0) return 0;
  return count * normalizedSeedValue(seed.seedValue);
}

void _addSeedCount(Map<String, int> totals, String label, int count) {
  final key = label.trim().isEmpty ? '-' : label.trim();
  totals[key] = (totals[key] ?? 0) + count;
}

int _compareIndexedUsers(
  _IndexedUser a,
  _IndexedUser b,
  FestivalUserSortCondition condition,
) {
  if (condition.mode == FestivalUserSortMode.current) {
    return condition.direction == FestivalSortDirection.descending
        ? a.index.compareTo(b.index)
        : b.index.compareTo(a.index);
  }

  var result = _compareUsers(a.user, b.user, condition.mode);
  if (condition.direction == FestivalSortDirection.descending) {
    result = -result;
  }
  return result;
}

int _compareUsers(FestivalUser a, FestivalUser b, FestivalUserSortMode mode) {
  switch (mode) {
    case FestivalUserSortMode.current:
      return 0;
    case FestivalUserSortMode.nickname:
      return a.nickname.compareTo(b.nickname);
    case FestivalUserSortMode.gender:
      return reportGenderLabel(a).compareTo(reportGenderLabel(b));
    case FestivalUserSortMode.age:
      return a.ageGroup.compareTo(b.ageGroup);
    case FestivalUserSortMode.participantCount:
      return a.participantCount.compareTo(b.participantCount);
    case FestivalUserSortMode.residence:
      return reportResidenceLabel(a).compareTo(reportResidenceLabel(b));
    case FestivalUserSortMode.submitted:
      return _submittedValue(a).compareTo(_submittedValue(b));
  }
}

int _compareIndexedBooths(
  _IndexedBooth a,
  _IndexedBooth b,
  FestivalBoothSortCondition condition,
) {
  var result = switch (condition.mode) {
    FestivalBoothSortMode.categoryName => a.row.categoryName.compareTo(
      b.row.categoryName,
    ),
    FestivalBoothSortMode.boothName => a.row.boothName.compareTo(
      b.row.boothName,
    ),
  };
  if (condition.direction == FestivalSortDirection.descending) {
    result = -result;
  }
  return result;
}

int _submittedValue(FestivalUser user) {
  return user.lastSubmittedAt == null ? 0 : 1;
}

String _resolvedCategoryName(SeedItem seed) {
  final name = seed.categoryName.trim();
  return name.isEmpty ? '미분류' : name;
}

List<FestivalUserSummaryRow> _summarizeUsers(
  List<FestivalUser> users,
  String groupName,
  String Function(FestivalUser user) labelFor,
) {
  final grouped = <String, ({int participantCount, int seedCount})>{};
  for (final user in users) {
    final label = labelFor(user);
    final current = grouped[label] ?? (participantCount: 0, seedCount: 0);
    grouped[label] = (
      participantCount: current.participantCount + user.participantCount,
      seedCount: current.seedCount + user.seedCount,
    );
  }
  final rows =
      grouped.entries
          .map(
            (entry) => FestivalUserSummaryRow(
              groupName: groupName,
              label: entry.key,
              participantCount: entry.value.participantCount,
              seedCount: entry.value.seedCount,
            ),
          )
          .toList()
        ..sort((a, b) => a.label.compareTo(b.label));
  return rows;
}

class _IndexedUser {
  const _IndexedUser(this.user, this.index);

  final FestivalUser user;
  final int index;
}

class _IndexedBooth {
  const _IndexedBooth(this.row, this.index);

  final FestivalBoothSummaryRow row;
  final int index;
}
