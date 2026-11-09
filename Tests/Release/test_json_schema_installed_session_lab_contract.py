"""Zulassung des begrenzten Sessionprofils ohne Labimport oder SQL."""
from pathlib import Path
from datetime import datetime,timedelta,timezone
import copy,hashlib,json,shutil,subprocess,tempfile,unittest,zipfile
ROOT=Path(__file__).resolve().parents[2]
DRIVER=ROOT/'Tests/Release/Invoke-JsonSchemaInstalledSessionLab.ps1'
Q=ROOT/'Releases/1.0.0/JSON-SCHEMA-PACKAGE-QUALIFICATION.json'
@unittest.skipUnless(shutil.which('pwsh'),'PowerShell 7 required')
class JsonSchemaInstalledSessionAdmissionTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory(prefix='json-session-admission-',dir=ROOT/'.runtime')
        self.directory=Path(self.temp.name);q=json.loads(Q.read_bytes());package=ROOT/q['package']['path']
        with zipfile.ZipFile(package) as z:
            bits=z.read('SQL-Server-Toolbelt-1.0.0-CLR-Install/Binaries/Toolbelt.JsonSchema.dll')
        binary=self.directory/'qualified.dll';binary.write_bytes(bits)
        core=self.directory/'core.dll'
        with zipfile.ZipFile(package) as z:core.write_bytes(z.read('SQL-Server-Toolbelt-1.0.0-CLR-Install/Binaries/Toolbelt.JsonCore.dll'))
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

$parts=@();$core=Join-Path $destination 'core.dll'
foreach($module in @('toolbelt.core.result-table','toolbelt.json.core')){
 $tree=Get-SqlcmdScriptTree -Path (Join-Path $repo ('Modules/'+$module+'/Deployment/Deploy.sql'));Add-Node $tree
 $parts+=@(ConvertTo-StandaloneSql -Node $tree -Values @{DeploymentMode='local';AssemblyBits=('0x'+[Convert]::ToHexString([IO.File]::ReadAllBytes($core)))} -ModulesRoot (Join-Path $repo 'Modules'))
}
[IO.File]::WriteAllText((Join-Path $destination 'baseline.sql'),($parts-join"`nGO`n"),[Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllText((Join-Path $destination 'nodes.json'),(@($paths)|ConvertTo-Json),[Text.UTF8Encoding]::new($false))
"""
        result=subprocess.run(['pwsh','-NoProfile','-Command',script],cwd=ROOT,capture_output=True,text=True,timeout=20)
        self.assertEqual(result.returncode,0,result.stdout+result.stderr)
        fixture=ROOT/'Tests/Release/Runtime/JsonSchema.InstalledSession.Contract.ps1'
        scripts={op:str(self.directory/(op+'.sql')) for op in ('deploy','uninstall')}
        files=[DRIVER,Q,package,binary,fixture,*(Path(p) for p in scripts.values()),
               *(Path(p) for p in json.loads((self.directory/'nodes.json').read_bytes())),
               *(ROOT/p for p in ('Deployment/Deploy-All.ps1','Tests/Release/Invoke-JsonSchemaAppLockLab.ps1',
                 'Tests/Release/Invoke-JsonSchemaCallerTransactionLab.ps1','Tests/Release/Invoke-ApiQualificationLab.ps1',
                 'Tests/Release/Invoke-StablePackageLab.ps1','Tests/CI/run-lab-local.ps1','Tests/CI/LabQualifiedContract.ps1'))]
        registry=ROOT/'Modules/toolbelt.json.core/Documentation/KNOWN_JSON_ARTIFACT_CLOSURE.json'
        files += [core,self.directory/'baseline.sql',registry,ROOT/'Tests/Release/ClrCaller.Environment.ps1',ROOT/'Tests/CI/run-csv-memory-lab.ps1']
        for row in json.loads(registry.read_bytes())['artifacts']:
            f=row['Fields']
            if f['moduleId'] in ('toolbelt.json.core','toolbelt.json.schema'):
                folder=ROOT/'Modules'/f['moduleId']/'Clr'
                files += [folder/(f['managedAssembly']+'.csproj')]
                files += [folder/key[7:] for key in f if key.startswith('source/')]
        files=list(dict.fromkeys(files));started=datetime.now(timezone.utc)-timedelta(seconds=5)
        self.record=dict(schema_version='json-schema-installed-session/v1',explicit_qualification_approved=True,
            started_utc=started.isoformat(),deadline_utc=(started+timedelta(minutes=45)).isoformat(),
            cases=[dict(Platform='windows',Version='2025',Patch='CU8',CL=170,modes=['local'])],fixtures=[str(fixture)],
            baseline=str(self.directory/'baseline.sql'),core_artifact=dict(path=str(core)),scripts=scripts,artifact=dict(path=str(binary)),provenance=str(Q),package=str(package),
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

    def test_repinning_wrong_core_or_baseline_rejected(self):
        for field in ('core_artifact','baseline'):
            with self.subTest(field=field):
                record=copy.deepcopy(self.record)
                path=Path(record[field]['path'] if field=='core_artifact' else record[field])
                original=path.read_bytes()
                try:
                    path.write_bytes(b'unqualified core' if field=='core_artifact' else b'SELECT 1;')
                    next(pin for pin in record['pins'] if pin['path']==str(path))['sha256']=hashlib.sha256(path.read_bytes()).hexdigest().upper()
                    self.assertNotEqual(self.admission(record).returncode,0)
                finally:path.write_bytes(original)

    def run_function_probe(self,path,name,body):
        quoted="'"+str(path).replace("'","''")+"'"
        script="$ErrorActionPreference='Stop';$path="+quoted+";$name='"+name+"';"+r"""
$e=$null;$a=[Management.Automation.Language.Parser]::ParseFile($path,[ref]$null,[ref]$e)
if($e.Count){throw 'SOURCE_PARSE'}
$n=@($a.FindAll({param($x)$x-is[Management.Automation.Language.FunctionDefinitionAst]-and$x.Name-ceq$name},$true))
if($n.Count-ne1){throw 'FUNCTION_REQUIRED'};. ([scriptblock]::Create($n[0].Extent.Text))
"""+body
        result=subprocess.run(['pwsh','-NoProfile','-Command',script],cwd=ROOT,capture_output=True,text=True,timeout=20)
        self.assertEqual(result.returncode,0,result.stdout+result.stderr)

    def test_three_installed_inputs_and_actual_profile_rejection(self):
        self.run_function_probe(ROOT/'Tests/Release/Runtime/JsonSchema.InstalledSession.Contract.ps1','Invoke-JsonSchemaInstalledSessionProfiles',r"""
$ledger=@{results=@()};$script:options=0;$script:wrong=$null;$script:commands=@()
function Sql($Db,$Text){if($Text.StartsWith('SET QUOTED_IDENTIFIER')){
 $script:commands+=@($Text);$script:options=256
 if($Text.Contains('SET XACT_ABORT ON;')){$script:options+=16384};if($Text.Contains('SET NOCOUNT ON;')){$script:options+=512}
}}
function Read-Scalar($Db,$Text){if($Text.Contains('@@OPTIONS')){if($null-ne$script:wrong){return $script:wrong};return $script:options};return 1}
function Get-ModuleState($Db){return 'synthetic'}
function Save-ReleaseJournal{}
function Invoke-BlockedTransactionCase($Db,$Observer,$Case,$Before,$Options){$ledger.results+=@(@{operation=$Case.operation;ordinal=$Case.ordinal})}
Invoke-JsonSchemaInstalledSessionProfiles $null $null
if($ledger.results.Count-ne3-or($ledger.results.operation-join',')-cne'uninstall,uninstall,uninstall'){throw 'PROFILE_COUNT'}
$expected=@(768,16640,17152)
for($i=0;$i-lt3;$i++){$v=$ledger.results[$i];if($v.ordinal-ne$i-or-not$v.installed_module-or$v.observed_options-ne$expected[$i]-or[bool]($v.observed_options-band16384)-ne$v.xact_abort-or[bool]($v.observed_options-band512)-ne$v.nocount){throw 'PROFILE_RECEIPT'}}
if($script:commands.Count-ne3-or$script:commands[0]-cne'SET QUOTED_IDENTIFIER ON;SET IMPLICIT_TRANSACTIONS OFF;SET XACT_ABORT OFF;SET NOCOUNT ON;'-or$script:commands[1]-cne'SET QUOTED_IDENTIFIER ON;SET IMPLICIT_TRANSACTIONS OFF;SET XACT_ABORT ON;SET NOCOUNT OFF;'-or$script:commands[2]-cne'SET QUOTED_IDENTIFIER ON;SET IMPLICIT_TRANSACTIONS OFF;SET XACT_ABORT ON;SET NOCOUNT ON;'){throw 'ACTUAL_SQL_INPUTS'}
foreach($wrong in @(0,256,17152,770)){
 $ledger.results=@();$script:wrong=$wrong;$blocked=$false
 try{Invoke-JsonSchemaInstalledSessionProfiles $null $null}catch{if($_.Exception.Message-cne'JSON_INSTALLED_ACTUAL_SESSION_PROFILE'){throw};$blocked=$true}
 if(-not$blocked-or$ledger.results.Count){throw 'WRONG_ACTUAL_OPTIONS_ACCEPTED'}
}
""")

    def test_trust_cleanup_preserves_foreign_preexisting_and_uncertain_state(self):
        self.run_function_probe(DRIVER,'Stop-JsonInstalledTrust',r"""
function Save-ReleaseJournal{}
function Get-ClrCallerTrust($Control,$Hash){return $script:actual}
function Assert-ClrCallerTrustCleanupScope($Control,$Hash){$script:checks++;if($script:deny){throw 'SYNTHETIC_CONSUMER'}}
function Invoke-ReleaseSql($Control,$Text,$Parameters){if(-not$Text.Contains('sp_drop_trusted_assembly')-or$script:checks-ne1){throw 'UNGUARDED_DROP'};$script:drops++;$script:actual=$null}
function Reset-Probe{
 $script:actual=[pscustomobject]@{Fingerprint='own';description='Contoso own'};$script:checks=0;$script:drops=0;$script:deny=$false
 $script:ledger=@{trust=@(@{hash=('AA'*64);preexisting=$false;fingerprint='own';state='OWNED';description='Contoso own'})}
}
Reset-Probe;Stop-JsonInstalledTrust $null
if($script:drops-ne1-or$ledger.trust[0].state-cne'REMOVED'){throw 'OWN_REMOVAL'}
Reset-Probe;$ledger.trust[0].preexisting=$true;Stop-JsonInstalledTrust $null
if($script:drops-or$script:checks-or$null-eq$script:actual){throw 'PREEXISTING_CHANGED'}
foreach($drift in @('fingerprint','description','consumer','adding','preexistingMissing')){
 Reset-Probe
 switch($drift){
 'fingerprint' {$script:actual.Fingerprint='foreign'}
 'description' {$script:actual.description='Fabrikam'}
 'consumer' {$script:deny=$true}
 'adding' {$ledger.trust[0].state='ADDING'}
 'preexistingMissing' {$ledger.trust[0].preexisting=$true;$script:actual=$null}
 }
 $blocked=$false;try{Stop-JsonInstalledTrust $null}catch{$blocked=$true}
 if(-not$blocked-or$script:drops){throw 'FOREIGN_OR_UNCERTAIN_TRUST_DROPPED'}
}
Reset-Probe;$ledger.trust[0].state='ADDING';$script:actual=$null;Stop-JsonInstalledTrust $null
if($script:drops-or$ledger.trust[0].state-cne'ABSENT'){throw 'ABSENT_INTENT_NOT_RECOGNIZED'}
""")

if __name__=='__main__':unittest.main()
