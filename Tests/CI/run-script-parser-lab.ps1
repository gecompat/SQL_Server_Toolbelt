[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('2019','2025')][string]$Version,
    [string]$Patch = 'base',
    [Parameter(Mandatory)][string]$ReleaseDirectory,
    [string]$PreviousReleaseDirectory,
    [switch]$OptInExactTrust,
    [string]$PrivateJournalDirectory = (Join-Path ([IO.Path]::GetTempPath()) 'ToolbeltParserTrustJournals')
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$moduleRoot = Join-Path $repoRoot 'Modules/toolbelt.tsql.script-parser'

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

function Invoke-ParserSql {
    param([Data.SqlClient.SqlConnection]$Connection,[string]$Text,[switch]$Scalar)
    $command = $Connection.CreateCommand()
    $command.CommandTimeout = 90
    $command.CommandText = $Text
    try {
        if ($Scalar) { return $command.ExecuteScalar() }
        [void]$command.ExecuteNonQuery()
    } finally { $command.Dispose() }
}

function Read-ParserScript {
    param([string]$Path,[hashtable]$Variables)
    $text = Get-Content -LiteralPath $Path -Raw
    foreach ($key in $Variables.Keys) { $text = $text.Replace('$(' + $key + ')', [string]$Variables[$key]) }
    if ($text -match '\$\(' -or $text -match '(?m)^:r\s+') { throw 'UNRESOLVED_SQLCMD_INPUT' }
    $text = [regex]::Replace($text, '(?im)^:On Error exit\s*$', '')
    if ($text -match '(?m)^:') { throw 'UNSUPPORTED_SQLCMD_DIRECTIVE' }
    return $text
}

function Invoke-ParserBatches {
    param([Data.SqlClient.SqlConnection]$Connection,[string]$Text)
    # Erster SQL-Fehler stoppt alle folgenden Batches wie :On Error exit.
    foreach ($batch in [regex]::Split($Text, '(?im)^\s*GO\s*(?:--[^\r\n]*)?\r?$')) {
        if (-not [string]::IsNullOrWhiteSpace($batch)) { Invoke-ParserSql $Connection $batch }
    }
}

function Get-ParserSnapshot {
    param([Data.SqlClient.SqlConnection]$Connection)
    $command = $Connection.CreateCommand()
    $command.CommandText = Get-Content -LiteralPath (Join-Path $moduleRoot 'Tests/Runtime/Lifecycle.Snapshot.sql') -Raw
    $command.CommandTimeout = 90
    try {
        $reader = $command.ExecuteReader()
        try {
            if (-not $reader.Read()) { throw 'SNAPSHOT_MISSING' }
            $values = @(for ($i=0; $i -lt $reader.FieldCount; $i++) {
                if ($reader.IsDBNull($i)) { $null } else { $reader.GetString($i) }
            })
            return ($values | ConvertTo-Json -Compress)
        } finally { $reader.Dispose() }
    } finally { $command.Dispose() }
}

function Assert-ParserRejected {
    param([Data.SqlClient.SqlConnection]$Connection,[string]$Text,[int]$Expected)
    $caught = $false
    try { Invoke-ParserBatches $Connection $Text }
    catch {
        $failure = $_.Exception
        while ($failure.InnerException) { $failure = $failure.InnerException }
        if ($failure -isnot [Data.SqlClient.SqlException] -or $failure.Number -ne $Expected) {
            throw 'EXPECTED_LIFECYCLE_ERROR_MISMATCH'
        }
        $caught = $true
    }
    if (-not $caught) { throw 'EXPECTED_LIFECYCLE_REJECTION_MISSING' }
}

function Assert-CallerTransaction {
    param([Data.SqlClient.SqlConnection]$Connection,[string]$Deploy,[string]$Uninstall)
    $metadata = Get-ParserSnapshot $Connection
    foreach ($xact in @('OFF','ON')) {
        foreach ($nocount in @('OFF','ON')) {
            Invoke-ParserSql $Connection ("SET XACT_ABORT $xact; SET NOCOUNT $nocount; CREATE TABLE #CallerWork(Value int); BEGIN TRAN; INSERT #CallerWork VALUES(1);")
            try {
                $options = Invoke-ParserSql $Connection 'SELECT @@OPTIONS;' -Scalar
                foreach ($script in @($Deploy,$Uninstall)) {
                    Assert-ParserRejected $Connection $script 50000
                    $preserved = Invoke-ParserSql $Connection ("SELECT CASE WHEN @@TRANCOUNT=1 AND XACT_STATE()=1 AND @@OPTIONS=$options AND (SELECT COUNT(*) FROM #CallerWork)=1 THEN 1 ELSE 0 END;") -Scalar
                    if ([int]$preserved -ne 1 -or (Get-ParserSnapshot $Connection) -cne $metadata) {
                        throw 'CALLER_TRANSACTION_OR_OPTIONS_CHANGED'
                    }
                }
            } finally {
                Invoke-ParserSql $Connection 'IF @@TRANCOUNT>0 ROLLBACK; DROP TABLE #CallerWork;'
            }
        }
    }
}

function Assert-CollisionPreflight {
    param([Data.SqlClient.SqlConnection]$Connection,[string]$Deploy,[string]$Uninstall)
    foreach ($fault in @('UnknownVersion','MissingVersion','ForeignFunctionMarker','ForeignProviderMarker','InconsistentFunctionVersion')) {
        $baseline = Get-ParserSnapshot $Connection
        $fixture = Read-ParserScript (Join-Path $moduleRoot 'Tests/Runtime/Lifecycle.CollisionFixture.sql') @{FaultCase=$fault}
        Invoke-ParserBatches $Connection $fixture
        $faultState = Get-ParserSnapshot $Connection
        $expected = if ($fault -eq 'UnknownVersion') { 53119 } else { 53118 }
        foreach ($script in @($Deploy,$Uninstall)) {
            Assert-ParserRejected $Connection $script $expected
            if ((Get-ParserSnapshot $Connection) -cne $faultState) { throw 'COLLISION_PREFLIGHT_MUTATED_METADATA' }
        }
        $restore = switch ($fault) {
            UnknownVersion { "EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.Module.toolbelt.tsql.script-parser.Version',@value=N'2.0.0';" }
            MissingVersion { "EXEC sys.sp_addextendedproperty @name=N'Toolbelt.Module.toolbelt.tsql.script-parser.Version',@value=N'2.0.0';" }
            ForeignProviderMarker { "EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.ModuleId',@value=N'toolbelt.tsql.script-parser',@level0type=N'ASSEMBLY',@level0name=N'Toolbelt_Tsql_ScriptParser';" }
            ForeignFunctionMarker { "EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.ModuleId',@value=N'toolbelt.tsql.script-parser',@level0type=N'SCHEMA',@level0name=N'toolbelt_tsql',@level1type=N'FUNCTION',@level1name=N'TVF_ParseScriptNodes';" }
            InconsistentFunctionVersion { "EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.ModuleVersion',@value=N'2.0.0',@level0type=N'SCHEMA',@level0name=N'toolbelt_tsql',@level1type=N'FUNCTION',@level1name=N'TVF_ParseScriptNodes';" }
        }
        Invoke-ParserSql $Connection $restore
        if ((Get-ParserSnapshot $Connection) -cne $baseline) { throw 'COLLISION_FIXTURE_RESTORE_MISMATCH' }
    }
    Invoke-ParserBatches $Connection (Read-ParserScript (Join-Path $moduleRoot 'Tests/Runtime/Lifecycle.CollisionFixture.sql') @{FaultCase='ForeignConsumer'})
    $faultState = Get-ParserSnapshot $Connection
    Assert-ParserRejected $Connection $Uninstall 53108
    if ((Get-ParserSnapshot $Connection) -cne $faultState) { throw 'DEPENDENCY_PREFLIGHT_MUTATED_METADATA' }
    Invoke-ParserSql $Connection 'DROP VIEW dbo.ContosoParserConsumer;'
}

function Assert-LifecycleRollback {
    param([Data.SqlClient.SqlConnection]$Connection,[string]$Deploy,[string]$Uninstall)
    $anchor = 'DROP FUNCTION IF EXISTS [toolbelt_tsql].[TVF_ParseScriptErrors];'
    foreach ($script in @($Deploy,$Uninstall)) {
        if ([regex]::Matches($script,[regex]::Escape($anchor)).Count -ne 1) { throw 'ROLLBACK_INJECTION_ANCHOR_NOT_UNIQUE' }
        $before = Get-ParserSnapshot $Connection
        $fault = $script.Replace($anchor, $anchor + "`nTHROW 50000,N'Contoso rollback fault.',1;")
        Assert-ParserRejected $Connection $fault 50000
        if ((Get-ParserSnapshot $Connection) -cne $before -or
            [int](Invoke-ParserSql $Connection 'SELECT CASE WHEN @@TRANCOUNT=0 AND XACT_STATE()=0 THEN 1 ELSE 0 END;' -Scalar) -ne 1) {
            throw 'LIFECYCLE_ROLLBACK_MISMATCH'
        }
    }
}

function Assert-LifecycleLock {
    param([Data.SqlClient.SqlConnection]$Connection,[string]$ConnectionString,[string]$Deploy,[string]$Uninstall)
    $holder = [Data.SqlClient.SqlConnection]::new($ConnectionString)
    try {
        $holder.Open()
        $result = Invoke-ParserSql $holder @'
BEGIN TRAN;
DECLARE @Result int;
EXEC @Result=sys.sp_getapplock @Resource=N'toolbelt.deploy.toolbelt.tsql.script-parser',
 @LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=0,@DbPrincipal=N'public';
SELECT @Result;
'@ -Scalar
        if ([int]$result -lt 0) { throw 'LOCK_FIXTURE_NOT_ACQUIRED' }
        $before = Get-ParserSnapshot $Connection
        foreach ($script in @($Deploy,$Uninstall)) {
            Assert-ParserRejected $Connection $script 53104
            if ((Get-ParserSnapshot $Connection) -cne $before -or
                [int](Invoke-ParserSql $Connection 'SELECT CASE WHEN @@TRANCOUNT=0 AND XACT_STATE()=0 THEN 1 ELSE 0 END;' -Scalar) -ne 1) {
                throw 'LOCK_REJECTION_MUTATED_SCOPE'
            }
        }
    } finally {
        try { if ($holder.State -eq 'Open') { Invoke-ParserSql $holder 'IF @@TRANCOUNT>0 ROLLBACK;' } }
        finally { $holder.Dispose() }
    }
}

function Assert-ForeignFixture {
    param([Data.SqlClient.SqlConnection]$Connection,[string]$Deploy,[string]$Uninstall,[string]$DependencyPath)
    Invoke-ParserSql $Connection 'CREATE SCHEMA toolbelt_tsql AUTHORIZATION dbo;'
    Invoke-ParserSql $Connection 'CREATE TABLE toolbelt_tsql.ContosoForeignSentinel(Id int PRIMARY KEY); INSERT toolbelt_tsql.ContosoForeignSentinel VALUES(1);'
    $hex = '0x' + [BitConverter]::ToString([IO.File]::ReadAllBytes($DependencyPath)).Replace('-','')
    Invoke-ParserSql $Connection ('CREATE ASSEMBLY [Microsoft.SqlServer.TransactSql.ScriptDom] FROM ' + $hex + ' WITH PERMISSION_SET=UNSAFE;')
    $before = Get-ParserSnapshot $Connection
    Invoke-ParserBatches $Connection $Deploy
    $unadopted = Invoke-ParserSql $Connection @'
SELECT CASE WHEN NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE
 (class=3 AND major_id=SCHEMA_ID(N'toolbelt_tsql') AND name LIKE N'Toolbelt.%')
 OR (class=5 AND major_id=(SELECT assembly_id FROM sys.assemblies WHERE name=N'Microsoft.SqlServer.TransactSql.ScriptDom') AND name LIKE N'Toolbelt.%'))
 THEN 1 ELSE 0 END;
'@ -Scalar
    if ([int]$unadopted -ne 1) { throw 'FOREIGN_FIXTURE_ADOPTED' }
    Invoke-ParserBatches $Connection $Uninstall
    if ((Get-ParserSnapshot $Connection) -cne $before -or
        [int](Invoke-ParserSql $Connection 'SELECT COUNT(*) FROM toolbelt_tsql.ContosoForeignSentinel WHERE Id=1;' -Scalar) -ne 1) {
        throw 'FOREIGN_FIXTURE_NOT_PRESERVED'
    }
    # Diese Fixtures wurden vom aktuellen Runner in seiner eigenen Datenbank
    # erzeugt; erst nach dem Erhaltungsnachweis ausdrücklich entfernen.
    Invoke-ParserSql $Connection 'DROP TABLE toolbelt_tsql.ContosoForeignSentinel; DROP SCHEMA toolbelt_tsql; DROP ASSEMBLY [Microsoft.SqlServer.TransactSql.ScriptDom];'
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
            $count = Invoke-ParserSql $Connection (
                'SELECT COUNT(*) FROM [' + $safeName + '].sys.assembly_files WHERE file_id=1 AND HASHBYTES(N''SHA2_512'',content)=' + $Hash + ';') -Scalar
            if ([int]$count -ne 0) { return $false }
        } catch { return $false }
    }
    return $true
}

$manifestPath = Join-Path $ReleaseDirectory 'Toolbelt.Tsql.ScriptParser.trust-manifest.json'
$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
if ($manifest.moduleVersion -cne '2.0.0' -or $manifest.permissionSet -cne 'UNSAFE') { throw 'RELEASE_IDENTITY_INVALID' }
foreach ($name in @('sqlServerHexLiteral','scriptDomSqlServerHexLiteral')) {
    if ([string]$manifest.$name -cnotmatch '^0x[0-9A-F]{128}$') { throw 'RELEASE_HASH_FORMAT_INVALID' }
}
if ($manifest.sqlServerHexLiteral -cne ('0x' + $manifest.sha512) -or
    $manifest.scriptDomSqlServerHexLiteral -cne ('0x' + $manifest.scriptDomSha512) -or
    $manifest.scriptDomSha512 -cne '459E137268A4CA378023CD7E68A04655CEC2C19A8D01546E81B1A7ABF1FE2F9226A03CC3FA2323081C3C1B05626AF988C98527711D577919CF409367F853DAC7') {
    throw 'RELEASE_TRUST_FINGERPRINT_MISMATCH'
}
$providerPath = Join-Path $ReleaseDirectory 'Toolbelt.Tsql.ScriptParser.dll'
$dependencyPath = Join-Path $ReleaseDirectory 'Microsoft.SqlServer.TransactSql.ScriptDom.dll'
if ((Get-FileHash -LiteralPath $providerPath -Algorithm SHA512).Hash -cne $manifest.sha512 -or
    (Get-FileHash -LiteralPath $dependencyPath -Algorithm SHA512).Hash -cne $manifest.scriptDomSha512) {
    throw 'RELEASE_BINARY_FINGERPRINT_MISMATCH'
}
# Integrierte Framework-Qualifikation wird vor jeder SQL-Verbindung ausgeführt.
# Der endgültige Gate-Aufruf wird mit dessen geprüfter Schnittstelle gekoppelt.
$frameworkGate = Join-Path $moduleRoot 'Tests/Framework/Invoke-Contract.ps1'
if (-not (Test-Path -LiteralPath $frameworkGate -PathType Leaf)) { throw 'INTEGRATED_FRAMEWORK_GATE_UNAVAILABLE' }
try {
    & $frameworkGate -ScriptDomDllPath $dependencyPath -ProviderAssemblyPath $providerPath -TrustManifestPath $manifestPath 2>$null
    if (-not $?) { throw 'INTEGRATED_FRAMEWORK_GATE_FAILED' }
} catch { throw 'INTEGRATED_FRAMEWORK_GATE_FAILED' }

# SQL-Artefakt gegen die aktuellen Templates/Source und dieselben Binaries prüfen.
$expectedDeploy = Get-Content -LiteralPath (Join-Path $moduleRoot 'Deployment/Deploy.sql') -Raw
foreach ($item in @(@('AssemblyBits',$providerPath),@('ScriptDomAssemblyBits',$dependencyPath))) {
    $bits = '0x' + [BitConverter]::ToString([IO.File]::ReadAllBytes($item[1])).Replace('-', '')
    $expectedDeploy = $expectedDeploy.Replace('$(' + $item[0] + ')', $bits)
}
foreach ($name in @('TVF_ParseScriptNodes.sql','TVF_ParseScriptNodeProperties.sql','TVF_TokenizeScript.sql','TVF_ParseScriptErrors.sql')) {
    $expectedDeploy = $expectedDeploy.Replace(':r ../Source/' + $name,
        (Get-Content -LiteralPath (Join-Path $moduleRoot ('Source/' + $name)) -Raw).TrimEnd())
}
$actualDeploy = Get-Content -LiteralPath (Join-Path $ReleaseDirectory 'Deploy.WithAssembly.sql') -Raw
if ($actualDeploy.Replace("`r`n","`n").TrimEnd() -cne $expectedDeploy.Replace("`r`n","`n").TrimEnd()) {
    throw 'RELEASE_DEPLOYMENT_SOURCE_MISMATCH'
}

try { $lab = Resolve-LabContract } catch { throw 'LAB_CONTRACT_INVALID_OR_UNAVAILABLE' }
$promptPath = Get-EnvironmentVariableValue 'SQL_SERVER_LAB_TEST_ENV_PROMPT_FILE'
if ($promptPath -and [string]::IsNullOrWhiteSpace((Get-Content -LiteralPath $promptPath -Raw))) {
    throw 'LAB_SUPPLEMENTAL_INSTRUCTIONS_EMPTY'
}
$targets = @(Get-LabTargetsForSelector -Contract $lab.Contract -Selector (
    [pscustomobject]@{Platform='windows';Version=$Version;Patch=$Patch}))
if (-not $targets.Count) { throw 'NO_SELECTED_READY_LAB_TARGET' }

$previous = $null
if ($PreviousReleaseDirectory) {
    $previous = Get-Content -LiteralPath (Join-Path $PreviousReleaseDirectory 'original-manifest.json') -Raw | ConvertFrom-Json
    $previousScriptDomPath = Join-Path $PreviousReleaseDirectory 'Microsoft.SqlServer.TransactSql.ScriptDom.dll'
    # Exakte ursprüngliche 1.0.0-Source, kein als Upgrade ausgegebener Markerwechsel.
    if ($previous.moduleVersion -cne '1.0.0' -or $previous.moduleId -cne 'toolbelt.tsql.script-parser' -or
        $previous.originalCommit -cne 'e281c01b93f000a8500b52eb13e67bce19b580e6' -or
        $previous.providerSourceSha256 -cne '0AB452CC2214C93EFCD67A4404E84D8DAA1A31327A9395219923CA456EC9EC0C' -or
        [string]$previous.sha512 -cnotmatch '^[0-9A-F]{128}$' -or
        (Get-FileHash -LiteralPath (Join-Path $PreviousReleaseDirectory 'Toolbelt.Tsql.ScriptParser.dll') -Algorithm SHA512).Hash -cne $previous.sha512 -or
        (Get-FileHash -LiteralPath $previousScriptDomPath -Algorithm SHA512).Hash -cne '24BDEE1CC5296488C3609BB6911DD76935B510F823CAAE4D39E8C45C84D272F3D28E3F6156E1E185C0F81D5812C9100E9C71CBE788966AC477A5B213BCE672D0' -or
        [Reflection.AssemblyName]::GetAssemblyName($previousScriptDomPath).FullName -cne 'Microsoft.SqlServer.TransactSql.ScriptDom, Version=18.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91' -or
        [Diagnostics.FileVersionInfo]::GetVersionInfo($previousScriptDomPath).FileVersion -cne '18.0.56.2' -or
        (Get-FileHash -LiteralPath (Join-Path $PreviousReleaseDirectory 'Deploy.WithAssembly.sql') -Algorithm SHA256).Hash -cne $previous.generatedDeploySha256 -or
        [Reflection.AssemblyName]::GetAssemblyName((Join-Path $PreviousReleaseDirectory 'Toolbelt.Tsql.ScriptParser.dll')).Version.ToString() -cne '1.0.0.0') {
        throw 'PREVIOUS_RELEASE_FINGERPRINT_MISMATCH'
    }
}

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
        [void](Invoke-ParserSql $master 'SELECT @@VERSION;' -Scalar)
        $ready = Invoke-ParserSql $master @'
SELECT CASE WHEN EXISTS(SELECT 1 FROM sys.configurations WHERE name=N'clr enabled' AND value_in_use=1)
 AND EXISTS(SELECT 1 FROM sys.configurations WHERE name=N'clr strict security' AND value_in_use=1)
 THEN 1 ELSE 0 END;
'@ -Scalar
        if ([int]$ready -ne 1) { throw 'CLR_CONFIGURATION_REQUIRES_SEPARATE_COORDINATION' }
        # Kein RECONFIGURE und keine Rechtevergabe. Administrative Testfreigabe
        # nur bei ausdrücklichem Aufruf mit OptInExactTrust, niemals im Deployment.
        $hashes = @($manifest.sqlServerHexLiteral,$manifest.scriptDomSqlServerHexLiteral)
        if ($previous) { $hashes += ('0x' + $previous.sha512) }
        if ($OptInExactTrust) {
            if ([int](Invoke-ParserSql $master "SELECT IS_SRVROLEMEMBER(N'sysadmin');" -Scalar) -ne 1) {
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
                $priorExists = [int](Invoke-ParserSql $master ('SELECT COUNT(*) FROM sys.trusted_assemblies WHERE hash=' + $_ + ';') -Scalar) -ne 0
                [pscustomobject]@{Hash=$_;PriorExists=$priorExists;AddedByWave=$false;Description=('Toolbelt parser test ' + $runId);State='PLANNED'}
            })
            $targetHasher = [Security.Cryptography.SHA256]::Create()
            try { $targetFingerprint = [BitConverter]::ToString($targetHasher.ComputeHash([Text.Encoding]::UTF8.GetBytes([string]$target.key))).Replace('-','') }
            finally { $targetHasher.Dispose() }
            $ledger = [pscustomobject]@{SchemaVersion='1.0';Wave='parser-hardening-2.0.0';RunId=$runId;Platform='windows';Version=$Version;RequestedPatch=$Patch;ActualPatch=[string]$target.patch;TargetKeyFingerprint=$targetFingerprint;State='ACTIVE';Entries=$entries;OwnedDatabases=@()}
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
        $trusted = Invoke-ParserSql $master (
            "SELECT COUNT(*) FROM sys.trusted_assemblies WHERE hash IN (" +
            $manifest.sqlServerHexLiteral + ',' + $manifest.scriptDomSqlServerHexLiteral + ');') -Scalar
        if ([int]$trusted -ne 2) { throw 'EXACT_TRUST_REQUIRES_SEPARATE_COORDINATION' }
        $database = 'ToolbeltParserContract_' + [Guid]::NewGuid().ToString('N')
        if ($ledger) {
            $ledger.OwnedDatabases += [pscustomobject]@{Name=$database;Created=$false;Dropped=$false;State='CREATE_IN_PROGRESS'}
            Save-TrustLedger $ledger $journalPath
        }
        Invoke-ParserSql $master ('CREATE DATABASE [' + $database + '];')
        $ownedDatabaseCreated = $true
        if ($ledger) {
            $ledger.OwnedDatabases[-1].Created=$true; $ledger.OwnedDatabases[-1].State='CREATED'
            Save-TrustLedger $ledger $journalPath
        }
        $builder['Initial Catalog'] = $database
        $consumer = [Data.SqlClient.SqlConnection]::new($builder.ConnectionString)
        $consumer.Open()
        foreach ($mode in @('local','central')) {
            $variables = @{DeploymentMode=$mode;ConfirmNoExternalConsumers='1';ToolbeltDatabase=$database}
            $deploy = Read-ParserScript (Join-Path $ReleaseDirectory 'Deploy.WithAssembly.sql') $variables
            $uninstall = Read-ParserScript (Join-Path $moduleRoot 'Deployment/Uninstall.sql') $variables
            if ($previous) {
                # Saubere 2.0-Installation ist ein eigener Nachweis vor Upgrade.
                Invoke-ParserBatches $consumer $deploy
                Invoke-ParserBatches $consumer (Read-ParserScript (Join-Path $moduleRoot 'Tests/Runtime/Lifecycle.Contract.sql') $variables)
                Invoke-ParserBatches $consumer $uninstall
                Assert-ForeignFixture $consumer $deploy $uninstall $dependencyPath
                Invoke-ParserBatches $consumer (Read-ParserScript (Join-Path $PreviousReleaseDirectory 'Deploy.WithAssembly.sql') $variables)
                $oldVersion = Invoke-ParserSql $consumer "SELECT CONVERT(nvarchar(64),value) FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.tsql.script-parser.Version';" -Scalar
                if ([string]$oldVersion -cne '1.0.0') { throw 'TRUE_UPGRADE_PREDECESSOR_MISSING' }
            }
            Invoke-ParserBatches $consumer $deploy
            Invoke-ParserBatches $consumer $deploy
            $levels = if ($Version -eq '2019') {@(150)} else {@(150,160,170)}
            foreach ($level in $levels) {
                Invoke-ParserSql $master ('ALTER DATABASE [' + $database + '] SET COMPATIBILITY_LEVEL=' + $level + ';')
                foreach ($name in @('ScriptParser.Contract.sql','Bounds.Contract.sql','Syntax.Contract.sql','Lifecycle.Contract.sql')) {
                    Invoke-ParserBatches $consumer (Read-ParserScript (Join-Path $moduleRoot ('Tests/Runtime/' + $name)) $variables)
                }
            }
            Assert-CallerTransaction $consumer $deploy $uninstall
            Assert-CollisionPreflight $consumer $deploy $uninstall
            Assert-LifecycleRollback $consumer $deploy $uninstall
            Assert-LifecycleLock $consumer $builder.ConnectionString $deploy $uninstall
            if ($mode -eq 'central') {
                $callerDatabase = 'ToolbeltParserCaller_' + [Guid]::NewGuid().ToString('N')
                if ($ledger) {
                    $ledger.OwnedDatabases += [pscustomobject]@{Name=$callerDatabase;Created=$false;Dropped=$false;State='CREATE_IN_PROGRESS'}
                    Save-TrustLedger $ledger $journalPath
                }
                Invoke-ParserSql $master ('CREATE DATABASE [' + $callerDatabase + '];')
                $ownedCallerCreated = $true
                if ($ledger) {
                    $ledger.OwnedDatabases[-1].Created=$true; $ledger.OwnedDatabases[-1].State='CREATED'
                    Save-TrustLedger $ledger $journalPath
                }
                $builder['Initial Catalog'] = $callerDatabase
                $callerConnection = [Data.SqlClient.SqlConnection]::new($builder.ConnectionString)
                $callerConnection.Open()
                Invoke-ParserBatches $callerConnection (Read-ParserScript (Join-Path $moduleRoot 'Tests/Runtime/Central.Contract.sql') $variables)
                $callerConnection.Dispose(); $callerConnection = $null
            }
            Invoke-ParserBatches $consumer $uninstall
        }
        $remaining = Invoke-ParserSql $consumer "SELECT COUNT(*) FROM sys.objects WHERE schema_id=SCHEMA_ID(N'toolbelt_tsql') AND type=N'FT';" -Scalar
        if ([int]$remaining -ne 0) { throw 'UNINSTALL_OWNED_OBJECTS_REMAIN' }
        $completed = $true
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
            if ($failure -is [Data.SqlClient.SqlException]) { throw ('PARSER_SQL_FAILED_' + $failure.Number) }
            if ($failure.Message -cmatch '^[A-Z][A-Z0-9_]+$') { throw $failure.Message }
            if (-not $failure.InnerException) { break }
            $failure = $failure.InnerException
        }
        throw ('PARSER_LAB_FAILED_' + $failure.GetType().Name + '_LINE_' + $_.InvocationInfo.ScriptLineNumber)
    } finally {
        if ($callerConnection) { $callerConnection.Dispose() }
        if ($consumer) { $consumer.Dispose() }
        if (($ownedDatabaseCreated -or $ownedCallerCreated) -and $master.State -ne 'Open') {
            Set-TrustLedgerBlocked $ledger $journalPath
            $master.Dispose(); throw 'OWNED_DATABASE_CLEANUP_REQUIRES_COORDINATION'
        }
        if ($ownedCallerCreated) {
            try {
                Invoke-ParserSql $master ('DROP DATABASE [' + $callerDatabase + '];')
                if ($ledger) {
                    foreach ($entry in $ledger.OwnedDatabases) { if ($entry.Name -ceq $callerDatabase) { $entry.Dropped=$true; $entry.State='DROPPED' } }
                    Save-TrustLedger $ledger $journalPath
                }
            }
            catch { Set-TrustLedgerBlocked $ledger $journalPath; $master.Dispose(); throw 'OWNED_DATABASE_CLEANUP_REQUIRES_COORDINATION' }
        }
        if ($ownedDatabaseCreated) {
            try {
                Invoke-ParserSql $master ('DROP DATABASE [' + $database + '];')
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
                        Invoke-ParserSql $master ('EXEC sys.sp_drop_trusted_assembly @hash=' + $entry.Hash + ';')
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
        [pscustomobject]@{Status='PASS';Scope='selected Windows local/central parser contract';Version=$Version;DatabaseCleanup='PASS';TrustCleanup=$trustCleanup;Upgrade=$(if($previous){'PASS'}else{'not executed'});Central='PASS';MinimalRights='not executed'}
    }
}
