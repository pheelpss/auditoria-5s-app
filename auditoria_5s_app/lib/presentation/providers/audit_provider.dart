import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/audit.dart';
import '../../domain/entities/evidence.dart';
import '../../domain/repositories/audit_repository.dart';

/// Gerencia o estado da auditoria em edição e o histórico de auditorias
/// já salvas. É o único ponto de acesso das telas ao [AuditRepository].
class AuditProvider extends ChangeNotifier {
  final AuditRepository repository;
  AuditProvider(this.repository);

  Audit? _current;
  Audit? get current => _current;

  List<Audit> _history = [];
  List<Audit> get history => _history;

  AuditFilter _filter = const AuditFilter();
  AuditFilter get filter => _filter;

  bool isLoading = false;

  void startNewAudit() {
    _current = Audit(
      id: const Uuid().v4(),
      responsavel: '',
      area: '',
      auditor: '',
      acompanhante: '',
      data: DateTime.now(),
      mesReferencia: _mesAtual(),
    );
    notifyListeners();
  }

  void editAudit(Audit audit) {
    _current = audit;
    notifyListeners();
  }

  String _mesAtual() {
    const meses = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
    ];
    return meses[DateTime.now().month - 1];
  }

  void updateHeader({
    String? responsavel,
    String? area,
    String? auditor,
    String? acompanhante,
    DateTime? data,
    String? mesReferencia,
    String? comentarios,
  }) {
    final a = _current;
    if (a == null) return;
    if (responsavel != null) a.responsavel = responsavel;
    if (area != null) a.area = area;
    if (auditor != null) a.auditor = auditor;
    if (acompanhante != null) a.acompanhante = acompanhante;
    if (data != null) a.data = data;
    if (mesReferencia != null) a.mesReferencia = mesReferencia;
    if (comentarios != null) a.comentarios = comentarios;
    notifyListeners();
  }

  void setScore(String categoryCode, String number, int score) {
    final a = _current;
    if (a == null) return;
    final item = a.items.firstWhere(
      (i) => i.categoryCode == categoryCode && i.number == number,
    );
    item.score = score;
    notifyListeners();
  }

  void addEvidence(Evidence evidence) {
    _current?.evidences.add(evidence);
    notifyListeners();
  }

  void removeEvidence(String evidenceId) {
    _current?.evidences.removeWhere((e) => e.id == evidenceId);
    notifyListeners();
  }

  Future<void> saveCurrent() async {
    final a = _current;
    if (a == null) return;
    isLoading = true;
    notifyListeners();
    await repository.saveAudit(a);
    isLoading = false;
    notifyListeners();
    await loadHistory();
  }

  Future<void> loadHistory({AuditFilter? filter}) async {
    isLoading = true;
    notifyListeners();
    _filter = filter ?? _filter;
    _history = await repository.getAudits(filter: _filter);
    isLoading = false;
    notifyListeners();
  }

  Future<void> deleteAudit(String id) async {
    await repository.deleteAudit(id);
    await loadHistory();
  }
}
