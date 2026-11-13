"""New fixture dispatch and exact missing/NULL/visibility closure; reuse admission setup."""
from pathlib import Path
import copy,hashlib,json,shutil,subprocess,unittest,zipfile
import test_json_lifecycle_binary_registration_lab_contract as admission

ROOT=Path(__file__).resolve().parents[2]
FIXTURE=ROOT/'Tests/Release/Runtime/JsonLifecycle.ConstructorDependency.Contract.ps1'

@unittest.skipUnless(shutil.which('pwsh'),'PowerShell 7 required')
class ConstructorDependencyTests(unittest.TestCase):
    def test_new_scope_requires_exact_new_fixture_and_reuses_canonical_preflight(self):
        base=admission.JsonLifecycleGuardAdmissionTests()
        base.setUp()
        try:
            r=copy.deepcopy(base.record)
            r['schema_version']='json-lifecycle-constructor-dependency/v1'
            r['fixtures']=[str(FIXTURE)]
            r.pop('binary_guards')
            dep=ROOT/'Tests/Release/Runtime/JsonSchema.DependencySignature.Contract.ps1'
            r['pins'].append(dict(path=str(dep),sha256=hashlib.sha256(dep.read_bytes()).hexdigest().upper()))
            r['pins'].append(dict(path=str(FIXTURE),sha256=hashlib.sha256(FIXTURE.read_bytes()).hexdigest().upper()))
            binary=base.directory/'constructors.dll'
            with zipfile.ZipFile(base.record['package']) as z:binary.write_bytes(z.read('SQL-Server-Toolbelt-1.0.0-CLR-Install/Binaries/Toolbelt.JsonConstructors.dll'))
            script="$ErrorActionPreference='Stop';$repo='"+str(ROOT).replace("'","''")+"';$dest='"+str(base.directory).replace("'","''")+"';$binary='"+str(binary).replace("'","''")+"';"+r"""
$e=$null;$a=[Management.Automation.Language.Parser]::ParseFile((Join-Path $repo 'Deployment/Deploy-All.ps1'),[ref]$null,[ref]$e)
foreach($name in @('Get-SqlcmdScriptTree','ConvertTo-StandaloneSql')){$n=@($a.FindAll({param($x)$x-is[Management.Automation.Language.FunctionDefinitionAst]-and$x.Name-ceq$name},$true));. ([scriptblock]::Create($n[0].Extent.Text))}
$nodes=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
function Add-Node($n){[void]$nodes.Add($n.Path);foreach($c in $n.Children){Add-Node $c}}
foreach($mode in @('local','central')){
 $tree=Get-SqlcmdScriptTree -Path (Join-Path $repo 'Modules/toolbelt.json.constructors/Deployment/Deploy.sql');Add-Node $tree
 $text=ConvertTo-StandaloneSql -Node $tree -Values @{DeploymentMode=$mode;AssemblyBits=('0x'+[Convert]::ToHexString([IO.File]::ReadAllBytes($binary)))} -ModulesRoot (Join-Path $repo 'Modules')
 [IO.File]::WriteAllText((Join-Path $dest ('ctor.'+$mode+'.sql')),$text,[Text.UTF8Encoding]::new($false))
}
$tree=Get-SqlcmdScriptTree -Path (Join-Path $repo 'Modules/toolbelt.json.constructors/Deployment/Uninstall.sql');Add-Node $tree
$text=ConvertTo-StandaloneSql -Node $tree -Values @{ConfirmNoExternalConsumers='1'} -ModulesRoot (Join-Path $repo 'Modules')
[IO.File]::WriteAllText((Join-Path $dest 'ctor.uninstall.sql'),$text,[Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllText((Join-Path $dest 'ctor.nodes.json'),(@($nodes)|ConvertTo-Json),[Text.UTF8Encoding]::new($false))
"""
            build=subprocess.run(['pwsh','-NoProfile','-Command',script],cwd=ROOT,capture_output=True,text=True,timeout=25)
            self.assertEqual(build.returncode,0,build.stdout+build.stderr)
            r['constructor_artifact']={'path':str(binary)}
            r['constructor_exports']={m:str(base.directory/('ctor.'+m+'.sql')) for m in ('local','central')}
            r['constructor_uninstall']=str(base.directory/'ctor.uninstall.sql')
            registry=json.loads((ROOT/'Modules/toolbelt.json.core/Documentation/KNOWN_JSON_ARTIFACT_CLOSURE.json').read_bytes())
            f=next(row['Fields'] for row in registry['artifacts'] if row['Fields']['moduleId']=='toolbelt.json.constructors')
            folder=ROOT/'Modules/toolbelt.json.constructors/Clr'
            files=[binary,*(Path(v) for v in r['constructor_exports'].values()),Path(r['constructor_uninstall']),*(Path(v) for v in json.loads((base.directory/'ctor.nodes.json').read_bytes())),folder/(f['managedAssembly']+'.csproj'),*(folder/k[7:] for k in f if k.startswith('source/'))]
            existing={v['path'] for v in r['pins']}
            for path in dict.fromkeys(files):
                if str(path) not in existing:r['pins'].append(dict(path=str(path),sha256=hashlib.sha256(path.read_bytes()).hexdigest().upper()));existing.add(str(path))
            valid=base.admission(r)
            self.assertEqual(valid.returncode,0,valid.stdout+valid.stderr)
            wrong=copy.deepcopy(r);wrong['fixtures']=base.record['fixtures']
            self.assertNotEqual(base.admission(wrong).returncode,0)
            missing=copy.deepcopy(r);missing['pins']=[p for p in r['pins'] if p['path']!=str(ROOT/'Tests/Release/Runtime/JsonLifecycle.BinaryRegistration.Contract.ps1')]
            self.assertNotEqual(base.admission(missing).returncode,0)
            path=Path(r['constructor_exports']['local']);original_script=path.read_bytes();path.write_text('SELECT 1;',encoding='utf-8')
            bad=copy.deepcopy(r);next(v for v in bad['pins'] if v['path']==str(path))['sha256']=hashlib.sha256(path.read_bytes()).hexdigest().upper()
            result=base.admission(bad)
            self.assertNotEqual(result.returncode,0)
            self.assertIn('CONSTRUCTOR_DEPENDENCY_CANONICAL_DEPLOY',result.stdout+result.stderr)
            path.write_bytes(original_script)
            binary.write_bytes(b'unknown constructor')
            bad=copy.deepcopy(r);next(v for v in bad['pins'] if v['path']==str(binary))['sha256']=hashlib.sha256(binary.read_bytes()).hexdigest().upper()
            result=base.admission(bad)
            self.assertNotEqual(result.returncode,0)
            self.assertIn('CONSTRUCTOR_DEPENDENCY_PACKAGE_BINARY',result.stdout+result.stderr)
        finally:base.tearDown()


    def test_exact_deploy_only_keys_error_sources_and_typed_restore(self):
        script="$ErrorActionPreference='Stop';$repo='"+str(ROOT).replace("'","''")+"';$path='"+str(FIXTURE).replace("'","''")+"';"+r"""
$e=$null;$a=[Management.Automation.Language.Parser]::ParseFile($path,[ref]$null,[ref]$e);if($e.Count){throw 'PARSE'}
foreach($name in @('Get-ConstructorDependencySpecs','Get-LifecycleGuardKeys','Get-ConstructorDependencyError')){
 $n=@($a.FindAll({param($x)$x-is[Management.Automation.Language.FunctionDefinitionAst]-and$x.Name-ceq$name},$true));if($n.Count-ne1){throw 'FUNCTION'};. ([scriptblock]::Create($n[0].Extent.Text))
}
$specs=@(Get-ConstructorDependencySpecs);if($specs.Count-ne26){throw 'VECTOR_CLOSURE'}
$source=[IO.File]::ReadAllText((Join-Path $repo 'Modules/toolbelt.json.schema/Deployment/Preflight.sql'))
foreach($spec in $specs){if(-not$source.Contains((Get-ConstructorDependencyError $spec))){throw 'ERROR_SOURCE'}}
foreach($cl in @(150,160,170)){foreach($mode in @('local','central')){
 $keys=@(Get-LifecycleGuardKeys $mode $cl)
 if($keys.Count-ne26-or@($keys|Select-Object -Unique).Count-ne26-or@($keys|Where-Object{$_-notlike'*/deploy'}).Count){throw 'DEPLOY_ONLY_CLOSURE'}
}}
$text=[IO.File]::ReadAllText($path)
foreach($required in @('sql_variant','sp_addextendedproperty','sp_updateextendedproperty','sp_dropextendedproperty','RESTORE_DRIFT','ORIGINAL_NOT_RESTORED','constructor_exports','constructor_uninstall')){if(-not$text.Contains($required)){throw 'DEPENDENCY_OR_RESTORE_GUARD_MISSING'}}
if($text-match'(?i)\b(GRANT|DENY|REVOKE)\b|ALTER\s+AUTHORIZATION|ALTER\s+ASSEMBLY|CREATE\s+TYPE'){throw 'SCOPE_EXCEEDED'}
'CONSTRUCTOR_DEPENDENCY_COUNTEREXAMPLES_PASS'
"""
        result=subprocess.run(['pwsh','-NoProfile','-Command',script],cwd=ROOT,capture_output=True,text=True,timeout=25)
        self.assertEqual(result.returncode,0,result.stdout+result.stderr)

if __name__=='__main__':unittest.main()
