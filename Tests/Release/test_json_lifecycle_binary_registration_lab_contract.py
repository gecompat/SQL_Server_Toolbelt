"""Admission and exact profile oracles for five binary/registration/lower-compatibility matrices."""
from pathlib import Path
from datetime import datetime,timedelta,timezone
import copy,hashlib,json,shutil,subprocess,tempfile,unittest,zipfile
ROOT=Path(__file__).resolve().parents[2]
DRIVER=ROOT/'Tests/Release/Invoke-JsonLifecycleBinaryRegistrationLab.ps1'
Q=ROOT/'Releases/1.0.0/JSON-SCHEMA-PACKAGE-QUALIFICATION.json'
@unittest.skipUnless(shutil.which('pwsh'),'PowerShell 7 required')
class JsonLifecycleGuardAdmissionTests(unittest.TestCase):
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



$coreExports=@{}
foreach($mode in @('local','central')){
 $tree=Get-SqlcmdScriptTree -Path (Join-Path $repo 'Modules/toolbelt.json.core/Deployment/Deploy.sql');Add-Node $tree
 $text=ConvertTo-StandaloneSql -Node $tree -Values @{DeploymentMode=$mode;AssemblyBits=('0x'+[Convert]::ToHexString(([IO.File]::ReadAllBytes($coreBinary))))} -ModulesRoot (Join-Path $repo 'Modules')
 $path=Join-Path $destination ('core.'+$mode+'.private.sql');[IO.File]::WriteAllText($path,$text,[Text.UTF8Encoding]::new($false));$coreExports[$mode]=$path
}
$tree=Get-SqlcmdScriptTree -Path (Join-Path $repo 'Modules/toolbelt.json.core/Deployment/Uninstall.sql');Add-Node $tree
$text=ConvertTo-StandaloneSql -Node $tree -Values @{ConfirmNoExternalConsumers='1'} -ModulesRoot (Join-Path $repo 'Modules')
$coreUninstall=Join-Path $destination 'core.uninstall.private.sql';[IO.File]::WriteAllText($coreUninstall,$text,[Text.UTF8Encoding]::new($false))
$binaryGuards=@()
foreach($module in @('core','schema')){foreach($id in @('null','empty','zero','other')){
 $literal=switch -CaseSensitive($id){'null'{'NULL'};'empty'{'0x'};'zero'{'0x00'};'other'{'0x'+[Convert]::ToHexString($(if($module-ceq'core'){([IO.File]::ReadAllBytes($binary))}else{([IO.File]::ReadAllBytes($coreBinary))}))}}
 $row=@{module=$module;id=$id;paths=@{}}
 foreach($mode in @('local','central')){
  $tree=Get-SqlcmdScriptTree -Path (Join-Path $repo ('Modules/toolbelt.json.'+$module+'/Deployment/Deploy.sql'));Add-Node $tree
  $text=ConvertTo-StandaloneSql -Node $tree -Values @{DeploymentMode=$mode;AssemblyBits=$literal} -ModulesRoot (Join-Path $repo 'Modules')
  $path=Join-Path $destination ('binary.'+$module+'.'+$id+'.'+$mode+'.private.sql');[IO.File]::WriteAllText($path,$text,[Text.UTF8Encoding]::new($false));$row.paths[$mode]=$path
 }
 $binaryGuards+=@($row)
}}

[IO.File]::WriteAllText((Join-Path $destination 'binary-guards.json'),($binaryGuards|ConvertTo-Json -Depth 6),[Text.UTF8Encoding]::new($false))

[IO.File]::WriteAllText((Join-Path $destination 'nodes.json'),(@($paths)|ConvertTo-Json),[Text.UTF8Encoding]::new($false))
"""
        result=subprocess.run(['pwsh','-NoProfile','-Command',script],cwd=ROOT,capture_output=True,text=True,timeout=20)
        self.assertEqual(result.returncode,0,result.stdout+result.stderr)
        fixture=ROOT/'Tests/Release/Runtime/JsonLifecycle.BinaryRegistration.Contract.ps1'
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
        binary_guards=json.loads((self.directory/'binary-guards.json').read_bytes());files += [self.directory/('core.'+m+'.private.sql') for m in ('local','central')]+[self.directory/'core.uninstall.private.sql']+[Path(p) for row in binary_guards for p in row['paths'].values()];files += [ROOT/'Tests/Release/Runtime/JsonCore.Lock.Contract.ps1'];files=list(dict.fromkeys(files));started=datetime.now(timezone.utc)-timedelta(seconds=5)
        self.record=dict(schema_version='json-lifecycle-binary-registration/v1',explicit_qualification_approved=True,
            started_utc=started.isoformat(),deadline_utc=(started+timedelta(minutes=60)).isoformat(),
            cases=cases,fixtures=[str(fixture)],
            exports=exports,uninstall=str(uninstall),core_exports={m:str(self.directory/('core.'+m+'.private.sql')) for m in ('local','central')},core_uninstall=str(self.directory/'core.uninstall.private.sql'),binary_guards=binary_guards,artifact=dict(path=str(binary)),core_artifact=dict(path=str(corebinary)),baselines={m:str(self.directory/('baseline.'+m+'.private.sql')) for m in ('local','central')},provenance=str(Q),package=str(package),
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
        self.reject(lambda r:r.update(started_utc=past.isoformat(),deadline_utc=(past+timedelta(minutes=60)).isoformat()))
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

    def test_truncated_dependency_export_rejected_despite_repin(self):
        p=Path(self.record['baselines']['local']);p.write_text('SELECT 1;',encoding='utf-8')
        r=copy.deepcopy(self.record);next(x for x in r['pins'] if x['path']==str(p))['sha256']=hashlib.sha256(p.read_bytes()).hexdigest().upper()
        self.assertNotEqual(self.admission(r).returncode,0)
    def test_binary_vectors_cannot_be_reordered_or_replaced_despite_repin(self):
        self.reject(lambda r:r['binary_guards'].reverse())
        self.reject(lambda r:r['binary_guards'].pop())
        p=Path(self.record['binary_guards'][0]['paths']['local']);p.write_text('SELECT 1;',encoding='utf-8')
        r=copy.deepcopy(self.record);next(x for x in r['pins'] if x['path']==str(p))['sha256']=hashlib.sha256(p.read_bytes()).hexdigest().upper()
        self.assertNotEqual(self.admission(r).returncode,0)
    def test_registration_error_precedence_matches_original_sources(self):
        fixture=ROOT/'Tests/Release/Runtime/JsonLifecycle.BinaryRegistration.Contract.ps1'
        script="$ErrorActionPreference='Stop';$repo='"+str(ROOT).replace("'","''")+"';$path='"+str(fixture).replace("'","''")+"';"+r"""
$e=$null;$a=[Management.Automation.Language.Parser]::ParseFile($path,[ref]$null,[ref]$e)
$n=@($a.FindAll({param($x)$x-is[Management.Automation.Language.FunctionDefinitionAst]-and$x.Name-ceq'Get-LifecycleGuardRegistrationError'},$true));if($e.Count-or$n.Count-ne1){throw 'FUNCTION_SOURCE'};. ([scriptblock]::Create($n[0].Extent.Text))
foreach($module in @('core','schema')){
 $sources=@('Deploy.sql','Uninstall.sql','Preflight.sql')|ForEach-Object{[IO.File]::ReadAllText((Join-Path $repo ('Modules/toolbelt.json.'+$module+'/Deployment/'+$_)))}
 foreach($id in @('version-null','version-old','version-noncanonical','mode-null','mode-upper','mode-opposite')){foreach($op in @('deploy','uninstall')){
  $errorExpected=Get-LifecycleGuardRegistrationError $module $id $op
  if(($sources-join"`n").IndexOf($errorExpected.message,[StringComparison]::Ordinal)-lt0-or($sources-join"`n")-notmatch('THROW '+$errorExpected.number+',')){throw 'UNBOUND_PUBLIC_ERROR'}
  $number=if($module-ceq'core'){55623}elseif($id-ceq'version-null'){55634}else{55633}
  if($errorExpected.number-ne$number){throw 'WRONG_ERROR_NUMBER'}
 }}
 if((Get-LifecycleGuardRegistrationError $module 'mode-upper' 'deploy').message-ceq(Get-LifecycleGuardRegistrationError $module 'mode-upper' 'uninstall').message){throw 'UNINSTALL_MODE_PRECEDENCE_LOST'}
 if((Get-LifecycleGuardRegistrationError $module 'mode-opposite' 'deploy').message-ceq(Get-LifecycleGuardRegistrationError $module 'mode-opposite' 'uninstall').message){throw 'UNINSTALL_TUPLE_PRECEDENCE_LOST'}
}
"""
        r=subprocess.run(['pwsh','-NoProfile','-Command',script],cwd=ROOT,capture_output=True,text=True,timeout=20)
        self.assertEqual(r.returncode,0,r.stdout+r.stderr)
    def test_compatibility_changes_require_exact_owned_database_identity(self):
        fixture=ROOT/'Tests/Release/Runtime/JsonLifecycle.BinaryRegistration.Contract.ps1'
        script="$ErrorActionPreference='Stop';$path='"+str(fixture).replace("'","''")+"';"+r"""
$e=$null;$a=[Management.Automation.Language.Parser]::ParseFile($path,[ref]$null,[ref]$e)
$n=@($a.FindAll({param($x)$x-is[Management.Automation.Language.FunctionDefinitionAst]-and$x.Name-ceq'Get-LifecycleGuardOwnDatabaseName'},$true));if($e.Count-or$n.Count-ne1){throw 'FUNCTION_SOURCE'};. ([scriptblock]::Create($n[0].Extent.Text))
$owner='a'*32;$name='Toolbelt_Release_'+$owner+'_l';$db=[pscustomobject]@{Database=$name};$control=[pscustomobject]@{role='observer'}
$ledger=[ordered]@{owner=$owner;databases=@([ordered]@{name=$name;suffix='l';state='OWNED';id=7;created='0011223344556677'})}
$actualId=7;$actualCreated='0011223344556677';$actualOwner=$owner
function Sql($Connection,$Text,$Parameters=@{},[switch]$Rows){
 if([object]::ReferenceEquals($Connection,$control)){return [pscustomobject]@{Id=$actualId;Created=$actualCreated}}
 return [pscustomobject]@{Owner=$actualOwner}
}
if((Get-LifecycleGuardOwnDatabaseName $db)-cne$name){throw 'OWN_DB_GOLDEN'}
foreach($field in @('id','created','owner')){
 $actualId=7;$actualCreated='0011223344556677';$actualOwner=$owner
 switch($field){'id'{$actualId=8};'created'{$actualCreated='different'};'owner'{$actualOwner='b'*32}}
 $caught=$false;try{Get-LifecycleGuardOwnDatabaseName $db}catch{$caught=$_.Exception.Message-ceq'LIFECYCLE_GUARD_OWN_DATABASE_IDENTITY_DRIFT'}
 if(-not$caught){throw 'FOREIGN_DB_ACCEPTED'}
}
"""
        r=subprocess.run(['pwsh','-NoProfile','-Command',script],cwd=ROOT,capture_output=True,text=True,timeout=20)
        self.assertEqual(r.returncode,0,r.stdout+r.stderr)
    def test_exact_five_point_coverage_and_error_oracles(self):
        fixture=ROOT/'Tests/Release/Runtime/JsonLifecycle.BinaryRegistration.Contract.ps1'
        script="$ErrorActionPreference='Stop';$path='"+str(fixture).replace("'","''")+"';"+r"""
$e=$null;$a=[Management.Automation.Language.Parser]::ParseFile($path,[ref]$null,[ref]$e)
foreach($name in @('Get-LifecycleGuardKeys','Test-LifecycleGuardCoverage','Test-LifecycleGuardError')){
 $n=@($a.FindAll({param($x)$x-is[Management.Automation.Language.FunctionDefinitionAst]-and$x.Name-ceq$name},$true));if($e.Count-or$n.Count-ne1){throw 'FUNCTION_SOURCE'};. ([scriptblock]::Create($n[0].Extent.Text))
}
$case=[pscustomobject]@{CL=150};
$rows=@(foreach($mode in @('local','central')){foreach($id in Get-LifecycleGuardKeys $mode $case.CL){[pscustomobject]@{mode=$mode;id=$id;passed=$true}}})
if($rows.Count-ne72-or-not(Test-LifecycleGuardCoverage $rows)){throw 'COVERAGE_GOLDEN'}
if(Test-LifecycleGuardCoverage @($rows[1..71])){throw 'MISSING_PROFILE_ACCEPTED'}
if(Test-LifecycleGuardCoverage @($rows+$rows[0])){throw 'DUPLICATE_PROFILE_ACCEPTED'}
if(Test-LifecycleGuardCoverage $rows @('unknown')){throw 'UNKNOWN_EXCLUSION'}
$case.CL=160;$high=@(foreach($mode in @('local','central')){foreach($id in Get-LifecycleGuardKeys $mode $case.CL){[pscustomobject]@{mode=$mode;id=$id;passed=$true}}})
if($high.Count-ne64-or-not(Test-LifecycleGuardCoverage $high)-or@($high|Where-Object id -Match '^compat140/').Count){throw 'GREEN_COMPAT_ANCHOR_REPEATED'}
$case.CL=150;
$rows[0].passed=$false;if(Test-LifecycleGuardCoverage $rows){throw 'FAILED_PROFILE_ACCEPTED'}
$good=[pscustomobject]@{Number=55623;State=1;Class=16;Message='Contoso exact error'}
if(-not(Test-LifecycleGuardError @($good) 55623 'Contoso exact error')){throw 'ERROR_GOLDEN'}
foreach($field in @('Number','State','Class','Message')){
 $row=[pscustomobject]@{Number=55623;State=1;Class=16;Message='Contoso exact error'};$row.$field=if($field-ceq'Message'){'wrong'}else{99}
 if(Test-LifecycleGuardError @($row) 55623 'Contoso exact error'){throw 'WRONG_ERROR_ACCEPTED'}
}
if(Test-LifecycleGuardError @($good,$good) 55623 'Contoso exact error'){throw 'DUPLICATE_ERROR_ACCEPTED'}
'FIVE_POINT_ORACLES_PASS'
"""
        result=subprocess.run(['pwsh','-NoProfile','-Command',script],cwd=ROOT,capture_output=True,text=True,timeout=20)
        self.assertEqual(result.returncode,0,result.stdout+result.stderr)
if __name__=='__main__':unittest.main()
