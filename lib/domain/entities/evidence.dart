enum EvidenceType { photo, file }

/// Representa um anexo de evidência (foto ou arquivo) vinculado a uma
/// categoria (1S..5S) de uma auditoria.
class Evidence {
  final String id;
  final String categoryCode;
  final String filePath;
  final String fileName;
  final EvidenceType type;

  Evidence({
    required this.id,
    required this.categoryCode,
    required this.filePath,
    required this.fileName,
    required this.type,
  });

  Map<String, dynamic> toMap(String auditId) => {
        'id': id,
        'auditId': auditId,
        'categoryCode': categoryCode,
        'filePath': filePath,
        'fileName': fileName,
        'type': type.name,
      };

  factory Evidence.fromMap(Map<String, dynamic> map) => Evidence(
        id: map['id'] as String,
        categoryCode: map['categoryCode'] as String,
        filePath: map['filePath'] as String,
        fileName: map['fileName'] as String,
        type: EvidenceType.values.firstWhere((e) => e.name == map['type']),
      );
}
