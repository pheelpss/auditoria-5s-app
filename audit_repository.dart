import '../entities/audit.dart';

/// Filtros usados na tela de histórico.
class AuditFilter {
  final String? mes;
  final int? ano;
  final String? area;
  final String? auditor;
  const AuditFilter({this.mes, this.ano, this.area, this.auditor});

  bool get isEmpty => mes == null && ano == null && area == null && auditor == null;
}

abstract class AuditRepository {
  Future<void> saveAudit(Audit audit);
  Future<List<Audit>> getAudits({AuditFilter filter = const AuditFilter()});
  Future<Audit?> getAuditById(String id);
  Future<void> deleteAudit(String id);

  /// Busca a auditoria mais recente da mesma área, feita antes de
  /// [beforeDate] — usada para comparar a nota do mês atual com a do
  /// mês anterior em tempo real.
  Future<Audit?> getPreviousAudit({
    required String area,
    required DateTime beforeDate,
    String? excludeId,
  });
}
