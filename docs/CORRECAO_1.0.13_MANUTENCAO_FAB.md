# Correção 1.0.13+14 — Manutenção Fab

Data: 29/10/2026.

Origem: Checklist-5s-ManutencaoFab_SET26.xls, aba FRENTE, linha 70. A 5.2 pergunta se cartazes e lembretes estão exibidos no ambiente; a 5.3 continua avaliando treinamentos. O código da versão 1.0.12+13 repetia o texto de treinamentos nas duas posições.

Escopo aprovado: corrigir apenas auditorias novas e preservar o histórico. O catálogo Dart e sua referência JSON foram corrigidos na mesma posição 5.2, sem renumerar nem adicionar perguntas. Novas auditorias continuam iniciando com notas vazias. Não houve alteração no banco, importador de backup, entidade Audit, cálculos, fotos, relatórios, identidade Android ou workflow do Codemagic.

Auditorias existentes e backups importados preservam suas próprias perguntas e notas, inclusive o texto antigo. Portanto, atualizar o APK não altera a auditoria já preenchida mostrada no print. Para usar o texto corrigido, crie uma nova auditoria. A comparação com auditoria anterior continua sendo feita apenas entre conjuntos de perguntas idênticos.

Teste adicionado: test/manutencao_fab_question_test.dart. Confere o texto novo, a 5.3, as notas independentes e a preservação de itens históricos restaurados. A suíte existente também compara o catálogo à referência JSON atualizada.

Verificação local: falha reproduzida antes da alteração; checagem estática aprovada após a correção; planilha original conferida. Código de leitura do histórico/importação e todos os demais arquivos de lógica preservados byte a byte. Flutter/Dart não disponível localmente; a suíte Flutter e a compilação do APK devem passar no workflow existente do Codemagic. APK fornecido pelo usuário mantido sem alterações; não foi feita compilação de APK nem teste físico no celular nesta entrega.

Para atualizar: envie o conteúdo da pasta completa à raiz do repositório GitHub conectado ao Codemagic, execute android-workflow e instale seu artefato APK com a mesma assinatura do app anterior. Exporte antes seu backup .5s e não desinstale o aplicativo. A versão foi incrementada de 1.0.12+13 para 1.0.13+14; dependências e pubspec.lock foram preservados.
