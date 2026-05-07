import 'package:flutter_test/flutter_test.dart';
import 'package:greenfestival/data/models/festival_admin_models.dart';
import 'package:greenfestival/data/models/festival_admin_reports.dart';

void main() {
  group('filterAndSortFestivalUsers', () {
    test('filters by profile fields and excludes unsubmitted users', () {
      final users = [
        _user(
          uid: 'u1',
          nickname: '가람',
          gender: 1,
          ageGroup: 3,
          residence: 1,
          participantCount: 2,
          seedCount: 4,
          submittedAt: DateTime(2026, 5, 1),
        ),
        _user(
          uid: 'u2',
          nickname: '나래',
          gender: 2,
          ageGroup: 4,
          residence: 5,
          participantCount: 3,
          seedCount: 6,
        ),
      ];

      final result = filterAndSortFestivalUsers(
        users,
        const FestivalUserReportFilters(
          filters: [
            FestivalUserFilterCondition(
              field: FestivalUserFilterField.gender,
              intValue: 1,
            ),
            FestivalUserFilterCondition(
              field: FestivalUserFilterField.age,
              intValue: 3,
            ),
            FestivalUserFilterCondition(
              field: FestivalUserFilterField.residence,
              intValue: 1,
            ),
            FestivalUserFilterCondition(
              field: FestivalUserFilterField.submitted,
              submitted: FestivalSubmittedFilter.submittedOnly,
            ),
          ],
        ),
      );

      expect(result.map((user) => user.uid), ['u1']);
    });

    test('keeps current order by default and reverses it for ascending', () {
      final users = [
        _user(uid: 'u1', nickname: '다'),
        _user(uid: 'u2', nickname: '가'),
        _user(uid: 'u3', nickname: '나'),
      ];

      final defaultResult = filterAndSortFestivalUsers(
        users,
        const FestivalUserReportFilters(),
      );
      final ascendingResult = filterAndSortFestivalUsers(
        users,
        const FestivalUserReportFilters(
          sorts: [
            FestivalUserSortCondition(
              mode: FestivalUserSortMode.current,
              direction: FestivalSortDirection.ascending,
            ),
          ],
        ),
      );

      expect(defaultResult.map((user) => user.uid), ['u1', 'u2', 'u3']);
      expect(ascendingResult.map((user) => user.uid), ['u3', 'u2', 'u1']);
    });

    test('sorts by nickname', () {
      final users = [
        _user(uid: 'u1', nickname: '다'),
        _user(uid: 'u2', nickname: '가'),
        _user(uid: 'u3', nickname: '나'),
      ];

      final result = filterAndSortFestivalUsers(
        users,
        const FestivalUserReportFilters(
          sorts: [
            FestivalUserSortCondition(
              mode: FestivalUserSortMode.nickname,
              direction: FestivalSortDirection.ascending,
            ),
          ],
        ),
      );

      expect(result.map((user) => user.uid), ['u2', 'u3', 'u1']);
    });

    test('applies multiple sort priorities in order', () {
      final users = [
        _user(uid: 'u1', nickname: '가람', gender: 1, participantCount: 1),
        _user(uid: 'u2', nickname: '나래', gender: 2, participantCount: 3),
        _user(uid: 'u3', nickname: '다온', gender: 1, participantCount: 4),
      ];

      final result = filterAndSortFestivalUsers(
        users,
        const FestivalUserReportFilters(
          sorts: [
            FestivalUserSortCondition(
              mode: FestivalUserSortMode.gender,
              direction: FestivalSortDirection.ascending,
            ),
            FestivalUserSortCondition(
              mode: FestivalUserSortMode.participantCount,
              direction: FestivalSortDirection.descending,
            ),
          ],
        ),
      );

      expect(result.map((user) => user.uid), ['u3', 'u1', 'u2']);
    });
  });

  group('booth report rows', () {
    test('calculates booth seed totals from seed count times seed value', () {
      final catalog = _catalog();
      final users = [
        _user(uid: 'u1', nickname: '가람', seedCounts: {'s1': 2, 's2': 1}),
        _user(uid: 'u2', nickname: '나래', seedCounts: {'s1': 1}),
      ];

      final result = buildFestivalBoothSummaryRows(
        users,
        catalog,
        const FestivalBoothReportFilters(),
      );

      expect(result.map((row) => (row.boothName, row.issuedSeedCount)), [
        ('부스 A', 6),
        ('부스 B', 1),
      ]);
    });

    test('category summary is based on booth summary rows', () {
      final catalog = _catalog();
      final users = [
        _user(
          uid: 'u1',
          nickname: '가람',
          seedCounts: {'s1': 2, 's2': 1},
          submittedAt: DateTime(2026, 5, 1),
        ),
      ];

      final exportRows = buildFestivalBoothSummaryRows(
        users,
        catalog,
        const FestivalBoothReportFilters(),
      );
      final summaries = buildFestivalCategorySummaryRows(exportRows);

      expect(summaries.map((row) => (row.categoryName, row.issuedSeedCount)), [
        ('카테고리 A', 5),
      ]);
    });
  });

  test('user summary groups participant and seed totals', () {
    final users = [
      _user(
        uid: 'u1',
        nickname: '가람',
        gender: 1,
        ageGroup: 3,
        residence: 1,
        participantCount: 2,
        seedCount: 4,
      ),
      _user(
        uid: 'u2',
        nickname: '나래',
        gender: 1,
        ageGroup: 4,
        residence: 1,
        participantCount: 3,
        seedCount: 6,
      ),
    ];

    final summaries = buildFestivalUserSummaryRows(users);
    final genderSummary = summaries.singleWhere(
      (row) => row.groupName == '성별' && row.label == '남성',
    );
    final residenceSummary = summaries.singleWhere(
      (row) => row.groupName == '거주정보' && row.label == '청주시 상당구',
    );

    expect(genderSummary.participantCount, 5);
    expect(genderSummary.seedCount, 10);
    expect(residenceSummary.participantCount, 5);
    expect(residenceSummary.seedCount, 10);
  });
}

FestivalUser _user({
  required String uid,
  required String nickname,
  int gender = 1,
  int ageGroup = 3,
  int residence = 1,
  int participantCount = 1,
  int seedCount = 0,
  Map<String, int> seedCounts = const {},
  DateTime? submittedAt,
}) {
  return FestivalUser(
    uid: uid,
    nickname: nickname,
    gender: gender,
    genderLabel: genderLabelByCode(gender),
    ageGroup: ageGroup,
    ageGroupLabel: ageLabelByCode(ageGroup),
    participantCount: participantCount,
    residence: residence,
    residenceLabel: residenceLabelByCode(residence),
    phoneNumber: '01000000000',
    seedCount: seedCount,
    seedCounts: seedCounts,
    isHighlighted: false,
    lastSubmittedAt: submittedAt,
  );
}

SeedCatalog _catalog() {
  return const SeedCatalog(
    categories: [SeedCategory(uid: 'c1', name: '카테고리 A')],
    seeds: [
      SeedItem(
        uid: 's1',
        name: '부스 A',
        categoryUid: 'c1',
        categoryName: '카테고리 A',
        seedValue: 2,
      ),
      SeedItem(
        uid: 's2',
        name: '부스 B',
        categoryUid: 'c1',
        categoryName: '카테고리 A',
      ),
    ],
  );
}
