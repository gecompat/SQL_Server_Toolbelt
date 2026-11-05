"""Synthetic evidence counterexamples; these fixtures never constitute native proof."""
import copy
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / 'Scripts/Release'))
import validate_ssis_fresh_build as validator


def fixture():
    digest = 'a' * 64
    matrix = {'result': 'PASS', 'fresh_contexts': 12, 'reused_contexts': 0,
              'assembly_sha256': digest,
              'package': {'path': validator.ARCHIVE, 'sha256': 'b' * 64, 'manifest_sha256': 'c' * 64},
              'cases': [{'platform': 'windows', 'sql_version': v, 'patch': validator.PATCHES[v],
                         'compatibility_level': cl, 'deployment_mode': mode,
                         'coordinator_result': 'PASS_CLEANED', 'cleanup_audit': 'PASS',
                         'fresh_execution': True, 'package_assertions': 8,
                         'procedure_assertions': 222, 'functional_assertions': 1028}
                        for v, cl, mode in sorted(validator.CONTEXTS)]}
    ssms = {'coordinator_result': 'PASS_CLEANED', 'cleanup_audit': 'PASS', 'fresh_execution': True,
            'platform': 'windows', 'sql_version': '2025', 'patch': 'CU8',
            'compatibility_level': 150, 'deployment_mode': 'local',
            'receipt_phase': 2, 'result_rows': 2, 'assembly_sha256': digest,
            'authentication_automated': False, 'test_purpose': 'Functional',
            'authentication': 'Windows', 'trust_server_certificate': True}
    ssms.update({key: True for key in ('gui_visible', 'windows_authentication', 'exact_lab_target',
        'encrypted', 'complete_unicode_copy', 'copy_hash_verified_before_execution', 'sqlcmd_mode',
        'native_error_stopped_later_batch', 'full_script_and_receipt_executed')})
    tls = {'result': 'PASS', 'fresh_execution': True, 'supervisor_result': 'PASS',
           'sql_cleanup_audit': 'PASS', 'lab_cleanup_audit': 'PASS', 'own_vm_removed': True,
           'encrypt': True, 'trust_server_certificate': False, 'signed_v2': True,
           'same_export_bytes': True, 'fresh_reader_before_each_open': True, 'fallback': False,
           'strict_client_stacks': 2, 'sql_build': '17.0.1000.7', 'compatibility_level': 170,
           'deployment_modes': ['local', 'central'], 'sql_assertions': 412, 'assembly_sha256': digest,
           'test_purpose': 'AuthenticatedTls', 'authentication': 'SQL'}
    tls['lab_method'] = {'repository': 'gecompat/SQL_Server_Lab',
                        'path': 'Tests/Integration/Invoke-ToolbeltSsisCurrentTlsAcceptance.ps1',
                        'commit': 'e' * 40, 'sha256': 'f' * 64}
    return {'kind': 'ssis_fresh_current_build_qualification', 'result': 'PASS',
            'publication_authorized': False, 'current_api_parameters': 40,
            'qualified_assembly_sha256': digest, 'historical_failures_preserved': True,
            'zip_matrix': matrix, 'ssms': ssms, 'authenticated_tls': tls,
            'source_sha256': {p: digest for p in (
                validator.MODULE + 'Tests/Runtime/Invoke-FreshBuildLab.ps1',
                validator.MODULE + 'Tests/WindowsClientRecovery/Invoke-CurrentBuildSsms.ps1',
                validator.MODULE + 'Tests/WindowsClientRecovery/CurrentBuildArtifacts.ps1')}}


class FreshEvidenceTests(unittest.TestCase):
    def test_synthetic_complete_shape(self):
        validator.validate(fixture(), check_files=False)

    def reject(self, change):
        report = fixture()
        change(report)
        with self.assertRaises(ValueError):
            validator.validate(report, check_files=False)

    def test_composed_or_historical_matrix_is_not_fresh(self):
        self.reject(lambda r: r['zip_matrix'].update(reused_contexts=1))
        self.reject(lambda r: r['zip_matrix']['cases'][0].update(fresh_execution=False))

    def test_missing_and_duplicate_contexts_fail(self):
        self.reject(lambda r: r['zip_matrix']['cases'].pop())
        self.reject(lambda r: r['zip_matrix']['cases'].__setitem__(1, copy.deepcopy(r['zip_matrix']['cases'][0])))

    def test_failed_coordinator_or_missing_audit_is_not_upgraded(self):
        for section in ('zip_matrix', 'ssms'):
            self.reject(lambda r, s=section: (r[s]['cases'][0] if s == 'zip_matrix' else r[s]).update(coordinator_result='FAILED_CLEANED'))
            self.reject(lambda r, s=section: (r[s]['cases'][0] if s == 'zip_matrix' else r[s]).update(cleanup_audit='not executed'))

    def test_missing_receipt_and_unobserved_error_stop_fail(self):
        self.reject(lambda r: r['ssms'].update(receipt_phase=1))
        self.reject(lambda r: r['ssms'].update(native_error_stopped_later_batch=False))

    def test_missing_or_different_ssms_target_scope_fails(self):
        self.reject(lambda r: r['ssms'].pop('sql_version'))
        self.reject(lambda r: r['ssms'].update(compatibility_level=170))

    def test_tls_trust_fallback_or_partial_supervisor_fails(self):
        for key, value in [('trust_server_certificate', True), ('fallback', True),
                           ('supervisor_result', 'FAIL'), ('sql_cleanup_audit', 'not executed'),
                           ('fresh_reader_before_each_open', False)]:
            self.reject(lambda r, k=key, v=value: r['authenticated_tls'].update({k: v}))

    def test_different_build_or_absent_current_method_fails(self):
        self.reject(lambda r: r['ssms'].update(assembly_sha256='d' * 64))
        self.reject(lambda r: r.update(current_api_parameters=38))
        self.reject(lambda r: r['authenticated_tls']['lab_method'].update(repository='Contoso/Other'))

    def test_failure_history_and_publication_boundary(self):
        self.reject(lambda r: r.update(historical_failures_preserved=False))
        self.reject(lambda r: r.update(publication_authorized=True))


if __name__ == '__main__':
    unittest.main()
