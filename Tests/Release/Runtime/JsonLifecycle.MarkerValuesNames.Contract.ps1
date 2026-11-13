# New value-only and parameter-name inputs; reuse exact established public oracles.
. (Join-Path $PSScriptRoot 'JsonLifecycle.BinaryRegistration.Contract.ps1')
foreach($block in Import-ClrFunctions (Join-Path $PSScriptRoot 'JsonSchema.DependencySignature.Contract.ps1') @('Get-SchemaGuardState','Get-SchemaGuardSignatureCases','New-SchemaGuardSignature','ConvertTo-SchemaGuardAlterCommand')){. $block}
function Get-LifecycleGuardState($Db){Get-SchemaGuardState $Db}
function Get-LifecycleGuardKeys([string]$Mode,[int]$CL){
 if($Mode-cnotin@('local','central')-or$CL-notin@(150,160,170)){throw 'VALUE_NAMES_EXACT_CONTEXT'}
 foreach($module in @('core','schema')){
  foreach($name in @('Toolbelt.Managed','Toolbelt.ModuleId','Toolbelt.ModuleVersion','Toolbelt.DeploymentMode','Toolbelt.AssemblySha512','Toolbelt.ArtifactId')){foreach($op in @('deploy','uninstall')){'value-'+$module+'/'+$name+'/'+$op}}
  foreach($name in @('Version','DeploymentMode')){foreach($op in @('deploy','uninstall')){'missing-db-'+$module+'/'+$name+'/'+$op}}
 }
 foreach($spec in Get-SchemaGuardSignatureCases){foreach($op in @('deploy','uninstall')){'parameter-name/'+$spec.id+'/'+$op}}
}
function New-ValueNameSignature([string]$Original,$Spec){
 $parts=$Spec.before.Split(' ',2)
 if($parts.Count-ne2-or$parts[0]-cne('@'+$Spec.id)){throw 'VALUE_NAMES_SINGLE_PARAMETER_TOKEN'}
 New-SchemaGuardSignature $Original ([pscustomobject]@{before=$Spec.before;after=($parts[0].ToUpperInvariant()+' '+$parts[1])})
}
function Invoke-LifecycleGuardProfiles($Db,[string]$Mode){
 Invoke-ReleaseBatches $Db ([IO.File]::ReadAllText($runset.baselines.$Mode))
 Invoke-ReleaseBatches $Db ([IO.File]::ReadAllText($runset.exports.$Mode))
 # Stabilize the existing-procedure catalog text before any captured fixture.
 Invoke-ReleaseBatches $Db ([IO.File]::ReadAllText($runset.exports.$Mode))
 $installed=Get-LifecycleGuardState $Db
 Sql $Db @'
SELECT class,major_id,name,value INTO #ValueNamesOriginals FROM sys.extended_properties
WHERE (class=5 AND major_id IN(SELECT assembly_id FROM sys.assemblies WHERE name IN(N'Toolbelt_JsonCore',N'Toolbelt_JsonSchema')))
 OR (class=0 AND name IN(N'Toolbelt.Module.toolbelt.json.core.Version',N'Toolbelt.Module.toolbelt.json.core.DeploymentMode',N'Toolbelt.Module.toolbelt.json.schema.Version',N'Toolbelt.Module.toolbelt.json.schema.DeploymentMode'));
'@
 if([int](Read-Scalar $Db 'SELECT COUNT(*) ScalarValue FROM #ValueNamesOriginals;')-ne16){throw 'VALUE_NAMES_SIXTEEN_ORIGINALS'}
 foreach($module in @('core','schema')){
  $slot=if($module-ceq'core'){'Toolbelt_JsonCore'}else{'Toolbelt_JsonSchema'}
  foreach($name in @('Toolbelt.Managed','Toolbelt.ModuleId','Toolbelt.ModuleVersion','Toolbelt.DeploymentMode','Toolbelt.AssemblySha512','Toolbelt.ArtifactId')){
   $parameters=@{'@Name'=$name;'@Slot'=$slot}
   Sql $Db @'
DECLARE @V sql_variant,@Bad sql_variant;
SELECT @V=value FROM #ValueNamesOriginals WHERE class=5 AND major_id=(SELECT assembly_id FROM sys.assemblies WHERE name=@Slot) AND name=@Name;
IF @V IS NULL THROW 52098,N'Owned marker missing.',1;
SET @Bad=CASE @Name
 WHEN N'Toolbelt.Managed' THEN CONVERT(sql_variant,CONVERT(int,0))
 WHEN N'Toolbelt.ModuleId' THEN CONVERT(sql_variant,CONVERT(nvarchar(64),LEFT(CONVERT(nvarchar(64),@V),LEN(CONVERT(nvarchar(64),@V))-1)+N'X'))
 WHEN N'Toolbelt.ModuleVersion' THEN CONVERT(sql_variant,CONVERT(nvarchar(16),N'1.0.9'))
 WHEN N'Toolbelt.DeploymentMode' THEN CONVERT(sql_variant,CONVERT(nvarchar(16),UPPER(CONVERT(nvarchar(16),@V))))
 WHEN N'Toolbelt.AssemblySha512' THEN CONVERT(sql_variant,CONVERT(varbinary(64),CONVERT(binary(64),0x00)))
 WHEN N'Toolbelt.ArtifactId' THEN CONVERT(sql_variant,CONVERT(varchar(64),REPLICATE('0',64))) END;
IF SQL_VARIANT_PROPERTY(@V,N'BaseType')<>SQL_VARIANT_PROPERTY(@Bad,N'BaseType')
 OR SQL_VARIANT_PROPERTY(@V,N'MaxLength')<>SQL_VARIANT_PROPERTY(@Bad,N'MaxLength')
 OR DATALENGTH(@V)<>DATALENGTH(@Bad) OR CONVERT(varbinary(max),@V)=CONVERT(varbinary(max),@Bad)
 THROW 52098,N'Value-only fixture must preserve type and length while changing bytes.',1;
EXEC sys.sp_updateextendedproperty @name=@Name,@value=@Bad,@level0type=N'ASSEMBLY',@level0name=@Slot;
'@ $parameters
   $damaged=Get-LifecycleGuardState $Db
   try{foreach($op in @('deploy','uninstall')){
    $path=Get-LifecycleGuardScript $module $op $Mode
    $number=if($module-ceq'core'){55623}else{55633}
    $message=if($module-ceq'core'){'JSON Core: typisiertes bekanntes Markertuple ist inkohärent.'}else{'JSON Schema lifecycle: typisiertes Assemblymarkertuple inkohärent.'}
    Assert-LifecycleGuardDenied $Db $Mode ('value-'+$module+'/'+$name+'/'+$op) ([IO.File]::ReadAllText($path)) $number $message
   }}finally{
    if((Get-LifecycleGuardState $Db)-cne$damaged){throw 'VALUE_NAMES_MARKER_RESTORE_DRIFT'}
    Sql $Db "DECLARE @V sql_variant;SELECT @V=value FROM #ValueNamesOriginals WHERE class=5 AND major_id=(SELECT assembly_id FROM sys.assemblies WHERE name=@Slot) AND name=@Name;EXEC sys.sp_updateextendedproperty @name=@Name,@value=@V,@level0type=N'ASSEMBLY',@level0name=@Slot;" $parameters
   }
   if((Get-LifecycleGuardState $Db)-cne$installed){throw 'VALUE_NAMES_TYPED_ORIGINAL_NOT_RESTORED'}
  }
  foreach($suffix in @('Version','DeploymentMode')){
   $name='Toolbelt.Module.toolbelt.json.'+$module+'.'+$suffix
   Sql $Db 'EXEC sys.sp_dropextendedproperty @name=@Name;' @{'@Name'=$name}
   $damaged=Get-LifecycleGuardState $Db
   try{foreach($op in @('deploy','uninstall')){
    $path=Get-LifecycleGuardScript $module $op $Mode
    $number=if($module-ceq'core'){55623}elseif($suffix-ceq'Version'){55634}else{55633}
    $message=if($module-ceq'core'){'JSON Core: keine kohärente bekannte technische SAFE-Assembly.'}elseif($suffix-ceq'Version'){'JSON Schema lifecycle: unregistrierter oder fremder Zielslot.'}else{'JSON Schema lifecycle: unbekannter oder inkohärenter Releasezustand.'}
    Assert-LifecycleGuardDenied $Db $Mode ('missing-db-'+$module+'/'+$suffix+'/'+$op) ([IO.File]::ReadAllText($path)) $number $message
   }}finally{
    if((Get-LifecycleGuardState $Db)-cne$damaged){throw 'VALUE_NAMES_DB_RESTORE_DRIFT'}
    Sql $Db 'DECLARE @V sql_variant;SELECT @V=value FROM #ValueNamesOriginals WHERE class=0 AND name=@Name;EXEC sys.sp_addextendedproperty @name=@Name,@value=@V;' @{'@Name'=$name}
   }
   if((Get-LifecycleGuardState $Db)-cne$installed){throw 'VALUE_NAMES_DB_ORIGINAL_NOT_RESTORED'}
  }
 }
 Sql $Db 'DROP TABLE #ValueNamesOriginals;'
 $original=[string](Read-Scalar $Db "SELECT OBJECT_DEFINITION(OBJECT_ID(N'toolbelt_json.USP_ValidateJsonSchema')) ScalarValue;")
 $ledger.definitionSnapshots+=@(@{mode=$Mode;scope='owned-public-procedure';definition=$original});Save-ReleaseJournal
 $catalogSql="SELECT parameter_id,name,system_type_id,user_type_id,max_length,[precision],[scale],is_output FROM sys.parameters WHERE object_id=OBJECT_ID(N'toolbelt_json.USP_ValidateJsonSchema') ORDER BY parameter_id;"
 $originalParameters=@(Sql $Db $catalogSql -Rows);if($originalParameters.Count-ne12){throw 'VALUE_NAMES_ORIGINAL_TWELVE_PARAMETERS'}
 foreach($spec in Get-SchemaGuardSignatureCases){
  $changed=New-ValueNameSignature $original $spec
  Invoke-ReleaseBatches $Db (ConvertTo-SchemaGuardAlterCommand $changed)
  $actual=@(Sql $Db $catalogSql -Rows);if($actual.Count-ne12){throw 'VALUE_NAMES_ACTUAL_PARAMETER_COUNT'}
  if(-not(Test-ValueNameCatalog $originalParameters $actual $spec.id)){throw 'VALUE_NAMES_EXACT_ONE_NAME_CHANGE'}
  $damaged=Get-LifecycleGuardState $Db
  try{foreach($op in @('deploy','uninstall')){
   $path=Get-LifecycleGuardScript 'schema' $op $Mode
   Assert-LifecycleGuardDenied $Db $Mode ('parameter-name/'+$spec.id+'/'+$op) ([IO.File]::ReadAllText($path)) 55633 'JSON Schema lifecycle: öffentliche Parametersignatur inkohärent.'
  }}finally{
   if((Get-LifecycleGuardState $Db)-cne$damaged){throw 'VALUE_NAMES_SIGNATURE_RESTORE_DRIFT'}
   Invoke-ReleaseBatches $Db (ConvertTo-SchemaGuardAlterCommand $original)
  }
  if((Get-LifecycleGuardState $Db)-cne$installed){throw 'VALUE_NAMES_SIGNATURE_ORIGINAL_NOT_RESTORED'}
 }
 $actualKeys=@($ledger.profileCompletions|Where-Object mode -CEQ $Mode|ForEach-Object id|Sort-Object)
 if(($actualKeys-join'|')-cne(@(Get-LifecycleGuardKeys $Mode $case.CL|Sort-Object)-join'|')){throw 'VALUE_NAMES_MODE_CLOSURE'}
 Invoke-ReleaseBatches $Db ([IO.File]::ReadAllText($runset.uninstall));Assert-CoreLockNeutral $Db
 Invoke-ReleaseBatches $Db ([IO.File]::ReadAllText($runset.core_uninstall));Assert-CoreLockNeutral $Db
}

function Test-ValueNameCatalog($Before,$After,[string]$Id){
 if($Before.Count-ne12-or$After.Count-ne12){return $false}
 $count=0
 for($i=0;$i-lt12;$i++){
  foreach($field in @('parameter_id','system_type_id','user_type_id','max_length','precision','scale','is_output')){if($Before[$i].$field-ne$After[$i].$field){return $false}}
  if($Before[$i].name-cne$After[$i].name){
   if($Before[$i].name-cne('@'+$Id)-or$After[$i].name-cne('@'+$Id.ToUpperInvariant())){return $false};$count++
  }
 }
 return [bool]($count-eq1)
}
