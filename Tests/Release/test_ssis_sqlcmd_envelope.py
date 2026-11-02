"""Reale mehrbatchige Eingaben und fail-closed SSMS-SQLCMD-Testinstrumentierung."""
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
HELPER = ROOT / 'Modules/toolbelt.tsql.ssis-debug/Tests/WindowsClientRecovery/New-SsmsSqlcmdEnvelope.ps1'
AREA = HELPER.parent


@unittest.skipUnless(shutil.which('pwsh'), 'PowerShell required; no native fallback')
class SqlcmdEnvelopeTests(unittest.TestCase):
    def check(self, body_suffix='', receipt_suffix='', mutate_output=None, changed_hash=False, replay=False):
        runtime = ROOT / '.runtime'; runtime.mkdir(exist_ok=True)
        with tempfile.TemporaryDirectory(prefix='ssms-sqlcmd-', dir=runtime) as temp:
            stage = Path(temp)
            self.assertTrue(stage.resolve().is_relative_to(runtime.resolve()))
            db = 'ContosoSsisRecovery_' + 'a' * 32
            body = f"-- Grüße Ω 😀\nIF DB_NAME()<>N'{db}' THROW 50000,'context',1;\n"
            body += "CREATE TABLE #Synthetic(Value int);\nGO\nINSERT #Synthetic VALUES(1);\nGO\nSELECT Value FROM #Synthetic;\nGO\nDROP TABLE #Synthetic;\n"
            body += body_suffix
            receipt = f"USE [{db}];\nUPDATE dbo.SyntheticSsisGuiReceipt SET Phase=2;\nSELECT N'SSIS_WINDOWS_CLIENT_GUI_PASS';\nUSE master;\n" + receipt_suffix
            copy, rec, output = (stage / n for n in ('body.sql', 'receipt.sql', 'execution.sql'))
            copy.write_bytes(body.replace('\n', '\r\n').encode('utf-8-sig'))
            rec.write_bytes(receipt.encode('utf-8-sig'))
            args = [shutil.which('pwsh'), '-NoProfile', '-File', str(HELPER),
                    '-CopiedScriptPath', str(copy), '-ExpectedUtf16LfSha256',
                    '0' * 64 if changed_hash else hashlib.sha256(body.encode('utf-16-le')).hexdigest().upper(),
                    '-ReceiptPath', str(rec), '-ExpectedReceiptSha256', hashlib.sha256(rec.read_bytes()).hexdigest().upper(),
                    '-Database', db, '-OutputPath', str(output)]
            def run(extra=()):
                return subprocess.run([*args, *extra], capture_output=True, text=True, timeout=20)
            r = run()
            if body_suffix or receipt_suffix or changed_hash:
                self.assertNotEqual(r.returncode, 0)
                self.assertFalse(output.exists())
                return r
            self.assertEqual(r.returncode, 0, r.stderr)
            expected = f':ON ERROR EXIT\nUSE [{db}];\nGO\n' + body + '\nGO\n' + receipt + '\nGO\n'
            self.assertEqual(output.read_text(encoding='utf-8-sig'), expected)
            self.assertEqual(copy.read_text(encoding='utf-8-sig'), body)
            self.assertEqual(rec.read_text(encoding='utf-8-sig'), receipt)
            self.assertEqual(expected.count(':ON ERROR EXIT'), 1)
            if replay:
                return run()
            if mutate_output:
                output.write_bytes(mutate_output(expected).encode('utf-8-sig'))
            return run(('-VerifyExisting',))

    def test_legitimate_go_batches_preserve_entire_body_and_receipt(self):
        r = self.check()
        self.assertEqual(r.returncode, 0, r.stderr)
        d = json.loads(r.stdout)
        self.assertTrue(d['verifiedExisting'])
        self.assertTrue(d['sqlcmdModeRequired'])
        self.assertEqual(d['onError'], 'EXIT')

    def test_removed_or_weakened_error_directive_is_rejected(self):
        for mutate in (lambda s: s.replace(':ON ERROR EXIT\n', ''),
                       lambda s: s.replace(':ON ERROR EXIT', ':ON ERROR IGNORE')):
            with self.subTest(mutate=mutate):
                r = self.check(mutate_output=mutate)
                self.assertNotEqual(r.returncode, 0)
                self.assertIn('SSMS_SQLCMD_EXECUTED_FILE_CHANGED', r.stderr)

    def test_body_receipt_or_batch_changes_are_rejected(self):
        for mutate in (lambda s: s.replace('Ω', '?'), lambda s: s.replace('SET Phase=2', 'SET Phase=1'),
                       lambda s: s.replace('\nGO\n', '\n', 1), lambda s: s + '\n'):
            with self.subTest(mutate=mutate):
                r = self.check(mutate_output=mutate)
                self.assertNotEqual(r.returncode, 0)

    def test_embedded_client_directives_are_rejected_before_writing(self):
        for suffix in (':ON ERROR IGNORE\n', ':r synthetic.sql\n', ':CONNECT localhost\n', '!! echo synthetic\n'):
            with self.subTest(suffix=suffix):
                r = self.check(body_suffix=suffix)
                self.assertIn('SSMS_SQLCMD_EMBEDDED_CLIENT_COMMAND', r.stderr)

    def test_substitution_inside_sql_literal_is_rejected(self):
        r = self.check(body_suffix="SELECT N'$(SyntheticVariable)';\n")
        self.assertIn('SSMS_SQLCMD_EMBEDDED_CLIENT_COMMAND', r.stderr)

    def test_receipt_client_directive_is_rejected(self):
        r = self.check(receipt_suffix=':ON ERROR IGNORE\n')
        self.assertIn('SSMS_SQLCMD_EMBEDDED_CLIENT_COMMAND', r.stderr)

    def test_wrong_copy_hash_is_rejected_before_writing(self):
        self.assertIn('SSMS_SQLCMD_COPY_CHANGED', self.check(changed_hash=True).stderr)

    def test_existing_output_cannot_be_replayed(self):
        self.assertNotEqual(self.check(replay=True).returncode, 0)


@unittest.skipUnless(shutil.which('pwsh'), 'PowerShell required; no native fallback')
class SqlcmdProfileTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        r = subprocess.run([shutil.which('pwsh'), '-NoProfile', '-File', str(AREA / 'Invoke-SsmsSqlcmd.ps1'),
            '-PlanPath', str(ROOT / '.runtime/unused-sqlcmd-plan.json'), '-DescribeOnly'],
            capture_output=True, text=True, timeout=20)
        if r.returncode:
            raise AssertionError(r.stderr)
        cls.d = json.loads(r.stdout)

    def test_compiled_profile_keeps_visible_manual_login_and_guards(self):
        self.assertIn("$start.ArgumentList.Add('-nosplash')", self.d['preflight'])
        self.assertNotIn("$start.ArgumentList.Add('-C')", self.d['preflight'])
        self.assertIn('manualConnectionRequired=$true', self.d['preflight'])
        self.assertIn('[datetimeoffset]::UtcNow.AddSeconds(1200)', self.d['preflight'])
        self.assertNotIn('[datetimeoffset]::UtcNow.AddSeconds(600)', self.d['preflight'])
        self.assertIn('(Get-SsmsDeadline).AddSeconds(-600)', self.d['preflight'])
        self.assertIn("throw 'SSIS_SSMS_TARGET_PREFLIGHT_TIMEOUT'", self.d['preflight'])
        for guard in ('WRONG_LAB_TARGET', 'WINDOWS_AUTH_REQUIRED', 'ENCRYPTED_CONNECTION_REQUIRED', 'SSMS_REQUIRED'):
            self.assertIn(guard, self.d['preflightQuery'])
        self.assertLess(self.d['canonical'].index(' Invoke-SsmsTargetPreflight\n'),
                        self.d['canonical'].index('Exec-Client $master ($prepare.Replace'))

    def test_native_stop_probe_observes_unchanged_phase_before_real_execution(self):
        g = self.d['gui']
        for text in ('SSIS_SQLCMD_EXPECTED_STOP', 'SET Phase=99', '$negativePassed=$false',
                     '$r.Rows[0].Phase-eq 1', 'SQLCMD_ERROR_STOPS_BEFORE_LATER_SENTINEL',
                     'sqlcmd-negative.pass.json', 'SQLCMD_MODE_AND_NEGATIVE_STOP_OBSERVED',
                     '$negativePassed -and $visual.sqlcmdMode-is [bool]'):
            self.assertIn(text, g)
        self.assertIn('+$guard+', g)
        self.assertIn("'.08-ExecutedNegative.sql'", g)
        self.assertIn('executedTextMatched=$true', g)
        self.assertLess(g.index('SQLCMD_ERROR_STOPS_BEFORE_LATER_SENTINEL'),
                        g.index("if($r.Rows[0].Phase-eq 2 -and $app.HasExited"))

    def test_real_envelope_copy_windows_and_process_checks_are_retained(self):
        g = self.d['gui']
        self.assertIn("'New-SsmsSqlcmdEnvelope.ps1'", g)
        self.assertNotIn("'New-SsmsExecutionEnvelope.ps1'", g)
        for guard in ('EXECUTION_ENVELOPE_PRESERVES_COMPLETE_COPY_AND_RECEIPT',
                      'COMPLETE_GUI_COPY_UNICODE_TRANSPORT', 'ACTUAL_SSMS_WINDOWS_LOGIN',
                      'SSIS_CLIENT_SSMS_PROCESS_OWNERSHIP_DRIFT', '-VerifyExisting'):
            self.assertIn(guard, g)

    def test_operator_abort_is_fail_closed_in_preflight_and_gui(self):
        for key in ('preflight', 'gui'):
            with self.subTest(key=key):
                self.assertIn("operator-abort.json", self.d[key])
                self.assertIn("throw 'SSIS_SQLCMD_OPERATOR_ABORT'", self.d[key])


if __name__ == '__main__':
    unittest.main()
