# Five remaining caller/lock/foreign-slot matrices. No new grants or identities.
foreach($block in Import-ClrFunctions (Join-Path $repo 'Tests/Release/Invoke-JsonSchemaAppLockLab.ps1') @('Read-Scalar','Get-ModuleState','Get-ExternalSessionState','Test-ExternalSessionIdle','Acquire-HolderLock','Assert-HolderLock','Assert-ExternalHolderGranted')){. $block}
foreach($block in Import-ClrFunctions (Join-Path $repo 'Tests/Release/Invoke-JsonSchemaUninstallAppLockLab.ps1') @('Read-CoreProjection')){. $block}
foreach($block in Import-ClrFunctions (Join-Path $repo 'Tests/Release/Invoke-JsonSchemaCallerTransactionLab.ps1') @('Get-WitnessValue','Get-LocalTransactionState','Assert-ExternalActiveTransaction','Invoke-BlockedTransactionCase')){. $block}
foreach($block in Import-ClrFunctions (Join-Path $PSScriptRoot 'JsonCore.Lock.Contract.ps1') @('Assert-CoreLockNeutral')){. $block}
function Sql($Connection,[string]$Text,[hashtable]$Parameters=@{},[switch]$Rows){Invoke-ReleaseSql $Connection $Text $Parameters -Rows:$Rows}
function Save-Journal{Save-ReleaseJournal}
function Get-SchemaRestKeys([string]$Mode){
 if($Mode-cnotin@('local','central')){throw 'SCHEMA_REST_EXACT_MODE'}
 foreach($group in @('caller-missing','caller-installed')){foreach($xa in @(0,1)){foreach($nc in @(0,1)){foreach($op in @('deploy','uninstall')){$group+'/xa'+$xa+'nc'+$nc+'/'+$op}}}}
 foreach($op in @('deploy','uninstall')){foreach($resource in @('shared-core','module')){foreach($stage in @('blocked','after-release')){'locks-'+$op+'/'+$resource+'/'+$stage}}}
 foreach($slot in @('USP_ValidateJsonSchema','FT_ValidateJsonSchemaInternal')){foreach($op in @('deploy','uninstall')){'foreign/'+$slot+'/'+$op}}
}
function Test-SchemaRestCoverage($Rows,[string[]]$Excluded=@()){
 $all=@(foreach($mode in @('local','central')){foreach($key in Get-SchemaRestKeys $mode){$mode+'/'+$key}})
 if(@($Excluded|Select-Object -Unique).Count-ne$Excluded.Count-or@($Excluded|Where-Object{$_-cnotin$all}).Count){return $false}
 $expected=@($all|Where-Object{$_-cnotin$Excluded}|Sort-Object);$actual=@($Rows|ForEach-Object{$_.mode+'/'+$_.id}|Sort-Object)
 return [bool](@($Rows).Count-eq$expected.Count-and@($Rows|Where-Object passed -NE $true).Count-eq0-and($expected-join'|')-ceq($actual-join'|'))
}
function Get-SchemaRestReusedKeys{
 # Existing transaction-holder lock records and foreign-slot guards use this exact executed closure.
 foreach($name in @('json-schema-deploy-lock-qualification.json','json-schema-uninstall-lock-qualification.json','json-schema-deploy-collision-qualification.json','json-schema-caller-transaction-qualification.json')){
  $path=Join-Path $repo ('Releases/1.0.0/'+$name)
  if(@($runset.pins|Where-Object path -CEQ $path).Count-ne1){throw 'SCHEMA_REST_REUSE_PUBLIC_PIN'}
  $r=Get-Content $path -Raw|ConvertFrom-Json -DateKind String
  if($r.result-cne'PASS'-or$r.execution.final_independent_audit.status-cne'PASS'-or-not$r.execution.final_independent_audit.complete_attempt){throw 'SCHEMA_REST_REUSE_PUBLIC_PASS'}
  if($r.scope.target.platform-cne'windows'-or$r.scope.target.sql_server_version-cne'2025'-or$r.scope.target.patch-cne'CU8'-or$r.scope.target.compatibility_level-ne170-or$r.scope.deployment_mode-cne'local'){throw 'SCHEMA_REST_REUSE_PUBLIC_CONTEXT'}
  foreach($pin in $r.inputs.source_pins.PSObject.Properties|Where-Object{$_.Name.StartsWith('Modules/toolbelt.json.schema/Deployment/',[StringComparison]::Ordinal)}){Assert-ReleasePin (Join-Path $repo $pin.Name) $pin.Value.ToUpperInvariant()}
 }
 if($runset.reuse.Count-ne3-or@($runset.reuse.id|Sort-Object -Unique).Count-ne3){throw 'SCHEMA_REST_PRIVATE_REUSE_CLOSURE'}
 $expectedCounts=@{'missing-nocount'=2;'missing-xact'=4;installed=3}
 foreach($item in $runset.reuse){
  if($item.id-cnotin@('missing-nocount','missing-xact','installed')){throw 'SCHEMA_REST_REUSE_ID'}
  foreach($field in @('journal','audit','inputs')){
   $binding=$item.$field;[void](Assert-ReleasePrivatePath $binding.path);Assert-ReleasePin $binding.path $binding.sha256
   if(@($runset.pins|Where-Object{$_.path-ceq$binding.path-and$_.sha256-ceq$binding.sha256}).Count-ne1){throw 'SCHEMA_REST_REUSE_PRIVATE_PIN'}
  }
  $j=Get-Content $item.journal.path -Raw|ConvertFrom-Json -DateKind String;$a=Get-Content $item.audit.path -Raw|ConvertFrom-Json -DateKind String
  $original=Get-Content $item.inputs.path -Raw|ConvertFrom-Json -DateKind String
  if($original.cases.Count-ne1-or$original.cases[0].Platform-cne'windows'-or$original.cases[0].Version-cne'2025'-or$original.cases[0].Patch-cne'CU8'-or$original.cases[0].CL-ne170-or(@($original.cases[0].modes)-join',')-cne'local'){throw 'SCHEMA_REST_REUSE_PRIVATE_CONTEXT'}
  foreach($op in @('Deploy','Uninstall')){
   $path=Join-Path $repo ('Modules/toolbelt.json.schema/Deployment/'+$op+'.sql')
   $pins=@($original.pins|Where-Object path -CEQ $path)
   if($pins.Count-ne1){throw 'SCHEMA_REST_REUSE_ORIGINAL_SCRIPT_REQUIRED'};Assert-ReleasePin $path $pins[0].sha256
  }
  if($item.id-ceq'installed'){
   foreach($name in @('JsonSchemaBridge.sql','USP_ValidateJsonSchema.sql')){
    $path=Join-Path $repo ('Modules/toolbelt.json.schema/Source/'+$name);$pins=@($original.pins|Where-Object path -CEQ $path)
    if($pins.Count-ne1){throw 'SCHEMA_REST_REUSE_CURRENT_INSTALLED_SOURCE'};Assert-ReleasePin $path $pins[0].sha256
   }
  }
  if($j.state-cne'COMPLETE'-or$j.failure-or$j.results.Count-ne$expectedCounts[$item.id]-or$a.state-cne'COMPLETE'-or-not$a.originalRunPassed-or$a.originalJournalSHA256-cne$item.journal.sha256-or-not$a.databaseAbsence-or-not$a.serverConfigurationAndTrustUnchanged-or-not$a.postPins){throw 'SCHEMA_REST_REUSE_PRIVATE_PASS'}
  foreach($row in $j.results){
   foreach($flag in @('blocked','exact_error','transaction_preserved','session_preserved','options_preserved','module_snapshot_preserved','witness_preserved','application_locks_absent')){if($row.$flag-ne$true){throw 'SCHEMA_REST_REUSE_ORIGINAL_ORACLE'}}
   if($CaseIndex-eq5){
    $group=if($item.id-ceq'installed'){'caller-installed'}else{'caller-missing'}
    'local/'+$group+'/xa'+[int][bool]$row.xact_abort+'nc'+[int][bool]$row.nocount+'/'+$row.operation
   }
  }
 }
 if($CaseIndex-eq5){
  'local/caller-installed/xa0nc0/uninstall'
  foreach($op in @('deploy','uninstall')){foreach($resource in @('shared-core','module')){foreach($stage in @('blocked','after-release')){'local/locks-'+$op+'/'+$resource+'/'+$stage}}}
  foreach($slot in @('USP_ValidateJsonSchema','FT_ValidateJsonSchemaInternal')){'local/foreign/'+$slot+'/deploy'}
 }
}
function Get-SchemaRestState($Db){
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
 if($Operation-cnotin@('deploy','uninstall')){throw 'SCHEMA_REST_CANONICAL_OPERATION'}
 Assert-ReleaseInputs
 $path=if($Operation-ceq'deploy'){$runset.exports.($script:schemaRestMode)}else{$runset.uninstall}
 Invoke-ReleaseBatches $script:guardConnection ([IO.File]::ReadAllText($path))
}
function Test-SchemaRestError($Errors,[int]$Number,[string]$Message){
 $bad=@($Errors|Where-Object Class -GE 11)
 return [bool]($bad.Count-eq1-and$bad[0].Number-eq$Number-and$bad[0].State-eq1-and$bad[0].Class-eq16-and$bad[0].Message-ceq$Message)
}
function Add-SchemaRestReceipt([string]$Mode,[string]$Id,[int]$Number,[string]$Snapshot){
 $positive=$Id-cmatch'^locks-(deploy|uninstall)/(shared-core|module)/after-release$'
 if($positive-ne($Number-eq0)){throw 'SCHEMA_REST_RECEIPT_PHASE_MISMATCH'}
 $receipt=[ordered]@{mode=$Mode;id=$Id;passed=$true;number=$Number;snapshotSHA256=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($Snapshot)))}
 if($positive){$receipt['canonicalState']=$true;$receipt['snapshotPhase']='after-positive'}
 else{$receipt['snapshotPreserved']=$true;$receipt['snapshotPhase']='before-denial'}
 $ledger.profileCompletions+=@($receipt);Save-ReleaseJournal
}
function Assert-SchemaRestDenied($Db,[string]$Mode,[string]$Id,[string]$Text,[int]$Number,[string]$Message){
 $before=Get-SchemaRestState $Db;$caught=$null
 try{Invoke-ReleaseBatches $Db $Text}catch{$caught=$_.Exception;while($caught.InnerException){$caught=$caught.InnerException}}
 if($caught-isnot[Data.SqlClient.SqlException]-or-not(Test-SchemaRestError $caught.Errors $Number $Message)){throw 'SCHEMA_REST_EXACT_ERROR_REQUIRED'}
 if((Get-SchemaRestState $Db)-cne$before){throw 'SCHEMA_REST_REJECTED_SCRIPT_MUTATED_STATE'}
 Assert-CoreLockNeutral $Db
 Add-SchemaRestReceipt $Mode $Id $Number $before
}


function Invoke-SchemaRestCallers($Db,[string]$Mode,[string]$Group){
 foreach($xa in @(0,1)){foreach($nc in @(0,1)){foreach($op in @('deploy','uninstall')){
  $id=$Group+'/xa'+$xa+'nc'+$nc+'/'+$op;if(($Mode+'/'+$id)-cin$script:schemaRestExcluded){continue}
  $xaText=if($xa){'ON'}else{'OFF'};$ncText=if($nc){'ON'}else{'OFF'}
  Sql $Db "SET QUOTED_IDENTIFIER ON;SET IMPLICIT_TRANSACTIONS OFF;SET XACT_ABORT $xaText;SET NOCOUNT $ncText;"
  $options=[int](Read-Scalar $Db 'SELECT @@OPTIONS ScalarValue;')
  if(($options-band256)-eq0-or($options-band2)-ne0-or[bool]($options-band16384)-ne[bool]$xa-or[bool]($options-band512)-ne[bool]$nc){throw 'SCHEMA_REST_ACTUAL_OPTIONS'}
  $before=Get-SchemaRestState $Db;$prior=$ledger.results.Count
  $c=[pscustomobject]@{ordinal=$prior;operation=$op;expected_message='JSON_SCHEMA_CALLER_TRANSACTION: aktive Callertransaktion ausgeschlossen.'}
  Invoke-BlockedTransactionCase $Db $control $c (Get-ModuleState $Db) $options
  if($ledger.results.Count-ne($prior+1)-or(Get-SchemaRestState $Db)-cne$before){throw 'SCHEMA_REST_CALLER_RECEIPT'}
  $ledger.results[-1]['mode']=$Mode;$ledger.results[-1]['group']=$Group;$ledger.results[-1]['xa']=$xa;$ledger.results[-1]['nc']=$nc
  Add-SchemaRestReceipt $Mode $id 50000 $before
 }}}
 Sql $Db 'SET NOCOUNT ON;SET XACT_ABORT ON;'
}
function Assert-SchemaRestAbsent($Db){
 $n=[int](Read-Scalar $Db "SELECT (SELECT COUNT(*) FROM sys.assemblies WHERE name=N'Toolbelt_JsonSchema')+(SELECT COUNT(*) FROM sys.objects WHERE schema_id=SCHEMA_ID(N'toolbelt_json'))+(SELECT COUNT(*) FROM sys.extended_properties WHERE class=0 AND name LIKE N'Toolbelt.Module.toolbelt.json.schema.%') ScalarValue;")
 if($n-ne0){throw 'SCHEMA_REST_MODULE_NOT_ABSENT'}
}
function Invoke-SchemaRestLocks($Db,[string]$Mode,[string]$Operation){
 foreach($resourceId in @('shared-core','module')){
  $id='locks-'+$Operation+'/'+$resourceId
  if(($Mode+'/'+$id+'/blocked')-cin$script:schemaRestExcluded){continue}
  if($Operation-ceq'uninstall'){Invoke-PinnedLifecycle 'deploy'}else{Assert-SchemaRestAbsent $Db}
  $resource=if($resourceId-ceq'shared-core'){'toolbelt.deploy.json.shared-core'}else{'toolbelt.deploy.toolbelt.json.schema'}
  $message=if($resourceId-ceq'shared-core'){'JSON Schema lifecycle: gemeinsame Core-AppLock nicht verfügbar.'}else{'JSON Schema lifecycle: Modul-AppLock nicht verfügbar.'}
  $holder=Open-ReleaseConnection $Db.Database
  try{
   $holderSpid=Acquire-HolderLock $holder $resource;Assert-ExternalHolderGranted $control $holderSpid
   $before=Get-SchemaRestState $Db;$beforeCore=Read-CoreProjection $Db
   $path=if($Operation-ceq'deploy'){$runset.exports.$Mode}else{$runset.uninstall}
   Assert-SchemaRestDenied $Db $Mode ($id+'/blocked') ([IO.File]::ReadAllText($path)) 55637 $message
   Assert-HolderLock $holder $holderSpid;Assert-ExternalHolderGranted $control $holderSpid
   $held=@(Sql $holder "SELECT APPLOCK_MODE(N'public',@Resource,N'Transaction') M;" @{'@Resource'=$resource} -Rows)
   if($held.Count-ne1-or$held[0].M-cne'Exclusive'){throw 'SCHEMA_REST_EXACT_HOLDER_RESOURCE'}
   Sql $holder 'ROLLBACK TRANSACTION;';Assert-CoreLockNeutral $holder
   $released=@(Sql $holder "SELECT COUNT(*) N FROM sys.dm_tran_locks WHERE request_session_id=@@SPID AND resource_type=N'APPLICATION';" -Rows)
   if($released.Count-ne1-or$released[0].N-ne0){throw 'SCHEMA_REST_HOLDER_RELEASE'}
   Invoke-PinnedLifecycle $Operation;Assert-CoreLockNeutral $Db
   if((Read-CoreProjection $Db)-cne$beforeCore){throw 'SCHEMA_REST_POSITIVE_CHANGED_DEPENDENCIES'}
   if($Operation-ceq'deploy'){
    $known=@(Sql $Db "SELECT a.permission_set,a.is_visible,CONVERT(varchar(128),HASHBYTES('SHA2_512',f.content),2) H FROM sys.assemblies a JOIN sys.assembly_files f ON f.assembly_id=a.assembly_id AND f.file_id=1 WHERE a.name=N'Toolbelt_JsonSchema';" -Rows)
    if($known.Count-ne1-or$known[0].permission_set-ne1-or-not$known[0].is_visible-or$known[0].H-cne(Get-FileHash $binary -Algorithm SHA512).Hash){throw 'SCHEMA_REST_POSITIVE_KNOWN_BINARY'}
   }else{Assert-SchemaRestAbsent $Db}
   Add-SchemaRestReceipt $Mode ($id+'/after-release') 0 (Get-SchemaRestState $Db)
   if($Operation-ceq'deploy'){Invoke-PinnedLifecycle 'uninstall';Assert-SchemaRestAbsent $Db}
  }finally{if($holder.State-eq[Data.ConnectionState]::Open){Sql $holder 'IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;'};$holder.Dispose()}
 }
}
function Invoke-SchemaRestProfiles($Db,[string]$Mode){
 $script:guardConnection=$Db;$script:schemaRestMode=$Mode
 Sql $Db 'CREATE TABLE dbo.JsonSchemaCallerTransactionWitness(WitnessId int NOT NULL PRIMARY KEY,WitnessValue int NOT NULL);INSERT dbo.JsonSchemaCallerTransactionWitness VALUES(1,100);'
 # Empty-module caller inputs; no dependency metadata is touched by the early guard.
 Invoke-SchemaRestCallers $Db $Mode 'caller-missing'
 Invoke-ReleaseBatches $Db ([IO.File]::ReadAllText($runset.baselines.$Mode));$core=Read-CoreProjection $Db
 Invoke-SchemaRestLocks $Db $Mode 'deploy'
 Assert-SchemaRestAbsent $Db
 Sql $Db "IF SCHEMA_ID(N'toolbelt_json') IS NULL EXEC(N'CREATE SCHEMA toolbelt_json;');"
 foreach($slot in @('USP_ValidateJsonSchema','FT_ValidateJsonSchemaInternal')){
  Sql $Db ("CREATE TABLE toolbelt_json.["+$slot+"](Witness int NOT NULL);INSERT toolbelt_json.["+$slot+"] VALUES(701);")
  $before=Get-SchemaRestState $Db
  try{foreach($op in @('deploy','uninstall')){
   $id='foreign/'+$slot+'/'+$op;if(($Mode+'/'+$id)-cin$script:schemaRestExcluded){continue}
   $path=if($op-ceq'deploy'){$runset.exports.$Mode}else{$runset.uninstall}
   Assert-SchemaRestDenied $Db $Mode $id ([IO.File]::ReadAllText($path)) 55634 'JSON Schema lifecycle: unregistrierter oder fremder Zielslot.'
   if([int](Read-Scalar $Db ("SELECT Witness ScalarValue FROM toolbelt_json.["+$slot+"];"))-ne701){throw 'SCHEMA_REST_FOREIGN_DATA_CHANGED'}
  }}finally{
   if((Get-SchemaRestState $Db)-cne$before){throw 'SCHEMA_REST_FOREIGN_OWNERSHIP_DRIFT'}
   Sql $Db ("DROP TABLE toolbelt_json.["+$slot+"];")
  }
 }
 Invoke-PinnedLifecycle 'deploy';Invoke-SchemaRestCallers $Db $Mode 'caller-installed'
 Invoke-SchemaRestLocks $Db $Mode 'uninstall'
 # Win2025 local lock profiles are reused; remove its setup only once.
 if([int](Read-Scalar $Db "SELECT COUNT(*) ScalarValue FROM sys.assemblies WHERE name=N'Toolbelt_JsonSchema';")-eq1){Invoke-PinnedLifecycle 'uninstall'}
 Assert-SchemaRestAbsent $Db;Assert-CoreLockNeutral $Db
 if((Read-CoreProjection $Db)-cne$core){throw 'SCHEMA_REST_FINAL_DEPENDENCIES_CHANGED'}
 $actual=@($ledger.profileCompletions|Where-Object mode -CEQ $Mode|ForEach-Object id|Sort-Object)
 $expected=@(Get-SchemaRestKeys $Mode|Where-Object{($Mode+'/'+$_)-cnotin$script:schemaRestExcluded}|Sort-Object)
 if(($actual-join'|')-cne($expected-join'|')){throw 'SCHEMA_REST_FIVE_POINT_COVERAGE'}
}
