[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('2019','2022','2025')][string]$Version,
    [ValidateSet('windows','linux')][string]$Platform = 'windows',
    [string]$Patch = 'base',
    [Parameter(Mandatory)][string]$ReleaseDirectory,
    [string]$PreviousReleaseDirectory,
    [switch]$ApiQualificationOnly,
    [ValidateSet('local','central')][string]$ApiDeploymentMode='local',
    [switch]$OptInExactTrust,
    [string]$PrivateJournalDirectory = (Join-Path ([IO.Path]::GetTempPath()) 'ToolbeltCaptureTrustJournals')
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$moduleRoot = Join-Path $repoRoot 'Modules/toolbelt.string.regex'
$script:CaptureStage = 'PREFLIGHT'
$script:CaptureBatch = 0

# Nur kanonische, lesende Discovery verwenden; keinen allgemeinen Runner starten.
$parseErrors = $null; $parseTokens = $null
$ast = [Management.Automation.Language.Parser]::ParseFile(
    (Join-Path $PSScriptRoot 'run-lab-local.ps1'), [ref]$parseTokens, [ref]$parseErrors)
if ($parseErrors.Count) { throw 'LAB_DISCOVERY_SYNTAX_INVALID' }
foreach ($name in @('Get-EnvironmentVariableValue','Resolve-LabContract',
    'Test-LabTargetReady','Get-LabTargetsForSelector','New-LabConnectionString','Invoke-LabPreflight')) {
    $definitions = @($ast.FindAll({param($node)
        $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $name
    }, $true))
    if ($definitions.Count -ne 1) { throw 'LAB_DISCOVERY_NOT_UNIQUE' }
    . ([scriptblock]::Create($definitions[0].Extent.Text))
}

function Invoke-CaptureSql {
    param([Data.SqlClient.SqlConnection]$Connection,[string]$Text,[switch]$Scalar,[int]$BatchNumber=0)
    $script:CaptureBatch=$BatchNumber
    $command = $Connection.CreateCommand()
    $command.CommandTimeout = 90
    $command.CommandText = $Text
    try {
        if ($Scalar) { return $command.ExecuteScalar() }
        [void]$command.ExecuteNonQuery()
    } finally { $command.Dispose() }
}

function Read-CaptureScript {
    param([string]$Path,[hashtable]$Variables)
    $text = Get-Content -LiteralPath $Path -Raw
    # Ausschließlich die drei kanonischen Modulquellen expandieren. Historische
    # Artefakte müssen ihre Source-Includes bereits privat verpackt enthalten.
    foreach ($name in @('RegexFunctions.sql','RegexRelations.sql','RegexCaptures.sql')) {
        $include = ':r ../Source/' + $name
        if ($text.Contains($include)) {
            $text = $text.Replace($include,(Get-Content -LiteralPath (Join-Path $moduleRoot ('Source/' + $name)) -Raw).TrimEnd())
        }
    }
    foreach ($key in $Variables.Keys) { $text = $text.Replace('$(' + $key + ')', [string]$Variables[$key]) }
    if ($text -match '\$\(' -or $text -match '(?m)^:r\s+') { throw 'UNRESOLVED_SQLCMD_INPUT' }
    $text = [regex]::Replace($text, '(?im)^:On Error exit\s*$', '')
    if ($text -match '(?m)^:') { throw 'UNSUPPORTED_SQLCMD_DIRECTIVE' }
    return $text
}

function Invoke-CaptureBatches {
    param([Data.SqlClient.SqlConnection]$Connection,[string]$Text,[string]$Stage)
    if($Stage){
        if($Stage -cnotmatch '^[A-Z][A-Z0-9_]*$'){throw 'INVALID_DIAGNOSTIC_STAGE'}
        $script:CaptureStage=$Stage
    }
    # Erster SQL-Fehler stoppt alle folgenden Batches wie :On Error exit.
    $batchNumber=0
    foreach ($batch in [regex]::Split($Text, '(?im)^\s*GO\s*(?:--[^\r\n]*)?\r?$')) {
        if (-not [string]::IsNullOrWhiteSpace($batch)) {
            $batchNumber++
            Invoke-CaptureSql $Connection $batch -BatchNumber $batchNumber
        }
    }
}

function Get-CaptureSnapshot {
    param([Data.SqlClient.SqlConnection]$Connection)
    $script:CaptureBatch=0
    $command = $Connection.CreateCommand()
    $command.CommandText = Get-Content -LiteralPath (Join-Path $moduleRoot 'Tests/Runtime/Lifecycle.Snapshot.sql') -Raw
    $command.CommandTimeout = 90
    try {
        $reader = $command.ExecuteReader()
        try {
            if (-not $reader.Read()) { throw 'SNAPSHOT_MISSING' }
            $values = @(for ($i=0; $i -lt $reader.FieldCount; $i++) {
                if ($reader.IsDBNull($i)) { $null } else { [string]$reader.GetValue($i) }
            })
            return ($values | ConvertTo-Json -Compress)
        } finally { $reader.Dispose() }
    } finally { $command.Dispose() }
}

function Assert-CaptureRejected {
    param([Data.SqlClient.SqlConnection]$Connection,[string]$Text,[int]$Expected)
    $caught = $false
    try { Invoke-CaptureBatches $Connection $Text }
    catch {
        $failure = $_.Exception
        while ($failure.InnerException) { $failure = $failure.InnerException }
        if ($failure -isnot [Data.SqlClient.SqlException] -or $failure.Number -ne $Expected) {
            $number=if ($failure -is [Data.SqlClient.SqlException]) {$failure.Number} else {0}
            $line=if ($failure -is [Data.SqlClient.SqlException]) {$failure.LineNumber} else {0}
            throw ('EXPECTED_LIFECYCLE_ERROR_MISMATCH_EXPECTED_' + $Expected + '_ACTUAL_' + $number + '_STAGE_' + $script:CaptureStage + '_BATCH_' + $script:CaptureBatch + '_LINE_' + $line)
        }
        $caught = $true
    }
    if (-not $caught) { throw 'EXPECTED_LIFECYCLE_REJECTION_MISSING' }
}

function Assert-CallerTransaction {
    param([Data.SqlClient.SqlConnection]$Connection,[string]$Deploy,[string]$Uninstall)
    $metadata = Get-CaptureSnapshot $Connection
    foreach ($xact in @('OFF','ON')) {
        foreach ($nocount in @('OFF','ON')) {
            Invoke-CaptureSql $Connection ("SET XACT_ABORT $xact; SET NOCOUNT $nocount; CREATE TABLE #CallerWork(Value int); BEGIN TRAN; INSERT #CallerWork VALUES(1);")
            try {
                $options = Invoke-CaptureSql $Connection 'SELECT @@OPTIONS;' -Scalar
                foreach ($script in @($Deploy,$Uninstall)) {
                    Assert-CaptureRejected $Connection $script 50000
                    $preserved = Invoke-CaptureSql $Connection ("SELECT CASE WHEN @@TRANCOUNT=1 AND XACT_STATE()=1 AND @@OPTIONS=$options AND (SELECT COUNT(*) FROM #CallerWork)=1 THEN 1 ELSE 0 END;") -Scalar
                    if ([int]$preserved -ne 1 -or (Get-CaptureSnapshot $Connection) -cne $metadata) {
                        throw 'CALLER_TRANSACTION_OR_OPTIONS_CHANGED'
                    }
                }
            } finally {
                Invoke-CaptureSql $Connection 'IF @@TRANCOUNT>0 ROLLBACK; DROP TABLE #CallerWork;'
            }
        }
    }
}

function Get-TrustedDescription {
    param([Data.SqlClient.SqlConnection]$Connection,[string]$Hash)
    $command = $Connection.CreateCommand()
    $command.CommandText = 'SELECT description FROM sys.trusted_assemblies WHERE hash=CONVERT(varbinary(64),@Hash,1);'
    [void]$command.Parameters.Add('@Hash',[Data.SqlDbType]::VarChar,130)
    $command.Parameters['@Hash'].Value = $Hash
    try { $value = $command.ExecuteScalar(); if ($null -ne $value -and $value -isnot [DBNull]) { return [string]$value } }
    finally { $command.Dispose() }
}

function Save-TrustLedger {
    param($Ledger,[string]$Path)
    $Ledger | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $Path -Encoding utf8
}

function Set-TrustLedgerBlocked {
    param($Ledger,[string]$Path)
    if ($null -eq $Ledger) { return }
    $Ledger.State = 'RESTORE_BLOCKED'
    foreach ($entry in $Ledger.Entries) {
        if ($entry.AddedByWave -and $entry.State -ne 'RESTORED') { $entry.State='RESTORE_BLOCKED_UNCONFIRMED_SCOPE' }
    }
    Save-TrustLedger $Ledger $Path
}

function Assert-NoAssemblyConsumer {
    param([Data.SqlClient.SqlConnection]$Connection,[string]$Hash)
    $command = $Connection.CreateCommand()
    $command.CommandText = 'SELECT name,state FROM sys.databases ORDER BY database_id;'
    $databases = [Collections.Generic.List[string]]::new()
    try {
        $reader = $command.ExecuteReader()
        try {
            while ($reader.Read()) {
                if ($reader.GetByte(1) -ne 0) { return $false }
                $databases.Add($reader.GetString(0))
            }
        } finally { $reader.Dispose() }
    } finally { $command.Dispose() }
    foreach ($name in $databases) {
        $safeName = $name.Replace(']',']]')
        try {
            $count = Invoke-CaptureSql $Connection (
                'SELECT COUNT(*) FROM [' + $safeName + '].sys.assembly_files WHERE file_id=1 AND HASHBYTES(N''SHA2_512'',content)=' + $Hash + ';') -Scalar
            if ([int]$count -ne 0) { return $false }
        } catch { return $false }
    }
    return $true
}

# Artefaktprüfung vor Netzwerkzugriff: SAFE, exakter Hash, gekoppelte Source.
$manifest = Get-Content -LiteralPath (Join-Path $ReleaseDirectory 'Toolbelt.String.Regex.trust-manifest.json') -Raw | ConvertFrom-Json
$providerPath = Join-Path $ReleaseDirectory 'Toolbelt.String.Regex.dll'
$sourcePaths=@('Clr/Toolbelt.String.Regex.csproj','Clr/Properties/AssemblyInfo.cs',
    'Clr/RegexProvider.cs','Clr/RegexTransformations.cs','Clr/RegexRelations.cs','Clr/RegexCaptures.cs',
    'Source/RegexFunctions.sql','Source/RegexRelations.sql','Source/RegexCaptures.sql',
    'Deployment/Deploy.sql','Deployment/Uninstall.sql','Scripts/New-ClrReleaseArtifacts.ps1')
if (@($manifest.sourceFingerprints).Count -ne $sourcePaths.Count) { throw 'RELEASE_SOURCE_MANIFEST_INVALID' }
for ($i=0;$i -lt $sourcePaths.Count;$i++) {
    if ($manifest.sourceFingerprints[$i].path -cne $sourcePaths[$i] -or
        (Get-FileHash -LiteralPath (Join-Path $moduleRoot $sourcePaths[$i]) -Algorithm SHA256).Hash -cne $manifest.sourceFingerprints[$i].sha256) {
        throw 'RELEASE_SOURCE_FINGERPRINT_MISMATCH'
    }
}
if ($manifest.moduleId -cne 'toolbelt.string.regex' -or $manifest.moduleVersion -cne '1.3.0' -or
    $manifest.permissionSet -cne 'SAFE' -or [string]$manifest.sha512 -cnotmatch '^[0-9A-F]{128}$' -or
    $manifest.sqlServerHexLiteral -cne ('0x' + $manifest.sha512) -or
    (Get-FileHash -LiteralPath $providerPath -Algorithm SHA512).Hash -cne $manifest.sha512 -or
    [Reflection.AssemblyName]::GetAssemblyName($providerPath).Version.ToString() -cne '1.3.0.0') {
    throw 'RELEASE_IDENTITY_OR_FINGERPRINT_INVALID'
}
$expectedDeploy = Get-Content -LiteralPath (Join-Path $moduleRoot 'Deployment/Deploy.sql') -Raw
$expectedDeploy = $expectedDeploy.Replace('$(AssemblyBits)','0x' + [BitConverter]::ToString([IO.File]::ReadAllBytes($providerPath)).Replace('-',''))
$actualDeploy = Get-Content -LiteralPath (Join-Path $ReleaseDirectory 'Deploy.WithAssembly.sql') -Raw
if ($actualDeploy.Replace("`r`n","`n").TrimEnd() -cne $expectedDeploy.Replace("`r`n","`n").TrimEnd()) { throw 'RELEASE_DEPLOYMENT_SOURCE_MISMATCH' }
try {
    & (Join-Path $moduleRoot 'Tests/Framework/run-framework-captures.ps1') -AssemblyPath $providerPath
    if (-not $?) { throw 'INTEGRATED_FRAMEWORK_GATE_FAILED' }
} catch { throw 'INTEGRATED_FRAMEWORK_GATE_FAILED' }

$previous = $null; $previousDeploy = $null
if ($PreviousReleaseDirectory) {
    $provenance = Get-Content -LiteralPath (Join-Path $PreviousReleaseDirectory 'fixture-provenance.json') -Raw | ConvertFrom-Json
    $previous = Get-Content -LiteralPath (Join-Path $PreviousReleaseDirectory 'Toolbelt.String.Regex.trust-manifest.json') -Raw | ConvertFrom-Json
    if ($provenance.sourceCommit -cne '1b838df8e54a211b16f7f1c303c21b66b673940e' -or
        $previous.moduleVersion -cne '1.2.0' -or $previous.permissionSet -cne 'SAFE' -or
        $previous.sqlServerHexLiteral -cne ('0x' + $previous.sha512) -or
        (Get-FileHash -LiteralPath (Join-Path $PreviousReleaseDirectory 'Toolbelt.String.Regex.dll') -Algorithm SHA512).Hash -cne $previous.sha512 -or
        $provenance.providerSha512 -cne $previous.sha512 -or
        (Get-FileHash -LiteralPath (Join-Path $PreviousReleaseDirectory 'Deploy.WithAssembly.sql') -Algorithm SHA256).Hash -cne $provenance.fixtureDeploySha256) {
        throw 'GENUINE_PREDECESSOR_FINGERPRINT_INVALID'
    }
    $previousDeploy = Get-Content -LiteralPath (Join-Path $PreviousReleaseDirectory 'Deploy.WithAssembly.sql') -Raw
    # Verpackte Original-Sources: Hashvergleich gegen den festgelegten Git-Stand.
    foreach ($name in @('RegexFunctions.sql','RegexRelations.sql')) {
        $original = (& git -C $repoRoot show ('1b838df8e54a211b16f7f1c303c21b66b673940e:Modules/toolbelt.string.regex/Source/' + $name)) -join "`n"
        if ($LASTEXITCODE -ne 0) { throw 'GENUINE_PREDECESSOR_SOURCE_UNAVAILABLE' }
        $include = [regex]::Matches($previousDeploy,'(?m)^:r\s+([^\r\n]*' + [regex]::Escape($name) + ')\s*$')
        if ($include.Count -ne 1) { throw 'GENUINE_PREDECESSOR_INCLUDE_INVALID' }
        $includePath=$include[0].Groups[1].Value.Trim().Trim('"')
        if (-not [IO.Path]::IsPathRooted($includePath)) { $includePath=Join-Path $PreviousReleaseDirectory $includePath }
        $source = Get-Content -LiteralPath $includePath -Raw
        if ($source.Replace("`r`n","`n").TrimEnd() -cne $original.TrimEnd()) { throw 'GENUINE_PREDECESSOR_SOURCE_MISMATCH' }
        $previousDeploy = $previousDeploy.Replace($include[0].Value,$source.TrimEnd())
    }
    if ($previousDeploy -match '(?m)^:r\s+') { throw 'GENUINE_PREDECESSOR_UNRESOLVED_INCLUDE' }
    # SQLClient erhält T-SQL; der Batchrunner bewahrt die Stop-on-error-Semantik.
    $previousDeploy = [regex]::Replace($previousDeploy,'(?im)^:On Error exit\s*$','')
    if($previousDeploy -match '\$\((?!DeploymentMode\))' -or $previousDeploy -match '(?m)^:'){
        throw 'GENUINE_PREDECESSOR_UNRESOLVED_SQLCMD'
    }
}
try { $lab = Resolve-LabContract } catch { throw 'LAB_CONTRACT_INVALID_OR_UNAVAILABLE' }
$promptPath = Get-EnvironmentVariableValue 'SQL_SERVER_LAB_TEST_ENV_PROMPT_FILE'
if ($promptPath -and [string]::IsNullOrWhiteSpace((Get-Content -LiteralPath $promptPath -Raw))) { throw 'LAB_SUPPLEMENTAL_INSTRUCTIONS_EMPTY' }
$targets = @(Get-LabTargetsForSelector -Contract $lab.Contract -Selector ([pscustomobject]@{Platform=$Platform;Version=$Version;Patch=$Patch}))
if (-not $targets.Count) { throw 'NO_SELECTED_READY_LAB_TARGET' }

foreach ($target in $targets) {
    try { [void](Invoke-LabPreflight -Entry $target) } catch { throw 'LAB_READONLY_PREFLIGHT_FAILED' }
    $builder = [Data.SqlClient.SqlConnectionStringBuilder]::new((New-LabConnectionString -Entry $target))
    $builder['Initial Catalog'] = 'master'
    $builder['Pooling'] = $false
    $master = [Data.SqlClient.SqlConnection]::new($builder.ConnectionString)
    $database = $null; $consumer = $null; $ownedDatabaseCreated = $false; $completed = $false
    $callerDatabase = $null; $callerConnection = $null; $ownedCallerCreated = $false
    $ledger = $null; $journalPath = $null; $trustCleanup = 'not applicable'
    try {
        $master.Open()
        [void](Invoke-CaptureSql $master 'SELECT @@VERSION;' -Scalar)
        $ready = Invoke-CaptureSql $master @'
SELECT CASE WHEN EXISTS(SELECT 1 FROM sys.configurations WHERE name=N'clr enabled' AND value_in_use=1)
 AND EXISTS(SELECT 1 FROM sys.configurations WHERE name=N'clr strict security' AND value_in_use=1)
 THEN 1 ELSE 0 END;
'@ -Scalar
        if ([int]$ready -ne 1) { throw 'CLR_CONFIGURATION_REQUIRES_SEPARATE_COORDINATION' }
        # Kein RECONFIGURE und keine Rechtevergabe. Administrative Testfreigabe
        # nur bei ausdrücklichem Aufruf mit OptInExactTrust, niemals im Deployment.
        $hashes = @($manifest.sqlServerHexLiteral)
        if ($previous) { $hashes += ('0x' + $previous.sha512) }
        if ($OptInExactTrust) {
            if ([int](Invoke-CaptureSql $master "SELECT IS_SRVROLEMEMBER(N'sysadmin');" -Scalar) -ne 1) {
                throw 'EXISTING_ADMINISTRATIVE_PERMISSION_REQUIRED'
            }
            $journalFullPath = [IO.Path]::GetFullPath($PrivateJournalDirectory)
            $existingParent = $journalFullPath
            while (-not (Test-Path -LiteralPath $existingParent -PathType Container)) {
                $nextParent = Split-Path -Parent $existingParent
                if (-not $nextParent -or $nextParent -eq $existingParent) { throw 'PRIVATE_JOURNAL_LOCATION_INVALID' }
                $existingParent = $nextParent
            }
            $gitRoot = & git -C $existingParent rev-parse --show-toplevel 2>$null
            if ($LASTEXITCODE -eq 0 -and $gitRoot) { throw 'PRIVATE_JOURNAL_MUST_BE_OUTSIDE_GIT' }
            New-Item -ItemType Directory -Path $PrivateJournalDirectory -Force | Out-Null
            $runId = [Guid]::NewGuid().ToString('N')
            $journalPath = Join-Path $PrivateJournalDirectory ($runId + '.json')
            $entries = @($hashes | ForEach-Object {
                $priorExists = [int](Invoke-CaptureSql $master ('SELECT COUNT(*) FROM sys.trusted_assemblies WHERE hash=' + $_ + ';') -Scalar) -ne 0
                [pscustomobject]@{Hash=$_;PriorExists=$priorExists;AddedByWave=$false;Description=('Toolbelt capture test ' + $runId);State='PLANNED'}
            })
            $targetHasher = [Security.Cryptography.SHA256]::Create()
            try { $targetFingerprint = [BitConverter]::ToString($targetHasher.ComputeHash([Text.Encoding]::UTF8.GetBytes([string]$target.key))).Replace('-','') }
            finally { $targetHasher.Dispose() }
            $ledger = [pscustomobject]@{SchemaVersion='1.0';Wave='regex-captures-1.3.0';RunId=$runId;Platform=$Platform;Version=$Version;RequestedPatch=$Patch;ActualPatch=[string]$target.patch;TargetKeyFingerprint=$targetFingerprint;State='ACTIVE';Entries=$entries;OwnedDatabases=@()}
            Save-TrustLedger $ledger $journalPath
            foreach ($entry in $entries) {
                if (-not $entry.PriorExists) {
                    $entry.State='ADDING'
                    Save-TrustLedger $ledger $journalPath
                    $command = $master.CreateCommand()
                    $command.CommandText = 'DECLARE @BinaryHash varbinary(64)=CONVERT(varbinary(64),@Hash,1); EXEC sys.sp_add_trusted_assembly @hash=@BinaryHash,@description=@Description;'
                    [void]$command.Parameters.Add('@Hash',[Data.SqlDbType]::VarChar,130)
                    [void]$command.Parameters.Add('@Description',[Data.SqlDbType]::NVarChar,4000)
                    $command.Parameters['@Hash'].Value=$entry.Hash; $command.Parameters['@Description'].Value=$entry.Description
                    try {
                        [void]$command.ExecuteNonQuery()
                        if ((Get-TrustedDescription $master $entry.Hash) -cne $entry.Description) { throw 'TRUST_OWNERSHIP_NOT_CONFIRMED' }
                        $entry.AddedByWave=$true; $entry.State='ADDED'
                    } catch {
                        $entry.State='ADD_OUTCOME_UNCERTAIN'
                        Set-TrustLedgerBlocked $ledger $journalPath
                        throw 'TRUST_REGISTRATION_OUTCOME_REQUIRES_COORDINATION'
                    } finally { $command.Dispose() }
                } else { $entry.State='PREEXISTING_PRESERVED' }
                Save-TrustLedger $ledger $journalPath
            }
        }
        foreach ($hash in $hashes) {
            if ([int](Invoke-CaptureSql $master ('SELECT COUNT(*) FROM sys.trusted_assemblies WHERE hash=' + $hash + ';') -Scalar) -ne 1) { throw 'EXACT_TRUST_REQUIRES_SEPARATE_COORDINATION' }
        }
        $database = 'ToolbeltCaptureContract_' + [Guid]::NewGuid().ToString('N')
        if ($ledger) {
            $ledger.OwnedDatabases += [pscustomobject]@{Name=$database;Created=$false;Dropped=$false;State='CREATE_IN_PROGRESS'}
            Save-TrustLedger $ledger $journalPath
        }
        Invoke-CaptureSql $master ('CREATE DATABASE [' + $database + '] COLLATE Latin1_General_100_CS_AS;')
        $ownedDatabaseCreated = $true
        if ($ledger) { $ledger.OwnedDatabases[-1].Created=$true; $ledger.OwnedDatabases[-1].State='CREATED'; Save-TrustLedger $ledger $journalPath }
        $builder['Initial Catalog']=$database
        $consumer=[Data.SqlClient.SqlConnection]::new($builder.ConnectionString); $consumer.Open()
        $modes=if($ApiQualificationOnly){@($ApiDeploymentMode)}else{@('local','central')}
        foreach ($mode in $modes) {
            $variables=@{DeploymentMode=$mode;ConfirmNoExternalConsumers='1';ToolbeltDatabase=$database;ExpectedInstalledAssemblyHash='0x'}
            $deploy=Read-CaptureScript (Join-Path $ReleaseDirectory 'Deploy.WithAssembly.sql') $variables
            $uninstall=Read-CaptureScript (Join-Path $moduleRoot 'Deployment/Uninstall.sql') $variables
            Invoke-CaptureSql $consumer 'CREATE SCHEMA toolbelt_string AUTHORIZATION dbo;'
            Invoke-CaptureSql $consumer 'CREATE TABLE toolbelt_string.ContosoForeignSentinel(Id int PRIMARY KEY); INSERT toolbelt_string.ContosoForeignSentinel VALUES(1);'
            $foreignState=Get-CaptureSnapshot $consumer
            Assert-CaptureRejected $consumer $deploy 52033
            if ((Get-CaptureSnapshot $consumer) -cne $foreignState) { throw 'FOREIGN_SCHEMA_PREFLIGHT_MUTATED_SCOPE' }
            Invoke-CaptureSql $consumer 'DROP TABLE toolbelt_string.ContosoForeignSentinel; DROP SCHEMA toolbelt_string;'
            Invoke-CaptureBatches $consumer $deploy -Stage 'FRESH_DEPLOY'
            $variables.ExpectedInstalledAssemblyHash=$manifest.sqlServerHexLiteral
            $deploy=Read-CaptureScript (Join-Path $ReleaseDirectory 'Deploy.WithAssembly.sql') $variables
            $uninstall=Read-CaptureScript (Join-Path $moduleRoot 'Deployment/Uninstall.sql') $variables
            if ($ApiQualificationOnly) {
                # Begrenzter separater Nachweis ohne Wiederdeployment/Upgrade/
                # Uninstall. Gesamt-Lifecycle bleibt ausdrücklich unqualifiziert.
                $hashProof=Invoke-CaptureSql $consumer ('SELECT CASE WHEN HASHBYTES(N''SHA2_512'',f.content)=' + $manifest.sqlServerHexLiteral + ' THEN 1 ELSE 0 END FROM sys.assembly_files f JOIN sys.assemblies a ON a.assembly_id=f.assembly_id WHERE a.name=N''Toolbelt_String_Regex'' AND f.file_id=1;') -Scalar
                if ([int]$hashProof -ne 1) { throw 'INSTALLED_BINARY_FINGERPRINT_MISMATCH' }
                $levels=switch($Version){'2019'{@(150)}'2022'{@(150,160)}'2025'{@(150,160,170)}}
                foreach($level in $levels){
                    Invoke-CaptureSql $master ('ALTER DATABASE ['+$database+'] SET COMPATIBILITY_LEVEL='+$level+';')
                    foreach($name in @('Regex.Contract.sql','Transformations.Contract.sql','Relations.Contract.sql','Captures.Contract.sql')){
                        Invoke-CaptureBatches $consumer (Read-CaptureScript (Join-Path $moduleRoot ('Tests/Runtime/'+$name)) $variables)
                    }
                    & (Join-Path $moduleRoot 'Tests/Runtime/Captures.Metadata.ps1') -Connection $consumer -ToolbeltDatabase $database
                    if(-not $?){throw 'CAPTURE_METADATA_GATE_FAILED'}
                }
                if($mode -eq 'central'){
                    $callerDatabase='ToolbeltCaptureCaller_'+[Guid]::NewGuid().ToString('N')
                    if($ledger){$ledger.OwnedDatabases += [pscustomobject]@{Name=$callerDatabase;Created=$false;Dropped=$false;State='CREATE_IN_PROGRESS'};Save-TrustLedger $ledger $journalPath}
                    Invoke-CaptureSql $master ('CREATE DATABASE ['+$callerDatabase+'] COLLATE Latin1_General_100_BIN2;');$ownedCallerCreated=$true
                    if($ledger){$ledger.OwnedDatabases[-1].Created=$true;$ledger.OwnedDatabases[-1].State='CREATED';Save-TrustLedger $ledger $journalPath}
                    $builder['Initial Catalog']=$callerDatabase
                    $callerConnection=[Data.SqlClient.SqlConnection]::new($builder.ConnectionString);$callerConnection.Open()
                    Invoke-CaptureBatches $callerConnection (Read-CaptureScript (Join-Path $moduleRoot 'Tests/Runtime/Captures.Central.sql') $variables)
                    & (Join-Path $moduleRoot 'Tests/Runtime/Captures.Metadata.ps1') -Connection $callerConnection -ToolbeltDatabase $database
                    if(-not $?){throw 'CAPTURE_CENTRAL_METADATA_GATE_FAILED'}
                    $callerConnection.Dispose();$callerConnection=$null
                }
                continue
            }
            Invoke-CaptureBatches $consumer (Read-CaptureScript (Join-Path $moduleRoot 'Tests/Runtime/Lifecycle.Contract.sql') $variables) -Stage 'FRESH_LIFECYCLE'
            Invoke-CaptureBatches $consumer $uninstall -Stage 'FRESH_UNINSTALL'
            if ($previous) {
                $old=$previousDeploy.Replace('$(DeploymentMode)',$mode)
                Invoke-CaptureBatches $consumer $old -Stage 'PREDECESSOR_DEPLOY'
                $variables.ExpectedInstalledAssemblyHash=$previous.sqlServerHexLiteral
                $deploy=Read-CaptureScript (Join-Path $ReleaseDirectory 'Deploy.WithAssembly.sql') $variables
                $uninstall=Read-CaptureScript (Join-Path $moduleRoot 'Deployment/Uninstall.sql') $variables
                if ([string](Invoke-CaptureSql $consumer "SELECT CONVERT(nvarchar(64),value) FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.string.regex.Version';" -Scalar) -cne '1.2.0') { throw 'TRUE_UPGRADE_PREDECESSOR_MISSING' }
                foreach ($slotCase in @('ForeignNewSlot','ImitatedNewSlot')) {
                    $script:CaptureStage='HISTORICAL_COLLISION'
                    Invoke-CaptureBatches $consumer (Read-CaptureScript (Join-Path $moduleRoot 'Tests/Runtime/Lifecycle.CollisionFixture.sql') @{FaultCase=$slotCase})
                    $collisionState=Get-CaptureSnapshot $consumer
                    Assert-CaptureRejected $consumer $deploy 52033
                    if ((Get-CaptureSnapshot $consumer) -cne $collisionState) { throw 'HISTORICAL_COLLISION_MUTATED_SCOPE' }
                    Invoke-CaptureBatches $consumer $uninstall
                    if ([int](Invoke-CaptureSql $consumer 'SELECT toolbelt_string.SVF_RegexReplaceGroups();' -Scalar) -ne 73) { throw 'HISTORICAL_UNINSTALL_REMOVED_FOREIGN_SLOT' }
                    Invoke-CaptureSql $consumer 'DROP FUNCTION toolbelt_string.SVF_RegexReplaceGroups; DROP SCHEMA toolbelt_string;'
                    Invoke-CaptureBatches $consumer $old -Stage 'PREDECESSOR_REINSTALL'
                }
            }
            else {
                $variables.ExpectedInstalledAssemblyHash='0x'
                $deploy=Read-CaptureScript (Join-Path $ReleaseDirectory 'Deploy.WithAssembly.sql') $variables
            }
            Invoke-CaptureBatches $consumer $deploy -Stage 'UPGRADE_OR_FRESH_DEPLOY'
            $variables.ExpectedInstalledAssemblyHash=$manifest.sqlServerHexLiteral
            $deploy=Read-CaptureScript (Join-Path $ReleaseDirectory 'Deploy.WithAssembly.sql') $variables
            $uninstall=Read-CaptureScript (Join-Path $moduleRoot 'Deployment/Uninstall.sql') $variables
            Invoke-CaptureBatches $consumer $deploy -Stage 'REPEAT_DEPLOY'
            # Falsche Erwartung darf weder bei Deploy noch bei Uninstall mutieren.
            $hashState=Get-CaptureSnapshot $consumer
            $script:CaptureStage='HASH_REJECTION'
            $wrongHash='0x'+('0'*128)
            if ($wrongHash -ceq $manifest.sqlServerHexLiteral) { $wrongHash='0x'+('F'*128) }
            $hashCases=@(
                @{Text='';Error=52046}, @{Text='0x';Error=52046},
                @{Text='0x00';Error=52046}, @{Text='0x'+('G'*128);Error=52046},
                @{Text=$manifest.sqlServerHexLiteral+' ';Error=52046},
                @{Text=$wrongHash;Error=52047})
            foreach($hashCase in $hashCases){
                $faultVariables=$variables.Clone()
                $faultVariables.ExpectedInstalledAssemblyHash=$hashCase.Text
                foreach($path in @((Join-Path $ReleaseDirectory 'Deploy.WithAssembly.sql'),(Join-Path $moduleRoot 'Deployment/Uninstall.sql'))){
                    Assert-CaptureRejected $consumer (Read-CaptureScript $path $faultVariables) $hashCase.Error
                    if((Get-CaptureSnapshot $consumer) -cne $hashState){throw 'HASH_REJECTION_MUTATED_SCOPE'}
                }
            }
            # Nur Testinjektion: nach AppLock eine andere Erwartung setzen;
            # der zweite Katalogdurchlauf muss vor jedem Drop erneut vergleichen.
            foreach($script in @($deploy,$uninstall)){
                $script:CaptureStage='HASH_LOCK_RECHECK'
                $hashAnchor='SET @Pass += 1;'
                if([regex]::Matches($script,[regex]::Escape($hashAnchor)).Count -ne 1){throw 'HASH_RECHECK_ANCHOR_NOT_UNIQUE'}
                $fault=$script.Replace($hashAnchor,"IF @Pass=1 SET @ExpectedInstalledAssemblyHash=$wrongHash;`n"+$hashAnchor)
                Assert-CaptureRejected $consumer $fault 52047
                if((Get-CaptureSnapshot $consumer) -cne $hashState){throw 'HASH_RECHECK_MUTATED_SCOPE'}
            }
            $levels = switch ($Version) { '2019' {@(150)} '2022' {@(150,160)} '2025' {@(150,160,170)} }
            foreach ($level in $levels) {
                Invoke-CaptureSql $master ('ALTER DATABASE [' + $database + '] SET COMPATIBILITY_LEVEL=' + $level + ';')
                foreach ($name in @('Regex.Contract.sql','Transformations.Contract.sql','Relations.Contract.sql','Captures.Contract.sql','Lifecycle.Contract.sql')) {
                    $contractStage='API_'+$name.Replace('.Contract.sql','').ToUpperInvariant()
                    Invoke-CaptureBatches $consumer (Read-CaptureScript (Join-Path $moduleRoot ('Tests/Runtime/' + $name)) $variables) -Stage $contractStage
                }
                & (Join-Path $moduleRoot 'Tests/Runtime/Captures.Metadata.ps1') -Connection $consumer -ToolbeltDatabase $database
                if (-not $?) { throw 'CAPTURE_METADATA_GATE_FAILED' }
            }
            $script:CaptureStage='CALLER_TRANSACTION'
            Assert-CallerTransaction $consumer $deploy $uninstall
            # Geöffnete Connections verbergen Credentials; der private Builder bleibt die Quelle.
            $holder=[Data.SqlClient.SqlConnection]::new($builder.ConnectionString)
            $script:CaptureStage='LOCK_CONTENTION'
            try {
                $holder.Open()
                $lockResult=Invoke-CaptureSql $holder "BEGIN TRAN; DECLARE @Result int; EXEC @Result=sys.sp_getapplock @Resource=N'toolbelt.deploy.toolbelt.string.regex',@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=0,@DbPrincipal=N'public'; SELECT @Result;" -Scalar
                if ([int]$lockResult -lt 0) { throw 'LOCK_FIXTURE_NOT_ACQUIRED' }
                $before=Get-CaptureSnapshot $consumer
                foreach ($script in @($deploy,$uninstall)) {
                    Assert-CaptureRejected $consumer $script 52035
                    if ((Get-CaptureSnapshot $consumer) -cne $before) { throw 'LOCK_REJECTION_MUTATED_SCOPE' }
                }
            } finally { if ($holder.State -eq 'Open') { Invoke-CaptureSql $holder 'IF @@TRANCOUNT>0 ROLLBACK;' }; $holder.Dispose() }
            # Kontrollierter Fehler nach dem ersten Drop prüft Transaktionsrollback.
            foreach ($script in @($deploy,$uninstall)) {
                $script:CaptureStage='POST_DROP_ROLLBACK'
                $anchor='IF @Release >= 10 DROP FUNCTION [toolbelt_string].[SVF_RegexCount];'
                if ([regex]::Matches($script,[regex]::Escape($anchor)).Count -ne 1) { throw 'ROLLBACK_INJECTION_ANCHOR_NOT_UNIQUE' }
                $before=Get-CaptureSnapshot $consumer
                Assert-CaptureRejected $consumer ($script.Replace($anchor,$anchor+"`nTHROW 50000,N'Contoso rollback fault.',1;")) 50000
                if ((Get-CaptureSnapshot $consumer) -cne $before -or [int](Invoke-CaptureSql $consumer 'SELECT CASE WHEN @@TRANCOUNT=0 AND XACT_STATE()=0 THEN 1 ELSE 0 END;' -Scalar) -ne 1) { throw 'LIFECYCLE_ROLLBACK_MISMATCH' }
            }
            # Marker-/Versionsfehler müssen den vollständigen Katalog erhalten.
            foreach ($case in @('UnknownVersion','MissingVersion','ForeignFunctionMarker','ForeignProviderMarker','InconsistentFunctionVersion')) {
                $script:CaptureStage='MARKER_COLLISION'
                $before=Get-CaptureSnapshot $consumer
                Invoke-CaptureBatches $consumer (Read-CaptureScript (Join-Path $moduleRoot 'Tests/Runtime/Lifecycle.CollisionFixture.sql') @{FaultCase=$case})
                $fault=Get-CaptureSnapshot $consumer
                $expected=if($case -eq 'UnknownVersion'){52032}else{52033}
                foreach ($script in @($deploy,$uninstall)) { Assert-CaptureRejected $consumer $script $expected; if ((Get-CaptureSnapshot $consumer) -cne $fault) { throw 'COLLISION_PREFLIGHT_MUTATED_METADATA' } }
                $restore=switch($case) {
                    UnknownVersion { "EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.Module.toolbelt.string.regex.Version',@value=N'1.3.0';" }
                    MissingVersion { "EXEC sys.sp_addextendedproperty @name=N'Toolbelt.Module.toolbelt.string.regex.Version',@value=N'1.3.0';" }
                    ForeignProviderMarker { "EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.ModuleId',@value=N'toolbelt.string.regex',@level0type=N'ASSEMBLY',@level0name=N'Toolbelt_String_Regex';" }
                    ForeignFunctionMarker { "EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.ModuleId',@value=N'toolbelt.string.regex',@level0type=N'SCHEMA',@level0name=N'toolbelt_string',@level1type=N'FUNCTION',@level1name=N'TVF_RegexCaptures';" }
                    InconsistentFunctionVersion { "EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.ModuleVersion',@value=N'1.3.0',@level0type=N'SCHEMA',@level0name=N'toolbelt_string',@level1type=N'FUNCTION',@level1name=N'TVF_RegexCaptures';" }
                }
                Invoke-CaptureSql $consumer $restore
                if ((Get-CaptureSnapshot $consumer) -cne $before) { throw 'COLLISION_FIXTURE_RESTORE_MISMATCH' }
            }
            Invoke-CaptureBatches $consumer (Read-CaptureScript (Join-Path $moduleRoot 'Tests/Runtime/Lifecycle.CollisionFixture.sql') @{FaultCase='Dependency'})
            $script:CaptureStage='DEPENDENCY_REJECTION'
            $dependencyState=Get-CaptureSnapshot $consumer
            Assert-CaptureRejected $consumer $uninstall 52038
            if ((Get-CaptureSnapshot $consumer) -cne $dependencyState) { throw 'DEPENDENCY_PREFLIGHT_MUTATED_METADATA' }
            Invoke-CaptureSql $consumer 'DROP VIEW dbo.ToolbeltRegexFixtureDependency;'
            if ($mode -eq 'central') {
                $callerDatabase='ToolbeltCaptureCaller_' + [Guid]::NewGuid().ToString('N')
                if ($ledger) { $ledger.OwnedDatabases += [pscustomobject]@{Name=$callerDatabase;Created=$false;Dropped=$false;State='CREATE_IN_PROGRESS'}; Save-TrustLedger $ledger $journalPath }
                Invoke-CaptureSql $master ('CREATE DATABASE ['+$callerDatabase+'] COLLATE Latin1_General_100_BIN2;'); $ownedCallerCreated=$true
                if ($ledger) { $ledger.OwnedDatabases[-1].Created=$true; $ledger.OwnedDatabases[-1].State='CREATED'; Save-TrustLedger $ledger $journalPath }
                $builder['Initial Catalog']=$callerDatabase
                $callerConnection=[Data.SqlClient.SqlConnection]::new($builder.ConnectionString); $callerConnection.Open()
                Invoke-CaptureBatches $callerConnection (Read-CaptureScript (Join-Path $moduleRoot 'Tests/Runtime/Captures.Central.sql') $variables)
                & (Join-Path $moduleRoot 'Tests/Runtime/Captures.Metadata.ps1') -Connection $callerConnection -ToolbeltDatabase $database
                if (-not $?) { throw 'CAPTURE_CENTRAL_METADATA_GATE_FAILED' }
                $callerConnection.Dispose(); $callerConnection=$null
            }
            Invoke-CaptureBatches $consumer $uninstall -Stage 'FINAL_UNINSTALL'
        }
        if (-not $ApiQualificationOnly -and [int](Invoke-CaptureSql $consumer "SELECT COUNT(*) FROM sys.objects WHERE schema_id=SCHEMA_ID(N'toolbelt_string') AND type IN(N'FT',N'FS',N'FN',N'IF');" -Scalar) -ne 0) { throw 'UNINSTALL_OWNED_OBJECTS_REMAIN' }
        $completed=$true
    } catch {
        # SQL-Fehlertext kann private Endpoints oder Runtime-Daten enthalten.
        if ($ledger) {
            foreach ($entry in $ledger.OwnedDatabases) {
                if ($entry.State -eq 'CREATE_IN_PROGRESS') { $entry.State='CREATE_OUTCOME_UNCERTAIN' }
            }
            Set-TrustLedgerBlocked $ledger $journalPath
        }
        $failure = $_.Exception
        while ($failure) {
            if ($failure -is [Data.SqlClient.SqlException]) {
                throw ('CAPTURE_SQL_FAILED_' + $failure.Number + '_STAGE_' + $script:CaptureStage + '_BATCH_' + $script:CaptureBatch + '_LINE_' + $failure.LineNumber)
            }
            if ($failure.Message -cmatch '^[A-Z][A-Z0-9_]+$') { throw $failure.Message }
            if (-not $failure.InnerException) { break }
            $failure = $failure.InnerException
        }
        throw ('CAPTURE_LAB_FAILED_' + $failure.GetType().Name + '_LINE_' + $_.InvocationInfo.ScriptLineNumber)
    } finally {
        if ($callerConnection) { $callerConnection.Dispose() }
        if ($consumer) { $consumer.Dispose() }
        if (($ownedDatabaseCreated -or $ownedCallerCreated) -and $master.State -ne 'Open') {
            Set-TrustLedgerBlocked $ledger $journalPath
            $master.Dispose(); throw 'OWNED_DATABASE_CLEANUP_REQUIRES_COORDINATION'
        }
        if ($ownedCallerCreated) {
            try {
                Invoke-CaptureSql $master ('DROP DATABASE [' + $callerDatabase + '];')
                if ($ledger) {
                    foreach ($entry in $ledger.OwnedDatabases) { if ($entry.Name -ceq $callerDatabase) { $entry.Dropped=$true; $entry.State='DROPPED' } }
                    Save-TrustLedger $ledger $journalPath
                }
            }
            catch { Set-TrustLedgerBlocked $ledger $journalPath; $master.Dispose(); throw 'OWNED_DATABASE_CLEANUP_REQUIRES_COORDINATION' }
        }
        if ($ownedDatabaseCreated) {
            try {
                Invoke-CaptureSql $master ('DROP DATABASE [' + $database + '];')
                if ($ledger) {
                    foreach ($entry in $ledger.OwnedDatabases) { if ($entry.Name -ceq $database) { $entry.Dropped=$true; $entry.State='DROPPED' } }
                    Save-TrustLedger $ledger $journalPath
                }
            }
            catch { Set-TrustLedgerBlocked $ledger $journalPath; $master.Dispose(); throw 'OWNED_DATABASE_CLEANUP_REQUIRES_COORDINATION' }
        }
        if ($ledger) {
            $trustCleanup = if (@($ledger.OwnedDatabases | Where-Object {$_.State -in @('CREATE_IN_PROGRESS','CREATE_OUTCOME_UNCERTAIN')}).Count) {'BLOCKED'} else {'PASS'}
            foreach ($entry in $ledger.Entries) {
                if ($entry.State -in @('ADDING','ADD_OUTCOME_UNCERTAIN')) { $trustCleanup='BLOCKED'; continue }
                if (-not $entry.AddedByWave) { continue }
                try {
                    if ($master.State -ne 'Open' -or
                        (Get-TrustedDescription $master $entry.Hash) -cne $entry.Description -or
                        -not (Assert-NoAssemblyConsumer $master $entry.Hash)) {
                        throw 'TRUST_CONSUMER_OR_OWNERSHIP_UNCONFIRMED'
                    } else {
                        Invoke-CaptureSql $master ('EXEC sys.sp_drop_trusted_assembly @hash=' + $entry.Hash + ';')
                        if ($null -ne (Get-TrustedDescription $master $entry.Hash)) { throw 'TRUST_RESTORE_NOT_VERIFIED' }
                        $entry.State='RESTORED'
                    }
                } catch { $entry.State='RESTORE_BLOCKED_UNCONFIRMED_SCOPE'; $trustCleanup='BLOCKED' }
                Save-TrustLedger $ledger $journalPath
            }
            $ledger.State = if ($trustCleanup -eq 'PASS') {'COMPLETE'} else {'RESTORE_BLOCKED'}
            Save-TrustLedger $ledger $journalPath
        }
        $master.Dispose(); $builder = $null
    }
    if ($completed) {
        if ($trustCleanup -eq 'BLOCKED') { throw 'EXACT_TRUST_RESTORE_REQUIRES_COORDINATION' }
        [pscustomobject]@{Status='PASS';Scope=$(if($ApiQualificationOnly){'Capture/Replace API only'}else{'selected local/central Capture/Replace contract'});Platform=$Platform;Version=$Version;DatabaseCleanup='PASS';TrustCleanup=$trustCleanup;Upgrade=$(if($previous -and -not $ApiQualificationOnly){'PASS'}else{'not executed'});Lifecycle=$(if($ApiQualificationOnly){'not executed'}else{'PASS'});Central=$(if($mode -eq 'central'){'PASS'}else{'not executed'});MinimalRights='not executed'}
    }
}
