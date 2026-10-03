"""Align the legacy splash plugin with the app's Android compile SDK.
Run after flutter pub get; changes only compileSdk in the resolved plugin.
"""
import json
import re
from pathlib import Path


def update_compile_sdk(text, minimum=36):
    pattern = re.compile(r'(\bcompileSdk(?:Version)?\s*(?:=\s*)?)(\d+)\b')
    matches = list(pattern.finditer(text))
    if len(matches) != 1:
        raise RuntimeError('Expected one numeric compileSdk declaration; plugin layout changed.')
    return pattern.sub(lambda m: m[1] + str(max(int(m[2]), minimum)), text)


def main():
    metadata = Path('.flutter-plugins-dependencies')
    if not metadata.is_file():
        raise RuntimeError('Run flutter pub get before this script.')
    plugins = json.loads(metadata.read_text(encoding='utf-8'))['plugins']['android']
    plugin = next((p for p in plugins if p['name'] == 'flutter_native_splash'), None)
    if plugin is None:
        raise RuntimeError('flutter_native_splash Android plugin was not found.')
    directory = Path(plugin['path']).resolve() / 'android'
    candidates = [p for p in [directory / 'build.gradle', directory / 'build.gradle.kts'] if p.is_file()]
    if len(candidates) != 1:
        raise RuntimeError('Expected a single splash plugin Gradle build file.')
    target = candidates[0]
    original = target.read_text(encoding='utf-8')
    updated = update_compile_sdk(original)
    if updated != original:
        target.write_text(updated, encoding='utf-8')
    print('flutter_native_splash: compileSdk >= 36 verified. minSdk and targetSdk unchanged.')


if __name__ == '__main__':
    main()
