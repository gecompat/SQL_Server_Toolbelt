"""Keine Umwertung des erhaltenen WrongType-Stubs in erfolgreiche Deinstallation."""
from pathlib import Path
import json
import sys
import unittest

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'Scripts/Release'))
import validate_xlsx_wrongtype_rest as proof


class XlsxWrongTypeRestTests(unittest.TestCase):
    def record(self):return json.loads((ROOT/proof.REPORT).read_bytes())
    def test_original_execution_and_reused_artifacts_are_bound(self):
        self.assertEqual(proof.validate(ROOT)['status'],'PARTIAL')

    def test_missing_foreign_witness_or_invented_uninstall_is_rejected(self):
        for kind in ('fixture','deploy','uninstall','witness','normal-uninstall'):
            r=self.record();g=r['cases'][0]['wrongtype_groups'][0]
            if kind=='fixture':g['fixture']='MarkerMissing'
            elif kind=='deploy':g['deploy_rejections']=0
            elif kind=='uninstall':g['uninstall_rejections']=0
            elif kind=='witness':g['foreign_witnesses']=2
            else:r['cases'][0]['lifecycle'].append('local/Uninstall')
            with self.subTest(kind=kind),self.assertRaises(ValueError):proof.validate(ROOT,r)

    def test_missing_audit_or_mode_is_rejected(self):
        for kind in ('audit','mode','missing','cleanup'):
            r=self.record()
            if kind=='audit':r['cases'][0]['audit']='NOT_EXECUTED'
            elif kind=='mode':r['cases'][0]['modes']=['local']
            elif kind=='missing':r['cases'].pop()
            else:r['cases'][0]['databases_removed']=1
            with self.subTest(kind=kind),self.assertRaises(ValueError):proof.validate(ROOT,r)

    def test_original_source_and_consumption_remain(self):
        for kind in ('failure','source','method','process','bounds','history'):
            r=self.record()
            if kind=='failure':r['audit_failures']=[]
            elif kind=='source':r['methods']['initial']['source_sha256']['Tests/CI/run-xlsx-types-lab.ps1']='0'*64
            elif kind=='method':r['cases'][0]['method_id']='corrected'
            elif kind=='process':r['cases'][4]['process_result']='EXIT_ZERO_COMPLETE_CAPTURE'
            elif kind=='bounds':r['bounds']['dispatches']=22
            else:r['green_replay']=True
            with self.subTest(kind=kind),self.assertRaises(ValueError):proof.validate(ROOT,r)

    def test_real_rights_or_whole_module_upgrade_is_rejected(self):
        for key,value in [('status','PASS_FOR_DECLARED_SCOPE'),('rights_granted',True),('not_claimed',[])]:
            r=self.record();r[key]=value
            with self.subTest(key=key),self.assertRaises(ValueError):proof.validate(ROOT,r)


if __name__=='__main__':unittest.main()
