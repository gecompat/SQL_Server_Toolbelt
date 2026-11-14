"""Zwanzig direkte Aggregat-Fehlerwellen: geschlossene Eingaben, SQL-Reader und Ressourcenrahmen."""
from pathlib import Path
import copy,hashlib,json,shutil,subprocess,unittest,zipfile
import test_json_lifecycle_binary_registration_lab_contract as admission

ROOT=Path(__file__).resolve().parents[2]
FIXTURE=ROOT/'Tests/Release/Runtime/JsonConstructors.AggregateErrors.Contract.ps1'

@unittest.skipUnless(shutil.which('pwsh'),'PowerShell 7 required')
class AggregateErrorWaveTests(unittest.TestCase):
    def test_new_scope_requires_exact_new_fixture_and_reuses_canonical_preflight(self):
        base=admission.JsonLifecycleGuardAdmissionTests()
        base.setUp()
        try:
            r=copy.deepcopy(base.record)
            r['schema_version']='json-constructors-aggregate-errors/v1'
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


    def test_twenty_waves_inputs_error_tags_and_partial_row_barrier(self):
        script="$ErrorActionPreference='Stop';$path='"+str(FIXTURE).replace("'","''")+"';"+r"""
$e=$null;$a=[Management.Automation.Language.Parser]::ParseFile($path,[ref]$null,[ref]$e);if($e.Count){throw 'PARSE'}
foreach($name in @('Get-AggregateErrorSpecs','Assert-AggregateErrorSpec','Get-AggregateErrorKey','Get-AggregateSelectedSpecs','Get-LifecycleGuardKeys','Get-AggregateErrorInput','Get-AggregateErrorStatement','Test-AggregateErrorTuple')){
 $n=@($a.FindAll({param($x)$x-is[Management.Automation.Language.FunctionDefinitionAst]-and$x.Name-ceq$name},$true));if($n.Count-ne1){throw 'FUNCTION'};. ([scriptblock]::Create($n[0].Extent.Text))
}
$specs=@(Get-AggregateSelectedSpecs);if($specs.Count-ne128){throw 'VECTOR_CLOSURE'}
$waves=@($specs|ForEach-Object{$_.aggregate+'/'+$_.wave}|Select-Object -Unique);if($waves.Count-ne20){throw 'WAVE_CLOSURE'}
foreach($cl in @(150,160,170)){foreach($mode in @('local','central')){$k=@(Get-LifecycleGuardKeys $mode $cl);if($k.Count-ne128-or@($k|Select-Object -Unique).Count-ne128){throw 'KEY_CLOSURE'}}}
foreach($spec in $specs){
 $p=Get-AggregateErrorInput $spec;$sql=Get-AggregateErrorStatement $spec
 if($sql-notmatch('AGF_Json'+$(if($spec.aggregate-ceq'array'){'Array'}else{'Object'}))){throw 'WRONG_AGGREGATE'}
 if($spec.wave-ceq'entry-priority-1'-and$p['@Count']-ne$(if($spec.id-ceq'at-limit'){10000}else{10001})){throw 'PROFILE1_COUNT'}
 if($spec.wave-ceq'entry-priority-2'-and$p['@Count']-ne$(if($spec.id-ceq'at-limit'){100000}else{100001})){throw 'PROFILE2_COUNT'}
 if($spec.wave-ceq'profile-invalid'-and$p['@Profile']-cin@(1,2)){throw 'VALID_PROFILE_IN_NEGATIVE'}
 $good=@([pscustomobject]@{Number=6522;Class=16;State=1;Message=('Wrapped: '+$spec.tag+' at Synthetic.Frame')})
 if(-not(Test-AggregateErrorTuple $good $spec.tag)){throw 'EXPECTED_TAG_REJECTED'}
 $good[0].Message+=' TBX_JSON_AGG_RESOURCE_FAILURE';if(Test-AggregateErrorTuple $good $spec.tag){throw 'MULTIPLE_TAGS_ACCEPTED'}
 $good[0].Message=$spec.tag;$good[0].Number=229;if(Test-AggregateErrorTuple $good $spec.tag){throw 'WRONG_SQL_ERROR_ACCEPTED'}
}
$runset=[pscustomobject]@{aggregate_error_scope='small-errors-only'};if(@(Get-AggregateSelectedSpecs).Count-ne120-or@(Get-LifecycleGuardKeys local 150).Count-ne120){throw 'SMALL_SCOPE_CLOSURE'}
$runset.aggregate_error_scope='unknown';$refused=$false;try{Get-AggregateSelectedSpecs}catch{$refused=$true};if(-not$refused){throw 'UNKNOWN_SCOPE_ACCEPTED'};Remove-Variable runset
$bad=[pscustomobject]@{aggregate='array';wave='entry-priority-2';id='one-over';profile=1;tag='TBX_JSON_AGG_ENTRY_LIMIT'}
$caught=$false;try{Get-AggregateErrorInput $bad}catch{$caught=$true};if(-not$caught){throw 'UNSELECTED_VECTOR_ACCEPTED'}
$t=[IO.File]::ReadAllText($path)
foreach($required in @('$rows-ne0','AGGREGATE_ERRORS_ACTUAL_INPUT_COUNT','AGGREGATE_ERRORS_MUTATED_MODULE_OR_INPUT','SHA2_256','FOR XML RAW,BINARY BASE64','Assert-CoreLockNeutral','inputDigest','aggregateTag','constructor_uninstall','CASE WHEN TRY_CONVERT(int,@ValidCount)=1 THEN n ELSE 0 END','AGGREGATE_ERRORS_REUSE_PREFIX_INPUT_CHANGED')){if(-not$t.Contains($required)){throw 'SAFETY_ORACLE_MISSING'}}
if($t-match'(?i)\b(GRANT|DENY|REVOKE)\b|ALTER\s+AUTHORIZATION|CREATE\s+(USER|LOGIN|ASSEMBLY)'){throw 'SCOPE_EXCEEDED'}
'AGGREGATE_ERROR_WAVES_COUNTEREXAMPLES_PASS'
"""
        r=subprocess.run(['pwsh','-NoProfile','-Command',script],cwd=ROOT,capture_output=True,text=True,timeout=25)
        self.assertEqual(r.returncode,0,r.stdout+r.stderr)

    def test_reused_prefix_rejects_missing_reordered_or_false_receipts(self):
        script="$ErrorActionPreference='Stop';$path='"+str(FIXTURE).replace("'","''")+"';"+r"""
$e=$null;$a=[Management.Automation.Language.Parser]::ParseFile($path,[ref]$null,[ref]$e)
foreach($name in @('Get-AggregateErrorSpecs','Assert-AggregateErrorSpec','Get-AggregateErrorKey','Get-AggregateErrorInput','Test-AggregateOriginalPrefix')){$n=@($a.FindAll({param($x)$x-is[Management.Automation.Language.FunctionDefinitionAst]-and$x.Name-ceq$name},$true));. ([scriptblock]::Create($n[0].Extent.Text))}
function New-Receipts{
 foreach($spec in @(Get-AggregateErrorSpecs|Select-Object -First 60)){$p=Get-AggregateErrorInput $spec;[pscustomobject]@{mode='local';id=(Get-AggregateErrorKey $spec);passed=$true;number=6522;aggregateTag=$spec.tag;partialRows=0;inputCount=$(if($p['@Second']-eq1){2}else{1});snapshotPreserved=$true;snapshotSHA256=('A'*64);inputDigest=('B'*64)}}
}
$r=@(New-Receipts);if(-not(Test-AggregateOriginalPrefix $r)){throw 'VALID_PREFIX_REJECTED'}
foreach($field in @('mode','id','number','aggregateTag','partialRows','inputCount','snapshotPreserved','snapshotSHA256','inputDigest')){
 $r=@(New-Receipts);switch($field){'mode'{$r[0].mode='central'};'id'{$r[0].id='unselected'};'number'{$r[0].number=229};'aggregateTag'{$r[0].aggregateTag='TBX_JSON_AGG_RESOURCE_FAILURE'};'partialRows'{$r[0].partialRows=1};'inputCount'{$r[0].inputCount=999};'snapshotPreserved'{$r[0].snapshotPreserved=$false};'snapshotSHA256'{$r[0].snapshotSHA256='bad'};'inputDigest'{$r[0].inputDigest='bad'}}
 if(Test-AggregateOriginalPrefix $r){throw 'BAD_PREFIX_ACCEPTED'}
}
$r=@(New-Receipts);if(Test-AggregateOriginalPrefix @($r|Select-Object -First 59)){throw 'MISSING_RECEIPT_ACCEPTED'}
$r=@(New-Receipts);$x=$r[0];$r[0]=$r[1];$r[1]=$x;if(Test-AggregateOriginalPrefix $r){throw 'REORDERED_PREFIX_ACCEPTED'}
'AGGREGATE_PREFIX_COUNTEREXAMPLES_PASS'
"""
        r=subprocess.run(['pwsh','-NoProfile','-Command',script],cwd=ROOT,capture_output=True,text=True,timeout=25)
        self.assertEqual(r.returncode,0,r.stdout+r.stderr)

    def test_remaining_boundaries_keep_valid_inputs_and_enforce_finite_timeout(self):
        script="$ErrorActionPreference='Stop';$path='"+str(FIXTURE).replace("'","''")+"';"+r"""
$e=$null;$a=[Management.Automation.Language.Parser]::ParseFile($path,[ref]$null,[ref]$e);if($e.Count){throw 'PARSE'}
foreach($name in @('Get-AggregateErrorSpecs','Assert-AggregateErrorSpec','Get-AggregateSelectedSpecs','Get-AggregateErrorInput','Get-AggregateErrorStatement','Get-ReleaseTimeout')){$n=@($a.FindAll({param($x)$x-is[Management.Automation.Language.FunctionDefinitionAst]-and$x.Name-ceq$name},$true));. ([scriptblock]::Create($n[0].Extent.Text))}
$runset=[pscustomobject]@{aggregate_error_scope='remaining-boundaries';deadline_utc=[DateTimeOffset]::UtcNow.AddHours(1).ToString('o')};$CaseIndex=0
$r=@(Get-AggregateSelectedSpecs);if($r.Count-ne12-or@($r|Where-Object wave -Like 'entry-valid-*').Count-ne4){throw 'BOUNDARY_CLOSURE'}
foreach($s in $r){$p=Get-AggregateErrorInput $s;if($p['@Count']-ne($(if($s.profile-eq1){10000}else{100000})+$(if($s.id-ceq'one-over'){1}else{0}))){throw 'COUNT'};if((Get-AggregateErrorStatement $s)-notmatch'OPTION \(MAXDOP 1\)'){throw 'SERIAL_SHAPE'}}
$CaseIndex=11;if(@(Get-AggregateSelectedSpecs).Count-ne132){throw 'LINUX_REST_CLOSURE'}
$runset.aggregate_error_scope='valid-boundaries';foreach($CaseIndex in @(0,11)){if(@(Get-AggregateSelectedSpecs).Count-ne4){throw 'VALID_BOUNDARIES_ONLY'}}
$runset|Add-Member aggregate_query_shape 'profile-hash';$sample=Get-AggregateSelectedSpecs|Select-Object -First 1;if((Get-AggregateErrorStatement $sample)-notmatch'GROUP BY Profile OPTION \(HASH GROUP, MAXDOP 1\)'){throw 'HASH_SHAPE'}
$runset.aggregate_error_scope='small-errors-only';$refused=$false;try{Get-AggregateSelectedSpecs}catch{$refused=$true};if(-not$refused){throw 'HASH_SCOPE_ESCAPED'};$runset.aggregate_error_scope='valid-boundaries';$runset.aggregate_query_shape='unknown';$refused=$false;try{Get-AggregateSelectedSpecs}catch{$refused=$true};if(-not$refused){throw 'UNKNOWN_QUERY_SHAPE'};$runset.PSObject.Properties.Remove('aggregate_query_shape')
$runset|Add-Member aggregate_capture_plan 'true';$refused=$false;try{Get-AggregateSelectedSpecs}catch{$refused=$true};if(-not$refused){throw 'UNTRUSTED_PLAN_BOOLEAN'};$runset.PSObject.Properties.Remove('aggregate_capture_plan');$runset.aggregate_error_scope='remaining-boundaries'
$s=Get-AggregateSelectedSpecs|Where-Object wave -CEQ 'number-invalid'|Select-Object -First 1;if((Get-AggregateErrorStatement $s)-match'MAXDOP'){throw 'SMALL_SHAPE_CHANGED'}
$script:clock=[Diagnostics.Stopwatch]::StartNew();$script:cleanup=$false;if((Get-ReleaseTimeout)-ne180){throw 'REST_TIMEOUT'}
$runset.aggregate_error_scope='small-errors-only';if((Get-ReleaseTimeout)-ne45){throw 'OLD_TIMEOUT_CHANGED'}
$runset.aggregate_error_scope='remaining-boundaries';$runset.deadline_utc=[DateTimeOffset]::UtcNow.AddSeconds(-1).ToString('o');$refused=$false;try{Get-ReleaseTimeout}catch{$refused=$true};if(-not$refused){throw 'EXPIRED_DEADLINE_ACCEPTED'}
'BOUNDARY_REST_COUNTEREXAMPLES_PASS'
"""
        r=subprocess.run(['pwsh','-NoProfile','-Command',script],cwd=ROOT,capture_output=True,text=True,timeout=25)
        self.assertEqual(r.returncode,0,r.stdout+r.stderr)

    def test_durable_journal_preserves_prior_state_and_rejects_corruption(self):
        import tempfile
        with tempfile.TemporaryDirectory() as directory:
            journal=str(Path(directory)/'journal.json').replace("'","''")
            helper=str(ROOT/'Tests/Release/Invoke-StablePackageLab.ps1').replace("'","''")
            script="$ErrorActionPreference='Stop';$script:journal='"+journal+"';$helper='"+helper+"';"+r"""
$e=$null;$a=[Management.Automation.Language.Parser]::ParseFile($helper,[ref]$null,[ref]$e);$n=@($a.FindAll({param($x)$x-is[Management.Automation.Language.FunctionDefinitionAst]-and$x.Name-ceq'Save-ReleaseJournal'},$true));if($n.Count-ne1){throw 'FUNCTION'};. ([scriptblock]::Create($n[0].Extent.Text))
$script:ledger=[ordered]@{owner='synthetic';state='FIRST'};Save-ReleaseJournal
if((Get-Content $journal -Raw|ConvertFrom-Json).state-cne'FIRST'-or(Get-Content ($journal+'.previous') -Raw|ConvertFrom-Json).state-cne'FIRST'){throw 'INITIAL_REDUNDANCY'}
$ledger.state='SECOND';Save-ReleaseJournal
if((Get-Content $journal -Raw|ConvertFrom-Json).state-cne'SECOND'-or(Get-Content ($journal+'.previous') -Raw|ConvertFrom-Json).state-cne'FIRST'){throw 'PREVIOUS_STATE_LOST'}
$savedBackup=$journal+'.saved';[IO.File]::Move(($journal+'.previous'),$savedBackup);[void][IO.Directory]::CreateDirectory($journal+'.previous')
$caught=$false;try{$ledger.state='THIRD';Save-ReleaseJournal}catch{$caught=$true}finally{[IO.Directory]::Delete($journal+'.previous');[IO.File]::Move($savedBackup,($journal+'.previous'))}
if(-not$caught-or(Get-Content $journal -Raw|ConvertFrom-Json).state-cne'SECOND'){throw 'FAILED_REPLACEMENT_LOST_CURRENT'}
if(@(Get-ChildItem (Split-Path $journal) -Filter '*.writing').Count){throw 'OWN_TEMP_LEAK'}
$prior=[IO.File]::ReadAllBytes($journal+'.previous');[IO.File]::WriteAllBytes($journal,[byte[]]::new(64));$caught=$false
try{Save-ReleaseJournal}catch{if($_.Exception.Message-ceq'RELEASE_JOURNAL_INVALID_EXISTING'){$caught=$true}}
if(-not$caught-or[Convert]::ToHexString($prior)-cne[Convert]::ToHexString([IO.File]::ReadAllBytes($journal+'.previous'))){throw 'CORRUPTION_MASKED_OR_BACKUP_LOST'}
'DURABLE_JOURNAL_COUNTEREXAMPLES_PASS'
"""
            r=subprocess.run(['pwsh','-NoProfile','-Command',script],cwd=ROOT,capture_output=True,text=True,timeout=25)
            self.assertEqual(r.returncode,0,r.stdout+r.stderr)

if __name__=='__main__':unittest.main()
