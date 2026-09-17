import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'data/repositories/audit_repository_impl.dart';
import 'presentation/providers/audit_provider.dart';
import 'presentation/screens/history_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const Auditoria5SApp());
}

class Auditoria5SApp extends StatelessWidget {
  const Auditoria5SApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuditProvider(AuditRepositoryImpl()),
      child: MaterialApp(
        title: 'Auditoria 5S',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const HistoryScreen(),
      ),
    );
  }
}
