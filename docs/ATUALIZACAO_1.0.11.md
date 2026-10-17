# Ondexa Android 1.0.11+12

Preparado em 16/10/2026 (horário de Brasília).
Base: branch principal de pheelpss/auditoria-5s-app, commit a59310d8a9e425174741bba542619313f1beafb8 (1.0.10+11).

## Fotos

- Captura e escolha da galeria guardam a evidência no diretório interno de documentos do app, como JPEG de qualidade 90 e até 2.560 pixels no lado maior.
- Mantém a proporção, corrige orientação EXIF e não amplia imagens menores. Transparência é composta sobre branco, pois JPEG não tem canal alfa.
- Processamento feito em isolate; não guarda uma cópia original adicional no arquivo permanente de evidências. A imagem da galeria do usuário não é apagada. Arquivos temporários do seletor seguem o ciclo normal de limpeza do Android.
- O DOCX e o backup .5s leem a evidência otimizada já salva. Exportar novamente não aplica outra compressão JPEG.
- Fotos antigas, anteriores à atualização, recebem uma versão temporária otimizada na primeira geração de DOCX. As próximas gerações reutilizam o cache enquanto o arquivo não mudar. As evidências antigas e os backups já existentes não sofrem uma migração destrutiva.
- JPEG já comprimido é armazenado diretamente no ZIP interno do Word; os XML continuam comprimidos. Isso evita gastar CPU tentando comprimir novamente as imagens.
- O Ondexa Desktop 2.3.7 recebe as imagens menores dos novos relatórios DOCX. Apresentações e relatórios antigos já exportados não mudam automaticamente.

Medição com as seis fotos do DOCX de PCP disponível nesta sessão:

| Medida | Resultado |
|---|---:|
| Bytes originais das seis imagens PNG | 43.021.152 |
| Bytes após otimização em JPEG | 3.029.381 |
| Redução no conjunto de imagens | 92,96% |
| Dimensões finais de cada imagem | 1.441 × 2.560 |

Os números referem-se às imagens, não ao tamanho total de um DOCX/PPTX. O teste foi executado no computador, não no Galaxy A54. Fotos diferentes podem ter outra redução e outro tempo de processamento. JPEG é uma compressão com perdas: o objetivo é preservar boa nitidez para o relatório e os slides, e não permitir a mesma ampliação extrema do original.

## Barra de navegação Android

- Oculta somente a barra inferior; relógio, bateria e notificações continuam visíveis.
- Android 11 ou superior: usa WindowInsetsController, navigationBars e BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE.
- Androids anteriores compatíveis com a base do app: usa os indicadores legados HIDE_NAVIGATION e IMMERSIVE_STICKY.
- Um gesto da borda revela a navegação temporariamente; não desativa o botão Voltar nem os gestos do sistema.
- Reaplica a política ao voltar ao aplicativo, inclusive depois da câmera/galeria, e 1,1 segundo após o fechamento do teclado. O sistema pode manter os controles visíveis enquanto eles forem necessários, como durante a entrada de texto.
- A Activity é instalada pelo novo script scripts/install_android_navigation.py depois que o Codemagic gera a pasta Android. O pacote Android existente é preservado.
- A base Flutter estável testada exige Android 7.0 (API 24) ou superior; a atualização não tenta forçar instalação em Androids abaixo do mínimo da base. O aparelho confirmado pelo usuário é o Galaxy A54.

Referências oficiais de implementação:

- [Android: ocultação das barras e revelação transitória por gesto](https://developer.android.com/develop/ui/views/layout/immersive).
- [Flutter: restrições de SystemChrome com SDK 35/36 e após fechar o teclado](https://api.flutter.dev/flutter/services/SystemChrome/setEnabledSystemUIMode.html).

## Rascunhos

- Abrir um setor e voltar sem preencher nada não grava uma auditoria. Área, data e mês preenchidos automaticamente na abertura não contam como resposta do auditor.
- Qualquer nome no cabeçalho, comentário, alteração efetiva de setor/data/mês, nota (incluindo zero), foto ou outro anexo mantém a auditoria nova como rascunho.
- Apagar o preenchimento e voltar aos valores iniciais remove o rascunho criado nessa sessão quando não restar nenhuma resposta ou evidência.
- O seletor de nota ganhou a opção “Sem nota”, representada por um traço, para permitir limpar a resposta. Zero continua sendo uma nota preenchida.
- Auditorias que já estavam no histórico não são excluídas automaticamente ao abrir e voltar. Não há limpeza retroativa em massa de registros antigos.
- Gravações automáticas são serializadas com cópias dos dados de cada solicitação. Uma gravação pendente não recria um rascunho esvaziado nem grava por engano outra auditoria recém-aberta.

## Validação desta entrega

- Flutter 3.47.7 estável e Dart 3.13.5 no Windows.
- 110 testes Flutter aprovados: questionários das 31 áreas, 735 perguntas, médias, histórico, abertura, galeria, rascunhos, navegação, imagens/EXIF e relatórios com até sete fotos.
- Dois testes Python aprovados: instalação da Activity no scaffold, preservação do pacote, repetibilidade e detecção de scaffold ausente.
- Análise estática dos módulos do workflow sem erros ou avisos impeditivos. Permanecem sete informações de APIs obsoletas já presentes na base, aceitas pela configuração --no-fatal-infos.
- As versões das 110 dependências do lockfile foram preservadas.
- Não foi compilado um APK localmente: este computador não tem a cadeia Android configurada. O workflow executa novamente a análise, os testes e a compilação Android no Codemagic.
- O comportamento nativo de ocultar/revelar a barra ainda deve ser conferido no aparelho físico após instalar o APK; os testes Flutter usam a ponte nativa simulada.

## Envio para GitHub e Codemagic

1. Extraia o ZIP e abra Ondexa-App.
2. Substitua os arquivos correspondentes no repositório pelo conteúdo dessa pasta, incluindo lib, test, scripts, docs, assets, pubspec.yaml, pubspec.lock, codemagic.yaml e .gitignore.
3. Os arquivos devem ficar diretamente na raiz do repositório. Não crie uma pasta Ondexa-App adicional dentro dele.
4. Envie o commit e execute android-workflow — Ondexa Android Build no Codemagic.
5. Baixe o APK dos artefatos depois de concluir os testes e a compilação.

Use o mesmo identificador e a mesma assinatura Android da instalação atual para atualizar o app. O projeto preserva o fluxo de geração Android e não modifica configurações externas de assinatura do Codemagic.

Após instalar no A54, confira: abrir PCP e voltar sem preencher; escrever somente o responsável e voltar; marcar zero e limpar; adicionar e remover uma foto; gerar o Word; retornar da câmera; fechar o teclado; revelar a barra inferior com um gesto.
