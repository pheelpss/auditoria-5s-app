# Ondexa Android 1.0.12+13

Projeto Flutter para auditorias 5S, com 32 áreas e 749 perguntas, histórico local, fotos, relatórios Word e backups .5s.

## Novidades

- Showroom adicionado ao final do grupo Administrativo, com 14 perguntas aprovadas (3/3/4/2/2 por senso), numeradas em sequência. Novas auditorias começam sem notas; mês e data seguem o preenchimento normal.
- O novo setor participa dos indicadores, histórico, relatórios Word, exportação em lote e backup .5s pelas rotinas existentes.
- Fotos em JPEG 90 e até 2.560 pixels no lado maior, mantendo a proporção. A evidência otimizada é guardada uma vez e reutilizada nos relatórios e backups.
- Barra de navegação inferior oculta nos Android compatíveis, com revelação temporária por gesto. A barra superior permanece visível.
- Abrir um setor e voltar sem preencher não salva rascunho. Cabeçalho, comentário, nota zero ou qualquer outra nota/anexo mantêm o registro; apagar todo o conteúdo de uma auditoria nova descarta o rascunho.

## Compilar pelo GitHub e Codemagic

1. Envie o conteúdo desta pasta para a raiz do repositório conectado. pubspec.yaml e codemagic.yaml devem ficar na raiz, junto de lib/, test/, scripts/, docs/ e assets/.
2. Execute android-workflow — Ondexa Android Build no Codemagic.
3. O workflow gera a pasta Android, instala a configuração nativa da barra de navegação, executa os testes e compila o APK.
4. Baixe o APK nos artefatos da compilação.

A pasta Android é gerada durante a compilação e não precisa ser enviada manualmente. O novo scripts/install_android_navigation.py e scripts/android/MainActivity.kt.template devem ser enviados junto do projeto.

## Validação

Nesta atualização, a conferência estática comparou as 14 perguntas do Showroom com o Word aprovado e verificou o catálogo de 32 áreas/749 perguntas. Os 31 questionários anteriores foram preservados. Dois testes Python do scaffold Android passaram. As versões das dependências e o workflow foram mantidos.

O SDK Flutter não está disponível no ambiente desta atualização: a análise Dart e os testes Flutter não foram executados localmente. A suíte existente foi atualizada para incluir o Showroom, com verificações de seleção, histórico, indicadores, DOCX, rascunho e nota zero. O workflow do Codemagic executa `flutter analyze` e `flutter test` antes de compilar o APK. Os resultados da versão 1.0.11 permanecem na documentação histórica e não representam execução desta versão.

O APK não foi compilado localmente: essa etapa permanece no Codemagic. O gesto da barra de navegação ainda precisa ser conferido no Galaxy A54 após a instalação.

No teste com seis fotos do relatório de PCP, as imagens passaram de 43.021.152 para 3.029.381 bytes, uma redução de aproximadamente 93%. O resultado varia conforme as fotos. JPEG aplica compressão com perdas.

## Documentação

- docs/ATUALIZACAO_1.0.11.md: regras completas, validação, compatibilidade e instalação.
- docs/ATUALIZACAO_1.0.12_SHOWROOM.md: inclusão do Showroom, numeração, validação e envio ao GitHub/Codemagic.
- docs/checklist_showroom_1.0.12.json: perguntas aprovadas do novo setor e mapeamento da numeração original.
- docs/checklists_por_area_2026-10.json: catálogo das 31 áreas.
- docs/ATUALIZACAO_QUESTIONARIOS_2026-10.md: perguntas e decisões anteriores.
- docs/ATUALIZACAO_FOTOS_1.0.10.md e docs/historico/: registros das versões anteriores; a regra atual de fotos é a da versão 1.0.11.
