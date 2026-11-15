"""No scope promotion, fabricated receipt, missing cleanup or source drift."""
from pathlib import Path
import copy
import json
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'Scripts/Release'))
import validate_ssis_copy_column_ssms as validator


class CopySsmsEvidenceTests(unittest.TestCase):
    def setUp(self):
        self.record = json.loads((ROOT / validator.REPORT).read_bytes())

    def reject(self, change, label):
        r = copy.deepcopy(self.record)
        change(r)
        with self.assertRaisesRegex(ValueError, label):
            validator.validate(r)

    def test_current_actual_record_and_archive(self):
        validator.validate(self.record)

    def test_failed_or_partial_coordinator_cannot_be_promoted(self):
        self.reject(lambda r: r['case'].update(coordinator_result='FAILED_CLEANED'), 'TOTAL_CASE')
        self.reject(lambda r: r['case'].update(full_script_and_receipt_executed=False), 'TOTAL_CASE')
        self.reject(lambda r: r['case'].update(receipt_phase=1), 'TOTAL_CASE')

    def test_copy_and_sqlcmd_stop_are_both_required(self):
        for key in ('complete_unicode_grid_copy', 'copy_hash_verified_before_execution',
                    'later_batch_stopped', 'executed_editor_text_verified'):
            with self.subTest(key=key):
                self.reject(lambda r: r['case'].update({key: False}), 'TOTAL_CASE')

    def test_fresh_final_journal_bound_windows_audit_required(self):
        for key in ('binds_exact_final_journal', 'fresh_independent_windows_process',
                    'configuration_restored', 'trust_restored', 'other_consumers_unchanged'):
            with self.subTest(key=key):
                self.reject(lambda r: r['audit'].update({key: False}), 'CLEANUP')

    def test_other_authentication_target_or_tls_scope_rejected(self):
        self.reject(lambda r: r['target'].update(authentication='SQL'), 'TARGET')
        self.reject(lambda r: r['target'].update(test_purpose='AuthenticatedTls'), 'TARGET')
        self.reject(lambda r: r['target'].update(compatibility_level=170), 'TARGET')

    def test_declared_scope_cannot_be_widened(self):
        for key in self.record['scope']:
            with self.subTest(key=key):
                self.reject(lambda r: r['scope'].update({key: not r['scope'][key]}), 'SCOPE')

    def test_manual_assistance_cannot_be_hidden(self):
        self.reject(lambda r: r['assistance'].update(authentication_automated=True), 'ASSISTANCE')
        self.reject(lambda r: r['assistance'].update(manual_steps=[]), 'ASSISTANCE')

    def test_counter_types_closed_budget_and_history_required(self):
        self.reject(lambda r: r['case'].update(completed_cases=True), 'TOTAL_CASE')
        self.reject(lambda r: r['budget'].update(closed=False), 'BUDGET')
        self.reject(lambda r: r['budget'].update(retries=1), 'BUDGET')
        self.reject(lambda r: r['reuse'].update(historical_records_unchanged=False), 'REUSE')

    def test_stale_artifact_and_incomplete_source_closure_rejected(self):
        self.reject(lambda r: r['artifacts'].update(assembly_sha256='0' * 64), 'CURRENT_ARTIFACTS')
        self.reject(lambda r: r['source_sha256'].pop(next(iter(r['source_sha256']))), 'SOURCE_CLOSURE')
        key = next(iter(self.record['source_sha256']))
        self.reject(lambda r: r['source_sha256'].update({key: '0' * 64}), 'SOURCE_DRIFT')



# Historische C7-Quellenbindung bleibt von der aktuellen Korrektur getrennt.
import sys
sys.path.insert(0,str(ROOT/'Scripts/Release'))
from ssis_historical_scope import copy_column_v1_scope
def setUpModule():
    global _historical_scope, _original_paths
    _historical_scope=copy_column_v1_scope(ROOT)
    snapshot=_historical_scope.__enter__()
    _original_paths={key:value for key,value in list(globals().items())
                     if isinstance(value,Path) and value.is_relative_to(ROOT)}
    original=ROOT
    for key,value in _original_paths.items():
        globals()[key]=snapshot/value.relative_to(original)
def tearDownModule():
    globals().update(_original_paths)
    _historical_scope.__exit__(None,None,None)

if __name__ == '__main__':
    unittest.main()
