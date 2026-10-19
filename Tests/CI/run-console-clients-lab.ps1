[CmdletBinding()]
param(
    [string[]]$Versions = @('2019', '2022', '2025'),
    [ValidateSet('linux', 'windows')][string[]]$Platforms = @('linux', 'windows')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$module = Join-Path $repo 'Modules/toolbelt.core.console-message'
$parseErrors = $null
$tree = [Management.Automation.Language.Parser]::ParseFile(
    (Join-Path $PSScriptRoot 'run-lab-local.ps1'), [ref]$null, [ref]$parseErrors)
if ($parseErrors.Count) { throw 'CONSOLE_LAB_DISCOVERY_PARSE' }
foreach ($name in @('Get-EnvironmentVariableValue', 'Resolve-LabContract',
                    'Test-LabTargetReady', 'Get-LabTargetsForSelector',
                    'Get-LabTargetsForSelectors', 'New-LabConnectionString',
                    'Invoke-LabPreflight')) {
    $nodes = @($tree.FindAll({param($node)
        $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
        $node.Name -ceq $name
    }, $false))
    if ($nodes.Count -ne 1) { throw 'CONSOLE_LAB_DISCOVERY' }
    . ([scriptblock]::Create($nodes[0].Extent.Text))
}

function Read-ConsoleSql([string]$Path) {
    $full = [IO.Path]::GetFullPath($Path)
    if (-not $full.StartsWith($module + [IO.Path]::DirectorySeparatorChar,
                             [StringComparison]::OrdinalIgnoreCase)) {
        throw 'CONSOLE_LAB_SOURCE_SCOPE'
    }
    $sql = Get-Content -LiteralPath $full -Raw
    $sql = [regex]::Replace($sql, '(?im)^:r\s+([^\r\n]+)\r?$', {
        param($match)
        Read-ConsoleSql (Join-Path (Split-Path -Parent $full) $match.Groups[1].Value.Trim())
    })
    $sql = [regex]::Replace($sql, '(?im)^:on error exit\s*$', '')
    $sql = $sql.Replace('$(DeploymentMode)', 'local').Replace('$(ConfirmNoExternalConsumers)', '0')
    if ($sql -match '(?m)^:' -or $sql -match '\$\(') { throw 'CONSOLE_LAB_SQLCMD_UNRESOLVED' }
    return $sql
}

function Invoke-ConsoleSql([Data.SqlClient.SqlConnection]$Connection, [string]$Sql,
                           [switch]$Scalar) {
    $command = $Connection.CreateCommand()
    $command.CommandText = $Sql
    $command.CommandTimeout = 60
    try {
        if ($Scalar) { return $command.ExecuteScalar() }
        [void]$command.ExecuteNonQuery()
    } finally { $command.Dispose() }
}

function Invoke-ConsoleSource([Data.SqlClient.SqlConnection]$Connection, [string]$Path) {
    foreach ($batch in ([regex]::Split((Read-ConsoleSql $Path), '(?im)^\s*GO\s*\r?$'))) {
        if (-not [string]::IsNullOrWhiteSpace($batch)) { Invoke-ConsoleSql $Connection $batch }
    }
}

$lab = Resolve-LabContract
$selectors = @(foreach ($platform in $Platforms) {
    foreach ($version in ($Versions | ForEach-Object { $_ -split ',' })) {
        if ($version -notin @('2019', '2022', '2025')) { throw 'CONSOLE_LAB_VERSION' }
        [pscustomobject]@{Platform=$platform; Version=$version;
            Patch=$(if ($platform -ceq 'windows') { 'base' } else { 'latest' })}
    }
})
$targets = @(Get-LabTargetsForSelectors -Contract $lab.Contract -Selectors $selectors)
foreach ($target in $targets) {
    $master = $null
    $worker = $null
    $created = $false
    $database = 'TBX_ConsoleClient_' + [guid]::NewGuid().ToString('N')
    try {
        $null = Invoke-LabPreflight -Entry $target -TestPurpose Functional
        $builder = [Data.SqlClient.SqlConnectionStringBuilder]::new(
            (New-LabConnectionString -Entry $target -TestPurpose Functional))
        $builder['Initial Catalog'] = 'master'
        $builder['Pooling'] = $false
        $master = [Data.SqlClient.SqlConnection]::new($builder.ConnectionString)
        $master.Open()
        Invoke-ConsoleSql $master "CREATE DATABASE [$database] COLLATE Latin1_General_100_CS_AS;"
        $created = $true
        $builder['Initial Catalog'] = $database
        $worker = [Data.SqlClient.SqlConnection]::new($builder.ConnectionString)
        $worker.Open()
        Invoke-ConsoleSource $worker (Join-Path $module 'Deployment/Deploy.sql')
        $observation = & (Join-Path $module 'Tests/Runtime/ConsoleClient.Contract.ps1') -Connection $worker
        Invoke-ConsoleSource $worker (Join-Path $module 'Deployment/Uninstall.sql')
        if ([int](Invoke-ConsoleSql $worker "SELECT COUNT(*) FROM sys.objects WHERE object_id=OBJECT_ID(N'toolbelt_core.USP_WriteConsoleMessage');" -Scalar) -ne 0) {
            throw 'CONSOLE_LAB_UNINSTALL_UNVERIFIED'
        }
    } catch {
        $failure = $_.Exception
        while ($failure.InnerException) { $failure = $failure.InnerException }
        if ($failure -is [Data.SqlClient.SqlException]) {
            throw ('CONSOLE_LAB_SQL_FAILED_' + $failure.Number + '_LINE_' + $failure.LineNumber)
        }
        if ($failure.Message -cmatch '^CONSOLE_[A-Z0-9_]+$') { throw $failure.Message }
        throw 'CONSOLE_LAB_FAILED_PRIVATE_DETAILS_SUPPRESSED'
    } finally {
        if ($worker) { $worker.Dispose() }
        if ($created) {
            Invoke-ConsoleSql $master "ALTER DATABASE [$database] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [$database];"
            if ([int](Invoke-ConsoleSql $master "SELECT COUNT(*) FROM sys.databases WHERE name=N'$database';" -Scalar) -ne 0) {
                throw 'CONSOLE_LAB_CLEANUP_UNVERIFIED'
            }
        }
        if ($master) { $master.Dispose() }
    }
    Write-Output ('CONSOLE_CLIENT_PASS_CLEANED {0} SQL{1} {2} {3}' -f
        $target.platform, $target.sqlVersion, $target.patch, $observation)
}
