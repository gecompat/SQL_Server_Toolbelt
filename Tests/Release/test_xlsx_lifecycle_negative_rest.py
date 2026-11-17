"""Kein Minimalrechte-PASS aus synthetischen Lifecyclefehlern ableiten."""
from pathlib import Path
import json
import sys
import unittest

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'Scripts/Release'))
import validate_xlsx_lifecycle_negative_rest as proof


class XlsxLifecycleNegativeRestTests(unittest.TestCase):
    def record(self):return json.loads((ROOT/proof.REPORT).read_bytes())
    def test_original_executed_method_is_bound(self):
        self.assertEqual(proof.validate(ROOT)['status'],'PASS_FOR_DECLARED_SCOPE')

    def test_missing_negative_group_or_wrong_error_scope_is_rejected(self):
        for kind in ('rollback','locks','visibility','scope'):
            r=self.record()
            if kind=='scope':r['visibility_method']='real minimal permissions'
            else:r['cases'][0]['negative_groups'][0][kind]=0
            with self.subTest(kind=kind),self.assertRaises(ValueError):proof.validate(ROOT,r)

    def test_missing_fresh_audit_or_mode_is_rejected(self):
        for kind in ('audit','mode','missing','cleanup'):
            r=self.record()
            if kind=='audit':r['cases'][0]['audit']='NOT_EXECUTED'
            elif kind=='mode':r['cases'][0]['modes']=['local']
            elif kind=='missing':r['cases'].pop()
            else:r['cases'][0]['databases_removed']=1
            with self.subTest(kind=kind),self.assertRaises(ValueError):proof.validate(ROOT,r)

    def test_original_helper_and_closed_bounds_remain(self):
        for kind in ('source','bounds','counts'):
            r=self.record()
            if kind=='source':r['method']['source_sha256']['Tests/CI/run-xlsx-types-lab.ps1']='0'*64
            elif kind=='bounds':r['bounds']['native_closed']=False
            else:r['totals']['negative_cases']=527
            with self.subTest(kind=kind),self.assertRaises(ValueError):proof.validate(ROOT,r)

    def test_real_rights_or_whole_module_upgrade_is_rejected(self):
        for key,value in [('status','PASS'),('rights_granted',True),('not_claimed',[])]:
            r=self.record();r[key]=value
            with self.subTest(key=key),self.assertRaises(ValueError):proof.validate(ROOT,r)


if __name__=='__main__':unittest.main()
