import 'package:flutter/material.dart';

class OptionModel {
  final String id; // 고유 ID
  final String text; // 카드 제목
  final String? subtitle; // 부제목 or 설명
  final List<String>? subtitleList; // ✅ 여러 줄 bullet 형태 설명
  final String? imageUrl; // 이미지 경로
  final bool isSelected; // 선택 여부
  final bool isMultipleSelectable; // 다중 선택 여부
  final int? maxSelectable; // ✅ 선택 가능한 최대 개수

  // ===== 🧩 커스터마이징 속성 =====
  final double? fontSize; // 텍스트 크기
  final Color? textColor; // 텍스트 색상
  final FontWeight? fontWeight; // 폰트 굵기
  final Alignment? alignment; // 텍스트 정렬
  final EdgeInsets? padding; // 내부 여백
  final double? borderRadius; // 카드 모서리 라운드
  final Color? backgroundColor; // 배경색
  final double? imageHeight; // 이미지 높이 지정
  final BoxFit? imageFit; // 이미지 fit 방식
  final TextAlign? textAlign; // ✅ 텍스트 정렬 (왼쪽/가운데 등)

  const OptionModel({
    required this.id,
    required this.text,
    this.subtitle,
    this.subtitleList,
    this.imageUrl,
    this.isSelected = false,
    this.isMultipleSelectable = false,
    this.maxSelectable,
    this.fontSize,
    this.textColor,
    this.fontWeight,
    this.alignment,
    this.padding,
    this.borderRadius,
    this.backgroundColor,
    this.imageHeight,
    this.imageFit,
    this.textAlign,
  });

  /// ✅ copyWith (선택 상태 등 변경)
  OptionModel copyWith({
    bool? isSelected,
    double? fontSize,
    Color? textColor,
    FontWeight? fontWeight,
    Alignment? alignment,
    EdgeInsets? padding,
    double? borderRadius,
    Color? backgroundColor,
    double? imageHeight,
    BoxFit? imageFit,
    TextAlign? textAlign,
    bool? isMultipleSelectable,
    int? maxSelectable,
    List<String>? subtitleList,
  }) {
    return OptionModel(
      id: id,
      text: text,
      subtitle: subtitle,
      subtitleList: subtitleList ?? this.subtitleList,
      imageUrl: imageUrl,
      isSelected: isSelected ?? this.isSelected,
      isMultipleSelectable: isMultipleSelectable ?? this.isMultipleSelectable,
      maxSelectable: maxSelectable ?? this.maxSelectable,
      fontSize: fontSize ?? this.fontSize,
      textColor: textColor ?? this.textColor,
      fontWeight: fontWeight ?? this.fontWeight,
      alignment: alignment ?? this.alignment,
      padding: padding ?? this.padding,
      borderRadius: borderRadius ?? this.borderRadius,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      imageHeight: imageHeight ?? this.imageHeight,
      imageFit: imageFit ?? this.imageFit,
      textAlign: textAlign ?? this.textAlign,
    );
  }

  /// ✅ fromJson (Firestore나 서버 연동 대비)
  factory OptionModel.fromJson(Map<String, dynamic> json) => OptionModel(
    id: json['id'],
    text: json['text'],
    subtitle: json['subtitle'],
    subtitleList: json['subtitleList'] != null
        ? List<String>.from(json['subtitleList'])
        : null,
    imageUrl: json['imageUrl'],
    isMultipleSelectable: json['isMultipleSelectable'] ?? false,
    maxSelectable: json['maxSelectable'],
    fontSize: (json['fontSize'] as num?)?.toDouble(),
    textColor: json['textColor'] != null
        ? Color(int.parse(json['textColor']))
        : null,
    fontWeight: _parseFontWeight(json['fontWeight']),
    alignment: _parseAlignment(json['alignment']),
    padding: _parseEdgeInsets(json['padding']),
    borderRadius: (json['borderRadius'] as num?)?.toDouble(),
    backgroundColor: json['backgroundColor'] != null
        ? Color(int.parse(json['backgroundColor']))
        : null,
    imageHeight: (json['imageHeight'] as num?)?.toDouble(),
    imageFit: _parseBoxFit(json['imageFit']),
    textAlign: _parseTextAlign(json['textAlign']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'subtitle': subtitle,
    'subtitleList': subtitleList,
    'imageUrl': imageUrl,
    'isMultipleSelectable': isMultipleSelectable,
    'maxSelectable': maxSelectable,
    'fontSize': fontSize,
    'textColor': textColor?.value.toString(),
    'fontWeight': fontWeight?.toString(),
    'alignment': alignment?.toString(),
    'padding': padding != null
        ? {
            'left': padding!.left,
            'top': padding!.top,
            'right': padding!.right,
            'bottom': padding!.bottom,
          }
        : null,
    'borderRadius': borderRadius,
    'backgroundColor': backgroundColor?.value.toString(),
    'imageHeight': imageHeight,
    'imageFit': imageFit?.toString(),
    'textAlign': textAlign?.toString(),
  };

  // ===== 🧠 Helper Parser =====
  static FontWeight? _parseFontWeight(String? value) {
    switch (value) {
      case 'FontWeight.w500':
        return FontWeight.w500;
      case 'FontWeight.w400':
        return FontWeight.w400;
      case 'FontWeight.w300':
        return FontWeight.w300;
      default:
        return null;
    }
  }

  static Alignment? _parseAlignment(String? value) {
    switch (value) {
      case 'Alignment.centerLeft':
        return Alignment.centerLeft;
      case 'Alignment.centerRight':
        return Alignment.centerRight;
      case 'Alignment.topCenter':
        return Alignment.topCenter;
      case 'Alignment.bottomCenter':
        return Alignment.bottomCenter;
      default:
        return null;
    }
  }

  static EdgeInsets? _parseEdgeInsets(Map<String, dynamic>? json) {
    if (json == null) return null;
    return EdgeInsets.fromLTRB(
      (json['left'] ?? 0).toDouble(),
      (json['top'] ?? 0).toDouble(),
      (json['right'] ?? 0).toDouble(),
      (json['bottom'] ?? 0).toDouble(),
    );
  }

  static BoxFit? _parseBoxFit(String? value) {
    switch (value) {
      case 'BoxFit.cover':
        return BoxFit.cover;
      case 'BoxFit.contain':
        return BoxFit.contain;
      case 'BoxFit.fill':
        return BoxFit.fill;
      default:
        return null;
    }
  }

  static TextAlign? _parseTextAlign(String? value) {
    switch (value) {
      case 'TextAlign.left':
        return TextAlign.left;
      case 'TextAlign.center':
        return TextAlign.center;
      case 'TextAlign.right':
        return TextAlign.right;
      default:
        return null;
    }
  }
}
