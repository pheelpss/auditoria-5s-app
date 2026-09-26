import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auditoria_5s/domain/entities/evidence.dart';
import 'package:auditoria_5s/presentation/widgets/evidence_picker.dart';
import 'package:auditoria_5s/presentation/screens/evidence_gallery_screen.dart';

Evidence photo(String id) => Evidence(id: id, filePath: '/missing/$id.png',
    fileName: '$id.png', type: EvidenceType.photo);

void main() {
  testWidgets('opens selected photo, excludes documents, navigates and preserves form', (tester) async {
    int changes = 0;
    final evidences = [photo('a'), Evidence(id: 'pdf', filePath: '/file.pdf',
        fileName: 'file.pdf', type: EvidenceType.file), photo('b'), photo('c')];
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: EvidencePicker(
      evidences: evidences, onChanged: (_) => changes++,
    ))));
    await tester.tap(find.bySemanticsLabel('Ampliar foto b.png'));
    await tester.pumpAndSettle();
    expect(find.byType(EvidenceGalleryScreen), findsOneWidget);
    expect(find.text('2 / 3'), findsOneWidget);
    await tester.tap(find.byTooltip('Próxima foto'));
    await tester.pumpAndSettle();
    expect(find.text('3 / 3'), findsOneWidget);
    expect(tester.widget<IconButton>(find.byTooltip('Próxima foto')).onPressed, isNull);
    await tester.tap(find.byTooltip('Foto anterior'));
    await tester.pumpAndSettle();
    expect(find.text('2 / 3'), findsOneWidget);
    await tester.drag(find.byKey(const Key('evidence-gallery-pages')), const Offset(600, 0));
    await tester.pumpAndSettle();
    expect(find.text('1 / 3'), findsOneWidget);
    expect(tester.widget<IconButton>(find.byTooltip('Foto anterior')).onPressed, isNull);
    await tester.tap(find.byTooltip('Fechar fotos'));
    await tester.pumpAndSettle();
    expect(find.byType(EvidenceGalleryScreen), findsNothing);
    expect(find.byType(EvidencePicker), findsOneWidget);
    expect(changes, 0);
    expect(evidences.length, 4);
  });

  testWidgets('single unavailable image keeps close button and disables arrows', (tester) async {
    await tester.pumpWidget(MaterialApp(home: EvidenceGalleryScreen(
      photos: [photo('unavailable')], initialIndex: 0,
    )));
    await tester.pumpAndSettle();
    expect(find.text('1 / 1'), findsOneWidget);
    expect(tester.widget<IconButton>(find.byTooltip('Foto anterior')).onPressed, isNull);
    expect(tester.widget<IconButton>(find.byTooltip('Próxima foto')).onPressed, isNull);
    expect(find.byTooltip('Fechar fotos'), findsOneWidget);
  });
}
