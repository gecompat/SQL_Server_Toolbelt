"""Historical integrity never substitutes for current source qualification."""
from pathlib import Path
import hashlib
import json
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / 'Scripts/Release'))
import evidence_sources as sources


class EvidenceSourceTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.git('init', '-q')
        self.git('config', 'core.autocrlf', 'false')
        self.file = self.root / 'Modules/Contoso.sql'
        self.file.parent.mkdir()
        self.file.write_bytes(b'original\r\n')
        self.git('add', '.')
        self.git('-c', 'user.name=Contoso', '-c', 'user.email=test@example.invalid',
                 'commit', '-qm', 'Synthetic source')
        self.revision = self.git('rev-parse', 'HEAD').decode().strip()
        self.path = 'Releases/1.0.0/evidence.json'
        self.report_file = self.root / self.path
        self.report_file.parent.mkdir(parents=True)
        self.digest = hashlib.sha256(self.file.read_bytes()).hexdigest()
        self.report = {'source_commit': self.revision,
                       'source_sha256': {'Modules/Contoso.sql': self.digest}}
        self.report_file.write_text(json.dumps(self.report), encoding='utf-8')
        self.git('add', '.')
        self.git('-c', 'user.name=Contoso', '-c', 'user.email=test@example.invalid',
                 'commit', '-qm', 'Synthetic evidence')

    def git(self, *args):
        return subprocess.run(['git', '-C', str(self.root), *args], check=True,
                              capture_output=True, timeout=30).stdout

    def test_original_preserved_current_drift_stays_unqualified(self):
        self.file.write_bytes(b'changed\n')
        bound = sources.report_sources(self.root, self.path)
        self.assertEqual(bound['Modules/Contoso.sql'].original, b'original\r\n')
        self.assertFalse(bound['Modules/Contoso.sql'].current_matches)
        self.assertEqual(sources.applicability(bound)['current_native_qualification'],
                         'not established by source integrity')
        with self.assertRaisesRegex(ValueError, 'current source qualification missing'):
            sources.require_current(bound)

    def test_identical_sources_satisfy_only_source_precondition(self):
        bound = sources.report_sources(self.root, self.path)
        sources.require_current(bound)
        self.assertEqual(sources.applicability(bound)['current_native_qualification'],
                         'not established by source integrity')

    def test_uppercase_hex_does_not_normalize_source_bytes(self):
        bound = sources.resolve(self.root, {'Modules/Contoso.sql': self.digest.upper()})
        self.assertEqual(bound['Modules/Contoso.sql'].original, b'original\r\n')
        with self.assertRaisesRegex(ValueError, 'exact original source unavailable'):
            sources.resolve(self.root, {'Modules/Contoso.sql': hashlib.sha256(b'original\n').hexdigest()},
                            revisions=[self.revision])

    def test_modified_report_cannot_redirect_original(self):
        sources.report_sources(self.root, self.path)
        self.report_file.write_text(json.dumps({**self.report, 'source_commit': '0' * 40}), encoding='utf-8')
        with self.assertRaisesRegex(ValueError, 'report differs from its committed original'):
            sources.report_sources(self.root, self.path)

    def test_unrecorded_digest_is_rejected(self):
        with self.assertRaisesRegex(ValueError, 'not recorded by this report'):
            sources.report_sources(self.root, self.path, bindings={'Modules/Contoso.sql': '0' * 64})

    def test_no_arbitrary_history_search(self):
        self.file.write_bytes(b'changed\n')
        with self.assertRaisesRegex(ValueError, 'exact original source unavailable'):
            sources.resolve(self.root, self.report['source_sha256'])
        with self.assertRaisesRegex(ValueError, 'full commit ID'):
            sources.resolve(self.root, self.report['source_sha256'], revisions=['HEAD'])

    def test_missing_live_source_is_historical_only(self):
        self.file.unlink()
        bound = sources.report_sources(self.root, self.path)
        self.assertEqual(bound['Modules/Contoso.sql'].original, b'original\r\n')
        self.assertIsNone(bound['Modules/Contoso.sql'].current_sha256)
        with self.assertRaises(ValueError):
            sources.require_current(bound)

    def test_unsafe_paths_and_non_commit_are_rejected(self):
        for path in ('../secret', '/secret', 'a/../secret', '.runtime/input', '.git/config',
                     'a\\b', 'a:b', 'a\nb'):
            with self.subTest(path=path), self.assertRaises(ValueError):
                sources.resolve(self.root, {path: self.digest})
        blob = self.git('rev-parse', 'HEAD:Modules/Contoso.sql').decode().strip()
        self.file.write_bytes(b'changed\n')
        with self.assertRaisesRegex(ValueError, 'not a commit'):
            sources.resolve(self.root, self.report['source_sha256'], revisions=[blob])

    def test_provided_original_still_requires_exact_digest(self):
        with self.assertRaisesRegex(ValueError, 'provided original digest differs'):
            sources.resolve(self.root, self.report['source_sha256'],
                            originals={'Modules/Contoso.sql': b'forged'})

    def test_bounds_precede_reading_large_live_source(self):
        with patch.object(sources, 'MAX_SOURCE_BYTES', 3), self.assertRaisesRegex(ValueError, 'bounded regular file'):
            sources.resolve(self.root, self.report['source_sha256'])

    def test_nonregular_live_source_is_rejected(self):
        self.file.unlink()
        self.file.mkdir()
        with self.assertRaisesRegex(ValueError, 'bounded regular file'):
            sources.resolve(self.root, self.report['source_sha256'])

    def test_report_identity_remains_bound_after_indexing(self):
        self.assertEqual(sources.report_path(self.root, self.report), self.path)
        self.report_file.write_text('{}', encoding='utf-8')
        with self.assertRaisesRegex(ValueError, 'report changed during verification'):
            sources.report_path(self.root, self.report)


    def package_report(self, entries):
        import io
        import warnings
        import zipfile
        data = io.BytesIO()
        with warnings.catch_warnings():
            warnings.simplefilter('ignore', UserWarning)
            with zipfile.ZipFile(data, 'w') as archive:
                for name, payload in entries:
                    archive.writestr(name, payload)
        package = self.root / 'Releases/1.0.0/Contoso.zip'
        package.write_bytes(data.getvalue())
        self.report['package'] = {'path': package.relative_to(self.root).as_posix(),
                                  'sha256': hashlib.sha256(data.getvalue()).hexdigest()}
        self.report_file.write_text(json.dumps(self.report), encoding='utf-8')
        self.git('add', '.')
        self.git('-c', 'user.name=Contoso', '-c', 'user.email=test@example.invalid',
                 'commit', '-qm', 'Synthetic archive')
        return package

    def test_archive_original_does_not_qualify_live_drift(self):
        self.package_report([('Contoso/Sources/Modules/Contoso.sql', b'original\r\n')])
        self.file.write_bytes(b'changed')
        bound = sources.report_sources(self.root, self.path)
        self.assertEqual(bound['Modules/Contoso.sql'].origin, 'verified_original')
        with self.assertRaises(ValueError):
            sources.require_current(bound)

    def test_archive_mutation_is_rejected_even_after_cache_hit(self):
        package = self.package_report([('Contoso/Sources/Modules/Contoso.sql', b'original\r\n')])
        sources.report_sources(self.root, self.path)
        package.write_bytes(b'corrupt')
        with self.assertRaisesRegex(ValueError, 'recorded package digest differs'):
            sources.report_sources(self.root, self.path)

    def test_duplicate_archive_entries_are_rejected(self):
        entry = ('Contoso/Sources/Modules/Contoso.sql', b'original\r\n')
        self.package_report([entry, entry])
        with self.assertRaisesRegex(ValueError, 'duplicate or excessive'):
            sources.report_sources(self.root, self.path)

    def test_production_framework_gate_still_rejects_live_drift(self):
        import json_schema_package as gate
        pins = {}
        for index in range(38):
            name = 'Modules/Contoso' + str(index) + '.sql'
            (self.root / name).write_bytes(b'original')
            pins[name] = hashlib.sha256(b'original').hexdigest()
        report = {'framework_input_pins': pins}
        gate.validate_source_pins(self.root, report)
        (self.root / next(iter(pins))).write_bytes(b'drift')
        with self.assertRaisesRegex(gate.SchemaPackageError, 'FRAMEWORK_PUBLIC_INPUT_DRIFT'):
            gate.validate_source_pins(self.root, report)


    def test_reviewed_reader_catalog_restores_original_but_rejects_mutation(self):
        import parameter_help_transition as transition
        root = Path(__file__).resolve().parents[2]
        pins = json.loads((root / transition.VERIFIER_PINS).read_bytes())
        for name in transition.ADDITIONAL_REVIEWED_READ_ADAPTERS:
            with self.subTest(path=name):
                current = (root / name).read_bytes()
                original = transition.restore_verifier_source(root, name, current)
                self.assertEqual(hashlib.sha256(original).hexdigest(), pins[name]['before'])
                with self.assertRaises(ValueError):
                    transition.restore_verifier_source(root, name, current + b'\n# unexpected drift\n')


if __name__ == '__main__':
    unittest.main()
