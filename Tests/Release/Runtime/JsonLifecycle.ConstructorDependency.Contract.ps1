. (Join-Path $PSScriptRoot 'JsonLifecycle.BinaryRegistration.Contract.ps1')
foreach($block in Import-ClrFunctions (Join-Path $PSScriptRoot 'JsonSchema.DependencySignature.Contract.ps1') @('Get-SchemaGuardState')){. $block}
function Get-LifecycleGuardState($Db){
 $refs=@(Sql $Db "SELECT assembly_id,referenced_assembly_id FROM sys.assembly_references WHERE assembly_id=(SELECT assembly_id FROM sys.assemblies WHERE name=N'Toolbelt_JsonConstructors') ORDER BY referenced_assembly_id;" -Rows)
 return ([ordered]@{baseline=(Get-SchemaGuardState $Db);constructorReferences=@($refs)}|ConvertTo-Json -Depth 7 -Compress)
}
function Get-ConstructorDependencySpecs{
 foreach($group in @('typed','missing','null')){foreach($name in @('Toolbelt.Managed','Toolbelt.ModuleId','Toolbelt.ModuleVersion','Toolbelt.DeploymentMode','Toolbelt.AssemblySha512','Toolbelt.ArtifactId')){[pscustomobject]@{group=$group;id=$name;class=5;name=$name}}}
 foreach($id in @('missing','null','old','noncanonical')){[pscustomobject]@{group='version';id=$id;class=0;name='Toolbelt.Module.toolbelt.json.constructors.Version'}}
 foreach($id in @('missing','null','upper','opposite')){[pscustomobject]@{group='mode';id=$id;class=0;name='Toolbelt.Module.toolbelt.json.constructors.DeploymentMode'}}
}
function Get-LifecycleGuardKeys([string]$Mode,[int]$CL){
 if($Mode-cnotin@('local','central')-or$CL-notin@(150,160,170)){throw 'CONSTRUCTOR_DEPENDENCY_EXACT_CONTEXT'}
 foreach($spec in Get-ConstructorDependencySpecs){$spec.group+'/'+$spec.id+'/deploy'}
}
function Get-ConstructorDependencyError($Spec){
 if($Spec.group-cin@('typed','missing','null')){'JSON Schema lifecycle: Constructor-Dependencytuple inkohärent.'}
 elseif($Spec.group-cin@('version','mode')){'JSON Schema lifecycle: vorhandene Constructors zuerst explizit und kohärent auf1.3 migrieren.'}
 else{throw 'CONSTRUCTOR_DEPENDENCY_ERROR_SCOPE'}
}
function Invoke-LifecycleGuardProfiles($Db,[string]$Mode){
 Invoke-ReleaseBatches $Db ([IO.File]::ReadAllText($runset.baselines.$Mode))
 Invoke-ReleaseBatches $Db ([IO.File]::ReadAllText($runset.constructor_exports.$Mode))
 Invoke-ReleaseBatches $Db ([IO.File]::ReadAllText($runset.exports.$Mode))
 $installed=Get-LifecycleGuardState $Db
 Sql $Db @'
SELECT class,major_id,name,value INTO #ConstructorDependencyOriginals FROM sys.extended_properties
WHERE (class=5 AND major_id=(SELECT assembly_id FROM sys.assemblies WHERE name=N'Toolbelt_JsonConstructors'))
 OR (class=0 AND name IN(N'Toolbelt.Module.toolbelt.json.constructors.Version',N'Toolbelt.Module.toolbelt.json.constructors.DeploymentMode'));
'@
 if([int](Read-Scalar $Db 'SELECT COUNT(*) ScalarValue FROM #ConstructorDependencyOriginals;')-ne8){throw 'CONSTRUCTOR_DEPENDENCY_EIGHT_ORIGINALS'}
 foreach($spec in Get-ConstructorDependencySpecs){
  $drop=($spec.group-ceq'missing'-or($spec.class-eq0-and$spec.id-ceq'missing'))
  $parameters=@{'@Name'=$spec.name;'@Class'=$spec.class;'@L0'=$(if($spec.class-eq5){'ASSEMBLY'}else{[DBNull]::Value});'@N0'=$(if($spec.class-eq5){'Toolbelt_JsonConstructors'}else{[DBNull]::Value})}
  if($drop){
   Sql $Db 'EXEC sys.sp_dropextendedproperty @name=@Name,@level0type=@L0,@level0name=@N0;' $parameters
  }elseif($spec.group-ceq'typed'){
   Sql $Db @'
DECLARE @V sql_variant,@Bad sql_variant;
SELECT @V=value FROM #ConstructorDependencyOriginals WHERE class=5 AND name=@Name;
IF @V IS NULL THROW 52098,N'Owned original marker missing.',1;
SET @Bad=CONVERT(varchar(128),CASE WHEN CONVERT(nvarchar(128),SQL_VARIANT_PROPERTY(@V,N'BaseType'))=N'varbinary' THEN CONVERT(varchar(128),CONVERT(varbinary(64),@V),2) ELSE CONVERT(varchar(128),@V) END);
EXEC sys.sp_updateextendedproperty @name=@Name,@value=@Bad,@level0type=@L0,@level0name=@N0;
'@ $parameters
  }else{
   $value=if($spec.group-ceq'null'-or$spec.id-ceq'null'){[DBNull]::Value}
    elseif($spec.id-ceq'old'){'1.2.0'}elseif($spec.id-ceq'noncanonical'){'1.3.00'}
    elseif($spec.id-ceq'upper'){$Mode.ToUpperInvariant()}
    elseif($spec.id-ceq'opposite'){if($Mode-ceq'local'){'central'}else{'local'}}
    else{throw 'CONSTRUCTOR_DEPENDENCY_VALUE_SCOPE'}
   $parameters['@Value']=$value
   Sql $Db 'DECLARE @V nvarchar(64)=@Value;EXEC sys.sp_updateextendedproperty @name=@Name,@value=@V,@level0type=@L0,@level0name=@N0;' $parameters
  }
  $damaged=Get-LifecycleGuardState $Db;if($damaged-ceq$installed){throw 'CONSTRUCTOR_DEPENDENCY_FIXTURE_NOT_CHANGED'}
  try{
   Assert-LifecycleGuardDenied $Db $Mode ($spec.group+'/'+$spec.id+'/deploy') ([IO.File]::ReadAllText($runset.exports.$Mode)) 55633 (Get-ConstructorDependencyError $spec)
  }finally{
   if((Get-LifecycleGuardState $Db)-cne$damaged){throw 'CONSTRUCTOR_DEPENDENCY_RESTORE_DRIFT'}
   $parameters['@Missing']=[int]$drop
   Sql $Db @'
DECLARE @V sql_variant;
IF (SELECT COUNT(*) FROM #ConstructorDependencyOriginals WHERE class=@Class AND name=@Name)<>1 THROW 52098,N'Owned original tuple missing.',1;
SELECT @V=value FROM #ConstructorDependencyOriginals WHERE class=@Class AND name=@Name;
IF @Missing=1 EXEC sys.sp_addextendedproperty @name=@Name,@value=@V,@level0type=@L0,@level0name=@N0;
ELSE EXEC sys.sp_updateextendedproperty @name=@Name,@value=@V,@level0type=@L0,@level0name=@N0;
'@ $parameters
  }
  if((Get-LifecycleGuardState $Db)-cne$installed){throw 'CONSTRUCTOR_DEPENDENCY_ORIGINAL_NOT_RESTORED'}
 }
 Sql $Db 'DROP TABLE #ConstructorDependencyOriginals;'
 $actual=@($ledger.profileCompletions|Where-Object mode -CEQ $Mode|ForEach-Object id|Sort-Object)
 if(($actual-join'|')-cne(@(Get-LifecycleGuardKeys $Mode $case.CL|Sort-Object)-join'|')){throw 'CONSTRUCTOR_DEPENDENCY_MODE_CLOSURE'}
 Invoke-ReleaseBatches $Db ([IO.File]::ReadAllText($runset.uninstall));Assert-CoreLockNeutral $Db
 Invoke-ReleaseBatches $Db ([IO.File]::ReadAllText($runset.constructor_uninstall));Assert-CoreLockNeutral $Db
 Invoke-ReleaseBatches $Db ([IO.File]::ReadAllText($runset.core_uninstall));Assert-CoreLockNeutral $Db
}
