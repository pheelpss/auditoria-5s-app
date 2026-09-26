# Atualização visual — aplicativo mobile 5S

Esta pasta contém o projeto Flutter do ZIP fornecido, com a mesma logo do Ordexa no ícone e na abertura. O APK antigo não foi alterado.

## Comportamento
- Fundo escuro com gradientes, grade e partículas discretas.
- Apenas a logo 5S centralizada, com brilho suave, em layout vertical.
- Ao tocar na logo, ou após aproximadamente 3 segundos, abre diretamente a tela existente de auditorias.
- Sem menu de três opções. A abertura não reaparece ao voltar de outras telas.
- Preferência vertical durante a abertura; depois retorna à política de orientação anterior do aplicativo.
- Arquivos .5s que abrem o aplicativo aguardam o fim da animação antes da confirmação de importação.
- Respeita a configuração de redução de animações do sistema.

## Gerar no Codemagic
Substitua os arquivos do repositório pelos desta pasta, incluindo assets/, test/, pubspec.yaml e codemagic.yaml. Execute o workflow Android Build existente. Ele gera a pasta Android, ícones, abertura nativa, executa as verificações e compila o APK.

Preserve a configuração de assinatura e o applicationId usados na versão instalada. Esta alteração não troca a organização com.suaempresa do workflow original. Uma atualização sobre o APK anterior exige a mesma chave de assinatura. Não desinstale a versão antiga para contornar incompatibilidade sem antes exportar as auditorias.

## Compilação manual
Depois de gerar ou recuperar a pasta android/ com as permissões e filtros .5s do workflow existente:

```text
flutter pub get
dart run flutter_launcher_icons
dart run flutter_native_splash:create
flutter analyze --no-fatal-infos lib/presentation/screens/opening_screen.dart lib/main.dart
flutter test test/opening_screen_test.dart
python3 scripts/fix_splash_compile_sdk.py
flutter build apk --release
```

O APK será gerado em build/app/outputs/flutter-apk/app-release.apk.

## Arquivos alterados
- lib/main.dart: abertura e espera dos compartilhamentos durante a animação.
- lib/presentation/screens/opening_screen.dart: animação e layout.
- assets/branding/logo_5s.png: logo original, sem redesenho.
- pubspec.yaml: registro da imagem, configuração de ícone e splash nativa; versão 1.0.1+2.
- codemagic.yaml: geração de recursos visuais e verificações antes da compilação.
- test/opening_screen_test.dart: toque, avanço automático e encerramento antecipado.

O restante do código de auditoria foi preservado. Este ambiente não possui Flutter/Android SDK: a compilação, os testes Flutter e a visualização em aparelho precisam ser executados no Codemagic ou em ambiente com Flutter. Não está incluído um APK recompilado.

A versão flutter_native_splash 2.4.1 está fixada para manter compatibilidade com archive 3.x usado pelo gerador DOCX original, evitando uma migração desnecessária do gerador de relatórios.


## Correção da compilação Android
O flutter_native_splash 2.4.1 declara compileSdk 31 no próprio módulo Android.
O script scripts/fix_splash_compile_sdk.py ajusta exclusivamente esse módulo para
compileSdk 36 após a resolução das dependências, antes de compilar o APK.
A configuração do aplicativo já usava 36, mas não era herdada pelo plugin.
Não muda minSdk, targetSdk, identificação do aplicativo nem dados das auditorias.
O ajuste é reaplicado automaticamente em cada execução do Codemagic, inclusive
quando o cache das dependências é recriado.
