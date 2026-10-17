# Ondexa Android 1.0.10+11 — fotos em resolução original

## Instalação via GitHub e Codemagic

1. Extraia o ZIP e abra a pasta `Ondexa-App`.
2. Envie o CONTEÚDO dessa pasta à raiz do mesmo repositório GitHub, substituindo os arquivos correspondentes. Inclua os novos arquivos `lib/utils/report_photo.dart` e `test/report_photo_test.dart`.
3. `pubspec.yaml`, `codemagic.yaml`, `lib`, `test`, `assets` e `scripts` devem ficar diretamente na raiz do repositório, sem outra pasta Ondexa-App por cima.
4. Faça commit e execute o workflow `Ondexa Android Build` no Codemagic.
5. O workflow executa a análise e TODOS os testes Flutter antes de compilar. Baixe o APK em Artifacts após o build terminar com sucesso.
6. Atualize o aplicativo instalado com o APK usando a mesma assinatura do build anterior. Não desinstale para atualizar, pois isso pode apagar os dados locais.

## Correção

- Câmera e galeria deixam de solicitar qualidade 80 ao image_picker; não há limite de largura ou altura na seleção.
- JPEG sem rotação EXIF e PNG são incluídos no DOCX com os mesmos bytes do arquivo disponível no aplicativo.
- Removidas a redução para 900 pixels e a recodificação JPEG em qualidade 72.
- JPEG com orientação EXIF 2 a 8: a orientação é aplicada e os pixels decodificados são salvos em PNG sem perdas, na resolução completa. Esse arquivo pode ser bem maior.
- Outros formatos reconhecidos pela biblioteca image são convertidos em PNG na resolução original. Isto não acrescenta suporte a formatos que a biblioteca não decodifica, como HEIC.
- O DOCX contém a opção do Word para não comprimir automaticamente suas imagens ao salvar.
- A dimensão de exibição e a grade continuam iguais: três colunas até seis fotos e quatro colunas acima disso. Dimensão na página não reduz os pixels armazenados.
- Fotos indisponíveis ou não reconhecidas seguem o comportamento anterior do gerador. Não foi alterado o armazenamento das evidências.

## Verificações realizadas nesta entrega

21 testes de imagem e relatório executados com sucesso com Dart 3.13.5 e com image/archive/xml/intl nas mesmas versões travadas pelo projeto. Os testes exercitaram os arquivos reais de produção por um runner Dart isolado, com um adaptador temporário de diretório para o plugin path_provider; nenhum adaptador foi incluído no app. A análise estática dos dois módulos alterados não encontrou problemas.

Cobertura executada:
- Todos os 31 relatórios, com perguntas de cada área, campos de cabeçalho, média e classificação.
- Relatório histórico com perguntas salvas e comparação incompatível desabilitada.
- Comparação compatível e seção de evidências.
- Quantidades de uma a sete fotos, identidade dos bytes dentro do ZIP/DOCX, extensão correta, proporções e dimensões de exibição, relacionamentos e tipos de conteúdo XML.
- JPEG de 4000 × 3000 pixels preservado byte a byte.
- PNG de 1600 × 1200 com canal alfa preservado byte a byte.
- Todas as sete orientações EXIF 2–8 com igualdade dos pixels decodificados após conversão.
- Conversão BMP de 1300 × 1000 para PNG sem perda de pixels.
- Entrada vazia ou não reconhecida.

A validação local não executou a suíte Flutter completa nem compilou APK: o ambiente bloqueou a inicialização do Flutter ao tentar consultar o serviço de metadados da máquina. O workflow do Codemagic mantém `flutter analyze` e `flutter test` como etapas obrigatórias antes da compilação.
Relatórios de conferência com três e sete imagens foram abertos e convertidos pelo LibreOffice; a página de sete fotos foi inspecionada visualmente, sem cortes ou sobreposição.
Comparação de arquivos confirmou que os catálogos, entidades, banco de dados, providers e pubspec.lock são idênticos à versão 1.0.9 entregue. Verificada também a configuração YAML e a ordem teste → compilação.

## Limites da validação

O ambiente desta entrega não disponibilizou o SDK Flutter/Android. Portanto, não foram executados aqui os testes de widgets, a câmera real, o compartilhamento no celular ou a compilação do APK. Os testes Flutter completos estão configurados como etapa obrigatória do Codemagic. Não é possível garantir ausência absoluta de bugs; o APK precisa passar pelo build e pela conferência final no aparelho.

Após instalar, capture uma foto com texto pequeno, confira a pré-visualização, gere o DOCX e abra no computador. Faça uma conferência com o celular na vertical e outra na horizontal. A qualidade preservada é a do arquivo disponível: detalhes perdidos em relatórios antigos ou em fotos já comprimidas não podem ser recuperados por esta atualização.

## Registro para o Ondexa no PC

Esta versão mantém as 31 áreas e as 735 perguntas aprovadas. O nome é Teste Titan; TesteQA não é uma nova área. As decisões anteriores permanecem em docs/ATUALIZACAO_QUESTIONARIOS_2026-10.md e docs/checklists_por_area_2026-10.json.

Para a futura atualização do programa no PC, preservar os bytes das imagens extraídas de word/media e aceitar JPEG e PNG, inclusive no mesmo relatório. O programa no PC não foi modificado nesta entrega.


## Limpeza da distribuição 1.0.10+11

- Código Dart ativo mantido somente em `lib/` e testes em `test/`; cópias redundantes da raiz removidas.
- Removidas dependências diretas sem uso (`cupertino_icons`, `open_filex`) e `xml` movida para dependências de desenvolvimento, pois só é importada nos testes.
- Criado `.gitignore` para builds, caches e arquivos de assinatura locais.
- Guias antigos foram movidos para `docs/historico/`.
- Versões de dependências que exigem migração de API, em especial `archive` 4.x e `file_picker` 13.x, foram mantidas no major atual.
