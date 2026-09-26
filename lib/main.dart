import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'core/theme/app_theme.dart';
import 'data/repositories/audit_repository_impl.dart';
import 'presentation/providers/audit_provider.dart';
import 'presentation/screens/history_screen.dart';
import 'presentation/screens/opening_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const Auditoria5SApp());
}

class Auditoria5SApp extends StatefulWidget {
  const Auditoria5SApp({super.key});

  @override
  State<Auditoria5SApp> createState() => _Auditoria5SAppState();
}

class _Auditoria5SAppState extends State<Auditoria5SApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<List<SharedMediaFile>>? _intentSub;
  bool _openingComplete = false;
  bool _importing = false;
  final List<String> _pendingImports = [];

  void _finishOpening() {
    if (!mounted || _openingComplete) return;
    setState(() => _openingComplete = true);
    // Only the opening requests portrait. Restore the original app policy.
    unawaited(SystemChrome.setPreferredOrientations([]));
    WidgetsBinding.instance.addPostFrameCallback((_) => _drainImports());
  }

  Future<void> _drainImports() async {
    if (!mounted || !_openingComplete || _importing) return;
    final context = _navigatorKey.currentContext;
    if (context == null) return;
    _importing = true;
    try {
      while (mounted && context.mounted && _pendingImports.isNotEmpty) {
        await _confirmImport(context, _pendingImports.removeAt(0));
      }
    } finally {
      _importing = false;
    }
  }

  @override
  void initState() {
    super.initState();

    // Arquivo .5s recebido enquanto o app já está aberto (em segundo plano).
    _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen(
      _handleSharedFiles,
      onError: (_) {},
    );

    // Arquivo .5s que abriu o app agora mesmo (app estava fechado e o
    // usuário tocou no arquivo recebido pelo WhatsApp/e-mail/etc.).
    ReceiveSharingIntent.instance.getInitialMedia().then((files) {
      _handleSharedFiles(files);
      ReceiveSharingIntent.instance.reset();
    });
  }

  void _handleSharedFiles(List<SharedMediaFile> files) {
    if (!mounted || files.isEmpty) return;
    _pendingImports.add(files.first.path);
    if (_openingComplete) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _drainImports());
      WidgetsBinding.instance.ensureVisualUpdate();
    }
  }

  Future<void> _confirmImport(BuildContext context, String path) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Importar auditorias?'),
        content: const Text(
          'Foi recebido um arquivo de backup de auditorias 5S. Deseja importar agora? '
          'As auditorias contidas nele serão adicionadas (ou substituídas, se já existirem) no seu aplicativo.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Importar')),
        ],
      ),
    );
    if (confirmar == true && context.mounted) {
      await context.read<AuditProvider>().importDataFromPath(path, context);
    }
  }

  @override
  void dispose() {
    _intentSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuditProvider(AuditRepositoryImpl()),
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        title: 'Auditoria 5S',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: _openingComplete
            ? const HistoryScreen()
            : OpeningScreen(onFinished: _finishOpening),
      ),
    );
  }
}
