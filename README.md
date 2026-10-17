# Ondexa Android 1.0.11+12

Projeto Flutter para auditorias 5S, com as 31 áreas e 735 perguntas aprovadas, histórico local, fotos, relatórios Word e backups .5s.

## Novidades

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

110 testes Flutter e dois testes Python passaram no Windows. A análise estática passou sem erros ou avisos impeditivos. As versões das dependências foram mantidas.

O APK não foi compilado localmente: essa etapa permanece no Codemagic. O gesto da barra de navegação ainda precisa ser conferido no Galaxy A54 após a instalação.

No teste com seis fotos do relatório de PCP, as imagens passaram de 43.021.152 para 3.029.381 bytes, uma redução de aproximadamente 93%. O resultado varia conforme as fotos. JPEG aplica compressão com perdas.

## Documentação

- docs/ATUALIZACAO_1.0.11.md: regras completas, validação, compatibilidade e instalação.
- docs/checklists_por_area_2026-10.json: catálogo das 31 áreas.
- docs/ATUALIZACAO_QUESTIONARIOS_2026-10.md: perguntas e decisões anteriores.
- docs/ATUALIZACAO_FOTOS_1.0.10.md e docs/historico/: registros das versões anteriores; a regra atual de fotos é a da versão 1.0.11.
