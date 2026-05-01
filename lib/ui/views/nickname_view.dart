import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:greenfestival/routes/app_pages.dart';
import 'package:greenfestival/ui/controllers/survey_controller.dart';
import 'package:greenfestival/ui/widgets/festival_page_title.dart';
import 'package:greenfestival/ui/widgets/start_over_button.dart';

enum _KeyboardMode { korean, english, symbols }

class NicknameView extends StatefulWidget {
  const NicknameView({super.key});

  @override
  State<NicknameView> createState() => _NicknameViewState();
}

class _NicknameViewState extends State<NicknameView> {
  final SurveyController _surveyController = Get.find<SurveyController>();
  final List<String> _tokens = [];

  _KeyboardMode _mode = _KeyboardMode.korean;
  bool _shifted = false;
  String _nickname = '';
  bool _checkingNickname = false;

  @override
  void initState() {
    super.initState();
    final savedNickname = _surveyController.nickname.value;
    if (savedNickname.isNotEmpty) {
      _tokens.addAll(savedNickname.characters);
      _nickname = savedNickname;
    }
  }

  void _insert(String value) {
    setState(() {
      _tokens.add(value);
      _nickname = _composeHangul(_tokens);
    });
  }

  void _delete() {
    if (_tokens.isEmpty) return;

    setState(() {
      _tokens.removeLast();
      _nickname = _composeHangul(_tokens);
    });
  }

  void _setMode(_KeyboardMode mode) {
    setState(() {
      _mode = mode;
      _shifted = false;
    });
  }

  void _toggleShift() {
    setState(() => _shifted = !_shifted);
  }

  Future<void> _complete() async {
    if (_checkingNickname) return;

    final nickname = _nickname.trim();
    if (nickname.isEmpty) {
      Get.snackbar(
        '닉네임 입력',
        '축제에 참여할 닉네임을 입력해 주세요.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    setState(() => _checkingNickname = true);
    try {
      final duplicated = await _surveyController.isNicknameDuplicated(nickname);
      if (!mounted) return;

      if (duplicated) {
        Get.snackbar(
          '닉네임 중복',
          '이미 사용 중인 닉네임입니다. 다른 닉네임을 입력해주세요.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
        return;
      }

      _surveyController.startSurveyWithNickname(nickname);
      Get.toNamed(AppPages.GENDER);
    } catch (error) {
      if (!mounted) return;
      Get.snackbar(
        '닉네임 확인 실패',
        '$error',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } finally {
      if (mounted) {
        setState(() => _checkingNickname = false);
      }
    }
  }

  List<List<String>> get _letterRows {
    switch (_mode) {
      case _KeyboardMode.korean:
        return _shifted
            ? const [
                ['ㅃ', 'ㅉ', 'ㄸ', 'ㄲ', 'ㅆ', 'ㅛ', 'ㅕ', 'ㅑ', 'ㅒ', 'ㅖ'],
                ['ㅁ', 'ㄴ', 'ㅇ', 'ㄹ', 'ㅎ', 'ㅗ', 'ㅓ', 'ㅏ', 'ㅣ'],
                ['ㅋ', 'ㅌ', 'ㅊ', 'ㅍ', 'ㅠ', 'ㅜ', 'ㅡ'],
              ]
            : const [
                ['ㅂ', 'ㅈ', 'ㄷ', 'ㄱ', 'ㅅ', 'ㅛ', 'ㅕ', 'ㅑ', 'ㅐ', 'ㅔ'],
                ['ㅁ', 'ㄴ', 'ㅇ', 'ㄹ', 'ㅎ', 'ㅗ', 'ㅓ', 'ㅏ', 'ㅣ'],
                ['ㅋ', 'ㅌ', 'ㅊ', 'ㅍ', 'ㅠ', 'ㅜ', 'ㅡ'],
              ];
      case _KeyboardMode.english:
        return _shifted
            ? const [
                ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
                ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
                ['Z', 'X', 'C', 'V', 'B', 'N', 'M'],
              ]
            : const [
                ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'],
                ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'],
                ['z', 'x', 'c', 'v', 'b', 'n', 'm'],
              ];
      case _KeyboardMode.symbols:
        return const [
          ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'],
          ['-', '/', ':', ';', '(', ')', '₩', '&', '@', '"'],
          ['.', ',', '?', '!', '\'', '#', '%'],
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          final contentWidth = (width * 0.56).clamp(420.0, 760.0);
          final titleTopGap = FestivalPageTitle.topGap(height);
          final inputHeight = (height * 0.086).clamp(60.0, 78.0);
          final keyboardTopGap = (height * 0.034).clamp(18.0, 30.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/images/background.png',
                fit: BoxFit.fill,
                filterQuality: FilterQuality.high,
              ),
              SafeArea(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.only(top: titleTopGap, bottom: 92),
                    child: Column(
                      children: [
                        const FestivalPageTitle('축제에 참여할 닉네임을 입력해 주세요.'),
                        SizedBox(height: (height * 0.03).clamp(14.0, 24.0)),
                        _NicknameInput(
                          width: contentWidth,
                          height: inputHeight,
                          nickname: _nickname,
                        ),
                        SizedBox(height: keyboardTopGap),
                        _NicknameKeyboard(
                          width: contentWidth,
                          rows: _letterRows,
                          mode: _mode,
                          shifted: _shifted,
                          onText: _insert,
                          onBackspace: _delete,
                          onShift: _toggleShift,
                          onSymbols: () {
                            if (_mode == _KeyboardMode.symbols) {
                              _setMode(_KeyboardMode.korean);
                            } else {
                              _setMode(_KeyboardMode.symbols);
                            }
                          },
                          onGlobe: () => _setMode(
                            _mode == _KeyboardMode.english
                                ? _KeyboardMode.korean
                                : _KeyboardMode.english,
                          ),
                          onSpace: () => _insert(' '),
                          onComplete: () {
                            _complete();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Positioned(
                left: 18,
                bottom: 18,
                child: SafeArea(child: StartOverButton()),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NicknameInput extends StatelessWidget {
  const _NicknameInput({
    required this.width,
    required this.height,
    required this.nickname,
  });

  final double width;
  final double height;
  final String nickname;

  @override
  Widget build(BuildContext context) {
    final hasNickname = nickname.trim().isNotEmpty;

    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.sentiment_satisfied_alt_outlined,
            color: Color(0xFF9AA0A6),
            size: 36,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (hasNickname)
                  Flexible(
                    child: Text(
                      nickname,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ),
                Text(
                  '님',
                  maxLines: 1,
                  style: TextStyle(
                    color: hasNickname ? Colors.black : const Color(0xFF9A9A9A),
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NicknameKeyboard extends StatelessWidget {
  const _NicknameKeyboard({
    required this.width,
    required this.rows,
    required this.mode,
    required this.shifted,
    required this.onText,
    required this.onBackspace,
    required this.onShift,
    required this.onSymbols,
    required this.onGlobe,
    required this.onSpace,
    required this.onComplete,
  });

  final double width;
  final List<List<String>> rows;
  final _KeyboardMode mode;
  final bool shifted;
  final ValueChanged<String> onText;
  final VoidCallback onBackspace;
  final VoidCallback onShift;
  final VoidCallback onSymbols;
  final VoidCallback onGlobe;
  final VoidCallback onSpace;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final keySize = (width * 0.074).clamp(40.0, 52.0);
    final keyHeight = keySize * 1.12;
    final gap = (width * 0.009).clamp(4.0, 7.0);

    return Container(
      width: width,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: gap * 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _KeyRow(
            labels: rows[0],
            keySize: keySize,
            keyHeight: keyHeight,
            gap: gap,
            onText: onText,
          ),
          SizedBox(height: gap),
          _KeyRow(
            labels: rows[1],
            keySize: keySize,
            keyHeight: keyHeight,
            gap: gap,
            onText: onText,
          ),
          SizedBox(height: gap),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SpecialKey(
                width: keySize,
                height: keyHeight,
                gap: gap,
                active: shifted,
                child: mode == _KeyboardMode.symbols
                    ? const Text('#+=', style: _specialKeyTextStyle)
                    : const Icon(Icons.arrow_upward, size: 22),
                onTap: mode == _KeyboardMode.symbols
                    ? () => onText('+')
                    : onShift,
              ),
              ...rows[2].map(
                (label) => _TextKey(
                  label: label,
                  width: keySize,
                  height: keyHeight,
                  gap: gap,
                  onTap: () => onText(label),
                ),
              ),
              _SpecialKey(
                width: keySize,
                height: keyHeight,
                gap: gap,
                child: const Icon(Icons.backspace_outlined, size: 22),
                onTap: onBackspace,
              ),
            ],
          ),
          SizedBox(height: gap),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SpecialKey(
                width: keySize,
                height: keyHeight,
                gap: gap,
                child: Text('123', style: _specialKeyTextStyle),
                onTap: onSymbols,
              ),
              _SpecialKey(
                width: keySize,
                height: keyHeight,
                gap: gap,
                child: const Icon(Icons.language, size: 23),
                onTap: onGlobe,
              ),
              _SpecialKey(
                width: keySize * 4.42,
                height: keyHeight,
                gap: gap,
                backgroundColor: Colors.white,
                child: const Text('space', style: _spaceKeyTextStyle),
                onTap: onSpace,
              ),
              _SpecialKey(
                width: keySize * 2.05,
                height: keyHeight,
                gap: gap,
                backgroundColor: const Color(0xFF4A9638),
                foregroundColor: Colors.white,
                child: const Text('완료', style: _completeKeyTextStyle),
                onTap: onComplete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KeyRow extends StatelessWidget {
  const _KeyRow({
    required this.labels,
    required this.keySize,
    required this.keyHeight,
    required this.gap,
    required this.onText,
  });

  final List<String> labels;
  final double keySize;
  final double keyHeight;
  final double gap;
  final ValueChanged<String> onText;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: labels
          .map(
            (label) => _TextKey(
              label: label,
              width: keySize,
              height: keyHeight,
              gap: gap,
              onTap: () => onText(label),
            ),
          )
          .toList(),
    );
  }
}

class _TextKey extends StatelessWidget {
  const _TextKey({
    required this.label,
    required this.width,
    required this.height,
    required this.gap,
    required this.onTap,
  });

  final String label;
  final double width;
  final double height;
  final double gap;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SpecialKey(
      width: width,
      height: height,
      gap: gap,
      backgroundColor: Colors.white,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 27,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _SpecialKey extends StatelessWidget {
  const _SpecialKey({
    required this.width,
    required this.height,
    required this.gap,
    required this.child,
    required this.onTap,
    this.active = false,
    this.backgroundColor,
    this.foregroundColor = Colors.black,
  });

  final double width;
  final double height;
  final double gap;
  final Widget child;
  final VoidCallback onTap;
  final bool active;
  final Color? backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    final resolvedBackground =
        backgroundColor ??
        (active ? const Color(0xFF7C8798) : const Color(0xFFAEB6C4));

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: gap / 2),
      child: Material(
        color: resolvedBackground,
        borderRadius: BorderRadius.circular(3),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(3),
          child: Container(
            width: width,
            height: height,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: resolvedBackground,
              borderRadius: BorderRadius.circular(3),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  offset: Offset(0, 1),
                  blurRadius: 0,
                ),
              ],
            ),
            child: IconTheme(
              data: IconThemeData(color: foregroundColor),
              child: DefaultTextStyle.merge(
                style: TextStyle(color: foregroundColor),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const _specialKeyTextStyle = TextStyle(
  color: Colors.black,
  fontSize: 17,
  fontWeight: FontWeight.w600,
  height: 1,
);

const _spaceKeyTextStyle = TextStyle(
  color: Colors.black,
  fontSize: 18,
  fontWeight: FontWeight.w600,
  height: 1,
);

const _completeKeyTextStyle = TextStyle(
  color: Colors.white,
  fontSize: 19,
  fontWeight: FontWeight.w800,
  height: 1,
);

String _composeHangul(List<String> tokens) {
  final buffer = StringBuffer();
  String? initial;
  String? medial;
  String? finalConsonant;

  void flush() {
    if (initial != null && medial != null) {
      buffer.write(_makeSyllable(initial!, medial!, finalConsonant));
    } else {
      if (initial != null) buffer.write(initial);
      if (medial != null) buffer.write(medial);
      if (finalConsonant != null) buffer.write(finalConsonant);
    }

    initial = null;
    medial = null;
    finalConsonant = null;
  }

  for (final token in tokens) {
    final isConsonant = _leadingConsonants.contains(token);
    final isVowel = _medialVowels.contains(token);

    if (!isConsonant && !isVowel) {
      flush();
      buffer.write(token);
      continue;
    }

    if (isVowel) {
      if (initial == null) {
        if (medial == null) {
          medial = token;
        } else {
          final combinedVowel = _combineVowel(medial!, token);
          if (combinedVowel == null) {
            flush();
            medial = token;
          } else {
            medial = combinedVowel;
          }
        }
      } else if (medial == null) {
        medial = token;
      } else if (finalConsonant != null) {
        final split = _splitFinalConsonant(finalConsonant!);
        if (split == null) {
          buffer.write(_makeSyllable(initial!, medial!, null));
          initial = finalConsonant;
        } else {
          buffer.write(_makeSyllable(initial!, medial!, split.$1));
          initial = split.$2;
        }
        medial = token;
        finalConsonant = null;
      } else {
        final combinedVowel = _combineVowel(medial!, token);
        if (combinedVowel == null) {
          flush();
          medial = token;
        } else {
          medial = combinedVowel;
        }
      }
      continue;
    }

    if (initial == null) {
      if (medial == null) {
        initial = token;
      } else {
        flush();
        initial = token;
      }
    } else if (medial == null) {
      flush();
      initial = token;
    } else if (finalConsonant == null) {
      if (_finalConsonants.contains(token)) {
        finalConsonant = token;
      } else {
        flush();
        initial = token;
      }
    } else {
      final combinedFinal = _combineFinalConsonant(finalConsonant!, token);
      if (combinedFinal == null) {
        flush();
        initial = token;
      } else {
        finalConsonant = combinedFinal;
      }
    }
  }

  flush();
  return buffer.toString();
}

String _makeSyllable(String initial, String medial, String? finalConsonant) {
  final initialIndex = _leadingConsonants.indexOf(initial);
  final medialIndex = _medialVowels.indexOf(medial);
  final finalIndex = finalConsonant == null
      ? 0
      : _finalConsonants.indexOf(finalConsonant);

  if (initialIndex < 0 || medialIndex < 0 || finalIndex < 0) {
    return '$initial$medial${finalConsonant ?? ''}';
  }

  final codeUnit =
      0xAC00 + ((initialIndex * 21) + medialIndex) * 28 + finalIndex;
  return String.fromCharCode(codeUnit);
}

String? _combineVowel(String first, String second) {
  return _combinedVowels['$first$second'];
}

String? _combineFinalConsonant(String first, String second) {
  return _combinedFinalConsonants['$first$second'];
}

(String, String)? _splitFinalConsonant(String consonant) {
  return _splitFinalConsonants[consonant];
}

const _leadingConsonants = [
  'ㄱ',
  'ㄲ',
  'ㄴ',
  'ㄷ',
  'ㄸ',
  'ㄹ',
  'ㅁ',
  'ㅂ',
  'ㅃ',
  'ㅅ',
  'ㅆ',
  'ㅇ',
  'ㅈ',
  'ㅉ',
  'ㅊ',
  'ㅋ',
  'ㅌ',
  'ㅍ',
  'ㅎ',
];

const _medialVowels = [
  'ㅏ',
  'ㅐ',
  'ㅑ',
  'ㅒ',
  'ㅓ',
  'ㅔ',
  'ㅕ',
  'ㅖ',
  'ㅗ',
  'ㅘ',
  'ㅙ',
  'ㅚ',
  'ㅛ',
  'ㅜ',
  'ㅝ',
  'ㅞ',
  'ㅟ',
  'ㅠ',
  'ㅡ',
  'ㅢ',
  'ㅣ',
];

const _finalConsonants = [
  '',
  'ㄱ',
  'ㄲ',
  'ㄳ',
  'ㄴ',
  'ㄵ',
  'ㄶ',
  'ㄷ',
  'ㄹ',
  'ㄺ',
  'ㄻ',
  'ㄼ',
  'ㄽ',
  'ㄾ',
  'ㄿ',
  'ㅀ',
  'ㅁ',
  'ㅂ',
  'ㅄ',
  'ㅅ',
  'ㅆ',
  'ㅇ',
  'ㅈ',
  'ㅊ',
  'ㅋ',
  'ㅌ',
  'ㅍ',
  'ㅎ',
];

const _combinedVowels = {
  'ㅗㅏ': 'ㅘ',
  'ㅗㅐ': 'ㅙ',
  'ㅗㅣ': 'ㅚ',
  'ㅜㅓ': 'ㅝ',
  'ㅜㅔ': 'ㅞ',
  'ㅜㅣ': 'ㅟ',
  'ㅡㅣ': 'ㅢ',
};

const _combinedFinalConsonants = {
  'ㄱㅅ': 'ㄳ',
  'ㄴㅈ': 'ㄵ',
  'ㄴㅎ': 'ㄶ',
  'ㄹㄱ': 'ㄺ',
  'ㄹㅁ': 'ㄻ',
  'ㄹㅂ': 'ㄼ',
  'ㄹㅅ': 'ㄽ',
  'ㄹㅌ': 'ㄾ',
  'ㄹㅍ': 'ㄿ',
  'ㄹㅎ': 'ㅀ',
  'ㅂㅅ': 'ㅄ',
};

const _splitFinalConsonants = {
  'ㄳ': ('ㄱ', 'ㅅ'),
  'ㄵ': ('ㄴ', 'ㅈ'),
  'ㄶ': ('ㄴ', 'ㅎ'),
  'ㄺ': ('ㄹ', 'ㄱ'),
  'ㄻ': ('ㄹ', 'ㅁ'),
  'ㄼ': ('ㄹ', 'ㅂ'),
  'ㄽ': ('ㄹ', 'ㅅ'),
  'ㄾ': ('ㄹ', 'ㅌ'),
  'ㄿ': ('ㄹ', 'ㅍ'),
  'ㅀ': ('ㄹ', 'ㅎ'),
  'ㅄ': ('ㅂ', 'ㅅ'),
};
