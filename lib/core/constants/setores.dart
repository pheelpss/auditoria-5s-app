/// Lista fixa dos setores/áreas que devem ser auditados todo mês.
/// Usada na tela de Indicadores para mostrar o que ainda falta auditar.
const List<String> setoresAuditaveis = [
  'ADM',
  'Repuxo',
  'Recebimento',
  'MTG Hera',
  'MKT',
  'Manutenção ADM',
  'Almoxarifado',
  'Teste Titan',
  'Área Externa',
  'Metálicos',
  'Leves',
  'Eng. Produto',
  'Tubos',
  'Manutenção Fab',
  'RH',
  'Laser',
  'Balanceamento',
  'Resíduos',
  'Dobra',
  'Solda',
  'QA',
  'Pintura',
  'P&D',
  'Financeiro',
  'ADM Vendas',
  'MTG Voluta',
  'Serralheria',
  'CL',
  'Processos',
  'PCP',
  'SST',
  'TI',
];

const List<String> setoresAdministrativos = [
  'ADM', 'Eng. Produto', 'Manutenção ADM', 'PCP', 'MKT', 'Processos',
  'SST', 'P&D', 'TI', 'ADM Vendas', 'QA', 'Financeiro', 'RH',
];

const List<String> setoresProducao = [
  'Balanceamento', 'Manutenção Fab', 'Almoxarifado', 'Solda',
  'Área Externa', 'CL', 'MTG Hera', 'Repuxo', 'Laser', 'Pintura',
  'Serralheria', 'Metálicos', 'Recebimento', 'Dobra', 'Leves',
  'MTG Voluta', 'Teste Titan', 'Tubos', 'Resíduos',
];

String? areaConhecida(String name) {
  final normalized = name.trim().toLowerCase();
  for (final area in [...setoresAdministrativos, ...setoresProducao]) {
    if (area.toLowerCase() == normalized) return area;
  }
  return null;
}

bool isAdministrativa(String name) =>
    setoresAdministrativos.contains(areaConhecida(name));
