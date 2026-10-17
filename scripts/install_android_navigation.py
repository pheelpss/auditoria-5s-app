"""Instala a Activity nativa no scaffold gerado pelo Codemagic."""
from pathlib import Path
import re


def install(root: Path) -> Path:
    candidates = list((root / 'android/app/src/main/kotlin').rglob('MainActivity.kt'))
    if len(candidates) != 1:
        raise RuntimeError('Esperada uma única MainActivity Kotlin no projeto Android.')
    target = candidates[0]
    match = re.search(r'^package\s+([\w.]+)', target.read_text(encoding='utf-8'), re.M)
    if match is None:
        raise RuntimeError('Não foi possível identificar o pacote Android existente.')
    template = (root / 'scripts/android/MainActivity.kt.template').read_text(encoding='utf-8')
    target.write_text(template.replace('__PACKAGE__', match[1]), encoding='utf-8')
    return target


if __name__ == '__main__':
    print(f'Navegação Android configurada em {install(Path(__file__).resolve().parent.parent)}')
