import '../../domain/entities/audit.dart';
import '../constants/five_s_data.dart';

/// Agrupa auditorias em Ano → Mês → Área, na ordem: anos mais recentes
/// primeiro, meses na ordem do calendário (usando [mesesReferencia]) e
/// áreas em ordem alfabética.
List<YearGroup> groupAuditsByYearMonthArea(List<Audit> audits) {
  final byYear = <int, Map<String, Map<String, List<Audit>>>>{};

  for (final audit in audits) {
    final year = audit.data.year;
    final mes = audit.mesReferencia;
    final area = audit.area.trim().isEmpty ? '(Área não informada)' : audit.area.trim();

    byYear.putIfAbsent(year, () => {});
    byYear[year]!.putIfAbsent(mes, () => {});
    byYear[year]![mes]!.putIfAbsent(area, () => []);
    byYear[year]![mes]![area]!.add(audit);
  }

  final years = byYear.keys.toList()..sort((a, b) => b.compareTo(a));

  return years.map((year) {
    final months = byYear[year]!.keys.toList()
      ..sort((a, b) => mesesReferencia.indexOf(a).compareTo(mesesReferencia.indexOf(b)));
    return YearGroup(
      year: year,
      months: months.map((mes) {
        final areas = byYear[year]![mes]!.keys.toList()..sort();
        return MonthGroup(
          mes: mes,
          areas: areas
              .map((area) => AreaGroup(area: area, audits: byYear[year]![mes]![area]!))
              .toList(),
        );
      }).toList(),
    );
  }).toList();
}

class YearGroup {
  final int year;
  final List<MonthGroup> months;
  YearGroup({required this.year, required this.months});

  int get totalAudits => months.fold(0, (acc, m) => acc + m.totalAudits);
}

class MonthGroup {
  final String mes;
  final List<AreaGroup> areas;
  MonthGroup({required this.mes, required this.areas});

  int get totalAudits => areas.fold(0, (acc, a) => acc + a.audits.length);
}

class AreaGroup {
  final String area;
  final List<Audit> audits;
  AreaGroup({required this.area, required this.audits});
}
