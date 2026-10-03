import 'package:flutter_test/flutter_test.dart';
import 'package:auditoria_5s/domain/entities/audit.dart';
import 'package:auditoria_5s/domain/repositories/audit_repository.dart';
import 'package:auditoria_5s/presentation/providers/audit_provider.dart';

class MemoryAuditRepository implements AuditRepository {
  final Map<String, Audit> audits = {};
  int writes = 0;

  @override
  Future<void> saveAudit(Audit audit) async {
    writes++;
    audits[audit.id] = audit;
  }

  @override
  Future<List<Audit>> getAudits({AuditFilter filter = const AuditFilter()}) async =>
      audits.values.toList();

  @override
  Future<Audit?> getAuditById(String id) async => audits[id];

  @override
  Future<void> deleteAudit(String id) async => audits.remove(id);

  @override
  Future<Audit?> getPreviousAudit({
    required String area,
    required DateTime beforeDate,
    String? excludeId,
  }) async => null;
}

void main() {
  late MemoryAuditRepository repository;
  late AuditProvider provider;
  setUp(() {
    repository = MemoryAuditRepository();
    provider = AuditProvider(repository);
    provider.startNewAudit();
  });
  tearDown(() => provider.dispose());

  test('opening and leaving a new form does not create a draft', () async {
    await provider.saveCurrent();
    expect(repository.writes, 0);
    expect(repository.audits, isEmpty);
    expect(provider.isLoading, isFalse);
  });

  test('comments and other fields without an area do not create a draft', () async {
    provider.updateHeader(auditor: 'Auditor', comentarios: 'Notas antes da área');
    await provider.saveCurrent();
    provider.updateHeader(area: '   ');
    await provider.saveCurrent();
    expect(repository.writes, 0);
    expect(repository.audits, isEmpty);
  });

  test('selecting an area saves an unscored draft and its existing fields', () async {
    provider.updateHeader(auditor: 'Auditor', comentarios: 'Comentário');
    provider.updateHeader(area: 'ADM Vendas');
    await provider.saveCurrent();
    expect(repository.writes, 1);
    expect(repository.audits.length, 1);
    expect(provider.current!.items, isNotEmpty);
    expect(provider.current!.notaGeral, isNull);
    expect(provider.history.single.area, 'ADM Vendas');
    expect(provider.history.single.auditor, 'Auditor');
    expect(provider.history.single.comentarios, 'Comentário');
    await Future<void>.delayed(Duration.zero);
  });

  test('later saves update the same selected-area audit', () async {
    provider.updateHeader(area: 'ADM Vendas');
    await provider.saveCurrent();
    final id = provider.current!.id;
    provider.updateHeader(comentarios: 'Atualizado');
    await provider.saveCurrent();
    expect(repository.writes, 2);
    expect(repository.audits.keys, [id]);
    expect(provider.history.single.comentarios, 'Atualizado');
    await Future<void>.delayed(Duration.zero);
  });
}
