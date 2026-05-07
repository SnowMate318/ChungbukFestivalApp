import 'option_model.dart';
import 'action_button_model.dart';
import 'enums.dart';

class SurveyStepModel {
  final String id;
  final StepType type;
  final String? title;
  final String? subtitle;
  final List<OptionModel>? options;
  final List<ActionButtonModel>? actions;
  final ButtonLayoutType buttonLayout;
  final Map<String, dynamic>? extraData;

  /// ✅ 추가된 필드
  final int? stepNumber; // ex) 1
  final String? stepLabel; // ex) 'KRISO 인지도 - 인식'

  SurveyStepModel({
    required this.id,
    required this.type,
    this.title,
    this.subtitle,
    this.options,
    this.actions,
    this.buttonLayout = ButtonLayoutType.spaced,
    this.extraData,
    this.stepNumber,
    this.stepLabel,
  });

  factory SurveyStepModel.fromJson(Map<String, dynamic> json) =>
      SurveyStepModel(
        id: json['id'],
        type: StepType.values.firstWhere(
          (e) => e.toString() == 'StepType.${json['type']}',
        ),
        title: json['title'],
        subtitle: json['subtitle'],
        options: json['options'] != null
            ? (json['options'] as List)
                  .map((e) => OptionModel.fromJson(e))
                  .toList()
            : null,
        actions: json['actions'] != null
            ? (json['actions'] as List)
                  .map((e) => ActionButtonModel.fromJson(e))
                  .toList()
            : null,
        buttonLayout: json['buttonLayout'] == 'centered'
            ? ButtonLayoutType.centered
            : ButtonLayoutType.spaced,
        extraData: json['extraData'],

        /// ✅ 추가된 필드
        stepNumber: json['stepNumber'],
        stepLabel: json['stepLabel'],
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'title': title,
    'subtitle': subtitle,
    'options': options?.map((e) => e.toJson()).toList(),
    'actions': actions?.map((e) => e.toJson()).toList(),
    'buttonLayout': buttonLayout.name,
    'extraData': extraData,

    /// ✅ 추가된 필드
    'stepNumber': stepNumber,
    'stepLabel': stepLabel,
  };
}
