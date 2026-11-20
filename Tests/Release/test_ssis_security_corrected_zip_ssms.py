"""Gegenproben: Gesamtkoordinator, Receipt, aktuelle DLL und frische Matrixaudits."""
from pathlib import Path
import copy,json,sys,unittest,tempfile
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'Scripts/Release'))
from validate_ssis_security_corrected_zip_ssms import validate_historical as validate,historical_qualification_records as qualification_records,REPORT,validate as validate_current
class QualificationTests(unittest.TestCase):
    def setUp(self):self.record=json.loads((ROOT/REPORT).read_bytes())
    def reject(self,change,label):
        r=copy.deepcopy(self.record);change(r)
        with self.assertRaisesRegex(ValueError,label):validate(r,check_files=False)
    def test_current_complete_record(self):validate(self.record)
    def test_failed_coordinator_never_promoted_from_visual_pass(self):
        self.reject(lambda r:r['ssms']['case'].update(coordinator_result='FAILED_CLEANED'),'GUI_TOTAL_CASE')
    def test_missing_receipt_never_promoted(self):
        self.reject(lambda r:r['ssms']['case'].update(receipt_phase=1),'GUI_RECEIPT')
    def test_matrix_gap_and_missing_fresh_audit(self):
        self.reject(lambda r:r['zip_matrix']['cases'].pop(),'MATRIX')
        self.reject(lambda r:r['zip_matrix']['cases'][0].update(fresh_independent_audit='not executed'),'CASE_AUDIT')
    def test_c7_artifact_not_current(self):
        self.reject(lambda r:r['provider'].update(sha256='94ececae25f9b9568dc6564445f9070bc09d80dc287026b15be920ec31906b5a'),'CURRENT_ARTIFACT_BINDING')
    def test_functional_transport_not_promoted_to_strict_tls(self):
        self.reject(lambda r:r['zip_matrix']['cases'][0].update(authenticated_tls='PASS'),'FUNCTIONAL_TRANSPORT')
    def test_native_boolean_is_strict(self):
        self.reject(lambda r:r['ssms']['case'].update(full_script_and_receipt_executed='true'),'GUI_FULL_SCRIPT')
    def test_new_adapter_source_pin_is_required(self):
        self.reject(lambda r:r['source_sha256'].pop('Modules/toolbelt.tsql.ssis-debug/Tests/Runtime/Invoke-SecurityCorrectedFunctionalLab.ps1'),'SOURCE_CLOSURE')
    def test_windows_authentication_cannot_be_inferred_from_sql_login(self):
        self.reject(lambda r:r['ssms']['target'].update(authentication='SQL'),'GUI_TARGET')

    def test_reused_tls_does_not_promote_original_scope(self):
        current,tls=qualification_records(self.record)
        self.assertFalse(tls['scope']['fresh_zip_matrix'])
        self.assertFalse(tls['scope']['fresh_ssms'])
        self.assertEqual(tls['transport']['authentication'],'SQL')
        self.assertFalse(tls['transport']['trust_server_certificate'])
        self.assertEqual(current['ssms']['target']['authentication'],'Windows')
        self.assertTrue(current['ssms']['target']['trust_server_certificate'])
    def test_unknown_authored_runtime_method_is_not_implicitly_qualified(self):
        with tempfile.NamedTemporaryFile(prefix='ContosoCurrentInput_',suffix='.ps1',dir=ROOT/'Modules/toolbelt.tsql.ssis-debug/Tests/Runtime',delete=False) as f:
            p=Path(f.name);f.write(b'# Synthetic new method\n')
        try:
            with self.assertRaisesRegex(ValueError,'SOURCE_CLOSURE'):validate_current(self.record)
        finally:p.unlink()
