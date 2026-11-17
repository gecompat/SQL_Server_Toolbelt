from pathlib import Path
import json,sys,unittest
ROOT=Path(__file__).resolve().parents[2];sys.path.insert(0,str(ROOT/'Scripts/Release'))
import validate_xlsx_wrongtype_process_closure as proof
class WrongTypeProcessClosureTests(unittest.TestCase):
 def record(self):return json.loads((ROOT/proof.REPORT).read_bytes())
 def test_original_new_process_and_preserved_partial_are_bound(self):self.assertEqual(proof.validate(ROOT)['status'],'PASS_FOR_DECLARED_SCOPE')
 def test_missing_numeric_or_audit_receipt_is_rejected(self):
  for key in ['exit_code','capture_complete','numeric_receipt_retained','bound_receipt_retained']:
   r=self.record();r['case']['processes'][0][key]=1 if key=='exit_code' else False
   with self.subTest(key=key),self.assertRaises(ValueError):proof.validate(ROOT,r)
 def test_wrong_target_or_missing_cleanup_is_rejected(self):
  for key,value in [('index',3),('cl',170),('databases_removed',1),('fresh_audit','NOT_EXECUTED')]:
   r=self.record();r['case'][key]=value
   with self.subTest(key=key),self.assertRaises(ValueError):proof.validate(ROOT,r)
 def test_history_upgrade_or_replay_is_rejected(self):
  for key in ['unknown_original_return_preserved','original_failures_unchanged','other_historical_cases_replayed']:
   r=self.record()
   if key=='unknown_original_return_preserved':r['historical_reference'][key]=False
   else:r['combined'][key]=key=='other_historical_cases_replayed'
   with self.subTest(key=key),self.assertRaises(ValueError):proof.validate(ROOT,r)
 def test_authority_source_or_nondurable_observation_is_rejected(self):
  for key in ['rights','source','bound','receipt']:
   r=self.record()
   if key=='rights':r['rights_granted']=True
   elif key=='source':r['method']['source_sha256']['Tests/Release/Invoke-XlsxWrongTypeProcessOnce.ps1']='0'*64
   elif key=='bound':r['bounds']['dispatches']=3
   else:r['receipt_method']['numeric_return_before_other_metadata_reads']=False
   with self.subTest(key=key),self.assertRaises(ValueError):proof.validate(ROOT,r)
if __name__=='__main__':unittest.main()
