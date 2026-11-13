"""New fixture dispatch and exact missing/NULL/visibility closure; reuse admission setup."""
from pathlib import Path
import copy,hashlib,shutil,subprocess,unittest
import test_json_lifecycle_binary_registration_lab_contract as admission

ROOT=Path(__file__).resolve().parents[2]
FIXTURE=ROOT/'Tests/Release/Runtime/JsonLifecycle.RegistrationText.Contract.ps1'

@unittest.skipUnless(shutil.which('pwsh'),'PowerShell 7 required')
class RegistrationTextTests(unittest.TestCase):
    def test_new_scope_requires_exact_new_fixture_and_reuses_canonical_preflight(self):
        base=admission.JsonLifecycleGuardAdmissionTests()
        base.setUp()
        try:
            r=copy.deepcopy(base.record)
            r['schema_version']='json-lifecycle-registration-text/v1'
            r['fixtures']=[str(FIXTURE)]
            r.pop('binary_guards')
            dep=ROOT/'Tests/Release/Runtime/JsonSchema.DependencySignature.Contract.ps1'
            r['pins'].append(dict(path=str(dep),sha256=hashlib.sha256(dep.read_bytes()).hexdigest().upper()))
            r['pins'].append(dict(path=str(FIXTURE),sha256=hashlib.sha256(FIXTURE.read_bytes()).hexdigest().upper()))
            valid=base.admission(r)
            self.assertEqual(valid.returncode,0,valid.stdout+valid.stderr)
            wrong=copy.deepcopy(r);wrong['fixtures']=base.record['fixtures']
            self.assertNotEqual(base.admission(wrong).returncode,0)
            missing=copy.deepcopy(r);missing['pins']=[p for p in r['pins'] if p['path']!=str(ROOT/'Tests/Release/Runtime/JsonLifecycle.BinaryRegistration.Contract.ps1')]
            self.assertNotEqual(base.admission(missing).returncode,0)
        finally:base.tearDown()

    def test_ten_closed_groups_properties_errors_and_restore_scope(self):
        script="$ErrorActionPreference='Stop';$path='"+str(FIXTURE).replace("'","''")+"';"+r"""
$e=$null;$a=[Management.Automation.Language.Parser]::ParseFile($path,[ref]$null,[ref]$e);if($e.Count){throw 'PARSE'}
foreach($name in @('Get-RegistrationTextSpecs','Get-LifecycleGuardKeys','Get-RegistrationTextParameters','Get-RegistrationTextError')){
 $n=@($a.FindAll({param($x)$x-is[Management.Automation.Language.FunctionDefinitionAst]-and$x.Name-ceq$name},$true));if($n.Count-ne1){throw 'FUNCTION'};. ([scriptblock]::Create($n[0].Extent.Text))
}
foreach($cl in @(150,160,170)){foreach($mode in @('local','central')){
 $k=@(Get-LifecycleGuardKeys $mode $cl);if($k.Count-ne92-or@($k|Select-Object -Unique).Count-ne92){throw 'EXACT_CLOSURE'}
 $counts=@($k|ForEach-Object{$_.Split('/')[0]}|Group-Object|ForEach-Object Count|Sort-Object)
 if(($counts-join',')-cne'4,8,8,8,8,8,8,12,12,16'){throw 'TEN_GROUPS'}
 foreach($spec in Get-RegistrationTextSpecs){
  $p=Get-RegistrationTextParameters $spec $mode;if($p['@Name']-cne$spec.name-or$p['@Class']-ne$spec.class-or$p['@Slot']-cne$spec.slot){throw 'PARAMETER_SCOPE'}
  foreach($op in @('deploy','uninstall')){
   $expectedError=Get-RegistrationTextError $spec $op
   if($expectedError.number-ne$(if($spec.module-ceq'core'){55623}else{55633})){throw 'ERROR_NUMBER'}
   $expected=if($spec.class-eq1){'JSON Schema lifecycle: objektgenaue Ownership inkohärent.'}elseif($op-ceq'uninstall'-and$spec.group.StartsWith('db-mode-')){if($spec.module-ceq'core'){'JSON Core: inkohärenter installierter Modus.'}else{'JSON Schema lifecycle: inkohärenter installierter Modus.'}}else{if($spec.module-ceq'core'){'JSON Core: keine kohärente bekannte technische SAFE-Assembly.'}else{'JSON Schema lifecycle: unbekannter oder inkohärenter Releasezustand.'}}
   if($expectedError.message-cne$expected){throw 'EXACT_ERROR_MESSAGE'}
  }
 }
}}
$bad=[pscustomobject]@{group='db-version-core';id='space';module='core';class=0;slot='';name='ContosoUnselected';variant='space'}
$caught=$false;try{Get-RegistrationTextParameters $bad 'local'}catch{$caught=$true};if(-not$caught){throw 'UNSELECTED_PROPERTY_ACCEPTED'}
$caught=$false;try{Get-LifecycleGuardKeys 'LOCAL' 150}catch{$caught=$true};if(-not$caught){throw 'WRONG_MODE_ACCEPTED'}
$caught=$false;try{Get-LifecycleGuardKeys 'local' 140}catch{$caught=$true};if(-not$caught){throw 'WRONG_CL_ACCEPTED'}
$t=[IO.File]::ReadAllText($path)
foreach($required in @('sql_variant','major_id=@Id','TYPED_ORIGINAL_NOT_RESTORED','RESTORE_DRIFT','CONVERT(varbinary(max),@Text)=CONVERT(varbinary(max),@Bad)','REGISTRATION_TEXT_TEN_ORIGINALS')){if(-not$t.Contains($required)){throw 'ORACLE_OR_RESTORE_MISSING'}}
if($t-match'(?i)\b(GRANT|DENY|REVOKE)\b|ALTER\s+AUTHORIZATION|CREATE\s+(USER|LOGIN|ASSEMBLY)'){throw 'SCOPE_EXCEEDED'}
'REGISTRATION_TEXT_COUNTEREXAMPLES_PASS'
"""
        r=subprocess.run(['pwsh','-NoProfile','-Command',script],cwd=ROOT,capture_output=True,text=True,timeout=25)
        self.assertEqual(r.returncode,0,r.stdout+r.stderr)

if __name__=='__main__':unittest.main()
