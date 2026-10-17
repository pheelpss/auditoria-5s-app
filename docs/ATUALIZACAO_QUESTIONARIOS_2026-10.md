# Ondexa 1.0.9 — questionários por área

Decisões confirmadas com Felipe (Phelps) em 16/10/2026.

## Referência para o aplicativo e para a futura atualização do PC

O aplicativo passa a usar as perguntas específicas de cada uma das 31 áreas,
conforme as 31 planilhas XLS de Nova pasta.zip. São 735 perguntas somando os
31 questionários. Não se deve usar apenas um modelo administrativo e um produtivo.

O catálogo executado pelo aplicativo está em lib/core/constants/area_checklists.dart.
O arquivo docs/checklists_por_area_2026-10.json registra cada origem, o texto original,
o texto com correções de português, a numeração original e a numeração aprovada.
Esse JSON serve como referência para portar os mesmos questionários ao Ondexa Desktop.
O programa de PC ainda não foi atualizado neste pacote.

Regras acordadas:

- Escolher uma área carrega sua quantidade, ordem e perguntas específicas.
- TesteQA / Teste QA da planilha corresponde a Teste Titan no aplicativo.
- Marketing corresponde a MKT; Eng Processo a Processos; Qualidade a QA;
  ENGENHARIA PRODUTO a Eng. Produto; ENGENHARIA P&D a P&D.
- Não existe setor ADM. ADM Vendas e Manutenção ADM continuam cadastrados.
- Os nomes e os agrupamentos das 31 áreas no app permanecem os mesmos.
- Corrigir português sem mudar os critérios ou inverter o sentido das perguntas.
- Notas de 0 a 5, média por senso e média geral dos cinco sensos.
- O comportamento atual para auditoria parcial continua: média das notas e
  dos sensos que já foram preenchidos, sem tratar campos em branco como zero.
- Auditorias e rascunhos existentes preservam seus itens e suas respostas.
  Importar backup também preserva as perguntas armazenadas nele.
- Novos questionários entram nas novas auditorias. A troca explícita de área
  segue o comportamento existente de carregar as perguntas da nova área.
- Comparar notas anteriores somente se o conjunto de perguntas for compatível.
- Preservar layout, tema, abertura, cabeçalho, resumo final, escala de notas e
  regras das evidências fotográficas. O gerador DOCX não foi modificado.

## Correções de numeração aprovadas

- Financeiro: a segunda pergunta 5.3 passa a ser 5.4.
- QA: a segunda pergunta 5.3 passa a ser 5.4.
- QA: 1.1, 1.3, 1.4, 1.5 passam a 1.1, 1.2, 1.3, 1.4.
- P&D: 4.1, 4.2, 4.3, 4.5 passam a 4.1, 4.2, 4.3, 4.4.
- Solda: 2.1, 2.2, 2.3, 2.6 passam a 2.1, 2.2, 2.3, 2.4.

Nenhuma pergunta foi adicionada ou removida por essas correções.

## Quantidades por área e por senso

| Área | 1S | 2S | 3S | 4S | 5S | Total |
|---|---:|---:|---:|---:|---:|---:|
| ADM Vendas | 4 | 5 | 5 | 4 | 3 | 21 |
| Almoxarifado | 6 | 6 | 5 | 6 | 5 | 28 |
| Balanceamento | 6 | 4 | 5 | 6 | 4 | 25 |
| CL | 6 | 6 | 5 | 6 | 4 | 27 |
| Dobra | 6 | 4 | 5 | 6 | 4 | 25 |
| Eng. Produto | 4 | 5 | 5 | 4 | 3 | 21 |
| Financeiro | 4 | 5 | 5 | 4 | 4 | 22 |
| Laser | 6 | 4 | 5 | 6 | 4 | 25 |
| Leves | 6 | 6 | 5 | 6 | 4 | 27 |
| MKT | 4 | 5 | 5 | 4 | 3 | 21 |
| MTG Hera | 6 | 4 | 5 | 6 | 4 | 25 |
| MTG Voluta | 6 | 4 | 5 | 6 | 4 | 25 |
| Manutenção ADM | 4 | 5 | 5 | 4 | 3 | 21 |
| Manutenção Fab | 6 | 4 | 5 | 6 | 4 | 25 |
| Metálicos | 6 | 6 | 5 | 6 | 4 | 27 |
| P&D | 4 | 5 | 5 | 4 | 3 | 21 |
| PCP | 4 | 5 | 5 | 4 | 3 | 21 |
| Pintura | 6 | 4 | 5 | 6 | 4 | 25 |
| Processos | 4 | 5 | 5 | 4 | 3 | 21 |
| QA | 4 | 5 | 5 | 4 | 4 | 22 |
| RH | 4 | 5 | 5 | 4 | 3 | 21 |
| Recebimento | 6 | 6 | 5 | 6 | 4 | 27 |
| Repuxo | 6 | 4 | 5 | 6 | 5 | 26 |
| Resíduos | 6 | 4 | 4 | 6 | 4 | 24 |
| SST | 4 | 5 | 5 | 4 | 3 | 21 |
| Serralheria | 6 | 4 | 5 | 6 | 4 | 25 |
| Solda | 6 | 4 | 5 | 6 | 4 | 25 |
| TI | 4 | 5 | 5 | 4 | 3 | 21 |
| Teste Titan | 6 | 6 | 5 | 6 | 4 | 27 |
| Tubos | 6 | 6 | 5 | 6 | 4 | 27 |
| Área Externa | 5 | 2 | 3 | 2 | 4 | 16 |

## Compilar no Codemagic

1. Envie o conteúdo da pasta Ondexa-App para a raiz do repositório conectado ao
   Codemagic. pubspec.yaml, codemagic.yaml, lib, test, docs, scripts e assets
   precisam estar na mesma raiz. Preserve todos os arquivos de assets/branding.
2. Execute o workflow android-workflow (Ondexa Android Build).
3. O workflow gera a pasta Android quando necessário, instala dependências,
   executa flutter analyze e flutter test e então compila o APK release.
4. Baixe o APK nos artefatos da compilação concluída.

A versão deste projeto é 1.0.9+10. Foram mantidas as dependências e as etapas de
preparação Android do projeto recebido. O pacote não contém um APK compilado.

## Validação desta entrega

Conferência estática: 31 setores, 735 perguntas, texto/ordem comparados com a
origem e com as correções aprovadas, números únicos no esquema SQLite atual,
arquivos de interface e gerador DOCX preservados, YAML e assets conferidos.

Foram incluídos testes Flutter para seleção dos questionários, quantidades,
notas, histórico, restauração e conteúdo dos relatórios/evidências. O ambiente
de preparação não possui Flutter/Dart SDK; esses testes e a compilação devem
ser executados no Codemagic. A paginação visual dos novos relatórios deve ser
conferida no Word com o APK compilado, sobretudo com comparação e comentários.
