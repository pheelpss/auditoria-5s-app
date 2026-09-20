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
import '../../domain/entities/audit_item.dart';

/// Gerencia o estado da auditoria em edição e o histórico de auditorias
/// já salvas. É o único ponto de acesso das telas ao [AuditRepository].
class AuditProvider extends ChangeNotifier {
  final AuditRepository repository;
  AuditProvider(this.repository);

  Audit? _current;
  Audit? get current => _current;

  Audit? _previous;
  Audit? get previous => _previous;

  List<Audit> _history = [];
  List<Audit> get history => _history;

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
  // SISTEMA DE EXPORTAÇÃO E IMPORTAÇÃO PADRÃO (.5s)
  // ====================================================================

  /// Exporta as auditorias gerando um arquivo com extensão unificada .5s
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

        for (final ev in audit.evidences) {
          final file = File(ev.filePath);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            final ext = ev.fileName.split('.').last;
            archive.addFile(ArchiveFile('media/${ev.id}.$ext', bytes.length, bytes));
          }
        }
      }

      final jsonBytes = utf8.encode(jsonEncode(jsonList));
      archive.addFile(ArchiveFile('data.json', jsonBytes.length, jsonBytes));

      final tempDir = await getTemporaryDirectory();
      final dateStr = DateTime.now().toIso8601String().substring(0, 10);
      
      // Arquivo salvo estritamente com a extensão .5s
      final exportFile = File('${tempDir.path}/Backup_Auditoria_5S_$dateStr.5s');
      
      final zipBytes = ZipEncoder().encode(archive);
      await exportFile.writeAsBytes(zipBytes!);

      isLoading = false;
      notifyListeners();

      await Share.shareXFiles([XFile(exportFile.path)], text: 'Segue o arquivo de backup das auditorias 5S.');
    } catch (e) {
      isLoading = false;
      notifyListeners();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao gerar arquivo: $e')));
      }
    }
  }

  /// Importa o arquivo .5s selecionado manualmente pelo usuário (seletor
  /// de arquivos).
  Future<void> importData(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['5s'],
    );
    if (result == null || result.files.single.path == null) return;
    if (!context.mounted) return;
    await _importFromPath(result.files.single.path!, context);
  }

  /// Importa um arquivo .5s a partir de um caminho já conhecido — usado
  /// quando o usuário recebe o arquivo por fora do app (WhatsApp, e-mail,
  /// gerenciador de arquivos) e toca nele para abrir com o Auditoria 5S.
  Future<void> importDataFromPath(String path, BuildContext context) async {
    await _importFromPath(path, context);
  }

  Future<void> _importFromPath(String path, BuildContext context) async {
    try {
      isLoading = true;
      notifyListeners();

      final file = File(path);
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      final jsonFile = archive.findFile('data.json');
      if (jsonFile == null) throw Exception('Arquivo inválido ou incompatível.');

      final jsonString = utf8.decode(jsonFile.content as List<int>);
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final appDir = await getApplicationDocumentsDirectory();

      for (final item in jsonList) {
        final auditMap = item['audit'] as Map<String, dynamic>;
        final itemsList = item['items'] as List<dynamic>;
        final evidencesList = item['evidences'] as List<dynamic>;

        final restoredEvidences = <Evidence>[];
        for (final evData in evidencesList) {
          final evMap = evData as Map<String, dynamic>;
          final ev = Evidence.fromMap(evMap);
          final ext = ev.fileName.split('.').last;
          final mediaFile = archive.findFile('media/${ev.id}.$ext');

          String newPath = ev.filePath;

          if (mediaFile != null) {
            final localFile = File('${appDir.path}/${ev.id}.$ext');
            await localFile.writeAsBytes(mediaFile.content as List<int>);
            newPath = localFile.path;
          }

          restoredEvidences.add(Evidence(
            id: ev.id,
            categoryCode: ev.categoryCode,
            filePath: newPath,
            fileName: ev.fileName,
            type: ev.type,
          ));
        }

        final restoredItems = <AuditItem>[];
        for (final iData in itemsList) {
          final iMap = iData as Map<String, dynamic>;
          restoredItems.add(AuditItem.fromMap(iMap));
        }

        final audit = Audit.fromMap(
          auditMap,
          items: restoredItems,
          evidences: restoredEvidences,
        );

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
            const SnackBar(content: Text('Erro ao importar. Certifique-se de que o arquivo .5s é válido.')));
      }
    }
  }

  // ====================================================================
  // EXPORTAÇÃO PARA EXCEL (DASHBOARD)
  // ====================================================================

  Future<void> exportDashboardExcel(BuildContext context) async {
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

      // 1. Organizar dados por Área -> Mês -> Lista de Notas (pois pode haver mais de uma no mês)
      final areaData = <String, Map<String, List<double>>>{};

      for (final audit in auditsToExport) {
        final area = audit.area.trim();
        final mes = audit.mesReferencia;
        final nota = audit.notaGeral;

        if (area.isEmpty || nota == null) continue;

        areaData.putIfAbsent(area, () => {});
        areaData[area]!.putIfAbsent(mes, () => []);
        areaData[area]![mes]!.add(nota);
      }

      // 2. Mapear meses para garantir a ordem correta nas colunas
      const meses = [
        'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
        'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
      ];

      // 3. Inteligência para classificar Fabril vs Administrativo
      String getCategoria(String areaName) {
        final adminKeywords = [
          'rh', 'escritório', 'escritorio', 'financeiro', 'ti', 'vendas', 
          'recepção', 'adm', 'administrativo', 'logística', 'almoxarifado', 
          'diretoria', 'compras', 'qualidade'
        ];
        final lower = areaName.toLowerCase();
        for (final kw in adminKeywords) {
          if (lower.contains(kw)) return 'Administrativo';
        }
        return 'Fabril'; // Se não tiver palavra de escritório, assume que é fábrica
      }

      final csv = StringBuffer();
      // O código \xEF\xBB\xBF é o BOM (Byte Order Mark). Ele força o Excel a 
      // ler acentos corretamente (ç, ã, í) no Brasil sem bugar as letras.
      csv.write('\xEF\xBB\xBF'); 
      
      // Cabeçalho da tabela separada por Ponto e Vírgula
      csv.writeln('Categoria;Área;Janeiro;Fevereiro;Março;Abril;Maio;Junho;Julho;Agosto;Setembro;Outubro;Novembro;Dezembro;Média Anual');

      // 4. Construir as linhas da matriz
      for (final area in areaData.keys) {
        final cat = getCategoria(area);
        final linha = [cat, area];

        double somaAnual = 0;
        int mesesAvaliados = 0;

        for (final mes in meses) {
          final notasDoMes = areaData[area]![mes];
          if (notasDoMes == null || notasDoMes.isEmpty) {
            linha.add('-'); // Mês sem auditoria
          } else {
            // Se fizeram 2 auditorias na mesma área no mesmo mês, tira a média delas
            final mediaMes = notasDoMes.reduce((a, b) => a + b) / notasDoMes.length;
            // Converte ponto para vírgula para o Excel entender como número no Brasil
            linha.add(mediaMes.toStringAsFixed(2).replaceAll('.', ',')); 
            somaAnual += mediaMes;
            mesesAvaliados++;
          }
        }

        // 5. Calcular a média do ano daquela área
        if (mesesAvaliados > 0) {
          final mediaAnual = somaAnual / mesesAvaliados;
          linha.add(mediaAnual.toStringAsFixed(2).replaceAll('.', ','));
        } else {
          linha.add('-');
        }

        csv.writeln(linha.join(';'));
      }

      // 6. Gerar o arquivo final
      final tempDir = await getTemporaryDirectory();
      final dateStr = DateTime.now().toIso8601String().substring(0, 10);
      final exportFile = File('${tempDir.path}/Dashboard_5S_$dateStr.csv');

      await exportFile.writeAsString(csv.toString());

      isLoading = false;
      notifyListeners();

      await Share.shareXFiles([XFile(exportFile.path)], text: 'Base de dados 5S cruzada e formatada para Excel.');

    } catch (e) {
      isLoading = false;
      notifyListeners();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao gerar Dashboard: $e')));
      }
    }
  }
}
