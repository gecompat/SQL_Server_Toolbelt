"""Fehlende Orakel, Green-Replay, falsche Quellen und Auditaufwertung abweisen."""
from pathlib import Path
import copy
import json
import shutil
import subprocess
import sys
import unittest

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'Scripts/Release'))
import validate_xlsx_cell_api_rest as proof


class XlsxCellApiRestTests(unittest.TestCase):
    def record(self):return json.loads((ROOT/proof.REPORT).read_bytes())

    def test_original_execution_remains_valid(self):
        self.assertEqual(proof.validate(ROOT)['status'],'PASS_FOR_DECLARED_SCOPE')

    def test_missing_failed_or_duplicate_context_is_rejected(self):
        for kind in ('missing','duplicate','failed','audit','replay-local','fixture'):
            r=self.record()
            if kind=='missing':r['cases'].pop()
            elif kind=='duplicate':r['cases'][1]=copy.deepcopy(r['cases'][0])
            elif kind=='failed':r['cases'][0]['state']='FAILED_CLEANED'
            elif kind=='audit':r['cases'][0]['audit']='NOT_EXECUTED'
            elif kind=='replay-local':r['cases'][-1]['modes']=['local','central']
            else:r['cases'][0]['fixtures'].pop()
            with self.subTest(kind=kind),self.assertRaises(ValueError):proof.validate(ROOT,r)

    def test_original_method_drift_and_missing_dependency_are_rejected(self):
        for kind in ('hash','missing'):
            r=self.record();pins=r['methods'][0]['source_sha256']
            name='Tests/Release/Xlsx.CellApi.Workload.ps1'
            if kind=='hash':pins[name]='0'*64
            else:del pins[name]
            with self.subTest(kind=kind),self.assertRaises(ValueError):proof.validate(ROOT,r)

    def test_scope_upgrade_and_lost_controller_error_are_rejected(self):
        for key,value in [('rights_granted',True),('status','PASS'),('controller_history',[]),('not_claimed',[])]:
            r=self.record();r[key]=value
            with self.subTest(key=key),self.assertRaises(ValueError):proof.validate(ROOT,r)

    def test_real_sql_free_workload_admission(self):
        shell=shutil.which('pwsh')
        if not shell:self.skipTest('PowerShell unavailable; admission remains required on Windows')
        result=subprocess.run([shell,'-NoProfile','-File',str(ROOT/'Tests/Release/Test-XlsxCellApiWorkload.ps1')],cwd=ROOT,capture_output=True,text=True,timeout=30)
        self.assertEqual(result.returncode,0,result.stdout+result.stderr)
        self.assertIn('negative counterexamples',result.stdout)


if __name__=='__main__':unittest.main()
