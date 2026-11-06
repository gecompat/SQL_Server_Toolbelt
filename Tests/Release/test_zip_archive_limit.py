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

import compose_zip_archive_limit as composer

ROOT = Path(__file__).resolve().parents[2]
DRIVER = ROOT / 'Tests/Release/Invoke-ZipArchiveLimitLab.ps1'
KNOWN = ROOT / 'Releases/1.0.0/zip-entry-count-qualification.json'


class ArchiveLimitComposerTests(unittest.TestCase):
    def test_valid_deterministic_zip32_with_exact_size_and_independent_headers(self):
        with tempfile.TemporaryDirectory(dir=ROOT / '.runtime') as directory:
            paths = [Path(directory) / name for name in ('a.zip', 'b.zip')]
            records = [composer.compose(path, 4096) for path in paths]
            self.assertEqual(paths[0].read_bytes(), paths[1].read_bytes())
            self.assertEqual(records[0]['sha256'], records[1]['sha256'])
            raw = paths[0].read_bytes()
            self.assertEqual(struct.unpack_from('<I', raw)[0], 0x04034B50)
            end = struct.unpack_from('<IHHHHIIH', raw, len(raw) - 22)
            self.assertEqual(end[0], 0x06054B50)
            self.assertEqual(end[3:5], (2, 2))
            self.assertEqual(end[6] + end[5] + 22, len(raw))
            with zipfile.ZipFile(paths[0]) as archive:
                self.assertIsNone(archive.testzip())
                self.assertEqual(archive.read('payload.txt'), b'abc')
                self.assertEqual(archive.read('filler.bin'), bytes(4096 - 219))

    def test_invalid_size_and_existing_outputs_are_rejected(self):
        with tempfile.TemporaryDirectory(dir=ROOT / '.runtime') as directory:
            path = Path(directory) / 'a.zip'
            with self.assertRaises(ValueError):
                composer.compose(path, 218)
            self.assertFalse(path.exists())
            composer.compose(path, 1024)
            with self.assertRaises(FileExistsError):
                composer.compose(path, 1024)


@unittest.skipUnless(shutil.which('pwsh'), 'PowerShell 7 required')
class ArchiveLimitAdmissionTests(unittest.TestCase):
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
        self.temp = tempfile.TemporaryDirectory(prefix='archive-admission-', dir=ROOT / '.runtime')
        self.directory = Path(self.temp.name)
        dll = self.directory / 'known.dll'
        dll.write_bytes(self.dll)
        exports = {}
        for mode in ('local', 'central'):
            path = self.directory / (mode + '.sql')
            path.write_text('SELECT 1;\n', encoding='utf-8')
            exports[mode] = str(path)
        fixtures = {}
        for key, size in (('at_limit', 268435456), ('overflow', 268435457)):
            # Scope-only admission reads metadata; it must not read these payloads.
            path = self.directory / (key + '.zip')
            fixtures[key] = dict(path=str(path), size=size, sha256='0' * 64,
                                  entries=[dict(name='payload.txt', size=3, crc32=0),
                                           dict(name='filler.bin', size=size - 219, crc32=0)])
        self.manifest = self.directory / 'manifest.json'
        self.manifest.write_text(json.dumps(dict(schema_version='zip-archive-hardlimit-fixtures/v1',
            archive_limit_bytes=268435456, limits_overridden=False, payload_hex='616263',
            payload_name='payload.txt', independent_zip_crc_verified=True, fixtures=fixtures)), encoding='utf-8')
        paths = [DRIVER, self.manifest, KNOWN, dll, *(Path(p) for p in exports.values()), *(ROOT / p for p in (
            'Tests/Release/Invoke-ApiQualificationLab.ps1', 'Tests/Release/Invoke-StablePackageLab.ps1',
            'Tests/Release/ClrCaller.Environment.ps1', 'Tests/CI/run-csv-memory-lab.ps1',
            'Tests/CI/run-lab-local.ps1', 'Tests/CI/LabQualifiedContract.ps1'))]
        started = datetime.now(timezone.utc) - timedelta(seconds=5)
        self.record = dict(schema_version='zip-archive-hardlimit-lab/v1', explicit_qualification_approved=True,
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
        meta['archive_limit_bytes'] = 1024
        self.manifest.write_text(json.dumps(meta), encoding='utf-8')
        for pin in self.record['pins']:
            if pin['path'] == str(self.manifest):
                pin['sha256'] = hashlib.sha256(self.manifest.read_bytes()).hexdigest().upper()
        self.assertNotEqual(self.admission().returncode, 0)


if __name__ == '__main__':
    unittest.main()
