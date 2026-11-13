"""Fixturezulassung, geschlossene CLR-Facetten und getrennte Engine-/Lifecycle-Keys."""
from pathlib import Path
import copy,hashlib,shutil,subprocess,unittest
import test_json_lifecycle_binary_registration_lab_contract as admission

ROOT=Path(__file__).resolve().parents[2]
FIXTURE=ROOT/'Tests/Release/Runtime/JsonLifecycle.ClrFacets.Contract.ps1'

@unittest.skipUnless(shutil.which('pwsh'),'PowerShell 7 required')
class ClrFacetsTests(unittest.TestCase):
    def test_new_scope_requires_exact_new_fixture_and_reuses_canonical_preflight(self):
        base=admission.JsonLifecycleGuardAdmissionTests()
        base.setUp()
        try:
            r=copy.deepcopy(base.record)
            r['schema_version']='json-lifecycle-clr-facets/v1'
            r['fixtures']=[str(FIXTURE)]
            r.pop('binary_guards')
            shared=ROOT/'Tests/Release/Runtime/JsonLifecycle.ClrBinding.Contract.ps1'
            r['pins'].append(dict(path=str(shared),sha256=hashlib.sha256(shared.read_bytes()).hexdigest().upper()))
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

    def test_exact_ten_groups_declarations_and_actual_catalog_negatives(self):
        script="$ErrorActionPreference='Stop';$repo='"+str(ROOT).replace("'","''")+"';$path='"+str(FIXTURE).replace("'","''")+"';"+r"""
$e=$null
foreach($entry in @(@{path=(Join-Path $repo 'Tests/Release/Runtime/JsonLifecycle.ClrBinding.Contract.ps1');names=@('Get-ClrBindingOriginal')},@{path=$path;names=@('Get-ClrFacetSpecs','Assert-ClrFacetSpec','Get-LifecycleGuardKeys','New-ClrFacetDeclaration','Test-ClrFacetCatalog')})){
 $a=[Management.Automation.Language.Parser]::ParseFile($entry.path,[ref]$null,[ref]$e);if($e.Count){throw 'PARSE'}
 foreach($name in $entry.names){$n=@($a.FindAll({param($x)$x-is[Management.Automation.Language.FunctionDefinitionAst]-and$x.Name-ceq$name},$true));if($n.Count-ne1){throw 'FUNCTION'};. ([scriptblock]::Create($n[0].Extent.Text))}
}
$source=[IO.File]::ReadAllText((Join-Path $repo 'Modules/toolbelt.json.schema/Source/JsonSchemaBridge.sql'));$original=Get-ClrBindingOriginal $source
$specs=@(Get-ClrFacetSpecs);if($specs.Count-ne36){throw 'VECTOR_CLOSURE'}
foreach($cl in @(150,160,170)){foreach($mode in @('local','central')){
 $keys=@(Get-LifecycleGuardKeys $mode $cl);if($keys.Count-ne62-or@($keys|Select-Object -Unique).Count-ne62){throw 'KEY_CLOSURE'}
 $counts=@($keys|ForEach-Object{$_.Split('/')[0]}|Group-Object|ForEach-Object Count|Sort-Object)
 if(@($keys|Where-Object{$_-like'column-not-null/*/engine-denied'}).Count-ne10-or@($keys|Where-Object{$_-like'column-not-null/*/deploy'-or$_-like'column-not-null/*/uninstall'}).Count){throw 'FICTIONAL_NULLABLE_PUBLIC_KEY'}
 if(($counts-join',')-cne'2,2,4,4,4,6,10,10,10,10'){throw 'TEN_GROUPS'}
}}
$pNames=@('Json','Schema','Profile','MaxDocumentBytes','MaxSchemaBytes','MaxDepth','MaxEvaluationSteps','MaxErrors');$pTypes=@(231,231,231,127,127,56,127,56);$pLengths=@(-1,-1,64,8,8,4,8,4)
$cNames=@('RowKind','ErrorOrdinal','Status','Profile','IsValid','DocumentPointer','SchemaPointer','Keyword','ErrorCode','ErrorsTruncated');$cTypes=@(231,56,231,231,104,231,231,231,231,104);$cLengths=@(16,4,48,64,1,-1,-1,256,64,1)
foreach($spec in $specs){
 $changed=New-ClrFacetDeclaration $original $spec
 if($changed-ceq$original-or$changed.Substring($changed.IndexOf('AS EXTERNAL NAME'))-cne$original.Substring($original.IndexOf('AS EXTERNAL NAME'))){throw 'BINDING_TARGET_CHANGED'}
 $beforeP=@(for($i=0;$i-lt8;$i++){[pscustomobject][ordered]@{parameter_id=$i+1;name=('@'+$pNames[$i]);system_type_id=$pTypes[$i];user_type_id=$pTypes[$i];max_length=$pLengths[$i];precision=0;scale=0;is_output=$false}})
 $beforeC=@(for($i=0;$i-lt10;$i++){[pscustomobject][ordered]@{column_id=$i+1;name=$cNames[$i];system_type_id=$cTypes[$i];user_type_id=$cTypes[$i];max_length=$cLengths[$i];precision=0;scale=0;is_nullable=$true;collation_name='ContosoCollation'}})
 $afterP=@($beforeP|ConvertTo-Json|ConvertFrom-Json);$afterC=@($beforeC|ConvertTo-Json|ConvertFrom-Json)
 if($spec.group-ceq'column-not-null'){$afterC[$spec.index].is_nullable=$false}else{
  $rows=if($spec.scope-ceq'p'){$afterP}else{$afterC}
  $rows[$spec.index].system_type_id=$spec.type;$rows[$spec.index].user_type_id=$spec.type;$rows[$spec.index].max_length=$spec.length
  if($spec.scope-ceq'p'){$afterP=$rows}else{$afterC=$rows}
 }
 if(-not(Test-ClrFacetCatalog $beforeP $beforeC $afterP $afterC $spec)){throw 'CATALOG_EXPECTED_CHANGE_REJECTED'}
 if(Test-ClrFacetCatalog $beforeP $beforeC $beforeP $beforeC $spec){throw 'NO_CHANGE_ACCEPTED'}
 $afterP[7].name='@ContosoUnrelated';if(Test-ClrFacetCatalog $beforeP $beforeC $afterP $afterC $spec){throw 'UNRELATED_CHANGE_ACCEPTED'}
}
$bad=[pscustomobject]@{group='column-not-null';id='RowKind';index=0;scope='c';type=0;length=999;token='';nullable=$false}
$caught=$false;try{New-ClrFacetDeclaration $original $bad}catch{$caught=$true};if(-not$caught){throw 'UNSELECTED_VECTOR_ACCEPTED'}
$text=[IO.File]::ReadAllText($path)
if($text-match'(?i)\b(GRANT|DENY|REVOKE)\b|ALTER\s+AUTHORIZATION|ALTER\s+ASSEMBLY|CREATE\s+TYPE'){throw 'SCOPE_EXCEEDED'}
foreach($required in @('sys.columns','RESTORE_DRIFT','ORIGINAL_NOT_RESTORED','CLR_FACETS_EXACT_CATALOG_REQUIRED','CLR_FACETS_ENGINE_DENIAL_MUTATED_STATE','6526')){if(-not$text.Contains($required)){throw 'STATE_OR_RESTORE_MISSING'}}
'CLR_FACET_COUNTEREXAMPLES_PASS'
"""
        r=subprocess.run(['pwsh','-NoProfile','-Command',script],cwd=ROOT,capture_output=True,text=True,timeout=25)
        self.assertEqual(r.returncode,0,r.stdout+r.stderr)

if __name__=='__main__':unittest.main()
