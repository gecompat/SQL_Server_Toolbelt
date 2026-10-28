"""Compositional package checks; no builds, SQL connections or publication."""
from pathlib import Path
import copy
import json
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'Scripts/Release'))
import clr_maintenance as maintenance


class ClrMaintenanceTests(unittest.TestCase):
    def record(self):
        return json.loads((ROOT / maintenance.RECORD).read_bytes())

    def test_actual_delivery_is_exact_qualified_derivation(self):
        record = maintenance.verify(ROOT)
        self.assertEqual(len(record['native_cases']), 12)
        self.assertFalse(record['publication_authorized'])

    def test_other_twelve_binaries_and_unselected_sources_remain_identical(self):
        before = maintenance.read_base(ROOT)
        after = maintenance.derive(ROOT)
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
        record = self.record()
        for mutation in ('missing_case', 'missing_audit', 'wrong_mode'):
            broken = copy.deepcopy(record)
            if mutation == 'missing_case':
                broken['native_cases'].pop()
            elif mutation == 'missing_audit':
                broken['native_cases'][0]['independent_cleanup_audit'] = 'NOT_EXECUTED'
            else:
                broken['native_cases'][0]['modes'] = ['local']
            with self.subTest(mutation=mutation), self.assertRaises(ValueError):
                maintenance.qualified_payload(ROOT, broken)

    def test_changed_qualified_source_is_rejected_before_derivation(self):
        original = Path.read_bytes
        path = ROOT / maintenance.SQL_SOURCES[0]

        def read(candidate):
            data = original(candidate)
            return data + b'\nSELECT 1;\n' if candidate == path else data

        with patch.object(Path, 'read_bytes', read), self.assertRaises(ValueError):
            maintenance.qualified_payload(ROOT, self.record())

    def test_broader_claims_unknown_fields_or_omitted_limits_are_rejected(self):
        record = self.record()
        mutations = []
        broken = copy.deepcopy(record); broken['status'] = 'PASS_ALL_PROFILES'; mutations.append(broken)
        broken = copy.deepcopy(record); broken['release_status'] = 'released'; mutations.append(broken)
        broken = copy.deepcopy(record); broken['full_profile_passed'] = True; mutations.append(broken)
        broken = copy.deepcopy(record); broken['qualification_scope']['not_executed'].pop(); mutations.append(broken)
        broken = copy.deepcopy(record); broken['native_cases'][0]['ssis_passed'] = True; mutations.append(broken)
        broken = copy.deepcopy(record); broken['native_cases'][0].pop('patch'); mutations.append(broken)
        for index, broken in enumerate(mutations):
            with self.subTest(mutation=index), self.assertRaises(ValueError):
                maintenance.qualified_payload(ROOT, broken)

    def test_changed_package_is_rejected_even_with_recomputed_sidecar(self):
        data = (ROOT / maintenance.LOCATION).read_bytes()
        changed = bytes([data[0] ^ 1]) + data[1:]
        with tempfile.TemporaryDirectory() as temporary:
            target = Path(temporary) / 'maintenance.zip'
            target.write_bytes(changed)
            Path(str(target) + '.sha256').write_text(
                maintenance.sha(changed) + '  ' + target.name + '\n', encoding='ascii')
            with self.assertRaises(ValueError):
                maintenance.verify(ROOT, target)


if __name__ == '__main__':
    unittest.main()
