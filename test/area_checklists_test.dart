import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:auditoria_5s/core/constants/area_checklists.dart';
import 'package:auditoria_5s/core/constants/five_s_data.dart';
import 'package:auditoria_5s/core/constants/setores.dart';
import 'package:auditoria_5s/domain/entities/audit.dart';
import 'package:auditoria_5s/domain/entities/audit_item.dart';
import 'package:auditoria_5s/domain/entities/evidence.dart';
import 'package:auditoria_5s/presentation/providers/audit_provider.dart';

import 'audit_draft_test.dart' show MemoryAuditRepository;

const expectedCounts = <String, int>{
  'ADM Vendas': 21, 'Almoxarifado': 28, 'Área Externa': 16,
  'Balanceamento': 25, 'CL': 27, 'Dobra': 25, 'Eng. Produto': 21,
  'Financeiro': 22, 'Laser': 25, 'Leves': 27, 'Manutenção ADM': 21,
  'Manutenção Fab': 25, 'Metálicos': 27, 'MKT': 21, 'MTG Hera': 25,
  'MTG Voluta': 25, 'PCP': 21, 'P&D': 21, 'Pintura': 25,
  'Processos': 21, 'QA': 22, 'Recebimento': 27, 'Repuxo': 26,
  'Resíduos': 24, 'RH': 21, 'Serralheria': 25, 'Solda': 25,
  'SST': 21, 'Teste Titan': 27, 'TI': 21, 'Tubos': 27,
  'Showroom': 14,
};

Audit makeAudit(String area, {List<AuditItem>? items}) => Audit(
  id: 'audit-$area', responsavel: 'Responsável', area: area,
  auditor: 'Auditor', acompanhante: 'Acompanhante',
  data: DateTime(2026, 10, 16), mesReferencia: 'Outubro', items: items,
);

class PreviousAuditRepository extends MemoryAuditRepository {
  Audit? previous;

  @override
  Future<Audit?> getPreviousAudit({required String area,
    required DateTime beforeDate, String? excludeId}) async => previous;
}

void main() {
  test('catalog covers exactly the 32 selectable sectors', () {
    expect(areaChecklists.keys.toSet(), setoresAuditaveis.toSet());
    expect(areaChecklists.keys.toSet(), expectedCounts.keys.toSet());
    expect(areaChecklists.containsKey('ADM'), isFalse);
    expect(areaChecklists.containsKey('TesteQA'), isFalse);
    expect(areaChecklists.containsKey('Teste QA'), isFalse);
    expect(Audit.buildItemsForArea(''), isEmpty);
    expect(Audit.buildItemsForArea('Área inexistente'), isEmpty);
    expect(Audit.buildItemsForArea(' teste titan ').length, 27);
    expect(expectedCounts.values.reduce((a, b) => a + b), 749);
  });

  final reference = jsonDecode(File('docs/checklists_por_area_2026-10.json')
      .readAsStringSync()) as Map<String, dynamic>;
  reference.addAll(jsonDecode(File('docs/checklist_showroom_1.0.12.json')
      .readAsStringSync()) as Map<String, dynamic>);
  for (final entry in expectedCounts.entries) {
    test('${entry.key}: source wording, order, numbering and count', () {
      final audit = makeAudit(entry.key);
      final source = (reference[entry.key] as Map<String, dynamic>)['items']
          as List<dynamic>;
      expect(audit.items.length, entry.value);
      expect(audit.items.map((i) => i.number).toSet().length, entry.value);
      expect(audit.items.map((i) => [i.categoryCode, i.number, i.question]).toList(),
          source.map((dynamic i) => [i['categoryCode'], i['number'], i['question']]).toList());
      expect(audit.items.every((i) => i.score == null), isTrue);
      expect(audit.notaGeral, isNull);
      for (var sense = 1; sense <= 5; sense++) {
        final items = audit.itemsFor('${sense}S');
        expect(items, isNotEmpty);
        expect(items.map((i) => i.number).toList(),
            List.generate(items.length, (i) => '$sense.${i + 1}'));
      }
    });
  }

  test('general score weights the five senses equally with different counts', () {
    final audit = makeAudit('Área Externa');
    for (final item in audit.items) {
      item.score = int.parse(item.categoryCode[0]);
    }
    expect(audit.notaGeral, 3.0);
    expect(audit.progresso, 1.0);
    expect(audit.averageForCategory('1S'), 1.0);
    expect(audit.averageForCategory('5S'), 5.0);
    for (final item in audit.items) { item.score = 0; }
    expect(audit.notaGeral, 0.0);
    for (final item in audit.items) { item.score = 5; }
    expect(audit.notaGeral, 5.0);
  });

  test('selecting a different area replaces questions and clears old scores', () async {
    final provider = AuditProvider(MemoryAuditRepository())..startNewAudit();
    addTearDown(provider.dispose);
    provider.updateHeader(area: 'Almoxarifado');
    expect(provider.current!.items.length, 28);
    provider.setScore('1S', '1.1', 4);
    provider.updateHeader(area: 'Showroom');
    expect(provider.current!.items.length, 14);
    expect(provider.current!.items.every((i) => i.score == null), isTrue);
    await provider.saveCurrent();
    expect(provider.history.single.items.length, 14);
    await Future<void>.delayed(Duration.zero);
  });

  test('corrected last questions in QA and Financeiro keep independent scores', () async {
    final provider = AuditProvider(MemoryAuditRepository());
    addTearDown(provider.dispose);
    for (final area in ['QA', 'Financeiro']) {
      provider.startNewAuditFor(area: area);
      provider.setScore('5S', '5.3', 2);
      provider.setScore('5S', '5.4', 5);
      final items = provider.current!.itemsFor('5S');
      expect(items[2].score, 2);
      expect(items[3].score, 5);
      expect(items[3].question, contains('INDICADOR'));
    }
    await Future<void>.delayed(Duration.zero);
  });

  test('stored old questions survive restore, edits, dates and saves', () async {
    final oldItems = [for (final category in administrativeCategories)
      for (final q in category.questions) AuditItem(categoryCode: category.code,
          number: q.number, question: q.text, score: 4)];
    final old = makeAudit('QA', items: oldItems);
    old.evidences.add(Evidence(id: 'photo', filePath: '/existing/photo.png',
        fileName: 'photo.png', type: EvidenceType.photo));
    final restored = Audit.fromMap(old.toMap(),
        items: old.items.map((i) => AuditItem.fromMap(i.toMap(old.id))).toList(),
        evidences: old.evidences.map((e) => Evidence.fromMap(e.toMap(old.id))).toList());
    final before = restored.items.map((i) => i.toMap(restored.id)).toList();
    final repo = MemoryAuditRepository();
    final provider = AuditProvider(repo)..editAudit(restored);
    addTearDown(provider.dispose);
    provider.updateHeader(area: 'QA', auditor: 'Outro auditor',
        data: DateTime(2026, 11, 1), mesReferencia: 'Novembro', comentarios: 'Texto');
    await provider.saveCurrent();
    expect(provider.current!.items.length, 24);
    expect(repo.audits[old.id]!.items.map((i) => i.toMap(old.id)).toList(), before);
    expect(provider.current!.evidences.single.filePath, '/existing/photo.png');
    expect(provider.current!.notaGeral, 4.0);
    expect(provider.current!.hasSameQuestions(makeAudit('QA')), isFalse);
    await Future<void>.delayed(Duration.zero);
  });

  test('previous scores are compared only for matching question sets', () async {
    final repo = PreviousAuditRepository();
    final provider = AuditProvider(repo);
    addTearDown(provider.dispose);
    repo.previous = makeAudit('Teste Titan');
    for (final item in repo.previous!.items) { item.score = 3; }
    provider.startNewAuditFor(area: 'Teste Titan');
    await Future<void>.delayed(Duration.zero);
    expect(provider.previousScoreFor('1S', '1.1'), 3);
    repo.previous = makeAudit('Teste Titan', items: [
      AuditItem(categoryCode: '1S', number: '1.1', question: 'Pergunta antiga', score: 1),
    ]);
    provider.startNewAuditFor(area: 'Teste Titan');
    await Future<void>.delayed(Duration.zero);
    expect(provider.previous, isNull);
    expect(provider.previousScoreFor('1S', '1.1'), isNull);
  });
}
