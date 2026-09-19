import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'core/theme/app_theme.dart';
import 'data/repositories/audit_repository_impl.dart';
import 'presentation/providers/audit_provider.dart';
import 'presentation/screens/history_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
    if (files.isEmpty) return;
    final backup = files.where((f) => f.path.toLowerCase().endsWith('.5s'));
    if (backup.isEmpty) return;
    final path = backup.first.path;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _navigatorKey.currentContext;
      if (context != null) _confirmImport(context, path);
    });
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
        home: const HistoryScreen(),
      ),
    );
  }
}
