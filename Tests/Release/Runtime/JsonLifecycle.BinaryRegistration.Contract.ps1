# Own DB registration fixtures and canonical original public scripts; no grants/owners.
foreach($block in Import-ClrFunctions (Join-Path $repo 'Tests/Release/Invoke-JsonSchemaAppLockLab.ps1') @('Read-Scalar','Get-ModuleState','Get-ExternalSessionState','Test-ExternalSessionIdle')){. $block}
foreach($block in Import-ClrFunctions (Join-Path $repo 'Tests/Release/Invoke-JsonSchemaUninstallAppLockLab.ps1') @('Read-CoreProjection')){. $block}
foreach($block in Import-ClrFunctions (Join-Path $PSScriptRoot 'JsonCore.Lock.Contract.ps1') @('Assert-CoreLockNeutral')){. $block}
function Sql($Connection,[string]$Text,[hashtable]$Parameters=@{},[switch]$Rows){Invoke-ReleaseSql $Connection $Text $Parameters -Rows:$Rows}
function Get-LifecycleGuardOwnDatabaseName($Db){
 $entries=@($ledger.databases|Where-Object name -CEQ $Db.Database)
 if($entries.Count-ne1-or$entries[0].state-cne'OWNED'-or$entries[0].name-cne('Toolbelt_Release_'+$ledger.owner+'_'+$entries[0].suffix)){throw 'LIFECYCLE_GUARD_OWN_DATABASE_REQUIRED'}
 $entry=$entries[0]
 $actual=@(Sql $control 'SELECT database_id Id,CONVERT(varchar(16),CONVERT(varbinary(8),create_date),2) Created FROM sys.databases WHERE name=@Name;' @{'@Name'=$entry.name} -Rows)
 $owner=@(Sql $Db "SELECT CONVERT(nvarchar(32),value) Owner FROM sys.extended_properties WHERE class=0 AND name=N'Test.Release.Owner';" -Rows)
 if($actual.Count-ne1-or$actual[0].Id-ne$entry.id-or$actual[0].Created-cne$entry.created-or$owner.Count-ne1-or$owner[0].Owner-cne$ledger.owner){throw 'LIFECYCLE_GUARD_OWN_DATABASE_IDENTITY_DRIFT'}
 return $entry.name
}
function Get-LifecycleGuardKeys([string]$Mode,[int]$CL){
 if($Mode-cnotin@('local','central')-or$CL-notin@(150,160,170)){throw 'LIFECYCLE_GUARD_EXACT_CONTEXT'}
 foreach($module in @('core','schema')){
  foreach($id in @('null','empty','zero','other')){'binary-'+$module+'/'+$id}
  foreach($id in @('version-null','version-old','version-noncanonical','mode-null','mode-upper','mode-opposite')){foreach($op in @('deploy','uninstall')){'registration-'+$module+'/'+$id+'/'+$op}}
  if($CL-eq150){foreach($op in @('deploy','uninstall')){'compat140/'+$module+'/'+$op}}
 }
}
function Test-LifecycleGuardCoverage($Rows,[string[]]$Excluded=@()){
 $all=@(foreach($mode in @('local','central')){foreach($id in Get-LifecycleGuardKeys $mode $case.CL){$mode+'/'+$id}})
 if(@($Excluded|Select-Object -Unique).Count-ne$Excluded.Count-or@($Excluded|Where-Object{$_-cnotin$all}).Count){return $false}
 $expected=@($all|Where-Object{$_-cnotin$Excluded}|Sort-Object);$actual=@($Rows|ForEach-Object{$_.mode+'/'+$_.id}|Sort-Object)
 return [bool](@($Rows|Where-Object passed -NE $true).Count-eq0-and($expected-join'|')-ceq($actual-join'|'))
}
function Get-LifecycleGuardRegistrationError([string]$Module,[string]$Id,[string]$Operation){
 if($Module-cnotin@('core','schema')-or$Operation-cnotin@('deploy','uninstall')-or$Id-cnotin@('version-null','version-old','version-noncanonical','mode-null','mode-upper','mode-opposite')){throw 'LIFECYCLE_GUARD_EXACT_ERROR_INPUT'}
 $number=if($Module-ceq'core'){55623}else{55633}
 $message=if($Module-ceq'core'){'JSON Core: keine kohärente bekannte technische SAFE-Assembly.'}else{'JSON Schema lifecycle: unbekannter oder inkohärenter Releasezustand.'}
 if($Module-ceq'schema'-and$Id-ceq'version-null'){$number=55634;$message='JSON Schema lifecycle: unregistrierter oder fremder Zielslot.'}
 if($Operation-ceq'uninstall'){
  if($Id-ceq'mode-upper'){$message=if($Module-ceq'core'){'JSON Core: inkohärenter installierter Modus.'}else{'JSON Schema lifecycle: inkohärenter installierter Modus.'}}
  if($Id-ceq'mode-opposite'){$message=if($Module-ceq'core'){'JSON Core: typisiertes bekanntes Markertuple ist inkohärent.'}else{'JSON Schema lifecycle: typisiertes Assemblymarkertuple inkohärent.'}}
 }
 return [pscustomobject]@{number=$number;message=$message}
}
function Get-LifecycleGuardScript([string]$Module,[string]$Operation,[string]$Mode){
 if($Module-cnotin@('core','schema')-or$Operation-cnotin@('deploy','uninstall')-or$Mode-cnotin@('local','central')){throw 'LIFECYCLE_GUARD_SCRIPT_SCOPE'}
 if($Module-ceq'core'){if($Operation-ceq'deploy'){$runset.core_exports.$Mode}else{$runset.core_uninstall}}
 else{if($Operation-ceq'deploy'){$runset.exports.$Mode}else{$runset.uninstall}}
}
function Get-LifecycleGuardState($Db){
 $types=@(Sql $Db @'
SELECT class,major_id,minor_id,name,
 CONVERT(nvarchar(128),SQL_VARIANT_PROPERTY(value,N'BaseType')) BaseType,
 CONVERT(int,SQL_VARIANT_PROPERTY(value,N'MaxLength')) MaxLength,DATALENGTH(value) Bytes,
 CONVERT(varchar(max),CONVERT(varbinary(max),value),2) Raw
FROM sys.extended_properties WHERE name LIKE N'Toolbelt.%' ORDER BY class,major_id,minor_id,name;
'@ -Rows)
 $schema=@(Sql $Db "SELECT assembly_id,principal_id,permission_set,is_visible FROM sys.assemblies WHERE name=N'Toolbelt_JsonSchema';" -Rows)
 $compat=[int](Read-Scalar $Db 'SELECT compatibility_level ScalarValue FROM sys.databases WHERE database_id=DB_ID();')
 $owner=@(Sql $Db "SELECT DB_ID() Id,CONVERT(nvarchar(32),value) Owner FROM sys.extended_properties WHERE class=0 AND name=N'Test.Release.Owner';" -Rows)
 return ([ordered]@{compatibilityLevel=$compat;ownedIdentity=@($owner);schema=@($schema);module=(Get-ModuleState $Db);core=(Read-CoreProjection $Db);typedProperties=@($types)}|ConvertTo-Json -Depth 6 -Compress)
}
function Test-LifecycleGuardError($Errors,[int]$Number,[string]$Message){
 $bad=@($Errors|Where-Object Class -GE 11)
 return [bool]($bad.Count-eq1-and$bad[0].Number-eq$Number-and$bad[0].State-eq1-and$bad[0].Class-eq16-and$bad[0].Message-ceq$Message)
}
function Add-LifecycleGuardReceipt([string]$Mode,[string]$Id,[int]$Number,[string]$Snapshot){
 $ledger.profileCompletions+=@([ordered]@{mode=$Mode;id=$Id;passed=$true;number=$Number;snapshotPreserved=$true;snapshotSHA256=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($Snapshot)))});Save-ReleaseJournal
}
function Assert-LifecycleGuardDenied($Db,[string]$Mode,[string]$Id,[string]$Text,[int]$Number,[string]$Message){
 $before=Get-LifecycleGuardState $Db;$caught=$null
 try{Invoke-ReleaseBatches $Db $Text}catch{$caught=$_.Exception;while($caught.InnerException){$caught=$caught.InnerException}}
 if($caught-isnot[Data.SqlClient.SqlException]-or-not(Test-LifecycleGuardError $caught.Errors $Number $Message)){throw 'LIFECYCLE_GUARD_EXACT_ERROR_REQUIRED'}
 if((Get-LifecycleGuardState $Db)-cne$before){throw 'LIFECYCLE_GUARD_REJECTED_SCRIPT_MUTATED_STATE'}
 Assert-CoreLockNeutral $Db
 Add-LifecycleGuardReceipt $Mode $Id $Number $before
}


function Invoke-LifecycleGuardProfiles($Db,[string]$Mode){
 foreach($row in $runset.binary_guards){
  $number=if($row.module-ceq'core'){55623}else{55633}
  $message=if($row.module-ceq'core'){'JSON Core: Targetbinary ist kein bekanntes qualifiziertes Artefakt.'}else{'JSON Schema lifecycle: Targetbinary ist kein bekanntes qualifiziertes Artefakt.'}
  Assert-LifecycleGuardDenied $Db $Mode ('binary-'+$row.module+'/'+$row.id) ([IO.File]::ReadAllText($row.paths.$Mode)) $number $message
 }
 Invoke-ReleaseBatches $Db ([IO.File]::ReadAllText($runset.baselines.$Mode))
 Invoke-ReleaseBatches $Db ([IO.File]::ReadAllText($runset.exports.$Mode))
 $installed=Get-LifecycleGuardState $Db
 Sql $Db "SELECT name,value INTO #LifecycleGuardOriginalDbMarkers FROM sys.extended_properties WHERE class=0 AND name IN(N'Toolbelt.Module.toolbelt.json.core.Version',N'Toolbelt.Module.toolbelt.json.core.DeploymentMode',N'Toolbelt.Module.toolbelt.json.schema.Version',N'Toolbelt.Module.toolbelt.json.schema.DeploymentMode');"
 if([int](Read-Scalar $Db 'SELECT COUNT(*) ScalarValue FROM #LifecycleGuardOriginalDbMarkers;')-ne4){throw 'LIFECYCLE_GUARD_FOUR_ORIGINAL_DB_MARKERS'}
 foreach($module in @('core','schema')){foreach($id in @('version-null','version-old','version-noncanonical','mode-null','mode-upper','mode-opposite')){
  $suffix=if($id.StartsWith('version-',[StringComparison]::Ordinal)){'Version'}else{'DeploymentMode'}
  $name='Toolbelt.Module.toolbelt.json.'+$module+'.'+$suffix
  $value=switch -CaseSensitive($id){
   'version-null'{[DBNull]::Value};'mode-null'{[DBNull]::Value};'version-old'{'0.0.0'};
   'version-noncanonical'{if($module-ceq'core'){'1.0.00'}else{'1.0.01'}};
   'mode-upper'{$Mode.ToUpperInvariant()};'mode-opposite'{if($Mode-ceq'local'){'central'}else{'local'}}
  }
  Sql $Db 'DECLARE @V nvarchar(64)=@Value;EXEC sys.sp_updateextendedproperty @name=@Name,@value=@V;' @{'@Name'=$name;'@Value'=$value}
  $damaged=Get-LifecycleGuardState $Db;if($damaged-ceq$installed){throw 'LIFECYCLE_GUARD_REGISTRATION_NOT_CHANGED'}
  try{foreach($op in @('deploy','uninstall')){
   $errorExpected=Get-LifecycleGuardRegistrationError $module $id $op
   $path=Get-LifecycleGuardScript $module $op $Mode
   Assert-LifecycleGuardDenied $Db $Mode ('registration-'+$module+'/'+$id+'/'+$op) ([IO.File]::ReadAllText($path)) $errorExpected.number $errorExpected.message
  }}finally{
   if((Get-LifecycleGuardState $Db)-cne$damaged){throw 'LIFECYCLE_GUARD_REGISTRATION_RESTORE_DRIFT'}
   Sql $Db 'DECLARE @V sql_variant;SELECT @V=value FROM #LifecycleGuardOriginalDbMarkers WHERE name=@Name;EXEC sys.sp_updateextendedproperty @name=@Name,@value=@V;' @{'@Name'=$name}
  }
  if((Get-LifecycleGuardState $Db)-cne$installed){throw 'LIFECYCLE_GUARD_REGISTRATION_ORIGINAL_NOT_RESTORED'}
 }}
 Sql $Db 'DROP TABLE #LifecycleGuardOriginalDbMarkers;'
 # One CL140 anchor per physical engine/mode; no replay for alternate starting CLs.
 if($case.CL-eq150){
  $dbName=Get-LifecycleGuardOwnDatabaseName $Db
  Sql $control ("ALTER DATABASE ["+$dbName+"] SET COMPATIBILITY_LEVEL=140;")
  $damaged=Get-LifecycleGuardState $Db
  if([int](Read-Scalar $Db 'SELECT compatibility_level ScalarValue FROM sys.databases WHERE database_id=DB_ID();')-ne140){throw 'LIFECYCLE_GUARD_ACTUAL_CL140_REQUIRED'}
  try{foreach($module in @('core','schema')){foreach($op in @('deploy','uninstall')){
   $path=Get-LifecycleGuardScript $module $op $Mode
   $number=if($module-ceq'core'){55620}else{55630}
   $message=if($module-ceq'core'){'JSON Core: SQL-Version oder Compatibility Level nicht unterstützt.'}else{'JSON Schema lifecycle: SQL-Version oder Compatibility Level nicht unterstützt.'}
   Assert-LifecycleGuardDenied $Db $Mode ('compat140/'+$module+'/'+$op) ([IO.File]::ReadAllText($path)) $number $message
  }}}finally{
   if((Get-LifecycleGuardState $Db)-cne$damaged){throw 'LIFECYCLE_GUARD_COMPAT_RESTORE_DRIFT'}
   if((Get-LifecycleGuardOwnDatabaseName $Db)-cne$dbName){throw 'LIFECYCLE_GUARD_COMPAT_DATABASE_REPLACED'}
   Sql $control ("ALTER DATABASE ["+$dbName+"] SET COMPATIBILITY_LEVEL="+$case.CL+";")
  }
  if((Get-LifecycleGuardState $Db)-cne$installed){throw 'LIFECYCLE_GUARD_COMPAT_ORIGINAL_NOT_RESTORED'}
 }
 $actual=@($ledger.profileCompletions|Where-Object mode -CEQ $Mode|ForEach-Object id|Sort-Object)
 $expected=@(Get-LifecycleGuardKeys $Mode $case.CL|Where-Object{($Mode+'/'+$_)-cnotin$script:lifecycleGuardExcluded}|Sort-Object)
 if(($actual-join'|')-cne($expected-join'|')){throw 'LIFECYCLE_GUARD_MODE_COVERAGE'}
 Invoke-ReleaseBatches $Db ([IO.File]::ReadAllText($runset.uninstall));Assert-CoreLockNeutral $Db
 Invoke-ReleaseBatches $Db ([IO.File]::ReadAllText($runset.core_uninstall));Assert-CoreLockNeutral $Db
}
