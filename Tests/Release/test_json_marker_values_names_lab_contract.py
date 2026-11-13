"""New fixture dispatch and exact missing/NULL/visibility closure; reuse admission setup."""
from pathlib import Path
import copy,hashlib,shutil,subprocess,unittest
import test_json_lifecycle_binary_registration_lab_contract as admission

ROOT=Path(__file__).resolve().parents[2]
FIXTURE=ROOT/'Tests/Release/Runtime/JsonLifecycle.MarkerValuesNames.Contract.ps1'

@unittest.skipUnless(shutil.which('pwsh'),'PowerShell 7 required')
class ValueNamesTests(unittest.TestCase):
    def test_new_scope_requires_exact_new_fixture_and_reuses_canonical_preflight(self):
        base=admission.JsonLifecycleGuardAdmissionTests()
        base.setUp()
        try:
            r=copy.deepcopy(base.record)
            r['schema_version']='json-lifecycle-marker-values-names/v1'
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

    def test_keys_header_only_transform_and_actual_catalog_counterexamples(self):
        script="$ErrorActionPreference='Stop';$repo='"+str(ROOT).replace("'","''")+"';$path='"+str(FIXTURE).replace("'","''")+"';"+r"""
$e=$null
foreach($entry in @(@{path=(Join-Path $repo 'Tests/Release/Runtime/JsonSchema.DependencySignature.Contract.ps1');names=@('Get-SchemaGuardSignatureCases','New-SchemaGuardSignature')},@{path=$path;names=@('Get-LifecycleGuardKeys','New-ValueNameSignature','Test-ValueNameCatalog')})){
 $a=[Management.Automation.Language.Parser]::ParseFile($entry.path,[ref]$null,[ref]$e);if($e.Count){throw 'PARSE'}
 foreach($name in $entry.names){$n=@($a.FindAll({param($x)$x-is[Management.Automation.Language.FunctionDefinitionAst]-and$x.Name-ceq$name},$true));if($n.Count-ne1){throw 'FUNCTION'};. ([scriptblock]::Create($n[0].Extent.Text))}
}
foreach($cl in @(150,160,170)){foreach($mode in @('local','central')){
 $keys=@(Get-LifecycleGuardKeys $mode $cl);if($keys.Count-ne56-or@($keys|Select-Object -Unique).Count-ne56){throw 'EXACT_CLOSURE'}
}}
$specs=@(Get-SchemaGuardSignatureCases)
$original="CREATE OR ALTER PROCEDURE dbo.Contoso`n"+(@($specs|ForEach-Object before)-join",`n")+"`nAS`nBEGIN`n SELECT N'@Json';`nEND;"
foreach($spec in $specs){
 $changed=New-ValueNameSignature $original $spec
 if($changed-ceq$original-or$changed.Substring($changed.IndexOf("AS`nBEGIN"))-cne$original.Substring($original.IndexOf("AS`nBEGIN"))){throw 'BODY_CHANGED'}
 $before=@(for($i=0;$i-lt12;$i++){[pscustomobject]@{parameter_id=$i+1;name=('@'+$specs[$i].id);system_type_id=56;user_type_id=56;max_length=4;precision=10;scale=0;is_output=0}})
 $after=$before|ConvertTo-Json|ConvertFrom-Json
 $index=[array]::IndexOf(@($specs|ForEach-Object id),$spec.id);$after[$index].name='@'+$spec.id.ToUpperInvariant()
 if(-not(Test-ValueNameCatalog $before $after $spec.id)){throw 'CATALOG_GOLDEN'}
 $after[$index].max_length=8;if(Test-ValueNameCatalog $before $after $spec.id){throw 'TYPE_DRIFT_ACCEPTED'}
 $after[$index].max_length=4;$after[$index].name='@ContosoWrong';if(Test-ValueNameCatalog $before $after $spec.id){throw 'OTHER_NAME_ACCEPTED'}
 if(Test-ValueNameCatalog $before $before $spec.id){throw 'NO_CHANGE_ACCEPTED'}
}
$text=[IO.File]::ReadAllText($path)
foreach($required in @('BaseType','MaxLength','DATALENGTH(@V)<>DATALENGTH(@Bad)','#ValueNamesOriginals',"REPLICATE('0',64)",'CONVERT(binary(64),0x00)')){if(-not$text.Contains($required)){throw 'VALUE_SHAPE_OR_TYPED_RESTORE_MISSING'}}
if($text-match'(?i)ALTER\s+AUTHORIZATION|\b(GRANT|DENY|REVOKE)\b|ALTER\s+ASSEMBLY'){throw 'FIXTURE_EXCEEDS_SCOPE'}
'VALUE_NAMES_ORACLES_PASS'
"""
        result=subprocess.run(['pwsh','-NoProfile','-Command',script],cwd=ROOT,capture_output=True,text=True,timeout=25)
        self.assertEqual(result.returncode,0,result.stdout+result.stderr)

if __name__=='__main__':unittest.main()
