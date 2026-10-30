"""Compositional package checks; no builds, SQL connections or publication."""
from pathlib import Path
import copy
import json
import os
import sys
import tempfile
import unittest
import zipfile
import stat
import io
from contextlib import contextmanager
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'Scripts/Release'))
import clr_maintenance as maintenance
import current_documentation_transition as followup
import verify_clr_maintenance as verifier


PROJECTION_FILES = frozenset({
    *maintenance.SOURCE_OVERRIDES,
    maintenance.LOCATION,
    maintenance.LOCATION + '.sha256',
    maintenance.CANDIDATE,
    maintenance.RECORD,
    verifier.DELIVERY,
    verifier.VERIFIER_PATH,
    'Scripts/Release/clr_maintenance.py',
    maintenance.package.LOCATION,
    maintenance.package.LOCATION + '.sha256',
    'Releases/1.0.0/CLR-INSTALL.md',
    'Tests/Release/Invoke-XlsxSharedStringBoundaryLab.ps1',
    'Tests/Release/Runtime/Xlsx.MaintenanceHelp.sql',
    'Tests/Release/Runtime/Xlsx.SharedStringCount.sql',
})
MAINTENANCE_HELP_PATHS = (
    maintenance.MODULE + 'Documentation/USP_ListXlsxWorksheets.md',
    maintenance.MODULE + 'Documentation/USP_ReadXlsxWorksheetCells.md',
)
MAX_PROJECTION_FILE_BYTES = 64 * 1024 * 1024
MAX_PROJECTION_TOTAL_BYTES = 128 * 1024 * 1024


def _read_projection_input(relative):
    if relative not in PROJECTION_FILES:
        raise ValueError('maintenance projection input is not allowlisted')
    root = ROOT.resolve(strict=True)
    current = root
    parts = Path(relative).parts
    reparse = getattr(stat, 'FILE_ATTRIBUTE_REPARSE_POINT', 0x400)
    for part in parts[:-1]:
        current = current / part
        metadata = current.lstat()
        if (not stat.S_ISDIR(metadata.st_mode) or
                getattr(metadata, 'st_file_attributes', 0) & reparse):
            raise ValueError('maintenance projection parent is not a regular directory')
    source = root.joinpath(*parts)
    before = source.lstat()
    if (not stat.S_ISREG(before.st_mode) or
            getattr(before, 'st_file_attributes', 0) & reparse or
            before.st_size > MAX_PROJECTION_FILE_BYTES):
        raise ValueError('maintenance projection source is not a bounded regular file')
    with source.open('rb') as stream:
        opened = os.fstat(stream.fileno())
        if (not stat.S_ISREG(opened.st_mode) or opened.st_size != before.st_size or
                getattr(opened, 'st_file_attributes', 0) & reparse):
            raise ValueError('maintenance projection source changed while opening')
        data = stream.read(MAX_PROJECTION_FILE_BYTES + 1)
    if len(data) != before.st_size or len(data) > MAX_PROJECTION_FILE_BYTES:
        raise ValueError('maintenance projection source changed while reading')
    return data


@contextmanager
def historical_maintenance_root():
    """Project only the fixed verifier inputs, restoring its two executed help sources."""
    runtime = ROOT / '.runtime'
    if runtime.is_symlink() or not runtime.is_dir():
        raise ValueError('maintenance projection runtime root is unsafe')
    record = json.loads((ROOT / maintenance.RECORD).read_bytes())
    with tempfile.TemporaryDirectory(prefix='current-documentation-maintenance-', dir=runtime) as name:
        projected = Path(name).resolve(strict=True)
        if not projected.is_relative_to(runtime.resolve(strict=True)):
            raise ValueError('maintenance projection escaped its private runtime root')
        total = 0
        for relative in sorted(PROJECTION_FILES):
            if relative in MAINTENANCE_HELP_PATHS:
                followup.validate_current(ROOT, relative,
                                          record['current_sources_sha256'][relative])
                content = followup.historical_source(ROOT, relative,
                                                     record['current_sources_sha256'][relative])
            else:
                content = _read_projection_input(relative)
                import parameter_help_transition
                if relative in parameter_help_transition.PATHS:
                    content = parameter_help_transition.predecessor_source(ROOT, relative)
            total += len(content)
            if total > MAX_PROJECTION_TOTAL_BYTES:
                raise ValueError('maintenance projection exceeds its total input bound')
            target = projected / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(content)
        yield projected


class ClrMaintenanceTests(unittest.TestCase):
    def record(self):
        return json.loads((ROOT / maintenance.RECORD).read_bytes())

    def test_actual_delivery_is_exact_qualified_derivation(self):
        with historical_maintenance_root() as projected:
            record = verifier.verify(projected)
            self.assertEqual(len(record['native_cases']), 12)
            self.assertFalse(record['publication_authorized'])

    def test_other_twelve_binaries_and_unselected_sources_remain_identical(self):
        with historical_maintenance_root() as projected:
            before = maintenance.read_base(projected)
            after = maintenance.derive(projected)
        changed_binaries = [p for p in before if p.startswith('Binaries/') and before[p] != after[p]]
        self.assertEqual(changed_binaries, [maintenance.BINARY])
        metadata = json.loads(after['CLR-PACKAGE.json'])
        self.assertNotIn('build_source_commit', metadata)
        self.assertNotIn('source_commit', metadata)
        self.assertEqual(set(metadata['artifact_build_overrides']), {'toolbelt.file.xlsx-memory'})
        self.assertEqual(metadata['artifact_build_overrides']['toolbelt.file.xlsx-memory']['dll_sha256'],
                         maintenance.BINARY_SHA256)
        changed_sources = {p.removeprefix('Sources/') for p in before
                           if p.startswith('Sources/') and before[p] != after[p]}
        self.assertEqual(changed_sources, set(maintenance.SOURCE_OVERRIDES))
        for mode in ('local', 'central'):
            sql = maintenance.selected_xlsx_export(after, mode)
            self.assertNotIn(b'-- BEGIN MODULE toolbelt.tsql.ssis-debug', sql)
            self.assertEqual(sql.count(b'-- BEGIN MODULE '), 3)

    def test_missing_native_case_or_audit_cannot_qualify(self):
        with historical_maintenance_root() as projected:
            record = json.loads((projected / maintenance.RECORD).read_bytes())
            for mutation in ('missing_case', 'missing_audit', 'wrong_mode'):
                broken = copy.deepcopy(record)
                if mutation == 'missing_case':
                    broken['native_cases'].pop()
                elif mutation == 'missing_audit':
                    broken['native_cases'][0]['independent_cleanup_audit'] = 'NOT_EXECUTED'
                else:
                    broken['native_cases'][0]['modes'] = ['local']
                with self.subTest(mutation=mutation), self.assertRaises(ValueError):
                    maintenance.qualified_payload(projected, broken)

    def test_changed_qualified_source_is_rejected_before_derivation(self):
        with historical_maintenance_root() as projected:
            original = Path.read_bytes
            path = projected / maintenance.SQL_SOURCES[0]

            def read(candidate):
                data = original(candidate)
                return data + b'\nSELECT 1;\n' if candidate == path else data

            with patch.object(Path, 'read_bytes', read), self.assertRaises(ValueError):
                maintenance.qualified_payload(projected, json.loads(
                    (projected / maintenance.RECORD).read_bytes()))

    def test_changed_pinned_maintenance_method_is_rejected(self):
        with historical_maintenance_root() as projected:
            path = projected / 'Scripts/Release/clr_maintenance.py'
            path.write_bytes(path.read_bytes() + b'\n# unqualified method change\n')
            with self.assertRaisesRegex(ValueError, 'qualification method differs'):
                maintenance.qualified_payload(projected, json.loads(
                    (projected / maintenance.RECORD).read_bytes()))

    def test_broader_claims_unknown_fields_or_omitted_limits_are_rejected(self):
        with historical_maintenance_root() as projected:
            record = json.loads((projected / maintenance.RECORD).read_bytes())
            mutations = []
            broken = copy.deepcopy(record); broken['status'] = 'PASS_ALL_PROFILES'; mutations.append(broken)
            broken = copy.deepcopy(record); broken['release_status'] = 'released'; mutations.append(broken)
            broken = copy.deepcopy(record); broken['full_profile_passed'] = True; mutations.append(broken)
            broken = copy.deepcopy(record); broken['qualification_scope']['not_executed'].pop(); mutations.append(broken)
            broken = copy.deepcopy(record); broken['native_cases'][0]['ssis_passed'] = True; mutations.append(broken)
            broken = copy.deepcopy(record); broken['native_cases'][0].pop('patch'); mutations.append(broken)
            for index, broken in enumerate(mutations):
                with self.subTest(mutation=index), self.assertRaises(ValueError):
                    maintenance.qualified_payload(projected, broken)

    def test_changed_package_is_rejected_even_with_recomputed_sidecar(self):
        data = (ROOT / maintenance.LOCATION).read_bytes()
        changed = bytes([data[0] ^ 1]) + data[1:]
        with historical_maintenance_root() as projected, tempfile.TemporaryDirectory() as temporary:
            target = Path(temporary) / 'maintenance.zip'
            target.write_bytes(changed)
            Path(str(target) + '.sha256').write_text(
                maintenance.sha(changed) + '  ' + target.name + '\n', encoding='ascii')
            with self.assertRaises(ValueError):
                verifier.verify(projected, target)

    def test_different_zip_container_with_same_payload_needs_delivery_pin(self):
        with historical_maintenance_root() as projected:
            report = json.loads((projected / maintenance.RECORD).read_bytes())
            payload = maintenance.qualified_payload(projected, report)
            target_payload = io.BytesIO()
            with zipfile.ZipFile(target_payload, 'w') as archive:
                for name, content in sorted(payload.items()):
                    info = zipfile.ZipInfo(maintenance.package.PACKAGE + '/' + name,
                                           date_time=(1980, 1, 1, 0, 0, 0))
                    info.compress_type = zipfile.ZIP_DEFLATED
                    info.create_system = 3
                    info.external_attr = (stat.S_IFREG | 0o644) << 16
                    archive.writestr(info, content, compress_type=zipfile.ZIP_DEFLATED,
                                     compresslevel=1)
            alternate = target_payload.getvalue()
            self.assertNotEqual(maintenance.sha(alternate),
                                maintenance.sha((projected / maintenance.LOCATION).read_bytes()))
            self.assertEqual(verifier._read_package_payload(alternate, payload), payload)
            with tempfile.TemporaryDirectory() as temporary:
                target = Path(temporary) / 'maintenance.zip'
                target.write_bytes(alternate)
                Path(str(target) + '.sha256').write_text(
                    maintenance.sha(alternate) + '  ' + target.name + '\n', encoding='ascii')
                with self.assertRaisesRegex(ValueError, 'delivery package digest differs'):
                    verifier.verify(projected, target)


if __name__ == '__main__':
    unittest.main()
