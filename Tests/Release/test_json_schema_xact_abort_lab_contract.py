"""Zulassung des begrenzten Sessionprofils ohne Labimport oder SQL."""
from pathlib import Path
from datetime import datetime,timedelta,timezone
import copy,hashlib,json,shutil,subprocess,tempfile,unittest,zipfile
ROOT=Path(__file__).resolve().parents[2]
DRIVER=ROOT/'Tests/Release/Invoke-JsonSchemaXactAbortLab.ps1'
Q=ROOT/'Releases/1.0.0/JSON-SCHEMA-PACKAGE-QUALIFICATION.json'
@unittest.skipUnless(shutil.which('pwsh'),'PowerShell 7 required')
class JsonSchemaSessionAdmissionTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory(prefix='json-session-admission-',dir=ROOT/'.runtime')
        self.directory=Path(self.temp.name);q=json.loads(Q.read_bytes());package=ROOT/q['package']['path']
        with zipfile.ZipFile(package) as z:
            bits=z.read('SQL-Server-Toolbelt-1.0.0-CLR-Install/Binaries/Toolbelt.JsonSchema.dll')
        binary=self.directory/'qualified.dll';binary.write_bytes(bits)
        # Dieselben kanonischen Include-/Variablenfunktionen wie im echten Preflight.
        def quote(p):return "'"+str(p).replace("'","''")+"'"
        script="$ErrorActionPreference='Stop';$repo="+quote(ROOT)+";$destination="+quote(self.directory)+";$binary="+quote(binary)+r"""
$e=$null;$a=[Management.Automation.Language.Parser]::ParseFile((Join-Path $repo 'Deployment/Deploy-All.ps1'),[ref]$null,[ref]$e)
if($e.Count){throw 'TEST_CANONICAL_PARSE'}
foreach($name in @('Get-SqlcmdScriptTree','ConvertTo-StandaloneSql')){
 $n=@($a.FindAll({param($x)$x-is[Management.Automation.Language.FunctionDefinitionAst]-and$x.Name-ceq$name},$true));if($n.Count-ne1){throw 'TEST_FUNCTION'};. ([scriptblock]::Create($n[0].Extent.Text))
}
$paths=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
function Add-Node($n){[void]$paths.Add($n.Path);foreach($c in $n.Children){Add-Node $c}}
foreach($op in @('deploy','uninstall')){
 $source=Join-Path $repo ('Modules/toolbelt.json.schema/Deployment/'+@{deploy='Deploy.sql';uninstall='Uninstall.sql'}[$op])
 $tree=Get-SqlcmdScriptTree -Path $source;Add-Node $tree
 $text=ConvertTo-StandaloneSql -Node $tree -Values @{DeploymentMode='local';AssemblyBits=('0x'+[Convert]::ToHexString([IO.File]::ReadAllBytes($binary)));ConfirmNoExternalConsumers='1'} -ModulesRoot (Join-Path $repo 'Modules')
 [IO.File]::WriteAllText((Join-Path $destination ($op+'.sql')),$text,[Text.UTF8Encoding]::new($false))
}
[IO.File]::WriteAllText((Join-Path $destination 'nodes.json'),(@($paths)|ConvertTo-Json),[Text.UTF8Encoding]::new($false))
"""
        result=subprocess.run(['pwsh','-NoProfile','-Command',script],cwd=ROOT,capture_output=True,text=True,timeout=20)
        self.assertEqual(result.returncode,0,result.stdout+result.stderr)
        fixture=ROOT/'Tests/Release/Runtime/JsonSchema.XactAbort.Contract.ps1'
        scripts={op:str(self.directory/(op+'.sql')) for op in ('deploy','uninstall')}
        files=[DRIVER,Q,package,binary,fixture,*(Path(p) for p in scripts.values()),
               *(Path(p) for p in json.loads((self.directory/'nodes.json').read_bytes())),
               *(ROOT/p for p in ('Deployment/Deploy-All.ps1','Tests/Release/Invoke-JsonSchemaAppLockLab.ps1',
                 'Tests/Release/Invoke-JsonSchemaCallerTransactionLab.ps1','Tests/Release/Invoke-ApiQualificationLab.ps1',
                 'Tests/Release/Invoke-StablePackageLab.ps1','Tests/CI/run-lab-local.ps1','Tests/CI/LabQualifiedContract.ps1'))]
        files=list(dict.fromkeys(files));started=datetime.now(timezone.utc)-timedelta(seconds=5)
        self.record=dict(schema_version='json-schema-xact-abort/v1',explicit_qualification_approved=True,
            started_utc=started.isoformat(),deadline_utc=(started+timedelta(minutes=45)).isoformat(),
            cases=[dict(Platform='windows',Version='2025',Patch='CU8',CL=170,modes=['local'])],fixtures=[str(fixture)],
            scripts=scripts,artifact=dict(path=str(binary)),provenance=str(Q),package=str(package),
            pins=[dict(path=str(p),sha256=hashlib.sha256(p.read_bytes()).hexdigest().upper()) for p in files])
    def tearDown(self):self.temp.cleanup()
    def admission(self,r=None):
        p=self.directory/'runset.json';p.write_text(json.dumps(r or self.record),encoding='utf-8')
        result=subprocess.run(['pwsh','-NoProfile','-File',str(DRIVER),'-RunsetPath',str(p),'-CaseIndex','0','-ValidateOnly'],cwd=ROOT,capture_output=True,text=True,timeout=25)
        self.assertEqual(list(self.directory.glob('case-*')),[])
        return result
    def reject(self,mutate):
        r=copy.deepcopy(self.record);mutate(r);v=self.admission(r);self.assertNotEqual(v.returncode,0,v.stdout+v.stderr)
    def test_valid_without_lab_or_sql(self):
        v=self.admission();self.assertEqual(v.returncode,0,v.stdout+v.stderr);self.assertIn('no Lab import or SQL',v.stdout)
    def test_authority_boolean(self):
        self.reject(lambda r:r.update(explicit_qualification_approved=False))
        self.reject(lambda r:r.update(explicit_qualification_approved='true'))
    def test_target_mode_and_count(self):
        self.reject(lambda r:r['cases'][0].update(Patch='base'))
        self.reject(lambda r:r['cases'][0].update(CL=160))
        self.reject(lambda r:r['cases'][0].update(modes=['central']))
        self.reject(lambda r:r['cases'].append(r['cases'][0]))
    def test_deadline_expired_or_extended(self):
        past=datetime.now(timezone.utc)-timedelta(hours=2)
        self.reject(lambda r:r.update(started_utc=past.isoformat(),deadline_utc=(past+timedelta(minutes=45)).isoformat()))
        self.reject(lambda r:r.update(deadline_utc=(datetime.now(timezone.utc)+timedelta(hours=2)).isoformat()))
    def test_required_method_and_include_pin(self):
        self.reject(lambda r:r['pins'].pop(0))
        path=str(ROOT/'Modules/toolbelt.json.schema/Deployment/State.sql')
        self.reject(lambda r:r.update(pins=[p for p in r['pins'] if p['path']!=path]))
    def test_repinning_truncated_public_script_rejected(self):
        p=Path(self.record['scripts']['deploy']);p.write_text('SELECT 1;',encoding='utf-8')
        r=copy.deepcopy(self.record)
        next(x for x in r['pins'] if x['path']==str(p))['sha256']=hashlib.sha256(p.read_bytes()).hexdigest().upper()
        self.assertNotEqual(self.admission(r).returncode,0)
    def test_repinning_wrong_binary_rejected(self):
        p=Path(self.record['artifact']['path']);p.write_bytes(b'unqualified')
        r=copy.deepcopy(self.record);next(x for x in r['pins'] if x['path']==str(p))['sha256']=hashlib.sha256(p.read_bytes()).hexdigest().upper()
        self.assertNotEqual(self.admission(r).returncode,0)
if __name__=='__main__':unittest.main()
