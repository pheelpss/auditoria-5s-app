# Ondexa Android 1.0.12+13 — Showroom

## Revisão do teste de interface após o primeiro build

O primeiro log do Codemagic registrou 112 testes aprovados e uma falha no teste de seleção da área. O toque no texto de dica “Selecione uma área” não abriu o menu; a busca seguinte com `.last` encontrou uma lista vazia e lançou `Bad state: No element`. Nesta revisão, o teste toca no `DropdownButton`, confirma que a lista foi aberta e rola dentro do menu usando um finder que aceita ausência inicial do item. Continua verificando a seleção real do Showroom, as 14 perguntas sem notas e o salvamento do rascunho. A execução Flutter desta revisão precisa ser confirmada no próximo build do Codemagic; não há SDK Flutter disponível localmente. Versão e código do aplicativo permanecem 1.0.12+13.

Atualização do projeto Flutter 1.0.11+12 fornecido por Felipe. Escopo confirmado na conversa: adicionar o Showroom ao aplicativo Android; a atualização do Desktop será tratada separadamente.

## Novo setor

Showroom é o último setor do grupo Administrativo no seletor de áreas. Foi acrescentado às listas usadas nos indicadores e à lista alternativa de setores. O catálogo passa de 31 áreas/735 perguntas para 32 áreas/749 perguntas. Os setores anteriores continuam com as mesmas perguntas.

O questionário usa o relatório `Auditoria_5S_Set_Showroom_26.docx` aprovado, derivado do relatório de RH. Foram excluídas as perguntas originais 1.4, 2.4, 2.5, 3.5, 4.3, 4.4 e 5.1. A numeração restante é sequencial por senso, conforme confirmação posterior de Felipe:

| Senso | Numeração nova | Quantidade |
| --- | --- | --- |
| 1S | 1.1 a 1.3 | 3 |
| 2S | 2.1 a 2.3 | 3 |
| 3S | 3.1 a 3.4 | 4 |
| 4S | 4.1 a 4.2 | 2 |
| 5S | 5.1 a 5.2 | 2 |

No 5S, a pergunta original 5.2 sobre cartazes passa a 5.1; a original 5.3 sobre treinamentos passa a 5.2. O texto das 14 perguntas restantes é o do Word aprovado. A referência JSON específica do Showroom registra a numeração original e a nova, separadamente do catálogo histórico de outubro.

## Uso e dados

Nenhuma auditoria de Showroom é incluída como exemplo ou base inicial. As notas 4 do Word eram apenas ilustrativas. Novas auditorias começam sem notas, com a data e o mês normais do aplicativo; Setembro não foi fixado no código.

O setor usa os mesmos formulários, cinco sensos, cálculo de médias, fotos, observações, rascunhos, histórico, indicadores, geração DOCX e exportação em lote dos demais setores. Notas zero são válidas; campos sem nota não entram nas médias. A média geral continua sendo a média dos sensos avaliados, sem dar peso maior ao senso com mais perguntas.

O banco SQLite, o formato .5s, as rotinas de importação/exportação e os dados históricos não foram modificados. O backup registra o nome Showroom e suas próprias perguntas como nos demais setores. Esta entrega não certifica a exibição do novo setor no Desktop 2.3.8: a atualização do programa ainda não faz parte deste pacote.

## Validação desta atualização

- Conferência estática do catálogo e do texto das 14 perguntas contra o Word aprovado, aplicando a renumeração confirmada.
- Conferência de 32 setores, 749 perguntas, listas sem duplicatas, Showroom no final dos administrativos e preservação dos 31 questionários anteriores.
- Dois testes Python existentes do script de navegação Android executados com sucesso.
- Atualizados testes Flutter do catálogo, seleção de área, identificação administrativa no histórico, rolagem do último setor e geração DOCX para todos os 32 setores. Acrescentados cenários de rascunho vazio e nota zero do Showroom.
- SDK Flutter indisponível localmente; análise Dart, suíte Flutter, APK e teste em aparelho físico pendentes da compilação e conferência no Codemagic/aparelho. Não considerar os resultados históricos da 1.0.11 como execução desta versão.

## GitHub e Codemagic

1. Extraia o ZIP e abra a pasta do projeto.
2. Envie o conteúdo dessa pasta à raiz do mesmo repositório conectado ao Codemagic. `pubspec.yaml`, `pubspec.lock`, `codemagic.yaml`, `lib`, `test`, `scripts`, `docs` e `assets` devem ficar na raiz, sem criar uma subpasta adicional no repositório.
3. Preserve o identificador Android e a configuração de assinatura usados na instalação existente.
4. Execute `android-workflow — Ondexa Android Build`. O workflow existente gera a pasta Android quando necessário, configura os recursos, analisa o código, executa testes e só então compila o APK release.
5. Baixe o APK em Artifacts e atualize a instalação existente com a mesma assinatura.
6. Confira Showroom ao final de Administrativo, as 14 perguntas renumeradas, criação sem notas, inclusão nos indicadores, registro de zero, foto, salvamento/reabertura, DOCX, ZIP de relatórios e exportação/importação .5s.

O projeto entregue não inclui um APK compilado. O objetivo desta entrega é servir de fonte para GitHub e Codemagic.
