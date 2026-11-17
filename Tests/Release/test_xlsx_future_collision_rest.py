"""Keine Fehlerlöschung oder gesamte Kollisionsqualifikation aus vier Fixtures."""
from pathlib import Path
import json
import sys
import unittest

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'Scripts/Release'))
import validate_xlsx_future_collision_rest as proof


class XlsxFutureCollisionRestTests(unittest.TestCase):
    def record(self):return json.loads((ROOT/proof.REPORT).read_bytes())
    def test_original_execution_and_reused_artifacts_are_bound(self):
        self.assertEqual(proof.validate(ROOT)['status'],'PASS_FOR_DECLARED_SCOPE')

    def test_missing_foreign_case_or_genuine_restore_is_rejected(self):
        for kind in ('fixture','restore','recovery','legacy'):
            r=self.record()
            if kind=='fixture':r['cases'][0]['future_groups'][0]['completed_faults'].pop()
            elif kind=='restore':r['cases'][0]['future_groups'][0]['legacy_witnesses']=4
            elif kind=='recovery':r['cases'][0]['lifecycle'].pop()
            else:r['legacy_reference']['artifact_sha256']='0'*64
            with self.subTest(kind=kind),self.assertRaises(ValueError):proof.validate(ROOT,r)

    def test_missing_audit_or_mode_is_rejected(self):
        for kind in ('audit','mode','missing','cleanup'):
            r=self.record()
            if kind=='audit':r['cases'][0]['audit']='NOT_EXECUTED'
            elif kind=='mode':r['cases'][0]['modes']=['local']
            elif kind=='missing':r['cases'].pop()
            else:r['cases'][0]['databases_removed']=1
            with self.subTest(kind=kind),self.assertRaises(ValueError):proof.validate(ROOT,r)

    def test_original_failure_source_and_consumption_remain(self):
        for kind in ('failure','source','bounds','correction'):
            r=self.record()
            if kind=='failure':r['initial_failure']['state']='COMPLETE'
            elif kind=='source':r['method']['source_sha256']['Tests/CI/run-xlsx-types-lab.ps1']='0'*64
            elif kind=='bounds':r['bounds']['dispatches']=24
            else:r['correction']='fresh reset'
            with self.subTest(kind=kind),self.assertRaises(ValueError):proof.validate(ROOT,r)

    def test_real_rights_or_whole_module_upgrade_is_rejected(self):
        for key,value in [('status','PASS'),('rights_granted',True),('not_claimed',[])]:
            r=self.record();r[key]=value
            with self.subTest(key=key),self.assertRaises(ValueError):proof.validate(ROOT,r)


if __name__=='__main__':unittest.main()
