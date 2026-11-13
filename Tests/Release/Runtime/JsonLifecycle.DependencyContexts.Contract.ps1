. (Join-Path $PSScriptRoot 'JsonLifecycle.ConstructorDependency.Contract.ps1')
function Get-ResultDependencySpecs{
 [pscustomobject]@{group='result-db-missing';id='Version';class=0;name='Toolbelt.Module.toolbelt.core.result-table.Version';operation='missing';value=$null}
 foreach($kind in @('missing','null')){
  [pscustomobject]@{group='result-module';id=$kind;class=1;name='Toolbelt.ModuleId';operation=$kind;value=$null}
  [pscustomobject]@{group='result-version';id=$kind;class=1;name='Toolbelt.ModuleVersion';operation=$kind;value=$null}
 }
 foreach($pair in @(@('short','1.0'),@('four-parts','1.0.0.0'),@('negative','1.0.-1'),@('overflow','2147483648.0.0'),@('leading-zero','01.0.0'))){
  [pscustomobject]@{group='result-db-format';id=$pair[0];class=0;name='Toolbelt.Module.toolbelt.core.result-table.Version';operation='value';value=$pair[1]}
 }
 foreach($id in @('module-upper','module-space','version-space','version-leading-zero')){
  [pscustomobject]@{group='result-object-format';id=$id;class=1;name=$(if($id.StartsWith('module-')){'Toolbelt.ModuleId'}else{'Toolbelt.ModuleVersion'});operation=$id;value=$null}
 }
}
function Get-LifecycleGuardKeys([string]$Mode,[int]$CL){
 if($Mode-cnotin@('local','central')-or$CL-notin@(150,160,170)){throw 'DEPENDENCY_CONTEXT_EXACT_CONTEXT'}
 foreach($spec in Get-ConstructorDependencySpecs){'absent-'+$spec.group+'/'+$spec.id+'/deploy'}
 foreach($spec in Get-ResultDependencySpecs){$spec.group+'/'+$spec.id+'/deploy'}
}
function Assert-DependencyParent($Db,[bool]$Present){
 $count=[int](Read-Scalar $Db @'
SELECT (SELECT COUNT(*) FROM sys.assemblies WHERE name=N'Toolbelt_JsonSchema')+
 (SELECT COUNT(*) FROM sys.objects WHERE schema_id=SCHEMA_ID(N'toolbelt_json') AND name IN(N'USP_ValidateJsonSchema',N'FT_ValidateJsonSchemaInternal'))+
 (SELECT COUNT(*) FROM sys.extended_properties WHERE class=0 AND name IN(N'Toolbelt.Module.toolbelt.json.schema.Version',N'Toolbelt.Module.toolbelt.json.schema.DeploymentMode')) ScalarValue;
'@)
 if($count-ne$(if($Present){5}else{0})){throw 'DEPENDENCY_CONTEXT_ACTUAL_PARENT_STATE_REQUIRED'}
}
function Get-ResultDependencyParameters($Spec){
 $known=@(Get-ResultDependencySpecs|Where-Object{$_.group-ceq$Spec.group-and$_.id-ceq$Spec.id-and$_.class-eq$Spec.class-and$_.name-ceq$Spec.name-and$_.operation-ceq$Spec.operation-and$_.value-ceq$Spec.value})
 if($known.Count-ne1){throw 'DEPENDENCY_CONTEXT_EXACT_RESULT_VECTOR'}
 return @{'@Name'=$Spec.name;'@Class'=$Spec.class;'@Variant'=$Spec.operation;'@Value'=$(if($null-eq$Spec.value){[DBNull]::Value}else{$Spec.value});'@L0'=$(if($Spec.class-eq0){[DBNull]::Value}else{'SCHEMA'});'@N0'=$(if($Spec.class-eq0){[DBNull]::Value}else{'toolbelt_core'});'@L1'=$(if($Spec.class-eq0){[DBNull]::Value}else{'PROCEDURE'});'@N1'=$(if($Spec.class-eq0){[DBNull]::Value}else{'USP_PrepareResultTable'})}
}
function Invoke-LifecycleGuardProfiles($Db,[string]$Mode){
 Invoke-ReleaseBatches $Db ([IO.File]::ReadAllText($runset.baselines.$Mode))
 Invoke-ReleaseBatches $Db ([IO.File]::ReadAllText($runset.constructor_exports.$Mode))
 Assert-DependencyParent $Db $false
 Invoke-ConstructorDependencyGuards $Db $Mode 'absent-'
 Assert-DependencyParent $Db $false
 Invoke-ReleaseBatches $Db ([IO.File]::ReadAllText($runset.exports.$Mode))
 Assert-DependencyParent $Db $true
 $installed=Get-LifecycleGuardState $Db
 Sql $Db @'
SELECT class,major_id,name,value INTO #DependencyContextResultOriginals FROM sys.extended_properties
WHERE (class=0 AND name=N'Toolbelt.Module.toolbelt.core.result-table.Version')
 OR (class=1 AND major_id=OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable') AND name IN(N'Toolbelt.ModuleId',N'Toolbelt.ModuleVersion'));
'@
 if([int](Read-Scalar $Db 'SELECT COUNT(*) ScalarValue FROM #DependencyContextResultOriginals;')-ne3){throw 'DEPENDENCY_CONTEXT_THREE_ORIGINALS'}
 foreach($spec in Get-ResultDependencySpecs){
  $parameters=Get-ResultDependencyParameters $spec
  if($spec.operation-ceq'missing'){
   Sql $Db 'EXEC sys.sp_dropextendedproperty @name=@Name,@level0type=@L0,@level0name=@N0,@level1type=@L1,@level1name=@N1;' $parameters
  }else{
   Sql $Db @'
DECLARE @V sql_variant,@Bad nvarchar(128);
SELECT @V=value FROM #DependencyContextResultOriginals WHERE class=@Class AND name=@Name;
SET @Bad=CASE @Variant WHEN N'null' THEN NULL WHEN N'module-upper' THEN UPPER(CONVERT(nvarchar(128),@V))
 WHEN N'module-space' THEN CONVERT(nvarchar(128),@V)+N' ' WHEN N'version-space' THEN CONVERT(nvarchar(128),@V)+N' '
 WHEN N'version-leading-zero' THEN N'0'+CONVERT(nvarchar(128),@V) ELSE @Value END;
EXEC sys.sp_updateextendedproperty @name=@Name,@value=@Bad,@level0type=@L0,@level0name=@N0,@level1type=@L1,@level1name=@N1;
'@ $parameters
  }
  $damaged=Get-LifecycleGuardState $Db;if($damaged-ceq$installed){throw 'DEPENDENCY_CONTEXT_RESULT_NOT_CHANGED'}
  try{
   Assert-LifecycleGuardDenied $Db $Mode ($spec.group+'/'+$spec.id+'/deploy') ([IO.File]::ReadAllText($runset.exports.$Mode)) 55632 'JSON Schema lifecycle: registrierte ResultTable-Dependency >=1.0.0 fehlt.'
  }finally{
   if((Get-LifecycleGuardState $Db)-cne$damaged){throw 'DEPENDENCY_CONTEXT_RESULT_RESTORE_DRIFT'}
   $parameters['@Missing']=[int]($spec.operation-ceq'missing')
   Sql $Db @'
DECLARE @V sql_variant;
IF (SELECT COUNT(*) FROM #DependencyContextResultOriginals WHERE class=@Class AND name=@Name)<>1 THROW 52098,N'Owned original marker missing.',1;
SELECT @V=value FROM #DependencyContextResultOriginals WHERE class=@Class AND name=@Name;
IF @Missing=1 EXEC sys.sp_addextendedproperty @name=@Name,@value=@V,@level0type=@L0,@level0name=@N0,@level1type=@L1,@level1name=@N1;
ELSE EXEC sys.sp_updateextendedproperty @name=@Name,@value=@V,@level0type=@L0,@level0name=@N0,@level1type=@L1,@level1name=@N1;
'@ $parameters
  }
  if((Get-LifecycleGuardState $Db)-cne$installed){throw 'DEPENDENCY_CONTEXT_RESULT_ORIGINAL_NOT_RESTORED'}
 }
 Sql $Db 'DROP TABLE #DependencyContextResultOriginals;'
 Assert-DependencyParent $Db $true
 $actual=@($ledger.profileCompletions|Where-Object mode -CEQ $Mode|ForEach-Object id|Sort-Object)
 if(($actual-join'|')-cne(@(Get-LifecycleGuardKeys $Mode $case.CL|Sort-Object)-join'|')){throw 'DEPENDENCY_CONTEXT_TEN_POINT_CLOSURE'}
 Invoke-ReleaseBatches $Db ([IO.File]::ReadAllText($runset.uninstall));Assert-CoreLockNeutral $Db
 Invoke-ReleaseBatches $Db ([IO.File]::ReadAllText($runset.constructor_uninstall));Assert-CoreLockNeutral $Db
 Invoke-ReleaseBatches $Db ([IO.File]::ReadAllText($runset.core_uninstall));Assert-CoreLockNeutral $Db
}
