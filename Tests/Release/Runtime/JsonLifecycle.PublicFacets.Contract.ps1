. (Join-Path $PSScriptRoot 'JsonLifecycle.BinaryRegistration.Contract.ps1')
foreach($block in Import-ClrFunctions (Join-Path $PSScriptRoot 'JsonSchema.DependencySignature.Contract.ps1') @('Get-SchemaGuardState','Get-SchemaGuardSignatureCases','New-SchemaGuardSignature','ConvertTo-SchemaGuardAlterCommand')){. $block}
function Get-LifecycleGuardState($Db){Get-SchemaGuardState $Db}
# Zwanzig geschlossene neue Deklarationen; weder bisherige kurze Längen noch Aliasfälle wiederholen.
function Get-PublicFacetSpecs{
 $rows=@(
  @('Json-nchar4000',0,'nchar(4000)',239,8000,0,0),
  @('Schema-nchar4000',1,'nchar(4000)',239,8000,0,0),
  @('Profile-char32',2,'char(32)',175,32,0,0),
  @('Profile-nvarchar32',2,'nvarchar(32)',231,64,0,0),
  @('Profile-varchar33',2,'varchar(33)',167,33,0,0),
  @('Profile-varcharMax',2,'varchar(max)',167,-1,0,0),
  @('MaxDocumentBytes-decimal19',3,'decimal(19,0)',106,9,19,0),
  @('MaxSchemaBytes-decimal19',4,'decimal(19,0)',106,9,19,0),
  @('MaxEvaluationSteps-decimal19',6,'decimal(19,0)',106,9,19,0),
  @('MaxDepth-bigint',5,'bigint',127,8,19,0),
  @('MaxErrors-bigint',7,'bigint',127,8,19,0),
  @('Debug-int',10,'int',56,4,10,0),
  @('KeepData-int',9,'int',56,4,10,0),
  @('Hilfe-int',11,'int',56,4,10,0),
  @('ResultTable-nvarchar129',8,'nvarchar(129)',231,258,0,0),
  @('ResultTable-nchar128',8,'nchar(128)',239,256,0,0),
  @('Json-nvarchar1',0,'nvarchar(1)',231,2,0,0),
  @('Schema-nvarchar1',1,'nvarchar(1)',231,2,0,0),
  @('Profile-varchar1',2,'varchar(1)',167,1,0,0),
  @('ResultTable-nvarchar1',8,'nvarchar(1)',231,2,0,0)
 )
 $original=@(Get-SchemaGuardSignatureCases)
 foreach($r in $rows){$o=$original[$r[1]];[pscustomobject]@{id=$r[0];index=$r[1];parameter=$o.id;before=$o.before;after=('@'+$o.id+' '+$r[2]);type=$r[3];length=$r[4];precision=$r[5];scale=$r[6]}}
}
function Assert-PublicFacetSpec($Spec){
 $known=@(Get-PublicFacetSpecs|Where-Object{$_.id-ceq$Spec.id-and$_.index-eq$Spec.index-and$_.parameter-ceq$Spec.parameter-and$_.before-ceq$Spec.before-and$_.after-ceq$Spec.after-and$_.type-eq$Spec.type-and$_.length-eq$Spec.length-and$_.precision-eq$Spec.precision-and$_.scale-eq$Spec.scale})
 if($known.Count-ne1){throw 'PUBLIC_FACETS_EXACT_VECTOR'}
}
function Get-LifecycleGuardKeys([string]$Mode,[int]$CL){
 if($Mode-cnotin@('local','central')-or$CL-notin@(150,160,170)){throw 'PUBLIC_FACETS_EXACT_CONTEXT'}
 foreach($spec in Get-PublicFacetSpecs){foreach($op in @('deploy','uninstall')){'public-facet/'+$spec.id+'/'+$op}}
}
function New-PublicFacetDeclaration([string]$Original,$Spec){
 Assert-PublicFacetSpec $Spec
 New-SchemaGuardSignature $Original $Spec
}
function Test-PublicFacetCatalog($Before,$After,$Spec){
 Assert-PublicFacetSpec $Spec
 if($Before.Count-ne12-or$After.Count-ne12){return $false}
 $expected=@($Before|ConvertTo-Json -Depth 4|ConvertFrom-Json)
 $row=$expected[$Spec.index];$row.system_type_id=$Spec.type;$row.user_type_id=$Spec.type;$row.max_length=$Spec.length;$row.precision=$Spec.precision;$row.scale=$Spec.scale
 return [bool](($expected|ConvertTo-Json -Depth 4 -Compress)-ceq($After|ConvertTo-Json -Depth 4 -Compress))
}
function Invoke-LifecycleGuardProfiles($Db,[string]$Mode){
 Invoke-ReleaseBatches $Db ([IO.File]::ReadAllText($runset.baselines.$Mode))
 Invoke-ReleaseBatches $Db ([IO.File]::ReadAllText($runset.exports.$Mode))
 # Bestehende CREATE/ALTER-Katalogrepräsentation vor dem ersten Snapshot stabilisieren.
 Invoke-ReleaseBatches $Db ([IO.File]::ReadAllText($runset.exports.$Mode))
 $installed=Get-LifecycleGuardState $Db
 $original=[string](Read-Scalar $Db "SELECT OBJECT_DEFINITION(OBJECT_ID(N'toolbelt_json.USP_ValidateJsonSchema')) ScalarValue;")
 $ledger.definitionSnapshots+=@(@{mode=$Mode;scope='owned-public-procedure';definition=$original});Save-ReleaseJournal
 $catalog="SELECT parameter_id,name,system_type_id,user_type_id,max_length,[precision],[scale],is_output FROM sys.parameters WHERE object_id=OBJECT_ID(N'toolbelt_json.USP_ValidateJsonSchema') ORDER BY parameter_id;"
 $before=@(Sql $Db $catalog -Rows)
 foreach($spec in Get-PublicFacetSpecs){
  Invoke-ReleaseBatches $Db (ConvertTo-SchemaGuardAlterCommand (New-PublicFacetDeclaration $original $spec))
  $actual=@(Sql $Db $catalog -Rows)
  if(-not(Test-PublicFacetCatalog $before $actual $spec)){throw 'PUBLIC_FACETS_EXACT_CATALOG_REQUIRED'}
  $damaged=Get-LifecycleGuardState $Db
  try{foreach($op in @('deploy','uninstall')){
   $path=Get-LifecycleGuardScript 'schema' $op $Mode
   Assert-LifecycleGuardDenied $Db $Mode ('public-facet/'+$spec.id+'/'+$op) ([IO.File]::ReadAllText($path)) 55633 'JSON Schema lifecycle: öffentliche Parametersignatur inkohärent.'
  }}finally{
   if((Get-LifecycleGuardState $Db)-cne$damaged){throw 'PUBLIC_FACETS_RESTORE_DRIFT'}
   Invoke-ReleaseBatches $Db (ConvertTo-SchemaGuardAlterCommand $original)
  }
  if((Get-LifecycleGuardState $Db)-cne$installed){throw 'PUBLIC_FACETS_ORIGINAL_NOT_RESTORED'}
 }
 $actualKeys=@($ledger.profileCompletions|Where-Object mode -CEQ $Mode|ForEach-Object id|Sort-Object)
 if(($actualKeys-join'|')-cne(@(Get-LifecycleGuardKeys $Mode $case.CL|Sort-Object)-join'|')){throw 'PUBLIC_FACETS_TWENTY_POINT_CLOSURE'}
 Invoke-ReleaseBatches $Db ([IO.File]::ReadAllText($runset.uninstall));Assert-CoreLockNeutral $Db
 Invoke-ReleaseBatches $Db ([IO.File]::ReadAllText($runset.core_uninstall));Assert-CoreLockNeutral $Db
}
