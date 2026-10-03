import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:auditoria_5s/core/theme/app_theme.dart';
import 'package:auditoria_5s/domain/entities/audit.dart';
import 'package:auditoria_5s/presentation/providers/audit_provider.dart';
import 'package:auditoria_5s/presentation/screens/history_screen.dart';
import 'audit_draft_test.dart' show MemoryAuditRepository;

Audit exampleAudit() => Audit(
  id: 'compact', responsavel: '', area: 'ADM Vendas', auditor: 'Auditor',
  acompanhante: '', data: DateTime(2026, 9, 1), mesReferencia: 'Setembro',
);

void main() {
  testWidgets('compact audit preserves content, deletion and edit actions', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = MemoryAuditRepository();
    final audit = exampleAudit();
    repository.audits[audit.id] = audit;
    final provider = AuditProvider(repository);
    addTearDown(provider.dispose);
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: provider,
      child: MaterialApp(theme: AppTheme.light,
        home: Scaffold(body: AuditTile(audit: audit))),
    ));
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    expect(find.text('ADM Vendas'), findsOneWidget);
    expect(find.textContaining('01/09/26'), findsOneWidget);
    expect(tester.getSize(find.byKey(const ValueKey('audit-card-compact'))).height, lessThanOrEqualTo(56));
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(find.text('Excluir auditoria?'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(repository.audits.length, 1);
    await tester.tap(find.text('ADM Vendas'));
    await tester.pumpAndSettle();
    expect(provider.current!.id, audit.id);
    expect(find.text('Dados da Auditoria'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('leaving a new form without selecting area does not save a draft', (tester) async {
    final repository = MemoryAuditRepository();
    final provider = AuditProvider(repository);
    addTearDown(provider.dispose);
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: provider,
      child: MaterialApp(theme: AppTheme.light, home: const HistoryScreen()),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nova Auditoria'));
    await tester.pumpAndSettle();
    expect(find.text('Selecione uma área'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(repository.writes, 0);
    expect(repository.audits, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
