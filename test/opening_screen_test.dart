import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:auditoria_5s/presentation/screens/opening_screen.dart';

class FakeVideoPlatform extends VideoPlayerPlatform {
  final events = StreamController<VideoEvent>.broadcast();
  bool initializeAutomatically = true;
  bool failCreation = false;
  bool played = false;
  bool disposed = false;
  double speed = 1;
  DataSource? source;

  void initializeVideo() => events.add(VideoEvent(
        eventType: VideoEventType.initialized,
        duration: const Duration(seconds: 6),
        size: const Size(720, 1280),
      ));

  @override
  Future<void> init() async {}
  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    source = options.dataSource;
    return 1;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) {
    if (failCreation) {
      scheduleMicrotask(() => events.addError(
          PlatformException(code: 'decoder', message: 'Decoder unavailable')));
    } else if (initializeAutomatically) {
      scheduleMicrotask(initializeVideo);
    }
    return events.stream;
  }

  @override
  Future<void> dispose(int playerId) async {
    disposed = true;
  }

  @override
  Future<void> setLooping(int playerId, bool looping) async {}
  @override
  Future<void> play(int playerId) async {
    played = true;
  }

  @override
  Future<void> pause(int playerId) async {}
  @override
  Future<void> setVolume(int playerId, double volume) async {}
  @override
  Future<void> seekTo(int playerId, Duration position) async {}
  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {
    this.speed = speed;
  }

  @override
  Future<Duration> getPosition(int playerId) async => Duration.zero;
  @override
  Widget buildViewWithOptions(VideoViewOptions options) =>
      const ColoredBox(color: Colors.black, key: Key('fake-video'));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeVideoPlatform platform;
  late VideoPlayerPlatform original;
  setUp(() {
    original = VideoPlayerPlatform.instance;
    platform = FakeVideoPlatform();
    VideoPlayerPlatform.instance = platform;
  });
  tearDown(() async {
    await platform.events.close();
    VideoPlayerPlatform.instance = original;
  });

  Future<void> open(WidgetTester tester, VoidCallback finish,
      {bool reduceMotion = false}) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: OpeningScreen(onFinished: finish),
      ),
    ));
    await tester.pump();
    await tester.pump();
  }

  testWidgets(
      'plays bundled portrait clip and fits whole animation into five seconds',
      (tester) async {
    int completed = 0;
    await open(tester, () => completed++);
    expect(platform.source?.sourceType, DataSourceType.asset);
    expect(platform.source?.asset, 'assets/branding/ondexa-opening.mp4');
    expect(platform.played, isTrue);
    expect(platform.speed, closeTo(1.2, .001));
    expect(find.byKey(const Key('fake-video')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 4999));
    expect(completed, 0);
    await tester.pump(const Duration(milliseconds: 1));
    expect(completed, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    expect(platform.disposed, isTrue);
  });

  testWidgets('tap anywhere skips immediately and only once', (tester) async {
    int completed = 0;
    await open(tester, () => completed++);
    await tester.tapAt(const Offset(2, 2));
    expect(completed, 1);
    await tester.tapAt(const Offset(388, 842));
    await tester.pump(const Duration(seconds: 6));
    expect(completed, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('five seconds starts after slow initialization', (tester) async {
    platform.initializeAutomatically = false;
    int completed = 0;
    await open(tester, () => completed++);
    await tester.pump(const Duration(seconds: 3));
    expect(completed, 0);
    platform.initializeVideo();
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 4999));
    expect(completed, 0);
    await tester.pump(const Duration(milliseconds: 1));
    expect(completed, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('can skip before initialization and never starts playback later',
      (tester) async {
    platform.initializeAutomatically = false;
    int completed = 0;
    await open(tester, () => completed++);
    await tester.tapAt(const Offset(20, 100));
    expect(completed, 1);
    platform.initializeVideo();
    await tester.pump();
    expect(platform.played, isFalse);
    await tester.pump(const Duration(seconds: 10));
    expect(completed, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('decoder failure advances without trapping the user',
      (tester) async {
    platform.failCreation = true;
    int completed = 0;
    await open(tester, () => completed++);
    expect(completed, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('stalled initialization has an eight-second safety limit',
      (tester) async {
    platform.initializeAutomatically = false;
    int completed = 0;
    await open(tester, () => completed++);
    await tester.pump(const Duration(seconds: 8));
    expect(completed, 1);
    platform.initializeVideo();
    await tester.pump();
    expect(platform.played, isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('playback completion and error advance only once',
      (tester) async {
    int completed = 0;
    await open(tester, () => completed++);
    platform.events.add(VideoEvent(eventType: VideoEventType.completed));
    await tester.pump();
    expect(completed, 1);
    await tester.pump(const Duration(seconds: 5));
    expect(completed, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('playback error advances immediately', (tester) async {
    int completed = 0;
    await open(tester, () => completed++);
    platform.events.addError(
        PlatformException(code: 'playback', message: 'Playback failed'));
    await tester.pump();
    expect(completed, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('disposing early cancels completion and frees the player',
      (tester) async {
    int completed = 0;
    await open(tester, () => completed++);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    expect(completed, 0);
    expect(platform.disposed, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion uses the static logo without playing video',
      (tester) async {
    int completed = 0;
    await open(tester, () => completed++, reduceMotion: true);
    expect(platform.source, isNull);
    await tester.pump(const Duration(milliseconds: 600));
    expect(completed, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
