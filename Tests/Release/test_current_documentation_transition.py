"""Focused integrity checks for the exact current documentation follow-up."""
from pathlib import Path
import json
import shutil
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
import sys
sys.path.insert(0, str(ROOT / 'Scripts/Release'))
import current_documentation_transition as transition
import help_contract_source
import parameter_documentation_transition as parameters


class CurrentDocumentationTransitionTests(unittest.TestCase):
    def _fixture(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        root = Path(temporary.name)
        paths = set(transition.PATHS) | {
            transition.RECORD_PATH, transition.ARCHIVE_PATH, 'LICENSE.md',
            parameters.ARCHIVE, parameters.REGISTRY} | set(parameters.PATHS)
        for path in parameters.PATHS:
            module = Path(path).parts[1]
            paths.update(p.relative_to(ROOT).as_posix()
                         for p in (ROOT / 'Modules' / module / 'Source').glob('*.sql'))
        for relative in paths:
            source = ROOT / relative
            target = root / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(source, target)
        return root

    def test_all_ten_current_and_historical_bytes_are_exactly_bound(self):
        record = json.loads((ROOT / transition.RECORD_PATH).read_bytes())
        for path in sorted(transition.PATHS):
            with self.subTest(path=path):
                before = transition.historical_source(
                    ROOT, path, record['before_source_sha256'][path])
                current = transition.validate_current(
                    ROOT, path, record['before_source_sha256'][path])
                self.assertEqual(transition._digest(before), record['before_source_sha256'][path])
                predecessor = (parameters.predecessor_source(ROOT, path, current)
                               if path in parameters.PATHS else current)
                self.assertEqual(transition._digest(predecessor), record['after_source_sha256'][path])
                with self.assertRaisesRegex(ValueError, 'predecessor pin'):
                    transition.validate_current(ROOT, path, '0' * 64)

    def test_help_predecessors_match_the_unchanged_historical_record(self):
        record = json.loads((ROOT / transition.RECORD_PATH).read_bytes())
        help_record = json.loads((ROOT / help_contract_source.RECORD).read_bytes())
        help_paths = transition.PATHS.intersection(help_contract_source.SOURCE_PATHS)
        self.assertEqual(len(help_paths), 8)
        for path in sorted(help_paths):
            expected = help_record['current_source_sha256'][path]
            self.assertEqual(record['before_source_sha256'][path], expected)
            prior_current = transition.historical_source(ROOT, path, expected)
            self.assertEqual(transition._digest(prior_current), expected)
            historical_baseline = help_contract_source.validate_historical_source(
                ROOT, path, help_record['baseline_source_sha256'][path])
            self.assertEqual(transition._digest(historical_baseline),
                             help_record['baseline_source_sha256'][path])

    def test_current_source_drift_and_unknown_paths_fail(self):
        root = self._fixture()
        target = root / sorted(transition.PATHS)[0]
        target.write_bytes(target.read_bytes() + b'\nUnapproved change.\n')
        with self.assertRaisesRegex(ValueError, 'exact follow-up pin'):
            transition.validate_current(root, sorted(transition.PATHS)[0])
        with self.assertRaisesRegex(ValueError, 'unsupported documentation transition path'):
            transition.validate_current(ROOT, 'README.md')

    def test_record_and_archive_corruption_fail_closed(self):
        root = self._fixture()
        record_path = root / transition.RECORD_PATH
        record_path.write_bytes(record_path.read_bytes() + b' ')
        with self.assertRaisesRegex(ValueError, 'record differs from its fixed digest'):
            transition.validate_current(root, sorted(transition.PATHS)[0])

        root = self._fixture()
        archive_path = root / transition.ARCHIVE_PATH
        archive_path.write_bytes(archive_path.read_bytes() + b'corruption')
        with self.assertRaisesRegex(ValueError, 'archive differs from its fixed digest'):
            transition.validate_current(root, sorted(transition.PATHS)[0])

    def test_missing_snapshot_source_and_license_drift_fail_closed(self):
        root = self._fixture()
        (root / sorted(transition.PATHS)[0]).unlink()
        with self.assertRaises((OSError, ValueError)):
            transition.validate_current(root, sorted(transition.PATHS)[1])

        root = self._fixture()
        license_path = root / 'LICENSE.md'
        license_path.write_bytes(license_path.read_bytes() + b'\n')
        with self.assertRaisesRegex(ValueError, 'license differs'):
            transition.validate_current(root, sorted(transition.PATHS)[0])

    def test_parameter_projection_rejects_noncanonical_table_and_surrounding_prose(self):
        path = sorted(parameters.PATHS)[0]
        for replacement in ('outside', 'inside'):
            root = self._fixture()
            target = root / path
            content = target.read_text(encoding='utf-8')
            changed = content + '\nUnapproved prose.\n' if replacement == 'outside' else content.replace(
                parameters.BEGIN, parameters.BEGIN + '\nUnapproved table content.', 1)
            target.write_text(changed, encoding='utf-8')
            with self.subTest(change=replacement), self.assertRaisesRegex(ValueError, 'exact canonical parameter projection'):
                parameters.predecessor_source(root, path)

    def test_parameter_archive_and_native_doc_pin_are_not_generic_exceptions(self):
        root = self._fixture()
        archive = root / parameters.ARCHIVE
        archive.write_bytes(archive.read_bytes() + b'corruption')
        with self.assertRaisesRegex(ValueError, 'parameter documentation archive differs'):
            parameters.predecessor_source(root, sorted(parameters.PATHS)[0])
        for path in ('README.md', 'Modules/toolbelt.file.xlsx-memory/Source/TVF_FormatXlsxCell.sql', '../escape.md'):
            with self.subTest(path=path), self.assertRaisesRegex(ValueError, 'unsupported native parameter documentation path'):
                parameters.native_documentation_source(ROOT, path, '0' * 64)
        with self.assertRaisesRegex(ValueError, 'predecessor pin differs'):
            parameters.native_documentation_source(ROOT, sorted(parameters.NATIVE_PATHS)[0], '0' * 64)


if __name__ == '__main__':
    unittest.main()
