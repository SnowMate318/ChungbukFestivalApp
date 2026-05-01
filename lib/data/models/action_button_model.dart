class ActionButtonModel {
  final String id;
  final String text;
  final String? nextStepId;
  final bool isPrimary;

  ActionButtonModel({
    required this.id,
    required this.text,
    this.nextStepId,
    this.isPrimary = true,
  });

  factory ActionButtonModel.fromJson(Map<String, dynamic> json) =>
      ActionButtonModel(
        id: json['id'],
        text: json['text'],
        nextStepId: json['nextStepId'],
        isPrimary: json['isPrimary'] ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'nextStepId': nextStepId,
        'isPrimary': isPrimary,
      };
}
