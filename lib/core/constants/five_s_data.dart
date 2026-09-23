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

/// Checklists dos modelos oficiais; as respostas antigas mantêm suas perguntas salvas.
const List<FiveSCategoryDef> administrativeCategories = [
  FiveSCategoryDef(code: '1S', senseName: 'Seiri', title: 'Separação, Utilização e Descarte', questions: [
    FiveSQuestion('1.1', 'Não há papéis, materiais ou itens obsoletos em mesas, gavetas e armários.'),
    FiveSQuestion('1.2', 'Documentos e arquivos físicos vencidos são descartados ou arquivados conforme o prazo de guarda.'),
    FiveSQuestion('1.3', 'Não há móveis, equipamentos ou cabos sem uso ou pertencentes a outros setores.'),
    FiveSQuestion('1.4', 'Arquivos digitais (área de trabalho, rede, e-mail) estão sem duplicados e versões antigas.'),
    FiveSQuestion('1.5', 'Objetos pessoais ficam em gaveta ou local definido, sem excesso sobre mesas e equipamentos.'),
    FiveSQuestion('1.6', 'Resíduos são separados corretamente e documentos sigilosos são destruídos com segurança.'),
  ]),
  FiveSCategoryDef(code: '2S', senseName: 'Seiton', title: 'Organização', questions: [
    FiveSQuestion('2.1', 'A área, as salas e os postos de trabalho estão identificados claramente.'),
    FiveSQuestion('2.2', 'As mesas estão organizadas, apenas com o material em uso (mesa limpa).'),
    FiveSQuestion('2.3', 'Armários, gavetas, pastas e arquivos estão identificados e organizados por critério definido.'),
    FiveSQuestion('2.4', 'Materiais de escritório e equipamentos de uso comum têm local definido e identificado.'),
  ]),
  FiveSCategoryDef(code: '3S', senseName: 'Seiso', title: 'Limpeza', questions: [
    FiveSQuestion('3.1', 'Piso, paredes, janelas, teto, lâmpadas e tomadas estão limpos e bem conservados.'),
    FiveSQuestion('3.2', 'Mesas, computadores, teclados e telefones estão limpos.'),
    FiveSQuestion('3.3', 'Sanitários, copa e áreas de convivência estão limpos e conservados.'),
    FiveSQuestion('3.4', 'Salas de reunião e áreas comuns são deixadas limpas e organizadas após o uso.'),
  ]),
  FiveSCategoryDef(code: '4S', senseName: 'Seiketsu', title: 'Padronização', questions: [
    FiveSQuestion('4.1', 'Há padrões visuais (placas, etiquetas, murais) e quadros 5S expostos e atualizados.'),
    FiveSQuestion('4.2', 'Procedimentos, formulários e modelos de documento estão padronizados, atualizados e acessíveis.'),
    FiveSQuestion('4.3', 'Iluminação, climatização e ergonomia (cadeira, mesa, monitor) são adequadas ao trabalho.'),
    FiveSQuestion('4.4', 'Extintores e saídas de emergência estão sinalizados e desobstruídos, sem cabos soltos.'),
    FiveSQuestion('4.5', 'Pastas de rede e arquivos digitais seguem estrutura e nomenclatura padronizadas.'),
    FiveSQuestion('4.6', 'Existe cronograma ou checklist de limpeza e organização definido e visível no setor.'),
  ]),
  FiveSCategoryDef(code: '5S', senseName: 'Shitsuke', title: 'Disciplina', questions: [
    FiveSQuestion('5.1', 'Os colaboradores conhecem e seguem os padrões e a rotina 5S do setor.'),
    FiveSQuestion('5.2', 'Ao fim do expediente, mesas e equipamentos são deixados organizados e desligados.'),
    FiveSQuestion('5.3', 'Os colaboradores seguem as regras de segurança, ergonomia e sigilo de informações.'),
    FiveSQuestion('5.4', 'Novos colaboradores recebem orientação 5S e há reciclagem periódica da equipe.'),
  ]),
];

const List<FiveSCategoryDef> productionCategories = [
  FiveSCategoryDef(code: '1S', senseName: 'Seiri', title: 'Separação, Utilização e Descarte', questions: [
    FiveSQuestion('1.1', 'Não há materiais, peças ou embalagens obsoletos ou sem uso na área.'),
    FiveSQuestion('1.2', 'Há no posto só o material necessário à produção, sem excesso de estoque em processo.'),
    FiveSQuestion('1.3', 'Não há objetos pessoais ou itens alheios ao setor sobre máquinas, bancadas e armários.'),
    FiveSQuestion('1.4', 'Máquinas, ferramentas e dispositivos fora de uso estão removidos ou identificados.'),
    FiveSQuestion('1.5', 'Material não conforme e retrabalho estão segregados e identificados.'),
    FiveSQuestion('1.6', 'Resíduos (cavaco, sucata, óleo, embalagens) são separados em coletores adequados.'),
  ]),
  FiveSCategoryDef(code: '2S', senseName: 'Seiton', title: 'Organização', questions: [
    FiveSQuestion('2.1', 'A área, os setores e os postos de trabalho estão identificados claramente.'),
    FiveSQuestion('2.2', 'Materiais, paletes e carrinhos ficam em locais demarcados, sem invadir corredores.'),
    FiveSQuestion('2.3', 'Ferramentas e instrumentos têm local definido e identificado e voltam a ele após o uso.'),
    FiveSQuestion('2.4', 'Armários, prateleiras, gavetas e arquivos estão identificados e organizados.'),
  ]),
  FiveSCategoryDef(code: '3S', senseName: 'Seiso', title: 'Limpeza', questions: [
    FiveSQuestion('3.1', 'Piso, paredes, janelas e teto estão limpos e em bom estado.'),
    FiveSQuestion('3.2', 'Máquinas, equipamentos e bancadas estão limpos, sem acúmulo de cavaco, pó, óleo ou vazamentos.'),
    FiveSQuestion('3.3', 'Lâmpadas, tomadas, quadros elétricos e proteções de máquinas estão limpos e conservados.'),
    FiveSQuestion('3.4', 'Sanitários, vestiários e refeitório estão limpos e conservados.'),
  ]),
  FiveSCategoryDef(code: '4S', senseName: 'Seiketsu', title: 'Padronização', questions: [
    FiveSQuestion('4.1', 'Há padrões visuais (etiquetas, placas, cores, limites) e quadros 5S expostos e atualizados.'),
    FiveSQuestion('4.2', 'Instruções de trabalho, formulários e registros estão padronizados, atualizados e no posto.'),
    FiveSQuestion('4.3', 'Iluminação, ventilação, ruído e temperatura são adequados às atividades.'),
    FiveSQuestion('4.4', 'Extintores, hidrantes e saídas de emergência estão sinalizados e desobstruídos.'),
    FiveSQuestion('4.5', 'Existe cronograma ou checklist de limpeza e organização definido e visível no setor.'),
    FiveSQuestion('4.6', 'Produtos químicos e inflamáveis estão identificados e armazenados conforme o padrão.'),
  ]),
  FiveSCategoryDef(code: '5S', senseName: 'Shitsuke', title: 'Disciplina', questions: [
    FiveSQuestion('5.1', 'Os colaboradores conhecem e seguem os padrões e a rotina 5S do setor.'),
    FiveSQuestion('5.2', 'A rotina de limpeza e organização (cronograma ou checklist) é cumprida e registrada.'),
    FiveSQuestion('5.3', 'Os colaboradores usam os EPIs corretamente e seguem as regras de segurança da área.'),
    FiveSQuestion('5.4', 'Novos colaboradores recebem orientação 5S e há reciclagem periódica da equipe.'),
  ]),
];

/// Titles are common to both forms; individual questions come from Audit.items.
const List<FiveSCategoryDef> fiveSCategories = productionCategories;

/// Rótulos de classificação conforme a nota geral (0 a 5).
String classificacaoParaNota(double nota) {
  if (nota < 1) return 'Muito Ruim';
  if (nota < 2) return 'Ruim';
  if (nota < 3) return 'Regular';
  if (nota < 4) return 'Bom';
  if (nota < 5) return 'Muito Bom';
  return 'Atende Plenamente';
}
