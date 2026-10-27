import 'package:flutter_test/flutter_test.dart';
import 'package:auditoria_5s/core/constants/sectors.dart';
import 'package:auditoria_5s/core/constants/setores.dart';
import 'package:auditoria_5s/domain/entities/audit.dart';
import 'package:auditoria_5s/domain/entities/audit_item.dart';
import 'package:auditoria_5s/presentation/providers/audit_provider.dart';

import 'audit_draft_test.dart' show MemoryAuditRepository;

void main() {
  test('Showroom is the last administrative sector in both sector lists', () {
    expect(setoresAdministrativos.last, 'Showroom');
    expect(setoresAuditaveis.last, 'Showroom');
    expect(auditSectors, orderedEquals(setoresAuditaveis));
    expect(isAdministrativa(' showroom '), isTrue);
    expect(setoresProducao, isNot(contains('Showroom')));
  });

  test('Showroom starts empty and retains a zero score when saved and restored', () async {
    final repo = MemoryAuditRepository();
    final provider = AuditProvider(repo);
    addTearDown(provider.dispose);
    provider.startNewAuditFor(area: 'Showroom');
    final audit = provider.current!;
    expect([for (var sense = 1; sense <= 5; sense++)
      audit.itemsFor('${sense}S').length], [3, 3, 4, 2, 2]);
    expect(audit.notaGeral, isNull);
    expect(audit.progresso, 0);
    expect(audit.evidences, isEmpty);
    await provider.saveCurrent();
    expect(repo.audits, isEmpty);
    provider.setScore('5S', '5.1', 0);
    await provider.saveCurrent();
    final saved = repo.audits[audit.id]!;
    final restored = Audit.fromMap(saved.toMap(), items: saved.items
        .map((item) => AuditItem.fromMap(item.toMap(saved.id))).toList(),
        evidences: []);
    expect(restored.area, 'Showroom');
    expect(restored.items.length, 14);
    expect(restored.itemsFor('5S').map((item) => item.number), ['5.1', '5.2']);
    expect(restored.notaGeral, 0);
    expect(restored.items.where((item) => item.score != null).length, 1);
    await Future<void>.delayed(Duration.zero);
  });
}
