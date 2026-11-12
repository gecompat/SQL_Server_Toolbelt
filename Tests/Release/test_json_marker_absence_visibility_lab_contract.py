"""New fixture dispatch and exact missing/NULL/visibility closure; reuse admission setup."""
from pathlib import Path
import copy,hashlib,shutil,subprocess,unittest
import test_json_lifecycle_binary_registration_lab_contract as admission

ROOT=Path(__file__).resolve().parents[2]
FIXTURE=ROOT/'Tests/Release/Runtime/JsonLifecycle.MarkerAbsenceVisibility.Contract.ps1'

@unittest.skipUnless(shutil.which('pwsh'),'PowerShell 7 required')
class MarkerAbsenceTests(unittest.TestCase):
    def test_new_scope_requires_exact_new_fixture_and_reuses_canonical_preflight(self):
        base=admission.JsonLifecycleGuardAdmissionTests()
        base.setUp()
        try:
            r=copy.deepcopy(base.record)
            r['schema_version']='json-lifecycle-marker-absence-visibility/v1'
            r['fixtures']=[str(FIXTURE)]
            r.pop('binary_guards')
            r['pins'].append(dict(path=str(FIXTURE),sha256=hashlib.sha256(FIXTURE.read_bytes()).hexdigest().upper()))
            valid=base.admission(r)
            self.assertEqual(valid.returncode,0,valid.stdout+valid.stderr)
            wrong=copy.deepcopy(r);wrong['fixtures']=base.record['fixtures']
            self.assertNotEqual(base.admission(wrong).returncode,0)
            missing=copy.deepcopy(r);missing['pins']=[p for p in r['pins'] if p['path']!=str(ROOT/'Tests/Release/Runtime/JsonLifecycle.BinaryRegistration.Contract.ps1')]
            self.assertNotEqual(base.admission(missing).returncode,0)
        finally:base.tearDown()

    def test_profile_closure_typed_restore_and_exact_mutation_scope(self):
        script="$ErrorActionPreference='Stop';$repo='"+str(ROOT).replace("'","''")+"';$path='"+str(FIXTURE).replace("'","''")+"';"+r"""
$e=$null;$ast=[Management.Automation.Language.Parser]::ParseFile($path,[ref]$null,[ref]$e);if($e.Count){throw 'PARSE'}
foreach($name in @('Get-MarkerAbsenceSpecs','Get-LifecycleGuardKeys','Get-MarkerAbsenceError','Get-MarkerAbsenceParameters')){
 $n=@($ast.FindAll({param($x)$x-is[Management.Automation.Language.FunctionDefinitionAst]-and$x.Name-ceq$name},$true));if($n.Count-ne1){throw 'FUNCTION'};. ([scriptblock]::Create($n[0].Extent.Text))
}
$specs=@(Get-MarkerAbsenceSpecs);if($specs.Count-ne18){throw 'SPEC_CLOSURE'}
foreach($spec in $specs){
 $p=Get-MarkerAbsenceParameters $spec
 if($p['@Name']-cne$spec.name-or$p['@Class']-ne$spec.class){throw 'PARAMETER_SCOPE'}
 $errorExpected=Get-MarkerAbsenceError $spec
 $source=[IO.File]::ReadAllText((Join-Path $repo ('Modules/toolbelt.json.'+$spec.module+'/Deployment/Preflight.sql')))
 if($source.IndexOf($errorExpected.message,[StringComparison]::Ordinal)-lt0-or$source-notmatch('THROW '+$errorExpected.number+',')){throw 'ERROR_SOURCE'}
}
$bad=[pscustomobject]@{group='assembly-core';module='core';slot='Toolbelt_JsonCore';name='ContosoUnselected';class=5}
$caught=$false;try{Get-MarkerAbsenceParameters $bad}catch{$caught=$_.Exception.Message-ceq'MARKER_ABSENCE_EXACT_PROPERTY_SCOPE'}
if(-not$caught){throw 'UNSELECTED_PROPERTY_ACCEPTED'}
$base=Join-Path $repo 'Tests/Release/Runtime/JsonLifecycle.BinaryRegistration.Contract.ps1'
$a=[Management.Automation.Language.Parser]::ParseFile($base,[ref]$null,[ref]$e)
$n=@($a.FindAll({param($x)$x-is[Management.Automation.Language.FunctionDefinitionAst]-and$x.Name-ceq'Test-LifecycleGuardCoverage'},$true));. ([scriptblock]::Create($n[0].Extent.Text))
foreach($cl in @(150,160,170)){
 $case=[pscustomobject]@{CL=$cl}
 $rows=@(foreach($mode in @('local','central')){foreach($id in Get-LifecycleGuardKeys $mode $cl){[pscustomobject]@{mode=$mode;id=$id;passed=$true}}})
 if($rows.Count-ne156-or-not(Test-LifecycleGuardCoverage $rows)){throw 'FULL_CLOSURE'}
 if(Test-LifecycleGuardCoverage @($rows[1..155])){throw 'MISSING_ACCEPTED'}
 if(Test-LifecycleGuardCoverage @($rows+$rows[0])){throw 'DUPLICATE_ACCEPTED'}
 $rows[0].passed=$false;if(Test-LifecycleGuardCoverage $rows){throw 'FAILURE_ACCEPTED'}
}
$text=[IO.File]::ReadAllText($path)
if($text-notmatch'permission_set,is_visible'-or-not$text.Contains('$script:markerAbsenceBaseState')){throw 'CORE_AND_SCHEMA_VISIBILITY_SNAPSHOT_REQUIRED'}
if($text-notmatch'@V sql_variant'-or$text-notmatch'sp_addextendedproperty'-or$text-notmatch'sp_updateextendedproperty'-or$text-notmatch'RESTORE_DRIFT'){throw 'TYPED_RESTORE_REQUIRED'}
$alters=@([regex]::Matches($text,'ALTER ASSEMBLY \[Toolbelt_Json(Core|Schema)\] WITH VISIBILITY=(ON|OFF);'))
if($alters.Count-ne4-or$text-match'(?i)PERMISSION_SET\s*=|ALTER\s+AUTHORIZATION|\b(GRANT|DENY|REVOKE)\b'){throw 'VISIBILITY_ONLY_SCOPE'}
'MARKER_ABSENCE_ORACLES_PASS'
"""
        r=subprocess.run(['pwsh','-NoProfile','-Command',script],cwd=ROOT,capture_output=True,text=True,timeout=25)
        self.assertEqual(r.returncode,0,r.stdout+r.stderr)

if __name__=='__main__':unittest.main()
