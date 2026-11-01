"""Reale SQL-freie Adaptergegenproben vor der einzigen nativen SSMS-Welle."""
import json
import hashlib
import copy
import sys
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


class EvidenceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        sys.path.insert(0, str(ROOT / 'Scripts/Release'))
        import validate_ssis_ssms_gui as validator
        import validate_ssis_preparation_recovery as previous
        cls.validator = validator
        cls.report = json.loads((ROOT / validator.RECORD).read_text(encoding='utf-8'))
        cls.windows = json.loads((ROOT / previous.WINDOWS_RECORD).read_text(encoding='utf-8'))

    def reject(self, path, value):
        report = copy.deepcopy(self.report)
        item = report
        for key in path[:-1]:
            item = item[key]
        item[path[-1]] = value
        with self.assertRaises((ValueError, KeyError, TypeError)):
            self.validator.validate_report(report, lambda p: (ROOT / p).read_bytes(), self.windows)

    def test_actual_report_and_dependencies(self):
        self.assertEqual(self.validator.validate(ROOT)['result'], 'PASS_FOR_DECLARED_SCOPE')

    def test_failed_coordinator_cannot_be_promoted(self):
        for path, value in [(('result',), 'PASS_CLEANED'), (('native_assertions',), 14),
                (('coordinator', 'state'), 'PASS_CLEANED'), (('coordinator', 'native_cases'), 1),
                (('coordinator', 'overall_pass_claimed'), True),
                (('coordinator', 'phase2_receipt_executed'), True)]:
            with self.subTest(path=path): self.reject(path, value)

    def test_windows_target_precedes_database(self):
        for key, value in [('before_database_creation', False), ('instance_process_start_witness_matched', False),
                           ('windows_authentication', 'SQL'), ('same_owned_instance_reused', False)]:
            with self.subTest(key=key): self.reject(('target_preflight', key), value)

    def test_whole_hash_unicode_and_execution_are_required(self):
        for key in ('whole_cell_copied', 'saved_utf16_lf_hash_matched', 'unicode_preserved', 'copied_script_executed'):
            with self.subTest(key=key): self.reject(('gui', key), False)

    def test_visual_oracles_and_types_are_required(self):
        for key, value in [('target_rows', 1), ('target_rows', 2.0), ('messages_errors', 1),
                           ('separate_visual_evidence', False), ('operator_assistance', 1)]:
            with self.subTest(key=key, value=value): self.reject(('gui', key), value)

    def test_fresh_audit_and_exact_cleanup_are_required(self):
        self.reject(('cleanup', 'fresh_windows_audit'), 'not executed')
        self.reject(('cleanup', 'database_removed'), False)
        self.reject(('cleanup', 'trust_restored'), False)

    def test_options_and_copy_method_are_bound(self):
        for key, value in [('non_xml_character_limit', 65535), ('retain_crlf', False),
                           ('configured_before_generation', False)]:
            with self.subTest(key=key): self.reject(('result_options', key), value)
        self.reject(('copy_check', 'method_sha256'), '0' * 64)
        self.reject(('transport', 'authenticated_tls_claimed'), True)
        self.reject(('history', 'prior_safety_audit_not_promoted'), False)

    def test_source_closure_and_native_method_cannot_be_rebound(self):
        pins = dict(self.report['source_sha256']); pins.pop(next(iter(pins)))
        self.reject(('source_sha256',), pins)
        path = next(iter(self.validator.METHODS))
        self.reject(('source_sha256', path), '0' * 64)
        report = copy.deepcopy(self.report)
        changed = (ROOT / path).read_bytes() + b'\n# changed after native execution\n'
        report['source_sha256'][path] = self.validator.digest(changed)
        with self.assertRaises(ValueError):
            self.validator.validate_report(report, lambda p: changed if p == path else (ROOT / p).read_bytes(), self.windows)


if __name__ == '__main__':
    unittest.main()
