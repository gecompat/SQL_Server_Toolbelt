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
 foreach($path in @('core','delegated-schema')){foreach($op in @('deploy','uninstall')){'visibility/'+$path+'/'+$op}}
 'visibility/schema/engine-denied'
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
function Get-MarkerAbsenceReusedKeys{
 if(-not$runset.PSObject.Properties['reuse']){return}
 if($CaseIndex-ne0){return}
 $reuse=$runset.reuse
 foreach($binding in @($reuse.journal,$reuse.audit,$reuse.runset)){
  [void](Assert-ReleasePrivatePath $binding.path);Assert-ReleasePin $binding.path $binding.sha256
  if(@($runset.pins|Where-Object{$_.path-ceq$binding.path-and$_.sha256-ceq$binding.sha256}).Count-ne1){throw 'MARKER_ABSENCE_REUSE_PIN'}
 }
 $old=Get-Content $reuse.journal.path -Raw|ConvertFrom-Json -DateKind String
 $audit=Get-Content $reuse.audit.path -Raw|ConvertFrom-Json -DateKind String
 $prior=Get-Content $reuse.runset.path -Raw|ConvertFrom-Json -DateKind String
 if($old.state-cne'FAILED_CLEANED'-or$audit.state-cne'COMPLETE'-or$audit.originalRunPassed-ne$false-or$audit.originalJournalSHA256-cne$reuse.journal.sha256-or-not$audit.databaseAbsence-or-not$audit.serverConfigurationAndTrustUnchanged-or-not$audit.postPins){throw 'MARKER_ABSENCE_REUSE_FRESH_CLEANUP'}
 if($prior.contract_sha256-cne$runset.contract_sha256){throw 'MARKER_ABSENCE_REUSE_LAB_DRIFT'}
 foreach($field in @('Platform','Version','Patch','CL')){if($prior.cases[0].$field-cne$runset.cases[0].$field){throw 'MARKER_ABSENCE_REUSE_CONTEXT_DRIFT'}}
 foreach($pin in @($prior.pins|Where-Object{$_.path.StartsWith((Join-Path $repo 'Modules')+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)-or$_.path-ceq(Join-Path $repo 'Tests/Release/Runtime/JsonLifecycle.BinaryRegistration.Contract.ps1')})){
  Assert-ReleasePin $pin.path $pin.sha256
  if(@($runset.pins|Where-Object{$_.path-ceq$pin.path-and$_.sha256-ceq$pin.sha256}).Count-ne1){throw 'MARKER_ABSENCE_REUSE_PRODUCT_OR_ORACLE_DRIFT'}
 }
 $caps=@($prior.source_capsules|Where-Object originalPath -CEQ (Join-Path $repo 'Tests/Release/Runtime/JsonLifecycle.MarkerAbsenceVisibility.Contract.ps1'))
 if($caps.Count-ne1){throw 'MARKER_ABSENCE_REUSE_SOURCE_CAPSULE'}
 [void](Assert-ReleasePrivatePath $caps[0].snapshotPath);Assert-ReleasePin $caps[0].snapshotPath $caps[0].sha256
 $errors=$null;$oldAst=[Management.Automation.Language.Parser]::ParseFile($caps[0].snapshotPath,[ref]$null,[ref]$errors);if($errors.Count){throw 'MARKER_ABSENCE_REUSE_OLD_PARSE'}
 $newAst=[Management.Automation.Language.Parser]::ParseFile((Join-Path $repo 'Tests/Release/Runtime/JsonLifecycle.MarkerAbsenceVisibility.Contract.ps1'),[ref]$null,[ref]$errors);if($errors.Count){throw 'MARKER_ABSENCE_REUSE_NEW_PARSE'}
 foreach($name in @('Get-MarkerAbsenceSpecs','Get-MarkerAbsenceParameters','Get-MarkerAbsenceError','Get-LifecycleGuardState')){
  $left=@($oldAst.FindAll({param($n)$n-is[Management.Automation.Language.FunctionDefinitionAst]-and$n.Name-ceq$name},$true));$right=@($newAst.FindAll({param($n)$n-is[Management.Automation.Language.FunctionDefinitionAst]-and$n.Name-ceq$name},$true))
  if($left.Count-ne1-or$right.Count-ne1-or$left[0].Extent.Text.Replace("`r`n","`n")-cne$right[0].Extent.Text.Replace("`r`n","`n")){throw 'MARKER_ABSENCE_REUSE_ORACLE_CHANGED'}
 }
 $expected=@(Get-LifecycleGuardKeys 'local' $case.CL|Where-Object{$_-cne'visibility/schema/engine-denied'}|ForEach-Object{'local/'+$_}|Sort-Object)
 if(-not(Test-MarkerAbsencePrefix $old.profileCompletions)){throw 'MARKER_ABSENCE_REUSE_EXACT_PREFIX'}
 return $expected
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
  if(($Mode+'/'+$spec.group+'/'+$spec.slot+'/'+$spec.name+'/'+$variant+'/deploy')-cin$script:lifecycleGuardExcluded){continue}
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
 if(($Mode+'/visibility/core/deploy')-cnotin$script:lifecycleGuardExcluded){
  Sql $Db 'ALTER ASSEMBLY [Toolbelt_JsonCore] WITH VISIBILITY=ON;'
  $damaged=Get-LifecycleGuardState $Db;if($damaged-ceq$installed){throw 'MARKER_ABSENCE_VISIBILITY_NOT_CHANGED'}
  try{foreach($entry in @('core','delegated-schema')){foreach($op in @('deploy','uninstall')){
   $target=if($entry-ceq'core'){'core'}else{'schema'}
   $path=Get-LifecycleGuardScript $target $op $Mode
   Assert-LifecycleGuardDenied $Db $Mode ('visibility/'+$entry+'/'+$op) ([IO.File]::ReadAllText($path)) 55623 'JSON Core: keine kohärente bekannte technische SAFE-Assembly.'
  }}}finally{
   if((Get-LifecycleGuardState $Db)-cne$damaged){throw 'MARKER_ABSENCE_VISIBILITY_RESTORE_DRIFT'}
   Sql $Db 'ALTER ASSEMBLY [Toolbelt_JsonCore] WITH VISIBILITY=OFF;'
  }
  if((Get-LifecycleGuardState $Db)-cne$installed){throw 'MARKER_ABSENCE_VISIBILITY_NOT_RESTORED'}
 }
 $before=Get-LifecycleGuardState $Db;$caught=$null
 try{Sql $Db 'ALTER ASSEMBLY [Toolbelt_JsonSchema] WITH VISIBILITY=OFF;'}catch{$caught=$_.Exception;while($caught.InnerException){$caught=$caught.InnerException}}
 if($caught-isnot[Data.SqlClient.SqlException]-or-not(Test-MarkerVisibilityEngineError $caught.Errors)){throw 'MARKER_ABSENCE_ENGINE_GUARD_REQUIRED'}
 if((Get-LifecycleGuardState $Db)-cne$before){throw 'MARKER_ABSENCE_ENGINE_DENIAL_CHANGED_STATE'}
 Assert-CoreLockNeutral $Db
 Add-LifecycleGuardReceipt $Mode 'visibility/schema/engine-denied' 6284 $before
 $ledger.profileCompletions[-1]['engineState']=@($caught.Errors|Where-Object Class -GE 11)[0].State;Save-ReleaseJournal
 $actual=@($ledger.profileCompletions|Where-Object mode -CEQ $Mode|ForEach-Object id|Sort-Object)
 $expected=@(Get-LifecycleGuardKeys $Mode $case.CL|Where-Object{($Mode+'/'+$_)-cnotin$script:lifecycleGuardExcluded}|Sort-Object)
 if(($actual-join'|')-cne($expected-join'|')){throw 'MARKER_ABSENCE_MODE_COVERAGE'}
 Invoke-ReleaseBatches $Db ([IO.File]::ReadAllText($runset.uninstall));Assert-CoreLockNeutral $Db
 Invoke-ReleaseBatches $Db ([IO.File]::ReadAllText($runset.core_uninstall));Assert-CoreLockNeutral $Db
}

function Test-MarkerVisibilityEngineError($Errors){
 $bad=@($Errors|Where-Object Class -GE 11)
 return [bool]($bad.Count-eq1-and$bad[0].Number-eq6284-and$bad[0].Class-eq16-and$bad[0].Message-ceq"ALTER ASSEMBLY failed because it is referenced by object 'FT_ValidateJsonSchemaInternal'. Assemblies that are referenced by SQL objects cannot be made invisible.")
}

function Test-MarkerAbsencePrefix($Rows){
 $expected=@(Get-LifecycleGuardKeys 'local' $case.CL|Where-Object{$_-cne'visibility/schema/engine-denied'}|ForEach-Object{'local/'+$_}|Sort-Object)
 $actual=@($Rows|ForEach-Object{$_.mode+'/'+$_.id}|Sort-Object)
 return [bool]($actual.Count-eq76-and($actual-join'|')-ceq($expected-join'|')-and@($Rows|Where-Object{-not$_.passed-or-not$_.snapshotPreserved}).Count-eq0)
}
