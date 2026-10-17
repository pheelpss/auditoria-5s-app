import 'package:flutter_test/flutter_test.dart';
import 'package:auditoria_5s/domain/entities/audit.dart';
import 'package:auditoria_5s/domain/entities/evidence.dart';
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
  Future<List<Audit>> getAudits({
    AuditFilter filter = const AuditFilter(),
  }) async => audits.values.toList();

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

  test(
    'comments and header fields keep a draft even before selecting an area',
    () async {
      provider.updateHeader(
        auditor: 'Auditor',
        comentarios: 'Notas antes da área',
      );
      await provider.saveCurrent();
      provider.updateHeader(area: '   ');
      await provider.saveCurrent();
      expect(repository.writes, 2);
      expect(repository.audits.length, 1);
    },
  );

  test(
    'selecting an area saves an unscored draft and its existing fields',
    () async {
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
    },
  );

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

  test(
    'opening a sector with its default month does not save a draft',
    () async {
      provider.startNewAuditFor(area: 'Solda', mesReferencia: 'Setembro');
      await provider.saveCurrent();
      expect(repository.writes, 0);
      expect(repository.audits, isEmpty);
    },
  );

  test(
    'zero is an answer; clearing the last score deletes the new draft',
    () async {
      provider.startNewAuditFor(area: 'PCP');
      final first = provider.current!.items.first;
      provider.setScore(first.categoryCode, first.number, 0);
      await provider.saveCurrent();
      expect(repository.audits.length, 1);
      expect(repository.audits.values.single.notaGeral, 0);
      expect(provider.allAudits.single.notaGeral, 0);
      provider.setScore(first.categoryCode, first.number, null);
      await provider.saveCurrent();
      expect(repository.audits, isEmpty);
      expect(provider.history, isEmpty);
      expect(provider.allAudits, isEmpty);
    },
  );

  for (final field in [
    'responsavel',
    'auditor',
    'acompanhante',
    'comentarios',
  ]) {
    test(
      'only $field keeps a draft; clearing it discards the new draft',
      () async {
        provider.startNewAuditFor(area: 'TI');
        void update(String text) {
          switch (field) {
            case 'responsavel':
              provider.updateHeader(responsavel: text);
            case 'auditor':
              provider.updateHeader(auditor: text);
            case 'acompanhante':
              provider.updateHeader(acompanhante: text);
            case 'comentarios':
              provider.updateHeader(comentarios: text);
          }
        }

        update('Preenchido');
        await provider.saveCurrent();
        expect(repository.audits.length, 1);
        update('   ');
        await provider.saveCurrent();
        expect(repository.audits, isEmpty);
      },
    );
  }

  test('changed date, month or sector counts as header content', () async {
    for (final field in ['data', 'mes', 'area']) {
      provider.startNewAuditFor(area: 'RH', mesReferencia: 'Setembro');
      final initial = provider.current!.data;
      switch (field) {
        case 'data':
          provider.updateHeader(data: initial.add(const Duration(days: 1)));
        case 'mes':
          provider.updateHeader(mesReferencia: 'Outubro');
        case 'area':
          provider.updateHeader(area: 'TI');
      }
      await provider.saveCurrent();
      expect(repository.audits.containsKey(provider.current!.id), isTrue);
      provider.updateHeader(
        area: 'RH',
        mesReferencia: 'Setembro',
        data: initial,
      );
      await provider.saveCurrent();
      expect(repository.audits, isEmpty);
    }
  });

  for (final type in EvidenceType.values) {
    test(
      'only ${type.name} keeps a draft; removing it discards the draft',
      () async {
        provider.startNewAuditFor(area: 'Solda');
        provider.addEvidence(
          Evidence(
            id: 'evidence',
            filePath: '/photo.jpg',
            fileName: 'photo.jpg',
            type: type,
          ),
        );
        await provider.saveCurrent();
        expect(repository.audits.length, 1);
        provider.removeEvidence('evidence');
        await provider.saveCurrent();
        expect(repository.audits, isEmpty);
      },
    );
  }

  test(
    'editing an existing audit never deletes it for being unscored',
    () async {
      final historical = Audit(
        id: 'historical',
        responsavel: '',
        area: 'RH',
        auditor: '',
        acompanhante: '',
        data: DateTime(2026, 9, 1),
        mesReferencia: 'Setembro',
      );
      repository.audits[historical.id] = historical;
      provider.editAudit(historical);
      await provider.saveCurrent();
      expect(repository.audits.containsKey(historical.id), isTrue);
    },
  );

  test(
    'pending saves cannot recreate a draft after its contents are cleared',
    () async {
      provider.startNewAuditFor(area: 'PCP');
      provider.updateHeader(comentarios: 'Primeira gravação');
      final first = provider.saveCurrent();
      provider.updateHeader(comentarios: '');
      final clear = provider.saveCurrent();
      await Future.wait([first, clear]);
      expect(repository.writes, 1);
      expect(repository.audits, isEmpty);
    },
  );

  test(
    'pending save keeps the captured audit when another sector is opened',
    () async {
      provider.startNewAuditFor(area: 'PCP');
      provider.updateHeader(comentarios: 'Registro PCP');
      final id = provider.current!.id;
      final save = provider.saveCurrent();
      provider.startNewAuditFor(area: 'Tubos');
      await save;
      expect(repository.audits.keys, [id]);
      expect(repository.audits[id]!.comentarios, 'Registro PCP');
      await provider.saveCurrent();
      expect(repository.audits.keys, [id]);
    },
  );
}
