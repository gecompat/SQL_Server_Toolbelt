"""New fixture dispatch and exact missing/NULL/visibility closure; reuse admission setup."""
from pathlib import Path
import copy,hashlib,shutil,subprocess,unittest
import test_json_lifecycle_binary_registration_lab_contract as admission

ROOT=Path(__file__).resolve().parents[2]
FIXTURE=ROOT/'Tests/Release/Runtime/JsonLifecycle.ClrBinding.Contract.ps1'

@unittest.skipUnless(shutil.which('pwsh'),'PowerShell 7 required')
class ClrBindingTests(unittest.TestCase):
    def test_new_scope_requires_exact_new_fixture_and_reuses_canonical_preflight(self):
        base=admission.JsonLifecycleGuardAdmissionTests()
        base.setUp()
        try:
            r=copy.deepcopy(base.record)
            r['schema_version']='json-lifecycle-clr-binding/v1'
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

    def test_exact_vectors_source_extraction_and_catalog_negatives(self):
        script="$ErrorActionPreference='Stop';$repo='"+str(ROOT).replace("'","''")+"';$path='"+str(FIXTURE).replace("'","''")+"';"+r"""
$e=$null;$a=[Management.Automation.Language.Parser]::ParseFile($path,[ref]$null,[ref]$e);if($e.Count){throw 'PARSE'}
foreach($name in @('Get-ClrBindingSpecs','Get-LifecycleGuardKeys','Get-ClrBindingOriginal','New-ClrBindingDeclaration','Test-ClrBindingCatalog')){
 $n=@($a.FindAll({param($x)$x-is[Management.Automation.Language.FunctionDefinitionAst]-and$x.Name-ceq$name},$true));if($n.Count-ne1){throw 'FUNCTION'};. ([scriptblock]::Create($n[0].Extent.Text))
}
$source=[IO.File]::ReadAllText((Join-Path $repo 'Modules/toolbelt.json.schema/Source/JsonSchemaBridge.sql'))
$original=Get-ClrBindingOriginal $source
if(-not$original.StartsWith('ALTER FUNCTION toolbelt_json.FT_ValidateJsonSchemaInternal')){throw 'CANONICAL_ALTER'}
$caught=$false;try{Get-ClrBindingOriginal ($source+$source)}catch{$caught=$true};if(-not$caught){throw 'DUPLICATE_DECLARATION_ACCEPTED'}
$specs=@(Get-ClrBindingSpecs);if($specs.Count-ne27){throw 'VECTOR_CLOSURE'}
foreach($cl in @(150,160,170)){foreach($mode in @('local','central')){$keys=@(Get-LifecycleGuardKeys $mode $cl);if($keys.Count-ne54-or@($keys|Select-Object -Unique).Count-ne54){throw 'KEY_CLOSURE'}}}
$pNames=@('Json','Schema','Profile','MaxDocumentBytes','MaxSchemaBytes','MaxDepth','MaxEvaluationSteps','MaxErrors')
$cNames=@('RowKind','ErrorOrdinal','Status','Profile','IsValid','DocumentPointer','SchemaPointer','Keyword','ErrorCode','ErrorsTruncated')
foreach($spec in $specs){
 $changed=New-ClrBindingDeclaration $original $spec
 if($changed-ceq$original-or$changed.Substring($changed.IndexOf('AS EXTERNAL NAME'))-cne$original.Substring($original.IndexOf('AS EXTERNAL NAME'))){throw 'BINDING_TARGET_CHANGED'}
 $beforeP=@(for($i=0;$i-lt8;$i++){[pscustomobject][ordered]@{parameter_id=$i+1;name=('@'+$pNames[$i]);system_type_id=231;user_type_id=231;max_length=64;precision=0;scale=0;is_output=$false}})
 $beforeC=@(for($i=0;$i-lt10;$i++){[pscustomobject][ordered]@{column_id=$i+1;name=$cNames[$i];system_type_id=231;user_type_id=231;max_length=64;precision=0;scale=0;is_nullable=$true;collation_name='ContosoCollation'}})
 $afterP=@($beforeP|ConvertTo-Json|ConvertFrom-Json);$afterC=@($beforeC|ConvertTo-Json|ConvertFrom-Json)
 switch -CaseSensitive($spec.group){
  'parameter-name'{$afterP[$spec.index].name='@'+$spec.id.ToUpperInvariant()}
  'parameter-length'{$afterP[$spec.index].max_length=$spec.length}
  'column-name'{$afterC[$spec.index].name=$spec.id.ToUpperInvariant()}
  'column-length'{$afterC[$spec.index].max_length=$spec.length}
  'column-order'{$saved=$afterC[$spec.index];$afterC[$spec.index]=$afterC[$spec.index+1];$afterC[$spec.index+1]=$saved;for($i=0;$i-lt10;$i++){$afterC[$i].column_id=$i+1}}
 }
 if(-not(Test-ClrBindingCatalog $beforeP $beforeC $afterP $afterC $spec)){throw 'CATALOG_GOLDEN'}
 $afterC[0].is_nullable=$false;if(Test-ClrBindingCatalog $beforeP $beforeC $afterP $afterC $spec){throw 'UNRELATED_COLUMN_CHANGE_ACCEPTED'}
 if(Test-ClrBindingCatalog $beforeP $beforeC $beforeP $beforeC $spec){throw 'NO_CHANGE_ACCEPTED'}
}
$bad=[pscustomobject]@{group='column-length';id='RowKind';index=0;length=999}
$caught=$false;try{New-ClrBindingDeclaration $original $bad}catch{$caught=$true};if(-not$caught){throw 'UNSELECTED_VECTOR_ACCEPTED'}
$text=[IO.File]::ReadAllText($path)
if($text-match'(?i)\b(GRANT|DENY|REVOKE)\b|ALTER\s+AUTHORIZATION|ALTER\s+ASSEMBLY|CREATE\s+TYPE'){throw 'SCOPE_EXCEEDED'}
foreach($required in @('sys.columns','RESTORE_DRIFT','ORIGINAL_NOT_RESTORED')){if(-not$text.Contains($required)){throw 'STATE_OR_RESTORE_MISSING'}}
'CLR_BINDING_COUNTEREXAMPLES_PASS'
"""
        result=subprocess.run(['pwsh','-NoProfile','-Command',script],cwd=ROOT,capture_output=True,text=True,timeout=25)
        self.assertEqual(result.returncode,0,result.stdout+result.stderr)

if __name__=='__main__':unittest.main()
