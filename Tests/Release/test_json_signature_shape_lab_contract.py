"""New fixture dispatch and exact missing/NULL/visibility closure; reuse admission setup."""
from pathlib import Path
import copy,hashlib,shutil,subprocess,unittest
import test_json_lifecycle_binary_registration_lab_contract as admission

ROOT=Path(__file__).resolve().parents[2]
FIXTURE=ROOT/'Tests/Release/Runtime/JsonLifecycle.SignatureShape.Contract.ps1'

@unittest.skipUnless(shutil.which('pwsh'),'PowerShell 7 required')
class SignatureShapeTests(unittest.TestCase):
    def test_new_scope_requires_exact_new_fixture_and_reuses_canonical_preflight(self):
        base=admission.JsonLifecycleGuardAdmissionTests()
        base.setUp()
        try:
            r=copy.deepcopy(base.record)
            r['schema_version']='json-lifecycle-signature-shape/v1'
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

    def test_exact_shape_vectors_and_header_transforms(self):
        script="$ErrorActionPreference='Stop';$repo='"+str(ROOT).replace("'","''")+"';$path='"+str(FIXTURE).replace("'","''")+"';"+r"""
$e=$null
foreach($entry in @(@{path=(Join-Path $repo 'Tests/Release/Runtime/JsonSchema.DependencySignature.Contract.ps1');names=@('Get-SchemaGuardSignatureCases')},@{path=$path;names=@('Get-SignatureShapeSpecs','Get-LifecycleGuardKeys','New-SignatureShape','Test-SignatureShapeCatalog','Read-ShapeScalar','Test-SignatureShapePrefix')})){
 $a=[Management.Automation.Language.Parser]::ParseFile($entry.path,[ref]$null,[ref]$e);if($e.Count){throw 'PARSE'}
 foreach($name in $entry.names){$n=@($a.FindAll({param($x)$x-is[Management.Automation.Language.FunctionDefinitionAst]-and$x.Name-ceq$name},$true));if($n.Count-ne1){throw 'FUNCTION'};. ([scriptblock]::Create($n[0].Extent.Text))}
}
$original=[IO.File]::ReadAllText((Join-Path $repo 'Modules/toolbelt.json.schema/Source/USP_ValidateJsonSchema.sql'))
$names=@(Get-SchemaGuardSignatureCases|ForEach-Object id)
foreach($cl in @(150,160,170)){foreach($mode in @('local','central')){$keys=@(Get-LifecycleGuardKeys $mode $cl);if($keys.Count-ne96-or@($keys|Select-Object -Unique).Count-ne96){throw 'KEY_CLOSURE'}}}
$specs=@(Get-SignatureShapeSpecs);if($specs.Count-ne48){throw 'VECTOR_CLOSURE'}
foreach($spec in $specs){
 $changed=New-SignatureShape $original $spec
 if($changed-ceq$original){throw 'NO_CHANGE'}
 $oldBoundary=[regex]::Match($original,'(?im)^\s*AS\s*\r?\nBEGIN\b');$newBoundary=[regex]::Match($changed,'(?im)^\s*AS\s*\r?\nBEGIN\b')
 $oldTail=$original.Substring($oldBoundary.Index+$oldBoundary.Length);$newTail=$changed.Substring($newBoundary.Index+$newBoundary.Length)
 if($spec.group-ceq'missing'){
  $line=[regex]::Match($original,'(?im)^\s*'+[regex]::Escape('@'+$spec.id)+'\s+[^\r\n]+').Value.Trim().TrimEnd(',')
  if($newTail-cne("`n DECLARE "+$line+';'+$oldTail)){throw 'MISSING_BODY_CHANGED_BEYOND_LOCAL_DECLARATION'}
 }elseif($newTail-cne$oldTail){throw 'UNRELATED_BODY_CHANGED'}

 $before=@(for($i=0;$i-lt12;$i++){[pscustomobject][ordered]@{parameter_id=$i+1;name=('@'+$names[$i]);system_type_id=56;user_type_id=56;max_length=4;precision=10;scale=0;is_output=$false}})
 $after=@($before|ConvertTo-Json|ConvertFrom-Json)
 switch -CaseSensitive($spec.group){
  'output'{$after[$spec.index].is_output=$true;if($changed-notmatch' OUTPUT'){throw 'OUTPUT_HEADER'}}
  'alias'{$spec.aliasId=999;$after[$spec.index].user_type_id=999;if($changed-notmatch' dbo.\[ContosoSignature_'){throw 'ALIAS_HEADER'}}
  'missing'{$after=@(for($i=0;$i-lt12;$i++){if($i-ne$spec.index){$after[$i]}});if(-not$changed.Contains('DECLARE @'+$spec.id+' ')){throw 'LOCAL_DECLARATION_REQUIRED'}}
  'order'{$saved=$after[$spec.index];$after[$spec.index]=$after[$spec.index+1];$after[$spec.index+1]=$saved}
  'extra'{$after+=@([pscustomobject][ordered]@{parameter_id=13;name='@ContosoExtra';system_type_id=56;user_type_id=56;max_length=4;precision=10;scale=0;is_output=$false})}
 }
 for($i=0;$i-lt$after.Count;$i++){$after[$i].parameter_id=$i+1}
 if(-not(Test-SignatureShapeCatalog $before $after $spec)){throw 'CATALOG_GOLDEN'}
 $after[0].scale=99;if(Test-SignatureShapeCatalog $before $after $spec){throw 'OTHER_SHAPE_CHANGE_ACCEPTED'}
 if(Test-SignatureShapeCatalog $before $before $spec){throw 'NO_CATALOG_CHANGE_ACCEPTED'}
}
$text=[IO.File]::ReadAllText($path)
if($text-match'(?i)\b(GRANT|DENY|REVOKE|sp_addtype)\b|ALTER\s+AUTHORIZATION|ALTER\s+ASSEMBLY'){throw 'SCOPE_EXCEEDED'}
foreach($required in @('sys.parameter_type_usages','ALIAS_IDENTITY_DRIFT','CREATE TYPE dbo.','DROP TYPE dbo.','ORIGINAL_NOT_RESTORED')){if(-not$text.Contains($required)){throw 'OWNED_ALIAS_OR_RESTORE_GUARD_MISSING'}}
$expectedParameters=@{'@Name'='dbo.ContosoFixture'}
function Sql($Db,$Text,$Parameters,[switch]$Rows){
 if(-not[object]::ReferenceEquals($Parameters,$expectedParameters)-or-not$Rows-or$Text-cne'SELECT TYPE_ID(@Name) ScalarValue;'){throw 'PARAMETERS_NOT_FORWARDED'}
 [pscustomobject]@{ScalarValue=777}
}
if((Read-ShapeScalar $null 'SELECT TYPE_ID(@Name) ScalarValue;' $expectedParameters)-ne777){throw 'SCALAR_VALUE_LOST'}
$case=[pscustomobject]@{CL=150}
$prefix=@(Get-LifecycleGuardKeys 'local' 150|Where-Object{$_.StartsWith('output/')}|ForEach-Object{[pscustomobject]@{mode='local';id=$_;passed=$true;snapshotPreserved=$true}})
if(-not(Test-SignatureShapePrefix $prefix)){throw 'PREFIX_GOLDEN'}
if(Test-SignatureShapePrefix @($prefix+$prefix[0])){throw 'PREFIX_DUPLICATE_ACCEPTED'}
if(Test-SignatureShapePrefix @($prefix[1..23])){throw 'PREFIX_MISSING_ACCEPTED'}
$prefix[0].passed=$false;if(Test-SignatureShapePrefix $prefix){throw 'PREFIX_FAILED_ACCEPTED'}
'ALL_SHAPE_COUNTEREXAMPLES_PASS'
"""
        result=subprocess.run(['pwsh','-NoProfile','-Command',script],cwd=ROOT,capture_output=True,text=True,timeout=25)
        self.assertEqual(result.returncode,0,result.stdout+result.stderr)

if __name__=='__main__':unittest.main()
