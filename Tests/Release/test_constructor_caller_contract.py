"""Echte verbindungslose Admission gegen Scope-/Rechte-/Pin-Aufwertung prüfen."""
from pathlib import Path
import copy
from datetime import datetime, timedelta, timezone
import hashlib
import json
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
DRIVER = ROOT / 'Tests/Release/Invoke-JsonConstructorsCallerLab.ps1'


@unittest.skipUnless(shutil.which('pwsh'), 'PowerShell 7 required for actual offline admission')
class ConstructorCallerAdmissionTests(unittest.TestCase):
    def setUp(self):
        (ROOT / '.runtime').mkdir(exist_ok=True)
        self.temp = tempfile.TemporaryDirectory(prefix='constructor-admission-', dir=ROOT / '.runtime')
        self.directory = Path(self.temp.name)
        self.exports = {}
        for mode in ('local', 'central'):
            path = self.directory / (mode + '.sql')
            path.write_text('SELECT 1;\n', encoding='utf-8')
            self.exports[mode] = str(path)
        fixture = ROOT / 'Tests/Release/Runtime/JsonConstructors.CallerRights.sql'
        files = [DRIVER, fixture, *(Path(p) for p in self.exports.values()),
                 *(ROOT / p for p in ('Tests/Release/Invoke-ApiQualificationLab.ps1',
                   'Tests/Release/Invoke-StablePackageLab.ps1', 'Tests/Release/ClrCaller.Environment.ps1',
                   'Tests/CI/run-csv-memory-lab.ps1', 'Tests/CI/run-lab-local.ps1',
                   'Tests/CI/LabQualifiedContract.ps1'))]
        started = datetime.now(timezone.utc) - timedelta(seconds=10)
        self.record = dict(schema_version='json-constructors-caller-contract/v1',
                           explicit_constructor_grants_approved=True,
                           started_utc=started.isoformat(), deadline_utc=(started + timedelta(minutes=45)).isoformat(),
                           fixture=str(fixture), exports=self.exports,
                           pins=[dict(path=str(p), sha256=hashlib.sha256(p.read_bytes()).hexdigest().upper()) for p in files],
                           cases=[dict(Platform='windows', Version=v, Patch=p, CL=cl) for v, p, cl in (
                               ('2019', 'CU32', 150), ('2022', 'CU26', 150), ('2022', 'CU26', 160),
                               ('2025', 'CU8', 150), ('2025', 'CU8', 160), ('2025', 'CU8', 170))])

    def tearDown(self):
        self.temp.cleanup()

    def admission(self, record=None, index=0):
        path = self.directory / 'runset.json'
        path.write_text(json.dumps(record or self.record), encoding='utf-8')
        result = subprocess.run(['pwsh', '-NoProfile', '-File', str(DRIVER), '-RunsetPath', str(path),
                                 '-CaseIndex', str(index), '-ValidateOnly'], cwd=ROOT,
                                capture_output=True, text=True, timeout=20)
        self.assertEqual(list(self.directory.glob('case-*')), [], 'No native journal in offline admission')
        return result

    def reject(self, mutate):
        record = copy.deepcopy(self.record)
        mutate(record)
        result = self.admission(record)
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_actual_offline_admission_does_not_import_lab(self):
        result = self.admission(index=5)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('no Lab import or SQL', result.stdout)

    def test_explicit_constructor_grants_are_required(self):
        self.reject(lambda r: r.update(explicit_constructor_grants_approved=False))

    def test_string_cannot_impersonate_boolean_authority(self):
        self.reject(lambda r: r.update(explicit_constructor_grants_approved='true'))

    def test_no_extended_or_expired_deadline(self):
        self.reject(lambda r: r.update(deadline_utc=(datetime.now(timezone.utc) + timedelta(hours=2)).isoformat()))
        self.reject(lambda r: r.update(started_utc=(datetime.now(timezone.utc) - timedelta(hours=2)).isoformat(),
                                      deadline_utc=(datetime.now(timezone.utc) - timedelta(minutes=75)).isoformat()))

    def test_unsupported_platform_and_patch_are_rejected(self):
        self.reject(lambda r: r['cases'][0].update(Platform='linux'))
        self.reject(lambda r: r['cases'][0].update(Patch='base'))

    def test_relabelled_or_duplicate_context_is_rejected(self):
        self.reject(lambda r: r['cases'][0].update(Version='2025', Patch='CU8', CL=170))

    def test_actual_changed_export_bytes_are_rejected(self):
        Path(self.exports['local']).write_text('SELECT 2;\n', encoding='utf-8')
        self.assertNotEqual(self.admission().returncode, 0)

    def test_missing_mandatory_method_pin_is_rejected(self):
        self.reject(lambda r: r['pins'].pop(0))

    def test_metadata_oracle_accepts_sparse_in_place_column_ids(self):
        # ALTER DROP/ADD lässt stabile IDs mit Lücken bestehen. Der ausgeführte
        # SQL-Oracle muss die Reihenfolge statt erfundener dichter IDs prüfen.
        sql = (ROOT / 'Tests/Release/Runtime/JsonConstructors.CallerRights.sql').read_text(encoding='utf-8')
        self.assertNotIn('column_id=1', sql)
        self.assertNotIn('column_id=2', sql)
        self.assertIn("name=N''GroupOrdinal'')>=(SELECT column_id", sql)
        self.assertIn('max_length=-1 AND is_nullable=0', sql)


if __name__ == '__main__':
    unittest.main()
