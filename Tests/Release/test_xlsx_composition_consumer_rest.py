"""Keine Umwertung direkter Aufrufe in providerfreie Consumer-/Rechtequalifikation."""
from pathlib import Path
import json
import sys
import unittest

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'Scripts/Release'))
import validate_xlsx_composition_consumer_rest as proof


class XlsxCompositionConsumerRestTests(unittest.TestCase):
    def record(self):return json.loads((ROOT/proof.REPORT).read_bytes())
    def test_original_execution_and_reused_artifacts_are_bound(self):
        self.assertEqual(proof.validate(ROOT)['status'],'PASS_FOR_DECLARED_SCOPE')

    def test_missing_consumer_or_original_helper_is_rejected(self):
        for kind in ('helper','provider-free','nullability','confirm0','collation'):
            r=self.record();g=r['cases'][0]['composition_groups'][1]
            if kind=='helper':g['consumer_helpers'].pop()
            elif kind=='provider-free':g['provider_free_witnesses']=1
            elif kind=='nullability':g['nullability']=0
            elif kind=='confirm0':g['confirm0']=0
            else:r['cases'][0]['consumer_collation']='Latin1_General_100_CI_AS_SC'
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
        for kind in ('failure','source','pin','fixture','bounds','history'):
            r=self.record()
            if kind=='failure':r['native_failures']=['invented']
            elif kind=='source':r['method']['source_sha256']['Tests/CI/run-xlsx-types-lab.ps1']='0'*64
            elif kind=='pin':r['method']['source_sha256'].pop('Tests/Release/Xlsx.OwnedDatabase.ps1')
            elif kind=='fixture':r['fixture_source_sha256']['Modules/toolbelt.file.xlsx-memory/Tests/Runtime/Types.Composition.xlsx']='0'*64
            elif kind=='bounds':r['bounds']['dispatches']=22
            else:r['green_replay']=True
            with self.subTest(kind=kind),self.assertRaises(ValueError):proof.validate(ROOT,r)

    def test_real_rights_or_whole_module_upgrade_is_rejected(self):
        for key,value in [('status','PASS'),('rights_granted',True),('not_claimed',[])]:
            r=self.record();r[key]=value
            with self.subTest(key=key),self.assertRaises(ValueError):proof.validate(ROOT,r)


if __name__=='__main__':unittest.main()
