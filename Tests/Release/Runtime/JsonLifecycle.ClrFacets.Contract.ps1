. (Join-Path $PSScriptRoot 'JsonLifecycle.ClrBinding.Contract.ps1')
# Nur Unicode-/Nullable-Facetten; bestehende Namens-/Ordinalfälle werden nicht wiederholt.
function Get-ClrFacetSpecs{
 $p=@('Json','Schema','Profile');$c=@('RowKind','ErrorOrdinal','Status','Profile','IsValid','DocumentPointer','SchemaPointer','Keyword','ErrorCode','ErrorsTruncated')
 for($i=0;$i-lt10;$i++){[pscustomobject]@{group='column-not-null';id=$c[$i];index=$i;scope='c';type=0;length=0;token='';nullable=$false}}
 for($i=0;$i-lt2;$i++){[pscustomobject]@{group='parameter-bounded';id=$p[$i];index=$i;scope='p';type=231;length=8000;token='nvarchar(4000)';nullable=$true}}
 for($i=0;$i-lt3;$i++){[pscustomobject]@{group='parameter-fixed';id=$p[$i];index=$i;scope='p';type=239;length=$(if($i-eq2){64}else{8000});token=$(if($i-eq2){'nchar(32)'}else{'nchar(4000)'});nullable=$true}}
 [pscustomobject]@{group='parameter-length-up';id='Profile';index=2;scope='p';type=231;length=66;token='nvarchar(33)';nullable=$true}
 [pscustomobject]@{group='parameter-max';id='Profile';index=2;scope='p';type=231;length=-1;token='nvarchar(max)';nullable=$true}
 foreach($pair in @(@(0,8),@(2,24),@(3,32),@(7,128),@(8,32))){
  $i=$pair[0];$n=$pair[1]
  [pscustomobject]@{group='column-length-up';id=$c[$i];index=$i;scope='c';type=231;length=(2*($n+1));token=('nvarchar('+($n+1)+')');nullable=$true}
  [pscustomobject]@{group='column-max';id=$c[$i];index=$i;scope='c';type=231;length=-1;token='nvarchar(max)';nullable=$true}
  [pscustomobject]@{group='column-fixed';id=$c[$i];index=$i;scope='c';type=239;length=(2*$n);token=('nchar('+$n+')');nullable=$true}
 }
 foreach($i in @(5,6)){
  [pscustomobject]@{group='column-bounded';id=$c[$i];index=$i;scope='c';type=231;length=8000;token='nvarchar(4000)';nullable=$true}
  [pscustomobject]@{group='column-fixed-pointer';id=$c[$i];index=$i;scope='c';type=239;length=8000;token='nchar(4000)';nullable=$true}
 }
}
function Assert-ClrFacetSpec($Spec){
 $known=@(Get-ClrFacetSpecs|Where-Object{$_.group-ceq$Spec.group-and$_.id-ceq$Spec.id-and$_.index-eq$Spec.index-and$_.scope-ceq$Spec.scope-and$_.type-eq$Spec.type-and$_.length-eq$Spec.length-and$_.token-ceq$Spec.token-and$_.nullable-eq$Spec.nullable})
 if($known.Count-ne1){throw 'CLR_FACETS_EXACT_VECTOR'}
}
function Get-LifecycleGuardKeys([string]$Mode,[int]$CL){
 if($Mode-cnotin@('local','central')-or$CL-notin@(150,160,170)){throw 'CLR_FACETS_EXACT_CONTEXT'}
 foreach($spec in Get-ClrFacetSpecs){if($spec.group-ceq'column-not-null'){$spec.group+'/'+$spec.id+'/engine-denied'}else{foreach($op in @('deploy','uninstall')){$spec.group+'/'+$spec.id+'/'+$op}}}
}
function New-ClrFacetDeclaration([string]$Original,$Spec){
 Assert-ClrFacetSpec $Spec
 $match=[regex]::Match($Original,'(?s)\A(?<lead>ALTER FUNCTION toolbelt_json\.FT_ValidateJsonSchemaInternal\s*)\((?<p>.*?)\)\s*RETURNS TABLE\s*\((?<c>.*?)\)\s*(?<tail>AS EXTERNAL NAME.*)\z')
 if(-not$match.Success){throw 'CLR_FACETS_CANONICAL_HEADER'}
 $p=@($match.Groups['p'].Value.Split(',')|ForEach-Object Trim);$c=@($match.Groups['c'].Value.Split(',')|ForEach-Object Trim)
 if($p.Count-ne8-or$c.Count-ne10){throw 'CLR_FACETS_ORIGINAL_ARITY'}
 if($Spec.group-ceq'column-not-null'){
  if(-not$c[$Spec.index].EndsWith(' NULL',[StringComparison]::Ordinal)){throw 'CLR_FACETS_ORIGINAL_NULL_REQUIRED'}
  $c[$Spec.index]=$c[$Spec.index].Substring(0,$c[$Spec.index].Length-5)+' NOT NULL'
 }else{
  $items=if($Spec.scope-ceq'p'){$p}else{$c}
  $matches=[regex]::Matches($items[$Spec.index],'nvarchar\((?:max|\d+)\)');if($matches.Count-ne1){throw 'CLR_FACETS_SINGLE_TYPE_TOKEN'}
  $items[$Spec.index]=[regex]::Replace($items[$Spec.index],'nvarchar\((?:max|\d+)\)',$Spec.token)
  if($Spec.scope-ceq'p'){$p=$items}else{$c=$items}
 }
 return $match.Groups['lead'].Value+'('+($p-join",`n")+")`nRETURNS TABLE`n("+($c-join",`n")+")`n"+$match.Groups['tail'].Value
}
function Test-ClrFacetCatalog($BeforeP,$BeforeC,$AfterP,$AfterC,$Spec){
 Assert-ClrFacetSpec $Spec
 if($BeforeP.Count-ne8-or$BeforeC.Count-ne10){return $false}
 $p=@($BeforeP|ConvertTo-Json -Depth 4|ConvertFrom-Json);$c=@($BeforeC|ConvertTo-Json -Depth 4|ConvertFrom-Json)
 if($Spec.group-ceq'column-not-null'){$c[$Spec.index].is_nullable=$false}else{
  $items=if($Spec.scope-ceq'p'){$p}else{$c}
  $items[$Spec.index].system_type_id=$Spec.type;$items[$Spec.index].user_type_id=$Spec.type;$items[$Spec.index].max_length=$Spec.length
  if($Spec.scope-ceq'p'){$p=$items}else{$c=$items}
 }
 return [bool](($p|ConvertTo-Json -Depth 4 -Compress)-ceq($AfterP|ConvertTo-Json -Depth 4 -Compress)-and($c|ConvertTo-Json -Depth 4 -Compress)-ceq($AfterC|ConvertTo-Json -Depth 4 -Compress))
}

function Invoke-LifecycleGuardProfiles($Db,[string]$Mode){
 Invoke-ReleaseBatches $Db ([IO.File]::ReadAllText($runset.baselines.$Mode))
 Invoke-ReleaseBatches $Db ([IO.File]::ReadAllText($runset.exports.$Mode))
 $installed=Get-LifecycleGuardState $Db
 $original=Get-ClrBindingOriginal ([IO.File]::ReadAllText((Join-Path $repo 'Modules/toolbelt.json.schema/Source/JsonSchemaBridge.sql')))
 $pSql="SELECT parameter_id,name,system_type_id,user_type_id,max_length,[precision],[scale],is_output FROM sys.parameters WHERE object_id=OBJECT_ID(N'toolbelt_json.FT_ValidateJsonSchemaInternal') ORDER BY parameter_id;"
 $cSql="SELECT column_id,name,system_type_id,user_type_id,max_length,[precision],[scale],is_nullable,collation_name FROM sys.columns WHERE object_id=OBJECT_ID(N'toolbelt_json.FT_ValidateJsonSchemaInternal') ORDER BY column_id;"
 $beforeP=@(Sql $Db $pSql -Rows);$beforeC=@(Sql $Db $cSql -Rows)
 foreach($spec in Get-ClrFacetSpecs){
  if($spec.group-ceq'column-not-null'){
   $message="Cannot use 'NOT NULL' constraint in the result table of a streaming user-defined function (column '"+$spec.id+"')."
   Assert-LifecycleGuardDenied $Db $Mode ($spec.group+'/'+$spec.id+'/engine-denied') (New-ClrFacetDeclaration $original $spec) 6526 $message
   if((Get-LifecycleGuardState $Db)-cne$installed){throw 'CLR_FACETS_ENGINE_DENIAL_MUTATED_STATE'}
   continue
  }
  Invoke-ReleaseBatches $Db (New-ClrFacetDeclaration $original $spec)
  $actualP=@(Sql $Db $pSql -Rows);$actualC=@(Sql $Db $cSql -Rows)
  if(-not(Test-ClrFacetCatalog $beforeP $beforeC $actualP $actualC $spec)){throw 'CLR_FACETS_EXACT_CATALOG_REQUIRED'}
  $damaged=Get-LifecycleGuardState $Db
  try{foreach($op in @('deploy','uninstall')){
   $path=Get-LifecycleGuardScript 'schema' $op $Mode
   Assert-LifecycleGuardDenied $Db $Mode ($spec.group+'/'+$spec.id+'/'+$op) ([IO.File]::ReadAllText($path)) 55633 'JSON Schema lifecycle: CLR-Binding-/Parameters-/Spaltenvertrag inkohärent.'
  }}finally{
   if((Get-LifecycleGuardState $Db)-cne$damaged){throw 'CLR_FACETS_RESTORE_DRIFT'}
   Invoke-ReleaseBatches $Db $original
  }
  if((Get-LifecycleGuardState $Db)-cne$installed){throw 'CLR_FACETS_ORIGINAL_NOT_RESTORED'}
 }
 $actual=@($ledger.profileCompletions|Where-Object mode -CEQ $Mode|ForEach-Object id|Sort-Object)
 if(($actual-join'|')-cne(@(Get-LifecycleGuardKeys $Mode $case.CL|Sort-Object)-join'|')){throw 'CLR_FACETS_MODE_CLOSURE'}
 Invoke-ReleaseBatches $Db ([IO.File]::ReadAllText($runset.uninstall));Assert-CoreLockNeutral $Db
 Invoke-ReleaseBatches $Db ([IO.File]::ReadAllText($runset.core_uninstall));Assert-CoreLockNeutral $Db
}
