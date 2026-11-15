"""Gegenproben halten Archivinstallation und umfassendere Qualifikation getrennt."""
from pathlib import Path
import copy
import json
import sys
import unittest
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'Scripts/Release'))
import validate_ssis_copy_column_delivery as validator


class DeliveryEvidenceTests(unittest.TestCase):
    def setUp(self):
        self.report=json.loads((ROOT/validator.REPORT).read_bytes())

    def reject(self,change,label):
        r=copy.deepcopy(self.report);change(r)
        with self.assertRaisesRegex(ValueError,label):validator.validate(r)

    def test_actual_record_and_archive(self):
        validator.validate(self.report)

    def test_complete_ordered_matrix_required(self):
        self.reject(lambda r:r['cases'].pop(),'CONTEXTS')
        self.reject(lambda r:r['cases'].reverse(),'ROSTER')

    def test_counts_and_integer_types_required(self):
        self.reject(lambda r:r.update(package_assertions=95),'TOTALS')
        self.reject(lambda r:r['cases'][0].update(owned_databases_removed=True),'CASE_COUNTS')
        self.reject(lambda r:r['history'].update(pre_sql_failed_attempts=True),'HISTORY_TYPES')

    def test_fresh_audit_must_bind_final_journal(self):
        self.reject(lambda r:r['cases'][0].update(audit_binds_final_journal=False),'CASE_CLEANUP')
        self.reject(lambda r:r['cases'][0].update(fresh_independent_audit='not executed'),'CASE_RESULT')

    def test_configuration_and_trust_cannot_be_assumed(self):
        for key in ('configuration_restored_or_unchanged','own_trust_absence_audited'):
            with self.subTest(key=key):
                r=copy.deepcopy(self.report);r['cases'][0][key]=False
                with self.assertRaisesRegex(ValueError,'CASE_CLEANUP'):validator.validate(r)

    def test_declared_delivery_does_not_qualify_broader_scope(self):
        for key in self.report['scope']:
            r=copy.deepcopy(self.report);r['scope'][key]=not r['scope'][key]
            with self.subTest(key=key),self.assertRaisesRegex(ValueError,'SCOPE'):validator.validate(r)

    def test_missing_pre_sql_audit_cannot_be_promoted(self):
        self.reject(lambda r:r['history'].update(failed_attempt_independent_sql_audit='PASS'),'HISTORY')
        self.reject(lambda r:r['history'].update(original_failure_preserved=False),'HISTORY')

    def test_unchanged_framework_proof_is_reused_not_new_execution(self):
        self.reject(lambda r:r['framework_reuse'].update(new_execution=True),'FRAMEWORK_REUSE')

    def test_other_dll_is_not_qualified(self):
        self.reject(lambda r:r['package'].update(provider_sha512='0'*128),'QUALIFIED_PACKAGE')

    def test_changed_source_and_archive_rejected(self):
        key=next(iter(self.report['source_sha256']))
        self.reject(lambda r:r['source_sha256'].update({key:'0'*64}),'SOURCE_DRIFT')
        self.reject(lambda r:r['package'].update(sha256='0'*64),'ARCHIVE_DRIFT')

    def test_failed_coordinator_does_not_count_as_pass(self):
        self.reject(lambda r:r['cases'][0].update(result='FAILED_CLEANED'),'CASE_RESULT')


if __name__=='__main__':unittest.main()
