# Five direct Core boundaries. Existing Schema caller oracles are reused as functions.
foreach($block in Import-ClrFunctions (Join-Path $repo 'Tests/Release/Invoke-JsonSchemaAppLockLab.ps1') @('Read-Scalar','Get-ModuleState','Get-ExternalSessionState','Test-ExternalSessionIdle')){. $block}
foreach($block in Import-ClrFunctions (Join-Path $repo 'Tests/Release/Invoke-JsonSchemaUninstallAppLockLab.ps1') @('Read-CoreProjection')){. $block}
foreach($block in Import-ClrFunctions (Join-Path $repo 'Tests/Release/Invoke-JsonSchemaCallerTransactionLab.ps1') @('Get-WitnessValue','Get-LocalTransactionState','Assert-ExternalActiveTransaction','Invoke-BlockedTransactionCase')){. $block}
foreach($block in Import-ClrFunctions (Join-Path $PSScriptRoot 'JsonCore.Lock.Contract.ps1') @('Assert-CoreLockNeutral')){. $block}
function Sql($Connection,[string]$Text,[hashtable]$Parameters=@{},[switch]$Rows){Invoke-ReleaseSql $Connection $Text $Parameters -Rows:$Rows}
function Save-Journal{Save-ReleaseJournal}
function Get-CoreBoundaryKeys([string]$Mode){
 if($Mode-cnotin@('local','central')){throw 'CORE_BOUNDARY_EXACT_MODE'}
 $keys=[Collections.Generic.List[string]]::new()
 foreach($group in @('caller-absent','caller-installed')){foreach($xa in @(0,1)){foreach($nc in @(0,1)){foreach($op in @('deploy','uninstall')){$keys.Add($group+'/xa'+$xa+'nc'+$nc+'/'+$op)}}}}
 foreach($name in @('Version','DeploymentMode')){foreach($op in @('deploy','uninstall')){$keys.Add('orphan/'+$name+'/'+$op)}}
 foreach($name in @('Toolbelt.Managed','Toolbelt.ModuleId','Toolbelt.ModuleVersion','Toolbelt.DeploymentMode','Toolbelt.AssemblySha512','Toolbelt.ArtifactId')){foreach($op in @('deploy','uninstall')){$keys.Add('typed/'+$name+'/'+$op)}}
 foreach($name in @('mode-upper','mode-space','confirm-invalid','confirm-space')){$keys.Add('arguments/'+$name)}
 if($Mode-ceq'central'){$keys.Add('arguments/central-unconfirmed')}
 return $keys.ToArray()
}
function Test-CoreBoundaryCoverage($Rows){
 $expected=@(foreach($mode in @('local','central')){foreach($key in Get-CoreBoundaryKeys $mode){$mode+'/'+$key}})|Sort-Object
 $actual=@($Rows|ForEach-Object{$_.mode+'/'+$_.id}|Sort-Object)
 return [bool](@($Rows).Count-eq73-and@($Rows|Where-Object passed -NE $true).Count-eq0-and($expected-join'|')-ceq($actual-join'|'))
}
function Get-CoreBoundaryState($Db){
 $types=@(Sql $Db @'
SELECT class,major_id,minor_id,name,
 CONVERT(nvarchar(128),SQL_VARIANT_PROPERTY(value,N'BaseType')) BaseType,
 CONVERT(int,SQL_VARIANT_PROPERTY(value,N'MaxLength')) MaxLength,DATALENGTH(value) Bytes,
 CONVERT(varchar(max),CONVERT(varbinary(max),value),2) Raw
FROM sys.extended_properties WHERE name LIKE N'Toolbelt.%' ORDER BY class,major_id,minor_id,name;
'@ -Rows)
 return ([ordered]@{module=(Get-ModuleState $Db);core=(Read-CoreProjection $Db);typedProperties=@($types)}|ConvertTo-Json -Depth 6 -Compress)
}
function Invoke-PinnedLifecycle([string]$Operation){
 if($Operation-cnotin@('deploy','uninstall')){throw 'CORE_BOUNDARY_CANONICAL_OPERATION'}
 Assert-ReleaseInputs
 $path=if($Operation-ceq'deploy'){$runset.exports.($script:coreBoundaryMode)}else{$runset.uninstall}
 Invoke-ReleaseBatches $script:guardConnection ([IO.File]::ReadAllText($path))
}
function Test-CoreBoundaryError($Errors,[int]$Number,[string]$Message){
 $bad=@($Errors|Where-Object Class -GE 11)
 return [bool]($bad.Count-eq1-and$bad[0].Number-eq$Number-and$bad[0].State-eq1-and$bad[0].Class-eq16-and$bad[0].Message-ceq$Message)
}
function Add-CoreBoundaryReceipt([string]$Mode,[string]$Id,[int]$Number,[string]$Snapshot){
 $ledger.profileCompletions+=@([ordered]@{mode=$Mode;id=$Id;passed=$true;number=$Number;snapshotPreserved=$true;snapshotSHA256=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($Snapshot)))});Save-ReleaseJournal
}
function Assert-CoreBoundaryDenied($Db,[string]$Mode,[string]$Id,[string]$Text,[int]$Number,[string]$Message){
 $before=Get-CoreBoundaryState $Db;$caught=$null
 try{Invoke-ReleaseBatches $Db $Text}catch{$caught=$_.Exception;while($caught.InnerException){$caught=$caught.InnerException}}
 if($caught-isnot[Data.SqlClient.SqlException]-or-not(Test-CoreBoundaryError $caught.Errors $Number $Message)){throw 'CORE_BOUNDARY_EXACT_ERROR_REQUIRED'}
 if((Get-CoreBoundaryState $Db)-cne$before){throw 'CORE_BOUNDARY_REJECTED_SCRIPT_MUTATED_STATE'}
 Assert-CoreLockNeutral $Db
 Add-CoreBoundaryReceipt $Mode $Id $Number $before
}
function Invoke-CoreBoundaryCallerGroup($Db,[string]$Mode,[string]$Group){
 if($Group-cnotin@('caller-absent','caller-installed')){throw 'CORE_BOUNDARY_CALLER_GROUP'}
 foreach($xa in @(0,1)){foreach($nc in @(0,1)){
  $xaText=if($xa){'ON'}else{'OFF'};$ncText=if($nc){'ON'}else{'OFF'}
  Sql $Db "SET QUOTED_IDENTIFIER ON;SET IMPLICIT_TRANSACTIONS OFF;SET XACT_ABORT $xaText;SET NOCOUNT $ncText;"
  $options=[int](Read-Scalar $Db 'SELECT @@OPTIONS ScalarValue;')
  if(($options-band256)-eq0-or($options-band2)-ne0-or[bool]($options-band16384)-ne[bool]$xa-or[bool]($options-band512)-ne[bool]$nc){throw 'CORE_BOUNDARY_ACTUAL_CALLER_OPTIONS'}
  foreach($operation in @('deploy','uninstall')){
   $before=Get-CoreBoundaryState $Db;$prior=$ledger.results.Count
   $case=[pscustomobject]@{ordinal=$prior;operation=$operation;expected_message='JSON_CORE_CALLER_TRANSACTION: aktive Callertransaktion ausgeschlossen.'}
   Invoke-BlockedTransactionCase $Db $control $case (Get-ModuleState $Db) $options
   if($ledger.results.Count-ne($prior+1)-or(Get-CoreBoundaryState $Db)-cne$before){throw 'CORE_BOUNDARY_ORIGINAL_CALLER_RECEIPT_REQUIRED'}
   $ledger.results[-1]['mode']=$Mode;$ledger.results[-1]['group']=$Group;$ledger.results[-1]['xa']=$xa;$ledger.results[-1]['nc']=$nc
   Add-CoreBoundaryReceipt $Mode ($Group+'/xa'+$xa+'nc'+$nc+'/'+$operation) 50000 $before
  }
 }}
 Sql $Db 'SET XACT_ABORT ON;SET NOCOUNT ON;'
}
function Invoke-CoreBoundaryProfiles($Db,[string]$Mode){
 $script:guardConnection=$Db;$script:coreBoundaryMode=$Mode
 Sql $Db 'CREATE TABLE dbo.JsonSchemaCallerTransactionWitness(WitnessId int NOT NULL PRIMARY KEY,WitnessValue int NOT NULL);INSERT dbo.JsonSchemaCallerTransactionWitness VALUES(1,100);'
 $empty=Get-CoreBoundaryState $Db
 Invoke-CoreBoundaryCallerGroup $Db $Mode 'caller-absent'
 # Point 3: an orphan DB marker must be preserved, never adopted or removed.
 foreach($suffix in @('Version','DeploymentMode')){
  $name='Toolbelt.Module.toolbelt.json.core.'+$suffix;$value=if($suffix-ceq'Version'){'1.0.0'}else{$Mode}
  Sql $Db 'EXEC sys.sp_addextendedproperty @name=@Name,@value=@Value;' @{'@Name'=$name;'@Value'=$value}
  $damaged=Get-CoreBoundaryState $Db
  try{foreach($op in @('deploy','uninstall')){
   $path=if($op-ceq'deploy'){$runset.exports.$Mode}else{$runset.uninstall}
   Assert-CoreBoundaryDenied $Db $Mode ('orphan/'+$suffix+'/'+$op) ([IO.File]::ReadAllText($path)) 55623 'JSON Core: erforderliche bekannte Dependency fehlt oder ist inkohärent.'
  }}finally{
   if((Get-CoreBoundaryState $Db)-cne$damaged){throw 'CORE_BOUNDARY_ORPHAN_RESTORE_OWNERSHIP_DRIFT'}
   Sql $Db 'EXEC sys.sp_dropextendedproperty @name=@Name;' @{'@Name'=$name}
  }
  if((Get-CoreBoundaryState $Db)-cne$empty){throw 'CORE_BOUNDARY_ORPHAN_NOT_RESTORED'}
 }
 Invoke-PinnedLifecycle 'deploy'
 $known=@(Sql $Db "SELECT a.assembly_id Id,a.permission_set,a.is_visible,CONVERT(varchar(128),HASHBYTES('SHA2_512',f.content),2) H FROM sys.assemblies a JOIN sys.assembly_files f ON f.assembly_id=a.assembly_id AND f.file_id=1 WHERE a.name=N'Toolbelt_JsonCore';" -Rows)
 if($known.Count-ne1-or$known[0].permission_set-ne1-or$known[0].is_visible-or$known[0].H-cne(Get-FileHash $binary -Algorithm SHA512).Hash){throw 'CORE_BOUNDARY_CURRENT_KNOWN_CORE_REQUIRED'}
 $installed=Get-CoreBoundaryState $Db
 Invoke-CoreBoundaryCallerGroup $Db $Mode 'caller-installed'
 # Point 4: preserve exact typed tuples, using a caller-local sql_variant copy.
 Sql $Db "SELECT name,value INTO #CoreBoundaryOriginalMarkers FROM sys.extended_properties WHERE class=5 AND major_id=ASSEMBLY_ID(N'Toolbelt_JsonCore');"
 if([int](Read-Scalar $Db 'SELECT COUNT(*) ScalarValue FROM #CoreBoundaryOriginalMarkers;')-ne6){throw 'CORE_BOUNDARY_SIX_ORIGINAL_MARKERS_REQUIRED'}
 foreach($name in @('Toolbelt.Managed','Toolbelt.ModuleId','Toolbelt.ModuleVersion','Toolbelt.DeploymentMode','Toolbelt.AssemblySha512','Toolbelt.ArtifactId')){
  Sql $Db @'
DECLARE @Original sql_variant,@Bad sql_variant;
SELECT @Original=value FROM #CoreBoundaryOriginalMarkers WHERE name=@Name;
IF @Original IS NULL THROW 52098,N'Owned original marker missing.',1;
SET @Bad=CONVERT(varchar(128),CASE WHEN CONVERT(nvarchar(128),SQL_VARIANT_PROPERTY(@Original,N'BaseType'))=N'varbinary'
 THEN CONVERT(varchar(128),CONVERT(varbinary(64),@Original),2) ELSE CONVERT(varchar(128),@Original) END);
EXEC sys.sp_updateextendedproperty @name=@Name,@value=@Bad,@level0type=N'ASSEMBLY',@level0name=N'Toolbelt_JsonCore';
'@ @{'@Name'=$name}
  $damaged=Get-CoreBoundaryState $Db
  if($damaged-ceq$installed){throw 'CORE_BOUNDARY_TYPE_DRIFT_NOT_VISIBLE'}
  try{foreach($op in @('deploy','uninstall')){
   $path=if($op-ceq'deploy'){$runset.exports.$Mode}else{$runset.uninstall}
   Assert-CoreBoundaryDenied $Db $Mode ('typed/'+$name+'/'+$op) ([IO.File]::ReadAllText($path)) 55623 'JSON Core: typisiertes bekanntes Markertuple ist inkohärent.'
  }}finally{
   if((Get-CoreBoundaryState $Db)-cne$damaged){throw 'CORE_BOUNDARY_TYPED_RESTORE_OWNERSHIP_DRIFT'}
   Sql $Db "DECLARE @V sql_variant;SELECT @V=value FROM #CoreBoundaryOriginalMarkers WHERE name=@Name;EXEC sys.sp_updateextendedproperty @name=@Name,@value=@V,@level0type=N'ASSEMBLY',@level0name=N'Toolbelt_JsonCore';" @{'@Name'=$name}
  }
  if((Get-CoreBoundaryState $Db)-cne$installed){throw 'CORE_BOUNDARY_TYPED_ORIGINAL_NOT_RESTORED'}
 }
 Sql $Db 'DROP TABLE #CoreBoundaryOriginalMarkers;'
 # Point 5: canonical input variants, no replacement of public guard SQL.
 foreach($argument in $runset.argument_scripts){
  if($argument.id-ceq'central-unconfirmed'-and$Mode-ceq'local'){continue}
  $number=if($argument.operation-ceq'deploy'){55621}else{55625}
  $message=if($argument.operation-ceq'deploy'){'JSON Core: ungültiger Deploymentmodus.'}elseif($argument.id-ceq'central-unconfirmed'){'JSON Core: zentrale Consumer-Bestätigung fehlt.'}else{'JSON Core: ungültige Consumer-Bestätigung.'}
  Assert-CoreBoundaryDenied $Db $Mode ('arguments/'+$argument.id) ([IO.File]::ReadAllText($argument.path)) $number $message
 }
 if((Get-CoreBoundaryState $Db)-cne$installed){throw 'CORE_BOUNDARY_FINAL_INSTALLED_IDENTITY_DRIFT'}
 $actual=@($ledger.profileCompletions|Where-Object mode -CEQ $Mode|ForEach-Object id|Sort-Object)
 $expected=@(Get-CoreBoundaryKeys $Mode|Sort-Object)
 if(($actual-join'|')-cne($expected-join'|')){throw 'CORE_BOUNDARY_FIVE_POINT_COVERAGE_REQUIRED'}
 # Final successful teardown is cleanup after newly exercised drift profiles.
 Invoke-PinnedLifecycle 'uninstall';Assert-CoreLockNeutral $Db
}
