[CmdletBinding()]
param(
    [ValidateSet('windows','linux')][string]$Platform='linux',
    [ValidateSet('2019','2022','2025')][string]$Version='2019',
    [string]$Patch='latest',
    [Parameter(Mandatory)][string]$LegacyDirectory,
    [Parameter(Mandatory)][string]$Legacy11Directory,
    [ValidateSet('local','central')][string[]]$DeploymentModes=@('local','central'),
    [ValidateSet('Range.Contract.sql','DateShift.Contract.sql','Lookup.Contract.sql','Lookup.Boundaries.sql','Translate.Contract.sql','Translate.Safety.sql','GeoJitter.Contract.sql','GeoJitter.Safety.sql','InstalledMetadata.Contract.sql')]
    [string[]]$RuntimeTests=@('Range.Contract.sql','DateShift.Contract.sql','Lookup.Contract.sql','Lookup.Boundaries.sql','Translate.Contract.sql','Translate.Safety.sql','GeoJitter.Contract.sql','GeoJitter.Safety.sql','InstalledMetadata.Contract.sql')
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$module=Join-Path $repo 'Modules/toolbelt.pseudonymization.deterministic'
$legacy10=(Resolve-Path -LiteralPath $LegacyDirectory).Path
$legacy11=(Resolve-Path -LiteralPath $Legacy11Directory).Path
$legacy=$legacy10

# Nur die geprüften Discovery- und Native-Helfer importieren, niemals einen
# generischen Lab-Runner oder den Top-level-Mutator des Vorgängerdrivers.
function Import-GeoFunctions([string]$Path,[string[]]$Names){
    $errors=$null
    $tree=[Management.Automation.Language.Parser]::ParseFile($Path,[ref]$null,[ref]$errors)
    if($errors.Count){throw 'GEO_HELPER_PARSE_FAILED'}
    foreach($name in $Names){
        $definitions=@($tree.FindAll({param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $name},$true))
        if($definitions.Count -ne 1){throw 'GEO_HELPER_AMBIGUOUS'}
        # Die caller-Session ist der einzige Import-Scope.
        $script:geoDefinitions.Add($definitions[0].Extent.Text)
    }
}
$geoDefinitions=[Collections.Generic.List[string]]::new()
Import-GeoFunctions (Join-Path $PSScriptRoot 'run-lab-local.ps1') @('Get-EnvironmentVariableValue','Resolve-LabContract','Test-LabTargetReady','Get-LabTargetsForSelector','New-LabConnectionString','Invoke-LabPreflight')
Import-GeoFunctions (Join-Path $PSScriptRoot 'run-deterministic-translate-lab.ps1') @('Read-TranslateSql','Invoke-TranslateSql','Invoke-TranslateBatches','Assert-TranslateRejected','Get-TranslateSnapshot','Assert-TranslatePreservedRejection','Open-TranslateConnection','Invoke-DeterministicClientMetadata')
foreach($definition in $geoDefinitions){. ([scriptblock]::Create($definition))}

$geoBatchIndex=0
function Invoke-GeoBatches($Connection,[string]$Sql){
    # Nur Nummer und fachlichen Testnamen melden; keine SQL-/Runnerdiagnostik.
    $script:geoBatchIndex=0
    foreach($batch in [regex]::Split($Sql,'(?im)^\s*GO\s*(?:--[^\r\n]*)?$')){
        if(-not [string]::IsNullOrWhiteSpace($batch)){
            $script:geoBatchIndex++
            if($stage -match 'GeoJitter\.(Contract|Safety)\.sql$'){
                Write-Output ('RUNNING_BATCH: '+$stage+'_'+$script:geoBatchIndex)
            }
            Invoke-TranslateSql $Connection $batch
        }
    }
}

function Assert-GeoLegacy([string]$Directory,[string]$Commit,[int]$Slots){
    $paths=@('Deployment/Deploy.sql','Deployment/Uninstall.sql','Deployment/ReleaseManifest.sql',
        'Source/TVF_DeterministicIntegerBytes.sql','Source/TVF_DeterministicRangeCore.sql','Source/TVF_DeterministicRange.sql',
        'Source/TVF_DeterministicDateShift.sql','Source/USP_DeterministicLookupCore.sql','Source/USP_DeterministicLookup.sql')
    if($Slots -eq 7){$paths+='Source/DeterministicTranslate.sql'}
    foreach($relative in $paths){
        $expected=(& git -C $repo show ($Commit+':Modules/toolbelt.pseudonymization.deterministic/'+$relative)) -join "`n"
        if($LASTEXITCODE -ne 0){throw 'GEO_LEGACY_PUBLIC_SOURCE_UNAVAILABLE'}
        $actual=[IO.File]::ReadAllText((Join-Path $Directory $relative)).Replace("`r`n","`n").TrimEnd("`n")
        if($actual -cne $expected.TrimEnd("`n")){throw 'GEO_LEGACY_GENUINE_SOURCE_MISMATCH'}
    }
}
Assert-GeoLegacy $legacy10 '9c77df2761db469ed9b2c20b48a4c909c69f7700' 6
Assert-GeoLegacy $legacy11 '76851e45f407089e062792c010176ae35a0ee77b' 7
$lab=Resolve-LabContract
$targets=@(Get-LabTargetsForSelector -Contract $lab.Contract -Selector ([pscustomobject]@{Platform=$Platform;Version=$Version;Patch=$Patch}))
if(-not $targets.Count){throw 'GEO_LAB_EXPLICIT_TARGET_NOT_READY'}
$levels=switch($Version){'2019'{@(150)};'2022'{@(150,160)};'2025'{@(150,160,170)}}
$hashes=@{}
$sourceFiles=@(Get-ChildItem (Join-Path $module 'Source') -File)
if($sourceFiles.Count -ne 8 -or -not (Test-Path -LiteralPath (Join-Path $module 'Source/DeterministicGeoJitter.sql'))){throw 'GEO_SOURCE_FREEZE_INCOMPLETE'}
foreach($file in ($sourceFiles+@(Get-ChildItem (Join-Path $module 'Deployment') -Filter '*.sql' -File)+@(Get-ChildItem (Join-Path $module 'Tests/Runtime') -File))){
    $hashes[$file.FullName]=(Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
}
foreach($target in $targets){
    [void](Invoke-LabPreflight -Entry $target)
    $runId=[guid]::NewGuid().ToString('N')
    $journal=Join-Path ([IO.Path]::GetTempPath()) ('ToolbeltGeoRestore-'+$runId+'.json')
    $ledger=[ordered]@{RunId=$runId;State='PREPARED';Databases=@();ConfigurationChanges=0;RightsChanges=0}
    $owned=[Collections.Generic.List[string]]::new()
    $connections=[Collections.Generic.List[Data.SqlClient.SqlConnection]]::new()
    $control=$null;$failed=$false;$cleanupBlocked=$false;$stage='CREATE'
    try{
        $control=Open-TranslateConnection $target 'master'
        foreach($mode in $DeploymentModes){
            $database='tbx_geo_'+$mode+'_'+$runId
            $stage='CREATE_'+$mode
            if([int](Invoke-TranslateSql $control ("SELECT COUNT(*) FROM sys.databases WHERE name=N'$database';") -Scalar)){throw 'GEO_OWN_DATABASE_COLLISION'}
            $ledger.Databases+=@{Name=$database;State='CREATING'}
            $ledger|ConvertTo-Json -Depth 5|Set-Content -LiteralPath $journal -Encoding utf8
            $collation=if($mode -eq 'local'){'Latin1_General_100_CS_AS'}else{'Latin1_General_100_BIN2'}
            Invoke-TranslateSql $control ("CREATE DATABASE [$database] COLLATE $collation;")
            $owned.Add($database);$ledger.Databases[-1].State='CREATED'
            $connection=Open-TranslateConnection $target $database;$connections.Add($connection)
            $vars=@{DeploymentMode=$mode;ConfirmNoExternalConsumers=1;ToolbeltDatabase=$database;CentralDb=$database;HistoricalVersion='1.0.0'}
            $stage='DEPENDENCY_'+$mode
            Invoke-GeoBatches $connection (Read-TranslateSql (Join-Path $repo 'Modules/toolbelt.core.result-table/Deployment/Deploy.sql') $vars)
            # Installer-Temps enden mit ihrer Session; keine benannten Temp-PK-
            # Kollisionen zwischen den eigenen Installationsverbrauchern.
            $connection.Dispose();$connection=Open-TranslateConnection $target $database;$connections.Add($connection)
            $deploy=Read-TranslateSql (Join-Path $module 'Deployment/Deploy.sql') $vars
            $uninstall=Read-TranslateSql (Join-Path $module 'Deployment/Uninstall.sql') $vars
            foreach($history in @(@{Directory=$legacy10;Version='1.0.0';Slots=6},@{Directory=$legacy11;Version='1.1.0';Slots=7})){
                $legacy=$history.Directory;$vars.HistoricalVersion=$history.Version
                $stage='GENUINE_'+$history.Version+'_'+$mode
                Invoke-GeoBatches $connection (Read-TranslateSql (Join-Path $legacy 'Deployment/Deploy.sql') $vars)
                if([int](Invoke-TranslateSql $connection "SELECT COUNT(*) FROM sys.objects WHERE schema_id=SCHEMA_ID(N'toolbelt_pseudonymization');" -Scalar) -ne $history.Slots){throw 'GEO_LEGACY_INVENTORY_FAILED'}
                $stage='UPGRADE_'+$history.Version+'_'+$mode
                Invoke-GeoBatches $connection $deploy
                Invoke-GeoBatches $connection (Read-TranslateSql (Join-Path $module 'Tests/Runtime/InstalledMetadata.Contract.sql') $vars)
                if($history.Version -eq '1.0.0'){
                    foreach($level in $levels){
                        Invoke-TranslateSql $control ("ALTER DATABASE [$database] SET COMPATIBILITY_LEVEL=$level;")
                        foreach($test in $RuntimeTests){
                            $stage='API_'+$mode+'_'+$level+'_'+$test
                            Write-Output ('RUNNING: '+$stage)
                            $testConnection=Open-TranslateConnection $target $database
                            try{Invoke-GeoBatches $testConnection (Read-TranslateSql (Join-Path $module ('Tests/Runtime/'+$test)) $vars)}
                            finally{$testConnection.Dispose()}
                        }
                    }
                }else{
                    # Die ausgewählten RuntimeTests liefen oben je CL. Nach
                    # echtem 1.1-Upgrade die neue API am aktuellen Stand prüfen.
                    $stage='UPGRADE_11_GEO_'+$mode
                    Invoke-GeoBatches $connection (Read-TranslateSql (Join-Path $module 'Tests/Runtime/GeoJitter.Contract.sql') $vars)
                }
                $stage='CLIENT_METADATA_'+$history.Version+'_'+$mode
                Invoke-DeterministicClientMetadata $target $database
                $stage='UPGRADE_UNINSTALL_'+$history.Version+'_'+$mode
                Invoke-GeoBatches $connection $uninstall
            }
            $legacy=$legacy10;$vars.HistoricalVersion='1.0.0'
            $stage='FRESH_REPEAT_'+$mode
            Invoke-GeoBatches $connection $deploy
            Invoke-GeoBatches $connection $deploy
            Invoke-GeoBatches $connection (Read-TranslateSql (Join-Path $module 'Tests/Runtime/InstalledMetadata.Contract.sql') $vars)
            if($mode -eq 'central'){
                $stage='CROSS_DATABASE'
                $consumer='tbx_geo_consumer_'+$runId
                if([int](Invoke-TranslateSql $control ("SELECT COUNT(*) FROM sys.databases WHERE name=N'$consumer';") -Scalar)){throw 'GEO_OWN_DATABASE_COLLISION'}
                $ledger.Databases+=@{Name=$consumer;State='CREATING'}
                $ledger|ConvertTo-Json -Depth 5|Set-Content -LiteralPath $journal -Encoding utf8
                Invoke-TranslateSql $control ("CREATE DATABASE [$consumer] COLLATE Latin1_General_100_CI_AS_SC_UTF8;")
                $owned.Add($consumer);$ledger.Databases[-1].State='CREATED'
                $consumerConnection=Open-TranslateConnection $target $consumer;$connections.Add($consumerConnection)
                Invoke-GeoBatches $consumerConnection (Read-TranslateSql (Join-Path $module 'Tests/Runtime/Central.Contract.sql') $vars)
            }
            $stage='CALLER_TRANSACTION_'+$mode
            foreach($abort in @('OFF','ON')){
                Invoke-TranslateSql $connection ("SET XACT_ABORT $abort;CREATE TABLE #GeoCaller(Value int);BEGIN TRAN;INSERT #GeoCaller VALUES(7);")
                try{
                    $options=[int](Invoke-TranslateSql $connection 'SELECT @@OPTIONS;' -Scalar)
                    foreach($installer in @($deploy,$uninstall)){
                        Assert-TranslateRejected $connection $installer 50000
                        if([int](Invoke-TranslateSql $connection ("SELECT CASE WHEN @@TRANCOUNT=1 AND XACT_STATE()=1 AND @@OPTIONS=$options AND (SELECT SUM(Value) FROM #GeoCaller)=7 THEN 1 ELSE 0 END;") -Scalar) -ne 1){throw 'GEO_CALLER_STATE_CHANGED'}
                    }
                }finally{Invoke-TranslateSql $connection 'IF @@TRANCOUNT>0 ROLLBACK;DROP TABLE #GeoCaller;'}
            }
            $stage='COLLISION_'+$mode
            foreach($fault in @('UnknownVersion','ForeignFunctionMarker','InconsistentFunctionVersion')){
                $faultVars=$vars.Clone();$faultVars.FaultCase=$fault
                Invoke-GeoBatches $connection (Read-TranslateSql (Join-Path $module 'Tests/Runtime/Lifecycle.CollisionFixture.sql') $faultVars)
                $number=if($fault -eq 'UnknownVersion'){54023}else{54024}
                Assert-TranslatePreservedRejection $connection $deploy $number $vars
                if($fault -eq 'UnknownVersion'){
                    Invoke-TranslateSql $connection "EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.Module.toolbelt.pseudonymization.deterministic.Version',@value=N'1.2.0';"
                }else{
                    $property=if($fault -eq 'ForeignFunctionMarker'){'Toolbelt.ModuleId'}else{'Toolbelt.ModuleVersion'}
                    $value=if($fault -eq 'ForeignFunctionMarker'){'toolbelt.pseudonymization.deterministic'}else{'1.2.0'}
                    Invoke-TranslateSql $connection ("EXEC sys.sp_updateextendedproperty @name=N'$property',@value=N'$value',@level0type=N'SCHEMA',@level0name=N'toolbelt_pseudonymization',@level1type=N'FUNCTION',@level1name=N'TVF_DeterministicGeoJitter';")
                }
            }
            Invoke-TranslateSql $connection 'CREATE VIEW dbo.SyntheticGeoDependency AS SELECT Value FROM toolbelt_pseudonymization.TVF_DeterministicGeoJitter(geography::Point(0,0,4326),0x01,1,DEFAULT,DEFAULT);'
            Assert-TranslatePreservedRejection $connection $uninstall 54027 $vars
            Invoke-TranslateSql $connection 'DROP VIEW dbo.SyntheticGeoDependency;'
            if($mode -eq 'central'){
                $noConfirm=$vars.Clone();$noConfirm.ConfirmNoExternalConsumers=0
                Assert-TranslatePreservedRejection $connection (Read-TranslateSql (Join-Path $module 'Deployment/Uninstall.sql') $noConfirm) 54026 $vars
            }
            Invoke-GeoBatches $connection $uninstall
            foreach($history in @(@{Directory=$legacy10;Version='1.0.0';Faults=@('FutureSlot','ImitatedFutureSlot','GeoFutureSlot','GeoImitatedFutureSlot')},@{Directory=$legacy11;Version='1.1.0';Faults=@('GeoFutureSlot','GeoImitatedFutureSlot')})){
                $legacy=$history.Directory;$vars.HistoricalVersion=$history.Version
                foreach($fault in $history.Faults){
                    $stage='FUTURE_'+$history.Version+'_'+$fault+'_'+$mode
                    Invoke-GeoBatches $connection (Read-TranslateSql (Join-Path $legacy 'Deployment/Deploy.sql') $vars)
                    $faultVars=$vars.Clone();$faultVars.FaultCase=$fault
                    Invoke-GeoBatches $connection (Read-TranslateSql (Join-Path $module 'Tests/Runtime/Lifecycle.CollisionFixture.sql') $faultVars)
                    Assert-TranslatePreservedRejection $connection $deploy 54024 $vars
                    Invoke-GeoBatches $connection $uninstall
                    $future=if($fault.StartsWith('Geo')){'TVF_DeterministicGeoJitter'}else{'TVF_DeterministicTranslate'}
                    if([int](Invoke-TranslateSql $connection ("SELECT COUNT(*) FROM toolbelt_pseudonymization.$future() WHERE ErrorCode=73;") -Scalar) -ne 1){throw 'GEO_HISTORICAL_UNINSTALL_FOREIGN_SLOT_LOST'}
                    Invoke-TranslateSql $connection ("DROP FUNCTION toolbelt_pseudonymization.$future;")
                }
            }
            if([int](Invoke-TranslateSql $connection "SELECT COUNT(*) FROM sys.objects WHERE schema_id=SCHEMA_ID(N'toolbelt_pseudonymization');" -Scalar)){throw 'GEO_OWN_OBJECTS_LEFT'}
            Invoke-GeoBatches $connection $uninstall
        }
        if(@(Get-ChildItem (Join-Path $module 'Source') -File).Count -ne $sourceFiles.Count){throw 'GEO_TESTED_SOURCE_SET_CHANGED'}
        foreach($path in $hashes.Keys){if((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -cne $hashes[$path]){throw 'GEO_TESTED_SOURCE_CHANGED'}}
        $ledger.State='TESTS_PASSED'
    }catch{
        $failed=$true;$ledger.State='TESTS_FAILED';$failure=$_.Exception;$sqlFailure=$null
        while($failure){if($failure -is [Data.SqlClient.SqlException] -and -not $sqlFailure){$sqlFailure=$failure};$lastFailure=$failure;$failure=$failure.InnerException}
        $safe=if($sqlFailure){'SQL_'+$sqlFailure.Number+'_STATE_'+$sqlFailure.State}else{$lastFailure.GetType().Name}
        Write-Output ('FAILED: Geo stage='+$stage+' batch='+$geoBatchIndex+' cause='+$safe)
    }finally{
        foreach($connection in $connections){$connection.Dispose()}
        if($control){
            foreach($database in $owned){
                try{
                    # Ausschließlich eigene GUID-Datenbanken; kein erzwungener
                    # Disconnect, KILL oder ROLLBACK IMMEDIATE.
                    Invoke-TranslateSql $control ("DROP DATABASE [$database];")
                    if([int](Invoke-TranslateSql $control ("SELECT COUNT(*) FROM sys.databases WHERE name=N'$database';") -Scalar)){throw 'GEO_DROP_UNCONFIRMED'}
                    foreach($entry in $ledger.Databases){if($entry.Name -ceq $database){$entry.State='DROPPED'}}
                }catch{$cleanupBlocked=$true;foreach($entry in $ledger.Databases){if($entry.Name -ceq $database){$entry.State='CLEANUP_BLOCKED'}}}
            }
            $control.Dispose()
        }
        if(@($ledger.Databases|Where-Object {$_.State -eq 'CREATING'}).Count){$cleanupBlocked=$true}
        $ledger.State=if($cleanupBlocked){'CLEANUP_BLOCKED'}elseif($failed){'FAILED_CLEANED'}else{'COMPLETE'}
        $ledger|ConvertTo-Json -Depth 5|Set-Content -LiteralPath $journal -Encoding utf8
    }
    if($cleanupBlocked){throw 'GEO_OWN_CLEANUP_REQUIRES_COORDINATION'}
    if($failed){throw 'GEO_LAB_FAILED'}
    Write-Output ('PASS: Geo RuntimeTests='+($RuntimeTests -join ',')+'; metadata/genuine1.0+1.1/repeat/caller/faults/future/uninstall; '+$Platform+' SQL'+$Version+'; modes='+($DeploymentModes -join ',')+'; no configuration/rights changes; own cleanup complete')
}
