"""Echte vollständige Matrix, unveränderte Originalpins und negative Scopeprüfungen."""
import json
from pathlib import Path
import sys
import unittest
from unittest import mock

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'Scripts/Release'))
import validate_xlsx_native_package as qualification


class XlsxNativeQualificationTests(unittest.TestCase):
    def record(self):return json.loads((ROOT/qualification.REPORT).read_bytes())

    def test_exact_completed_scope(self):
        result=qualification.validate(ROOT)
        self.assertEqual(result['status'],'PASS_FOR_DECLARED_SCOPE')

    def test_missing_or_failed_context_rejected(self):
        for mode in ('missing','failed','audit','lifecycle'):
            record=self.record()
            if mode=='missing':record['native']['cases'].pop()
            elif mode=='failed':record['native']['cases'][0]['state']='FAILED_CLEANED'
            elif mode=='audit':record['native']['cases'][0]['audit']='NOT_EXECUTED'
            else:record['native']['cases'][0]['lifecycle']['Repeat']=0
            with self.assertRaises(ValueError):qualification.validate(ROOT,record)

    def test_failed_history_cannot_be_upgraded(self):
        for key in ('pre_sql_rejection','metadata_oracle_failure','intentional_state_diagnostic'):
            record=self.record();record['history'][key]['state']='COMPLETE'
            with self.assertRaises(ValueError):qualification.validate(ROOT,record)

    def test_original_method_and_binary_are_bound(self):
        record=self.record();record['method']['source_sha256']['Tests/Release/Invoke-XlsxFullSizeLab.ps1']='0'*64
        with self.assertRaises(ValueError):qualification.validate(ROOT,record)
        record=self.record();record['package']['sha256']='0'*64
        with self.assertRaises(ValueError):qualification.validate(ROOT,record)

    def test_false_totals_and_broader_claim_rejected(self):
        for key,value in (('publication_authorized',True),('status','FULLY_QUALIFIED')):
            record=self.record();record[key]=value
            with self.assertRaises(ValueError):qualification.validate(ROOT,record)
        record=self.record();record['native']['rows_before_error']=1
        with self.assertRaises(ValueError):qualification.validate(ROOT,record)

    def test_future_product_change_does_not_rewrite_original_execution(self):
        current=qualification.package.source_files()
        name=next(iter(current));current[name]+=b'\n-- synthetic future source delta\n'
        with mock.patch.object(qualification.package,'source_files',return_value=current):
            result=qualification.validate(ROOT)
        self.assertEqual(result['status'],'PASS_FOR_DECLARED_SCOPE')
        self.assertFalse(result['current_product_source_match'])


if __name__=='__main__':unittest.main()
