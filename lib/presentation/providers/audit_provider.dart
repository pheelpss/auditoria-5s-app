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

  /// Auditoria anterior da mesma área (mês anterior), usada só para
  /// comparação em tempo real — nunca é editada.
  Audit? _previous;
  Audit? get previous => _previous;

  List<Audit> _history = [];
  List<Audit> get history => _history;

  /// Todas as auditorias, sem filtro nenhum — usado pela tela de
  /// Indicadores (independente do que estiver filtrado no histórico).
  List<Audit> _allAudits = [];
  List<Audit> get allAudits => _allAudits;

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
    _previous = null;
    notifyListeners();
  }

  /// Igual a [startNewAudit], mas já parte com a área (e opcionalmente o
  /// mês de referência) pré-preenchidos — usado ao tocar num setor
  /// pendente na tela de Indicadores.
  void startNewAuditFor({required String area, String? mesReferencia}) {
    startNewAudit();
    updateHeader(area: area, mesReferencia: mesReferencia);
  }

  void editAudit(Audit audit) {
    _current = audit;
    _previous = null;
    notifyListeners();
    _refreshPrevious();
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
    final areaMudou = area != null && area.trim() != a.area.trim();
    final dataMudou = data != null && data != a.data;

    if (responsavel != null) a.responsavel = responsavel;
    if (area != null) a.area = area;
    if (auditor != null) a.auditor = auditor;
    if (acompanhante != null) a.acompanhante = acompanhante;
    if (data != null) a.data = data;
    if (mesReferencia != null) a.mesReferencia = mesReferencia;
    if (comentarios != null) a.comentarios = comentarios;
    notifyListeners();

    if (areaMudou || dataMudou) {
      _refreshPrevious();
    }
  }

  /// Busca (em segundo plano) a auditoria mais recente da mesma área
  /// feita antes da data atual, para exibir a comparação mês a mês.
  Future<void> _refreshPrevious() async {
    final a = _current;
    if (a == null || a.area.trim().isEmpty) {
      _previous = null;
      notifyListeners();
      return;
    }
    final found = await repository.getPreviousAudit(
      area: a.area,
      beforeDate: a.data,
      excludeId: a.id,
    );
    // Garante que o resultado ainda corresponde à auditoria em edição
    // (evita condição de corrida se a área mudar de novo enquanto busca).
    if (_current?.id == a.id) {
      _previous = found;
      notifyListeners();
    }
  }

  double? previousAverageForCategory(String categoryCode) =>
      _previous?.averageForCategory(categoryCode);

  int? previousScoreFor(String categoryCode, String number) {
    final p = _previous;
    if (p == null) return null;
    for (final item in p.itemsFor(categoryCode)) {
      if (item.number == number) return item.score;
    }
    return null;
  }

  double? get previousNotaGeral => _previous?.notaGeral;

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

  Future<void> loadAllAudits() async {
    isLoading = true;
    notifyListeners();
    _allAudits = await repository.getAudits();
    isLoading = false;
    notifyListeners();
  }
}
