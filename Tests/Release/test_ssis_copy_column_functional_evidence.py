"""Gegenproben verhindern die Aufwertung unvollständiger funktionaler ZIP-Fälle."""
from pathlib import Path
import copy
import json
import sys
import unittest

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'Scripts/Release'))
import validate_ssis_copy_column_functional as validator

class FunctionalEvidenceTests(unittest.TestCase):
    def setUp(self):
        self.report=json.loads((ROOT/validator.REPORT).read_bytes())

    def reject(self,change,label):
        r=copy.deepcopy(self.report);change(r)
        with self.assertRaisesRegex(ValueError,label):validator.validate(r)

    def test_actual_record_archive_and_method_closure(self):
        validator.validate(self.report)

    def test_complete_ordered_unique_matrix_required(self):
        self.reject(lambda r:r['cases'].pop(),'CONTEXTS')
        self.reject(lambda r:r['cases'].reverse(),'ROSTER')
        self.reject(lambda r:r['cases'].__setitem__(1,copy.deepcopy(r['cases'][0])),'ROSTER')

    def test_counts_and_integer_types_required(self):
        self.reject(lambda r:r.update(assertions=15203),'TOTALS')
        self.reject(lambda r:r['cases'][0].update(owned_databases_removed=True),'CASE_COUNTS')
        self.reject(lambda r:r['accounting'].update(retries=False),'ACCOUNTING')

    def test_all_five_functional_subcases_must_be_counted(self):
        self.reject(lambda r:r['cases'][0]['functional_subcase_assertions'].pop('SSIS_RELEASE_RIGHTS_PASS'),'SUBCASES')
        self.reject(lambda r:r['cases'][0].update(functional_assertions=208),'CASE_COUNTS')

    def test_cl170_extended_semantics_not_replaced_by_lower_level(self):
        self.reject(lambda r:r['cases'][-1]['functional_subcase_assertions'].update(SSIS_CURRENT_QUALIFICATION_SEMANTICS_PASS=688),'SUBCASES')
        self.reject(lambda r:r['cases'][-1].update(functional_assertions=1028),'CASE_COUNTS')

    def test_fresh_audit_must_bind_final_journal(self):
        self.reject(lambda r:r['cases'][0].update(audit_binds_final_journal=False),'CASE_CLEANUP')
        self.reject(lambda r:r['cases'][0].update(fresh_independent_audit='not executed'),'CASE_RESULT')

    def test_real_login_and_two_database_cleanup_required(self):
        self.reject(lambda r:r['cases'][0].update(owned_procedure_login_removed=False),'CASE_CLEANUP')
        self.reject(lambda r:r['cases'][0].update(owned_databases_created=1),'CASE_COUNTS')

    def test_rights_scope_and_concrete_exception_required(self):
        self.reject(lambda r:r.update(rights_scope='unrestricted'),'RIGHTS_SCOPE')
        self.reject(lambda r:r.update(user_rights_exception_recorded=False),'RIGHTS_SCOPE')

    def test_failed_coordinator_and_missing_procedure_not_pass(self):
        self.reject(lambda r:r['cases'][0].update(result='FAILED_CLEANED'),'CASE_RESULT')
        self.reject(lambda r:r['cases'][0].update(procedure_assertions=0),'CASE_COUNTS')

    def test_configuration_and_trust_cleanup_cannot_be_assumed(self):
        for key in ('configuration_restored_or_unchanged','own_trust_absence_audited'):
            self.reject(lambda r:r['cases'][0].update({key:False}),'CASE_CLEANUP')

    def test_no_whole_module_gui_tls_or_publication_claim(self):
        for key in self.report['scope']:
            with self.subTest(key=key):
                self.reject(lambda r:r['scope'].update({key:not r['scope'][key]}),'SCOPE')
        self.reject(lambda r:r['scope'].update(actual_procedure_and_rights=1),'SCOPE')

    def test_same_archive_and_reused_framework_are_explicit(self):
        self.reject(lambda r:r['package'].update(provider_sha512='0'*128),'PACKAGE_BINDING')
        self.reject(lambda r:r['framework_reuse'].update(new_execution=True),'FRAMEWORK_REUSE')

    def test_closed_no_retry_budget_and_history_preserved(self):
        self.reject(lambda r:r['accounting'].update(retries=1),'ACCOUNTING')
        self.reject(lambda r:r['accounting'].update(previous_failures_and_closed_limits_preserved=False),'ACCOUNTING')
        self.reject(lambda r:r['accounting'].update(within_original_window=False),'ACCOUNTING')

    def test_current_runtime_source_and_exact_inputs_required(self):
        self.reject(lambda r:r.update(runtime_source_commit='0'*40),'RUNTIME_SOURCE')
        key=next(iter(self.report['source_sha256']))
        self.reject(lambda r:r['source_sha256'].pop(key),'SOURCE_CLOSURE')
        self.reject(lambda r:r['source_sha256'].update({key:'0'*64}),'SOURCE_DRIFT')

if __name__=='__main__':unittest.main()
