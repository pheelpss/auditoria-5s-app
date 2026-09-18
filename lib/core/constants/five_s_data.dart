/// Pergunta de um item do checklist 5S.
class FiveSQuestion {
  final String number; // ex: "1.1"
  final String text;
  const FiveSQuestion(this.number, this.text);
}

/// Definição estática de uma categoria (senso) do 5S, com suas perguntas.
class FiveSCategoryDef {
  final String code; // "1S".."5S"
  final String senseName; // Seiri, Seiton, ...
  final String title; // Nome completo da categoria
  final List<FiveSQuestion> questions;
  const FiveSCategoryDef({
    required this.code,
    required this.senseName,
    required this.title,
    required this.questions,
  });

  String get displayTitle => '$code – $title ($senseName)';
}

/// Meses de referência disponíveis no seletor.
const List<String> mesesReferencia = [
  'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
  'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
];

/// Estrutura completa da auditoria 5S conforme o formulário oficial.
final List<FiveSCategoryDef> fiveSCategories = [
  const FiveSCategoryDef(
    code: '1S',
    senseName: 'Seiri',
    title: 'Separação, Utilização e Descarte',
    questions: [
      FiveSQuestion('1.1', 'Existem materiais a serem descartados (obsoletos ou inutilizáveis)?'),
      FiveSQuestion('1.2', 'Existem objetos pessoais no setor, sobre armários ou sobre equipamentos?'),
      FiveSQuestion('1.3', 'Existe material que não pertence ao ambiente?'),
      FiveSQuestion('1.4', 'Existe local apropriado para descarte de lixo, material obsoleto ou para reciclar?'),
      FiveSQuestion('1.5', 'Máquinas, ferramentas e instalações estão sendo utilizadas corretamente?'),
      FiveSQuestion('1.6', 'Há separação correta de resíduos?'),
    ],
  ),
  const FiveSCategoryDef(
    code: '2S',
    senseName: 'Seiton',
    title: 'Organização',
    questions: [
      FiveSQuestion('2.1', 'Localização da área está identificada claramente?'),
      FiveSQuestion('2.2', 'A disposição atual do prédio, máquina ou equipamento propicia acidentes?'),
      FiveSQuestion('2.3', 'Armários, prateleiras, arquivos, portas e gavetas estão identificados?'),
      FiveSQuestion('2.4', 'Há local próprio para ferramentas e equipamentos?'),
    ],
  ),
  const FiveSCategoryDef(
    code: '3S',
    senseName: 'Seiso',
    title: 'Limpeza',
    questions: [
      FiveSQuestion('3.1', 'O piso, paredes, janelas e teto estão limpos e bem apresentáveis?'),
      FiveSQuestion('3.2', 'As lâmpadas e tomadas estão conservadas?'),
      FiveSQuestion('3.3', 'Os sanitários estão limpos e conservados?'),
      FiveSQuestion('3.4', 'As pessoas estão conscientizadas das boas práticas de limpeza?'),
    ],
  ),
  const FiveSCategoryDef(
    code: '4S',
    senseName: 'Seiketsu',
    title: 'Padronização',
    questions: [
      FiveSQuestion('4.1', 'A área está padronizada com etiquetas ou placas padrão?'),
      FiveSQuestion('4.2', 'O ambiente físico é favorável à higiene e saúde?'),
      FiveSQuestion('4.3', 'Procedimentos, formulários e registros estão padronizados?'),
      FiveSQuestion('4.4', 'A iluminação é apropriada e suficiente?'),
      FiveSQuestion('4.5', 'As pessoas conhecem os padrões existentes?'),
      FiveSQuestion('4.6', 'Extintores e outras ferramentas são localizáveis?'),
    ],
  ),
  const FiveSCategoryDef(
    code: '5S',
    senseName: 'Shitsuke',
    title: 'Disciplina',
    questions: [
      FiveSQuestion('5.1', 'Os funcionários demonstram interesse nas atividades 5S?'),
      FiveSQuestion('5.2', 'Cartazes e lembretes estão exibidos no ambiente?'),
      FiveSQuestion('5.3', 'Treinamentos e programas são implementados para sustentar a organização?'),
      FiveSQuestion('5.4', 'Os procedimentos de segurança são seguidos?'),
    ],
  ),
];

/// Rótulos de classificação conforme a nota geral (0 a 5).
String classificacaoParaNota(double nota) {
  if (nota < 1) return 'Muito Ruim';
  if (nota < 2) return 'Ruim';
  if (nota < 3) return 'Regular';
  if (nota < 4) return 'Bom';
  if (nota < 5) return 'Muito Bom';
  return 'Atende Plenamente';
}
