# Nur eigene synthetische DB, aktuelle Originalbatches; keine Rechte-/Labänderung.
function Get-SplitLifecycleDefinitions($Db){
 return (@(Invoke-ReleaseSql $Db "SELECT o.name,o.type,CONVERT(varchar(64),HASHBYTES('SHA2_256',m.definition),2) Hash FROM sys.objects o JOIN sys.schemas s ON s.schema_id=o.schema_id JOIN sys.sql_modules m ON m.object_id=o.object_id WHERE s.name=N'toolbelt_string' AND o.name IN(N'TVF_SplitAdvanced',N'TVF_UnquoteToken',N'USP_SplitAdvanced') ORDER BY o.name;" -Rows)|ConvertTo-Json -Depth 4 -Compress)
}
function Get-SplitLifecycleState($Db){
 $sql=@'
SELECT s.name SchemaName,o.name,o.object_id,o.type,CONVERT(varchar(64),HASHBYTES('SHA2_256',m.definition),2) DefinitionHash
FROM sys.objects o JOIN sys.schemas s ON s.schema_id=o.schema_id
LEFT JOIN sys.sql_modules m ON m.object_id=o.object_id WHERE o.is_ms_shipped=0 ORDER BY s.name,o.name;
SELECT class,major_id,minor_id,name,CONVERT(nvarchar(max),value) Value FROM sys.extended_properties ORDER BY class,major_id,minor_id,name;
SELECT schema_id,name,principal_id FROM sys.schemas WHERE name IN(N'toolbelt_string',N'toolbelt_core') ORDER BY name;
SELECT @@TRANCOUNT TranCount,XACT_STATE() XactState;
'@
 return (@(Invoke-ReleaseSql $Db $sql -Rows)|ConvertTo-Json -Depth 5 -Compress)
}
function Save-SplitLifecycleProfile([string]$Label){
 $ledger.profileCompletions+=@(@{mode=$Mode;profile=$Label;passed=$true});Save-ReleaseJournal
}
function Assert-SplitLifecycleDenied($Db,[string]$Sql,[int]$Number,[string]$Label){
 $before=Get-SplitLifecycleState $Db;$observed=$false
 try{Invoke-ReleaseBatches $Db $Sql}catch{
  $errorObject=$_.Exception
  while($errorObject-and$errorObject-isnot[Data.SqlClient.SqlException]){$errorObject=$errorObject.InnerException}
  if(-not$errorObject){throw}
  $actual=@($errorObject.Errors|Where-Object{$_.Number-eq$Number-and$_.State-eq1})
  if($actual.Count-ne1-or@($errorObject.Errors|Where-Object{$_.Class-ge11-and($_.Number-ne$Number-or$_.State-ne1)}).Count){throw}
  $observed=$true
 }
 if(-not$observed){throw 'SPLIT_LIFECYCLE_EXPECTED_ERROR_MISSING'}
 if((Get-SplitLifecycleState $Db)-cne$before){throw 'SPLIT_LIFECYCLE_DENIAL_CHANGED_STATE'}
 $ledger.profileCompletions+=@(@{mode=$Mode;profile=$Label;number=$Number;state=1;passed=$true});Save-ReleaseJournal
}
function Assert-SplitLifecycleSentinel($Db){
 $rows=@(Invoke-ReleaseSql $Db 'SELECT Value FROM toolbelt_string.ContosoLifecycleSentinel;' -Rows)
 if($rows.Count-ne1-or$rows[0].Value-ne2718){throw 'SPLIT_LIFECYCLE_SENTINEL_CHANGED'}
}
function Assert-SplitLifecycleAbsent($Db,[bool]$Sentinel){
 $rows=@(Invoke-ReleaseSql $Db "SELECT (SELECT COUNT(*) FROM sys.objects WHERE schema_id=SCHEMA_ID(N'toolbelt_string') AND name IN(N'TVF_SplitAdvanced',N'TVF_UnquoteToken',N'USP_SplitAdvanced')) Objects,(SELECT COUNT(*) FROM sys.extended_properties WHERE class=0 AND name LIKE N'Toolbelt.Module.toolbelt.string.split-advanced.%') Markers,SCHEMA_ID(N'toolbelt_string') SchemaId;" -Rows)
 if($rows.Count-ne1-or$rows[0].Objects-ne0-or$rows[0].Markers-ne0){throw 'SPLIT_LIFECYCLE_INCOMPLETE_UNINSTALL'}
 if($Sentinel){Assert-SplitLifecycleSentinel $Db}elseif($rows[0].SchemaId-isnot[DBNull]){throw 'SPLIT_LIFECYCLE_EMPTY_SCHEMA_REMAINS'}
}
function Invoke-SplitLifecycleProfiles($Db,[string]$Mode){
 $deploy=Get-SplitLifecycleText $Mode
 $original=[IO.File]::ReadAllText((Join-Path $repo 'Modules/toolbelt.string.split-advanced/Deployment/Uninstall.sql'))
 $uninstall=$original.Replace('$(ConfirmNoExternalConsumers)','1')
 $canonical=Get-SplitLifecycleDefinitions $Db
 Invoke-ReleaseSql $Db "EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.Module.toolbelt.string.split-advanced.Version',@value=N'9.9.9';"
 Assert-SplitLifecycleDenied $Db $deploy 51673 'unknown-version-deploy'
 Assert-SplitLifecycleDenied $Db $uninstall 51673 'unknown-version-uninstall'
 Invoke-ReleaseSql $Db "EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.Module.toolbelt.string.split-advanced.Version',@value=N'1.1.0';"
 $invalid=if($Mode-ceq'local'){'invalid'}else{'0'}
 Assert-SplitLifecycleDenied $Db ($original.Replace('$(ConfirmNoExternalConsumers)',$invalid)) 51675 'confirmation-rejected'
 # Vollständige kanonische Definitionen, keine wiederholte große API-Fixture.
 Invoke-ReleaseBatches $Db "ALTER FUNCTION toolbelt_string.TVF_SplitAdvanced (@Input nvarchar(max),@SeparatorsJson nvarchar(max),@Quote nvarchar(max)=N'',@Escape nvarchar(max)=N'',@KeepEmpty bit=1) RETURNS @r TABLE(Value nvarchar(max),Ordinal bigint,IsValid bit,ErrorCode varchar(64),ErrorPosition bigint) AS BEGIN INSERT @r VALUES(N'drift',1,1,NULL,NULL); RETURN; END;"
 if((Get-SplitLifecycleDefinitions $Db)-ceq$canonical){throw 'SPLIT_LIFECYCLE_DRIFT_NOT_ESTABLISHED'}
 Invoke-ReleaseBatches $Db $deploy
 if((Get-SplitLifecycleDefinitions $Db)-cne$canonical){throw 'SPLIT_LIFECYCLE_DRIFT_NOT_REPAIRED'}
 Save-SplitLifecycleProfile 'same-version-drift-repaired'
 Invoke-ReleaseSql $Db 'DROP FUNCTION toolbelt_string.TVF_SplitAdvanced;'
 Invoke-ReleaseBatches $Db "CREATE FUNCTION toolbelt_string.TVF_SplitAdvanced (@Input nvarchar(max),@SeparatorsJson nvarchar(max),@Quote nvarchar(max),@Escape nvarchar(max),@KeepEmpty bit) RETURNS TABLE AS RETURN SELECT N'drift' AS Value;"
 $type=@(Invoke-ReleaseSql $Db "SELECT type FROM sys.objects WHERE object_id=OBJECT_ID(N'toolbelt_string.TVF_SplitAdvanced');" -Rows)
 if($type.Count-ne1-or$type[0].type-cne'IF'){throw 'SPLIT_LIFECYCLE_TYPE_DRIFT_NOT_ESTABLISHED'}
 Invoke-ReleaseBatches $Db $deploy
 if((Get-SplitLifecycleDefinitions $Db)-cne$canonical){throw 'SPLIT_LIFECYCLE_TYPE_NOT_REPAIRED'}
 Save-SplitLifecycleProfile 'registered-type-change-repaired'
 Invoke-ReleaseBatches $Db "CREATE VIEW dbo.ContosoSplitLifecycleConsumer AS SELECT Value FROM toolbelt_string.TVF_SplitAdvanced(N'a;b',N'[`";`"]',DEFAULT,DEFAULT,DEFAULT);"
 Assert-SplitLifecycleDenied $Db $uninstall 51676 'resolved-consumer-blocks-uninstall'
 Invoke-ReleaseSql $Db 'DROP VIEW dbo.ContosoSplitLifecycleConsumer; CREATE TABLE toolbelt_string.ContosoLifecycleSentinel(Value int NOT NULL); INSERT toolbelt_string.ContosoLifecycleSentinel VALUES(2718);'
 $identity=@(Invoke-ReleaseSql $Db "SELECT OBJECT_ID(N'toolbelt_string.ContosoLifecycleSentinel') Id,SCHEMA_ID(N'toolbelt_string') SchemaId;" -Rows)|ConvertTo-Json -Compress
 Invoke-ReleaseBatches $Db $uninstall
 Assert-SplitLifecycleAbsent $Db $true
 $after=@(Invoke-ReleaseSql $Db "SELECT OBJECT_ID(N'toolbelt_string.ContosoLifecycleSentinel') Id,SCHEMA_ID(N'toolbelt_string') SchemaId;" -Rows)|ConvertTo-Json -Compress
 if($after-cne$identity){throw 'SPLIT_LIFECYCLE_FOREIGN_IDENTITY_CHANGED'}
 Save-SplitLifecycleProfile 'uninstall-preserves-foreign-object'
 Invoke-ReleaseBatches $Db $deploy
 if((Get-SplitLifecycleDefinitions $Db)-cne$canonical){throw 'SPLIT_LIFECYCLE_REINSTALL_DEFINITIONS'}
 Assert-SplitLifecycleSentinel $Db
 Save-SplitLifecycleProfile 'reinstall-in-retained-schema'
 Invoke-ReleaseSql $Db 'DROP TABLE toolbelt_string.ContosoLifecycleSentinel;'
 Invoke-ReleaseBatches $Db $uninstall
 Assert-SplitLifecycleAbsent $Db $false
 Save-SplitLifecycleProfile 'uninstall-removes-empty-schema'
 $before=Get-SplitLifecycleState $Db
 Invoke-ReleaseBatches $Db $uninstall
 Assert-SplitLifecycleAbsent $Db $false
 if((Get-SplitLifecycleState $Db)-cne$before){throw 'SPLIT_LIFECYCLE_ABSENT_UNINSTALL_DRIFT'}
 Save-SplitLifecycleProfile 'absent-uninstall-idempotent'
}
