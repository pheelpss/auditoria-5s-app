/// Um item (pergunta) respondido dentro de uma categoria do 5S.
class AuditItem {
  final String categoryCode;
  final String number;
  final String question;
  int? score; // 0..5, null = não respondido ainda

  AuditItem({
    required this.categoryCode,
    required this.number,
    required this.question,
    this.score,
  });

  Map<String, dynamic> toMap(String auditId) => {
        'auditId': auditId,
        'categoryCode': categoryCode,
        'number': number,
        'question': question,
        'score': score,
      };

  factory AuditItem.fromMap(Map<String, dynamic> map) => AuditItem(
        categoryCode: map['categoryCode'] as String,
        number: map['number'] as String,
        question: map['question'] as String,
        score: map['score'] as int?,
      );
}
