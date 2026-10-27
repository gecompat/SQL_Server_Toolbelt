"""Exakte Rechtekorrekturen; historische Pins sind keine aktuellen Quellhashes."""
from pathlib import Path
import copy
import json
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'Scripts/Release'))
import caller_metadata as metadata
from test_xlsx_metadata import XlsxMetadataMixin
from test_json_constructor_package_gate import JsonConstructorPackageGateMixin
from test_json_schema_package_gate import JsonSchemaPackageGateMixin
from test_zip_caller_composer import ZipCallerComposerMixin
from test_zip_caller_profile import ZipCallerProfileMixin
from test_edit_distance_package_gate import EditDistancePackageGateMixin
from test_script_parser_package_gate import ScriptParserPackageGateMixin
from test_clr_framework_package_profile import ClrFrameworkCandidateProfileMixin
from test_xlsx_zip_package_framework import XlsxZipPackageFrameworkMixin
from test_zip_entry_count_composer import ZipEntryCountComposerMixin
from test_xlsx_shared_string_count_composer import XlsxSharedStringCountComposerMixin
from test_xlsx_sheet_count_composer import XlsxSheetCountComposerMixin
from test_xlsx_boundary_evidence import XlsxBoundaryEvidenceMixin
import xlsx_metadata


class CallerMetadataTests(XlsxMetadataMixin, JsonConstructorPackageGateMixin, JsonSchemaPackageGateMixin, ZipCallerComposerMixin, ZipCallerProfileMixin, EditDistancePackageGateMixin, ScriptParserPackageGateMixin, ClrFrameworkCandidateProfileMixin, XlsxZipPackageFrameworkMixin, ZipEntryCountComposerMixin, XlsxSharedStringCountComposerMixin, XlsxSheetCountComposerMixin, XlsxBoundaryEvidenceMixin, unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        runtime = ROOT / '.runtime'
        if runtime.is_symlink():
            raise RuntimeError('Release-Testlaufzeitverzeichnis darf kein Symlink sein.')
        runtime.mkdir(exist_ok=True)
        cls.originals = {p: metadata.historical_manifest(ROOT, p) for p in metadata.PATHS}

    def test_six_exact_fields_preserve_original_native_pins(self):
        record = json.loads((ROOT / metadata.RECORD).read_bytes())
        self.assertEqual(set(record['manifests']), set(metadata.PATHS))
        for path, original in self.originals.items():
            with self.subTest(path=path):
                current = (ROOT / path).read_bytes()
                metadata.validate_manifest(path, original, current)
                metadata.validate_source(ROOT, path, metadata.digest(original))
                self.assertNotEqual(metadata.digest(current), metadata.digest(original))
        for report in metadata.REPORTS:
            path = 'Releases/1.0.0/' + report
            original = subprocess.run(['git', 'show', metadata.BASELINE + ':' + path], cwd=ROOT,
                                      capture_output=True, timeout=30, check=True).stdout
            self.assertEqual((ROOT / path).read_bytes(), original)
            self.assertEqual(record['historical_reports_sha256'][path], metadata.digest(original))

    def test_xlsx_manifest_source_uses_only_its_exact_overlay_validator(self):
        path = xlsx_metadata.MANIFEST
        raw_bytes = (ROOT / xlsx_metadata.RAW_REPORT).read_bytes()
        executed_digest = json.loads(raw_bytes)['source_sha256'][path]
        metadata.validate_source(ROOT, path, executed_digest)
        with self.assertRaises(ValueError):
            metadata.validate_source(ROOT, path, '0' * 64)

        historical = {path: xlsx_metadata.historical(ROOT, path)}
        current_files = (path, xlsx_metadata.RECORD, xlsx_metadata.RAW_REPORT,
                         xlsx_metadata.CELL_REPORT)
        with tempfile.TemporaryDirectory(dir=ROOT / '.runtime', prefix='caller-xlsx-source-') as folder:
            root = Path(folder)
            for relative in current_files:
                target = root / relative
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes((ROOT / relative).read_bytes())
            changed = (root / path).read_bytes() + b'\n# unqualified change\n'
            (root / path).write_bytes(changed)
            with patch.object(xlsx_metadata, 'historical',
                              side_effect=lambda _root, selected: historical[selected]):
                with self.assertRaises(ValueError):
                    metadata.validate_source(root, path, executed_digest)

        with self.assertRaises(ValueError):
            metadata.validate_source(ROOT, 'Modules/toolbelt.file.xlsx-memory/Tests/README.md', '0' * 64)

    def test_other_manifest_changes_are_rejected(self):
        for path, original in self.originals.items():
            valid = metadata.corrected_manifest(path, original)
            for old, new in ((b'unreleased', b'released'), (b'1.0.0', b'9.9.9'),
                             (b'dependencies:', b'changed_dependencies:'),
                             (b'SELECT auf', b'SELECT und REFERENCES auf')):
                changed = valid.replace(old, new)
                if changed == valid:
                    continue
                with self.subTest(path=path, change=old), self.assertRaises(ValueError):
                    metadata.validate_manifest(path, original, changed)
            with self.assertRaises(ValueError):
                metadata.validate_manifest(path, original, valid + b'\nextra_contract: true\n')
            with self.assertRaises(ValueError):
                metadata.validate_source(ROOT, path, '0' * 64)

    def test_runtime_and_unknown_paths_cannot_use_manifest_exception(self):
        for path in ('Modules/toolbelt.json.schema/Source/ValidateJsonSchema.sql',
                     'Deployment/Install.sql', 'Workers/worker.ps1',
                     'Modules/unknown/module.yaml', '../outside', '/absolute'):
            with self.subTest(path=path), self.assertRaises(ValueError):
                metadata.corrected_manifest(path, b'permissions_required: []')

    def test_product_delta_rejects_runtime_new_contract_and_rewritten_report(self):
        previous = dict(self.originals)
        current = {p: metadata.corrected_manifest(p, b) for p, b in previous.items()}
        baseline = dict(previous)
        report_paths = ['Releases/1.0.0/' + p for p in metadata.REPORTS]
        for p in report_paths:
            previous[p] = current[p] = baseline[p] = b'{"historical": true}'
        r = {'public_baseline_commit': metadata.BASELINE, 'publication_authorized': False,
             'manifests': {p: {'executed_sha256': metadata.digest(previous[p]),
                              'current_sha256': metadata.digest(current[p])} for p in metadata.PATHS},
             'historical_reports_sha256': {p: metadata.digest(current[p]) for p in report_paths},
             'changed_product_paths': sorted(metadata.PATHS),
             'previous_source_sha256': {p: metadata.digest(previous[p]) for p in metadata.PATHS},
             'current_source_sha256': {p: metadata.digest(current[p]) for p in metadata.PATHS}}
        metadata.validate_product_delta(previous, current, r, baseline)
        for path in ('Modules/toolbelt.json.schema/Source/runtime.sql',
                     'Modules/toolbelt.json.schema/Contracts/Api.json', 'Deployment/install.sql',
                     'Workers/worker.ps1', 'Modules/unknown/module.yaml'):
            changed = dict(current, **{path: b'changed'})
            with self.subTest(path=path), self.assertRaises(ValueError):
                metadata.validate_product_delta(previous, changed, r, baseline)
        changed = dict(current, **{report_paths[0]: b'{"rewritten": true}'})
        with self.assertRaises(ValueError):
            metadata.validate_product_delta(previous, changed, r, baseline)
        for field, value in (('publication_authorized', True), ('public_baseline_commit', '0' * 40),
                             ('manifests', {}), ('historical_reports_sha256', {}),
                             ('changed_product_paths', [])):
            altered = copy.deepcopy(r); altered[field] = value
            with self.subTest(field=field), self.assertRaises(ValueError):
                metadata.validate_product_delta(previous, current, altered, baseline)

    def test_rights_are_exactly_supported_by_native_api_sets(self):
        reports = [json.loads((ROOT / 'Releases/1.0.0' / p).read_bytes()) for p in metadata.REPORTS]
        known = {(a['name'], a['permission']) for r in reports for a in
                 r.get('public_apis', r.get('required_object_rights', []))}
        import re
        for module, statements in metadata.RIGHTS.items():
            for statement in statements[:1 if module == 'toolbelt.json.schema' else 2]:
                selected = 'EXECUTE' if statement.startswith('EXECUTE') else 'SELECT'
                if module == 'toolbelt.json.schema':
                    self.assertTrue({('USP_ValidateJsonSchema', 'EXECUTE'),
                                     ('USP_PrepareResultTable', 'EXECUTE'),
                                     ('FT_ValidateJsonSchemaInternal', 'SELECT')} <= known)
                    continue
                for name in re.findall(r'\b(?:TVF|SVF)_\w+', statement):
                    self.assertIn((name, selected), known)


if __name__ == '__main__':
    unittest.main()
