import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:auditoria_5s/core/theme/app_theme.dart';
import 'package:auditoria_5s/domain/entities/audit.dart';
import 'package:auditoria_5s/presentation/providers/audit_provider.dart';
import 'package:auditoria_5s/presentation/screens/history_screen.dart';
import 'package:auditoria_5s/presentation/screens/indicators_screen.dart';
import 'package:auditoria_5s/presentation/widgets/header_form.dart';
import 'audit_draft_test.dart' show MemoryAuditRepository;

void main() {
  testWidgets('area headings are disabled and area selection saves the draft', (tester) async {
    final repo = MemoryAuditRepository();
    final provider = AuditProvider(repo)..startNewAudit();
    addTearDown(provider.dispose);
    await tester.pumpWidget(ChangeNotifierProvider.value(value: provider,
      child: MaterialApp(theme: AppTheme.light, home: const Scaffold(
        body: SingleChildScrollView(child: HeaderForm())))));
    await tester.pumpAndSettle();
    final dropdownFinder = find.byType(DropdownButton<String>).first;
    final dropdown = tester.widget<DropdownButton<String>>(dropdownFinder);
    final headings = dropdown.items!.where((item) => !item.enabled).toList();
    expect(headings.length, 2);
    expect(headings.every((item) => item.value == null), isTrue);
    expect(headings.every((item) => item.child is Semantics), isTrue);
    final values = dropdown.items!.map((item) => item.value).toList();
    final showroomIndex = values.indexOf('Showroom');
    expect(showroomIndex, greaterThan(values.indexOf('RH')));
    expect(values[showroomIndex + 1], isNull);
    expect(values[showroomIndex + 2], 'Balanceamento');
    await tester.ensureVisible(dropdownFinder);
    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();
    // O texto de dica não recebe eventos; tocar no botão abre a rota real.
    final menu = find.byType(ListView);
    expect(menu, findsOneWidget);
    final menuScrollable = find.descendant(
        of: menu, matching: find.byType(Scrollable));
    expect(menuScrollable, findsOneWidget);
    // Sem .last: a busca pode estar vazia antes de construir o item na rolagem.
    final showroom = find.text('Showroom');
    await tester.scrollUntilVisible(showroom, 150,
        scrollable: menuScrollable);
    await tester.pumpAndSettle();
    expect(showroom.hitTestable(), findsOneWidget);
    await tester.tap(showroom.hitTestable());
    await tester.pumpAndSettle();
    expect(provider.current!.area, 'Showroom');
    expect(provider.current!.items.length, 14);
    expect(provider.current!.items.every((item) => item.score == null), isTrue);
    expect(repo.writes, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('history distinguishes administrative and production areas', (tester) async {
    final repo = MemoryAuditRepository();
    for (final area in ['Showroom', 'Solda']) {
      repo.audits[area] = Audit(id: area, responsavel: '', area: area,
        auditor: '', acompanhante: '', data: DateTime(2026, 9, 1), mesReferencia: 'Setembro');
    }
    final provider = AuditProvider(repo);
    addTearDown(provider.dispose);
    await tester.pumpWidget(ChangeNotifierProvider.value(value: provider,
      child: MaterialApp(theme: AppTheme.light, home: const HistoryScreen())));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Setembro'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.computer_outlined), findsOneWidget);
    expect(find.byIcon(Icons.factory_outlined), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('last sector scrolls above Android navigation with extra clearance', (tester) async {
    tester.view.physicalSize = const Size(390, 700);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(bottom: 48);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    final provider = AuditProvider(MemoryAuditRepository());
    addTearDown(provider.dispose);
    await tester.pumpWidget(ChangeNotifierProvider.value(value: provider,
      child: MaterialApp(theme: AppTheme.light, home: const IndicatorsScreen())));
    await tester.pumpAndSettle();
    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable).first);
    scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
    await tester.pumpAndSettle();
    final bottom = tester.getBottomLeft(find.widgetWithText(ActionChip, 'Showroom')).dy;
    expect(bottom, lessThanOrEqualTo(700 - 48 - 40));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
