. (Join-Path $PSScriptRoot 'JsonLifecycle.DependencyContexts.Contract.ps1')
# Neue Werte bei fehlendem und installiertem Schema; alte grüne Profile bleiben getrennt.
function Get-ConstructorValueSpecs{
 foreach($name in @('Toolbelt.Managed','Toolbelt.ModuleId','Toolbelt.ModuleVersion','Toolbelt.DeploymentMode','Toolbelt.AssemblySha512','Toolbelt.ArtifactId')){
  [pscustomobject]@{group='value';id=$name;class=5;name=$name;value=$null}
 }
 foreach($pair in @(@('short','1.3'),@('four-parts','1.3.0.0'),@('negative','1.3.-1'),@('overflow','2147483648.0.0'),@('leading-zero','01.3.0'),@('space','1.3.0 '))){
  [pscustomobject]@{group='version-format';id=$pair[0];class=0;name='Toolbelt.Module.toolbelt.json.constructors.Version';value=$pair[1]}
 }
 foreach($id in @('empty','space','leading-space','unknown')){[pscustomobject]@{group='mode-format';id=$id;class=0;name='Toolbelt.Module.toolbelt.json.constructors.DeploymentMode';value=$null}}
}
function Get-AbsentResultValueSpecs{Get-ResultDependencySpecs|Where-Object group -CNE 'result-object-format'}
function Get-LifecycleGuardKeys([string]$Mode,[int]$CL){
 if($Mode-cnotin@('local','central')-or$CL-notin@(150,160,170)){throw 'DEPENDENCY_VALUES_EXACT_CONTEXT'}
 foreach($parent in @('absent','installed')){foreach($spec in Get-ConstructorValueSpecs){$parent+'-constructor-'+$spec.group+'/'+$spec.id+'/deploy'}}
 foreach($spec in Get-AbsentResultValueSpecs){'absent-'+$spec.group+'/'+$spec.id+'/deploy'}
}
function Get-ConstructorValueParameters($Spec,[string]$Mode){
 if($Mode-cnotin@('local','central')){throw 'DEPENDENCY_VALUES_EXACT_MODE'}
 $known=@(Get-ConstructorValueSpecs|Where-Object{$_.group-ceq$Spec.group-and$_.id-ceq$Spec.id-and$_.class-eq$Spec.class-and$_.name-ceq$Spec.name-and$_.value-ceq$Spec.value})
 if($known.Count-ne1){throw 'DEPENDENCY_VALUES_EXACT_CONSTRUCTOR_VECTOR'}
 $value=if($Spec.group-ceq'mode-format'){switch -CaseSensitive($Spec.id){'empty'{''};'space'{$Mode+' '};'leading-space'{' '+$Mode};'unknown'{'contoso'}}}else{$Spec.value}
 return @{'@Name'=$Spec.name;'@Class'=$Spec.class;'@Value'=$(if($null-eq$value){[DBNull]::Value}else{$value});'@L0'=$(if($Spec.class-eq5){'ASSEMBLY'}else{[DBNull]::Value});'@N0'=$(if($Spec.class-eq5){'Toolbelt_JsonConstructors'}else{[DBNull]::Value})}
}
function Invoke-ConstructorValueGuards($Db,[string]$Mode,[string]$Parent){
 if($Parent-cnotin@('absent','installed')){throw 'DEPENDENCY_VALUES_EXACT_PARENT'}
 Assert-DependencyParent $Db ($Parent-ceq'installed')
 $original=Get-LifecycleGuardState $Db
 Sql $Db @'
SELECT class,major_id,name,value INTO #ConstructorValueOriginals FROM sys.extended_properties
WHERE (class=5 AND major_id=(SELECT assembly_id FROM sys.assemblies WHERE name=N'Toolbelt_JsonConstructors'))
 OR (class=0 AND name IN(N'Toolbelt.Module.toolbelt.json.constructors.Version',N'Toolbelt.Module.toolbelt.json.constructors.DeploymentMode'));
'@
 if([int](Read-Scalar $Db 'SELECT COUNT(*) ScalarValue FROM #ConstructorValueOriginals;')-ne8){throw 'DEPENDENCY_VALUES_EIGHT_ORIGINALS'}
 foreach($spec in Get-ConstructorValueSpecs){
  $parameters=Get-ConstructorValueParameters $spec $Mode
  if($spec.class-eq5){
   Sql $Db @'
DECLARE @V sql_variant,@Bad sql_variant;
SELECT @V=value FROM #ConstructorValueOriginals WHERE class=5 AND name=@Name;
IF @V IS NULL THROW 52098,N'Owned marker missing.',1;
SET @Bad=CASE @Name
 WHEN N'Toolbelt.Managed' THEN CONVERT(sql_variant,CONVERT(int,0))
 WHEN N'Toolbelt.ModuleId' THEN CONVERT(sql_variant,CONVERT(nvarchar(64),LEFT(CONVERT(nvarchar(64),@V),LEN(CONVERT(nvarchar(64),@V))-1)+N'X'))
 WHEN N'Toolbelt.ModuleVersion' THEN CONVERT(sql_variant,CONVERT(nvarchar(16),N'1.3.9'))
 WHEN N'Toolbelt.DeploymentMode' THEN CONVERT(sql_variant,CONVERT(nvarchar(16),UPPER(CONVERT(nvarchar(16),@V))))
 WHEN N'Toolbelt.AssemblySha512' THEN CONVERT(sql_variant,CONVERT(varbinary(64),CONVERT(binary(64),0x00)))
 WHEN N'Toolbelt.ArtifactId' THEN CONVERT(sql_variant,CONVERT(varchar(64),REPLICATE('0',64))) END;
IF SQL_VARIANT_PROPERTY(@V,N'BaseType')<>SQL_VARIANT_PROPERTY(@Bad,N'BaseType')
 OR SQL_VARIANT_PROPERTY(@V,N'MaxLength')<>SQL_VARIANT_PROPERTY(@Bad,N'MaxLength')
 OR DATALENGTH(@V)<>DATALENGTH(@Bad) OR CONVERT(varbinary(max),@V)=CONVERT(varbinary(max),@Bad)
 THROW 52098,N'Value-only fixture must preserve type and length while changing bytes.',1;
EXEC sys.sp_updateextendedproperty @name=@Name,@value=@Bad,@level0type=@L0,@level0name=@N0;
'@ $parameters
  }else{Sql $Db 'DECLARE @V nvarchar(64)=@Value;EXEC sys.sp_updateextendedproperty @name=@Name,@value=@V;' $parameters}
  $damaged=Get-LifecycleGuardState $Db;if($damaged-ceq$original){throw 'DEPENDENCY_VALUES_MUTATION_REQUIRED'}
  try{
   $message=if($spec.class-eq5){'JSON Schema lifecycle: Constructor-Dependencytuple inkohärent.'}else{'JSON Schema lifecycle: vorhandene Constructors zuerst explizit und kohärent auf1.3 migrieren.'}
   Assert-LifecycleGuardDenied $Db $Mode ($Parent+'-constructor-'+$spec.group+'/'+$spec.id+'/deploy') ([IO.File]::ReadAllText($runset.exports.$Mode)) 55633 $message
  }finally{
   if((Get-LifecycleGuardState $Db)-cne$damaged){throw 'DEPENDENCY_VALUES_RESTORE_DRIFT'}
   Sql $Db @'
DECLARE @V sql_variant;
IF (SELECT COUNT(*) FROM #ConstructorValueOriginals WHERE class=@Class AND name=@Name)<>1 THROW 52098,N'Owned original missing.',1;
SELECT @V=value FROM #ConstructorValueOriginals WHERE class=@Class AND name=@Name;
EXEC sys.sp_updateextendedproperty @name=@Name,@value=@V,@level0type=@L0,@level0name=@N0;
'@ $parameters
  }
  if((Get-LifecycleGuardState $Db)-cne$original){throw 'DEPENDENCY_VALUES_TYPED_ORIGINAL_NOT_RESTORED'}
 }
 Sql $Db 'DROP TABLE #ConstructorValueOriginals;'
 Assert-DependencyParent $Db ($Parent-ceq'installed')
}
function Invoke-LifecycleGuardProfiles($Db,[string]$Mode){
 Invoke-ReleaseBatches $Db ([IO.File]::ReadAllText($runset.baselines.$Mode))
 Invoke-ReleaseBatches $Db ([IO.File]::ReadAllText($runset.constructor_exports.$Mode))
 Assert-DependencyParent $Db $false
 Invoke-ConstructorValueGuards $Db $Mode 'absent'
 Invoke-ResultDependencyGuards $Db $Mode @(Get-AbsentResultValueSpecs) 'absent-'
 Assert-DependencyParent $Db $false
 Invoke-ReleaseBatches $Db ([IO.File]::ReadAllText($runset.exports.$Mode))
 Assert-DependencyParent $Db $true
 Invoke-ConstructorValueGuards $Db $Mode 'installed'
 $actual=@($ledger.profileCompletions|Where-Object mode -CEQ $Mode|ForEach-Object id|Sort-Object)
 if(($actual-join'|')-cne(@(Get-LifecycleGuardKeys $Mode $case.CL|Sort-Object)-join'|')){throw 'DEPENDENCY_VALUES_TEN_POINT_CLOSURE'}
 Invoke-ReleaseBatches $Db ([IO.File]::ReadAllText($runset.uninstall));Assert-CoreLockNeutral $Db
 Invoke-ReleaseBatches $Db ([IO.File]::ReadAllText($runset.constructor_uninstall));Assert-CoreLockNeutral $Db
 Invoke-ReleaseBatches $Db ([IO.File]::ReadAllText($runset.core_uninstall));Assert-CoreLockNeutral $Db
}
