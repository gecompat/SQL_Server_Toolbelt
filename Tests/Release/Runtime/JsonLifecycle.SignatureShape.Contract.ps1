. (Join-Path $PSScriptRoot 'JsonLifecycle.BinaryRegistration.Contract.ps1')
foreach($block in Import-ClrFunctions (Join-Path $PSScriptRoot 'JsonSchema.DependencySignature.Contract.ps1') @('Get-SchemaGuardState','Get-SchemaGuardSignatureCases','ConvertTo-SchemaGuardAlterCommand')){. $block}
function Get-LifecycleGuardState($Db){
 $types=@(Sql $Db "SELECT user_type_id,system_type_id,name,schema_id,principal_id,max_length,[precision],[scale],is_nullable,is_user_defined,is_assembly_type,collation_name FROM sys.types WHERE schema_id=SCHEMA_ID(N'dbo') AND name LIKE N'ContosoSignature[_]%' ORDER BY name;" -Rows)
 return ([ordered]@{baseline=(Get-SchemaGuardState $Db);fixtureTypes=@($types)}|ConvertTo-Json -Depth 7 -Compress)
}
function Get-SignatureShapeSpecs{
 $original=@(Get-SchemaGuardSignatureCases)
 foreach($group in @('output','alias','missing')){for($i=0;$i-lt12;$i++){[pscustomobject]@{group=$group;id=$original[$i].id;index=$i;aliasId=0}}}
 for($i=0;$i-lt11;$i++){[pscustomobject]@{group='order';id=($original[$i].id+'-'+$original[$i+1].id);index=$i;aliasId=0}}
 [pscustomobject]@{group='extra';id='ContosoExtra';index=12;aliasId=0}
}
function Get-LifecycleGuardKeys([string]$Mode,[int]$CL){
 if($Mode-cnotin@('local','central')-or$CL-notin@(150,160,170)){throw 'SIGNATURE_SHAPE_EXACT_CONTEXT'}
 foreach($spec in Get-SignatureShapeSpecs){foreach($op in @('deploy','uninstall')){$spec.group+'/'+$spec.id+'/'+$op}}
}
function New-SignatureShape([string]$Original,$Spec){
 $known=@(Get-SignatureShapeSpecs|Where-Object{$_.group-ceq$Spec.group-and$_.id-ceq$Spec.id-and$_.index-eq$Spec.index})
 if($known.Count-ne1){throw 'SIGNATURE_SHAPE_EXACT_VECTOR'}
 $boundary=[regex]::Match($Original,'(?im)^\s*AS\s*\r?\nBEGIN\b')
 $declaration=[regex]::Match($Original,'(?im)^\s*(?:CREATE(?:\s+OR\s+ALTER)?|ALTER)\s+PROCEDURE[^\r\n]*\r?\n')
 if(-not$boundary.Success-or-not$declaration.Success){throw 'SIGNATURE_SHAPE_HEADER_REQUIRED'}
 $start=$declaration.Index+$declaration.Length
 $lines=@($Original.Substring($start,$boundary.Index-$start)-split'\r?\n'|Where-Object{$_.Trim()}|ForEach-Object{$_.Trim().TrimEnd(',')})
 $specs=@(Get-SchemaGuardSignatureCases)
 if($lines.Count-ne12){throw 'SIGNATURE_SHAPE_ORIGINAL_ARITY'}
 for($i=0;$i-lt12;$i++){if(-not$lines[$i].StartsWith($specs[$i].before+'=',[StringComparison]::Ordinal)){throw 'SIGNATURE_SHAPE_EXACT_ORIGINAL_HEADER'}}
 $body=$Original.Substring($boundary.Index)
 switch -CaseSensitive($Spec.group){
  'output'{$lines[$Spec.index]+=' OUTPUT'}
  'alias'{$lines[$Spec.index]='@'+$Spec.id+' dbo.[ContosoSignature_'+$Spec.id+']'+$lines[$Spec.index].Substring($specs[$Spec.index].before.Length)}
  'order'{$saved=$lines[$Spec.index];$lines[$Spec.index]=$lines[$Spec.index+1];$lines[$Spec.index+1]=$saved}
  'extra'{$lines+=@('@ContosoExtra int=0')}
  'missing'{
   $removed=$lines[$Spec.index];$lines=@(for($i=0;$i-lt12;$i++){if($i-ne$Spec.index){$lines[$i]}})
   $begin=[regex]::Match($body,'(?im)^\s*BEGIN\b');$pos=$begin.Index+$begin.Length
   $body=$body.Substring(0,$pos)+"`n DECLARE "+$removed+';'+$body.Substring($pos)
  }
 }
 return $Original.Substring(0,$start)+($lines-join",`n")+"`n"+$body
}
function Test-SignatureShapeCatalog($Before,$After,$Spec){
 if($Before.Count-ne12){return $false}
 $expected=@($Before|ConvertTo-Json -Depth 4|ConvertFrom-Json)
 switch -CaseSensitive($Spec.group){
  'output'{$expected[$Spec.index].is_output=$true}
  'alias'{if($Spec.aliasId-le256){return $false};$expected[$Spec.index].user_type_id=$Spec.aliasId}
  'order'{$saved=$expected[$Spec.index];$expected[$Spec.index]=$expected[$Spec.index+1];$expected[$Spec.index+1]=$saved}
  'missing'{$expected=@(for($i=0;$i-lt12;$i++){if($i-ne$Spec.index){$expected[$i]}})}
  'extra'{$expected+=@([pscustomobject][ordered]@{parameter_id=13;name='@ContosoExtra';system_type_id=56;user_type_id=56;max_length=4;precision=10;scale=0;is_output=$false})}
  default{return $false}
 }
 for($i=0;$i-lt$expected.Count;$i++){$expected[$i].parameter_id=$i+1}
 return [bool](($expected|ConvertTo-Json -Depth 4 -Compress)-ceq($After|ConvertTo-Json -Depth 4 -Compress))
}
function Invoke-LifecycleGuardProfiles($Db,[string]$Mode){
 Invoke-ReleaseBatches $Db ([IO.File]::ReadAllText($runset.baselines.$Mode))
 Invoke-ReleaseBatches $Db ([IO.File]::ReadAllText($runset.exports.$Mode))
 Invoke-ReleaseBatches $Db ([IO.File]::ReadAllText($runset.exports.$Mode))
 $installed=Get-LifecycleGuardState $Db
 $original=[string](Read-ShapeScalar $Db "SELECT OBJECT_DEFINITION(OBJECT_ID(N'toolbelt_json.USP_ValidateJsonSchema')) ScalarValue;")
 $ledger.definitionSnapshots+=@(@{mode=$Mode;scope='owned-public-procedure';definition=$original});Save-ReleaseJournal
 $catalog="SELECT parameter_id,name,system_type_id,user_type_id,max_length,[precision],[scale],is_output FROM sys.parameters WHERE object_id=OBJECT_ID(N'toolbelt_json.USP_ValidateJsonSchema') ORDER BY parameter_id;"
 $before=@(Sql $Db $catalog -Rows)
 foreach($spec in Get-SignatureShapeSpecs){
  if(($Mode+'/'+$spec.group+'/'+$spec.id+'/deploy')-cin$script:lifecycleGuardExcluded){continue}
  $aliasShape=$null
  if($spec.group-ceq'alias'){
   $type=(@(Get-SchemaGuardSignatureCases)[$spec.index].before -split' ',2)[1]
   if($type-ceq'sysname'){$type='nvarchar(128)'}
   $name='ContosoSignature_'+$spec.id
   if([int](Read-ShapeScalar $Db "SELECT COUNT(*) ScalarValue FROM sys.types WHERE schema_id=SCHEMA_ID(N'dbo') AND name=@Name;" @{'@Name'=$name})-ne0){throw 'SIGNATURE_SHAPE_ALIAS_COLLISION'}
   Sql $Db ('CREATE TYPE dbo.['+$name+'] FROM '+$type+' NULL;')
   $spec.aliasId=[int](Read-ShapeScalar $Db 'SELECT TYPE_ID(@Name) ScalarValue;' @{'@Name'=('dbo.'+$name)})
   if($spec.aliasId-le256){throw 'SIGNATURE_SHAPE_OWN_ALIAS_REQUIRED'}
   $aliasShape=Get-LifecycleGuardState $Db
  }
  $ready=Get-LifecycleGuardState $Db
  $changed=New-SignatureShape $original $spec
  Invoke-ReleaseBatches $Db (ConvertTo-SchemaGuardAlterCommand $changed)
  $actual=@(Sql $Db $catalog -Rows)
  if(-not(Test-SignatureShapeCatalog $before $actual $spec)){throw 'SIGNATURE_SHAPE_EXACT_CATALOG_REQUIRED'}
  $damaged=Get-LifecycleGuardState $Db
  try{foreach($op in @('deploy','uninstall')){
   $path=Get-LifecycleGuardScript 'schema' $op $Mode
   Assert-LifecycleGuardDenied $Db $Mode ($spec.group+'/'+$spec.id+'/'+$op) ([IO.File]::ReadAllText($path)) 55633 'JSON Schema lifecycle: öffentliche Parametersignatur inkohärent.'
  }}finally{
   if((Get-LifecycleGuardState $Db)-cne$damaged){throw 'SIGNATURE_SHAPE_RESTORE_DRIFT'}
   Invoke-ReleaseBatches $Db (ConvertTo-SchemaGuardAlterCommand $original)
  }
  if((Get-LifecycleGuardState $Db)-cne$ready){throw 'SIGNATURE_SHAPE_ORIGINAL_NOT_RESTORED'}
  if($spec.group-ceq'alias'){
   if((Get-LifecycleGuardState $Db)-cne$aliasShape-or[int](Read-ShapeScalar $Db 'SELECT TYPE_ID(@Name) ScalarValue;' @{'@Name'=('dbo.'+$name)})-ne$spec.aliasId){throw 'SIGNATURE_SHAPE_ALIAS_IDENTITY_DRIFT'}
   if([int](Read-ShapeScalar $Db 'SELECT COUNT(*) ScalarValue FROM sys.parameter_type_usages WHERE user_type_id=@Id;' @{'@Id'=$spec.aliasId})-ne0){throw 'SIGNATURE_SHAPE_ALIAS_STILL_REFERENCED'}
   Sql $Db ('DROP TYPE dbo.['+$name+'];')
  }
  if((Get-LifecycleGuardState $Db)-cne$installed){throw 'SIGNATURE_SHAPE_FINAL_BASELINE_DRIFT'}
 }
 $actualKeys=@($ledger.profileCompletions|Where-Object mode -CEQ $Mode|ForEach-Object id|Sort-Object)
 if(($actualKeys-join'|')-cne(@(Get-LifecycleGuardKeys $Mode $case.CL|Where-Object{($Mode+'/'+$_)-cnotin$script:lifecycleGuardExcluded}|Sort-Object)-join'|')){throw 'SIGNATURE_SHAPE_MODE_CLOSURE'}
 Invoke-ReleaseBatches $Db ([IO.File]::ReadAllText($runset.uninstall));Assert-CoreLockNeutral $Db
 Invoke-ReleaseBatches $Db ([IO.File]::ReadAllText($runset.core_uninstall));Assert-CoreLockNeutral $Db
}

function Read-ShapeScalar($Db,[string]$Text,[hashtable]$Parameters=@{}){
 $rows=@(Sql $Db $Text $Parameters -Rows)
 if($rows.Count-ne1){throw 'SIGNATURE_SHAPE_SCALAR_ROW_REQUIRED'}
 return $rows[0].ScalarValue
}

function Get-SignatureShapeReusedKeys{
 if(-not$runset.PSObject.Properties['reuse']){return}
 if($CaseIndex-ne0){return}
 $reuse=$runset.reuse
 foreach($binding in @($reuse.journal,$reuse.audit,$reuse.runset)){
  [void](Assert-ReleasePrivatePath $binding.path);Assert-ReleasePin $binding.path $binding.sha256
  if(@($runset.pins|Where-Object{$_.path-ceq$binding.path-and$_.sha256-ceq$binding.sha256}).Count-ne1){throw 'SIGNATURE_SHAPE_REUSE_PIN'}
 }
 $old=Get-Content $reuse.journal.path -Raw|ConvertFrom-Json -DateKind String
 $audit=Get-Content $reuse.audit.path -Raw|ConvertFrom-Json -DateKind String
 $prior=Get-Content $reuse.runset.path -Raw|ConvertFrom-Json -DateKind String
 if($old.state-cne'FAILED_CLEANED'-or$audit.state-cne'COMPLETE'-or$audit.originalRunPassed-ne$false-or$audit.originalJournalSHA256-cne$reuse.journal.sha256-or-not$audit.databaseAbsence-or-not$audit.serverConfigurationAndTrustUnchanged-or-not$audit.postPins){throw 'SIGNATURE_SHAPE_REUSE_FRESH_CLEANUP'}
 if($prior.contract_sha256-cne$runset.contract_sha256){throw 'SIGNATURE_SHAPE_REUSE_LAB_DRIFT'}
 foreach($field in @('Platform','Version','Patch','CL')){if($prior.cases[0].$field-cne$runset.cases[0].$field){throw 'SIGNATURE_SHAPE_REUSE_CONTEXT_DRIFT'}}
 foreach($pin in @($prior.pins|Where-Object{$_.path.StartsWith((Join-Path $repo 'Modules')+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)-or$_.path-ceq(Join-Path $repo 'Tests/Release/Runtime/JsonLifecycle.BinaryRegistration.Contract.ps1')})){
  Assert-ReleasePin $pin.path $pin.sha256
  if(@($runset.pins|Where-Object{$_.path-ceq$pin.path-and$_.sha256-ceq$pin.sha256}).Count-ne1){throw 'SIGNATURE_SHAPE_REUSE_PRODUCT_OR_ORACLE_DRIFT'}
 }
 $caps=@($prior.source_capsules|Where-Object originalPath -CEQ (Join-Path $repo 'Tests/Release/Runtime/JsonLifecycle.SignatureShape.Contract.ps1'))
 if($caps.Count-ne1){throw 'SIGNATURE_SHAPE_REUSE_SOURCE_CAPSULE'}
 [void](Assert-ReleasePrivatePath $caps[0].snapshotPath);Assert-ReleasePin $caps[0].snapshotPath $caps[0].sha256
 $errors=$null;$oldAst=[Management.Automation.Language.Parser]::ParseFile($caps[0].snapshotPath,[ref]$null,[ref]$errors);if($errors.Count){throw 'SIGNATURE_SHAPE_REUSE_OLD_PARSE'}
 $newAst=[Management.Automation.Language.Parser]::ParseFile((Join-Path $repo 'Tests/Release/Runtime/JsonLifecycle.SignatureShape.Contract.ps1'),[ref]$null,[ref]$errors);if($errors.Count){throw 'SIGNATURE_SHAPE_REUSE_NEW_PARSE'}
 foreach($name in @('Get-SignatureShapeSpecs','New-SignatureShape','Test-SignatureShapeCatalog','Get-LifecycleGuardState')){
  $left=@($oldAst.FindAll({param($n)$n-is[Management.Automation.Language.FunctionDefinitionAst]-and$n.Name-ceq$name},$true));$right=@($newAst.FindAll({param($n)$n-is[Management.Automation.Language.FunctionDefinitionAst]-and$n.Name-ceq$name},$true))
  if($left.Count-ne1-or$right.Count-ne1-or$left[0].Extent.Text.Replace("`r`n","`n")-cne$right[0].Extent.Text.Replace("`r`n","`n")){throw 'SIGNATURE_SHAPE_REUSE_ORACLE_CHANGED'}
 }
 $expected=@(Get-LifecycleGuardKeys 'local' $case.CL|Where-Object{$_.StartsWith('output/',[StringComparison]::Ordinal)}|ForEach-Object{'local/'+$_}|Sort-Object)
 if(-not(Test-SignatureShapePrefix $old.profileCompletions)){throw 'SIGNATURE_SHAPE_REUSE_EXACT_PREFIX'}
 return $expected
}

function Test-SignatureShapePrefix($Rows){
 $expected=@(Get-LifecycleGuardKeys 'local' $case.CL|Where-Object{$_.StartsWith('output/',[StringComparison]::Ordinal)}|ForEach-Object{'local/'+$_}|Sort-Object)
 $actual=@($Rows|ForEach-Object{$_.mode+'/'+$_.id}|Sort-Object)
 return [bool]($actual.Count-eq24-and($actual-join'|')-ceq($expected-join'|')-and@($Rows|Where-Object{-not$_.passed-or-not$_.snapshotPreserved}).Count-eq0)
}
