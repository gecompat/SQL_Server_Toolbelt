"""Standalone admission for the single unexecuted central context; no SQL."""
from pathlib import Path
import copy,hashlib,json,shutil,subprocess,unittest
import test_json_schema_dependency_signature_lab_contract as base
ROOT=base.ROOT
DRIVER=ROOT/'Tests/Release/Invoke-JsonSchemaCentralRestLab.ps1'
@unittest.skipUnless(shutil.which('pwsh'),'PowerShell 7 required')
class CentralRemainderAdmissionTests(unittest.TestCase):
    def setUp(self):
        base.JsonSchemaGuardAdmissionTests.setUp(self)
        self.record['schema_version']='json-schema-dependency-signature-central-rest/v1'
        self.record['central_rest_authority']=dict(approved=True,maximumCalls=2,maximumDatabases=1,maximumMinutes=45)
        self.record['pins'].append(dict(path=str(DRIVER),sha256=hashlib.sha256(DRIVER.read_bytes()).hexdigest().upper()))
    def tearDown(self):self.temp.cleanup()
    def admission(self,r=None,index=0):
        p=self.directory/'central-rest.json';p.write_text(json.dumps(r or self.record),encoding='utf-8')
        result=subprocess.run(['pwsh','-NoProfile','-File',str(DRIVER),'-RunsetPath',str(p),'-CaseIndex',str(index),'-ValidateOnly'],cwd=ROOT,capture_output=True,text=True,timeout=25)
        self.assertEqual(list(self.directory.glob('case-*')),[])
        return result
    def reject(self,mutate):
        r=copy.deepcopy(self.record);mutate(r);v=self.admission(r);self.assertNotEqual(v.returncode,0,v.stdout+v.stderr)
    def test_valid_central_scope_without_lab_or_sql(self):
        r=self.admission();self.assertEqual(r.returncode,0,r.stdout+r.stderr);self.assertIn('CENTRAL_ONLY_OFFLINE',r.stdout)
    def test_explicit_typed_and_finite_authority(self):
        for value in (False,'true'):
            self.reject(lambda r:r['central_rest_authority'].update(approved=value))
        for field,value in [('maximumCalls',3),('maximumDatabases',2),('maximumMinutes',46)]:
            self.reject(lambda r:r['central_rest_authority'].__setitem__(field,value))
        self.reject(lambda r:r.pop('central_rest_authority'))
    def test_no_other_target_or_partial_tail(self):
        self.assertNotEqual(self.admission(index=1).returncode,0)
        self.reject(lambda r:r['cases'][0].update(CL=160))
        self.reject(lambda r:r.update(partial_tail={}))
    def test_audit_cannot_promote_central_to_full_pair(self):
        text=DRIVER.read_text(encoding='utf-8-sig')
        self.assertIn("$case.modes=@('central')",text)
        self.assertIn("$prior.profileCompletions.Count-eq46",text)
        self.assertIn("$prior.witnesses.Count-eq1",text)
        self.assertIn("WINDOWS2019_CL150_CENTRAL_ONLY",text)
if __name__=='__main__':unittest.main()
