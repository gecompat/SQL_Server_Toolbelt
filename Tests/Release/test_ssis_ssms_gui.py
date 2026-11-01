"""Reale SQL-freie Adaptergegenproben vor der einzigen nativen SSMS-Welle."""
import json
import hashlib
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
AREA = Path('Modules/toolbelt.tsql.ssis-debug/Tests/WindowsClientRecovery')


@unittest.skipUnless(shutil.which('pwsh'), 'PowerShell required; no native fallback')
class AdapterTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        result = cls.describe(ROOT)
        if result.returncode:
            raise AssertionError(result.stderr)
        cls.description = json.loads(result.stdout)

    @staticmethod
    def describe(root):
        return subprocess.run([shutil.which('pwsh'), '-NoProfile', '-File', str(root / AREA / 'Invoke-SsmsQualification.ps1'),
            '-PlanPath', str(root / '.runtime/unused-plan.json'), '-DescribeOnly'], capture_output=True, text=True, timeout=20)

    def test_target_preflight_is_before_database_creation_and_bound(self):
        text = self.description['canonical']
        self.assertEqual(text.count(' Invoke-SsmsTargetPreflight\n'), 1)
        self.assertLess(text.index(' Invoke-SsmsTargetPreflight\n'), text.index('Exec-Client $master ($prepare.Replace'))
        for path in ('Invoke-SsmsQualification.ps1', 'SsmsGuiHook.ps1'):
            self.assertIn(str(AREA).replace('\\', '/') + '/' + path, text)

    def test_same_owned_instance_and_remaining_deadline_are_used(self):
        text = self.description['gui']
        self.assertIn('$app=$script:ssmsTargetApp', text)
        self.assertNotIn('[Diagnostics.Process]::Start', text)
        self.assertIn('$clock.Elapsed.TotalSeconds-lt $guiSeconds', text)
        self.assertIn('(Get-SsmsDeadline)', text)
        self.assertIn('SSIS_CLIENT_SSMS_PROCESS_OWNERSHIP_DRIFT', text)

    def test_preflight_rejects_wrong_target_sql_auth_and_unencrypted_client(self):
        text = self.description['preflightQuery']
        for guard in ('WRONG_LAB_TARGET', 'WINDOWS_AUTH_REQUIRED', 'ENCRYPTED_CONNECTION_REQUIRED', 'SSMS_REQUIRED'):
            self.assertIn(guard, text)
        self.assertIn("NOT IN(N'NTLM',N'KERBEROS')", text)
        self.assertIn("encrypt_option=N'TRUE'", text)
        self.assertNotIn('CREATE DATABASE', text)
        self.assertNotIn('sp_configure', text)

    def test_mutated_historical_drivers_are_rejected_without_lab_access(self):
        runtime = ROOT / '.runtime'; runtime.mkdir(exist_ok=True)
        with tempfile.TemporaryDirectory(prefix='ssms-adapter-', dir=runtime) as temporary:
            stage = Path(temporary)
            self.assertTrue(stage.resolve().is_relative_to(runtime.resolve()))
            target = stage / AREA; target.mkdir(parents=True)
            names = ('Invoke-SsmsQualification.ps1', 'SsmsGuiHook.ps1', 'Invoke-WindowsClient.ps1',
                     'ClientGuiHook.ps1', 'Invoke-TransportRecovery.ps1')
            for name in names:
                (target / name).write_bytes((ROOT / AREA / name).read_bytes())
            control = self.describe(stage)
            self.assertEqual(control.returncode, 0, control.stderr)
            for name, error in [('Invoke-WindowsClient.ps1', 'SSMS_ORIGINAL_DRIVER_CHANGED'),
                                ('ClientGuiHook.ps1', 'SSMS_ORIGINAL_HOOK_CHANGED')]:
                original = (target / name).read_bytes()
                (target / name).write_bytes(original + b'\n# changed\n')
                result = self.describe(stage)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn(error, result.stderr)
                (target / name).write_bytes(original)


@unittest.skipUnless(shutil.which('pwsh'), 'PowerShell required; no native fallback')
class CopyTests(unittest.TestCase):
    # Realistischer langer Zelleninhalt: Unicode und SQL-Kommentare benötigen LF.
    SCRIPT = "-- Grüße Ω 😀\n" + ("SELECT N'Grüße Ω'; -- Zeilenende\n" * 6000)

    def verify(self, copied):
        runtime = ROOT / '.runtime'; runtime.mkdir(exist_ok=True)
        with tempfile.TemporaryDirectory(prefix='ssms-copy-', dir=runtime) as temporary:
            stage = Path(temporary)
            self.assertTrue(stage.resolve().is_relative_to(runtime.resolve()))
            path = stage / 'synthetic.sql'
            path.write_bytes(copied.encode('utf-8-sig'))
            expected = hashlib.sha256(self.SCRIPT.encode('utf-16-le')).hexdigest().upper()
            return subprocess.run([shutil.which('pwsh'), '-NoProfile', '-File',
                str(ROOT / AREA / 'Test-SsmsScriptCopy.ps1'), '-CopiedScriptPath', str(path),
                '-ExpectedUtf16LfSha256', expected], capture_output=True, text=True, timeout=20)

    def test_complete_long_unicode_cell(self):
        result = self.verify(self.SCRIPT)
        self.assertEqual(result.returncode, 0, result.stderr)
        record = json.loads(result.stdout)
        self.assertEqual(record['scope'], 'saved-copy-only')
        self.assertEqual(record['utf16CodeUnits'], len(self.SCRIPT.encode('utf-16-le')) // 2)

    def test_crlf_only_normalization(self):
        result = self.verify(self.SCRIPT.replace('\n', '\r\n'))
        self.assertEqual(result.returncode, 0, result.stderr)

    def assert_rejected(self, copied):
        result = self.verify(copied)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('SSMS_SCRIPT_COPY_HASH_MISMATCH', result.stderr)
        self.assertNotIn('"result":"PASS"', result.stdout)

    def test_grid_65535_truncation_is_rejected(self):
        self.assert_rejected(self.SCRIPT[:65535])

    def test_removed_line_breaks_are_rejected(self):
        self.assert_rejected(self.SCRIPT.replace('\n', ''))

    def test_changed_unicode_is_rejected(self):
        self.assert_rejected(self.SCRIPT.replace('Ω', '?'))

    def test_extra_final_row_newline_is_rejected(self):
        self.assert_rejected(self.SCRIPT + '\n')


if __name__ == '__main__':
    unittest.main()
