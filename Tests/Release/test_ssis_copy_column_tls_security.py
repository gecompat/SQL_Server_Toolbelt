"""Do not infer fresh strict TLS or cleanup from historical/source-only passes."""
from pathlib import Path
import copy
import sys
import unittest
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'Scripts/Release'))
import validate_ssis_copy_column_tls_security as evidence

class CurrentTlsSecurityTests(unittest.TestCase):
    def test_actual_declared_current_scope(self):
        evidence.validate()

    def test_no_transport_downgrade_or_fabricated_wire_observation(self):
        for key,value in (('trust_server_certificate',True),('encrypt',False),('signed_v2_export',False),
                          ('same_bytes_per_open',False),('fallback_used',True),('wire_fingerprint_observed',True),
                          ('trust_server_certificate',0),('authentication','Windows')):
            r=copy.deepcopy(evidence.validate());r['transport'][key]=value
            with self.assertRaises(ValueError):evidence.validate(r)

    def test_no_missing_audit_or_unrestored_owned_resource(self):
        for key in ('fresh_sql_audit','fresh_lab_audit','fresh_host_scope_audit'):
            r=copy.deepcopy(evidence.validate());r['cleanup'][key]='not executed'
            with self.assertRaises(ValueError):evidence.validate(r)
        for key in ('sql_configuration_restored','host_trust_restored','owned_encrypted_ca_key_removed','foreign_bindings_unchanged'):
            r=copy.deepcopy(evidence.validate());r['cleanup'][key]=False
            with self.assertRaises(ValueError):evidence.validate(r)

    def test_no_historical_or_scope_upgrade(self):
        for key in ('full_module_qualification','fresh_zip_matrix','fresh_ssms','publication_authorized'):
            r=copy.deepcopy(evidence.validate());r['scope'][key]=True
            with self.assertRaises(ValueError):evidence.validate(r)
        for mutate in (lambda r:r['cases'].pop(),lambda r:r['provider'].update(sha256='0'*64),
                       lambda r:r['source_review'].update(sha256='0'*64),lambda r:r['accounting'].update(retries=1),
                       lambda r:r['history'].update(selected_authority_revision='COMMITTED')):
            r=copy.deepcopy(evidence.validate());mutate(r)
            with self.assertRaises(ValueError):evidence.validate(r)

    def test_source_and_method_bindings_are_required(self):
        r=copy.deepcopy(evidence.validate());r['source_sha256'].pop(next(iter(r['source_sha256'])))
        with self.assertRaises(ValueError):evidence.validate(r)
        r=copy.deepcopy(evidence.validate());r['lab_method']['sha256']='0'*64
        with self.assertRaises(ValueError):evidence.validate(r)

if __name__=='__main__':unittest.main()
