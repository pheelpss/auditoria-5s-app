import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Oculta somente a navegação. O Android controla a revelação por gesto.
class AndroidNavigationPolicy extends StatefulWidget {
  const AndroidNavigationPolicy({super.key, required this.child});
  final Widget child;

  @override
  State<AndroidNavigationPolicy> createState() =>
      _AndroidNavigationPolicyState();
}

class _AndroidNavigationPolicyState extends State<AndroidNavigationPolicy>
    with WidgetsBindingObserver {
  static const _channel = MethodChannel('ondexa/navigation');
  Timer? _restore;
  bool _keyboardVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _hideNavigation());
  }

  Future<void> _hideNavigation() async {
    if (!mounted ||
        kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android ||
        _keyboardVisible)
      return;
    try {
      await _channel.invokeMethod<void>('hideNavigation');
    } on MissingPluginException {
      // Plataformas sem implementação continuam com navegação normal.
    } on PlatformException {
      // Se o sistema não permitir, não impede o uso do aplicativo.
    }
  }

  void _scheduleRestore() {
    _restore?.cancel();
    _restore = Timer(const Duration(milliseconds: 1100), _hideNavigation);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _scheduleRestore();
    } else {
      _restore?.cancel();
    }
  }

  @override
  void didChangeMetrics() {
    final visible = WidgetsBinding.instance.platformDispatcher.views.any(
      (view) => view.viewInsets.bottom > 0,
    );
    if (visible) _restore?.cancel();
    if (_keyboardVisible && !visible) _scheduleRestore();
    _keyboardVisible = visible;
  }

  @override
  void dispose() {
    _restore?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
