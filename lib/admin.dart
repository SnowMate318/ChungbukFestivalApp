import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:greenfestival/data/models/festival_admin_models.dart';
import 'package:greenfestival/services/festival_firestore_service.dart';
import 'package:intl/intl.dart';

const _genderChoices = <FestivalSelectOption>[
  FestivalSelectOption(value: 1, label: '남성'),
  FestivalSelectOption(value: 2, label: '여성'),
];

const _ageChoices = <FestivalSelectOption>[
  FestivalSelectOption(value: 1, label: '0~12세'),
  FestivalSelectOption(value: 2, label: '13~19세'),
  FestivalSelectOption(value: 3, label: '20대'),
  FestivalSelectOption(value: 4, label: '30대'),
  FestivalSelectOption(value: 5, label: '40대'),
  FestivalSelectOption(value: 6, label: '50대'),
  FestivalSelectOption(value: 7, label: '60대'),
  FestivalSelectOption(value: 8, label: '70대 이상'),
];

const _residenceChoices = <FestivalSelectOption>[
  FestivalSelectOption(value: 1, label: '청주 상당구'),
  FestivalSelectOption(value: 2, label: '청주 서원구'),
  FestivalSelectOption(value: 3, label: '청주 청원구'),
  FestivalSelectOption(value: 4, label: '청주 흥덕구'),
  FestivalSelectOption(value: 5, label: '청주 외 지역'),
  FestivalSelectOption(value: 6, label: '해외 거주'),
];

const _navItems = <_AdminNavItem>[
  _AdminNavItem(index: 1, label: '유저 정보 조회', icon: Icons.groups_rounded),
  _AdminNavItem(index: 2, label: '인원 추가', icon: Icons.person_add_alt_1_rounded),
  _AdminNavItem(index: 3, label: '부스 등록', icon: Icons.storefront_rounded),
  _AdminNavItem(index: 4, label: '시드 수량 변경', icon: Icons.tune_rounded),
];

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  static const _adminPassword = '9358';

  final FestivalFirestoreService _service = FestivalFirestoreService();
  final TextEditingController _passwordController = TextEditingController();
  int _pageIndex = 0;
  bool _authenticated = false;
  String _passwordError = '';

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _goToPage(int index) {
    if (_pageIndex == index) return;
    setState(() => _pageIndex = index);
  }

  void _submitPassword() {
    final password = _passwordController.text.trim();
    if (password == _adminPassword) {
      setState(() {
        _authenticated = true;
        _passwordError = '';
      });
      return;
    }

    setState(() {
      _passwordError = '비밀번호가 올바르지 않습니다.';
      _passwordController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final maxContentWidth = _pageIndex == 1 ? 1680.0 : 1240.0;
    final pages = <Widget>[
      _HomeTab(service: _service, onSelect: _goToPage),
      _UsersTab(service: _service, onHome: () => _goToPage(0)),
      _CreateUserTab(service: _service, onHome: () => _goToPage(0)),
      _SeedCatalogTab(service: _service, onHome: () => _goToPage(0)),
      _SeedEditorTab(service: _service, onHome: () => _goToPage(0)),
    ];

    return Scaffold(
      backgroundColor: _AdminPalette.bg,
      body: Stack(
        children: [
          const Positioned.fill(child: _AdminBackdrop()),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  child: Column(
                    children: [
                      _AdminTopbar(
                        currentIndex: _pageIndex,
                        onSelect: _goToPage,
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: IndexedStack(index: _pageIndex, children: pages),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (!_authenticated)
            Positioned.fill(
              child: _AdminPasswordGate(
                controller: _passwordController,
                errorText: _passwordError,
                onSubmit: _submitPassword,
              ),
            ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({required this.service, required this.onSelect});

  final FestivalFirestoreService service;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return _PageScrollView(
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 1080;
              final hero = _HomeHero(onSelect: onSelect);
              final stats = _HomeStatStack(service: service);
              if (stacked) {
                return Column(
                  children: [hero, const SizedBox(height: 20), stats],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 7, child: hero),
                  const SizedBox(width: 20),
                  Expanded(flex: 5, child: stats),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 1080;
              final features = _FeaturePanel(onSelect: onSelect);
              final recent = _RecentUsersPanel(service: service);
              if (stacked) {
                return Column(
                  children: [features, const SizedBox(height: 20), recent],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 7, child: features),
                  const SizedBox(width: 20),
                  Expanded(flex: 5, child: recent),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AdminPasswordGate extends StatelessWidget {
  const _AdminPasswordGate({
    required this.controller,
    required this.errorText,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final String errorText;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0x99000000),
      child: Center(
        child: Container(
          width: 420,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 36,
                offset: Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '관리자 비밀번호',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _AdminPalette.ink,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '관리 페이지에 접근하려면 비밀번호를 입력해주세요.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _AdminPalette.muted,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 22),
              TextField(
                controller: controller,
                autofocus: true,
                obscureText: true,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => onSubmit(),
                decoration: _inputDecoration(
                  '비밀번호',
                ).copyWith(errorText: errorText.isEmpty ? null : errorText),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: onSubmit,
                style: FilledButton.styleFrom(
                  backgroundColor: _AdminPalette.ink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  '확인',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UsersTab extends StatefulWidget {
  const _UsersTab({required this.service, required this.onHome});

  final FestivalFirestoreService service;
  final VoidCallback onHome;

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FestivalUser> _filterUsers(List<FestivalUser> users) {
    if (_query.isEmpty) return users;
    return users.where((user) {
      return [
        user.nickname,
        user.uid,
        user.phoneNumber,
        _displayGender(user),
        _displayAge(user),
        _displayResidence(user),
      ].join(' ').toLowerCase().contains(_query);
    }).toList();
  }

  Future<void> _highlight(FestivalUser user) async {
    if (user.lastSubmittedAt == null) {
      _showSnack(context, '최종 제출하지 않은 참가자는 강조 상태로 변경할 수 없습니다.', isError: true);
      return;
    }
    try {
      await widget.service.updateHighlightedUserByPhoneNumber(user.phoneNumber);
      if (!mounted) return;
      _showSnack(context, '${user.nickname} 사용자가 display live에 반영됩니다.');
    } catch (error) {
      if (!mounted) return;
      _showSnack(context, '$error', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _PageScrollView(
      child: Column(
        children: [
          _PageHeader(
            eyebrow: '유저 정보 조회',
            title: '참가자 현황을 한눈에 살펴보세요.',
            description:
                '최근 제출 시각이 최신인 참가자부터 정렬되며, 휴대폰 번호를 누르면 메인 화면 강조 대상이 바뀝니다.',
            actionLabel: '메인으로 돌아가기',
            actionIcon: Icons.home_rounded,
            onAction: widget.onHome,
          ),
          const SizedBox(height: 20),
          _Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PanelHeading(
                  eyebrow: '참가자 목록',
                  title: '전체 유저 디렉터리',
                  subtitle:
                      '닉네임, UID, 휴대폰 번호로 빠르게 검색할 수 있고, 실시간 스트림으로 최신 상태가 유지됩니다.',
                  trailing: LayoutBuilder(
                    builder: (context, constraints) {
                      final stacked = constraints.maxWidth < 720;
                      final controls = <Widget>[
                        SizedBox(
                          width: stacked ? double.infinity : 280,
                          child: _ToolbarField(
                            label: '검색',
                            child: TextField(
                              controller: _searchController,
                              decoration: _inputDecoration('닉네임, UID, 휴대폰 번호'),
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _searchController.clear(),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('검색 초기화'),
                        ),
                      ];
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.end,
                        children: controls,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),
                StreamBuilder<List<FestivalUser>>(
                  stream: widget.service.watchUsers(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return _EmptyState(message: '${snapshot.error}');
                    }
                    if (!snapshot.hasData) {
                      return const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _LiveBanner(text: '참가자 목록을 준비하고 있습니다.'),
                          SizedBox(height: 18),
                          _LoadingState(message: '유저 정보를 불러오는 중입니다.'),
                        ],
                      );
                    }

                    final allUsers = snapshot.data!;
                    final users = _filterUsers(allUsers);
                    final bannerText = _query.isEmpty
                        ? '총 ${allUsers.length}명의 참여자가 실시간으로 반영됩니다.'
                        : '검색 결과 ${users.length}명의 참여자가 표시되고 있습니다.';

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _LiveBanner(text: bannerText),
                        const SizedBox(height: 18),
                        if (users.isEmpty)
                          const _EmptyState(message: '검색 조건에 맞는 참여자가 없습니다.')
                        else
                          _UsersTable(users: users, onHighlight: _highlight),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateUserTab extends StatefulWidget {
  const _CreateUserTab({required this.service, required this.onHome});

  final FestivalFirestoreService service;
  final VoidCallback onHome;

  @override
  State<_CreateUserTab> createState() => _CreateUserTabState();
}

class _CreateUserTabState extends State<_CreateUserTab> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _participantCountController = TextEditingController(text: '1');

  int _gender = 1;
  int _age = 1;
  int _residence = 1;
  bool _submitting = false;
  String _nicknameStatus = '중복 확인 전입니다.';
  String _phoneStatus = '숫자만 입력해도 됩니다.';
  String _resultMessage = '등록 결과가 이곳에 표시됩니다.';
  _NoticeTone _resultTone = _NoticeTone.neutral;

  @override
  void dispose() {
    _nicknameController.dispose();
    _phoneController.dispose();
    _participantCountController.dispose();
    super.dispose();
  }

  Future<bool> _checkNickname() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      setState(() => _nicknameStatus = '닉네임을 입력해 주세요.');
      return false;
    }
    final duplicated = await widget.service.isNicknameDuplicated(nickname);
    if (!mounted) return false;
    setState(() {
      _nicknameStatus = duplicated ? '이미 사용 중인 닉네임입니다.' : '사용 가능한 닉네임입니다.';
    });
    return !duplicated;
  }

  Future<bool> _checkPhone() async {
    final phone = _phoneController.text.trim();
    if (!widget.service.isValidPhoneNumber(phone)) {
      setState(() => _phoneStatus = '올바른 휴대폰 번호를 입력해 주세요.');
      return false;
    }
    final duplicated = await widget.service.isPhoneNumberDuplicated(phone);
    if (!mounted) return false;
    setState(() {
      _phoneStatus = duplicated ? '이미 등록된 휴대폰 번호입니다.' : '사용 가능한 휴대폰 번호입니다.';
    });
    return !duplicated;
  }

  void _setResult(String message, _NoticeTone tone) {
    if (!mounted) return;
    setState(() {
      _resultMessage = message;
      _resultTone = tone;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final passed = await Future.wait([_checkNickname(), _checkPhone()]);
      if (passed.any((value) => !value)) {
        throw const FestivalAdminException('중복 확인 결과를 다시 확인해 주세요.');
      }
      final uid = await widget.service.createUser(
        nickname: _nicknameController.text.trim(),
        gender: _gender,
        ageGroup: _age,
        participantCount: int.parse(_participantCountController.text),
        residence: _residence,
        phoneNumber: _phoneController.text.trim(),
      );
      if (!mounted) return;
      _setResult('참여자가 등록되었습니다. UID: $uid', _NoticeTone.success);
      _showSnack(context, '참여자가 등록되었습니다. UID: $uid');
      _reset(preserveResult: true);
    } catch (error) {
      if (!mounted) return;
      _setResult('$error', _NoticeTone.error);
      _showSnack(context, '$error', isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _reset({bool preserveResult = false}) {
    _formKey.currentState?.reset();
    _nicknameController.clear();
    _phoneController.clear();
    _participantCountController.text = '1';
    setState(() {
      _gender = 1;
      _age = 1;
      _residence = 1;
      _nicknameStatus = '중복 확인 전입니다.';
      _phoneStatus = '숫자만 입력해도 됩니다.';
      if (!preserveResult) {
        _resultMessage = '등록 결과가 이곳에 표시됩니다.';
        _resultTone = _NoticeTone.neutral;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _PageScrollView(
      child: Column(
        children: [
          _PageHeader(
            eyebrow: '인원 추가',
            title: '새 참가자를 차분하게 등록하세요.',
            description:
                '선택형 카드와 간단한 입력칸으로 필요한 정보만 빠르게 채우고, 중복 여부도 등록 전에 바로 확인할 수 있습니다.',
            actionLabel: '메인으로 돌아가기',
            actionIcon: Icons.home_rounded,
            onAction: widget.onHome,
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 1080;
              final form = _Panel(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _PanelHeading(
                        eyebrow: '입력 폼',
                        title: '참가자 기본 정보',
                        subtitle: '모든 항목을 입력하면 바로 등록할 수 있습니다.',
                      ),
                      const SizedBox(height: 18),
                      _ResponsiveFields(
                        children: [
                          _FormFieldBlock(
                            label: '닉네임',
                            helper: _nicknameStatus,
                            child: TextFormField(
                              controller: _nicknameController,
                              maxLength: 20,
                              decoration: _inputDecoration('20자 이하'),
                              validator: (value) =>
                                  (value == null || value.trim().isEmpty)
                                  ? '닉네임을 입력해 주세요.'
                                  : null,
                              onEditingComplete: _checkNickname,
                            ),
                          ),
                          _FormFieldBlock(
                            label: '휴대폰 번호',
                            helper: _phoneStatus,
                            child: TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: _inputDecoration('010-1234-5678'),
                              validator: (value) =>
                                  widget.service.isValidPhoneNumber(value ?? '')
                                  ? null
                                  : '올바른 휴대폰 번호를 입력해 주세요.',
                              onEditingComplete: _checkPhone,
                            ),
                          ),
                          _FormFieldBlock(
                            label: '참여인원',
                            helper: '1명 이상 99명 이하로 입력해 주세요.',
                            child: TextFormField(
                              controller: _participantCountController,
                              keyboardType: TextInputType.number,
                              decoration: _inputDecoration('참여 인원 수'),
                              validator: (value) {
                                final parsed = int.tryParse(value ?? '');
                                if (parsed == null ||
                                    parsed < 1 ||
                                    parsed > 99) {
                                  return '1~99 사이 숫자를 입력해 주세요.';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      _ChoiceCardGroup(
                        title: '성별',
                        description: '현장에서 확인하기 쉽도록 한 번만 선택하면 됩니다.',
                        columns: 2,
                        options: _genderChoices,
                        selected: _gender,
                        detailBuilder: (option) =>
                            option.value == 1 ? '남성 참여자 등록' : '여성 참여자 등록',
                        onSelected: (value) => setState(() => _gender = value),
                      ),
                      const SizedBox(height: 24),
                      _ChoiceCardGroup(
                        title: '연령',
                        description: '운영 통계를 위해 연령대를 선택해 주세요.',
                        columns: 3,
                        options: _ageChoices,
                        selected: _age,
                        detailBuilder: (option) => '${option.label} 참여자',
                        onSelected: (value) => setState(() => _age = value),
                      ),
                      const SizedBox(height: 24),
                      _ChoiceCardGroup(
                        title: '거주정보',
                        description: '지역별 참여 현황을 보기 쉽게 정리한 항목입니다.',
                        columns: 3,
                        options: _residenceChoices,
                        selected: _residence,
                        detailBuilder: (option) => option.label,
                        onSelected: (value) =>
                            setState(() => _residence = value),
                      ),
                      const SizedBox(height: 28),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          FilledButton.icon(
                            onPressed: _submitting ? null : _submit,
                            icon: const Icon(Icons.person_add_alt_1_rounded),
                            label: Text(_submitting ? '등록 중...' : '인원 추가하기'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _submitting ? null : _reset,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('입력 초기화'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );

              final side = _Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _PanelHeading(
                      eyebrow: '입력 안내',
                      title: '등록 전에 확인할 내용',
                    ),
                    const SizedBox(height: 18),
                    const _ChecklistItem('닉네임은 최대 20자까지 가능합니다.'),
                    const _ChecklistItem('휴대폰 번호는 하이픈이 있어도 자동으로 정리됩니다.'),
                    const _ChecklistItem('참여인원은 1명 이상 99명 이하만 입력할 수 있습니다.'),
                    const _ChecklistItem('등록이 끝나면 다른 화면에서도 최신 현황이 바로 반영됩니다.'),
                    const SizedBox(height: 22),
                    _ResultCard(message: _resultMessage, tone: _resultTone),
                  ],
                ),
              );

              if (stacked) {
                return Column(
                  children: [form, const SizedBox(height: 20), side],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 7, child: form),
                  const SizedBox(width: 20),
                  Expanded(flex: 4, child: side),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SeedCatalogTab extends StatefulWidget {
  const _SeedCatalogTab({required this.service, required this.onHome});

  final FestivalFirestoreService service;
  final VoidCallback onHome;

  @override
  State<_SeedCatalogTab> createState() => _SeedCatalogTabState();
}

class _SeedCatalogTabState extends State<_SeedCatalogTab> {
  final _seedNameController = TextEditingController();
  final _newCategoryController = TextEditingController();
  final _seedValueController = TextEditingController(text: '1');
  String _categoryUid = '';
  bool _submitting = false;

  @override
  void dispose() {
    _seedNameController.dispose();
    _newCategoryController.dispose();
    _seedValueController.dispose();
    super.dispose();
  }

  void _reset() {
    _seedNameController.clear();
    _newCategoryController.clear();
    _seedValueController.text = '1';
    setState(() => _categoryUid = '');
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await widget.service.createSeed(
        seedName: _seedNameController.text.trim(),
        seedValue: int.tryParse(_seedValueController.text.trim()) ?? 1,
        categoryUid: _categoryUid.isEmpty ? null : _categoryUid,
        newCategoryName: _newCategoryController.text.trim().isEmpty
            ? null
            : _newCategoryController.text.trim(),
      );
      if (!mounted) return;
      _showSnack(context, '부스가 등록되었습니다.');
      _reset();
    } catch (error) {
      if (!mounted) return;
      _showSnack(context, '$error', isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _deleteSeed(SeedItem seed) async {
    final confirmed = await _confirmDialog(
      context,
      title: '부스를 삭제할까요?',
      message: '부스 "${seed.name}"를 삭제하면 연결된 사용자 적립 횟수도 함께 정리됩니다.',
      confirmLabel: '부스 삭제',
    );
    if (confirmed != true) return;
    try {
      await widget.service.deleteSeed(seed.uid);
      if (!mounted) return;
      _showSnack(context, '부스가 삭제되었습니다.');
    } catch (error) {
      if (!mounted) return;
      _showSnack(context, '$error', isError: true);
    }
  }

  Future<void> _deleteCategory(SeedCategory category) async {
    final confirmed = await _confirmDialog(
      context,
      title: '카테고리를 삭제할까요?',
      message: '카테고리 "${category.name}"를 삭제하면 소속 부스와 사용자 적립 횟수도 함께 정리됩니다.',
      confirmLabel: '카테고리 삭제',
    );
    if (confirmed != true) return;
    try {
      await widget.service.deleteCategory(category.uid);
      if (!mounted) return;
      _showSnack(context, '카테고리가 삭제되었습니다.');
    } catch (error) {
      if (!mounted) return;
      _showSnack(context, '$error', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _PageScrollView(
      child: Column(
        children: [
          _PageHeader(
            eyebrow: '부스 등록',
            title: '카테고리와 부스 이름으로 부스를 등록하세요',
            description:
                '기존 카테고리를 선택하거나 새 카테고리를 입력한 뒤, 부스 이름과 기본 시드값을 등록할 수 있습니다.',
            actionLabel: '메인으로 돌아가기',
            actionIcon: Icons.home_rounded,
            onAction: widget.onHome,
          ),
          const SizedBox(height: 20),
          StreamBuilder<SeedCatalog>(
            stream: widget.service.watchSeedCatalog(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _Panel(child: _EmptyState(message: '${snapshot.error}'));
              }
              if (!snapshot.hasData) {
                return const _Panel(
                  child: _LoadingState(message: '카테고리와 부스 목록을 불러오는 중입니다.'),
                );
              }

              final catalog = snapshot.data!;
              final categoryByUid = {
                for (final category in catalog.categories)
                  category.uid: category,
              };

              return LayoutBuilder(
                builder: (context, constraints) {
                  final stacked = constraints.maxWidth < 1080;
                  final form = _Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _PanelHeading(
                          eyebrow: '입력',
                          title: '부스 추가',
                          subtitle:
                              '카테고리와 부스 이름은 모두 1자 이상이어야 하며, 부스 이름은 전체에서 중복될 수 없습니다.',
                        ),
                        const SizedBox(height: 18),
                        _ResponsiveFields(
                          children: [
                            _FormFieldBlock(
                              label: '기존 카테고리 선택',
                              helper: '선택하지 않으면 새 카테고리로 등록됩니다.',
                              child: DropdownButtonFormField<String>(
                                key: ValueKey(
                                  '${catalog.categories.length}-$_categoryUid',
                                ),
                                initialValue:
                                    catalog.categories.any(
                                      (item) => item.uid == _categoryUid,
                                    )
                                    ? _categoryUid
                                    : '',
                                decoration: _inputDecoration('기존 카테고리 선택'),
                                items: [
                                  const DropdownMenuItem(
                                    value: '',
                                    child: Text('새 카테고리를 입력할게요'),
                                  ),
                                  ...catalog.categories.map(
                                    (category) => DropdownMenuItem(
                                      value: category.uid,
                                      child: Text(category.name),
                                    ),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _categoryUid = value ?? '';
                                    if (_categoryUid.isNotEmpty) {
                                      _newCategoryController.clear();
                                    }
                                  });
                                },
                              ),
                            ),
                            _FormFieldBlock(
                              label: '새 카테고리 추가',
                              helper: '입력하면 선택 박스 대신 새 카테고리로 등록됩니다.',
                              child: TextField(
                                controller: _newCategoryController,
                                decoration: _inputDecoration('예: 교육'),
                                onChanged: (value) {
                                  if (value.trim().isNotEmpty &&
                                      _categoryUid.isNotEmpty) {
                                    setState(() => _categoryUid = '');
                                  }
                                },
                              ),
                            ),
                            _FormFieldBlock(
                              label: '부스 이름',
                              helper: '부스 이름은 전체에서 중복될 수 없습니다.',
                              child: TextField(
                                controller: _seedNameController,
                                decoration: _inputDecoration('예: 업사이클 체험부스'),
                              ),
                            ),
                            _FormFieldBlock(
                              label: '부스별 시드 갯수',
                              helper: '비워두면 기본값 1이 적용됩니다.',
                              child: TextField(
                                controller: _seedValueController,
                                keyboardType: TextInputType.number,
                                decoration: _inputDecoration('기본값 1'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            FilledButton.icon(
                              onPressed: _submitting ? null : _submit,
                              icon: const Icon(Icons.storefront_rounded),
                              label: Text(_submitting ? '저장 중...' : '시드 등록하기'),
                            ),
                            OutlinedButton.icon(
                              onPressed: _submitting ? null : _reset,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('입력 초기화'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );

                  final list = _Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _PanelHeading(
                          eyebrow: '등록 현황',
                          title: '카테고리 / 부스 목록',
                          subtitle:
                              '현재 ${catalog.categories.length}개 카테고리, ${catalog.seeds.length}개 부스가 등록되어 있습니다.',
                        ),
                        const SizedBox(height: 18),
                        if (catalog.categories.isEmpty && catalog.seeds.isEmpty)
                          const _EmptyState(message: '등록된 부스가 없습니다.')
                        else
                          Column(
                            children: [
                              ...catalog.categories.map((category) {
                                final seeds =
                                    catalog.seedsByCategory[category.uid] ??
                                    const <SeedItem>[];
                                return _CatalogCategoryCard(
                                  title: category.name,
                                  countLabel: '${seeds.length}개 부스',
                                  onDeleteCategory: () =>
                                      _deleteCategory(category),
                                  children: seeds.isEmpty
                                      ? const [
                                          _InlineEmptyState(
                                            message: '이 카테고리에 등록된 부스가 없습니다.',
                                          ),
                                        ]
                                      : seeds.map((seed) {
                                          return _CatalogSeedRow(
                                            seed: seed,
                                            onDelete: () => _deleteSeed(seed),
                                          );
                                        }).toList(),
                                );
                              }),
                              ...catalog.seedsByCategory.entries
                                  .where(
                                    (entry) =>
                                        !categoryByUid.containsKey(entry.key),
                                  )
                                  .map((entry) {
                                    return _CatalogCategoryCard(
                                      title: entry.value.first.categoryName,
                                      countLabel: '${entry.value.length}개 부스',
                                      children: entry.value.map((seed) {
                                        return _CatalogSeedRow(
                                          seed: seed,
                                          onDelete: () => _deleteSeed(seed),
                                        );
                                      }).toList(),
                                    );
                                  }),
                            ],
                          ),
                      ],
                    ),
                  );

                  if (stacked) {
                    return Column(
                      children: [form, const SizedBox(height: 20), list],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 6, child: form),
                      const SizedBox(width: 20),
                      Expanded(flex: 5, child: list),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SeedEditorTab extends StatefulWidget {
  const _SeedEditorTab({required this.service, required this.onHome});

  final FestivalFirestoreService service;
  final VoidCallback onHome;

  @override
  State<_SeedEditorTab> createState() => _SeedEditorTabState();
}

class _SeedEditorTabState extends State<_SeedEditorTab> {
  final _lookupController = TextEditingController();
  String _lookupStatus = '휴대폰 번호를 입력하고 조회해주세요.';
  String? _currentUid;
  String? _loadedStamp;
  bool _saving = false;
  bool _dirty = false;
  Map<String, int> _counts = {};

  @override
  void dispose() {
    _lookupController.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    try {
      final user = await widget.service.findUserByPhoneNumber(
        _lookupController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _currentUid = user.uid;
        _lookupController.text = user.phoneNumber;
        _lookupStatus = '${user.nickname} 참여자 정보를 불러왔습니다.';
        _dirty = false;
        _loadedStamp = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _currentUid = null;
        _lookupStatus = '$error';
      });
      _showSnack(context, '$error', isError: true);
    }
  }

  void _syncCountsIfNeeded(FestivalUser user, SeedCatalog catalog) {
    final stamp =
        '${user.uid}-${user.updatedAt?.toIso8601String()}-${catalog.seeds.length}';
    if (_dirty || _loadedStamp == stamp) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _dirty || _loadedStamp == stamp) return;
      final participantLimit = user.participantCount < 1
          ? 1
          : user.participantCount;
      setState(() {
        _counts = {
          for (final seed in catalog.seeds)
            seed.uid: math.min(
              user.seedCounts[seed.uid] ?? 0,
              participantLimit,
            ),
        };
        _loadedStamp = stamp;
      });
    });
  }

  Future<void> _save() async {
    final uid = _currentUid;
    if (uid == null) {
      _showSnack(context, '먼저 참여자를 조회해주세요.', isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.service.updateUserSeedCounts(uid: uid, seedCounts: _counts);
      if (!mounted) return;
      setState(() {
        _dirty = false;
        _loadedStamp = null;
      });
      _showSnack(context, '시드 적립 정보가 저장되었습니다.');
    } catch (error) {
      if (!mounted) return;
      _showSnack(context, '$error', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _changeCount(String seedUid, int nextValue) {
    setState(() {
      _counts[seedUid] = math.max(0, nextValue);
      _dirty = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _PageScrollView(
      child: Column(
        children: [
          _PageHeader(
            eyebrow: '시드 수량 변경',
            title: '참여자별 시드 보유 현황을 수정하세요',
            description: '휴대폰 번호로 참여자를 찾은 뒤 부스별 적립 횟수를 조정할 수 있습니다.',
            actionLabel: '메인으로 돌아가기',
            actionIcon: Icons.home_rounded,
            onAction: widget.onHome,
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 1080;
              final lookupPanel = _Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _PanelHeading(
                      eyebrow: '휴대폰 번호 조회',
                      title: '대상 참여자 찾기',
                    ),
                    const SizedBox(height: 18),
                    LayoutBuilder(
                      builder: (context, innerConstraints) {
                        final compact = innerConstraints.maxWidth < 420;
                        final field = _FormFieldBlock(
                          label: '휴대폰 번호',
                          helper: _lookupStatus,
                          child: TextField(
                            controller: _lookupController,
                            keyboardType: TextInputType.phone,
                            decoration: _inputDecoration('예: 010-1234-5678'),
                            onSubmitted: (_) => _lookup(),
                          ),
                        );
                        final button = FilledButton.icon(
                          onPressed: _lookup,
                          icon: const Icon(Icons.search_rounded),
                          label: const Text('조회하기'),
                        );
                        if (compact) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              field,
                              const SizedBox(height: 12),
                              button,
                            ],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: field),
                            const SizedBox(width: 12),
                            button,
                          ],
                        );
                      },
                    ),
                  ],
                ),
              );

              final profilePanel = StreamBuilder<SeedCatalog>(
                stream: widget.service.watchSeedCatalog(),
                builder: (context, catalogSnapshot) {
                  if (catalogSnapshot.hasError) {
                    return _Panel(
                      child: _EmptyState(message: '${catalogSnapshot.error}'),
                    );
                  }

                  final catalog =
                      catalogSnapshot.data ??
                      const SeedCatalog(categories: [], seeds: []);

                  if (_currentUid == null) {
                    return const _Panel(
                      child: _LargeEmptyState(
                        message: '조회한 참여자 정보가 여기에 표시됩니다.',
                      ),
                    );
                  }

                  return StreamBuilder<FestivalUser?>(
                    stream: widget.service.watchUser(_currentUid!),
                    builder: (context, userSnapshot) {
                      if (userSnapshot.hasError) {
                        return _Panel(
                          child: _EmptyState(message: '${userSnapshot.error}'),
                        );
                      }
                      final user = userSnapshot.data;
                      if (user == null) {
                        return const _Panel(
                          child: _LoadingState(message: '참여자 정보를 불러오는 중입니다.'),
                        );
                      }

                      _syncCountsIfNeeded(user, catalog);
                      final previewTotal = seedTotalFromCounts(
                        _counts,
                        catalog.seeds,
                      );
                      final categoryTotals = _buildCategoryTotals(catalog);

                      return _Panel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _PanelHeading(
                              eyebrow: '참여자 정보',
                              title: '시드 보유 현황',
                              trailing: _SummaryBadge(
                                label: '현재 합계',
                                value: '$previewTotal SEED',
                                color: _AdminPalette.teal,
                                background: _AdminPalette.tealSoft,
                              ),
                            ),
                            const SizedBox(height: 18),
                            _AdaptiveWrap(
                              minChildWidth: 170,
                              maxColumns: 4,
                              children: [
                                _ProfileChip(label: '이름', value: user.nickname),
                                _ProfileChip(
                                  label: '휴대폰 번호',
                                  value: user.phoneNumber,
                                ),
                                _ProfileChip(
                                  label: '참여 인원',
                                  value: '${user.participantCount}명',
                                ),
                                _ProfileChip(
                                  label: '최근 제출',
                                  value: _formatDate(user.lastSubmittedAt),
                                ),
                              ],
                            ),
                            if (categoryTotals.isNotEmpty) ...[
                              const SizedBox(height: 18),
                              const _SectionBlockTitle(
                                title: '카테고리별 합계',
                                description: '적립 횟수와 부스별 기본 시드값을 곱한 결과입니다.',
                              ),
                              const SizedBox(height: 12),
                              _AdaptiveWrap(
                                minChildWidth: 150,
                                maxColumns: 3,
                                children: categoryTotals
                                    .map(
                                      (item) => _ProfileChip(
                                        label: item.name,
                                        value: '${item.total} SEED',
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                            const SizedBox(height: 24),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                FilledButton.icon(
                                  onPressed: _saving ? null : _save,
                                  icon: const Icon(Icons.save_rounded),
                                  label: Text(_saving ? '저장 중...' : '시드 수량 저장'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: _saving
                                      ? null
                                      : () {
                                          setState(() {
                                            _dirty = false;
                                            _loadedStamp = null;
                                          });
                                        },
                                  icon: const Icon(Icons.refresh_rounded),
                                  label: const Text('다시 불러오기'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            if (catalog.seeds.isEmpty)
                              const _EmptyState(
                                message: '등록된 부스가 없습니다. 먼저 부스를 추가해주세요.',
                              )
                            else
                              Column(
                                children: catalog.seedsByCategory.entries.map((
                                  entry,
                                ) {
                                  final categoryName =
                                      catalog.categories
                                          .where(
                                            (category) =>
                                                category.uid == entry.key,
                                          )
                                          .map((category) => category.name)
                                          .firstOrNull ??
                                      entry.value.first.categoryName;
                                  final categoryTotal = entry.value.fold<int>(
                                    0,
                                    (sum, seed) =>
                                        sum +
                                        ((_counts[seed.uid] ?? 0) *
                                            seed.seedValue),
                                  );

                                  return _SeedCategoryEditorBlock(
                                    title: categoryName,
                                    total: categoryTotal,
                                    children: entry.value.map((seed) {
                                      final count = _counts[seed.uid] ?? 0;
                                      return _SeedEditorRow(
                                        seed: seed,
                                        count: count,
                                        maxCount: user.participantCount < 1
                                            ? 1
                                            : user.participantCount,
                                        onDecrease: () =>
                                            _changeCount(seed.uid, count - 1),
                                        onIncrease: () =>
                                            _changeCount(seed.uid, count + 1),
                                      );
                                    }).toList(),
                                  );
                                }).toList(),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );

              if (stacked) {
                return Column(
                  children: [
                    lookupPanel,
                    const SizedBox(height: 20),
                    profilePanel,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 4, child: lookupPanel),
                  const SizedBox(width: 20),
                  Expanded(flex: 7, child: profilePanel),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  List<({String name, int total})> _buildCategoryTotals(SeedCatalog catalog) {
    final items = <({String name, int total})>[];
    for (final entry in catalog.seedsByCategory.entries) {
      final total = entry.value.fold<int>(
        0,
        (sum, seed) => sum + ((_counts[seed.uid] ?? 0) * seed.seedValue),
      );
      if (total <= 0) continue;
      items.add((name: entry.value.first.categoryName, total: total));
    }
    return items;
  }
}

class _AdminBackdrop extends StatelessWidget {
  const _AdminBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.92, -0.88),
              radius: 0.42,
              colors: [
                const Color(0xFFFCE0BC).withValues(alpha: 0.92),
                Colors.transparent,
              ],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.88, -0.82),
              radius: 0.30,
              colors: [
                const Color(0xFF87DED1).withValues(alpha: 0.42),
                Colors.transparent,
              ],
            ),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _AdminPalette.bg,
                Color(0xFFFBF7F2),
                _AdminPalette.bgDeep,
              ],
              stops: [0, 0.38, 1],
            ),
          ),
        ),
        const IgnorePointer(child: CustomPaint(painter: _GridPainter())),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const gap = 48.0;
    final paint = Paint()
      ..color = const Color(0xFF2F241A).withValues(alpha: 0.025)
      ..strokeWidth = 1;

    for (double y = 0; y <= size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (double x = 0; x <= size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AdminTopbar extends StatelessWidget {
  const _AdminTopbar({required this.currentIndex, required this.onSelect});

  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x1A704E30)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14542E12),
            blurRadius: 50,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 920;
          return Flex(
            direction: compact ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: compact
                ? CrossAxisAlignment.stretch
                : CrossAxisAlignment.center,
            children: [
              _BrandMark(onTap: () => onSelect(0)),
              if (compact) const SizedBox(height: 12) else const Spacer(),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.end,
                children: _navItems.map((item) {
                  return _TopbarLink(
                    label: item.label,
                    icon: item.icon,
                    selected: currentIndex == item.index,
                    onTap: () => onSelect(item.index),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFD55A2A), Color(0xFFF0A73E)],
                ),
              ),
              child: const Text(
                'CB',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Festival Admin',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: _AdminPalette.ink,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '실시간 운영 대시보드',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _AdminPalette.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopbarLink extends StatelessWidget {
  const _TopbarLink({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? _AdminPalette.accent.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected
                    ? _AdminPalette.accentStrong
                    : _AdminPalette.muted,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? _AdminPalette.accentStrong
                      : _AdminPalette.muted,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeHero extends StatelessWidget {
  const _HomeHero({required this.onSelect});

  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: const EdgeInsets.all(28),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final titleSize = constraints.maxWidth < 560 ? 30.0 : 40.0;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Eyebrow('운영 대시보드'),
              const SizedBox(height: 12),
              Text(
                '축제 운영 흐름을\n한 화면에서 관리하세요',
                style: TextStyle(
                  fontSize: titleSize,
                  height: 1.02,
                  fontWeight: FontWeight.w900,
                  color: _AdminPalette.ink,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '참가자 등록, 부스 관리, 강조 사용자 전환, 시드 수동 조정까지 '
                '운영에 필요한 작업을 현재 상태 기준으로 빠르게 이어갈 수 있습니다.',
                style: TextStyle(
                  height: 1.55,
                  color: _AdminPalette.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 22),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: () => onSelect(1),
                    icon: const Icon(Icons.groups_rounded),
                    label: const Text('유저 정보 조회'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => onSelect(2),
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    label: const Text('인원 추가'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => onSelect(3),
                    icon: const Icon(Icons.storefront_rounded),
                    label: const Text('카테고리 및 부스 등록'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => onSelect(4),
                    icon: const Icon(Icons.tune_rounded),
                    label: const Text('시드 수량 변경'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HomeStatStack extends StatelessWidget {
  const _HomeStatStack({required this.service});

  final FestivalFirestoreService service;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        StreamBuilder<HighlightedUser?>(
          stream: service.watchHighlightedUser(),
          builder: (context, snapshot) {
            final user = snapshot.data;
            return _StatCard(
              label: '현재 강조 유저',
              value: user?.nickname ?? '선택 없음',
              helper: user == null
                  ? 'display live 대기 중'
                  : '보유 시드 ${user.seedCount}개',
            );
          },
        ),
        const SizedBox(height: 14),
        StreamBuilder<int>(
          stream: service.watchTotalSeedCount(),
          builder: (context, snapshot) {
            return _StatCard(
              label: '전체 시드 합계',
              value: '${snapshot.data ?? 0}',
              helper: '부스별 시드값 가중 합계 기준',
            );
          },
        ),
        const SizedBox(height: 14),
        StreamBuilder<List<FestivalUser>>(
          stream: service.watchUsers(),
          builder: (context, snapshot) {
            return _StatCard(
              label: '등록 유저 수',
              value: '${snapshot.data?.length ?? 0}',
              helper: 'Firestore 실시간 스트림 반영',
            );
          },
        ),
      ],
    );
  }
}

class _FeaturePanel extends StatelessWidget {
  const _FeaturePanel({required this.onSelect});

  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final items =
        <
          ({
            int index,
            IconData icon,
            String kicker,
            String title,
            String description,
          })
        >[
          (
            index: 1,
            icon: Icons.groups_rounded,
            kicker: '조회',
            title: '유저 정보 조회',
            description: '최근 제출 상태와 연락처, 누적 시드를 한 화면에서 확인합니다.',
          ),
          (
            index: 2,
            icon: Icons.person_add_alt_1_rounded,
            kicker: '등록',
            title: '인원 추가',
            description: '기본 정보와 중복 여부를 확인한 뒤 바로 참가자를 등록합니다.',
          ),
          (
            index: 3,
            icon: Icons.storefront_rounded,
            kicker: '마스터',
            title: '부스 등록',
            description: '카테고리와 부스를 추가하고 기본 시드값을 설정합니다.',
          ),
          (
            index: 4,
            icon: Icons.tune_rounded,
            kicker: '조정',
            title: '시드 수량 변경',
            description: '참가자별 부스 적립 횟수를 조회 후 저장합니다.',
          ),
        ];

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelHeading(eyebrow: '바로 가기', title: '자주 쓰는 화면'),
          const SizedBox(height: 18),
          _AdaptiveWrap(
            maxColumns: 2,
            minChildWidth: 280,
            children: items.map((item) {
              return _FeatureCard(
                icon: item.icon,
                kicker: item.kicker,
                title: item.title,
                description: item.description,
                onTap: () => onSelect(item.index),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _RecentUsersPanel extends StatelessWidget {
  const _RecentUsersPanel({required this.service});

  final FestivalFirestoreService service;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelHeading(eyebrow: '최근 제출', title: '가장 최근에 반영된 참가자'),
          const SizedBox(height: 18),
          StreamBuilder<List<FestivalUser>>(
            stream: service.watchSubmittedUsers(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _EmptyState(message: '${snapshot.error}');
              }
              if (!snapshot.hasData) {
                return const _LoadingState(message: '최근 제출 목록을 불러오는 중입니다.');
              }
              final users = snapshot.data!;
              if (users.isEmpty) {
                return const _EmptyState(message: '아직 제출된 참가자 정보가 없습니다.');
              }
              return Column(
                children: users.take(5).map((user) {
                  return _RecentUserCard(user: user);
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PageScrollView extends StatelessWidget {
  const _PageScrollView({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(padding: const EdgeInsets.only(bottom: 24), child: child),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.padding = const EdgeInsets.all(24)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: _AdminPalette.panel,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _AdminPalette.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x235A3214),
            blurRadius: 80,
            offset: Offset(0, 24),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.actionIcon,
    required this.onAction,
  });

  final String eyebrow;
  final String title;
  final String description;
  final String actionLabel;
  final IconData actionIcon;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 760;
          final titleSize = constraints.maxWidth < 560 ? 28.0 : 34.0;
          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Eyebrow(eyebrow),
              const SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: titleSize,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                  color: _AdminPalette.ink,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                description,
                style: const TextStyle(
                  color: _AdminPalette.muted,
                  height: 1.55,
                ),
              ),
            ],
          );
          final button = OutlinedButton.icon(
            onPressed: onAction,
            icon: Icon(actionIcon),
            label: Text(actionLabel),
          );

          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                content,
                const SizedBox(height: 16),
                SizedBox(width: double.infinity, child: button),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: content),
              const SizedBox(width: 20),
              button,
            ],
          );
        },
      ),
    );
  }
}

class _PanelHeading extends StatelessWidget {
  const _PanelHeading({
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String eyebrow;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = trailing != null && constraints.maxWidth < 760;
        final heading = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Eyebrow(eyebrow),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: _AdminPalette.ink,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                style: const TextStyle(
                  color: _AdminPalette.muted,
                  height: 1.5,
                  fontSize: 20,
                ),
              ),
            ],
          ],
        );

        if (trailing == null) {
          return heading;
        }

        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [heading, const SizedBox(height: 16), trailing!],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: heading),
            const SizedBox(width: 20),
            Flexible(child: trailing!),
          ],
        );
      },
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: _AdminPalette.accentStrong,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.helper,
  });

  final String label;
  final String value;
  final String helper;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _AdminPalette.accentStrong,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: _AdminPalette.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            helper,
            style: const TextStyle(color: _AdminPalette.muted, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.kicker,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String kicker;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.64),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0x1A704E30)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: _AdminPalette.accentStrong),
              const SizedBox(height: 14),
              Text(
                kicker,
                style: const TextStyle(
                  color: _AdminPalette.accentStrong,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: _AdminPalette.ink,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(
                  color: _AdminPalette.muted,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentUserCard extends StatelessWidget {
  const _RecentUserCard({required this.user});

  final FestivalUser user;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.60),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x1A704E30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            user.nickname,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: _AdminPalette.ink,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetaText(text: user.phoneNumber),
              _MetaText(text: '${user.seedCount} SEED'),
              _MetaText(text: _formatDate(user.lastSubmittedAt)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaText extends StatelessWidget {
  const _MetaText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: _AdminPalette.muted,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _ToolbarField extends StatelessWidget {
  const _ToolbarField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: _AdminPalette.ink,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _UsersTable extends StatelessWidget {
  const _UsersTable({required this.users, required this.onHighlight});

  final List<FestivalUser> users;
  final ValueChanged<FestivalUser> onHighlight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = math.max(constraints.maxWidth, 1280.0);

        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0x1A704E30)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: tableWidth),
              child: DataTable(
                dataRowMinHeight: 72,
                dataRowMaxHeight: 72,
                headingRowHeight: 54,
                columnSpacing: 24,
                horizontalMargin: 18,
                headingRowColor: WidgetStatePropertyAll(
                  const Color(0xFFF6EEE2).withValues(alpha: 0.96),
                ),
                columns: const [
                  DataColumn(label: Text('상태')),
                  DataColumn(label: Text('닉네임')),
                  DataColumn(label: Text('UID')),
                  DataColumn(label: Text('휴대폰 번호')),
                  DataColumn(label: Text('성별')),
                  DataColumn(label: Text('연령')),
                  DataColumn(label: Text('참여인원')),
                  DataColumn(label: Text('거주정보')),
                  DataColumn(label: Text('총 시드')),
                  DataColumn(label: Text('최근 제출')),
                ],
                rows: users.map((user) {
                  final canHighlight = user.lastSubmittedAt != null;
                  return DataRow(
                    color: WidgetStatePropertyAll(
                      user.isHighlighted
                          ? _AdminPalette.accent.withValues(alpha: 0.08)
                          : Colors.transparent,
                    ),
                    cells: [
                      DataCell(
                        _StatusBadge(
                          label: user.isHighlighted ? 'LIVE' : '대기',
                          highlighted: user.isHighlighted,
                        ),
                      ),
                      DataCell(Text(user.nickname)),
                      DataCell(
                        SelectableText(
                          user.uid,
                          style: const TextStyle(
                            color: _AdminPalette.ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      DataCell(
                        ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 156),
                          child: TextButton.icon(
                            onPressed: canHighlight
                                ? () => onHighlight(user)
                                : null,
                            icon: const Icon(Icons.campaign_outlined, size: 16),
                            label: Text(
                              user.phoneNumber,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: canHighlight
                                  ? _AdminPalette.teal
                                  : _AdminPalette.muted,
                              backgroundColor: canHighlight
                                  ? _AdminPalette.tealSoft
                                  : const Color(0xFFE8E0D5),
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                      ),
                      DataCell(Text(_displayGender(user))),
                      DataCell(Text(_displayAge(user))),
                      DataCell(Text('${user.participantCount}명')),
                      DataCell(Text(_displayResidence(user))),
                      DataCell(Text('${user.seedCount}')),
                      DataCell(Text(_formatDate(user.lastSubmittedAt))),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LiveBanner extends StatelessWidget {
  const _LiveBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(
            color: const Color(0xFF62B86B),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF62B86B).withValues(alpha: 0.24),
                blurRadius: 0,
                spreadRadius: 7,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: _AdminPalette.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ResponsiveFields extends StatelessWidget {
  const _ResponsiveFields({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 16.0;
        final columns = constraints.maxWidth >= 980
            ? 3
            : constraints.maxWidth >= 620
            ? 2
            : 1;
        final width = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - (gap * (columns - 1))) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: children
              .map((child) => SizedBox(width: width, child: child))
              .toList(),
        );
      },
    );
  }
}

class _FormFieldBlock extends StatelessWidget {
  const _FormFieldBlock({
    required this.label,
    required this.helper,
    required this.child,
  });

  final String label;
  final String helper;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: _AdminPalette.ink,
          ),
        ),
        const SizedBox(height: 8),
        child,
        const SizedBox(height: 8),
        Text(
          helper,
          style: const TextStyle(
            color: _AdminPalette.muted,
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _ChoiceCardGroup extends StatelessWidget {
  const _ChoiceCardGroup({
    required this.title,
    required this.description,
    required this.columns,
    required this.options,
    required this.selected,
    required this.detailBuilder,
    required this.onSelected,
  });

  final String title;
  final String description;
  final int columns;
  final List<FestivalSelectOption> options;
  final int selected;
  final String Function(FestivalSelectOption option) detailBuilder;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionBlockTitle(title: title, description: description),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 14.0;
            final resolvedColumns = constraints.maxWidth >= 920
                ? columns
                : constraints.maxWidth >= 620
                ? math.min(columns, 2)
                : 1;
            final width = resolvedColumns == 1
                ? constraints.maxWidth
                : (constraints.maxWidth - (gap * (resolvedColumns - 1))) /
                      resolvedColumns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: options.map((option) {
                final isSelected = option.value == selected;
                return SizedBox(
                  width: width,
                  child: _ChoiceCard(
                    title: option.label,
                    detail: detailBuilder(option),
                    selected: isSelected,
                    onTap: () => onSelected(option.value),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _SectionBlockTitle extends StatelessWidget {
  const _SectionBlockTitle({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: _AdminPalette.ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          description,
          style: const TextStyle(color: _AdminPalette.muted, height: 1.45),
        ),
      ],
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.title,
    required this.detail,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String detail;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFFFF0E8)
                : Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected
                  ? _AdminPalette.accent.withValues(alpha: 0.42)
                  : const Color(0x1A704E30),
            ),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x24D55A2A),
                      blurRadius: 30,
                      offset: Offset(0, 12),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: selected
                      ? _AdminPalette.accentStrong
                      : _AdminPalette.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                detail,
                style: const TextStyle(
                  color: _AdminPalette.muted,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  const _ChecklistItem(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.check_circle_rounded,
              size: 18,
              color: _AdminPalette.accentStrong,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: _AdminPalette.muted, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.message, required this.tone});

  final String message;
  final _NoticeTone tone;

  @override
  Widget build(BuildContext context) {
    Color background;
    Color border;

    switch (tone) {
      case _NoticeTone.success:
        background = const Color(0xDDE2F5E5);
        border = const Color(0x3D2D8551);
        break;
      case _NoticeTone.error:
        background = const Color(0xDFFFF0EB);
        border = const Color(0x40B34226);
        break;
      case _NoticeTone.neutral:
        background = Colors.white.withValues(alpha: 0.64);
        border = const Color(0x1F704E30);
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Text(
        message,
        style: const TextStyle(color: _AdminPalette.ink, height: 1.45),
      ),
    );
  }
}

class _CatalogCategoryCard extends StatelessWidget {
  const _CatalogCategoryCard({
    required this.title,
    required this.countLabel,
    required this.children,
    this.onDeleteCategory,
  });

  final String title;
  final String countLabel;
  final List<Widget> children;
  final VoidCallback? onDeleteCategory;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x1A704E30)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 520;
          final actions = <Widget>[
            _SummaryBadge(
              label: '',
              value: countLabel,
              color: _AdminPalette.accentStrong,
              background: _AdminPalette.accentSoft,
            ),
            if (onDeleteCategory != null)
              IconButton(
                tooltip: '카테고리 삭제',
                onPressed: onDeleteCategory,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
          ];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (stacked)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: _AdminPalette.ink,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(spacing: 10, runSpacing: 10, children: actions),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: _AdminPalette.ink,
                        ),
                      ),
                    ),
                    ...actions,
                  ],
                ),
              const SizedBox(height: 14),
              ...children,
            ],
          );
        },
      ),
    );
  }
}

class _CatalogSeedRow extends StatelessWidget {
  const _CatalogSeedRow({required this.seed, required this.onDelete});

  final SeedItem seed;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x14704E30)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 520;
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                seed.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: _AdminPalette.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'UID: ${seed.uid}',
                style: const TextStyle(
                  color: _AdminPalette.muted,
                  fontSize: 12,
                ),
              ),
            ],
          );
          final actions = Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _SummaryBadge(
                label: '',
                value: '${seed.seedValue} SEED',
                color: _AdminPalette.teal,
                background: _AdminPalette.tealSoft,
              ),
              IconButton(
                tooltip: '부스 삭제',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          );

          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [copy, const SizedBox(height: 12), actions],
            );
          }

          return Row(
            children: [
              Expanded(child: copy),
              const SizedBox(width: 16),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _InlineEmptyState extends StatelessWidget {
  const _InlineEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.54),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x14704E30)),
      ),
      child: Text(message, style: const TextStyle(color: _AdminPalette.muted)),
    );
  }
}

class _SummaryBadge extends StatelessWidget {
  const _SummaryBadge({
    required this.label,
    required this.value,
    required this.color,
    required this.background,
  });

  final String label;
  final String value;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(color: color),
          children: [
            TextSpan(
              text: '$label ',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileChip extends StatelessWidget {
  const _ProfileChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x1A704E30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _AdminPalette.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: _AdminPalette.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdaptiveWrap extends StatelessWidget {
  const _AdaptiveWrap({
    required this.children,
    this.maxColumns = 4,
    this.minChildWidth = 160,
  });

  final List<Widget> children;
  final int maxColumns;
  final double minChildWidth;

  @override
  Widget build(BuildContext context) {
    const spacing = 12.0;
    const runSpacing = 12.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        if (!maxWidth.isFinite || maxWidth <= 0) {
          return Wrap(
            spacing: spacing,
            runSpacing: runSpacing,
            children: children,
          );
        }

        var columns = math.max(1, maxColumns);
        while (columns > 1) {
          final candidateWidth =
              (maxWidth - (spacing * (columns - 1))) / columns;
          if (candidateWidth >= minChildWidth) {
            break;
          }
          columns -= 1;
        }

        final itemWidth = columns == 1
            ? maxWidth
            : (maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: children
              .map((child) => SizedBox(width: itemWidth, child: child))
              .toList(),
        );
      },
    );
  }
}

class _SeedCategoryEditorBlock extends StatelessWidget {
  const _SeedCategoryEditorBlock({
    required this.title,
    required this.total,
    required this.children,
  });

  final String title;
  final int total;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.60),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x1A704E30)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 520;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (stacked)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: _AdminPalette.ink,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SummaryBadge(
                      label: '합계',
                      value: '$total SEED',
                      color: _AdminPalette.teal,
                      background: _AdminPalette.tealSoft,
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: _AdminPalette.ink,
                        ),
                      ),
                    ),
                    _SummaryBadge(
                      label: '합계',
                      value: '$total SEED',
                      color: _AdminPalette.teal,
                      background: _AdminPalette.tealSoft,
                    ),
                  ],
                ),
              const SizedBox(height: 14),
              ...children,
            ],
          );
        },
      ),
    );
  }
}

class _SeedEditorRow extends StatelessWidget {
  const _SeedEditorRow({
    required this.seed,
    required this.count,
    required this.maxCount,
    required this.onDecrease,
    required this.onIncrease,
  });

  final SeedItem seed;
  final int count;
  final int maxCount;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    final total = count * seed.seedValue;
    final maxTotal = maxCount * seed.seedValue;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.80),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x14704E30)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 640;
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                seed.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: _AdminPalette.ink,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  _MetaText(text: '1회 적립 시 ${seed.seedValue}SEED'),
                  _MetaText(text: '현재 총 ${total}SEED / 최대 ${maxTotal}SEED'),
                ],
              ),
            ],
          );
          final stepper = _SeedStepper(
            count: count,
            maxCount: maxCount,
            onDecrease: onDecrease,
            onIncrease: onIncrease,
          );

          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [copy, const SizedBox(height: 14), stepper],
            );
          }

          return Row(
            children: [
              Expanded(child: copy),
              const SizedBox(width: 16),
              stepper,
            ],
          );
        },
      ),
    );
  }
}

class _SeedStepper extends StatelessWidget {
  const _SeedStepper({
    required this.count,
    required this.maxCount,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int count;
  final int maxCount;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepperButton(
          tooltip: '감소',
          icon: Icons.remove_rounded,
          onPressed: count > 0 ? onDecrease : null,
        ),
        Container(
          width: 68,
          height: 48,
          alignment: Alignment.center,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x1A704E30)),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: _AdminPalette.ink,
            ),
          ),
        ),
        _StepperButton(
          tooltip: '증가',
          icon: Icons.add_rounded,
          onPressed: count < maxCount ? onIncrease : null,
        ),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton.filledTonal(
        onPressed: onPressed,
        icon: Icon(icon),
        style: IconButton.styleFrom(
          backgroundColor: _AdminPalette.accentSoft,
          foregroundColor: _AdminPalette.accentStrong,
          disabledBackgroundColor: const Color(0xFFEDE6DE),
          disabledForegroundColor: const Color(0xFFAF9B88),
          fixedSize: const Size(48, 48),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.highlighted});

  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: highlighted ? _AdminPalette.accentSoft : const Color(0x1F6B5A4C),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: highlighted ? _AdminPalette.accentStrong : _AdminPalette.muted,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 180),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x2E704E30)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: _AdminPalette.muted, height: 1.5),
      ),
    );
  }
}

class _LargeEmptyState extends StatelessWidget {
  const _LargeEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 260),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x2E704E30)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: _AdminPalette.muted, height: 1.5),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _AdminPalette.accent,
            ),
          ),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: _AdminPalette.muted)),
        ],
      ),
    );
  }
}

class _AdminPalette {
  static const bg = Color(0xFFF6F1E8);
  static const bgDeep = Color(0xFFEFE4D5);
  static const panel = Color(0xD6FFFAF2);
  static const line = Color(0x24703921);
  static const ink = Color(0xFF2F241A);
  static const muted = Color(0xFF6B5A4C);
  static const accent = Color(0xFFD55A2A);
  static const accentSoft = Color(0xFFFFE2D5);
  static const accentStrong = Color(0xFF8E3517);
  static const teal = Color(0xFF0F7C7B);
  static const tealSoft = Color(0xFFD6F2EF);
}

class _AdminNavItem {
  const _AdminNavItem({
    required this.index,
    required this.label,
    required this.icon,
  });

  final int index;
  final String label;
  final IconData icon;
}

enum _NoticeTone { neutral, success, error }

InputDecoration _inputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.80),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: _AdminPalette.line),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: _AdminPalette.line),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: _AdminPalette.accentStrong),
    ),
  );
}

String _displayGender(FestivalUser user) {
  if (user.genderLabel.trim().isNotEmpty && user.genderLabel != '-') {
    return user.genderLabel;
  }
  return _labelFromCode(_genderChoices, user.gender);
}

String _displayAge(FestivalUser user) {
  if (user.ageGroupLabel.trim().isNotEmpty && user.ageGroupLabel != '-') {
    return user.ageGroupLabel;
  }
  return _labelFromCode(_ageChoices, user.ageGroup);
}

String _displayResidence(FestivalUser user) {
  if (user.residenceLabel.trim().isNotEmpty && user.residenceLabel != '-') {
    return user.residenceLabel;
  }
  return _labelFromCode(_residenceChoices, user.residence);
}

String _labelFromCode(List<FestivalSelectOption> options, int code) {
  for (final option in options) {
    if (option.value == code) return option.label;
  }
  return '-';
}

String _formatDate(DateTime? value) {
  if (value == null) return '미제출';
  return DateFormat('yyyy. M. d. HH:mm', 'ko_KR').format(value);
}

void _showSnack(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: isError ? const Color(0xFF8A3B34) : _AdminPalette.ink,
      content: Text(message),
    ),
  );
}

Future<bool?> _confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
}
