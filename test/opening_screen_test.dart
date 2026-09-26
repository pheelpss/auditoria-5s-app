import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auditoria_5s/presentation/screens/opening_screen.dart';

void main() {
  Future<void> open(WidgetTester tester, VoidCallback finish) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: OpeningScreen(onFinished: finish)));
    await tester.runAsync(() => precacheImage(
      const AssetImage('assets/branding/logo_5s.png'),
      tester.element(find.byType(OpeningScreen)),
    ));
    await tester.pump();
  }

  testWidgets('portrait opening has only the logo and accepts a tap once', (tester) async {
    int completed = 0;
    await open(tester, () => completed++);
    expect(find.byKey(const Key('opening-logo')), findsOneWidget);
    expect(find.text('Dashboard'), findsNothing);
    expect(find.text('Gerador de Apresentações'), findsNothing);
    await tester.tap(find.byKey(const Key('opening-logo')));
    await tester.tap(find.byKey(const Key('opening-logo')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(completed, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('continues automatically after the opening', (tester) async {
    int completed = 0;
    await open(tester, () => completed++);
    await tester.pump(const Duration(milliseconds: 2800));
    await tester.pump(const Duration(milliseconds: 500));
    expect(completed, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('disposing early cancels completion', (tester) async {
    int completed = 0;
    await open(tester, () => completed++);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 5));
    expect(completed, 0);
    expect(tester.takeException(), isNull);
  });
}
