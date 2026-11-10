"""Zulassung des begrenzten Sessionprofils ohne Labimport oder SQL."""
from pathlib import Path
from datetime import datetime,timedelta,timezone
import copy,hashlib,json,shutil,subprocess,tempfile,unittest,zipfile
ROOT=Path(__file__).resolve().parents[2]
DRIVER=ROOT/'Tests/Release/Invoke-JsonCoreBoundariesLab.ps1'
Q=ROOT/'Releases/1.0.0/JSON-SCHEMA-PACKAGE-QUALIFICATION.json'
@unittest.skipUnless(shutil.which('pwsh'),'PowerShell 7 required')
class JsonCoreBoundaryAdmissionTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory(prefix='json-session-admission-',dir=ROOT/'.runtime')
        self.directory=Path(self.temp.name);q=json.loads(Q.read_bytes());package=ROOT/q['package']['path']
        with zipfile.ZipFile(package) as z:
            bits=z.read('SQL-Server-Toolbelt-1.0.0-CLR-Install/Binaries/Toolbelt.JsonCore.dll')
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

foreach($mode in @('local','central')){
 $tree=Get-SqlcmdScriptTree -Path (Join-Path $repo 'Modules/toolbelt.json.core/Deployment/Deploy.sql');Add-Node $tree
 $text=ConvertTo-StandaloneSql -Node $tree -Values @{DeploymentMode=$mode;AssemblyBits=('0x'+[Convert]::ToHexString([IO.File]::ReadAllBytes($binary)))} -ModulesRoot (Join-Path $repo 'Modules')
 [IO.File]::WriteAllText((Join-Path $destination ($mode+'.sql')),$text,[Text.UTF8Encoding]::new($false))
}
$tree=Get-SqlcmdScriptTree -Path (Join-Path $repo 'Modules/toolbelt.json.core/Deployment/Uninstall.sql');Add-Node $tree
$text=ConvertTo-StandaloneSql -Node $tree -Values @{ConfirmNoExternalConsumers='1'} -ModulesRoot (Join-Path $repo 'Modules')
[IO.File]::WriteAllText((Join-Path $destination 'uninstall.sql'),$text,[Text.UTF8Encoding]::new($false))
$arguments=@()
foreach($spec in @(@{id='mode-upper';operation='deploy';variable='DeploymentMode';value='LOCAL'},@{id='mode-space';operation='deploy';variable='DeploymentMode';value=' local '},@{id='confirm-invalid';operation='uninstall';variable='ConfirmNoExternalConsumers';value='2'},@{id='confirm-space';operation='uninstall';variable='ConfirmNoExternalConsumers';value=' 1'},@{id='central-unconfirmed';operation='uninstall';variable='ConfirmNoExternalConsumers';value='0'})){
 $name=if($spec.operation-ceq'deploy'){'Deploy.sql'}else{'Uninstall.sql'};$tree=Get-SqlcmdScriptTree -Path (Join-Path $repo ('Modules/toolbelt.json.core/Deployment/'+$name));Add-Node $tree
 $values=@{};$values[$spec.variable]=$spec.value;if($spec.operation-ceq'deploy'){$values['AssemblyBits']='0x'+[Convert]::ToHexString([IO.File]::ReadAllBytes($binary))}
 $text=ConvertTo-StandaloneSql -Node $tree -Values $values -ModulesRoot (Join-Path $repo 'Modules');$path=Join-Path $destination ($spec.id+'.sql');[IO.File]::WriteAllText($path,$text,[Text.UTF8Encoding]::new($false))
 $arguments+=@(@{id=$spec.id;operation=$spec.operation;value=$spec.value;path=$path})
}
[IO.File]::WriteAllText((Join-Path $destination 'arguments.json'),($arguments|ConvertTo-Json),[Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllText((Join-Path $destination 'nodes.json'),(@($paths)|ConvertTo-Json),[Text.UTF8Encoding]::new($false))
"""
        result=subprocess.run(['pwsh','-NoProfile','-Command',script],cwd=ROOT,capture_output=True,text=True,timeout=20)
        self.assertEqual(result.returncode,0,result.stdout+result.stderr)
        fixture=ROOT/'Tests/Release/Runtime/JsonCore.Boundaries.Contract.ps1'
        exports={mode:str(self.directory/(mode+'.sql')) for mode in ('local','central')};uninstall=self.directory/'uninstall.sql'
        files=[DRIVER,Q,package,binary,fixture,uninstall,*(Path(p) for p in exports.values()),
               *(Path(p) for p in json.loads((self.directory/'nodes.json').read_bytes())),
               *(ROOT/p for p in ('Deployment/Deploy-All.ps1','Tests/Release/Invoke-JsonSchemaAppLockLab.ps1',
                 'Tests/Release/Invoke-JsonSchemaCallerTransactionLab.ps1','Tests/Release/Invoke-ApiQualificationLab.ps1',
                 'Tests/Release/Invoke-StablePackageLab.ps1','Tests/CI/run-lab-local.ps1','Tests/CI/LabQualifiedContract.ps1'))]
        registry=ROOT/'Modules/toolbelt.json.core/Documentation/KNOWN_JSON_ARTIFACT_CLOSURE.json'
        files += [registry,ROOT/'Tests/Release/ClrCaller.Environment.ps1',ROOT/'Tests/CI/run-csv-memory-lab.ps1',ROOT/'Tests/Release/Invoke-JsonSchemaUninstallAppLockLab.ps1']
        for row in json.loads(registry.read_bytes())['artifacts']:
            f=row['Fields']
            if f['moduleId']=='toolbelt.json.core':
                folder=ROOT/'Modules'/f['moduleId']/'Clr'
                files += [folder/(f['managedAssembly']+'.csproj')]+[folder/key[7:] for key in f if key.startswith('source/')]
        cases=[dict(Platform=p,Version=v,Patch=('latest' if p=='linux' else {'2019':'CU32','2022':'CU26','2025':'CU8'}[v]),CL=cl,modes=['local','central']) for p in ('windows','linux') for v in ('2019','2022','2025') for cl in {'2019':[150],'2022':[150,160],'2025':[150,160,170]}[v]]
        arguments=json.loads((self.directory/'arguments.json').read_bytes());files += [Path(a['path']) for a in arguments]+[ROOT/'Tests/Release/Runtime/JsonCore.Lock.Contract.ps1'];files=list(dict.fromkeys(files));started=datetime.now(timezone.utc)-timedelta(seconds=5)
        self.record=dict(schema_version='json-core-five-boundaries/v1',explicit_qualification_approved=True,
            started_utc=started.isoformat(),deadline_utc=(started+timedelta(minutes=45)).isoformat(),
            cases=cases,argument_scripts=arguments,fixtures=[str(fixture)],
            exports=exports,uninstall=str(uninstall),artifact=dict(path=str(binary)),provenance=str(Q),package=str(package),
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
        path=str(ROOT/'Modules/toolbelt.json.core/Deployment/Deploy.sql')
        self.reject(lambda r:r.update(pins=[p for p in r['pins'] if p['path']!=path]))
    def test_repinning_truncated_public_script_rejected(self):
        p=Path(self.record['exports']['local']);p.write_text('SELECT 1;',encoding='utf-8')
        r=copy.deepcopy(self.record)
        next(x for x in r['pins'] if x['path']==str(p))['sha256']=hashlib.sha256(p.read_bytes()).hexdigest().upper()
        self.assertNotEqual(self.admission(r).returncode,0)
    def test_repinning_wrong_binary_rejected(self):
        p=Path(self.record['artifact']['path']);p.write_bytes(b'unqualified')
        r=copy.deepcopy(self.record);next(x for x in r['pins'] if x['path']==str(p))['sha256']=hashlib.sha256(p.read_bytes()).hexdigest().upper()
        self.assertNotEqual(self.admission(r).returncode,0)

    def test_argument_scripts_cannot_be_swapped_or_rewritten(self):
        self.reject(lambda r:r['argument_scripts'][0].update(value='local'))
        self.reject(lambda r:r['argument_scripts'].pop())
        path=Path(self.record['argument_scripts'][0]['path']);path.write_text('SELECT 1;',encoding='utf-8')
        r=copy.deepcopy(self.record);next(p for p in r['pins'] if p['path']==str(path))['sha256']=hashlib.sha256(path.read_bytes()).hexdigest().upper()
        self.assertNotEqual(self.admission(r).returncode,0)
    def test_exact_five_point_coverage_and_error_oracles(self):
        fixture=ROOT/'Tests/Release/Runtime/JsonCore.Boundaries.Contract.ps1'
        script="$ErrorActionPreference='Stop';$path='"+str(fixture).replace("'","''")+"';"+r"""
$e=$null;$a=[Management.Automation.Language.Parser]::ParseFile($path,[ref]$null,[ref]$e)
foreach($name in @('Get-CoreBoundaryKeys','Test-CoreBoundaryCoverage','Test-CoreBoundaryError')){
 $n=@($a.FindAll({param($x)$x-is[Management.Automation.Language.FunctionDefinitionAst]-and$x.Name-ceq$name},$true));if($e.Count-or$n.Count-ne1){throw 'FUNCTION_SOURCE'};. ([scriptblock]::Create($n[0].Extent.Text))
}
$rows=@(foreach($mode in @('local','central')){foreach($id in Get-CoreBoundaryKeys $mode){[pscustomobject]@{mode=$mode;id=$id;passed=$true}}})
if($rows.Count-ne73-or-not(Test-CoreBoundaryCoverage $rows)){throw 'COVERAGE_GOLDEN'}
if(Test-CoreBoundaryCoverage @($rows[1..72])){throw 'MISSING_PROFILE_ACCEPTED'}
if(Test-CoreBoundaryCoverage @($rows+$rows[0])){throw 'DUPLICATE_PROFILE_ACCEPTED'}
$rows[0].passed=$false;if(Test-CoreBoundaryCoverage $rows){throw 'FAILED_PROFILE_ACCEPTED'}
$good=[pscustomobject]@{Number=55623;State=1;Class=16;Message='Contoso exact error'}
if(-not(Test-CoreBoundaryError @($good) 55623 'Contoso exact error')){throw 'ERROR_GOLDEN'}
foreach($field in @('Number','State','Class','Message')){
 $row=[pscustomobject]@{Number=55623;State=1;Class=16;Message='Contoso exact error'};$row.$field=if($field-ceq'Message'){'wrong'}else{99}
 if(Test-CoreBoundaryError @($row) 55623 'Contoso exact error'){throw 'WRONG_ERROR_ACCEPTED'}
}
if(Test-CoreBoundaryError @($good,$good) 55623 'Contoso exact error'){throw 'DUPLICATE_ERROR_ACCEPTED'}
'FIVE_POINT_ORACLES_PASS'
"""
        result=subprocess.run(['pwsh','-NoProfile','-Command',script],cwd=ROOT,capture_output=True,text=True,timeout=20)
        self.assertEqual(result.returncode,0,result.stdout+result.stderr)
if __name__=='__main__':unittest.main()
