"""Keine fehlenden Reader, erneuten grünen Profile oder verlorenen Fehlaudits."""
from pathlib import Path
import json
import sys
import unittest
from unittest import mock

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'Scripts/Release'))
import validate_xlsx_cell_client_rest as proof


class XlsxCellClientRestTests(unittest.TestCase):
    def record(self):return json.loads((ROOT/proof.REPORT).read_bytes())

    def test_exact_original_client_scope(self):
        self.assertEqual(proof.validate(ROOT)['status'],'PASS_FOR_DECLARED_SCOPE')

    def test_future_product_delta_keeps_original_execution_but_loses_applicability(self):
        current=proof.native.package.source_files()
        name=next(iter(current));current[name]+=b'\n-- synthetic future source delta'
        with mock.patch.object(proof.native.package,'source_files',return_value=current):
            result=proof.validate(ROOT)
        self.assertEqual(result['status'],'PASS_FOR_DECLARED_SCOPE')
        self.assertFalse(result['current_product_source_match'])

    def test_lost_case_audit_or_reader_is_rejected(self):
        for kind in ('missing','audit','helper','replay'):
            r=self.record()
            if kind=='missing':r['cases'].pop()
            elif kind=='audit':r['cases'][0]['audit']='NOT_EXECUTED'
            elif kind=='helper':r['cases'][0]['helpers'].pop()
            else:r['cases'][-1]['modes']=['local','central']
            with self.subTest(kind=kind),self.assertRaises(ValueError):proof.validate(ROOT,r)

    def test_failed_scope_cannot_become_pass(self):
        for field,value in [('state','PASS'),('completed_helpers',1),('audit','NOT_EXECUTED')]:
            r=self.record();r['history'][field]=value
            with self.subTest(field=field),self.assertRaises(ValueError):proof.validate(ROOT,r)

    def test_original_helper_or_budget_tamper_is_rejected(self):
        for kind in ('source','budget','claim'):
            r=self.record()
            if kind=='source':r['methods'][1]['source_sha256']['Tests/Release/Xlsx.CellApi.Workload.ps1']='0'*64
            elif kind=='budget':r['bounds']['native_closed']=False
            else:r['not_claimed']=[]
            with self.subTest(kind=kind),self.assertRaises(ValueError):proof.validate(ROOT,r)


if __name__=='__main__':unittest.main()
