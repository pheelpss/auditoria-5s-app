import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

/// Plays the bundled introduction once, without adding a navigation route.
class OpeningScreen extends StatefulWidget {
  const OpeningScreen({super.key, required this.onFinished});
  final VoidCallback onFinished;

  @override
  State<OpeningScreen> createState() => _OpeningScreenState();
}

class _OpeningScreenState extends State<OpeningScreen> {
  static const _introDuration = Duration(seconds: 5);
  VideoPlayerController? _video;
  Timer? _timer;
  bool _started = false;
  bool _leaving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.of(context).disableAnimations) {
      _timer = Timer(const Duration(milliseconds: 600), _finish);
    } else {
      unawaited(_prepareVideo());
    }
  }

  Future<void> _prepareVideo() async {
    final video = VideoPlayerController.asset(
      'assets/branding/ondexa-opening.mp4',
    );
    _video = video;
    // A stalled initialization must not block the app.
    _timer = Timer(const Duration(seconds: 8), _finish);
    try {
      await video.initialize();
      if (!mounted || _leaving) return;
      await video.setLooping(false);
      if (!mounted || _leaving) return;
      // The supplied clip is six seconds; fit the whole animation into five.
      if (video.value.duration > _introDuration) {
        await video.setPlaybackSpeed(
          video.value.duration.inMilliseconds / _introDuration.inMilliseconds,
        );
        if (!mounted || _leaving) return;
      }
      video.addListener(_checkPlayback);
      setState(() {});
      await video.play();
      if (!mounted || _leaving) return;
      _timer?.cancel();
      // Start the five-second window only after the player starts.
      _timer = Timer(_introDuration, _finish);
    } catch (_) {
      _finish();
    }
  }

  void _checkPlayback() {
    final value = _video?.value;
    if (value == null || _leaving) return;
    if (value.hasError ||
        value.isCompleted ||
        value.position >= _introDuration) {
      _finish();
    }
  }

  void _finish() {
    if (!mounted || _leaving) return;
    _leaving = true;
    _timer?.cancel();
    // A tap advances immediately, including while the video loads.
    widget.onFinished();
  }

  @override
  void dispose() {
    _timer?.cancel();
    final video = _video;
    if (video != null) {
      video.removeListener(_checkPlayback);
      unawaited(video.dispose());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final video = _video;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF030711),
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF030711),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF030711),
        body: GestureDetector(
          key: const Key('opening-logo'),
          behavior: HitTestBehavior.opaque,
          onTap: _finish,
          child: Semantics(
            button: true,
            label: 'Pular abertura e entrar na auditoria 5S',
            child: SizedBox.expand(
              child: video != null && video.value.isInitialized
                  ? Center(
                      child: AspectRatio(
                        aspectRatio: video.value.aspectRatio,
                        child: VideoPlayer(video),
                      ),
                    )
                  : Image.asset(
                      'assets/branding/ondexa-opening-portrait.png',
                      fit: BoxFit.contain,
                      excludeFromSemantics: true,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
