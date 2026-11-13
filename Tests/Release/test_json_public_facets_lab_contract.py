"""Zwanzig öffentliche Parameterfacetten: Zulassung, Deklarationen und tatsächliche Katalogabweichung."""
from pathlib import Path
import copy,hashlib,shutil,subprocess,unittest
import test_json_lifecycle_binary_registration_lab_contract as admission

ROOT=Path(__file__).resolve().parents[2]
FIXTURE=ROOT/'Tests/Release/Runtime/JsonLifecycle.PublicFacets.Contract.ps1'

@unittest.skipUnless(shutil.which('pwsh'),'PowerShell 7 required')
class PublicFacetsTests(unittest.TestCase):
    def test_new_scope_requires_exact_new_fixture_and_reuses_canonical_preflight(self):
        base=admission.JsonLifecycleGuardAdmissionTests()
        base.setUp()
        try:
            r=copy.deepcopy(base.record)
            r['schema_version']='json-lifecycle-public-facets/v1'
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

    def test_twenty_exact_vectors_body_preservation_and_catalog_negatives(self):
        script="$ErrorActionPreference='Stop';$repo='"+str(ROOT).replace("'","''")+"';$path='"+str(FIXTURE).replace("'","''")+"';"+r"""
$e=$null
foreach($item in @(@{path=(Join-Path $repo 'Tests/Release/Runtime/JsonSchema.DependencySignature.Contract.ps1');names=@('Get-SchemaGuardSignatureCases','New-SchemaGuardSignature')},@{path=$path;names=@('Get-PublicFacetSpecs','Assert-PublicFacetSpec','Get-LifecycleGuardKeys','New-PublicFacetDeclaration','Test-PublicFacetCatalog')})){
 $a=[Management.Automation.Language.Parser]::ParseFile($item.path,[ref]$null,[ref]$e);if($e.Count){throw 'PARSE'}
 foreach($name in $item.names){$n=@($a.FindAll({param($x)$x-is[Management.Automation.Language.FunctionDefinitionAst]-and$x.Name-ceq$name},$true));if($n.Count-ne1){throw 'FUNCTION'};. ([scriptblock]::Create($n[0].Extent.Text))}
}
$specs=@(Get-PublicFacetSpecs);if($specs.Count-ne20-or@($specs.id|Select-Object -Unique).Count-ne20){throw 'TWENTY_CLOSURE'}
foreach($cl in @(150,160,170)){foreach($mode in @('local','central')){$k=@(Get-LifecycleGuardKeys $mode $cl);if($k.Count-ne40-or@($k|Select-Object -Unique).Count-ne40){throw 'KEY_CLOSURE'}}}
$original=[IO.File]::ReadAllText((Join-Path $repo 'Modules/toolbelt.json.schema/Source/USP_ValidateJsonSchema.sql'))
$signature=@(Get-SchemaGuardSignatureCases)
foreach($spec in $specs){
 $changed=New-PublicFacetDeclaration $original $spec
 $boundary=[regex]::Match($original,'(?im)^\s*AS\s*\r?\nBEGIN\b')
 if($changed-ceq$original-or$changed.Substring($changed.Length-($original.Length-$boundary.Index))-cne$original.Substring($boundary.Index)){throw 'BODY_CHANGED'}
 if($changed-cne($original.Substring(0,$boundary.Index).Replace($spec.before,$spec.after)+$original.Substring($boundary.Index))){throw 'OTHER_HEADER_TOKEN_CHANGED'}
 $before=@(for($i=0;$i-lt12;$i++){[pscustomobject][ordered]@{parameter_id=$i+1;name=('@'+$signature[$i].id);system_type_id=56;user_type_id=56;max_length=4;precision=10;scale=0;is_output=$false}})
 # Der Ausgangskatalog bleibt pro Vektor absichtlich anders als die erwartete Zielfacette.
 $before[$spec.index].max_length=1234
 $after=@($before|ConvertTo-Json -Depth 4|ConvertFrom-Json)
 $after[$spec.index].system_type_id=$spec.type;$after[$spec.index].user_type_id=$spec.type;$after[$spec.index].max_length=$spec.length;$after[$spec.index].precision=$spec.precision;$after[$spec.index].scale=$spec.scale
 if(-not(Test-PublicFacetCatalog $before $after $spec)){throw 'EXPECTED_CATALOG_REJECTED'}
 if(Test-PublicFacetCatalog $before $before $spec){throw 'NO_CHANGE_ACCEPTED'}
 $other=($spec.index+1)%12;$after[$other].is_output=$true;if(Test-PublicFacetCatalog $before $after $spec){throw 'UNRELATED_CHANGE_ACCEPTED'}
}
$bad=[pscustomobject]@{id=$specs[0].id;index=$specs[0].index;parameter=$specs[0].parameter;before=$specs[0].before;after='@Json nvarchar(7)';type=231;length=14;precision=0;scale=0}
$caught=$false;try{New-PublicFacetDeclaration $original $bad}catch{$caught=$true};if(-not$caught){throw 'UNSELECTED_VECTOR_ACCEPTED'}
$caught=$false;try{Get-LifecycleGuardKeys 'central' 140}catch{$caught=$true};if(-not$caught){throw 'UNSELECTED_CONTEXT_ACCEPTED'}
$t=[IO.File]::ReadAllText($path)
foreach($required in @('sys.parameters','PUBLIC_FACETS_EXACT_CATALOG_REQUIRED','RESTORE_DRIFT','ORIGINAL_NOT_RESTORED','TWENTY_POINT_CLOSURE')){if(-not$t.Contains($required)){throw 'ORACLE_MISSING'}}
if($t-match'(?i)\b(GRANT|DENY|REVOKE)\b|ALTER\s+AUTHORIZATION|CREATE\s+(USER|LOGIN|TYPE|ASSEMBLY)'){throw 'SCOPE_EXCEEDED'}
'PUBLIC_FACETS_COUNTEREXAMPLES_PASS'
"""
        r=subprocess.run(['pwsh','-NoProfile','-Command',script],cwd=ROOT,capture_output=True,text=True,timeout=25)
        self.assertEqual(r.returncode,0,r.stdout+r.stderr)

if __name__=='__main__':unittest.main()
