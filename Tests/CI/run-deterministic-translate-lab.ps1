[CmdletBinding()]
param(
    [ValidateSet('windows','linux')][string]$Platform='linux',
    [ValidateSet('2019','2022','2025')][string]$Version='2019',
    [string]$Patch='latest',
    [Parameter(Mandatory)][string]$LegacyDirectory,
    [ValidateSet('local','central')][string[]]$DeploymentModes=@('local','central'),
    [ValidateSet('Range.Contract.sql','DateShift.Contract.sql','Lookup.Contract.sql','Lookup.Boundaries.sql','Translate.Contract.sql','Translate.Safety.sql','InstalledMetadata.Contract.sql')]
    [string[]]$RuntimeTests=@('Range.Contract.sql','DateShift.Contract.sql','Lookup.Contract.sql','Lookup.Boundaries.sql','Translate.Contract.sql','Translate.Safety.sql','InstalledMetadata.Contract.sql')
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$module=Join-Path $repo 'Modules/toolbelt.pseudonymization.deterministic'
$legacy=(Resolve-Path -LiteralPath $LegacyDirectory).Path

# Nur native Read-only-Discovery, niemals den generischen Mutator ausführen.
$parseErrors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'run-lab-local.ps1'),[ref]$null,[ref]$parseErrors)
if($parseErrors.Count){throw 'LAB_DISCOVERY_PARSE_FAILED'}
foreach($name in @('Get-EnvironmentVariableValue','Resolve-LabContract','Test-LabTargetReady','Get-LabTargetsForSelector','New-LabConnectionString','Invoke-LabPreflight')){
    $found=@($ast.FindAll({param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $name},$true))
    if($found.Count -ne 1){throw 'LAB_DISCOVERY_FUNCTION_AMBIGUOUS'}
    . ([scriptblock]::Create($found[0].Extent.Text))
}
function Read-TranslateSql([string]$Path,[hashtable]$Variables,[int]$Depth=0){
    if($Depth -gt 8){throw 'SQLCMD_INCLUDE_DEPTH'}
    $resolved=(Resolve-Path -LiteralPath $Path).Path
    $allowed=$false
    foreach($root in @($repo,$legacy)){
        if($resolved.StartsWith($root+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){$allowed=$true}
    }
    if(-not $allowed){throw 'SQLCMD_INCLUDE_OUTSIDE_APPROVED_ROOTS'}
    $lines=[Collections.Generic.List[string]]::new()
    foreach($line in [IO.File]::ReadAllLines($resolved)){
        if($line -match '^\s*:r\s+(.+?)\s*$'){
            $include=$Matches[1].Trim('"')
            foreach($key in $Variables.Keys){$include=$include.Replace('$('+ $key +')',[string]$Variables[$key])}
            $lines.Add((Read-TranslateSql (Join-Path (Split-Path $resolved) $include) $Variables ($Depth+1)))
        }elseif($line -match '^\s*:On Error exit\s*$'){}
        elseif($line -match '^\s*:'){throw 'SQLCMD_UNSUPPORTED_DIRECTIVE'}
        else{$lines.Add($line)}
    }
    $text=$lines -join "`n"
    foreach($key in $Variables.Keys){$text=$text.Replace('$('+ $key +')',[string]$Variables[$key])}
    if($text -match '\$\([A-Za-z_][A-Za-z0-9_]*\)'){throw 'SQLCMD_UNRESOLVED_VARIABLE'}
    # Kein neuer Lab-Rechte-, Konfigurations- oder Infrastrukturpfad.
    if($text -match '(?i)\b(GRANT|RECONFIGURE|TRUSTWORTHY|CREATE\s+LOGIN|CREATE\s+USER|KILL)\b'){throw 'SQL_OUTSIDE_LAB_AUTHORIZATION'}
    return $text
}
function Invoke-TranslateSql($Connection,[string]$Sql,[switch]$Scalar){
    $command=$Connection.CreateCommand();$command.CommandTimeout=120;$command.CommandText=$Sql
    try{if($Scalar){return $command.ExecuteScalar()};[void]$command.ExecuteNonQuery()}finally{$command.Dispose()}
}
function Invoke-TranslateBatches($Connection,[string]$Sql){
    foreach($batch in [regex]::Split($Sql,'(?im)^\s*GO\s*(?:--[^\r\n]*)?$')){
        if(-not [string]::IsNullOrWhiteSpace($batch)){Invoke-TranslateSql $Connection $batch}
    }
}
function Assert-TranslateRejected($Connection,[string]$Sql,[int]$Number){
    $rejected=$false
    try{Invoke-TranslateBatches $Connection $Sql}
    catch{
        $failure=$_.Exception;while($failure.InnerException){$failure=$failure.InnerException}
        if($failure -isnot [Data.SqlClient.SqlException] -or $failure.Number -ne $Number){throw 'LIFECYCLE_ERROR_ORACLE_MISMATCH'}
        $rejected=$true
    }
    if(-not $rejected){throw 'LIFECYCLE_EXPECTED_REJECTION_MISSING'}
}
function Get-TranslateSnapshot($Connection,[hashtable]$Variables){
    $command=$Connection.CreateCommand()
    $command.CommandText=Read-TranslateSql (Join-Path $module 'Tests/Runtime/Lifecycle.Snapshot.sql') $Variables
    $reader=$command.ExecuteReader()
    try{
        if(-not $reader.Read()){throw 'SNAPSHOT_ROW_MISSING'}
        $values=@(for($i=0;$i -lt $reader.FieldCount;$i++){if($reader.IsDBNull($i)){'NULL'}else{[string]$reader.GetValue($i)}})
        return ($values -join '|')
    }finally{$reader.Dispose();$command.Dispose()}
}
function Assert-TranslatePreservedRejection($Connection,[string]$Sql,[int]$Number,[hashtable]$Variables){
    $before=Get-TranslateSnapshot $Connection $Variables
    Assert-TranslateRejected $Connection $Sql $Number
    if((Get-TranslateSnapshot $Connection $Variables) -cne $before){throw 'REJECTION_MUTATED_INSTALLED_STATE'}
    if([int](Invoke-TranslateSql $Connection 'SELECT @@TRANCOUNT;' -Scalar)){throw 'REJECTION_LEFT_OWN_TRANSACTION'}
}
function Open-TranslateConnection($Target,[string]$Database){
    $builder=[Data.SqlClient.SqlConnectionStringBuilder]::new((New-LabConnectionString -Entry $Target))
    $builder['Initial Catalog']=$Database;$builder['Pooling']=$false
    $c=$null
    try{$c=[Data.SqlClient.SqlConnection]::new($builder.ConnectionString);$c.Open();return $c}
    catch{if($c){$c.Dispose()};throw}
    finally{$builder.Clear()}
}
function Assert-TranslateMetadata($Connection){
    foreach($sql in @(
        "SELECT Value,ErrorCode FROM toolbelt_pseudonymization.TVF_DeterministicTranslate(N'Ab09',1,DEFAULT,DEFAULT,DEFAULT);",
        'SELECT Value,ErrorCode FROM toolbelt_pseudonymization.TVF_DeterministicTranslate(NULL,NULL,NULL,NULL,NULL);',
        "SELECT Value,ErrorCode FROM toolbelt_pseudonymization.TVF_DeterministicTranslate(N'?',1,0,N'',DEFAULT);"
    )){
        $command=$Connection.CreateCommand();$command.CommandText=$sql;$reader=$command.ExecuteReader()
        try{
            $schema=$reader.GetSchemaTable()
            if($reader.FieldCount -ne 2 -or $reader.GetName(0) -cne 'Value' -or $reader.GetName(1) -cne 'ErrorCode' -or
               $reader.GetDataTypeName(0) -cne 'nvarchar' -or $reader.GetDataTypeName(1) -cne 'int' -or
               -not [bool]$schema.Rows[0].AllowDBNull -or [bool]$schema.Rows[1].AllowDBNull -or
               $schema.Rows[0].ColumnSize -ne [int]::MaxValue){throw 'TRANSLATE_CLIENT_METADATA_FAILED'}
            if(-not $reader.Read() -or $reader.Read() -or $reader.NextResult()){throw 'TRANSLATE_SINGLE_ROW_FAILED'}
        }finally{$reader.Dispose();$command.Dispose()}
    }
}
function Invoke-DeterministicClientMetadata($Target,[string]$Database){
    $names=@('TBX_SQL_HOST','TBX_SQL_PORT','TBX_SQL_USER','TBX_SQL_PASSWORD')
    $previous=@{}
    foreach($name in $names){$previous[$name]=[Environment]::GetEnvironmentVariable($name,'Process')}
    try{
        $env:TBX_SQL_HOST=[string]$Target.host;$env:TBX_SQL_PORT=[string]$Target.port
        $env:TBX_SQL_USER=[string]$Target.username;$env:TBX_SQL_PASSWORD=[string]$Target.password
        & (Join-Path $module 'Tests/Runtime/SelectMetadata.Contract.ps1') -Database $Database
    }finally{foreach($name in $names){[Environment]::SetEnvironmentVariable($name,$previous[$name],'Process')}}
}

# Ein Fixture muss unveränderte öffentliche 1.0-Quellen enthalten. Der Agent-
# Helper darf Dateien paketieren; der Labdriver prüft gegen Git, nicht Labels.
$legacyCommit='9c77df2761db469ed9b2c20b48a4c909c69f7700'
foreach($relative in @('Deployment/Deploy.sql','Deployment/Uninstall.sql','Deployment/ReleaseManifest.sql',
 'Source/TVF_DeterministicIntegerBytes.sql','Source/TVF_DeterministicRangeCore.sql','Source/TVF_DeterministicRange.sql',
 'Source/TVF_DeterministicDateShift.sql','Source/USP_DeterministicLookupCore.sql','Source/USP_DeterministicLookup.sql')){
    $gitPath='Modules/toolbelt.pseudonymization.deterministic/'+$relative
    $expected=(& git -C $repo show ($legacyCommit+':'+$gitPath)) -join "`n"
    if($LASTEXITCODE -ne 0){throw 'LEGACY_PUBLIC_SOURCE_UNAVAILABLE'}
    $actual=[IO.File]::ReadAllText((Join-Path $legacy $relative)).Replace("`r`n","`n").TrimEnd("`n")
    if($actual -cne $expected.TrimEnd("`n")){throw 'LEGACY_GENUINE_SOURCE_MISMATCH'}
}
$lab=Resolve-LabContract
$sourceFiles=@(Get-ChildItem -LiteralPath (Join-Path $module 'Source') -File)+
    @(Get-ChildItem -LiteralPath (Join-Path $module 'Deployment') -Filter '*.sql' -File)
$sourceHashes=@{}
foreach($file in $sourceFiles){$sourceHashes[$file.FullName]=(Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash}
$targets=@(Get-LabTargetsForSelector -Contract $lab.Contract -Selector ([pscustomobject]@{Platform=$Platform;Version=$Version;Patch=$Patch}))
if(-not $targets.Count){throw 'LAB_EXPLICIT_TARGET_NOT_READY'}
$levels=switch($Version){'2019'{@(150)};'2022'{@(150,160)};'2025'{@(150,160,170)}}
foreach($target in $targets){
    [void](Invoke-LabPreflight -Entry $target)
    $runId=[Guid]::NewGuid().ToString('N')
    $journalPath=Join-Path ([IO.Path]::GetTempPath()) ('ToolbeltTranslateRestore-'+$runId+'.json')
    $ledger=[ordered]@{RunId=$runId;State='PREPARED';Databases=@();ConfigurationChanges=0;RightsChanges=0}
    $owned=[Collections.Generic.List[string]]::new()
    $connections=[Collections.Generic.List[Data.SqlClient.SqlConnection]]::new()
    $control=$null;$failed=$false;$cleanupBlocked=$false;$stage='CREATE'
    try{
        $control=Open-TranslateConnection $target 'master'
        foreach($mode in $DeploymentModes){
            $database='tbx_translate_'+$mode+'_'+$runId
            $stage='CREATE_'+$mode
            if([int](Invoke-TranslateSql $control ("SELECT COUNT(*) FROM sys.databases WHERE name=N'$database';") -Scalar)){throw 'OWN_DATABASE_COLLISION'}
            $ledger.Databases+=@{Name=$database;State='CREATING'}
            $ledger|ConvertTo-Json -Depth 5|Set-Content -LiteralPath $journalPath -Encoding utf8
            $collation=if($mode -eq 'local'){'Latin1_General_100_CS_AS'}else{'Latin1_General_100_BIN2'}
            Invoke-TranslateSql $control ("CREATE DATABASE [$database] COLLATE $collation;")
            $owned.Add($database);$ledger.Databases[-1].State='CREATED'
            $connection=Open-TranslateConnection $target $database;$connections.Add($connection)
            $vars=@{DeploymentMode=$mode;ConfirmNoExternalConsumers=1;ToolbeltDatabase=$database;CentralDb=$database}
            $stage='DEPENDENCY_'+$mode
            Invoke-TranslateBatches $connection (Read-TranslateSql (Join-Path $repo 'Modules/toolbelt.core.result-table/Deployment/Deploy.sql') $vars)
            # Der historische Dependencyinstaller verwendet sessionlokale
            # Manifesttemps mit benannten Constraints. Wie SQLCMD die eigene
            # Installersession beenden, bevor ein weiterer Modus startet.
            $connection.Dispose()
            $connection=Open-TranslateConnection $target $database;$connections.Add($connection)
            $stage='GENUINE_10_'+$mode
            Invoke-TranslateBatches $connection (Read-TranslateSql (Join-Path $legacy 'Deployment/Deploy.sql') $vars)
            if([int](Invoke-TranslateSql $connection "SELECT COUNT(*) FROM sys.objects WHERE schema_id=SCHEMA_ID(N'toolbelt_pseudonymization');" -Scalar) -ne 6){throw 'LEGACY_SIX_OBJECTS_FAILED'}
            $stage='UPGRADE_'+$mode
            $deploy=Read-TranslateSql (Join-Path $module 'Deployment/Deploy.sql') $vars
            $uninstall=Read-TranslateSql (Join-Path $module 'Deployment/Uninstall.sql') $vars
            Invoke-TranslateBatches $connection $deploy
            foreach($level in $levels){
                $stage='API_'+$mode+'_'+$level
                Invoke-TranslateSql $control ("ALTER DATABASE [$database] SET COMPATIBILITY_LEVEL=$level;")
                foreach($test in $RuntimeTests){
                    $stage='API_'+$mode+'_'+$level+'_'+$test
                    Write-Output ('RUNNING: '+$stage)
                    # SQLCMD startet je Datei eine eigene Session. Dasselbe gilt
                    # hier: caller-lokale Fixtures dürfen nicht andere eclipsen.
                    $testConnection=Open-TranslateConnection $target $database
                    try{Invoke-TranslateBatches $testConnection (Read-TranslateSql (Join-Path $module ('Tests/Runtime/'+$test)) $vars)}
                    finally{$testConnection.Dispose()}
                }
                Assert-TranslateMetadata $connection
            }
            $stage='CLIENT_METADATA_'+$mode
            Invoke-DeterministicClientMetadata $target $database
            if($mode -eq 'central'){
                $stage='CROSS_DATABASE'
                $consumer='tbx_translate_consumer_'+$runId
                if([int](Invoke-TranslateSql $control ("SELECT COUNT(*) FROM sys.databases WHERE name=N'$consumer';") -Scalar)){throw 'OWN_DATABASE_COLLISION'}
                $ledger.Databases+=@{Name=$consumer;State='CREATING'}
                $ledger|ConvertTo-Json -Depth 5|Set-Content -LiteralPath $journalPath -Encoding utf8
                Invoke-TranslateSql $control ("CREATE DATABASE [$consumer] COLLATE Latin1_General_100_CI_AS_SC_UTF8;")
                $owned.Add($consumer);$ledger.Databases[-1].State='CREATED'
                $consumerConnection=Open-TranslateConnection $target $consumer;$connections.Add($consumerConnection)
                Invoke-TranslateBatches $consumerConnection (Read-TranslateSql (Join-Path $module 'Tests/Runtime/Central.Contract.sql') $vars)
            }
            $stage='REPEAT_'+$mode
            Invoke-TranslateBatches $connection $deploy
            Invoke-TranslateBatches $connection (Read-TranslateSql (Join-Path $module 'Tests/Runtime/InstalledMetadata.Contract.sql') $vars)
            $stage='CALLER_TRANSACTION_'+$mode
            foreach($abort in @('OFF','ON')){
                Invoke-TranslateSql $connection ("SET XACT_ABORT $abort;CREATE TABLE #TranslateCaller(Value int);BEGIN TRAN;INSERT #TranslateCaller VALUES(7);")
                try{
                    $options=[int](Invoke-TranslateSql $connection 'SELECT @@OPTIONS;' -Scalar)
                    foreach($installer in @($deploy,$uninstall)){
                        Assert-TranslateRejected $connection $installer 50000
                        if([int](Invoke-TranslateSql $connection ("SELECT CASE WHEN @@TRANCOUNT=1 AND XACT_STATE()=1 AND @@OPTIONS=$options AND (SELECT SUM(Value) FROM #TranslateCaller)=7 THEN 1 ELSE 0 END;") -Scalar) -ne 1){throw 'CALLER_STATE_CHANGED'}
                    }
                }finally{Invoke-TranslateSql $connection 'IF @@TRANCOUNT>0 ROLLBACK;DROP TABLE #TranslateCaller;'}
            }
            $stage='UNINSTALL_'+$mode
            Invoke-TranslateBatches $connection $uninstall
            # Aktuelle Erstinstallation separat vom genuine Upgrade belegen.
            $stage='FRESH_'+$mode
            Invoke-TranslateBatches $connection $deploy
            Invoke-TranslateBatches $connection (Read-TranslateSql (Join-Path $module 'Tests/Runtime/InstalledMetadata.Contract.sql') $vars)
            $stage='COLLISION_'+$mode
            foreach($fault in @('UnknownVersion','ForeignFunctionMarker','InconsistentFunctionVersion')){
                $faultVars=$vars.Clone();$faultVars.FaultCase=$fault
                Invoke-TranslateBatches $connection (Read-TranslateSql (Join-Path $module 'Tests/Runtime/Lifecycle.CollisionFixture.sql') $faultVars)
                $number=if($fault -eq 'UnknownVersion'){54023}else{54024}
                Assert-TranslatePreservedRejection $connection $deploy $number $vars
                if($fault -eq 'UnknownVersion'){
                    Invoke-TranslateSql $connection "EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.Module.toolbelt.pseudonymization.deterministic.Version',@value=N'1.1.0';"
                }else{
                    $property=if($fault -eq 'ForeignFunctionMarker'){'Toolbelt.ModuleId'}else{'Toolbelt.ModuleVersion'}
                    $value=if($fault -eq 'ForeignFunctionMarker'){'toolbelt.pseudonymization.deterministic'}else{'1.1.0'}
                    Invoke-TranslateSql $connection ("EXEC sys.sp_updateextendedproperty @name=N'$property',@value=N'$value',@level0type=N'SCHEMA',@level0name=N'toolbelt_pseudonymization',@level1type=N'FUNCTION',@level1name=N'TVF_DeterministicTranslate';")
                }
            }
            Invoke-TranslateSql $connection "CREATE VIEW dbo.SyntheticTranslateDependency AS SELECT Value FROM toolbelt_pseudonymization.TVF_DeterministicTranslate(N'a',1,DEFAULT,DEFAULT,DEFAULT);"
            Assert-TranslatePreservedRejection $connection $uninstall 54027 $vars
            Invoke-TranslateSql $connection 'DROP VIEW dbo.SyntheticTranslateDependency;'
            if($mode -eq 'central'){
                $noConfirm=$vars.Clone();$noConfirm.ConfirmNoExternalConsumers=0
                Assert-TranslatePreservedRejection $connection (Read-TranslateSql (Join-Path $module 'Deployment/Uninstall.sql') $noConfirm) 54026 $vars
            }
            Invoke-TranslateBatches $connection $uninstall
            $stage='FUTURE_SLOT_'+$mode
            foreach($fault in @('FutureSlot','ImitatedFutureSlot')){
                Invoke-TranslateBatches $connection (Read-TranslateSql (Join-Path $legacy 'Deployment/Deploy.sql') $vars)
                $faultVars=$vars.Clone();$faultVars.FaultCase=$fault
                Invoke-TranslateBatches $connection (Read-TranslateSql (Join-Path $module 'Tests/Runtime/Lifecycle.CollisionFixture.sql') $faultVars)
                Assert-TranslatePreservedRejection $connection $deploy 54024 $vars
                Invoke-TranslateBatches $connection $uninstall
                if([int](Invoke-TranslateSql $connection "SELECT COUNT(*) FROM toolbelt_pseudonymization.TVF_DeterministicTranslate() WHERE CONVERT(varbinary(max),Value)=CONVERT(varbinary(max),N'Contoso') AND ErrorCode=73;" -Scalar) -ne 1){throw 'HISTORICAL_UNINSTALL_FOREIGN_SLOT_LOST'}
                Invoke-TranslateSql $connection 'DROP FUNCTION toolbelt_pseudonymization.TVF_DeterministicTranslate;'
            }
            if([int](Invoke-TranslateSql $connection "SELECT COUNT(*) FROM sys.objects WHERE schema_id=SCHEMA_ID(N'toolbelt_pseudonymization');" -Scalar)){throw 'OWN_OBJECTS_LEFT_AFTER_UNINSTALL'}
            Invoke-TranslateBatches $connection $uninstall
        }
        foreach($path in $sourceHashes.Keys){
            if((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -cne $sourceHashes[$path]){throw 'TESTED_SOURCE_CHANGED_DURING_RUN'}
        }
        $ledger.State='TESTS_PASSED'
    }catch{
        $failed=$true;$ledger.State='TESTS_FAILED'
        $failure=$_.Exception;$sqlFailure=$null
        while($failure){if($failure -is [Data.SqlClient.SqlException] -and -not $sqlFailure){$sqlFailure=$failure};$lastFailure=$failure;$failure=$failure.InnerException}
        $safe=if($sqlFailure){'SQL_'+$sqlFailure.Number+'_STATE_'+$sqlFailure.State}else{$lastFailure.GetType().Name}
        if($sqlFailure -and $sqlFailure.Number -eq 2714){
            foreach($known in @('USP_PrepareResultTable','USP_GetTempTableMeta','SVF_GetTempTableMeta','TVF_DeterministicIntegerBytes','TVF_DeterministicRangeCore','TVF_DeterministicRange','TVF_DeterministicDateShift','USP_DeterministicLookupCore','USP_DeterministicLookup','TVF_DeterministicTranslate','#tbx_ResultTableReleaseObjects','#tbx_ResultTableDeployState','#tbx_Deterministic_Release')){
                if($sqlFailure.Message.Contains($known)){Write-Output ('KNOWN_OBJECT_COLLISION: '+$known)}
            }
        }
        Write-Output ('FAILED: Translate stage='+$stage+' cause='+$safe)
    }finally{
        foreach($connection in $connections){$connection.Dispose()}
        if($control){
            foreach($database in $owned){
                try{
                    # Keine KILL-/SINGLE_USER-/Rollback-Immediate-Abkürzung.
                    Invoke-TranslateSql $control ("DROP DATABASE [$database];")
                    if([int](Invoke-TranslateSql $control ("SELECT COUNT(*) FROM sys.databases WHERE name=N'$database';") -Scalar)){throw 'DATABASE_DROP_UNCONFIRMED'}
                    foreach($entry in $ledger.Databases){if($entry.Name -ceq $database){$entry.State='DROPPED'}}
                }catch{$cleanupBlocked=$true;foreach($entry in $ledger.Databases){if($entry.Name -ceq $database){$entry.State='CLEANUP_BLOCKED'}}}
            }
            $control.Dispose()
        }
        if(@($ledger.Databases|Where-Object {$_.State -eq 'CREATING'}).Count){$cleanupBlocked=$true}
        $ledger.State=if($cleanupBlocked){'CLEANUP_BLOCKED'}elseif($failed){'FAILED_CLEANED'}else{'COMPLETE'}
        $ledger|ConvertTo-Json -Depth 5|Set-Content -LiteralPath $journalPath -Encoding utf8
    }
    if($cleanupBlocked){throw 'TRANSLATE_OWN_CLEANUP_REQUIRES_COORDINATION'}
    if($failed){throw 'TRANSLATE_LAB_FAILED'}
    Write-Output ('PASS: Translate genuine1.0 upgrade/selected API/metadata/repeat/caller/faults/future/uninstall; '+$Platform+' SQL'+$Version+'; modes='+($DeploymentModes -join ',')+'; tests='+($RuntimeTests -join ',')+'; no configuration/rights changes; own cleanup complete')
}
