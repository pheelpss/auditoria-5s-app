import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Portrait-first opening. It never adds a menu or a route to the back stack.
class OpeningScreen extends StatefulWidget {
  const OpeningScreen({super.key, required this.onFinished});
  final VoidCallback onFinished;

  @override
  State<OpeningScreen> createState() => _OpeningScreenState();
}

class _OpeningScreenState extends State<OpeningScreen>
    with TickerProviderStateMixin {
  late final AnimationController _ambient;
  late final AnimationController _exit;
  Timer? _timer;
  bool _leaving = false;
  bool _started = false;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _ambient = AnimationController(vsync: this, duration: const Duration(seconds: 7));
    _exit = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.of(context).disableAnimations;
    if (_reduceMotion) {
      _ambient.stop();
    } else if (!_ambient.isAnimating) {
      _ambient.repeat(reverse: true);
    }
    if (!_started) {
      _started = true;
      _prepareLogo();
    }
  }

  Future<void> _prepareLogo() async {
    await precacheImage(const AssetImage('assets/branding/logo_5s.png'), context);
    if (!mounted || _leaving) return;
    _timer = Timer(Duration(milliseconds: _reduceMotion ? 600 : 2800), _finish);
  }

  Future<void> _finish() async {
    if (_leaving || !mounted) return;
    _leaving = true;
    _timer?.cancel();
    if (!_reduceMotion) {
      try {
        await _exit.forward().orCancel;
      } on TickerCanceled {
        return;
      }
    }
    if (mounted) widget.onFinished();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ambient.dispose();
    _exit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF030711),
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF030711),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF030711),
        body: AnimatedBuilder(
          animation: Listenable.merge([_ambient, _exit]),
          builder: (context, _) {
            final phase = _ambient.value;
            final exit = Curves.easeInOutCubic.transform(_exit.value);
            final pulse = _reduceMotion ? 0.0 : math.sin(phase * math.pi);
            return Opacity(
              opacity: 1 - exit,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(painter: _AmbientPainter(phase)),
                  SafeArea(
                    child: LayoutBuilder(builder: (context, bounds) {
                      final logoSize = math.min(340.0,
                          math.min(bounds.maxWidth * .80, bounds.maxHeight * .48));
                      return Center(
                        child: Transform.translate(
                          offset: Offset(0, -28 * exit),
                          child: Transform.scale(
                            scale: 1 + pulse * .025 - exit * .08,
                            child: Semantics(
                              button: true,
                              label: 'Entrar na auditoria 5S',
                              child: GestureDetector(
                                key: const Key('opening-logo'),
                                onTap: _finish,
                                behavior: HitTestBehavior.opaque,
                                child: Container(
                                  width: logoSize,
                                  height: logoSize,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [BoxShadow(
                                      color: const Color(0xFF00BFFF).withOpacity(.035 + pulse * .045),
                                      blurRadius: 48 + pulse * 20,
                                      spreadRadius: 4,
                                    )],
                                  ),
                                  child: Image.asset('assets/branding/logo_5s.png',
                                      fit: BoxFit.contain, excludeFromSemantics: true),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AmbientPainter extends CustomPainter {
  const _AmbientPainter(this.phase);
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    void glow(Alignment center, Color color) {
      canvas.drawRect(rect, Paint()..shader = RadialGradient(
        center: center,
        radius: .95,
        colors: [color, color.withOpacity(0)],
      ).createShader(rect));
    }
    glow(Alignment(-.7 + phase * .3, -.4), const Color(0x2222BCF2));
    glow(Alignment(.8 - phase * .3, .65), const Color(0x22693DF0));
    final line = Paint()..color = const Color(0x0875BFFF)..strokeWidth = .5;
    final offset = phase * 30;
    for (double x = -48 + offset; x < size.width; x += 48) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    for (double y = -48 + offset; y < size.height; y += 48) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
    for (int i = 0; i < 18; i++) {
      final x = ((i * 79.0 + 23) % size.width);
      final y = ((i * 137.0 + phase * 22) % size.height);
      canvas.drawCircle(Offset(x, y), i.isEven ? 1.0 : 1.5,
          Paint()..color = const Color(0x2663D9F5));
    }
  }

  @override
  bool shouldRepaint(_AmbientPainter oldDelegate) => oldDelegate.phase != phase;
}
