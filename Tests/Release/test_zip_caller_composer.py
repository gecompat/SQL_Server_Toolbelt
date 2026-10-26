"""Independent byte and scope checks for the fixed ZIP caller fixture."""
from pathlib import Path
import hashlib
import io
import json
import sys
import tempfile
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'Tests/Release'))
import compose_zip_caller as composer


class ZipCallerComposerMixin:
    def test_reader_fixture_is_fixed_stored_zip(self):
        data = composer.reader_fixture()
        self.assertEqual(len(data), 121)
        self.assertEqual(hashlib.sha256(data).hexdigest(),
                         'c3c875d34d69ec7868fa6dad856df10bd64015022f7ef25c00aa0e7285c7cc81')
        with zipfile.ZipFile(io.BytesIO(data)) as archive:
            self.assertEqual(archive.namelist(), ['hello.txt'])
            entry = archive.infolist()[0]
            self.assertEqual(entry.date_time, (2020, 2, 3, 4, 5, 6))
            self.assertEqual(entry.compress_type, zipfile.ZIP_STORED)
            self.assertEqual(entry.CRC, 0xF7D18982)
            self.assertEqual((entry.flag_bits, entry.extra, entry.comment, archive.comment), (0x0800, b'', b'', b''))
            self.assertEqual(archive.read(entry), b'Hello')

    def test_writer_golden_is_distinct_fixed_output(self):
        data = composer.writer_golden()
        self.assertEqual(len(data), 121)
        self.assertEqual(hashlib.sha256(data).hexdigest(),
                         '190222c13438b7c020320790a28be7e8ffdd4ba130ae1b706350ab5afb4ffe66')
        with zipfile.ZipFile(io.BytesIO(data)) as archive:
            entry = archive.infolist()[0]
            self.assertEqual((entry.filename, archive.read(entry)), ('hello.txt', b'Hello'))
            self.assertEqual(entry.date_time, (1980, 1, 1, 0, 0, 0))
            self.assertEqual((entry.compress_type, entry.CRC), (zipfile.ZIP_STORED, 0xF7D18982))
            self.assertEqual((entry.flag_bits, entry.extra, entry.comment, archive.comment), (0x0800, b'', b'', b''))
        self.assertNotEqual(data, composer.reader_fixture())

    def test_composition_and_fault_controls_are_deterministic(self):
        fixture = composer.FIXTURE.read_bytes()
        baseline, manifest = composer.compose_sources(fixture)
        again, same_manifest = composer.compose_sources(fixture)
        wrong, wrong_manifest = composer.compose_sources(fixture, 'wrong-golden')
        grant, grant_manifest = composer.compose_sources(fixture, 'extra-schema-grant')
        self.assertEqual((baseline, manifest), (again, same_manifest))
        self.assertEqual(manifest['output_sha256'], hashlib.sha256(baseline).hexdigest())
        self.assertNotEqual(wrong, baseline)
        self.assertEqual(wrong_manifest['fault'], 'wrong-golden')
        self.assertNotEqual(grant, baseline)
        self.assertEqual(grant_manifest['fault'], 'extra-schema-grant')
        self.assertIn(b'GRANT SELECT ON SCHEMA::toolbelt_archive TO ContosoZipCaller;', grant)
        self.assertNotIn(b'GRANT SELECT ON SCHEMA::toolbelt_archive', baseline)

    def test_markers_and_fresh_runtime_output_scope_are_enforced(self):
        fixture = composer.FIXTURE.read_bytes()
        with self.assertRaisesRegex(ValueError, 'exactly one marker'):
            composer.compose_sources(fixture.replace(composer.READER_MARKER, b''))
        with self.assertRaisesRegex(ValueError, 'exactly one marker'):
            composer.compose_sources(fixture + composer.GRANT_MARKER)
        originals = {p: p.read_bytes() for p in (composer.FIXTURE,)}
        with tempfile.TemporaryDirectory(dir=ROOT / '.runtime', prefix='zip-caller-compose-test-') as temp:
            parent = Path(temp)
            output = parent / 'fresh'
            result = composer.write_output(output)
            written = (output / 'ZipMemory.CallerRights.sql').read_bytes()
            self.assertEqual(result['output_sha256'], hashlib.sha256(written).hexdigest())
            self.assertEqual(json.loads((output / 'composition.json').read_text())['output_sha256'], result['output_sha256'])
            with self.assertRaisesRegex(ValueError, 'fresh child'):
                composer.write_output(output)
            with self.assertRaisesRegex(ValueError, 'fresh child'):
                composer.validate_output_path(ROOT / '.runtime')
            with self.assertRaisesRegex(ValueError, 'fresh child'):
                composer.validate_output_path(ROOT / 'outside-zip-caller-output')
        self.assertEqual({p: p.read_bytes() for p in originals}, originals)


class ZipCallerComposerTests(ZipCallerComposerMixin, unittest.TestCase):
    pass


if __name__ == '__main__':
    unittest.main()
