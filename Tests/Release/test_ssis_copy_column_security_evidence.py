"""Aktuelles ANSI-Delta getrennt von historischen C7- und TLS-Nachweisen."""
from pathlib import Path
import copy
import sys
import unittest
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'Scripts/Release'))
import validate_ssis_copy_column_security as evidence
import validate_ssis_copy_column as prior
from ssis_historical_scope import copy_column_v1_scope

class SecurityCorrectionTests(unittest.TestCase):
    def test_independent_review_accepts_sources_only(self):
        evidence.validate_review()

    def test_review_cannot_upgrade_native_or_independence_scope(self):
        for change in (lambda r:r.update(independent_reviewer=False),
                       lambda r:r.update(changed_input_followups=1),
                       lambda r:r['scope'].update(native_tls_result=True),
                       lambda r:r['lab_context_revision_review'].update(native_revision_committed=True),
                       lambda r:r['lab_context_revision_review'].update(native_tls_executed=True),
                       lambda r:r['lab_context_revision_review'].update(native_tls_executed=0),
                       lambda r:r['lab_context_revision_review'].update(registry_freshness_floor_preserved=False),
                       lambda r:r['isolated_setup_review'].update(native_pass_inferred=True),
                       lambda r:r['isolated_setup_review'].update(runtime_executed_by_reviewer=True),
                       lambda r:r['isolated_setup_review'].update(original_failed_review_preserved=False),
                       lambda r:r['isolated_setup_review'].update(native_pass_inferred=0),
                       lambda r:r['open_findings'].append('unresolved')):
            r=copy.deepcopy(evidence.validate_review());change(r)
            with self.assertRaises(ValueError):evidence.validate_review(r)

    def test_current_delta_and_historical_evidence(self):
        evidence.validate()
        with copy_column_v1_scope(ROOT):prior.validate()
        with self.assertRaisesRegex(ValueError,'source drift'):prior.validate()

    def test_missing_cases_audit_provider_or_history_are_rejected(self):
        for change in (lambda r:r['cases'].pop(),lambda r:r['cases'][3].update(cleanup_audit='not executed'),
                       lambda r:r['provider'].update(sha256='0'*64),lambda r:r['history'].update(first_total_case='PASS_CLEANED'),
                       lambda r:r['accounting'].update(target_audit_dispatches=8)):
            r=copy.deepcopy(evidence.validate());change(r)
            with self.assertRaises(ValueError):evidence.validate(r)

    def test_no_tls_security_total_or_publication_upgrade(self):
        for key in ('full_module_qualification','fresh_authenticated_tls','security_total_acceptance','publication_authorized'):
            r=copy.deepcopy(evidence.validate());r['scope'][key]=True
            with self.assertRaises(ValueError):evidence.validate(r)
        r=copy.deepcopy(evidence.validate());r['scope']['fresh_authenticated_tls']=0
        with self.assertRaises(ValueError):evidence.validate(r)

    def test_complete_product_and_method_projection_required(self):
        for field in ('product_projection','source_sha256'):
            r=copy.deepcopy(evidence.validate());r[field].pop(next(iter(r[field])))
            with self.assertRaises(ValueError):evidence.validate(r)

if __name__=='__main__':unittest.main()
