# Ausschließlich eigene synthetische Testdatenbank; keine Datei-I/O oder Rechte.
# Die echten öffentlichen Deploy-/Uninstall-Batches bleiben unverändert.
function Get-FileLifecycleState($Db) {
 $sql=@'
SELECT s.name SchemaName,o.name,o.object_id,o.type,CONVERT(varchar(64),HASHBYTES('SHA2_256',m.definition),2) DefinitionHash
FROM sys.objects o JOIN sys.schemas s ON s.schema_id=o.schema_id
LEFT JOIN sys.sql_modules m ON m.object_id=o.object_id WHERE o.is_ms_shipped=0 ORDER BY s.name,o.name;
SELECT class,major_id,minor_id,name,CONVERT(nvarchar(max),value) Value FROM sys.extended_properties ORDER BY class,major_id,minor_id,name;
SELECT schema_id,name,principal_id FROM sys.schemas WHERE name IN(N'toolbelt_file',N'toolbelt_core') ORDER BY name;
SELECT @@TRANCOUNT TranCount,XACT_STATE() XactState;
'@
 return (@(Invoke-ReleaseSql $Db $sql -Rows)|ConvertTo-Json -Depth 5 -Compress)
}
function Assert-FileLifecycleDenied($Db,[string]$Sql,[int]$Number,[string]$Label) {
 $before=Get-FileLifecycleState $Db;$observed=$false
 try { Invoke-ReleaseBatches $Db $Sql } catch {
  $errorObject=$_.Exception
  while($errorObject -and $errorObject -isnot [Data.SqlClient.SqlException]){$errorObject=$errorObject.InnerException}
  if(-not$errorObject){throw}
  $actual=@($errorObject.Errors|Where-Object{$_.Number-eq$Number-and$_.State-eq1})
  if($actual.Count-ne1-or@($errorObject.Errors|Where-Object{$_.Class-ge11-and($_.Number-ne$Number-or$_.State-ne1)}).Count){throw}
  $observed=$true
 }
 if(-not$observed){throw 'FILE_LIFECYCLE_EXPECTED_ERROR_MISSING'}
 if((Get-FileLifecycleState $Db)-cne$before){throw 'FILE_LIFECYCLE_DENIAL_CHANGED_STATE'}
 $ledger.profileCompletions+=@(@{mode=$Mode;profile=$Label;number=$Number;state=1;unchanged=$true});Save-ReleaseJournal
}
function Assert-FileLifecycleAbsent($Db,[bool]$Sentinel) {
 $rows=@(Invoke-ReleaseSql $Db @'
SELECT (SELECT COUNT(*) FROM sys.objects WHERE schema_id=SCHEMA_ID(N'toolbelt_file') AND name IN(N'USP_LoadBinaryFile',N'USP_LoadTextFile',N'FileContentRootAllowlist')) Objects,
(SELECT COUNT(*) FROM sys.extended_properties WHERE class=0 AND name LIKE N'Toolbelt.Module.toolbelt.file.content.%') Markers,
SCHEMA_ID(N'toolbelt_file') SchemaId,OBJECT_ID(N'toolbelt_file.ContosoLifecycleSentinel',N'U') SentinelId;
'@ -Rows)
 if($rows.Count-ne1-or$rows[0].Objects-ne0-or$rows[0].Markers-ne0){throw 'FILE_LIFECYCLE_INCOMPLETE_UNINSTALL'}
 if($Sentinel){
  if($rows[0].SchemaId-is[DBNull]-or$rows[0].SentinelId-is[DBNull]){throw 'FILE_LIFECYCLE_SENTINEL_LOST'}
  $data=@(Invoke-ReleaseSql $Db 'SELECT Value FROM toolbelt_file.ContosoLifecycleSentinel;' -Rows)
  if($data.Count-ne1-or$data[0].Value-ne2718){throw 'FILE_LIFECYCLE_SENTINEL_DATA_CHANGED'}
 }elseif($rows[0].SchemaId-isnot[DBNull]){throw 'FILE_LIFECYCLE_EMPTY_SCHEMA_REMAINS'}
}
function Invoke-FileLifecycleProfiles($Db,[string]$Mode) {
 $deploy=Get-FileLifecycleText $Mode
 $uninstall=[IO.File]::ReadAllText((Join-Path $repo 'Modules/toolbelt.file.content/Deployment/Uninstall.sql'))
 # Ein unbekannter Marker muss vor jeglicher Mutation scheitern.
 Invoke-ReleaseSql $Db "EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.Module.toolbelt.file.content.Version',@value=N'9.9.9';"
 Assert-FileLifecycleDenied $Db $deploy 51273 'unknown-version-deploy'
 Assert-FileLifecycleDenied $Db $uninstall 51273 'unknown-version-uninstall'
 Invoke-ReleaseSql $Db "EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.Module.toolbelt.file.content.Version',@value=N'1.0.0'; CREATE TABLE toolbelt_file.ContosoLifecycleSentinel(Value int NOT NULL); INSERT toolbelt_file.ContosoLifecycleSentinel VALUES(2718);"
 $sentinel=@(Invoke-ReleaseSql $Db "SELECT OBJECT_ID(N'toolbelt_file.ContosoLifecycleSentinel') Id,SCHEMA_ID(N'toolbelt_file') SchemaId;" -Rows)
 Invoke-ReleaseBatches $Db $uninstall
 Assert-FileLifecycleAbsent $Db $true
 $after=@(Invoke-ReleaseSql $Db "SELECT OBJECT_ID(N'toolbelt_file.ContosoLifecycleSentinel') Id,SCHEMA_ID(N'toolbelt_file') SchemaId;" -Rows)
 if(($sentinel|ConvertTo-Json -Compress)-cne($after|ConvertTo-Json -Compress)){throw 'FILE_LIFECYCLE_SCHEMA_IDENTITY_CHANGED'}
 $ledger.profileCompletions+=@(@{mode=$Mode;profile='uninstall-preserves-foreign-schema-object';unchanged=$true});Save-ReleaseJournal
 # Jedes reservierte Zielobjekt einzeln als fremde Tabelle, ohne Release-Marker.
 foreach($name in @('USP_LoadBinaryFile','USP_LoadTextFile','FileContentRootAllowlist')){
  Invoke-ReleaseSql $Db "CREATE TABLE toolbelt_file.[$name](Value int NOT NULL); INSERT toolbelt_file.[$name] VALUES(314);"
  Assert-FileLifecycleDenied $Db $deploy 51274 ('foreign-'+$name+'-deploy')
  Assert-FileLifecycleDenied $Db $uninstall 51274 ('foreign-'+$name+'-uninstall')
  $data=@(Invoke-ReleaseSql $Db "SELECT Value FROM toolbelt_file.[$name];" -Rows)
  if($data.Count-ne1-or$data[0].Value-ne314){throw 'FILE_LIFECYCLE_COLLISION_DATA_CHANGED'}
  Invoke-ReleaseSql $Db "DROP TABLE toolbelt_file.[$name];"
 }
 Invoke-ReleaseBatches $Db $deploy
 $installed=@(Invoke-ReleaseSql $Db "SELECT (SELECT COUNT(*) FROM sys.objects WHERE schema_id=SCHEMA_ID(N'toolbelt_file') AND name IN(N'USP_LoadBinaryFile',N'USP_LoadTextFile',N'FileContentRootAllowlist')) Objects,(SELECT CONVERT(nvarchar(32),value) FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.file.content.Version') Version,(SELECT CONVERT(nvarchar(32),value) FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.file.content.DeploymentMode') Mode;" -Rows)
 if($installed.Count-ne1-or$installed[0].Objects-ne3-or$installed[0].Version-cne'1.0.0'-or$installed[0].Mode-cne$Mode){throw 'FILE_LIFECYCLE_REINSTALL_FAILED'}
 Assert-FileLifecycleAbsentSentinel $Db
 $ledger.profileCompletions+=@(@{mode=$Mode;profile='reinstall-current-preserves-sentinel';unchanged=$true});Save-ReleaseJournal
 Invoke-ReleaseSql $Db 'DROP TABLE toolbelt_file.ContosoLifecycleSentinel;'
 Invoke-ReleaseBatches $Db $uninstall
 Assert-FileLifecycleAbsent $Db $false
 $ledger.profileCompletions+=@(@{mode=$Mode;profile='uninstall-removes-empty-schema';unchanged=$true});Save-ReleaseJournal
 $before=Get-FileLifecycleState $Db
 Invoke-ReleaseBatches $Db $uninstall
 Assert-FileLifecycleAbsent $Db $false
 if((Get-FileLifecycleState $Db)-cne$before){throw 'FILE_LIFECYCLE_ABSENT_UNINSTALL_DRIFT'}
 $ledger.profileCompletions+=@(@{mode=$Mode;profile='absent-uninstall-idempotent';unchanged=$true});Save-ReleaseJournal
}
function Assert-FileLifecycleAbsentSentinel($Db){
 $data=@(Invoke-ReleaseSql $Db 'SELECT Value FROM toolbelt_file.ContosoLifecycleSentinel;' -Rows)
 if($data.Count-ne1-or$data[0].Value-ne2718){throw 'FILE_LIFECYCLE_REINSTALL_SENTINEL_CHANGED'}
}
