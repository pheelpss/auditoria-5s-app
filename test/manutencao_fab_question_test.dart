import 'package:flutter_test/flutter_test.dart';
import 'package:auditoria_5s/domain/entities/audit.dart';
import 'package:auditoria_5s/domain/entities/audit_item.dart';

const correctQuestion =
    'CARTAZES E LEMBRETES ESTÃO EXIBIDOS NO AMBIENTE DE TRABALHO?';
const trainingQuestion =
    'OS TREINAMENTOS E OUTRAS PROGRAMAÇÕES SÃO IMPLEMENTADOS PARA SUSTENTAR A ORGANIZAÇÃO DO TRABALHO?';

Audit makeAudit({List<AuditItem>? items}) => Audit(
      id: 'manutencao-fab-regression',
      responsavel: 'Responsável',
      area: 'Manutenção Fab',
      auditor: 'Auditor',
      acompanhante: '',
      data: DateTime(2026, 10, 29),
      mesReferencia: 'Outubro',
      items: items,
    );

void main() {
  test('new Manutenção Fab audit separates posters from training', () {
    final audit = makeAudit();
    final discipline = audit.itemsFor('5S');
    expect(audit.items.length, 25);
    expect(discipline.map((item) => item.number), ['5.1', '5.2', '5.3', '5.4']);
    expect(discipline[1].question, correctQuestion);
    expect(discipline[2].question, trainingQuestion);
    expect(discipline.every((item) => item.score == null), isTrue);
    discipline[1].score = 2;
    discipline[2].score = 4;
    expect(audit.averageForCategory('5S'), 3);
  });

  test('stored and imported Manutenção Fab questions and scores survive', () {
    final historical = makeAudit(items: [
      AuditItem(categoryCode: '5S', number: '5.2',
          question: trainingQuestion, score: 3),
      AuditItem(categoryCode: '5S', number: '5.3',
          question: trainingQuestion, score: 4),
    ]);
    final restored = Audit.fromMap(historical.toMap(),
        items: historical.items
            .map((item) => AuditItem.fromMap(item.toMap(historical.id)))
            .toList(),
        evidences: []);
    expect(restored.items.map((item) => item.question),
        [trainingQuestion, trainingQuestion]);
    expect(restored.items.map((item) => item.score), [3, 4]);
    expect(restored.hasSameQuestions(makeAudit()), isFalse);
  });
}
