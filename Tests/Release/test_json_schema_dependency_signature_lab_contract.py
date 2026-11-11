"""Admission and exact profile oracles for five Schema dependency/signature matrices."""
from pathlib import Path
from datetime import datetime,timedelta,timezone
import copy,hashlib,json,shutil,subprocess,tempfile,unittest,zipfile
ROOT=Path(__file__).resolve().parents[2]
DRIVER=ROOT/'Tests/Release/Invoke-JsonSchemaDependencySignatureLab.ps1'
Q=ROOT/'Releases/1.0.0/JSON-SCHEMA-PACKAGE-QUALIFICATION.json'
@unittest.skipUnless(shutil.which('pwsh'),'PowerShell 7 required')
class JsonSchemaGuardAdmissionTests(unittest.TestCase):
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
        fixture=ROOT/'Tests/Release/Runtime/JsonSchema.DependencySignature.Contract.ps1'
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
        self.record=dict(schema_version='json-schema-dependency-signature/v1',explicit_qualification_approved=True,
            started_utc=started.isoformat(),deadline_utc=(started+timedelta(minutes=45)).isoformat(),
            cases=cases,fixtures=[str(fixture)],
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

    def test_truncated_dependency_export_rejected_despite_repin(self):
        p=Path(self.record['baselines']['local']);p.write_text('SELECT 1;',encoding='utf-8')
        r=copy.deepcopy(self.record);next(x for x in r['pins'] if x['path']==str(p))['sha256']=hashlib.sha256(p.read_bytes()).hexdigest().upper()
        self.assertNotEqual(self.admission(r).returncode,0)
    def test_signature_variants_change_only_one_header_token(self):
        fixture=ROOT/'Tests/Release/Runtime/JsonSchema.DependencySignature.Contract.ps1'
        source=ROOT/'Modules/toolbelt.json.schema/Source/USP_ValidateJsonSchema.sql'
        script="$ErrorActionPreference='Stop';$path='"+str(fixture).replace("'","''")+"';$source='"+str(source).replace("'","''")+"';"+r"""
$e=$null;$a=[Management.Automation.Language.Parser]::ParseFile($path,[ref]$null,[ref]$e)
foreach($name in @('Get-SchemaGuardSignatureCases','New-SchemaGuardSignature')){
 $n=@($a.FindAll({param($x)$x-is[Management.Automation.Language.FunctionDefinitionAst]-and$x.Name-ceq$name},$true));if($e.Count-or$n.Count-ne1){throw 'FUNCTION_SOURCE'};. ([scriptblock]::Create($n[0].Extent.Text))
}
$original=[IO.File]::ReadAllText($source);$specs=@(Get-SchemaGuardSignatureCases)
if($specs.Count-ne12-or@($specs.id|Sort-Object -Unique).Count-ne12){throw 'TWELVE_PARAMETERS_REQUIRED'}
$body=[regex]::Match($original,'(?im)^\s*AS\s*\r?\nBEGIN\b')
foreach($spec in $specs){
 $changed=New-SchemaGuardSignature $original $spec;$boundary=[regex]::Match($changed,'(?im)^\s*AS\s*\r?\nBEGIN\b')
 if($changed-ceq$original-or$changed.Substring($boundary.Index)-cne$original.Substring($body.Index)){throw 'BODY_CHANGED'}
 if($changed.Substring(0,$boundary.Index).Replace($spec.after,$spec.before)-cne$original.Substring(0,$body.Index)){throw 'OTHER_PARAMETER_CHANGED'}
}
$caught=$false;try{New-SchemaGuardSignature 'SELECT 1;' $specs[0]}catch{$caught=$_.Exception.Message-ceq'SCHEMA_GUARD_HEADER_BOUNDARY'}
if(-not$caught){throw 'MISSING_BODY_ACCEPTED'}
$caught=$false;try{New-SchemaGuardSignature $original ([pscustomobject]@{before='@Absent int';after='@Absent bit'})}catch{$caught=$_.Exception.Message-ceq'SCHEMA_GUARD_EXACT_SINGLE_PARAMETER'}
if(-not$caught){throw 'MISSING_PARAMETER_ACCEPTED'}
"""
        result=subprocess.run(['pwsh','-NoProfile','-Command',script],cwd=ROOT,capture_output=True,text=True,timeout=20)
        self.assertEqual(result.returncode,0,result.stdout+result.stderr)
    def test_catalog_create_definition_uses_idempotent_alter_command(self):
        fixture=ROOT/'Tests/Release/Runtime/JsonSchema.DependencySignature.Contract.ps1'
        script="$ErrorActionPreference='Stop';$path='"+str(fixture).replace("'","''")+"';"+r"""
$e=$null;$a=[Management.Automation.Language.Parser]::ParseFile($path,[ref]$null,[ref]$e)
$n=@($a.FindAll({param($x)$x-is[Management.Automation.Language.FunctionDefinitionAst]-and$x.Name-ceq'ConvertTo-SchemaGuardAlterCommand'},$true));if($e.Count-or$n.Count-ne1){throw 'FUNCTION_SOURCE'};. ([scriptblock]::Create($n[0].Extent.Text))
foreach($verb in @('CREATE','ALTER','CREATE OR ALTER','CREATE  ','CREATE    ')){
 $input=$verb+" PROCEDURE dbo.Contoso @Value int=1`nAS`nBEGIN SELECT @Value;END;"
 $expected="CREATE OR ALTER PROCEDURE dbo.Contoso @Value int=1`nAS`nBEGIN SELECT @Value;END;"
 if((ConvertTo-SchemaGuardAlterCommand $input)-cne$expected){throw 'CATALOG_CREATE_NOT_CONVERTED'}
}
$caught=$false;try{ConvertTo-SchemaGuardAlterCommand 'CREATE VIEW dbo.Contoso AS SELECT 1 X;'}catch{$caught=$_.Exception.Message-ceq'SCHEMA_GUARD_EXISTING_PROCEDURE_DDL_REQUIRED'}
if(-not$caught){throw 'FOREIGN_DDL_ACCEPTED'}
"""
        result=subprocess.run(['pwsh','-NoProfile','-Command',script],cwd=ROOT,capture_output=True,text=True,timeout=20)
        self.assertEqual(result.returncode,0,result.stdout+result.stderr)
    def test_fixture_restores_original_typed_values_and_observes_real_consumer(self):
        text=(ROOT/'Tests/Release/Runtime/JsonSchema.DependencySignature.Contract.ps1').read_text(encoding='utf-8-sig')
        self.assertIn('DECLARE @V sql_variant;SELECT @V=value FROM #SchemaGuardCoreMarkers',text)
        self.assertIn('DECLARE @V sql_variant;SELECT @V=value FROM #SchemaGuardResultMarkers',text)
        self.assertIn('referenced_id=OBJECT_ID',text)
        self.assertIn("major_id=(SELECT assembly_id FROM sys.assemblies WHERE name=N'Toolbelt_JsonCore')",text)
        self.assertNotIn('ASSEMBLY_ID(',text)
    def test_exact_five_point_coverage_and_error_oracles(self):
        fixture=ROOT/'Tests/Release/Runtime/JsonSchema.DependencySignature.Contract.ps1'
        script="$ErrorActionPreference='Stop';$path='"+str(fixture).replace("'","''")+"';"+r"""
$e=$null;$a=[Management.Automation.Language.Parser]::ParseFile($path,[ref]$null,[ref]$e)
foreach($name in @('Get-SchemaGuardSignatureCases','Get-SchemaGuardKeys','Test-SchemaGuardCoverage','Test-SchemaGuardModeCoverage','Test-SchemaGuardError')){
 $n=@($a.FindAll({param($x)$x-is[Management.Automation.Language.FunctionDefinitionAst]-and$x.Name-ceq$name},$true));if($e.Count-or$n.Count-ne1){throw 'FUNCTION_SOURCE'};. ([scriptblock]::Create($n[0].Extent.Text))
}
$rows=@(foreach($mode in @('local','central')){foreach($id in Get-SchemaGuardKeys $mode){[pscustomobject]@{mode=$mode;id=$id;passed=$true}}})
if($rows.Count-ne92-or-not(Test-SchemaGuardCoverage $rows)){throw 'COVERAGE_GOLDEN'}
if(Test-SchemaGuardCoverage @($rows[1..91])){throw 'MISSING_PROFILE_ACCEPTED'}
if(Test-SchemaGuardCoverage @($rows+$rows[0])){throw 'DUPLICATE_PROFILE_ACCEPTED'}
if(Test-SchemaGuardCoverage $rows @('local/signature/Json/deploy')){throw 'UNAUTHORISED_PROFILE_EXCLUSION'}
$excluded=@('local/signature/Json/deploy','local/signature/Json/uninstall');$tail=@($rows|Where-Object{($_.mode+'/'+$_.id)-cnotin$excluded})
if($tail.Count-ne90-or-not(Test-SchemaGuardCoverage $tail $excluded)){throw 'BOUND_TAIL_COVERAGE'}
if(Test-SchemaGuardCoverage $tail){throw 'TAIL_PROMOTED_TO_FULL'}
if(Test-SchemaGuardCoverage $rows $excluded){throw 'GREEN_PREFIX_REPEATED'}
if(Test-SchemaGuardCoverage $tail @('unknown')){throw 'UNKNOWN_REUSE'}
if(Test-SchemaGuardCoverage $tail @($excluded+$excluded)){throw 'DUPLICATE_REUSE'}
if(-not(Test-SchemaGuardModeCoverage $tail 'local' $excluded)){throw 'REUSED_MODE_PREFIX_COUNTED_TWICE'}
if(Test-SchemaGuardModeCoverage $tail 'local'){throw 'MISSING_MODE_PROFILES_ACCEPTED'}
if(-not(Test-SchemaGuardModeCoverage $rows 'central')){throw 'CENTRAL_MODE_COVERAGE'}
$rows[0].passed=$false;if(Test-SchemaGuardCoverage $rows){throw 'FAILED_PROFILE_ACCEPTED'}
$good=[pscustomobject]@{Number=55623;State=1;Class=16;Message='Contoso exact error'}
if(-not(Test-SchemaGuardError @($good) 55623 'Contoso exact error')){throw 'ERROR_GOLDEN'}
foreach($field in @('Number','State','Class','Message')){
 $row=[pscustomobject]@{Number=55623;State=1;Class=16;Message='Contoso exact error'};$row.$field=if($field-ceq'Message'){'wrong'}else{99}
 if(Test-SchemaGuardError @($row) 55623 'Contoso exact error'){throw 'WRONG_ERROR_ACCEPTED'}
}
if(Test-SchemaGuardError @($good,$good) 55623 'Contoso exact error'){throw 'DUPLICATE_ERROR_ACCEPTED'}
'FIVE_POINT_ORACLES_PASS'
"""
        result=subprocess.run(['pwsh','-NoProfile','-Command',script],cwd=ROOT,capture_output=True,text=True,timeout=20)
        self.assertEqual(result.returncode,0,result.stdout+result.stderr)
if __name__=='__main__':unittest.main()
