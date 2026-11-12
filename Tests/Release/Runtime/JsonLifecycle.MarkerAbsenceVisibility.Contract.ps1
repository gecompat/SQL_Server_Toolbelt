# Reuse unchanged snapshots, canonical public paths and external neutrality oracles.
. (Join-Path $PSScriptRoot 'JsonLifecycle.BinaryRegistration.Contract.ps1')
$script:markerAbsenceBaseState=${function:Get-LifecycleGuardState}
function Get-LifecycleGuardState($Db){
 $prior=& $script:markerAbsenceBaseState $Db
 $flags=@(Sql $Db "SELECT assembly_id,name,principal_id,permission_set,is_visible FROM sys.assemblies WHERE name IN(N'Toolbelt_JsonCore',N'Toolbelt_JsonSchema') ORDER BY name;" -Rows)
 return ([ordered]@{baseline=$prior;assemblyFlags=@($flags)}|ConvertTo-Json -Depth 7 -Compress)
}
function Get-MarkerAbsenceSpecs{
 foreach($module in @('core','schema')){
  foreach($name in @('Toolbelt.Managed','Toolbelt.ModuleId','Toolbelt.ModuleVersion','Toolbelt.DeploymentMode','Toolbelt.AssemblySha512','Toolbelt.ArtifactId')){
   [pscustomobject]@{group=('assembly-'+$module);module=$module;slot=$(if($module-ceq'core'){'Toolbelt_JsonCore'}else{'Toolbelt_JsonSchema'});name=$name;class=5}
  }
 }
 foreach($slot in @('USP_ValidateJsonSchema','FT_ValidateJsonSchemaInternal')){foreach($name in @('Toolbelt.ModuleId','Toolbelt.ModuleVersion','Toolbelt.DeploymentMode')){
  [pscustomobject]@{group='ownership-schema';module='schema';slot=$slot;name=$name;class=1}
 }}
}
function Get-LifecycleGuardKeys([string]$Mode,[int]$CL){
 if($Mode-cnotin@('local','central')-or$CL-notin@(150,160,170)){throw 'MARKER_ABSENCE_EXACT_CONTEXT'}
 foreach($spec in Get-MarkerAbsenceSpecs){foreach($variant in @('missing','null')){foreach($op in @('deploy','uninstall')){$spec.group+'/'+$spec.slot+'/'+$spec.name+'/'+$variant+'/'+$op}}}
 foreach($path in @('core','delegated-schema','schema')){foreach($op in @('deploy','uninstall')){'visibility/'+$path+'/'+$op}}
}
function Get-MarkerAbsenceError($Spec){
 if($Spec.group-ceq'assembly-core'){return [pscustomobject]@{number=55623;message='JSON Core: typisiertes bekanntes Markertuple ist inkohärent.'}}
 if($Spec.group-ceq'assembly-schema'){return [pscustomobject]@{number=55633;message='JSON Schema lifecycle: typisiertes Assemblymarkertuple inkohärent.'}}
 if($Spec.group-ceq'ownership-schema'){return [pscustomobject]@{number=55633;message='JSON Schema lifecycle: objektgenaue Ownership inkohärent.'}}
 throw 'MARKER_ABSENCE_EXACT_ERROR_SCOPE'
}
function Get-MarkerAbsenceParameters($Spec){
 $known=@(Get-MarkerAbsenceSpecs|Where-Object{$_.group-ceq$Spec.group-and$_.slot-ceq$Spec.slot-and$_.name-ceq$Spec.name-and$_.class-eq$Spec.class-and$_.module-ceq$Spec.module})
 if($known.Count-ne1){throw 'MARKER_ABSENCE_EXACT_PROPERTY_SCOPE'}
 return @{'@Name'=$Spec.name;'@Slot'=$Spec.slot;'@Class'=$Spec.class;'@L0'=$(if($Spec.class-eq5){'ASSEMBLY'}else{'SCHEMA'});'@N0'=$(if($Spec.class-eq5){$Spec.slot}else{'toolbelt_json'});'@L1'=$(if($Spec.class-eq5){[DBNull]::Value}elseif($Spec.slot-ceq'USP_ValidateJsonSchema'){'PROCEDURE'}else{'FUNCTION'});'@N1'=$(if($Spec.class-eq5){[DBNull]::Value}else{$Spec.slot})}
}
function Invoke-LifecycleGuardProfiles($Db,[string]$Mode){
 Invoke-ReleaseBatches $Db ([IO.File]::ReadAllText($runset.baselines.$Mode))
 Invoke-ReleaseBatches $Db ([IO.File]::ReadAllText($runset.exports.$Mode))
 $installed=Get-LifecycleGuardState $Db
 Sql $Db @'
SELECT class,major_id,name,value INTO #MarkerAbsenceOriginals FROM sys.extended_properties
WHERE (class=5 AND major_id IN(SELECT assembly_id FROM sys.assemblies WHERE name IN(N'Toolbelt_JsonCore',N'Toolbelt_JsonSchema')))
 OR (class=1 AND major_id IN(OBJECT_ID(N'toolbelt_json.USP_ValidateJsonSchema'),OBJECT_ID(N'toolbelt_json.FT_ValidateJsonSchemaInternal'))
 AND name IN(N'Toolbelt.ModuleId',N'Toolbelt.ModuleVersion',N'Toolbelt.DeploymentMode'));
'@
 if([int](Read-Scalar $Db 'SELECT COUNT(*) ScalarValue FROM #MarkerAbsenceOriginals;')-ne18){throw 'MARKER_ABSENCE_EIGHTEEN_ORIGINALS_REQUIRED'}
 foreach($spec in Get-MarkerAbsenceSpecs){foreach($variant in @('missing','null')){
  $parameters=Get-MarkerAbsenceParameters $spec
  if($variant-ceq'missing'){
   Sql $Db 'EXEC sys.sp_dropextendedproperty @name=@Name,@level0type=@L0,@level0name=@N0,@level1type=@L1,@level1name=@N1;' $parameters
  }else{
   Sql $Db 'DECLARE @V sql_variant=NULL;EXEC sys.sp_updateextendedproperty @name=@Name,@value=@V,@level0type=@L0,@level0name=@N0,@level1type=@L1,@level1name=@N1;' $parameters
  }
  $damaged=Get-LifecycleGuardState $Db;if($damaged-ceq$installed){throw 'MARKER_ABSENCE_FIXTURE_UNCHANGED'}
  try{
   $expected=Get-MarkerAbsenceError $spec
   foreach($op in @('deploy','uninstall')){
    $path=Get-LifecycleGuardScript $spec.module $op $Mode
    Assert-LifecycleGuardDenied $Db $Mode ($spec.group+'/'+$spec.slot+'/'+$spec.name+'/'+$variant+'/'+$op) ([IO.File]::ReadAllText($path)) $expected.number $expected.message
   }
  }finally{
   if((Get-LifecycleGuardState $Db)-cne$damaged){throw 'MARKER_ABSENCE_RESTORE_DRIFT'}
   $parameters['@Missing']=[int]($variant-ceq'missing')
   Sql $Db @'
DECLARE @Id int,@V sql_variant;
SET @Id=CASE WHEN @Class=5 THEN (SELECT assembly_id FROM sys.assemblies WHERE name=@Slot) ELSE OBJECT_ID(N'toolbelt_json.'+QUOTENAME(@Slot)) END;
IF (SELECT COUNT(*) FROM #MarkerAbsenceOriginals WHERE class=@Class AND major_id=@Id AND name=@Name)<>1 THROW 52098,N'Owned original marker missing.',1;
SELECT @V=value FROM #MarkerAbsenceOriginals WHERE class=@Class AND major_id=@Id AND name=@Name;
IF @Missing=1 EXEC sys.sp_addextendedproperty @name=@Name,@value=@V,@level0type=@L0,@level0name=@N0,@level1type=@L1,@level1name=@N1;
ELSE EXEC sys.sp_updateextendedproperty @name=@Name,@value=@V,@level0type=@L0,@level0name=@N0,@level1type=@L1,@level1name=@N1;
'@ $parameters
  }
  if((Get-LifecycleGuardState $Db)-cne$installed){throw 'MARKER_ABSENCE_TYPED_ORIGINAL_NOT_RESTORED'}
 }}
 Sql $Db 'DROP TABLE #MarkerAbsenceOriginals;'
 # Visibility is the only ALTER ASSEMBLY operation; no binary or permission changes.
 foreach($module in @('core','schema')){
  if($module-ceq'core'){Sql $Db 'ALTER ASSEMBLY [Toolbelt_JsonCore] WITH VISIBILITY=ON;'}else{Sql $Db 'ALTER ASSEMBLY [Toolbelt_JsonSchema] WITH VISIBILITY=OFF;'}
  $damaged=Get-LifecycleGuardState $Db;if($damaged-ceq$installed){throw 'MARKER_ABSENCE_VISIBILITY_NOT_CHANGED'}
  try{
   $paths=if($module-ceq'core'){@('core','delegated-schema')}else{@('schema')}
   foreach($entry in $paths){foreach($op in @('deploy','uninstall')){
    $target=if($entry-ceq'core'){'core'}else{'schema'}
    $path=Get-LifecycleGuardScript $target $op $Mode
    $number=if($module-ceq'core'){55623}else{55633}
    $message=if($module-ceq'core'){'JSON Core: keine kohärente bekannte technische SAFE-Assembly.'}else{'JSON Schema lifecycle: unbekannter oder inkohärenter Releasezustand.'}
    Assert-LifecycleGuardDenied $Db $Mode ('visibility/'+$entry+'/'+$op) ([IO.File]::ReadAllText($path)) $number $message
   }}
  }finally{
   if((Get-LifecycleGuardState $Db)-cne$damaged){throw 'MARKER_ABSENCE_VISIBILITY_RESTORE_DRIFT'}
   if($module-ceq'core'){Sql $Db 'ALTER ASSEMBLY [Toolbelt_JsonCore] WITH VISIBILITY=OFF;'}else{Sql $Db 'ALTER ASSEMBLY [Toolbelt_JsonSchema] WITH VISIBILITY=ON;'}
  }
  if((Get-LifecycleGuardState $Db)-cne$installed){throw 'MARKER_ABSENCE_VISIBILITY_NOT_RESTORED'}
 }
 $actual=@($ledger.profileCompletions|Where-Object mode -CEQ $Mode|ForEach-Object id|Sort-Object)
 $expected=@(Get-LifecycleGuardKeys $Mode $case.CL|Sort-Object)
 if(($actual-join'|')-cne($expected-join'|')){throw 'MARKER_ABSENCE_MODE_COVERAGE'}
 Invoke-ReleaseBatches $Db ([IO.File]::ReadAllText($runset.uninstall));Assert-CoreLockNeutral $Db
 Invoke-ReleaseBatches $Db ([IO.File]::ReadAllText($runset.core_uninstall));Assert-CoreLockNeutral $Db
}
