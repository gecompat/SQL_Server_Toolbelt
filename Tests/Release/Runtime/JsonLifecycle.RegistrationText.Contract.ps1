. (Join-Path $PSScriptRoot 'JsonLifecycle.BinaryRegistration.Contract.ps1')
foreach($block in Import-ClrFunctions (Join-Path $PSScriptRoot 'JsonSchema.DependencySignature.Contract.ps1') @('Get-SchemaGuardState')){. $block}
function Get-LifecycleGuardState($Db){Get-SchemaGuardState $Db}
# Geschlossene Textvektoren: neue Formatgrenzen, keine Wiederholung alter NULL-/Typfälle.
function Get-RegistrationTextSpecs{
 foreach($module in @('core','schema')){
  foreach($id in @('short','four-parts','negative','overflow','leading-zero','space')){
   [pscustomobject]@{group=('db-version-'+$module);id=$id;module=$module;class=0;slot='';name=('Toolbelt.Module.toolbelt.json.'+$module+'.Version');variant=$id}
  }
  foreach($id in @('empty','space','leading-space','unknown')){
   [pscustomobject]@{group=('db-mode-'+$module);id=$id;module=$module;class=0;slot='';name=('Toolbelt.Module.toolbelt.json.'+$module+'.DeploymentMode');variant=$id}
  }
 }
 foreach($slot in @('USP_ValidateJsonSchema','FT_ValidateJsonSchemaInternal')){
  foreach($row in @(@('module-case','Toolbelt.ModuleId','upper'),@('module-whitespace','Toolbelt.ModuleId','space'),@('module-whitespace','Toolbelt.ModuleId','leading-space'),@('version-format','Toolbelt.ModuleVersion','leading-zero'),@('version-format','Toolbelt.ModuleVersion','four-parts'),@('version-whitespace','Toolbelt.ModuleVersion','space'),@('version-whitespace','Toolbelt.ModuleVersion','leading-space'),@('mode-case','Toolbelt.DeploymentMode','upper'),@('mode-case','Toolbelt.DeploymentMode','opposite'),@('mode-format','Toolbelt.DeploymentMode','empty'),@('mode-format','Toolbelt.DeploymentMode','space'),@('mode-format','Toolbelt.DeploymentMode','leading-space'),@('mode-format','Toolbelt.DeploymentMode','unknown'))){
   [pscustomobject]@{group=('object-'+$row[0]);id=($slot+'-'+$row[2]);module='schema';class=1;slot=$slot;name=$row[1];variant=$row[2]}
  }
 }
}
function Get-LifecycleGuardKeys([string]$Mode,[int]$CL){
 if($Mode-cnotin@('local','central')-or$CL-notin@(150,160,170)){throw 'REGISTRATION_TEXT_EXACT_CONTEXT'}
 foreach($spec in Get-RegistrationTextSpecs){foreach($op in @('deploy','uninstall')){$spec.group+'/'+$spec.id+'/'+$op}}
}
function Get-RegistrationTextParameters($Spec,[string]$Mode){
 if($Mode-cnotin@('local','central')){throw 'REGISTRATION_TEXT_EXACT_MODE'}
 $known=@(Get-RegistrationTextSpecs|Where-Object{$_.group-ceq$Spec.group-and$_.id-ceq$Spec.id-and$_.module-ceq$Spec.module-and$_.class-eq$Spec.class-and$_.slot-ceq$Spec.slot-and$_.name-ceq$Spec.name-and$_.variant-ceq$Spec.variant})
 if($known.Count-ne1){throw 'REGISTRATION_TEXT_EXACT_PROPERTY'}
 return @{'@Name'=$Spec.name;'@Class'=$Spec.class;'@Slot'=$Spec.slot;'@Variant'=$Spec.variant;'@Mode'=$Mode;'@L0'=$(if($Spec.class-eq1){'SCHEMA'}else{[DBNull]::Value});'@N0'=$(if($Spec.class-eq1){'toolbelt_json'}else{[DBNull]::Value});'@L1'=$(if($Spec.class-eq0){[DBNull]::Value}elseif($Spec.slot-ceq'USP_ValidateJsonSchema'){'PROCEDURE'}else{'FUNCTION'});'@N1'=$(if($Spec.class-eq1){$Spec.slot}else{[DBNull]::Value})}
}
function Get-RegistrationTextError($Spec,[string]$Operation){
 if($Operation-cnotin@('deploy','uninstall')){throw 'REGISTRATION_TEXT_EXACT_OPERATION'}
 if($Spec.class-eq1){return [pscustomobject]@{number=55633;message='JSON Schema lifecycle: objektgenaue Ownership inkohärent.'}}
 $number=if($Spec.module-ceq'core'){55623}else{55633}
 $message=if($Spec.module-ceq'core'){'JSON Core: keine kohärente bekannte technische SAFE-Assembly.'}else{'JSON Schema lifecycle: unbekannter oder inkohärenter Releasezustand.'}
 if($Operation-ceq'uninstall'-and$Spec.group.StartsWith('db-mode-',[StringComparison]::Ordinal)){$message=if($Spec.module-ceq'core'){'JSON Core: inkohärenter installierter Modus.'}else{'JSON Schema lifecycle: inkohärenter installierter Modus.'}}
 return [pscustomobject]@{number=$number;message=$message}
}
function Invoke-LifecycleGuardProfiles($Db,[string]$Mode){
 Invoke-ReleaseBatches $Db ([IO.File]::ReadAllText($runset.baselines.$Mode))
 Invoke-ReleaseBatches $Db ([IO.File]::ReadAllText($runset.exports.$Mode))
 $original=Get-LifecycleGuardState $Db
 Sql $Db @'
SELECT class,major_id,name,value INTO #RegistrationTextOriginals FROM sys.extended_properties
WHERE (class=0 AND name IN(N'Toolbelt.Module.toolbelt.json.core.Version',N'Toolbelt.Module.toolbelt.json.core.DeploymentMode',N'Toolbelt.Module.toolbelt.json.schema.Version',N'Toolbelt.Module.toolbelt.json.schema.DeploymentMode'))
 OR (class=1 AND major_id IN(OBJECT_ID(N'toolbelt_json.USP_ValidateJsonSchema'),OBJECT_ID(N'toolbelt_json.FT_ValidateJsonSchemaInternal')) AND name IN(N'Toolbelt.ModuleId',N'Toolbelt.ModuleVersion',N'Toolbelt.DeploymentMode'));
'@
 if([int](Read-Scalar $Db 'SELECT COUNT(*) ScalarValue FROM #RegistrationTextOriginals;')-ne10){throw 'REGISTRATION_TEXT_TEN_ORIGINALS'}
 foreach($spec in Get-RegistrationTextSpecs){
  $parameters=Get-RegistrationTextParameters $spec $Mode
  Sql $Db @'
DECLARE @Old sql_variant,@Text nvarchar(128),@Bad nvarchar(128),@Id int;
SET @Id=CASE WHEN TRY_CONVERT(int,@Class)=0 THEN 0 ELSE OBJECT_ID(N'toolbelt_json.'+QUOTENAME(@Slot)) END;
IF (SELECT COUNT(*) FROM #RegistrationTextOriginals WHERE class=TRY_CONVERT(int,@Class) AND major_id=@Id AND name=@Name)<>1 THROW 52098,N'Owned original missing.',1;
SELECT @Old=value FROM #RegistrationTextOriginals WHERE class=TRY_CONVERT(int,@Class) AND major_id=@Id AND name=@Name;
SET @Text=CONVERT(nvarchar(128),@Old);
SET @Bad=CASE @Variant WHEN N'short' THEN N'1.0' WHEN N'four-parts' THEN @Text+N'.0' WHEN N'negative' THEN N'1.0.-1'
 WHEN N'overflow' THEN N'2147483648.0.0' WHEN N'leading-zero' THEN N'0'+@Text WHEN N'space' THEN @Text+N' '
 WHEN N'leading-space' THEN N' '+@Text WHEN N'empty' THEN N'' WHEN N'unknown' THEN N'contoso'
 WHEN N'upper' THEN UPPER(@Text) WHEN N'opposite' THEN CASE @Mode WHEN N'local' THEN N'central' ELSE N'local' END END;
IF @Old IS NULL OR @Bad IS NULL OR CONVERT(varbinary(max),@Text)=CONVERT(varbinary(max),@Bad) THROW 52098,N'Exact text mutation required.',1;
EXEC sys.sp_updateextendedproperty @name=@Name,@value=@Bad,@level0type=@L0,@level0name=@N0,@level1type=@L1,@level1name=@N1;
'@ $parameters
  $damaged=Get-LifecycleGuardState $Db;if($damaged-ceq$original){throw 'REGISTRATION_TEXT_ACTUAL_MUTATION_REQUIRED'}
  try{foreach($op in @('deploy','uninstall')){
   $expected=Get-RegistrationTextError $spec $op
   $path=Get-LifecycleGuardScript $spec.module $op $Mode
   Assert-LifecycleGuardDenied $Db $Mode ($spec.group+'/'+$spec.id+'/'+$op) ([IO.File]::ReadAllText($path)) $expected.number $expected.message
  }}finally{
   if((Get-LifecycleGuardState $Db)-cne$damaged){throw 'REGISTRATION_TEXT_RESTORE_DRIFT'}
   Sql $Db @'
DECLARE @V sql_variant,@Id int;
SET @Id=CASE WHEN TRY_CONVERT(int,@Class)=0 THEN 0 ELSE OBJECT_ID(N'toolbelt_json.'+QUOTENAME(@Slot)) END;
IF (SELECT COUNT(*) FROM #RegistrationTextOriginals WHERE class=TRY_CONVERT(int,@Class) AND major_id=@Id AND name=@Name)<>1 THROW 52098,N'Owned restore original missing.',1;
SELECT @V=value FROM #RegistrationTextOriginals WHERE class=TRY_CONVERT(int,@Class) AND major_id=@Id AND name=@Name;
EXEC sys.sp_updateextendedproperty @name=@Name,@value=@V,@level0type=@L0,@level0name=@N0,@level1type=@L1,@level1name=@N1;
'@ $parameters
  }
  if((Get-LifecycleGuardState $Db)-cne$original){throw 'REGISTRATION_TEXT_TYPED_ORIGINAL_NOT_RESTORED'}
 }
 Sql $Db 'DROP TABLE #RegistrationTextOriginals;'
 $actual=@($ledger.profileCompletions|Where-Object mode -CEQ $Mode|ForEach-Object id|Sort-Object)
 if(($actual-join'|')-cne(@(Get-LifecycleGuardKeys $Mode $case.CL|Sort-Object)-join'|')){throw 'REGISTRATION_TEXT_TEN_POINT_CLOSURE'}
 Invoke-ReleaseBatches $Db ([IO.File]::ReadAllText($runset.uninstall));Assert-CoreLockNeutral $Db
 Invoke-ReleaseBatches $Db ([IO.File]::ReadAllText($runset.core_uninstall));Assert-CoreLockNeutral $Db
}
