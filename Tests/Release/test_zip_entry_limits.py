"""Unabhängige Composerstruktur und tatsächliche Admission ohne Labzugriff."""
from pathlib import Path
from datetime import datetime, timedelta, timezone
import copy
import hashlib
import json
import shutil
import struct
import subprocess
import tempfile
import unittest
import zipfile

import compose_zip_entry_limits as composer

ROOT = Path(__file__).resolve().parents[2]
DRIVER = ROOT / 'Tests/Release/Invoke-ZipEntryLimitsLab.ps1'
KNOWN = ROOT / 'Releases/1.0.0/zip-entry-count-qualification.json'


class EntryLimitComposerTests(unittest.TestCase):
    def test_valid_production_boundaries_with_independent_zip_metadata(self):
        with tempfile.TemporaryDirectory(dir=ROOT / '.runtime') as directory:
            for compressed in (True, False):
                for overflow in (False, True):
                    path = Path(directory) / (str(compressed) + str(overflow) + '.zip')
                    record = composer.compose(path, compressed=compressed, overflow=overflow)
                    expected_output = (1 if compressed else 67108864) + int(overflow)
                    expected_packed = (134217728 if compressed else 67108864) + int(overflow)
                    self.assertEqual((record['compressed_bytes'], record['output_bytes']), (expected_packed, expected_output))
                    self.assertEqual(path.stat().st_size, expected_packed + 120)
                    with path.open('rb') as stream:
                        header = struct.unpack('<IHHHHHIIIHH', stream.read(30))
                    self.assertEqual((header[0], header[3], header[7], header[8]), (0x04034B50, 8 if compressed else 0, expected_packed, expected_output))
                    with zipfile.ZipFile(path) as archive:
                        self.assertEqual(archive.namelist(), ['payload.txt'])
                        if compressed:
                            self.assertEqual(archive.read('payload.txt'), b'ab' if overflow else b'a')

    def test_existing_output_and_nonprivate_directory_are_rejected(self):
        with tempfile.TemporaryDirectory(dir=ROOT / '.runtime') as directory:
            path = Path(directory) / 'existing.zip'
            path.write_bytes(b'unchanged')
            with self.assertRaises(FileExistsError):
                composer.compose(path, compressed=True, overflow=False)
            self.assertEqual(path.read_bytes(), b'unchanged')
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'not-private'
            with self.assertRaises(ValueError):
                composer.main(path)
            self.assertFalse(path.exists())


@unittest.skipUnless(shutil.which('pwsh'), 'PowerShell 7 required')
class EntryLimitAdmissionTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        known = json.loads(KNOWN.read_bytes())
        with zipfile.ZipFile(ROOT / known['package']['path']) as archive:
            names = [n for n in archive.namelist() if n.endswith('/Toolbelt.Archive.ZipMemory.dll')]
            if not names:
                names = [n for n in archive.namelist() if n == 'Toolbelt.Archive.ZipMemory.dll']
            if len(names) != 1:
                raise AssertionError('Unique known ZIP DLL required')
            cls.dll = archive.read(names[0])
        if hashlib.sha256(cls.dll).hexdigest() != known['binary']['sha256']:
            raise AssertionError('Known ZIP DLL bytes required')

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='entry-admission-', dir=ROOT / '.runtime')
        self.directory = Path(self.temp.name)
        dll = self.directory / 'known.dll'
        dll.write_bytes(self.dll)
        exports = {}
        for mode in ('local', 'central'):
            path = self.directory / (mode + '.sql')
            path.write_text('SELECT 1;\n', encoding='utf-8')
            exports[mode] = str(path)
        fixtures = {}
        for compressed in (True, False):
            for overflow in (False, True):
                key = ('compressed' if compressed else 'output') + ('_overflow' if overflow else '_cap')
                packed = (134217728 if compressed else 67108864) + int(overflow)
                size = (1 if compressed else 67108864) + int(overflow)
                # Admission-only metadata: actual nonexistent payloads must not be read.
                fixtures[key] = dict(path=str(self.directory / (key + '.zip')), size=packed + 120,
                    sha256='0' * 64, compressed_bytes=packed, output_bytes=size, payload_sha256='0' * 64,
                    crc32=0, method=8 if compressed else 0, overflow=overflow)
        self.manifest = self.directory / 'manifest.json'
        self.manifest.write_text(json.dumps(dict(schema_version='zip-entry-hardlimit-fixtures/v1',
            compressed_limit_bytes=134217728, output_limit_bytes=67108864, limits_overridden=False,
            independent_zip_crc_verified=True, fixtures=fixtures)), encoding='utf-8')
        paths = [DRIVER, self.manifest, KNOWN, dll, *(Path(p) for p in exports.values()), *(ROOT / p for p in (
            'Tests/Release/Invoke-ApiQualificationLab.ps1', 'Tests/Release/Invoke-StablePackageLab.ps1',
            'Tests/Release/ClrCaller.Environment.ps1', 'Tests/CI/run-csv-memory-lab.ps1',
            'Tests/CI/run-lab-local.ps1', 'Tests/CI/LabQualifiedContract.ps1'))]
        started = datetime.now(timezone.utc) - timedelta(seconds=5)
        self.record = dict(schema_version='zip-entry-hardlimit-lab/v1', explicit_qualification_approved=True,
            fixture_manifest=str(self.manifest), exports=exports,
            artifact=dict(path=str(dll), module_id='toolbelt.archive.zip-memory', sql_name='Toolbelt_Archive_ZipMemory',
                          sha256=hashlib.sha256(self.dll).hexdigest().upper(), sha512=hashlib.sha512(self.dll).hexdigest().upper()),
            started_utc=started.isoformat(), deadline_utc=(started + timedelta(minutes=45)).isoformat(),
            cases=[dict(Platform='windows', Version='2025', Patch='CU8', CL=170),
                   dict(Platform='linux', Version='2019', Patch='latest', CL=150)],
            pins=[dict(path=str(p), sha256=hashlib.sha256(p.read_bytes()).hexdigest().upper()) for p in paths])

    def tearDown(self):
        self.temp.cleanup()

    def admission(self, record=None):
        path = self.directory / 'runset.json'
        path.write_text(json.dumps(record or self.record), encoding='utf-8')
        result = subprocess.run(['pwsh', '-NoProfile', '-File', str(DRIVER), '-RunsetPath', str(path),
                                 '-CaseIndex', '1', '-ValidateOnly'], cwd=ROOT,
                                capture_output=True, text=True, timeout=20)
        self.assertEqual(list(self.directory.glob('case-*')), [])
        return result

    def test_actual_scope_admission_does_not_read_payloads_or_lab(self):
        result = self.admission()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('no payload read/Lab import/SQL', result.stdout)

    def test_authority_target_and_method_pin_are_not_optional(self):
        for mutate in (lambda r: r.update(explicit_qualification_approved='true'),
                       lambda r: r['cases'][1].update(Version='2022'),
                       lambda r: r['cases'][0].update(Patch='base'),
                       lambda r: r['pins'].pop(0)):
            record = copy.deepcopy(self.record)
            mutate(record)
            self.assertNotEqual(self.admission(record).returncode, 0)

    def test_unrelated_self_hashed_dll_is_not_a_known_artifact(self):
        path = Path(self.record['artifact']['path'])
        path.write_bytes(b'unrelated')
        record = copy.deepcopy(self.record)
        record['artifact'].update(sha256=hashlib.sha256(path.read_bytes()).hexdigest().upper(),
                                  sha512=hashlib.sha512(path.read_bytes()).hexdigest().upper())
        for pin in record['pins']:
            if pin['path'] == str(path):
                pin['sha256'] = record['artifact']['sha256']
        self.assertNotEqual(self.admission(record).returncode, 0)

    def test_scaled_quota_and_expired_window_are_rejected(self):
        record = copy.deepcopy(self.record)
        expired = datetime.now(timezone.utc) - timedelta(hours=2)
        record.update(started_utc=expired.isoformat(), deadline_utc=(expired + timedelta(minutes=45)).isoformat())
        self.assertNotEqual(self.admission(record).returncode, 0)
        meta = json.loads(self.manifest.read_bytes())
        meta['compressed_limit_bytes'] = 1024
        self.manifest.write_text(json.dumps(meta), encoding='utf-8')
        for pin in self.record['pins']:
            if pin['path'] == str(self.manifest):
                pin['sha256'] = hashlib.sha256(self.manifest.read_bytes()).hexdigest().upper()
        self.assertNotEqual(self.admission().returncode, 0)


if __name__ == '__main__':
    unittest.main()
