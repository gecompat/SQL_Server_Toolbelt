[CmdletBinding()]
param(
    [ValidateSet('windows','linux')][string]$Platform='linux',
    [ValidateSet('2019','2022','2025')][string]$Version='2019',
    [string]$Patch='latest',
    [Parameter(Mandatory)][string]$LegacyDirectory,
    [ValidateSet('local','central')][string[]]$DeploymentModes=@('local','central'),
    [ValidateSet('JsonConstructors.Contract.sql','Collation.Contract.sql','JsonGroups.Contract.sql','JsonGroups.Boundaries.sql','InstalledMetadata.Contract.sql')]
    [string[]]$RuntimeTests=@('JsonConstructors.Contract.sql','Collation.Contract.sql','JsonGroups.Contract.sql','JsonGroups.Boundaries.sql','InstalledMetadata.Contract.sql')
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$module=Join-Path $repo 'Modules/toolbelt.json.constructors'
if([IO.File]::ReadAllText((Join-Path $module 'module.yaml')) -match '(?m)^version: "1\.2\.0"$'){
    throw 'JSON_CLR_NATIVE_ADAPTER_REVIEW_REQUIRED'
}
$legacy=(Resolve-Path -LiteralPath $LegacyDirectory).Path

# Ausschließlich geprüfte Funktionen importieren; keine Top-level-Mutatoren.
$definitions=[Collections.Generic.List[string]]::new()
foreach($import in @(
    @{File='run-lab-local.ps1';Names=@('Get-EnvironmentVariableValue','Resolve-LabContract','Test-LabTargetReady','Get-LabTargetsForSelector','New-LabConnectionString','Invoke-LabPreflight')},
    @{File='run-deterministic-translate-lab.ps1';Names=@('Read-TranslateSql','Invoke-TranslateSql','Open-TranslateConnection')}
)){
    $errors=$null
    $tree=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot $import.File),[ref]$null,[ref]$errors)
    if($errors.Count){throw 'JSON_LAB_HELPER_PARSE_FAILED'}
    foreach($name in $import.Names){
        $found=@($tree.FindAll({param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $name},$true))
        if($found.Count -ne 1){throw 'JSON_LAB_HELPER_AMBIGUOUS'}
        $definitions.Add($found[0].Extent.Text)
    }
}
foreach($definition in $definitions){. ([scriptblock]::Create($definition))}
$batchIndex=0
function Invoke-JsonBatches($Connection,[string]$Sql){
    $script:batchIndex=0
    foreach($batch in [regex]::Split($Sql,'(?im)^\s*GO\s*(?:--[^\r\n]*)?$')){
        if(-not [string]::IsNullOrWhiteSpace($batch)){
            $script:batchIndex++
            Invoke-TranslateSql $Connection $batch
        }
    }
}
function Assert-JsonRejected($Connection,[string]$Sql,[int]$Number){
    $rejected=$false
    try{Invoke-JsonBatches $Connection $Sql}
    catch{
        $failure=$_.Exception
        while($failure.InnerException){$failure=$failure.InnerException}
        if($failure -isnot [Data.SqlClient.SqlException]){throw 'JSON_LIFECYCLE_ERROR_ORACLE_MISMATCH'}
        if($failure.Number -ne $Number -or $failure.State -ne 1){
            Write-Output ('ORACLE_MISMATCH: expected='+$Number+'_STATE_1 actual='+$failure.Number+'_STATE_'+$failure.State)
            throw 'JSON_LIFECYCLE_ERROR_ORACLE_MISMATCH'
        }
        if($Number -eq 50000 -and -not $failure.Message.StartsWith('JSON_LIFECYCLE_CALLER_TRANSACTION:',[StringComparison]::Ordinal)){throw 'JSON_CALLER_PREFIX_MISMATCH'}
        $rejected=$true
    }
    if(-not $rejected){throw 'JSON_EXPECTED_REJECTION_MISSING'}
}
function Get-JsonSnapshotSql{
    # Kein SET: auch @@OPTIONS ist Teil des unveränderten Caller-Vertrags.
    $sql=@'
SELECT COALESCE(CONVERT(varchar(12),SCHEMA_ID(N'toolbelt_json')),'ABSENT')+'|'+CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),(
 SELECT o.name,o.type,o.object_id,m.definition,
  (SELECT ep.name,CONVERT(nvarchar(max),ep.value) AS value FROM sys.extended_properties ep
   WHERE ep.class=1 AND ep.major_id=o.object_id ORDER BY ep.name,ep.minor_id FOR JSON PATH,INCLUDE_NULL_VALUES) AS properties
 FROM sys.objects o LEFT JOIN sys.sql_modules m ON m.object_id=o.object_id
 WHERE o.schema_id=SCHEMA_ID(N'toolbelt_json') ORDER BY o.name FOR JSON PATH,INCLUDE_NULL_VALUES))),2)
 + '|' + CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),(
 SELECT ep.class,ep.name,ep.minor_id,CONVERT(nvarchar(max),ep.value) AS value FROM sys.extended_properties ep
 WHERE (ep.class=0 AND ep.name LIKE N'Toolbelt.Module.toolbelt.json.constructors.%')
    OR (ep.class=3 AND ep.major_id=SCHEMA_ID(N'toolbelt_json'))
 ORDER BY ep.class,ep.name,ep.minor_id FOR JSON PATH,INCLUDE_NULL_VALUES))),2);
'@
    return $sql
}
function Get-JsonSnapshot($Connection){
    return [string](Invoke-TranslateSql $Connection (Get-JsonSnapshotSql) -Scalar)
}
function Assert-JsonDoomedCaller($Connection,[string]$Deploy,[string]$Uninstall,[string]$Abort){
    # Eine beschädigte Transaktion darf keine äußere Batchgrenze passieren:
    # SQL Server würde sie dort mit 3998 zurückrollen. Originale Erstbatches
    # bleiben unverändert und laufen samt Oracle und eigenem Rollback zusammen.
    $command=$Connection.CreateCommand();$command.CommandTimeout=120
    $command.CommandText=@'
DECLARE @Options int,@Before nvarchar(max),@After nvarchar(max),@Rejected bit;
BEGIN TRY
 BEGIN TRAN;INSERT #JsonCaller VALUES(7);
 SET XACT_ABORT ON;
 BEGIN TRY INSERT #JsonCaller VALUES(-1);END TRY BEGIN CATCH
  IF ERROR_NUMBER()<>547 THROW;
 END CATCH;
 IF @Abort=N'OFF' SET XACT_ABORT OFF;ELSE SET XACT_ABORT ON;
 IF @@TRANCOUNT<>1 OR XACT_STATE()<>-1 THROW 54601,N'JSON_CALLER_DOOM_NOT_ESTABLISHED',1;
 SET @Options=@@OPTIONS;
 EXEC sys.sp_executesql @SnapshotQuery,N'@Snapshot nvarchar(max) OUTPUT',@Snapshot=@Before OUTPUT;
 DECLARE @Index int=0,@Installer nvarchar(max);
 WHILE @Index<2
 BEGIN
  SET @Installer=CASE WHEN @Index=0 THEN @Deploy ELSE @Uninstall END;
  SET @Rejected=0;
  BEGIN TRY EXEC sys.sp_executesql @Installer;END TRY BEGIN CATCH
   IF ERROR_NUMBER()<>50000 OR ERROR_STATE()<>1
    OR LEFT(ERROR_MESSAGE(),34)<>N'JSON_LIFECYCLE_CALLER_TRANSACTION:'
    THROW 54602,N'JSON_CALLER_ERROR_ORACLE_MISMATCH',1;
   SET @Rejected=1;
  END CATCH;
  IF @Rejected<>1 THROW 54603,N'JSON_CALLER_REJECTION_MISSING',1;
  IF @@TRANCOUNT<>1 OR XACT_STATE()<>-1 OR @@OPTIONS<>@Options
   OR (SELECT COUNT(*) FROM #JsonCaller)<>1
   OR (SELECT SUM(Value) FROM #JsonCaller)<>7
   OR (SELECT COUNT(*) FROM #tbx_JsonConstructorDeployState)<>1
   OR (SELECT SUM(SyntheticForeign) FROM #tbx_JsonConstructorDeployState)<>73
   THROW 54604,N'JSON_CALLER_STATE_CHANGED',1;
  EXEC sys.sp_executesql @SnapshotQuery,N'@Snapshot nvarchar(max) OUTPUT',@Snapshot=@After OUTPUT;
  IF @Before IS NULL OR @After IS NULL
   OR CONVERT(varbinary(max),@Before)<>CONVERT(varbinary(max),@After)
   THROW 54605,N'JSON_CALLER_MUTATED_MODULE',1;
  SET @Index+=1;
 END;
 ROLLBACK;
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK;
 THROW;
END CATCH;
'@
    try{
        foreach($entry in @(@{Name='@Deploy';Value=$Deploy},@{Name='@Uninstall';Value=$Uninstall})){
            $first=([regex]::Split($entry.Value,'(?im)^\s*GO\s*(?:--[^\r\n]*)?$'))[0]
            [void]$command.Parameters.Add($entry.Name,[Data.SqlDbType]::NVarChar,-1)
            $command.Parameters[$entry.Name].Value=$first
        }
        [void]$command.Parameters.Add('@Abort',[Data.SqlDbType]::NVarChar,3)
        $command.Parameters['@Abort'].Value=$Abort
        [void]$command.Parameters.Add('@SnapshotQuery',[Data.SqlDbType]::NVarChar,-1)
        $command.Parameters['@SnapshotQuery'].Value=[regex]::Replace((Get-JsonSnapshotSql),'\ASELECT ','SELECT @Snapshot=')
        [void]$command.ExecuteNonQuery()
    }finally{$command.Dispose()}
}
function Assert-JsonPreservedRejection($Connection,[string]$Sql,[int]$Number){
    $before=Get-JsonSnapshot $Connection
    Assert-JsonRejected $Connection $Sql $Number
    if((Get-JsonSnapshot $Connection) -cne $before){throw 'JSON_REJECTION_MUTATED_STATE'}
    if([int](Invoke-TranslateSql $Connection 'SELECT @@TRANCOUNT;' -Scalar)){throw 'JSON_REJECTION_LEFT_TRANSACTION'}
}
function Invoke-JsonClientMetadata($Target,[string]$Database){
    $names=@('TBX_SQL_HOST','TBX_SQL_PORT','TBX_SQL_USER','TBX_SQL_PASSWORD');$previous=@{}
    foreach($name in $names){$previous[$name]=[Environment]::GetEnvironmentVariable($name,'Process')}
    try{
        $env:TBX_SQL_HOST=[string]$Target.host;$env:TBX_SQL_PORT=[string]$Target.port
        $env:TBX_SQL_USER=[string]$Target.username;$env:TBX_SQL_PASSWORD=[string]$Target.password
        & (Join-Path $module 'Tests/Runtime/SelectMetadata.Contract.ps1') -Database $Database
    }finally{foreach($name in $names){[Environment]::SetEnvironmentVariable($name,$previous[$name],'Process')}}
}
function Invoke-JsonCollision($Connection,[hashtable]$Variables,[string]$Case){
    $fault=$Variables.Clone();$fault.FaultCase=$Case
    $command=$Connection.CreateCommand();$command.CommandTimeout=120
    $command.CommandText=Read-TranslateSql (Join-Path $module 'Tests/Runtime/Lifecycle.CollisionFixture.sql') $fault
    $reader=$null
    try{
        $reader=$command.ExecuteReader()
        if($reader.FieldCount -ne 2 -or $reader.GetName(0) -cne 'ExpectedError' -or $reader.GetName(1) -cne 'RestoreSql' -or -not $reader.Read()){throw 'JSON_COLLISION_ORACLE_MISSING'}
        $result=@{Number=$reader.GetInt32(0);RestoreSql=$reader.GetString(1)}
        if($reader.Read() -or $reader.NextResult()){throw 'JSON_COLLISION_ORACLE_EXTRA_RESULT'}
        return $result
    }finally{if($reader){$reader.Dispose()};$command.Dispose()}
}
function Assert-JsonInstallerRollback($Connection,[string]$Deploy){
    # Nur den expandierten privaten Testtext verändern, nie Source/Installer.
    # Beide Fehler liegen im echten finalen TRY/CATCH des Installers.
    foreach($needle in @(' IF XACT_STATE()<>1',' COMMIT TRANSACTION;')){
        if(([regex]::Matches($Deploy,[regex]::Escape($needle))).Count -ne 1){throw 'JSON_INSTALLER_FAULT_SEAM_AMBIGUOUS'}
        $fault=$Deploy.Replace($needle," THROW 54600,N'JSON synthetic lifecycle fault.',1;`n"+$needle)
        Assert-JsonPreservedRejection $Connection $fault 54600
    }
    $needle='  SET @Pass+=1;'
    if(([regex]::Matches($Deploy,[regex]::Escape($needle))).Count -ne 1){throw 'JSON_POSTLOCK_FAULT_SEAM_AMBIGUOUS'}
    # Unter eigener Lock+Transaktion eine bekannte Releasebasis verfälschen;
    # der echte zweite Preflight muss ablehnen und die Mutation zurückrollen.
    $fault=$Deploy.Replace($needle,"  IF @Pass=0 EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.Module.toolbelt.json.constructors.Version',@value=N'9.9.9';`n"+$needle)
    if([int](Invoke-TranslateSql $Connection "SELECT COUNT(*) FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.json.constructors.Version';" -Scalar)){
        Assert-JsonPreservedRejection $Connection $fault 53627
    }
}
function Get-JsonForeignSnapshot($Connection,[string]$Name){
    if($Name -notin @('USP_JsonArraysByGroup','USP_JsonObjectsByGroup')){throw 'JSON_FOREIGN_SLOT_NOT_ALLOWLISTED'}
    return [string](Invoke-TranslateSql $Connection ("SELECT CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),(SELECT o.object_id,m.definition,(SELECT ep.name,CONVERT(nvarchar(max),ep.value) AS value FROM sys.extended_properties ep WHERE ep.class=1 AND ep.major_id=o.object_id ORDER BY ep.name,ep.minor_id FOR JSON PATH,INCLUDE_NULL_VALUES) AS properties FROM sys.objects o JOIN sys.sql_modules m ON m.object_id=o.object_id WHERE o.object_id=OBJECT_ID(N'toolbelt_json.$Name') FOR JSON PATH,INCLUDE_NULL_VALUES))),2);") -Scalar)
}
 $legacyFiles=@('Deployment/Deploy.sql','Deployment/Uninstall.sql','Source/USP_JsonConstructInternal.sql','Source/USP_JsonArray.sql','Source/USP_JsonObject.sql')
foreach($relative in $legacyFiles){
    $expected=(& git -C $repo rev-parse ('435340a25b10ef5dccd60bf892727bd7e4e45be6:Modules/toolbelt.json.constructors/'+$relative)).Trim()
    if($LASTEXITCODE -ne 0){throw 'JSON_LEGACY_PUBLIC_SOURCE_UNAVAILABLE'}
    $actual=(& git -C $repo hash-object --no-filters -- (Join-Path $legacy $relative)).Trim()
    if($LASTEXITCODE -ne 0 -or $actual -cne $expected){throw 'JSON_LEGACY_GENUINE_SOURCE_MISMATCH'}
}
try{
    $lab=Resolve-LabContract
    $targets=@(Get-LabTargetsForSelector -Contract $lab.Contract -Selector ([pscustomobject]@{Platform=$Platform;Version=$Version;Patch=$Patch}))
}catch{throw 'JSON_LAB_DISCOVERY_FAILED_PRIVATE_DIAGNOSTICS_SUPPRESSED'}
if(-not $targets.Count){throw 'JSON_LAB_EXPLICIT_TARGET_NOT_READY'}
$levels=switch($Version){'2019'{@(150)};'2022'{@(150,160)};'2025'{@(150,160,170)}}
$sources=@(Get-ChildItem (Join-Path $module 'Source') -Filter '*.sql' -File)
if($sources.Count -ne 5){throw 'JSON_SOURCE_FREEZE_INCOMPLETE'}
$hashes=@{}
foreach($file in ($sources+@(Get-ChildItem (Join-Path $module 'Deployment') -Filter '*.sql' -File)+@(Get-ChildItem (Join-Path $module 'Tests/Runtime') -File))){
    $hashes[$file.FullName]=(Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
}
foreach($relative in $legacyFiles){
    $path=Join-Path $legacy $relative
    $hashes[$path]=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
}
foreach($target in $targets){
    $runId=[guid]::NewGuid().ToString('N')
    $journal=Join-Path ([IO.Path]::GetTempPath()) ('ToolbeltJsonGroupsRestore-'+$runId+'.json')
    $ledger=[ordered]@{RunId=$runId;State='PREPARED';Databases=@();ConfigurationChanges=0;RightsChanges=0}
    $owned=[Collections.Generic.List[string]]::new();$connections=[Collections.Generic.List[Data.SqlClient.SqlConnection]]::new()
    $control=$null;$failed=$false;$cleanupBlocked=$false;$stage='CREATE'
    try{
        $stage='PREFLIGHT'
        [void](Invoke-LabPreflight -Entry $target)
        $stage='CREATE'
        $control=Open-TranslateConnection $target 'master'
        foreach($mode in $DeploymentModes){
            $database='tbx_json_groups_'+$mode+'_'+$runId;$stage='CREATE_'+$mode
            if([int](Invoke-TranslateSql $control ("SELECT COUNT(*) FROM sys.databases WHERE name=N'$database';") -Scalar)){throw 'JSON_OWN_DATABASE_COLLISION'}
            $ledger.Databases+=@{Name=$database;State='CREATING'}
            $ledger|ConvertTo-Json -Depth 5|Set-Content -LiteralPath $journal -Encoding utf8
            $collation=if($mode -eq 'local'){'Latin1_General_100_CS_AS'}else{'Latin1_General_100_BIN2'}
            Invoke-TranslateSql $control ("CREATE DATABASE [$database] COLLATE $collation;")
            $owned.Add($database);$ledger.Databases[-1].State='CREATED'
            $connection=Open-TranslateConnection $target $database;$connections.Add($connection)
            $vars=@{DeploymentMode=$mode;ConfirmNoExternalConsumers=1;ToolbeltDatabase=$database;HistoricalVersion='1.0.0'}
            $stage='DEPENDENCY_'+$mode
            Invoke-JsonBatches $connection (Read-TranslateSql (Join-Path $repo 'Modules/toolbelt.core.result-table/Deployment/Deploy.sql') $vars)
            $connection.Dispose();$connection=Open-TranslateConnection $target $database;$connections.Add($connection)
            $deploy=Read-TranslateSql (Join-Path $module 'Deployment/Deploy.sql') $vars
            $uninstall=Read-TranslateSql (Join-Path $module 'Deployment/Uninstall.sql') $vars
            $stage='FIRST_INSTALL_ROLLBACK_'+$mode
            Assert-JsonInstallerRollback $connection $deploy
            $stage='GENUINE_10_'+$mode
            Invoke-JsonBatches $connection (Read-TranslateSql (Join-Path $legacy 'Deployment/Deploy.sql') $vars)
            if([int](Invoke-TranslateSql $connection "SELECT COUNT(*) FROM sys.objects WHERE schema_id=SCHEMA_ID(N'toolbelt_json');" -Scalar) -ne 3){throw 'JSON_LEGACY_THREE_SLOTS_FAILED'}
            $stage='HISTORICAL_SESSION_TEMP_GUARD_'+$mode
            Assert-JsonPreservedRejection $connection $deploy 53623
            if([int](Invoke-TranslateSql $connection 'SELECT CASE WHEN (SELECT COUNT(*) FROM #tbx_JsonConstructorDeployState)=1 AND (SELECT COUNT(*) FROM #tbx_JsonConstructorReleaseObjects)=3 THEN 1 ELSE 0 END;' -Scalar) -ne 1){throw 'JSON_HISTORICAL_CALLER_TEMP_CHANGED'}
            # Historische Installer-Temps enden wie bei SQLCMD mit ihrer
            # Session. Ihr altes Schema darf aktuelle Batches nicht eclipsen.
            $connection.Dispose();$connection=Open-TranslateConnection $target $database;$connections.Add($connection)
            $stage='UPGRADE_ROLLBACK_'+$mode
            Assert-JsonInstallerRollback $connection $deploy
            $stage='UPGRADE_'+$mode
            Invoke-JsonBatches $connection $deploy
            Invoke-JsonBatches $connection (Read-TranslateSql (Join-Path $module 'Tests/Runtime/Lifecycle.Contract.sql') $vars)
            $stage='REPEAT_ROLLBACK_'+$mode
            Assert-JsonInstallerRollback $connection $deploy
            $stage='LOCK_REJECTION_'+$mode
            $holder=Open-TranslateConnection $target $database
            try{
                $lock=[int](Invoke-TranslateSql $holder "BEGIN TRANSACTION;DECLARE @r int;EXEC @r=sys.sp_getapplock @Resource=N'toolbelt.deploy.toolbelt.json.constructors',@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=0,@DbPrincipal=N'public';SELECT @r;" -Scalar)
                if($lock -lt 0){throw 'JSON_LOCK_HOLDER_FAILED'}
                Assert-JsonPreservedRejection $connection $deploy 53627
                Assert-JsonPreservedRejection $connection $uninstall 53627
            }finally{
                try{Invoke-TranslateSql $holder 'IF @@TRANCOUNT>0 ROLLBACK;'}finally{$holder.Dispose()}
            }
            foreach($level in $levels){
                Invoke-TranslateSql $control ("ALTER DATABASE [$database] SET COMPATIBILITY_LEVEL=$level;")
                foreach($test in $RuntimeTests){
                    $stage='API_'+$mode+'_'+$level+'_'+$test;Write-Output ('RUNNING: '+$stage)
                    $testConnection=Open-TranslateConnection $target $database
                    try{Invoke-JsonBatches $testConnection (Read-TranslateSql (Join-Path $module ('Tests/Runtime/'+$test)) $vars)}
                    finally{$testConnection.Dispose()}
                }
                $stage='CLIENT_METADATA_'+$mode+'_'+$level
                Invoke-JsonClientMetadata $target $database
            }
            $stage='FRESH_REPEAT_'+$mode
            Invoke-JsonBatches $connection $uninstall
            Invoke-JsonBatches $connection $deploy
            Invoke-JsonBatches $connection $deploy
            Invoke-JsonBatches $connection (Read-TranslateSql (Join-Path $module 'Tests/Runtime/Lifecycle.Contract.sql') $vars)
            foreach($fault in @('VersionUnknown','VersionPadded','ModePadded','MarkerPadded','MarkerMissing')){
                $stage='COLLISION_'+$fault+'_'+$mode
                $collision=Invoke-JsonCollision $connection $vars $fault
                if($collision.Number -ne 53623 -or -not $collision.RestoreSql){throw 'JSON_COLLISION_ERROR_CONTRACT_MISMATCH'}
                try{
                    Assert-JsonPreservedRejection $connection $deploy 53623
                    Assert-JsonPreservedRejection $connection $uninstall 53623
                }finally{Invoke-TranslateSql $connection $collision.RestoreSql}
            }
            foreach($abort in @('OFF','ON')){
                foreach($doomed in @($false,$true)){
                    $stage='CALLER_'+$abort+'_'+$doomed+'_'+$mode
                    Invoke-TranslateSql $connection ("SET XACT_ABORT $abort;CREATE TABLE #tbx_JsonConstructorDeployState(SyntheticForeign int);INSERT #tbx_JsonConstructorDeployState VALUES(73);CREATE TABLE #JsonCaller(Value int NOT NULL CHECK(Value>0));")
                    try{
                        if($doomed){
                            Assert-JsonDoomedCaller $connection $deploy $uninstall $abort
                            continue
                        }
                        Invoke-TranslateSql $connection 'BEGIN TRAN;INSERT #JsonCaller VALUES(7);'
                        $state=if($doomed){-1}else{1}
                        $options=[int](Invoke-TranslateSql $connection 'SELECT @@OPTIONS;' -Scalar)
                        $snapshot=Get-JsonSnapshot $connection
                        foreach($installer in @($deploy,$uninstall)){
                            Assert-JsonRejected $connection $installer 50000
                            if([int](Invoke-TranslateSql $connection ("SELECT CASE WHEN @@TRANCOUNT=1 AND XACT_STATE()=$state AND @@OPTIONS=$options AND (SELECT SUM(Value) FROM #JsonCaller)=7 AND (SELECT SUM(SyntheticForeign) FROM #tbx_JsonConstructorDeployState)=73 THEN 1 ELSE 0 END;") -Scalar) -ne 1){throw 'JSON_CALLER_STATE_CHANGED'}
                            if((Get-JsonSnapshot $connection) -cne $snapshot){throw 'JSON_CALLER_MUTATED_MODULE'}
                        }
                    }finally{Invoke-TranslateSql $connection 'IF @@TRANCOUNT>0 ROLLBACK;DROP TABLE #JsonCaller;DROP TABLE #tbx_JsonConstructorDeployState;'}
                }
            }
            $stage='FOREIGN_STATE_TEMP_GUARD_'+$mode
            Invoke-TranslateSql $connection 'CREATE TABLE #tbx_JsonConstructorDeployState(SyntheticForeign int);INSERT #tbx_JsonConstructorDeployState VALUES(73);'
            try{
                Assert-JsonPreservedRejection $connection $deploy 53623
                if([int](Invoke-TranslateSql $connection 'SELECT SUM(SyntheticForeign) FROM #tbx_JsonConstructorDeployState;' -Scalar) -ne 73){throw 'JSON_FOREIGN_STATE_TEMP_CHANGED'}
            }finally{Invoke-TranslateSql $connection 'DROP TABLE #tbx_JsonConstructorDeployState;'}
            $stage='DEPENDENCY_REJECTION_'+$mode
            Invoke-TranslateSql $connection 'CREATE PROCEDURE dbo.SyntheticJsonDependency AS EXEC toolbelt_json.USP_JsonArraysByGroup @Hilfe=1;'
            Assert-JsonPreservedRejection $connection $uninstall 53626
            Invoke-TranslateSql $connection 'DROP PROCEDURE dbo.SyntheticJsonDependency;'
            if($mode -eq 'central'){
                $stage='CENTRAL_CONFIRMATION'
                $noConfirm=$vars.Clone();$noConfirm.ConfirmNoExternalConsumers=0
                Assert-JsonPreservedRejection $connection (Read-TranslateSql (Join-Path $module 'Deployment/Uninstall.sql') $noConfirm) 53625
                $consumer='tbx_json_groups_consumer_'+$runId
                if([int](Invoke-TranslateSql $control ("SELECT COUNT(*) FROM sys.databases WHERE name=N'$consumer';") -Scalar)){throw 'JSON_OWN_DATABASE_COLLISION'}
                $ledger.Databases+=@{Name=$consumer;State='CREATING'}
                $ledger|ConvertTo-Json -Depth 5|Set-Content -LiteralPath $journal -Encoding utf8
                Invoke-TranslateSql $control ("CREATE DATABASE [$consumer] COLLATE Latin1_General_100_CI_AS_SC_UTF8;")
                $owned.Add($consumer);$ledger.Databases[-1].State='CREATED'
                $consumerConnection=Open-TranslateConnection $target $consumer;$connections.Add($consumerConnection)
                Invoke-JsonBatches $consumerConnection (Read-TranslateSql (Join-Path $module 'Tests/Runtime/Central.Contract.sql') $vars)
            }
            $stage='UNINSTALL_'+$mode
            $needle=' COMMIT TRANSACTION;'
            if(([regex]::Matches($uninstall,[regex]::Escape($needle))).Count -ne 1){throw 'JSON_UNINSTALL_FAULT_SEAM_AMBIGUOUS'}
            Assert-JsonPreservedRejection $connection ($uninstall.Replace($needle," THROW 54600,N'JSON synthetic uninstall fault.',1;`n"+$needle)) 54600
            Invoke-JsonBatches $connection $uninstall
            Invoke-JsonBatches $connection $uninstall
            if([int](Invoke-TranslateSql $connection "SELECT COUNT(*) FROM sys.objects WHERE schema_id=SCHEMA_ID(N'toolbelt_json');" -Scalar)){throw 'JSON_UNINSTALL_OBJECTS_LEFT'}
            foreach($fault in @('FutureSlot','ImitatedFutureSlot','ObjectFutureSlot','ObjectImitatedFutureSlot')){
                $stage='HISTORICAL_FUTURE_'+$fault+'_'+$mode
                Invoke-JsonBatches $connection (Read-TranslateSql (Join-Path $legacy 'Deployment/Deploy.sql') $vars)
                $connection.Dispose();$connection=Open-TranslateConnection $target $database;$connections.Add($connection)
                $collision=Invoke-JsonCollision $connection $vars $fault
                if($collision.Number -ne 53624 -or -not $collision.RestoreSql){throw 'JSON_FUTURE_ERROR_CONTRACT_MISMATCH'}
                Assert-JsonPreservedRejection $connection $deploy 53624
                $futureName=if($fault.StartsWith('Object',[StringComparison]::Ordinal)){'USP_JsonObjectsByGroup'}else{'USP_JsonArraysByGroup'}
                $foreign=Get-JsonForeignSnapshot $connection $futureName
                Invoke-JsonBatches $connection $uninstall
                if(-not $foreign -or (Get-JsonForeignSnapshot $connection $futureName) -cne $foreign){throw 'JSON_HISTORICAL_UNINSTALL_FOREIGN_SLOT_LOST'}
                Invoke-TranslateSql $connection $collision.RestoreSql
            }
            $stage='FRESH_FOREIGN_SLOTS_'+$mode
            if(-not [int](Invoke-TranslateSql $connection "SELECT CASE WHEN SCHEMA_ID(N'toolbelt_json') IS NULL THEN 0 ELSE 1 END;" -Scalar)){
                Invoke-TranslateSql $connection 'CREATE SCHEMA toolbelt_json;'
            }
            foreach($name in @('USP_JsonConstructInternal','USP_JsonArray','USP_JsonObject','USP_JsonArraysByGroup','USP_JsonObjectsByGroup')){
                Invoke-TranslateSql $connection ("CREATE PROCEDURE toolbelt_json.$name AS SELECT 73 AS SyntheticForeign;")
                try{Assert-JsonPreservedRejection $connection $deploy 53624}
                finally{Invoke-TranslateSql $connection ("DROP PROCEDURE toolbelt_json.$name;")}
            }
            $stage='WRONG_TYPE_'+$mode
            Invoke-JsonBatches $connection $deploy
            $collision=Invoke-JsonCollision $connection $vars 'WrongType'
            if($collision.Number -ne 53623 -or $collision.RestoreSql){throw 'JSON_WRONG_TYPE_ERROR_CONTRACT_MISMATCH'}
            Assert-JsonPreservedRejection $connection $deploy 53623
            Assert-JsonPreservedRejection $connection $uninstall 53623
            # Dieser absichtlich fremde Endzustand endet durch DROP der eigenen
            # Wegwerf-DB; keine Adoption oder Reparatur eines falschen Objekttyps.
        }
        if(@(Get-ChildItem (Join-Path $module 'Source') -Filter '*.sql' -File).Count -ne $sources.Count){throw 'JSON_TESTED_SOURCE_SET_CHANGED'}
        foreach($path in $hashes.Keys){if((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -cne $hashes[$path]){throw 'JSON_TESTED_SOURCE_CHANGED'}}
        $ledger.State='TESTS_PASSED'
    }catch{
        $failed=$true;$ledger.State='TESTS_FAILED';$failure=$_.Exception;$sqlFailure=$null
        while($failure){if($failure -is [Data.SqlClient.SqlException] -and -not $sqlFailure){$sqlFailure=$failure};$lastFailure=$failure;$failure=$failure.InnerException}
        $safe=if($sqlFailure){'SQL_'+$sqlFailure.Number+'_STATE_'+$sqlFailure.State}elseif($lastFailure.Message -cmatch '^JSON_[A-Z0-9_]+$'){$lastFailure.Message}else{$lastFailure.GetType().Name}
        Write-Output ('FAILED: JSON stage='+$stage+' batch='+$batchIndex+' cause='+$safe)
    }finally{
        foreach($connection in $connections){$connection.Dispose()}
        if($control){
            foreach($database in $owned){
                try{
                    # Nur eigene GUID-Datenbanken, kein erzwungener Disconnect.
                    Invoke-TranslateSql $control ("DROP DATABASE [$database];")
                    if([int](Invoke-TranslateSql $control ("SELECT COUNT(*) FROM sys.databases WHERE name=N'$database';") -Scalar)){throw 'JSON_DROP_UNCONFIRMED'}
                    foreach($entry in $ledger.Databases){if($entry.Name -ceq $database){$entry.State='DROPPED'}}
                }catch{$cleanupBlocked=$true;foreach($entry in $ledger.Databases){if($entry.Name -ceq $database){$entry.State='CLEANUP_BLOCKED'}}}
            }
            $control.Dispose()
        }
        if(@($ledger.Databases|Where-Object {$_.State -eq 'CREATING'}).Count){$cleanupBlocked=$true}
        $ledger.State=if($cleanupBlocked){'CLEANUP_BLOCKED'}elseif($failed){'FAILED_CLEANED'}else{'COMPLETE'}
        $ledger|ConvertTo-Json -Depth 5|Set-Content -LiteralPath $journal -Encoding utf8
    }
    if($cleanupBlocked){throw 'JSON_OWN_CLEANUP_REQUIRES_COORDINATION'}
    if($failed){throw 'JSON_LAB_FAILED'}
    Write-Output ('PASS: JSON groups RuntimeTests='+($RuntimeTests -join ',')+'; genuine1.0/repeat/rollback/lock/clientmetadata/caller/markers/future/wrongtype/dependencies/central/uninstall; '+$Platform+' SQL'+$Version+'; modes='+($DeploymentModes -join ',')+'; no configuration/rights changes; own cleanup complete')
}
