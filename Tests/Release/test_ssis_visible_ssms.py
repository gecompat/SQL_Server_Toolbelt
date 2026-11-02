"""SQL-freie Prüfung: eigenes SSMS vor dem Anmeldedialog sichtbar machen."""
import json
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
AREA = Path('Modules/toolbelt.tsql.ssis-debug/Tests/WindowsClientRecovery')


@unittest.skipUnless(shutil.which('pwsh'), 'PowerShell required; no native fallback')
class VisibleSsmsTests(unittest.TestCase):
    @staticmethod
    def describe(root):
        return subprocess.run([shutil.which('pwsh'), '-NoProfile', '-File',
            str(root / AREA / 'Invoke-VisibleSsms.ps1'), '-PlanPath',
            str(root / '.runtime/unused-visible-plan.json'), '-DescribeOnly'],
            capture_output=True, text=True, timeout=20)

    @classmethod
    def setUpClass(cls):
        r = cls.describe(ROOT)
        if r.returncode:
            raise AssertionError(r.stderr)
        cls.d = json.loads(r.stdout)

    def test_start_has_no_connection_or_query_file_arguments(self):
        p = self.d['preflight']
        self.assertEqual(re.findall(r'\$start\.ArgumentList\.Add\(([^)]+)\)', p), ["'-nosplash'"])
        self.assertIn('$start.UseShellExecute=$false', p)
        self.assertIn('ProcessWindowStyle]::Maximized', p)
        self.assertIn('$script:ssmsTargetApp=[Diagnostics.Process]::Start($start)', p)

    def test_manual_target_contract_is_explicit_but_not_a_pass(self):
        p = self.d['preflight']
        for field in ('targetDataSource=$builder.DataSource', "encrypt='Mandatory'",
                      'trustServerCertificate=[bool]$builder.TrustServerCertificate',
                      'manualConnectionRequired=$true', 'connectionArgumentsPassed=$false',
                      'ssmsStartedUtc=$script:ssmsTargetStarted', 'databaseNotCreated=$true'):
            self.assertIn(field, p)
        self.assertIn("state='SSMS_TARGET_PREFLIGHT'", p)
        self.assertIn('VISIBLE_SSMS_TARGET_PREFLIGHT', p)
        self.assertIn('SSMS_TARGET_PREFLIGHT_NOT_COMPLETED', p)

    def test_real_preflight_receipt_and_process_guards_remain(self):
        d = self.d
        self.assertLess(d['canonical'].index(' Invoke-SsmsTargetPreflight\n'),
                        d['canonical'].index('Exec-Client $master ($prepare.Replace'))
        for name in ('Invoke-VisibleSsms.ps1', 'VisibleSsmsHook.ps1',
                     'AutonomousSsmsHook.ps1', 'SsmsGuiHook.ps1', 'New-SsmsExecutionEnvelope.ps1'):
            self.assertIn(name, d['canonical'])
        self.assertNotIn('/Invoke-AutonomousSsms.ps1', d['canonical'])
        for guard in ('WRONG_LAB_TARGET', 'WINDOWS_AUTH_REQUIRED', 'ENCRYPTED_CONNECTION_REQUIRED', 'SSMS_REQUIRED'):
            self.assertIn(guard, d['preflightQuery'])
        for guard in ('EXECUTION_ENVELOPE_PRESERVES_COMPLETE_COPY_AND_RECEIPT',
                      'COMPLETE_GUI_COPY_UNICODE_TRANSPORT', 'ACTUAL_SSMS_WINDOWS_LOGIN',
                      'SSIS_CLIENT_SSMS_PROCESS_OWNERSHIP_DRIFT', "$r.Rows[0].Phase-eq 2 -and $app.HasExited"):
            self.assertIn(guard, d['gui'])

    def test_changed_prior_hook_is_rejected_without_lab_access(self):
        runtime = ROOT / '.runtime'; runtime.mkdir(exist_ok=True)
        with tempfile.TemporaryDirectory(prefix='ssms-visible-', dir=runtime) as temp:
            stage = Path(temp)
            self.assertTrue(stage.resolve().is_relative_to(runtime.resolve()))
            folder = stage / AREA; folder.mkdir(parents=True)
            for name in ('Invoke-VisibleSsms.ps1', 'VisibleSsmsHook.ps1', 'AutonomousSsmsHook.ps1',
                         'SsmsGuiHook.ps1', 'Invoke-WindowsClient.ps1', 'ClientGuiHook.ps1',
                         'Invoke-TransportRecovery.ps1', 'New-SsmsExecutionEnvelope.ps1'):
                (folder / name).write_bytes((ROOT / AREA / name).read_bytes())
            control = self.describe(stage)
            self.assertEqual(control.returncode, 0, control.stderr)
            prior = folder / 'AutonomousSsmsHook.ps1'
            prior.write_bytes(prior.read_bytes() + b'\n# changed\n')
            r = self.describe(stage)
            self.assertNotEqual(r.returncode, 0)
            self.assertIn('VISIBLE_SSMS_PRIOR_HOOK_CHANGED', r.stderr)


if __name__ == '__main__':
    unittest.main()
