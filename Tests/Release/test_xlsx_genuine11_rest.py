"""Keine Versionsmarkerfälschung, historische Aufwertung oder grüne Wiederholung."""
from pathlib import Path
import json
import sys
import unittest

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'Scripts/Release'))
import validate_xlsx_genuine11_rest as proof


class XlsxGenuine11RestTests(unittest.TestCase):
    def record(self):return json.loads((ROOT/proof.REPORT).read_bytes())
    def test_original_execution_is_bound(self):
        self.assertEqual(proof.validate(ROOT)['status'],'PASS_FOR_DECLARED_SCOPE')

    def test_fake_original_version_or_missing_source_is_rejected(self):
        for kind in ('version','source','repro','slots'):
            r=self.record()
            if kind=='version':r['legacy']['installed_version']='1.2.0'
            elif kind=='source':r['legacy']['source_sha256'].pop(next(iter(r['legacy']['source_sha256'])))
            elif kind=='repro':r['legacy']['reproducible_bytes']=False
            else:r['legacy']['installed_slots']=9
            with self.subTest(kind=kind),self.assertRaises(ValueError):proof.validate(ROOT,r)

    def test_missing_audit_or_local_replay_is_rejected(self):
        for kind in ('audit','replay','missing','helper'):
            r=self.record()
            if kind=='audit':r['cases'][0]['audit']='NOT_EXECUTED'
            elif kind=='replay':r['cases'][-1]['modes']=['local']
            elif kind=='missing':r['cases'].pop()
            else:r['cases'][0]['helpers'].pop()
            with self.subTest(kind=kind),self.assertRaises(ValueError):proof.validate(ROOT,r)

    def test_original_method_and_closed_bounds_remain(self):
        for kind in ('method','bounds','history','checkout','invocation'):
            r=self.record()
            if kind=='method':r['methods'][0]['source_sha256']['Tests/Release/Xlsx.Genuine11.Workload.ps1']='0'*64
            elif kind=='bounds':r['bounds']['native_closed']=False
            elif kind=='checkout':r['methods'][0]['executed_source_sha256']['Tests/Release/Xlsx.Genuine11.Workload.ps1']='0'*64
            elif kind=='invocation':r['invocation_history']['native_dispatches']=1
            else:r['plan_revision']='new start'
            with self.subTest(kind=kind),self.assertRaises(ValueError):proof.validate(ROOT,r)

    def test_whole_module_or_rights_upgrade_is_rejected(self):
        for key,value in [('status','PASS'),('rights_granted',True),('not_claimed',[])]:
            r=self.record();r[key]=value
            with self.subTest(key=key),self.assertRaises(ValueError):proof.validate(ROOT,r)


if __name__=='__main__':unittest.main()
