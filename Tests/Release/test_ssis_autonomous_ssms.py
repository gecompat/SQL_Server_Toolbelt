"""SQL-freie Gegenproben des autonomen SSMS-Ablaufs und seiner Ausführungshülle."""
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
AREA = ROOT / 'Modules/toolbelt.tsql.ssis-debug/Tests/WindowsClientRecovery'


@unittest.skipUnless(shutil.which('pwsh'), 'PowerShell required; no native fallback')
class AutonomousSsmsTests(unittest.TestCase):
    def invoke(self, name, *args):
        return subprocess.run([shutil.which('pwsh'), '-NoProfile', '-File', str(AREA / name),
                               *map(str, args)], capture_output=True, text=True, timeout=20)

    def test_actual_compiled_profile_preserves_native_guards_and_omits_query_file(self):
        r = self.invoke('Invoke-AutonomousSsms.ps1', '-PlanPath', ROOT / '.runtime/unused.json', '-DescribeOnly')
        self.assertEqual(r.returncode, 0, r.stderr)
        d = json.loads(r.stdout)
        self.assertIn("@('-S',$builder.DataSource,'-d','master','-N','Mandatory'", d['preflight'])
        self.assertNotIn("@($path,'-S'", d['preflight'])
        self.assertLess(d['canonical'].index(' Invoke-SsmsTargetPreflight\n'), d['canonical'].index('Exec-Client $master ($prepare.Replace'))
        for name in ('Invoke-AutonomousSsms.ps1', 'AutonomousSsmsHook.ps1', 'SsmsGuiHook.ps1', 'New-SsmsExecutionEnvelope.ps1'):
            self.assertIn(name, d['canonical'])
        for guard in ('ACTUAL_SSMS_WINDOWS_LOGIN', 'COMPLETE_GUI_COPY_UNICODE_TRANSPORT',
                      'EXECUTION_ENVELOPE_PRESERVES_COMPLETE_COPY_AND_RECEIPT',
                      'SSIS_CLIENT_SSMS_PROCESS_OWNERSHIP_DRIFT', "$r.Rows[0].Phase-eq 2 -and $app.HasExited"):
            self.assertIn(guard, d['gui'])
        self.assertIn('-ExpectedReceiptSha256 $completeSha256', d['gui'])
        self.assertLess(d['gui'].index('$completeSha256=(Get-FileHash $completePath).Hash'),
                        d['gui'].index("Save-ClientPrivate ($JournalPath+'.gui-ready.json')"))
        for guard in ('WRONG_LAB_TARGET', 'WINDOWS_AUTH_REQUIRED', 'ENCRYPTED_CONNECTION_REQUIRED', 'SSMS_REQUIRED'):
            self.assertIn(guard, d['preflightQuery'])

    def envelope(self, copied_change=None, receipt_change=None, wrong_db=False, executed_change=None, replay=False, batch_suffix=''):
        runtime = ROOT / '.runtime'; runtime.mkdir(exist_ok=True)
        with tempfile.TemporaryDirectory(prefix='ssms-envelope-', dir=runtime) as temp:
            stage = Path(temp)
            db = 'ContosoSsisRecovery_' + 'a' * 32
            script = "-- Grüße Ω 😀\nIF DB_NAME()<>N'" + db + "' THROW 50000,'context',1;\n" + "SELECT 1; -- Unicode Ω\n" * 8000
            script += batch_suffix
            receipt = f"USE [{db}];\nUPDATE dbo.SyntheticSsisGuiReceipt SET Phase=2;\nSELECT N'SSIS_WINDOWS_CLIENT_GUI_PASS';\nUSE master;\n"
            copy_path, receipt_path, output = (stage / name for name in ('copy.sql', 'receipt.sql', 'envelope.sql'))
            copy_path.write_bytes((copied_change(script) if copied_change else script).replace('\n', '\r\n').encode('utf-8-sig'))
            receipt_path.write_bytes(receipt.encode('utf-8-sig'))
            receipt_hash = hashlib.sha256(receipt_path.read_bytes()).hexdigest().upper()
            if receipt_change:
                receipt_path.write_bytes(receipt_change(receipt).encode('utf-8-sig'))
            args = ['-CopiedScriptPath', copy_path, '-ExpectedUtf16LfSha256', hashlib.sha256(script.encode('utf-16-le')).hexdigest().upper(),
                    '-ReceiptPath', receipt_path, '-ExpectedReceiptSha256', receipt_hash,
                    '-Database', db if not wrong_db else db.replace('a', 'b'), '-OutputPath', output]
            r = self.invoke('New-SsmsExecutionEnvelope.ps1', *args)
            if copied_change or receipt_change or wrong_db or batch_suffix:
                self.assertFalse(output.exists())
                return r
            self.assertEqual(r.returncode, 0, r.stderr)
            expected = f'USE [{db}];\n' + script + '\n' + receipt
            self.assertEqual(output.read_text(encoding='utf-8-sig'), expected)
            self.assertEqual(copy_path.read_text(encoding='utf-8-sig'), script)
            if replay:
                return self.invoke('New-SsmsExecutionEnvelope.ps1', *args)
            if executed_change:
                output.write_bytes(executed_change(expected).encode('utf-8-sig'))
            return self.invoke('New-SsmsExecutionEnvelope.ps1', *args, '-VerifyExisting')

    def test_complete_unicode_body_and_real_receipt_remain_separate_and_exact(self):
        r = self.envelope()
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertTrue(json.loads(r.stdout)['verifiedExisting'])

    def test_truncated_copy_is_rejected_before_writing(self):
        r = self.envelope(copied_change=lambda s: s[:65535])
        self.assertNotEqual(r.returncode, 0)
        self.assertIn('SSMS_ENVELOPE_COPY_CHANGED', r.stderr)

    def test_changed_receipt_is_rejected_before_writing(self):
        r = self.envelope(receipt_change=lambda s: s.replace('Phase=2', 'Phase=1'))
        self.assertNotEqual(r.returncode, 0)
        self.assertIn('SSMS_ENVELOPE_RECEIPT_CHANGED', r.stderr)

    def test_wrong_database_is_rejected_before_writing(self):
        r = self.envelope(wrong_db=True)
        self.assertNotEqual(r.returncode, 0)
        self.assertIn('SSMS_ENVELOPE_RECEIPT_SCOPE', r.stderr)

    def test_changed_executed_body_receipt_or_context_is_rejected(self):
        for mutate in (lambda s: s.replace('Ω', '?'), lambda s: s.replace('SET Phase=2', 'SET Phase=1'), lambda s: s + '\n'):
            with self.subTest(mutate=mutate):
                r = self.envelope(executed_change=mutate)
                self.assertNotEqual(r.returncode, 0)
                self.assertIn('SSMS_ENVELOPE_EXECUTED_FILE_CHANGED', r.stderr)

    def test_existing_output_cannot_be_silently_replayed(self):
        r = self.envelope(replay=True)
        self.assertNotEqual(r.returncode, 0)

    def test_batch_separator_cannot_run_receipt_after_failed_body(self):
        for suffix in ('GO\n', '  go 2 -- repeated batch\n', 'GO/* batch */\n'):
            with self.subTest(suffix=suffix):
                r = self.envelope(batch_suffix=suffix)
                self.assertNotEqual(r.returncode, 0)
                self.assertIn('SSMS_ENVELOPE_MULTIPLE_BATCHES', r.stderr)


if __name__ == '__main__':
    unittest.main()
