# Five Schema metadata/input boundaries. No grants, principals or owner repair.
foreach($block in Import-ClrFunctions (Join-Path $repo 'Tests/Release/Invoke-JsonSchemaAppLockLab.ps1') @('Read-Scalar','Get-ModuleState','Get-ExternalSessionState','Test-ExternalSessionIdle')){. $block}
foreach($block in Import-ClrFunctions (Join-Path $repo 'Tests/Release/Invoke-JsonSchemaUninstallAppLockLab.ps1') @('Read-CoreProjection')){. $block}
foreach($block in Import-ClrFunctions (Join-Path $PSScriptRoot 'JsonCore.Lock.Contract.ps1') @('Assert-CoreLockNeutral')){. $block}
function Sql($Connection,[string]$Text,[hashtable]$Parameters=@{},[switch]$Rows){Invoke-ReleaseSql $Connection $Text $Parameters -Rows:$Rows}
function Get-SchemaBoundaryKeys([string]$Mode){
 if($Mode-cnotin@('local','central')){throw 'SCHEMA_BOUNDARY_EXACT_MODE'}
 foreach($name in @('Version','DeploymentMode')){foreach($op in @('deploy','uninstall')){'orphan/'+$name+'/'+$op}}
 foreach($name in @('Toolbelt.Managed','Toolbelt.ModuleId','Toolbelt.ModuleVersion','Toolbelt.DeploymentMode','Toolbelt.AssemblySha512','Toolbelt.ArtifactId')){foreach($op in @('deploy','uninstall')){'typed/'+$name+'/'+$op}}
 foreach($slot in @('USP_ValidateJsonSchema','FT_ValidateJsonSchemaInternal')){foreach($name in @('Toolbelt.ModuleId','Toolbelt.ModuleVersion','Toolbelt.DeploymentMode')){foreach($op in @('deploy','uninstall')){'ownership/'+$slot+'/'+$name+'/'+$op}}}
 'reserved/deploy'
 foreach($name in @('mode-upper','mode-space','confirm-invalid','confirm-space','confirm-leading-zero')){'arguments/'+$name}
 if($Mode-ceq'central'){'arguments/central-unconfirmed'}
}
function Test-SchemaBoundaryCoverage($Rows,[string[]]$Excluded=@()){
 $all=@(foreach($mode in @('local','central')){foreach($key in Get-SchemaBoundaryKeys $mode){$mode+'/'+$key}})
 if(@($Excluded|Select-Object -Unique).Count-ne$Excluded.Count-or@($Excluded|Where-Object{$_-cnotin$all}).Count){return $false}
 $expected=@($all|Where-Object{$_-cnotin$Excluded}|Sort-Object)
 $actual=@($Rows|ForEach-Object{$_.mode+'/'+$_.id}|Sort-Object)
 return [bool](@($Rows).Count-eq$expected.Count-and@($Rows|Where-Object passed -NE $true).Count-eq0-and($expected-join'|')-ceq($actual-join'|'))
}
function Get-SchemaBoundaryReusedKeys{
 # Only guards whose complete executed lifecycle closure is byte-identical.
 # Later public procedure help text is outside these rejection paths.
 $names=@('json-schema-deploy-collision-qualification.json','json-schema-uninstall-confirmation-qualification.json')
 foreach($name in $names){
  $path=Join-Path $repo ('Releases/1.0.0/'+$name)
  if(@($runset.pins|Where-Object path -CEQ $path).Count-ne1){throw 'SCHEMA_BOUNDARY_REUSE_REPORT_PIN'}
  $r=Get-Content $path -Raw|ConvertFrom-Json -DateKind String
  if($r.result-cne'PASS'-or-not$r.execution.final_independent_audit.complete_attempt-or$r.execution.final_independent_audit.status-cne'PASS'){throw 'SCHEMA_BOUNDARY_REUSE_ORIGINAL_PASS_REQUIRED'}
  foreach($p in $r.inputs.source_pins.PSObject.Properties|Where-Object{$_.Name.StartsWith('Modules/toolbelt.json.schema/Deployment/',[StringComparison]::Ordinal)}){
   Assert-ReleasePin (Join-Path $repo $p.Name) $p.Value.ToUpperInvariant()
  }
 }
 if($CaseIndex-eq5){'local/reserved/deploy';'local/orphan/DeploymentMode/deploy';'central/arguments/confirm-leading-zero';'central/arguments/central-unconfirmed'}
 if($runset.PSObject.Properties['partial_tail']){
  $tail=$runset.partial_tail
  if($tail.case_index-ne0){throw 'SCHEMA_BOUNDARY_TAIL_CONTEXT'}
  foreach($binding in @(@{path=$tail.journal;sha256=$tail.journal_sha256},@{path=$tail.audit;sha256=$tail.audit_sha256},@{path=$tail.original_runset;sha256=$tail.original_runset_sha256})){
   [void](Assert-ReleasePrivatePath $binding.path);Assert-ReleasePin $binding.path $binding.sha256
   if(@($runset.pins|Where-Object{$_.path-ceq$binding.path-and$_.sha256-ceq$binding.sha256}).Count-ne1){throw 'SCHEMA_BOUNDARY_TAIL_BINDING'}
  }
  $old=Get-Content $tail.journal -Raw|ConvertFrom-Json -DateKind String
  $audit=Get-Content $tail.audit -Raw|ConvertFrom-Json -DateKind String
  $original=Get-Content $tail.original_runset -Raw|ConvertFrom-Json -DateKind String
  if($old.state-cne'FAILED_CLEANED'-or$audit.state-cne'COMPLETE'-or$audit.originalRunPassed-ne$false-or$audit.originalJournalSHA256-cne$tail.journal_sha256-or-not$audit.databaseAbsence-or-not$audit.serverConfigurationAndTrustUnchanged-or-not$audit.postPins){throw 'SCHEMA_BOUNDARY_TAIL_FRESH_CLEANUP_REQUIRED'}
  if($original.contract_sha256-cne$runset.contract_sha256){throw 'SCHEMA_BOUNDARY_TAIL_CONTRACT_DRIFT'}
  $fixture=Join-Path $repo 'Tests/Release/Runtime/JsonSchema.Boundaries.Contract.ps1'
  $caps=@($original.source_capsules|Where-Object originalPath -CEQ $fixture)
  if($caps.Count-ne1){throw 'SCHEMA_BOUNDARY_TAIL_ORIGINAL_ORACLES_REQUIRED'}
  [void](Assert-ReleasePrivatePath $caps[0].snapshotPath);Assert-ReleasePin $caps[0].snapshotPath $caps[0].sha256
  $e=$null;$beforeAst=[Management.Automation.Language.Parser]::ParseFile($caps[0].snapshotPath,[ref]$null,[ref]$e);if($e.Count){throw 'SCHEMA_BOUNDARY_TAIL_PARSE'}
  $afterAst=[Management.Automation.Language.Parser]::ParseFile($fixture,[ref]$null,[ref]$e);if($e.Count){throw 'SCHEMA_BOUNDARY_TAIL_PARSE'}
  foreach($name in @('Assert-SchemaBoundaryDenied','Test-SchemaBoundaryError','Get-SchemaBoundaryState')){
   $left=@($beforeAst.FindAll({param($n)$n-is[Management.Automation.Language.FunctionDefinitionAst]-and$n.Name-ceq$name},$true))
   $right=@($afterAst.FindAll({param($n)$n-is[Management.Automation.Language.FunctionDefinitionAst]-and$n.Name-ceq$name},$true))
   if($left.Count-ne1-or$right.Count-ne1-or$left[0].Extent.Text.Replace("`r`n","`n")-cne$right[0].Extent.Text.Replace("`r`n","`n")){throw 'SCHEMA_BOUNDARY_TAIL_ORACLE_DRIFT'}
  }
  foreach($pin in @($original.pins|Where-Object{$_.path.StartsWith((Join-Path $repo 'Modules')+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)})){
   Assert-ReleasePin $pin.path $pin.sha256
   if(@($runset.pins|Where-Object{$_.path-ceq$pin.path-and$_.sha256-ceq$pin.sha256}).Count-ne1){throw 'SCHEMA_BOUNDARY_TAIL_PRODUCT_DRIFT'}
  }
  $expected=@('local/reserved/deploy','local/orphan/Version/deploy','local/orphan/Version/uninstall','local/orphan/DeploymentMode/deploy','local/orphan/DeploymentMode/uninstall')|Sort-Object
  $actual=@($old.profileCompletions|ForEach-Object{$_.mode+'/'+$_.id}|Sort-Object)
  if(@($old.profileCompletions|Where-Object passed -NE $true).Count-or($actual-join'|')-cne($expected-join'|')){throw 'SCHEMA_BOUNDARY_TAIL_EXACT_PREFIX'}
  if($CaseIndex-eq0){$actual}
 }
}
function Get-SchemaBoundaryState($Db){
 $types=@(Sql $Db @'
SELECT class,major_id,minor_id,name,
 CONVERT(nvarchar(128),SQL_VARIANT_PROPERTY(value,N'BaseType')) BaseType,
 CONVERT(int,SQL_VARIANT_PROPERTY(value,N'MaxLength')) MaxLength,DATALENGTH(value) Bytes,
 CONVERT(varchar(max),CONVERT(varbinary(max),value),2) Raw
FROM sys.extended_properties WHERE name LIKE N'Toolbelt.%' ORDER BY class,major_id,minor_id,name;
'@ -Rows)
 $schema=@(Sql $Db "SELECT assembly_id,principal_id,permission_set,is_visible FROM sys.assemblies WHERE name=N'Toolbelt_JsonSchema';" -Rows)
 return ([ordered]@{schema=@($schema);module=(Get-ModuleState $Db);core=(Read-CoreProjection $Db);typedProperties=@($types)}|ConvertTo-Json -Depth 6 -Compress)
}
function Invoke-PinnedLifecycle([string]$Operation){
 if($Operation-cnotin@('deploy','uninstall')){throw 'SCHEMA_BOUNDARY_CANONICAL_OPERATION'}
 Assert-ReleaseInputs
 $path=if($Operation-ceq'deploy'){$runset.exports.($script:schemaBoundaryMode)}else{$runset.uninstall}
 Invoke-ReleaseBatches $script:guardConnection ([IO.File]::ReadAllText($path))
}
function Test-SchemaBoundaryError($Errors,[int]$Number,[string]$Message){
 $bad=@($Errors|Where-Object Class -GE 11)
 return [bool]($bad.Count-eq1-and$bad[0].Number-eq$Number-and$bad[0].State-eq1-and$bad[0].Class-eq16-and$bad[0].Message-ceq$Message)
}
function Add-SchemaBoundaryReceipt([string]$Mode,[string]$Id,[int]$Number,[string]$Snapshot){
 $ledger.profileCompletions+=@([ordered]@{mode=$Mode;id=$Id;passed=$true;number=$Number;snapshotPreserved=$true;snapshotSHA256=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($Snapshot)))});Save-ReleaseJournal
}
function Assert-SchemaBoundaryDenied($Db,[string]$Mode,[string]$Id,[string]$Text,[int]$Number,[string]$Message){
 $before=Get-SchemaBoundaryState $Db;$caught=$null
 try{Invoke-ReleaseBatches $Db $Text}catch{$caught=$_.Exception;while($caught.InnerException){$caught=$caught.InnerException}}
 if($caught-isnot[Data.SqlClient.SqlException]-or-not(Test-SchemaBoundaryError $caught.Errors $Number $Message)){throw 'SCHEMA_BOUNDARY_EXACT_ERROR_REQUIRED'}
 if((Get-SchemaBoundaryState $Db)-cne$before){throw 'SCHEMA_BOUNDARY_REJECTED_SCRIPT_MUTATED_STATE'}
 Assert-CoreLockNeutral $Db
 Add-SchemaBoundaryReceipt $Mode $Id $Number $before
}

function Invoke-SchemaBoundaryProfiles($Db,[string]$Mode){
 $script:guardConnection=$Db;$script:schemaBoundaryMode=$Mode
 Invoke-ReleaseBatches $Db ([IO.File]::ReadAllText($runset.baselines.$Mode))
 $empty=Get-SchemaBoundaryState $Db
 # The original reserved caller-temp guard precedes module/dependency inspection.
 if(($Mode+'/reserved/deploy')-cnotin$script:schemaBoundaryExcluded){
  Sql $Db 'CREATE TABLE #tbx_JsonSchema_DeployState(Witness int NOT NULL);INSERT #tbx_JsonSchema_DeployState VALUES(700);'
  try{
   Assert-SchemaBoundaryDenied $Db $Mode 'reserved/deploy' ([IO.File]::ReadAllText($runset.exports.$Mode)) 55633 'JSON Schema lifecycle: reservierter Callerzustand belegt.'
   if([int](Read-Scalar $Db 'SELECT Witness ScalarValue FROM #tbx_JsonSchema_DeployState;')-ne700){throw 'SCHEMA_BOUNDARY_RESERVED_WITNESS_CHANGED'}
  }finally{Sql $Db 'DROP TABLE #tbx_JsonSchema_DeployState;'}
 }
 foreach($suffix in @('Version','DeploymentMode')){
  if(@('deploy','uninstall'|Where-Object{($Mode+'/orphan/'+$suffix+'/'+$_)-cnotin$script:schemaBoundaryExcluded}).Count-eq0){continue}
  $name='Toolbelt.Module.toolbelt.json.schema.'+$suffix;$value=if($suffix-ceq'Version'){'1.0.1'}else{$Mode}
  Sql $Db 'DECLARE @TypedValue nvarchar(16)=@Value;EXEC sys.sp_addextendedproperty @name=@Name,@value=@TypedValue;' @{'@Name'=$name;'@Value'=$value}
  $damaged=Get-SchemaBoundaryState $Db
  try{foreach($op in @('deploy','uninstall')){
   if(($Mode+'/orphan/'+$suffix+'/'+$op)-cin$script:schemaBoundaryExcluded){continue}
   $path=if($op-ceq'deploy'){$runset.exports.$Mode}else{$runset.uninstall}
   $number=if($suffix-ceq'Version'){55633}else{55634}
   $message=if($suffix-ceq'Version'){'JSON Schema lifecycle: unbekannter oder inkohärenter Releasezustand.'}else{'JSON Schema lifecycle: unregistrierter oder fremder Zielslot.'}
   Assert-SchemaBoundaryDenied $Db $Mode ('orphan/'+$suffix+'/'+$op) ([IO.File]::ReadAllText($path)) $number $message
  }}finally{
   if((Get-SchemaBoundaryState $Db)-cne$damaged){throw 'SCHEMA_BOUNDARY_ORPHAN_RESTORE_OWNERSHIP_DRIFT'}
   Sql $Db 'EXEC sys.sp_dropextendedproperty @name=@Name;' @{'@Name'=$name}
  }
  if((Get-SchemaBoundaryState $Db)-cne$empty){throw 'SCHEMA_BOUNDARY_ORPHAN_NOT_RESTORED'}
 }
 Invoke-PinnedLifecycle 'deploy'
 $known=@(Sql $Db "SELECT a.permission_set,a.is_visible,CONVERT(varchar(128),HASHBYTES('SHA2_512',f.content),2) H FROM sys.assemblies a JOIN sys.assembly_files f ON f.assembly_id=a.assembly_id AND f.file_id=1 WHERE a.name=N'Toolbelt_JsonSchema';" -Rows)
 if($known.Count-ne1-or$known[0].permission_set-ne1-or-not$known[0].is_visible-or$known[0].H-cne(Get-FileHash $binary -Algorithm SHA512).Hash){throw 'SCHEMA_BOUNDARY_CURRENT_KNOWN_SCHEMA_REQUIRED'}
 $installed=Get-SchemaBoundaryState $Db
 Sql $Db "SELECT class,major_id,name,value INTO #SchemaBoundaryOriginalMarkers FROM sys.extended_properties WHERE (class=5 AND major_id=(SELECT assembly_id FROM sys.assemblies WHERE name=N'Toolbelt_JsonSchema')) OR (class=1 AND name IN(N'Toolbelt.ModuleId',N'Toolbelt.ModuleVersion',N'Toolbelt.DeploymentMode') AND major_id IN(OBJECT_ID(N'toolbelt_json.USP_ValidateJsonSchema'),OBJECT_ID(N'toolbelt_json.FT_ValidateJsonSchemaInternal')));"
 if([int](Read-Scalar $Db 'SELECT COUNT(*) ScalarValue FROM #SchemaBoundaryOriginalMarkers;')-ne12){throw 'SCHEMA_BOUNDARY_TWELVE_ORIGINAL_MARKERS_REQUIRED'}
 foreach($group in @('typed','ownership')){
  $slots=if($group-ceq'typed'){@('Toolbelt_JsonSchema')}else{@('USP_ValidateJsonSchema','FT_ValidateJsonSchemaInternal')}
  $markers=if($group-ceq'typed'){@('Toolbelt.Managed','Toolbelt.ModuleId','Toolbelt.ModuleVersion','Toolbelt.DeploymentMode','Toolbelt.AssemblySha512','Toolbelt.ArtifactId')}else{@('Toolbelt.ModuleId','Toolbelt.ModuleVersion','Toolbelt.DeploymentMode')}
  foreach($slot in $slots){foreach($name in $markers){
   $level0=if($group-ceq'typed'){'ASSEMBLY'}else{'SCHEMA'};$level0Name=if($group-ceq'typed'){$slot}else{'toolbelt_json'}
   $level1=if($group-ceq'typed'){[DBNull]::Value}elseif($slot-ceq'USP_ValidateJsonSchema'){'PROCEDURE'}else{'FUNCTION'}
   $parameters=@{'@Name'=$name;'@Slot'=$slot;'@Group'=$group;'@L0'=$level0;'@N0'=$level0Name;'@L1'=$level1;'@N1'=$(if($group-ceq'typed'){[DBNull]::Value}else{$slot})}
   Sql $Db @'
DECLARE @Original sql_variant,@Bad sql_variant,@Id int;
SET @Id=CASE WHEN @Group=N'typed' THEN (SELECT assembly_id FROM sys.assemblies WHERE name=@Slot) ELSE OBJECT_ID(N'toolbelt_json.'+QUOTENAME(@Slot)) END;
SELECT @Original=value FROM #SchemaBoundaryOriginalMarkers WHERE class=CASE WHEN @Group=N'typed' THEN 5 ELSE 1 END AND major_id=@Id AND name=@Name;
IF @Original IS NULL THROW 52098,N'Owned original marker missing.',1;
IF @Group=N'typed'
 SET @Bad=CONVERT(varchar(128),CASE WHEN CONVERT(nvarchar(128),SQL_VARIANT_PROPERTY(@Original,N'BaseType'))=N'varbinary' THEN CONVERT(varchar(128),CONVERT(varbinary(64),@Original),2) ELSE CONVERT(varchar(128),@Original) END);
ELSE SET @Bad=CONVERT(nvarchar(64),N'ContosoInvalidOwnership');
EXEC sys.sp_updateextendedproperty @name=@Name,@value=@Bad,@level0type=@L0,@level0name=@N0,@level1type=@L1,@level1name=@N1;
'@ $parameters
   $damaged=Get-SchemaBoundaryState $Db
   if($damaged-ceq$installed){throw 'SCHEMA_BOUNDARY_DRIFT_NOT_VISIBLE'}
   try{foreach($op in @('deploy','uninstall')){
    $id=if($group-ceq'typed'){'typed/'+$name+'/'+$op}else{'ownership/'+$slot+'/'+$name+'/'+$op}
    $message=if($group-ceq'typed'){'JSON Schema lifecycle: typisiertes Assemblymarkertuple inkohärent.'}else{'JSON Schema lifecycle: objektgenaue Ownership inkohärent.'}
    $path=if($op-ceq'deploy'){$runset.exports.$Mode}else{$runset.uninstall}
    Assert-SchemaBoundaryDenied $Db $Mode $id ([IO.File]::ReadAllText($path)) 55633 $message
   }}finally{
    if((Get-SchemaBoundaryState $Db)-cne$damaged){throw 'SCHEMA_BOUNDARY_MARKER_RESTORE_OWNERSHIP_DRIFT'}
    Sql $Db @'
DECLARE @V sql_variant,@Id int;
SET @Id=CASE WHEN @Group=N'typed' THEN (SELECT assembly_id FROM sys.assemblies WHERE name=@Slot) ELSE OBJECT_ID(N'toolbelt_json.'+QUOTENAME(@Slot)) END;
SELECT @V=value FROM #SchemaBoundaryOriginalMarkers WHERE class=CASE WHEN @Group=N'typed' THEN 5 ELSE 1 END AND major_id=@Id AND name=@Name;
EXEC sys.sp_updateextendedproperty @name=@Name,@value=@V,@level0type=@L0,@level0name=@N0,@level1type=@L1,@level1name=@N1;
'@ $parameters
   }
   if((Get-SchemaBoundaryState $Db)-cne$installed){throw 'SCHEMA_BOUNDARY_ORIGINAL_NOT_RESTORED'}
  }}
 }
 Sql $Db 'DROP TABLE #SchemaBoundaryOriginalMarkers;'
 foreach($argument in $runset.argument_scripts){
  if(($argument.id-ceq'central-unconfirmed'-and$Mode-ceq'local')-or($Mode+'/arguments/'+$argument.id)-cin$script:schemaBoundaryExcluded){continue}
  $number=if($argument.operation-ceq'deploy'){55631}else{55635}
  $message=if($argument.operation-ceq'deploy'){'JSON Schema lifecycle: ungültiger Deploymentmodus.'}elseif($argument.id-ceq'central-unconfirmed'){'JSON Schema lifecycle: zentrale Consumer-Bestätigung fehlt.'}else{'JSON Schema lifecycle: ungültige Consumer-Bestätigung.'}
  Assert-SchemaBoundaryDenied $Db $Mode ('arguments/'+$argument.id) ([IO.File]::ReadAllText($argument.path)) $number $message
 }
 $actual=@($ledger.profileCompletions|Where-Object mode -CEQ $Mode|ForEach-Object id|Sort-Object)
 $expected=@(Get-SchemaBoundaryKeys $Mode|Where-Object{($Mode+'/'+$_)-cnotin$script:schemaBoundaryExcluded}|Sort-Object)
 if(($actual-join'|')-cne($expected-join'|')){throw 'SCHEMA_BOUNDARY_FIVE_POINT_COVERAGE_REQUIRED'}
 Invoke-PinnedLifecycle 'uninstall';Assert-CoreLockNeutral $Db
}
