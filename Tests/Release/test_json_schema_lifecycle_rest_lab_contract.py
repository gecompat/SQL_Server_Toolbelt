"""Admission and exact profile oracles for five remaining Schema matrices."""
from pathlib import Path
from datetime import datetime,timedelta,timezone
import copy,hashlib,json,shutil,subprocess,tempfile,unittest,zipfile
ROOT=Path(__file__).resolve().parents[2]
DRIVER=ROOT/'Tests/Release/Invoke-JsonSchemaLifecycleRestLab.ps1'
Q=ROOT/'Releases/1.0.0/JSON-SCHEMA-PACKAGE-QUALIFICATION.json'
@unittest.skipUnless(shutil.which('pwsh'),'PowerShell 7 required')
class JsonSchemaRestAdmissionTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory(prefix='json-session-admission-',dir=ROOT/'.runtime')
        self.directory=Path(self.temp.name);q=json.loads(Q.read_bytes());package=ROOT/q['package']['path']
        with zipfile.ZipFile(package) as z:
            bits=z.read('SQL-Server-Toolbelt-1.0.0-CLR-Install/Binaries/Toolbelt.JsonSchema.dll')
        binary=self.directory/'qualified.dll';binary.write_bytes(bits)
        with zipfile.ZipFile(package) as z:corebits=z.read('SQL-Server-Toolbelt-1.0.0-CLR-Install/Binaries/Toolbelt.JsonCore.dll')
        corebinary=self.directory/'core.dll';corebinary.write_bytes(corebits)
        # Dieselben kanonischen Include-/Variablenfunktionen wie im echten Preflight.
        def quote(p):return "'"+str(p).replace("'","''")+"'"
        script="$ErrorActionPreference='Stop';$repo="+quote(ROOT)+";$destination="+quote(self.directory)+";$binary="+quote(binary)+';$coreBinary='+quote(corebinary)+r"""
$e=$null;$a=[Management.Automation.Language.Parser]::ParseFile((Join-Path $repo 'Deployment/Deploy-All.ps1'),[ref]$null,[ref]$e)
if($e.Count){throw 'TEST_CANONICAL_PARSE'}
foreach($name in @('Get-SqlcmdScriptTree','ConvertTo-StandaloneSql')){
 $n=@($a.FindAll({param($x)$x-is[Management.Automation.Language.FunctionDefinitionAst]-and$x.Name-ceq$name},$true));if($n.Count-ne1){throw 'TEST_FUNCTION'};. ([scriptblock]::Create($n[0].Extent.Text))
}
$paths=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
function Add-Node($n){[void]$paths.Add($n.Path);foreach($c in $n.Children){Add-Node $c}}

foreach($mode in @('local','central')){
 $tree=Get-SqlcmdScriptTree -Path (Join-Path $repo 'Modules/toolbelt.json.schema/Deployment/Deploy.sql');Add-Node $tree
 $text=ConvertTo-StandaloneSql -Node $tree -Values @{DeploymentMode=$mode;AssemblyBits=('0x'+[Convert]::ToHexString([IO.File]::ReadAllBytes($binary)))} -ModulesRoot (Join-Path $repo 'Modules')
 [IO.File]::WriteAllText((Join-Path $destination ($mode+'.sql')),$text,[Text.UTF8Encoding]::new($false))
}
$tree=Get-SqlcmdScriptTree -Path (Join-Path $repo 'Modules/toolbelt.json.schema/Deployment/Uninstall.sql');Add-Node $tree
$text=ConvertTo-StandaloneSql -Node $tree -Values @{ConfirmNoExternalConsumers='1'} -ModulesRoot (Join-Path $repo 'Modules')
[IO.File]::WriteAllText((Join-Path $destination 'uninstall.sql'),$text,[Text.UTF8Encoding]::new($false))
$baselines=@{}
foreach($mode in @('local','central')){
 $parts=@()
 foreach($dependency in @('toolbelt.core.result-table','toolbelt.json.core')){
  $tree=Get-SqlcmdScriptTree -Path (Join-Path $repo ('Modules/'+$dependency+'/Deployment/Deploy.sql'));Add-Node $tree
  $parts+=@(ConvertTo-StandaloneSql -Node $tree -Values @{DeploymentMode=$mode;AssemblyBits=('0x'+[Convert]::ToHexString(([IO.File]::ReadAllBytes($coreBinary))))} -ModulesRoot (Join-Path $repo 'Modules'))
 }
 $path=Join-Path $destination ('baseline.'+$mode+'.private.sql');[IO.File]::WriteAllText($path,($parts-join"`nGO`n"),[Text.UTF8Encoding]::new($false));$baselines[$mode]=$path
}


[IO.File]::WriteAllText((Join-Path $destination 'nodes.json'),(@($paths)|ConvertTo-Json),[Text.UTF8Encoding]::new($false))
"""
        result=subprocess.run(['pwsh','-NoProfile','-Command',script],cwd=ROOT,capture_output=True,text=True,timeout=20)
        self.assertEqual(result.returncode,0,result.stdout+result.stderr)
        fixture=ROOT/'Tests/Release/Runtime/JsonSchema.LifecycleRest.Contract.ps1'
        exports={mode:str(self.directory/(mode+'.sql')) for mode in ('local','central')};uninstall=self.directory/'uninstall.sql'
        files=[DRIVER,Q,package,binary,corebinary,fixture,uninstall, self.directory/'baseline.local.private.sql',self.directory/'baseline.central.private.sql',ROOT/'Releases/1.0.0/json-schema-deploy-collision-qualification.json',ROOT/'Releases/1.0.0/json-schema-deploy-lock-qualification.json',ROOT/'Releases/1.0.0/json-schema-uninstall-lock-qualification.json',ROOT/'Releases/1.0.0/json-schema-caller-transaction-qualification.json',*(Path(p) for p in exports.values()),
               *(Path(p) for p in json.loads((self.directory/'nodes.json').read_bytes())),
               *(ROOT/p for p in ('Deployment/Deploy-All.ps1','Tests/Release/Invoke-JsonSchemaAppLockLab.ps1',
                 'Tests/Release/Invoke-JsonSchemaCallerTransactionLab.ps1','Tests/Release/Invoke-ApiQualificationLab.ps1',
                 'Tests/Release/Invoke-StablePackageLab.ps1','Tests/CI/run-lab-local.ps1','Tests/CI/LabQualifiedContract.ps1'))]
        registry=ROOT/'Modules/toolbelt.json.core/Documentation/KNOWN_JSON_ARTIFACT_CLOSURE.json'
        files += [registry,ROOT/'Tests/Release/ClrCaller.Environment.ps1',ROOT/'Tests/CI/run-csv-memory-lab.ps1',ROOT/'Tests/Release/Invoke-JsonSchemaUninstallAppLockLab.ps1']
        for row in json.loads(registry.read_bytes())['artifacts']:
            f=row['Fields']
            if f['moduleId'] in ('toolbelt.json.core','toolbelt.json.schema'):
                folder=ROOT/'Modules'/f['moduleId']/'Clr'
                files += [folder/(f['managedAssembly']+'.csproj')]+[folder/key[7:] for key in f if key.startswith('source/')]
        cases=[dict(Platform=p,Version=v,Patch=('latest' if p=='linux' else {'2019':'CU32','2022':'CU26','2025':'CU8'}[v]),CL=cl,modes=['local','central']) for p in ('windows','linux') for v in ('2019','2022','2025') for cl in {'2019':[150],'2022':[150,160],'2025':[150,160,170]}[v]]
        files += [ROOT/'Tests/Release/Runtime/JsonCore.Lock.Contract.ps1'];files=list(dict.fromkeys(files));started=datetime.now(timezone.utc)-timedelta(seconds=5)
        reuse=[]
        flags={k:True for k in ('blocked','exact_error','transaction_preserved','session_preserved','options_preserved','module_snapshot_preserved','witness_preserved','application_locks_absent')}
        for name,profiles in [('missing-nocount',[(0,1,'deploy'),(0,1,'uninstall')]),('missing-xact',[(x,n,o) for x in (1,) for n in (0,1) for o in ('deploy','uninstall')]),('installed',[(0,1,'uninstall'),(1,0,'uninstall'),(1,1,'uninstall')])]:
            j=self.directory/(name+'.json');a=self.directory/(name+'.audit.json');inp=self.directory/(name+'.inputs.json')
            j.write_text(json.dumps(dict(state='COMPLETE',failure=None,results=[dict(flags,xact_abort=bool(x),nocount=bool(n),operation=o) for x,n,o in profiles])),encoding='utf-8')
            a.write_text(json.dumps(dict(state='COMPLETE',originalRunPassed=True,originalJournalSHA256=hashlib.sha256(j.read_bytes()).hexdigest().upper(),databaseAbsence=True,serverConfigurationAndTrustUnchanged=True,postPins=True)),encoding='utf-8')
            inp.write_text(json.dumps(dict(cases=[dict(Platform='windows',Version='2025',Patch='CU8',CL=170,modes=['local'])],pins=[dict(path=str(ROOT/p),sha256=hashlib.sha256((ROOT/p).read_bytes()).hexdigest().upper()) for p in ('Modules/toolbelt.json.schema/Deployment/Deploy.sql','Modules/toolbelt.json.schema/Deployment/Uninstall.sql','Modules/toolbelt.json.schema/Source/JsonSchemaBridge.sql','Modules/toolbelt.json.schema/Source/USP_ValidateJsonSchema.sql')])),encoding='utf-8')
            reuse.append(dict(id=name,**{k:dict(path=str(p),sha256=hashlib.sha256(p.read_bytes()).hexdigest().upper()) for k,p in [('journal',j),('audit',a),('inputs',inp)]}));files += [j,a,inp]
        self.record=dict(schema_version='json-schema-lifecycle-rest/v1',explicit_qualification_approved=True,
            started_utc=started.isoformat(),deadline_utc=(started+timedelta(minutes=45)).isoformat(),
            cases=cases,reuse=reuse,fixtures=[str(fixture)],
            exports=exports,uninstall=str(uninstall),artifact=dict(path=str(binary)),core_artifact=dict(path=str(corebinary)),baselines={m:str(self.directory/('baseline.'+m+'.private.sql')) for m in ('local','central')},provenance=str(Q),package=str(package),
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
        path=str(ROOT/'Modules/toolbelt.json.schema/Deployment/Deploy.sql')
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

    def test_reuse_requires_complete_original_audit_and_no_duplicates(self):
        self.reject(lambda r:r['reuse'].pop())
        self.reject(lambda r:r['reuse'][0].update(id='unknown'))
        self.reject(lambda r:r['reuse'].__setitem__(0,r['reuse'][1]))
        p=Path(self.record['reuse'][0]['audit']['path']);a=json.loads(p.read_bytes());a['originalRunPassed']=False;p.write_text(json.dumps(a),encoding='utf-8')
        r=copy.deepcopy(self.record);h=hashlib.sha256(p.read_bytes()).hexdigest().upper();r['reuse'][0]['audit']['sha256']=h;next(x for x in r['pins'] if x['path']==str(p))['sha256']=h
        self.assertNotEqual(self.admission(r).returncode,0)
    def test_truncated_dependency_export_rejected_despite_repin(self):
        p=Path(self.record['baselines']['local']);p.write_text('SELECT 1;',encoding='utf-8')
        r=copy.deepcopy(self.record);next(x for x in r['pins'] if x['path']==str(p))['sha256']=hashlib.sha256(p.read_bytes()).hexdigest().upper()
        self.assertNotEqual(self.admission(r).returncode,0)
    def test_exact_five_point_coverage_and_error_oracles(self):
        fixture=ROOT/'Tests/Release/Runtime/JsonSchema.LifecycleRest.Contract.ps1'
        script="$ErrorActionPreference='Stop';$path='"+str(fixture).replace("'","''")+"';"+r"""
$e=$null;$a=[Management.Automation.Language.Parser]::ParseFile($path,[ref]$null,[ref]$e)
foreach($name in @('Get-SchemaRestKeys','Test-SchemaRestCoverage','Test-SchemaRestError')){
 $n=@($a.FindAll({param($x)$x-is[Management.Automation.Language.FunctionDefinitionAst]-and$x.Name-ceq$name},$true));if($e.Count-or$n.Count-ne1){throw 'FUNCTION_SOURCE'};. ([scriptblock]::Create($n[0].Extent.Text))
}
$rows=@(foreach($mode in @('local','central')){foreach($id in Get-SchemaRestKeys $mode){[pscustomobject]@{mode=$mode;id=$id;passed=$true}}})
if($rows.Count-ne56-or-not(Test-SchemaRestCoverage $rows)){throw 'COVERAGE_GOLDEN'}
if(Test-SchemaRestCoverage @($rows[1..55])){throw 'MISSING_PROFILE_ACCEPTED'}
if(Test-SchemaRestCoverage @($rows+$rows[0])){throw 'DUPLICATE_PROFILE_ACCEPTED'}
$excluded=@($rows|Where-Object{$_.mode-ceq'local'-and$_.id-cmatch'^caller-missing/'}|ForEach-Object{$_.mode+'/'+$_.id})
$tail=@($rows|Where-Object{($_.mode+'/'+$_.id)-cnotin$excluded})
if($tail.Count-ne48-or-not(Test-SchemaRestCoverage $tail $excluded)){throw 'DECLARED_TAIL_COVERAGE'}
if(Test-SchemaRestCoverage $tail){throw 'TAIL_PROMOTED_TO_FULL_PAIR'}
if(Test-SchemaRestCoverage $rows $excluded){throw 'GREEN_PREFIX_REPEATED'}
if(Test-SchemaRestCoverage $tail @('unknown')){throw 'UNKNOWN_REUSE_ACCEPTED'}
if(Test-SchemaRestCoverage $tail @($excluded+$excluded)){throw 'DUPLICATE_REUSE_ACCEPTED'}
$rows[0].passed=$false;if(Test-SchemaRestCoverage $rows){throw 'FAILED_PROFILE_ACCEPTED'}
$good=[pscustomobject]@{Number=55623;State=1;Class=16;Message='Contoso exact error'}
if(-not(Test-SchemaRestError @($good) 55623 'Contoso exact error')){throw 'ERROR_GOLDEN'}
foreach($field in @('Number','State','Class','Message')){
 $row=[pscustomobject]@{Number=55623;State=1;Class=16;Message='Contoso exact error'};$row.$field=if($field-ceq'Message'){'wrong'}else{99}
 if(Test-SchemaRestError @($row) 55623 'Contoso exact error'){throw 'WRONG_ERROR_ACCEPTED'}
}
if(Test-SchemaRestError @($good,$good) 55623 'Contoso exact error'){throw 'DUPLICATE_ERROR_ACCEPTED'}
'FIVE_POINT_ORACLES_PASS'
"""
        result=subprocess.run(['pwsh','-NoProfile','-Command',script],cwd=ROOT,capture_output=True,text=True,timeout=20)
        self.assertEqual(result.returncode,0,result.stdout+result.stderr)
if __name__=='__main__':unittest.main()
