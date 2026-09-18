# Auditoria 5S — App Mobile (Flutter)

Aplicativo Android para substituir o formulário físico de auditoria 5S por uma
versão 100% digital: preenchimento do checklist, cálculo automático de notas,
classificação, anexos de evidências (fotos/arquivos), histórico com filtros e
geração de relatório em Word (.docx) — tudo funcionando **localmente**, sem
depender de servidor (banco SQLite local).

## O que já está implementado

- **Cabeçalho da auditoria**: Responsável, Área/Seção, Auditor(a), Acompanhante,
  Data (date picker) e Mês de Referência (seletor Jan–Dez).
- **Checklist completo dos 5 sensos** (1S a 5S) com todas as perguntas do
  formulário original, cada uma com seletor suspenso de nota (0 a 5) — o
  auditor nunca digita números, apenas toca e escolhe.
- **Cálculo automático**: média por senso (Resultado do 1S..5S), Nota Geral 5S
  (média dos 5 resultados) e classificação automática (Muito Ruim → Atende
  Plenamente), com nota numérica, barra de progresso e cor indicativa.
- **Evidências por categoria**: tirar foto pela câmera, escolher da galeria ou
  anexar arquivo (PDF/Word/Excel), com miniaturas e opção de excluir.
- **Histórico de auditorias** salvas em SQLite local, com filtros por mês, ano,
  área e auditor.
- **Geração de relatório Word (.docx)**: botão "Gerar Relatório Word" cria um
  arquivo .docx com cabeçalho, todas as notas, resultado de cada senso, nota
  geral, classificação, comentários e as fotos de evidência organizadas por
  seção — usando um gerador OOXML próprio (`lib/utils/docx_generator.dart`),
  sem depender de template externo.
- **Arquitetura limpa**: `domain` (entidades e regras), `data` (SQLite),
  `presentation` (telas, widgets, `Provider` para estado) — pronta para crescer
  (ex.: sincronização em nuvem no futuro).

## Estrutura do projeto

```
lib/
  core/            # tema e dados fixos do checklist 5S
  domain/          # entidades (Audit, AuditItem, Evidence) e contrato do repositório
  data/            # SQLite (datasource) e implementação do repositório
  presentation/    # provider (estado), telas e widgets
  utils/           # gerador de relatório .docx
```

## Como rodar (você precisa ter o Flutter SDK instalado)

Este pacote contém apenas o código-fonte Dart (`lib/`, `pubspec.yaml`). As
pastas de plataforma (`android/`, `ios/`) não vieram junto porque precisam ser
geradas pelo próprio Flutter SDK, que não está disponível neste ambiente.

1. Extraia o zip e, dentro da pasta do projeto, rode:
   ```bash
   flutter create . --platforms=android
   ```
   Isso gera a pasta `android/` sem sobrescrever seu `lib/` ou `pubspec.yaml`.

2. Instale as dependências:
   ```bash
   flutter pub get
   ```

3. Adicione as permissões no arquivo
   `android/app/src/main/AndroidManifest.xml`, dentro da tag `<manifest>`
   (antes de `<application>`):
   ```xml
   <uses-permission android:name="android.permission.CAMERA"/>
   <uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
   <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
   ```

4. Rode em um dispositivo/emulador conectado:
   ```bash
   flutter run
   ```

5. Para gerar o APK final:
   ```bash
   flutter build apk --release
   ```
   O arquivo fica em `build/app/outputs/flutter-apk/app-release.apk`.

## Próximos passos sugeridos

- Sincronização em nuvem (ex.: Firebase ou API própria) reaproveitando a
  interface `AuditRepository` já existente — basta criar uma nova
  implementação e trocar no `main.dart`.
- Tela de visualização/edição do relatório antes de gerar o .docx final.
- Testes automatizados dos cálculos de nota (`lib/domain/entities/audit.dart`).
