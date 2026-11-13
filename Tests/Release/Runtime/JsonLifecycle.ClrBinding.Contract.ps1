. (Join-Path $PSScriptRoot 'JsonLifecycle.BinaryRegistration.Contract.ps1')
foreach($block in Import-ClrFunctions (Join-Path $PSScriptRoot 'JsonSchema.DependencySignature.Contract.ps1') @('Get-SchemaGuardState')){. $block}
function Get-LifecycleGuardState($Db){
 $columns=@(Sql $Db "SELECT object_id,column_id,name,system_type_id,user_type_id,max_length,[precision],[scale],is_nullable,collation_name FROM sys.columns WHERE object_id=OBJECT_ID(N'toolbelt_json.FT_ValidateJsonSchemaInternal') ORDER BY column_id;" -Rows)
 return ([ordered]@{baseline=(Get-SchemaGuardState $Db);returnColumns=@($columns)}|ConvertTo-Json -Depth 7 -Compress)
}
function Get-ClrBindingSpecs{
 $parameters=@('Json','Schema','Profile','MaxDocumentBytes','MaxSchemaBytes','MaxDepth','MaxEvaluationSteps','MaxErrors')
 $columns=@('RowKind','ErrorOrdinal','Status','Profile','IsValid','DocumentPointer','SchemaPointer','Keyword','ErrorCode','ErrorsTruncated')
 for($i=0;$i-lt8;$i++){[pscustomobject]@{group='parameter-name';id=$parameters[$i];index=$i;length=0}}
 [pscustomobject]@{group='parameter-length';id='Profile';index=2;length=62}
 for($i=0;$i-lt10;$i++){[pscustomobject]@{group='column-name';id=$columns[$i];index=$i;length=0}}
 foreach($pair in @(@(0,14),@(2,46),@(3,62),@(7,254),@(8,62))){[pscustomobject]@{group='column-length';id=$columns[$pair[0]];index=$pair[0];length=$pair[1]}}
 foreach($i in @(2,5,7)){[pscustomobject]@{group='column-order';id=($columns[$i]+'-'+$columns[$i+1]);index=$i;length=0}}
}
function Get-LifecycleGuardKeys([string]$Mode,[int]$CL){
 if($Mode-cnotin@('local','central')-or$CL-notin@(150,160,170)){throw 'CLR_BINDING_EXACT_CONTEXT'}
 foreach($spec in Get-ClrBindingSpecs){foreach($op in @('deploy','uninstall')){$spec.group+'/'+$spec.id+'/'+$op}}
}
function Get-ClrBindingOriginal([string]$Source){
 $matches=[regex]::Matches($Source,"(?s)EXEC\s+sys\.sp_executesql\s+N'(?<sql>(?:''|[^'])*)';")
 if($matches.Count-ne1){throw 'CLR_BINDING_SINGLE_CANONICAL_DECLARATION'}
 $sql=$matches[0].Groups['sql'].Value.Replace("''","'")
 if(-not$sql.StartsWith('CREATE FUNCTION toolbelt_json.FT_ValidateJsonSchemaInternal',[StringComparison]::Ordinal)){throw 'CLR_BINDING_KNOWN_SLOT_REQUIRED'}
 return 'ALTER'+$sql.Substring(6)
}
function New-ClrBindingDeclaration([string]$Original,$Spec){
 $known=@(Get-ClrBindingSpecs|Where-Object{$_.group-ceq$Spec.group-and$_.id-ceq$Spec.id-and$_.index-eq$Spec.index-and$_.length-eq$Spec.length})
 if($known.Count-ne1){throw 'CLR_BINDING_EXACT_VECTOR'}
 $match=[regex]::Match($Original,'(?s)\A(?<lead>ALTER FUNCTION toolbelt_json\.FT_ValidateJsonSchemaInternal\s*)\((?<p>.*?)\)\s*RETURNS TABLE\s*\((?<c>.*?)\)\s*(?<tail>AS EXTERNAL NAME.*)\z')
 if(-not$match.Success){throw 'CLR_BINDING_CANONICAL_HEADER'}
 $p=@($match.Groups['p'].Value.Split(',')|ForEach-Object Trim);$c=@($match.Groups['c'].Value.Split(',')|ForEach-Object Trim)
 if($p.Count-ne8-or$c.Count-ne10){throw 'CLR_BINDING_ORIGINAL_ARITY'}
 switch -CaseSensitive($Spec.group){
  'parameter-name'{$p[$Spec.index]=$p[$Spec.index].Replace(('@'+$Spec.id),('@'+$Spec.id.ToUpperInvariant()))}
  'parameter-length'{$p[$Spec.index]=$p[$Spec.index].Replace('nvarchar(32)','nvarchar(31)')}
  'column-name'{$c[$Spec.index]=$Spec.id.ToUpperInvariant()+$c[$Spec.index].Substring($Spec.id.Length)}
  'column-length'{$c[$Spec.index]=[regex]::Replace($c[$Spec.index],'nvarchar\(\d+\)',('nvarchar('+($Spec.length/2)+')'))}
  'column-order'{$saved=$c[$Spec.index];$c[$Spec.index]=$c[$Spec.index+1];$c[$Spec.index+1]=$saved}
 }
 return $match.Groups['lead'].Value+'('+($p-join",`n")+")`nRETURNS TABLE`n("+($c-join",`n")+")`n"+$match.Groups['tail'].Value
}
function Test-ClrBindingCatalog($BeforeP,$BeforeC,$AfterP,$AfterC,$Spec){
 if($BeforeP.Count-ne8-or$BeforeC.Count-ne10){return $false}
 $p=@($BeforeP|ConvertTo-Json -Depth 4|ConvertFrom-Json);$c=@($BeforeC|ConvertTo-Json -Depth 4|ConvertFrom-Json)
 switch -CaseSensitive($Spec.group){
  'parameter-name'{$p[$Spec.index].name='@'+$Spec.id.ToUpperInvariant()}
  'parameter-length'{$p[$Spec.index].max_length=$Spec.length}
  'column-name'{$c[$Spec.index].name=$Spec.id.ToUpperInvariant()}
  'column-length'{$c[$Spec.index].max_length=$Spec.length}
  'column-order'{$saved=$c[$Spec.index];$c[$Spec.index]=$c[$Spec.index+1];$c[$Spec.index+1]=$saved;for($i=0;$i-lt10;$i++){$c[$i].column_id=$i+1}}
  default{return $false}
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
 foreach($spec in Get-ClrBindingSpecs){
  Invoke-ReleaseBatches $Db (New-ClrBindingDeclaration $original $spec)
  $actualP=@(Sql $Db $pSql -Rows);$actualC=@(Sql $Db $cSql -Rows)
  if(-not(Test-ClrBindingCatalog $beforeP $beforeC $actualP $actualC $spec)){throw 'CLR_BINDING_EXACT_CATALOG_REQUIRED'}
  $damaged=Get-LifecycleGuardState $Db
  try{foreach($op in @('deploy','uninstall')){
   $path=Get-LifecycleGuardScript 'schema' $op $Mode
   Assert-LifecycleGuardDenied $Db $Mode ($spec.group+'/'+$spec.id+'/'+$op) ([IO.File]::ReadAllText($path)) 55633 'JSON Schema lifecycle: CLR-Binding-/Parameters-/Spaltenvertrag inkohärent.'
  }}finally{
   if((Get-LifecycleGuardState $Db)-cne$damaged){throw 'CLR_BINDING_RESTORE_DRIFT'}
   Invoke-ReleaseBatches $Db $original
  }
  if((Get-LifecycleGuardState $Db)-cne$installed){throw 'CLR_BINDING_ORIGINAL_NOT_RESTORED'}
 }
 $actual=@($ledger.profileCompletions|Where-Object mode -CEQ $Mode|ForEach-Object id|Sort-Object)
 if(($actual-join'|')-cne(@(Get-LifecycleGuardKeys $Mode $case.CL|Sort-Object)-join'|')){throw 'CLR_BINDING_MODE_CLOSURE'}
 Invoke-ReleaseBatches $Db ([IO.File]::ReadAllText($runset.uninstall));Assert-CoreLockNeutral $Db
 Invoke-ReleaseBatches $Db ([IO.File]::ReadAllText($runset.core_uninstall));Assert-CoreLockNeutral $Db
}
