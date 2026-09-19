import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
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

  // ====================================================================
  // SISTEMA DE EXPORTAÇÃO E IMPORTAÇÃO DE BACKUP OFFLINE (.5s)
  // ====================================================================

  /// Compacta o banco de dados e todas as fotos num arquivo único e compartilha.
  Future<void> exportData(BuildContext context) async {
    try {
      isLoading = true;
      notifyListeners();

      final auditsToExport = await repository.getAudits();
      if (auditsToExport.isEmpty) {
        isLoading = false;
        notifyListeners();
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nenhuma auditoria para exportar.')));
        return;
      }

      final archive = Archive();
      final jsonList = [];

      for (final audit in auditsToExport) {
        jsonList.add({
          'audit': audit.toMap(),
          'items': audit.items.map((i) => i.toMap(audit.id)).toList(),
          'evidences': audit.evidences.map((e) => e.toMap(audit.id)).toList(),
        });

        // Adiciona as fotos físicas ao ZIP
        for (final ev in audit.evidences) {
          final file = File(ev.filePath);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            final ext = ev.fileName.split('.').last;
            archive.addFile(ArchiveFile('media/${ev.id}.$ext', bytes.length, bytes));
          }
        }
      }

      // Adiciona o banco de dados (JSON) ao ZIP
      final jsonBytes = utf8.encode(jsonEncode(jsonList));
      archive.addFile(ArchiveFile('data.json', jsonBytes.length, jsonBytes));

      // Salva o pacote temporariamente
      final tempDir = await getTemporaryDirectory();
      
      // Data formatada para o nome do arquivo
      final dateStr = DateTime.now().toIso8601String().substring(0, 10);
      final exportFile = File('${tempDir.path}/Backup_5S_$dateStr.5s');
      
      final zipBytes = ZipEncoder().encode(archive);
      await exportFile.writeAsBytes(zipBytes!);

      isLoading = false;
      notifyListeners();

      // Abre a tela de compartilhamento (WhatsApp, Drive, etc)
      await Share.shareXFiles([XFile(exportFile.path)], text: 'Aqui estão minhas auditorias 5S!');
    } catch (e) {
      isLoading = false;
      notifyListeners();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao gerar arquivo: $e')));
      }
    }
  }

  /// Descompacta um arquivo recebido (.5s), extrai as fotos para a memória 
  /// local e injeta as auditorias no banco de dados.
  Future<void> importData(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);

      if (result == null || result.files.single.path == null) return;

      isLoading = true;
      notifyListeners();

      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      final jsonFile = archive.findFile('data.json');
      if (jsonFile == null) throw Exception('Arquivo inválido ou incompatível.');

      final jsonString = utf8.decode(jsonFile.content as List<int>);
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final appDir = await getApplicationDocumentsDirectory();

      for (final item in jsonList) {
        final auditMap = item['audit'];
        final itemsList = item['items'] as List<dynamic>;
        final evidencesList = item['evidences'] as List<dynamic>;

        final restoredEvidences = <Evidence>[];
        
        for (final evMap in evidencesList) {
          final ev = Evidence.fromMap(evMap);
          final ext = ev.fileName.split('.').last;
          final mediaFile = archive.findFile('media/${ev.id}.$ext');

          String newPath = ev.filePath; 

          // Se a foto veio junto, salva na memória do celular NOVO
          if (mediaFile != null) {
            final localFile = File('${appDir.path}/${ev.id}.$ext');
            await localFile.writeAsBytes(mediaFile.content as List<int>);
            newPath = localFile.path;
          }

          restoredEvidences.add(Evidence(
            id: ev.id,
            categoryCode: ev.categoryCode,
            filePath: newPath, // Salva com o caminho novo do celular
            fileName: ev.fileName,
            type: ev.type,
          ));
        }

        final restoredItems = itemsList.map((iMap) => AuditItem.fromMap(iMap)).toList();

        final audit = Audit.fromMap(
          auditMap,
          items: restoredItems,
          evidences: restoredEvidences,
        );

        // Injeta a auditoria no banco de dados local
        await repository.saveAudit(audit);
      }

      isLoading = false;
      notifyListeners();
      await loadHistory();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Auditorias importadas com sucesso!')));
      }
    } catch (e) {
      isLoading = false;
      notifyListeners();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao importar: $e')));
      }
    }
  }
}
