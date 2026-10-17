import 'package:auditoria_5s/core/theme/app_theme.dart';
import 'package:auditoria_5s/presentation/providers/audit_provider.dart';
import 'package:auditoria_5s/presentation/screens/audit_form_screen.dart';
import 'package:auditoria_5s/presentation/widgets/score_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'audit_draft_test.dart' show MemoryAuditRepository;

void main() {
  for (final fillHeader in [false, true]) {
    testWidgets('sector opened and back: header=$fillHeader', (tester) async {
      final repository = MemoryAuditRepository();
      final provider = AuditProvider(repository);
      addTearDown(provider.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: MaterialApp(
            theme: AppTheme.light,
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () {
                    provider.startNewAuditFor(
                      area: 'PCP',
                      mesReferencia: 'Outubro',
                    );
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const AuditFormScreen(),
                      ),
                    );
                  },
                  child: const Text('Abrir PCP'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Abrir PCP'));
      await tester.pumpAndSettle();
      if (fillHeader) {
        await tester.enterText(
          find.widgetWithText(TextField, 'Nome do Responsável'),
          'Maria',
        );
        await tester.pumpAndSettle();
      }
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(repository.audits.length, fillHeader ? 1 : 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('score dropdown allows zero and then clearing the response', (
    tester,
  ) async {
    int? score;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => ScoreDropdown(
              value: score,
              onChanged: (value) => setState(() => score = value),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(DropdownButton<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('0').last);
    await tester.pumpAndSettle();
    expect(score, 0);
    await tester.tap(find.byType(DropdownButton<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('—').last);
    await tester.pumpAndSettle();
    expect(score, isNull);
  });
}
