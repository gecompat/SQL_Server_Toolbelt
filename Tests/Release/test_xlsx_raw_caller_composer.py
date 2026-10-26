from pathlib import Path
import hashlib
import sys
import tempfile
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'Tests/Release'))
import compose_xlsx_raw_caller as composer


class XlsxRawCallerComposerMixin:
    def test_binary_binding_and_determinism(self):
        first, metadata = composer.compose()
        second, again = composer.compose()
        self.assertEqual(first, second)
        self.assertEqual(metadata, again)
        self.assertEqual(hashlib.sha256(first).hexdigest(), metadata['output_sha256'])
        self.assertEqual(metadata['inputs']['workbook_sha256'], hashlib.sha256(
            (ROOT / 'Modules/toolbelt.file.xlsx-memory/Tests/Runtime/Types.Composition.xlsx').read_bytes()).hexdigest())
        self.assertNotIn(composer.MARKER, first)
        self.assertIn(b'504B0304', first)

    def test_missing_and_duplicate_markers_are_rejected(self):
        workbook = b'PK\x03\x04synthetic'
        with self.assertRaisesRegex(ValueError, 'exactly one'):
            composer.compose_sources(b'no marker', workbook)
        with self.assertRaisesRegex(ValueError, 'exactly one'):
            composer.compose_sources(composer.MARKER + b' ' + composer.MARKER, workbook)

    def test_invalid_workbook_header_is_rejected(self):
        before = composer.FIXTURE.read_bytes()
        with self.assertRaisesRegex(ValueError, 'ZIP workbook'):
            composer.compose_sources(composer.MARKER, b'not a zip')
        self.assertEqual(composer.FIXTURE.read_bytes(), before)

    def test_fresh_output_scope_and_originals_are_preserved(self):
        original_fixture = composer.FIXTURE.read_bytes()
        original_workbook = composer.WORKBOOK.read_bytes()
        with tempfile.TemporaryDirectory(dir=ROOT / '.runtime', prefix='xlsx-raw-composer-test-') as parent:
            parent_path = Path(parent)
            output = parent_path / 'fresh-output'
            manifest = composer.write_output(output)
            self.assertEqual(manifest['output_sha256'], hashlib.sha256(
                (output / 'XlsxRaw.CallerRights.sql').read_bytes()).hexdigest())
            with self.assertRaisesRegex(ValueError, 'fresh child'):
                composer.write_output(output)
            with self.assertRaisesRegex(ValueError, 'fresh child'):
                composer.validate_output_path(ROOT / '.runtime')
            outside = ROOT / 'outside-r12-output'
            with self.assertRaisesRegex(ValueError, 'fresh child'):
                composer.validate_output_path(outside)
        self.assertEqual(composer.FIXTURE.read_bytes(), original_fixture)
        self.assertEqual(composer.WORKBOOK.read_bytes(), original_workbook)


class XlsxRawCallerComposerTests(XlsxRawCallerComposerMixin, unittest.TestCase):
    pass


if __name__ == '__main__':
    unittest.main()
