from pathlib import Path
import importlib.util
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('navigation', ROOT / 'scripts/install_android_navigation.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class AndroidNavigationTest(unittest.TestCase):
    def test_scaffold_package_is_preserved_and_install_is_idempotent(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            target = root / 'android/app/src/main/kotlin/com/suaempresa/auditoria_5s/MainActivity.kt'
            target.parent.mkdir(parents=True)
            target.write_text('package com.suaempresa.auditoria_5s\nclass MainActivity : FlutterActivity()', encoding='utf-8')
            template = root / 'scripts/android/MainActivity.kt.template'
            template.parent.mkdir(parents=True)
            template.write_bytes((ROOT / 'scripts/android/MainActivity.kt.template').read_bytes())
            module.install(root)
            first = target.read_bytes()
            module.install(root)
            self.assertEqual(first, target.read_bytes())
            text = first.decode('utf-8')
            self.assertIn('package com.suaempresa.auditoria_5s', text)
            self.assertIn('hide(WindowInsets.Type.navigationBars())', text)
            self.assertIn('show(WindowInsets.Type.statusBars())', text)
            self.assertNotIn('hide(WindowInsets.Type.systemBars())', text)

    def test_missing_scaffold_fails_instead_of_silently_skipping_the_feature(self):
        with tempfile.TemporaryDirectory() as directory:
            with self.assertRaises(RuntimeError):
                module.install(Path(directory))
