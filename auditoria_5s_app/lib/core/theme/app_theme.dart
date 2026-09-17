import 'package:flutter/material.dart';

/// Tema visual do aplicativo — Material Design 3, paleta corporativa
/// pensada para uso industrial (bom contraste, botões grandes para toque
/// com luva, cores de status claras).
class AppTheme {
  AppTheme._();

  static const Color primary = Color(0xFF0B5FA5);
  static const Color secondary = Color(0xFF00897B);
  static const Color background = Color(0xFFF4F6F8);
  static const Color surface = Colors.white;

  static const Color muitoRuim = Color(0xFFC62828);
  static const Color ruim = Color(0xFFEF6C00);
  static const Color regular = Color(0xFFF9A825);
  static const Color bom = Color(0xFF7CB342);
  static const Color muitoBom = Color(0xFF388E3C);
  static const Color atendePlenamente = Color(0xFF1B5E20);

  static Color colorForScore(double score) {
    if (score < 1) return muitoRuim;
    if (score < 2) return ruim;
    if (score < 3) return regular;
    if (score < 4) return bom;
    if (score < 5) return muitoBom;
    return atendePlenamente;
  }

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        surface: surface,
      ),
      scaffoldBackgroundColor: background,
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 1.5,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFD0D7DE)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
