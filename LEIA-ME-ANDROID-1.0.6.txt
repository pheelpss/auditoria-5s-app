ONDEXA ANDROID — ATUALIZAÇÃO 1.0.6 (BUILD 7)

Alterações incluídas
• Histórico com cartões mais compactos, bordas discretas e menos espaço vertical.
  Ícones, cores de classificação, informações e ações existentes foram preservados.
• Nova logo Ondexa no ícone do aplicativo, na abertura nativa do Android e na
  abertura animada do aplicativo.
• Uma nova auditoria só é salva como rascunho depois de selecionar uma área.
  Preencher outros campos ou voltar sem selecionar uma área não grava o rascunho.

Como compilar no Codemagic
1. Extraia Ondexa-Android-Projeto-1.0.6.zip e coloque seu conteúdo na raiz do
   repositório conectado ao Codemagic (pubspec.yaml e codemagic.yaml na raiz).
2. Execute o workflow android-workflow / Ondexa Android Build.
3. Baixe o APK gerado nos artefatos da compilação.

O workflow cria a pasta Android, gera os ícones e as telas de abertura, executa
análise e testes e compila o APK de release. A pasta Android gerada localmente,
caches e arquivos de build não fazem parte deste ZIP.

Instalação sobre a versão existente
O identificador com.suaempresa.auditoria_5s foi mantido e a versão foi elevada
de 1.0.5+6 para 1.0.6+7. Use a mesma chave de assinatura da versão instalada
para atualizar sem desinstalar e preservar os dados locais. O APK fornecido
está assinado com certificado Android Debug; uma chave diferente impede a
instalação como atualização. Não desinstale o aplicativo sem exportar seus dados.
A estrutura do banco de dados não foi alterada.

Validação realizada
• 11 testes Flutter passaram: abertura, exportação de evidências, rascunhos
  e funcionamento dos cartões compactos do histórico.
• Análise dos arquivos afetados sem erros ou avisos; apenas informações de
  APIs antigas já utilizadas pelo projeto.
• Geração dos recursos de ícone e splash Android concluída com sucesso.
• Flutter 3.47.6 / Dart 3.13.5; pubspec.lock incluído.

Este pacote contém o código atualizado. O novo APK será produzido pelo Codemagic;
a compilação Android completa não foi executada localmente.
