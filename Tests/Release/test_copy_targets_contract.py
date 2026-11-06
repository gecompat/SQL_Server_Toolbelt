"""Verbindungslose Admission der fehlenden Copy-Zielkontexte."""
from pathlib import Path
from datetime import datetime, timedelta, timezone
import copy
import hashlib
import json
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
DRIVER = ROOT / 'Tests/Release/Invoke-TableCloneCopyTargetsLab.ps1'


@unittest.skipUnless(shutil.which('pwsh'), 'PowerShell 7 required')
class CopyTargetsAdmissionTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='copy-admission-', dir=ROOT / '.runtime')
        self.directory = Path(self.temp.name)
        exports = {}
        for mode in ('local', 'central'):
            path = self.directory / (mode + '.sql')
            path.write_text('SELECT 1;\n', encoding='utf-8')
            exports[mode] = str(path)
        fixtures = [ROOT / 'Modules/toolbelt.metadata.table-clone/Tests/Runtime' / name
                    for name in ('Copy.Contract.sql', 'Copy.Safety.sql')]
        files = [DRIVER, *fixtures, *(Path(p) for p in exports.values()), *(ROOT / p for p in (
            'Tests/Release/Invoke-ApiQualificationLab.ps1', 'Tests/Release/Invoke-StablePackageLab.ps1',
            'Tests/CI/run-lab-local.ps1', 'Tests/CI/LabQualifiedContract.ps1'))]
        started = datetime.now(timezone.utc) - timedelta(seconds=5)
        cases = []
        for platform in ('windows', 'linux'):
            for version, patch, levels in (('2019', 'CU32', (150,)), ('2022', 'CU26', (150, 160)),
                                            ('2025', 'CU8', (150, 160, 170))):
                for level in levels:
                    cases.append(dict(Platform=platform, Version=version, Patch=patch if platform == 'windows' else 'latest',
                                      CL=level, modes=['local', 'central']))
        for index in (5, 6):
            cases[index]['modes'] = ['central']
        self.record = dict(schema_version='table-clone-copy-targets/v1', explicit_qualification_approved=True,
                           started_utc=started.isoformat(), deadline_utc=(started + timedelta(minutes=45)).isoformat(),
                           fixtures=list(map(str, fixtures)), exports=exports, cases=cases,
                           pins=[dict(path=str(p), sha256=hashlib.sha256(p.read_bytes()).hexdigest().upper()) for p in files])

    def tearDown(self):
        self.temp.cleanup()

    def admission(self, record=None):
        path = self.directory / 'runset.json'
        path.write_text(json.dumps(record or self.record), encoding='utf-8')
        result = subprocess.run(['pwsh', '-NoProfile', '-File', str(DRIVER), '-RunsetPath', str(path),
                                 '-CaseIndex', '11', '-ValidateOnly'], cwd=ROOT, capture_output=True, text=True, timeout=20)
        self.assertEqual(list(self.directory.glob('case-*')), [])
        return result

    def reject(self, mutate):
        record = copy.deepcopy(self.record)
        mutate(record)
        result = self.admission(record)
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_valid_scope_without_lab_import(self):
        result = self.admission()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('no Lab import or SQL', result.stdout)

    def test_authority_requires_boolean_true(self):
        self.reject(lambda r: r.update(explicit_qualification_approved=False))
        self.reject(lambda r: r.update(explicit_qualification_approved='true'))

    def test_deadline_expiry_and_extension(self):
        expired = datetime.now(timezone.utc) - timedelta(hours=2)
        self.reject(lambda r: r.update(started_utc=expired.isoformat(), deadline_utc=(expired + timedelta(minutes=45)).isoformat()))
        self.reject(lambda r: r.update(deadline_utc=(datetime.now(timezone.utc) + timedelta(hours=2)).isoformat()))

    def test_later_target_cannot_be_relabelled(self):
        self.reject(lambda r: r['cases'][11].update(Patch='base'))
        self.reject(lambda r: r['cases'][11].update(CL=160))

    def test_previously_green_local_modes_cannot_be_repeated(self):
        for index in (5, 6):
            self.reject(lambda r: r['cases'][index].update(modes=['local', 'central']))

    def test_fixtures_and_method_pins_are_mandatory(self):
        self.reject(lambda r: r['fixtures'].reverse())
        self.reject(lambda r: r['pins'].pop(0))

    def test_changed_real_export_bytes_are_rejected(self):
        Path(self.record['exports']['local']).write_text('SELECT 2;\n', encoding='utf-8')
        self.assertNotEqual(self.admission().returncode, 0)


if __name__ == '__main__':
    unittest.main()
