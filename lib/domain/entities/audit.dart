import '../../core/constants/five_s_data.dart';
import 'audit_item.dart';
import 'evidence.dart';

/// Entidade principal: uma auditoria 5S completa (cabeçalho + itens +
/// evidências), com os cálculos de nota e classificação.
class Audit {
  final String id;
  String responsavel;
  String area;
  String auditor;
  String acompanhante;
  DateTime data;
  String mesReferencia;
  String comentarios;
  final DateTime createdAt;
  final List<AuditItem> items;
  final List<Evidence> evidences;

  // --- ATALHO MÁGICO PARA EVIDÊNCIAS GLOBAIS ---
  // Permite que o formulário acesse todas as evidências de forma global 
  // sem quebrar o formato que o seu banco de dados local já utiliza para salvar.
  List<Evidence> get globalEvidences => evidences;
  set globalEvidences(List<Evidence> novas) {
    evidences.clear();
    evidences.addAll(novas);
  }

  Audit({
    required this.id,
    required this.responsavel,
    required this.area,
    required this.auditor,
    required this.acompanhante,
    required this.data,
    required this.mesReferencia,
    this.comentarios = '',
    DateTime? createdAt,
    List<AuditItem>? items,
    List<Evidence>? evidences,
  })  : createdAt = createdAt ?? DateTime.now(),
        items = items ?? _buildDefaultItems(),
        evidences = evidences ?? [];

  static List<AuditItem> _buildDefaultItems() {
    final list = <AuditItem>[];
    for (final cat in fiveSCategories) {
      for (final q in cat.questions) {
        list.add(AuditItem(categoryCode: cat.code, number: q.number, question: q.text));
      }
    }
    return list;
  }

  List<AuditItem> itemsFor(String categoryCode) =>
      items.where((i) => i.categoryCode == categoryCode).toList();

  List<Evidence> evidencesFor(String categoryCode) =>
      evidences.where((e) => e.categoryCode == categoryCode).toList();

  /// Média das notas de uma categoria. Retorna null se nenhum item da
  /// categoria foi pontuado ainda.
  double? averageForCategory(String categoryCode) {
    final scored = itemsFor(categoryCode).where((i) => i.score != null).toList();
    if (scored.isEmpty) return null;
    final sum = scored.fold<int>(0, (acc, i) => acc + i.score!);
    return sum / scored.length;
  }

  /// Nota geral 5S: média dos resultados dos cinco sensos já calculados.
  double? get notaGeral {
    final medias = fiveSCategories
        .map((c) => averageForCategory(c.code))
        .whereType<double>()
        .toList();
    if (medias.isEmpty) return null;
    return medias.reduce((a, b) => a + b) / medias.length;
  }

  String get classificacao {
    final n = notaGeral;
    if (n == null) return 'Sem avaliação';
    return classificacaoParaNota(n);
  }

  double get progresso {
    final respondidos = items.where((i) => i.score != null).length;
    if (items.isEmpty) return 0;
    return respondidos / items.length;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'responsavel': responsavel,
        'area': area,
        'auditor': auditor,
        'acompanhante': acompanhante,
        'data': data.toIso8601String(),
        'mesReferencia': mesReferencia,
        'comentarios': comentarios,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Audit.fromMap(
    Map<String, dynamic> map, {
    required List<AuditItem> items,
    required List<Evidence> evidences,
  }) =>
      Audit(
        id: map['id'] as String,
        responsavel: map['responsavel'] as String,
        area: map['area'] as String,
        auditor: map['auditor'] as String,
        acompanhante: map['acompanhante'] as String,
        data: DateTime.parse(map['data'] as String),
        mesReferencia: map['mesReferencia'] as String,
        comentarios: map['comentarios'] as String? ?? '',
        createdAt: DateTime.parse(map['createdAt'] as String),
        items: items,
        evidences: evidences,
      );
}
