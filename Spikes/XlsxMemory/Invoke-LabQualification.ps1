[CmdletBinding()]
param([ValidateSet('linux','windows')][string]$Platform = 'linux',
    [ValidateSet('2019','2022','2025')][string]$Version = '2019',
    [string]$Patch = 'latest',
    [switch]$AuthorizeClrEnable,
    [switch]$AuthorizePendingMinimumMemory)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
# Kanonische Discovery-/Selektor-/Connection-Funktionen übernehmen, ohne den
# Fullrunner zu initialisieren oder ein Providerfallback zu erfinden.
$errors = $null; $tokens = $null
$ast = [Management.Automation.Language.Parser]::ParseFile((Join-Path $root 'Tests/CI/run-lab-local.ps1'),[ref]$tokens,[ref]$errors)
if ($errors.Count) { throw 'Kanonischer Labrunner hat Syntaxfehler.' }
foreach ($name in @('Get-EnvironmentVariableValue','Resolve-LabContract','Test-LabTargetReady','Get-LabTargetsForSelector','New-LabConnectionString')) {
    $function = $ast.FindAll({param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $name},$true)
    if ($function.Count -ne 1) { throw 'Kanonische Labfunktion nicht eindeutig.' }
    . ([scriptblock]::Create($function[0].Extent.Text))
}
$lab = Resolve-LabContract
$promptPath = Get-EnvironmentVariableValue 'SQL_SERVER_LAB_TEST_ENV_PROMPT_FILE'
if ($promptPath) {
    # Der zusätzliche Vertrag wird vor Verbindung vollständig gelesen. Keine
    # Credentials oder private Infrastrukturwerte gelangen in Artefakte.
    $prompt = Get-Content -LiteralPath $promptPath -Raw
    if ([string]::IsNullOrWhiteSpace($prompt)) { throw 'Lab-Zusatzprompt ist leer.' }
}
$targets = @(Get-LabTargetsForSelector $lab.Contract ([pscustomobject]@{Platform=$Platform;Version=$Version;Patch=$Patch}))
if (-not $targets.Count) { throw 'Kein exakt geeignetes READY-Qualifizierungsziel.' }
$framework = Join-Path $env:WINDIR 'System32/WindowsPowerShell/v1.0/powershell.exe'
$base64 = & $framework -NoProfile -File (Join-Path $PSScriptRoot 'Test-Framework.ps1') -FixtureOnly
if ($LASTEXITCODE -or @($base64).Count -ne 1) { throw 'Synthetischer Fixturegenerator fehlgeschlagen.' }
$fixture = [Convert]::FromBase64String($base64)
$binaries = @(
    @{Name='Toolbelt_Archive_ZipMemory';Path=(Join-Path $PSScriptRoot 'bin/Release/Toolbelt.Archive.ZipMemory.dll')},
    @{Name='Toolbelt_File_XlsxMemory';Path=(Join-Path $PSScriptRoot 'bin/Release/Toolbelt.File.XlsxMemory.dll')},
    @{Name='Toolbelt_Xlsx_Qualification';Path=(Join-Path $PSScriptRoot 'bin/Release/Toolbelt.Xlsx.Qualification.dll')}
)
foreach ($target in $targets) {
    $database = 'Toolbelt_XlsxProbe_' + [Guid]::NewGuid().ToString('N')
    $created = $false; $added = [Collections.Generic.List[byte[]]]::new(); $phase = 'login'
    $connection = [Data.SqlClient.SqlConnection]::new((New-LabConnectionString $target))
    function Execute([string]$sql) {
        $command = $connection.CreateCommand(); $command.CommandTimeout = 30; $command.CommandText = $sql
        try { return $command.ExecuteScalar() } finally { $command.Dispose() }
    }
    try {
        $connection.Open()
        $phase = 'preflight'
        [void](Execute 'SELECT @@VERSION;')
        $preflight = $connection.CreateCommand(); $preflight.CommandText = 'SELECT name,state_desc FROM sys.databases ORDER BY database_id;'; $preflight.CommandTimeout = 30
        try { $reader=$preflight.ExecuteReader(); try { while($reader.Read()){[void]$reader.GetString(0);[void]$reader.GetString(1)} } finally {$reader.Dispose()} } finally {$preflight.Dispose()}
        $enabled = Execute "SELECT value_in_use FROM sys.configurations WHERE name = 'clr enabled';"
        $strict = Execute "SELECT value_in_use FROM sys.configurations WHERE name = 'clr strict security';"
        $major = Execute "SELECT CONVERT(int,SERVERPROPERTY('ProductMajorVersion'));"
        if ($strict -ne 1) { $phase='preflight-strict-security'; throw 'Strict security prerequisite missing.' }
        $expectedMajor = @{ '2019'=15; '2022'=16; '2025'=17 }[$Version]
        if ($major -ne $expectedMajor) { $phase='preflight-version'; throw 'Version prerequisite missing.' }
        if ($enabled -ne 1 -and $AuthorizeClrEnable) {
            $phase = 'authorized-clr-enable'
            # Explizite Benutzerfreigabe vom 2026-10-01, eng koordinierter Selector.
            # RECONFIGURE darf keine andere ausstehende Änderung aktivieren.
            if ($Platform -cne 'linux' -or $Version -cne '2019' -or $Patch -cne 'latest') { throw 'Configuration authorization selector mismatch.' }
            $phase='authorized-clr-existing-permission'
            if ((Execute "SELECT HAS_PERMS_BY_NAME(NULL,NULL,N'ALTER SETTINGS');") -ne 1) { throw 'Existing ALTER SETTINGS permission missing.' }
            $phase='authorized-clr-pooling'
            if ((Execute "SELECT value_in_use FROM sys.configurations WHERE name=N'lightweight pooling';") -ne 0) { throw 'Lightweight pooling blocks CLR.' }
            $phase='authorized-clr-pending-config'
            $allowedPending = if ($AuthorizePendingMinimumMemory) { "N'clr enabled',N'min server memory (MB)'" } else { "N'clr enabled'" }
            if ((Execute "SELECT COUNT(*) FROM sys.configurations WHERE value<>value_in_use AND name NOT IN($allowedPending);") -ne 0) { throw 'Unrelated pending configuration blocks RECONFIGURE.' }
            $configured = Execute "SELECT value FROM sys.configurations WHERE name=N'clr enabled';"
            $memoryConfigured = Execute "SELECT value FROM sys.configurations WHERE name=N'min server memory (MB)';"
            $memoryInUse = Execute "SELECT value_in_use FROM sys.configurations WHERE name=N'min server memory (MB)';"
            $journalDirectory = Join-Path ([IO.Path]::GetTempPath()) 'ToolbeltConfigurationJournal'
            [void](New-Item -ItemType Directory -Path $journalDirectory -Force)
            $journal = Join-Path $journalDirectory ('xlsx-clr-' + [Guid]::NewGuid().ToString('N') + '.json')
            $phase='authorized-clr-journal'
            $journalData = [ordered]@{schemaVersion=1;selector='linux/2019/latest';parameters=@(
                @{name='clr enabled';beforeValue=[int]$configured;beforeValueInUse=[int]$enabled;requestedValue=1},
                @{name='min server memory (MB)';beforeValue=[int]$memoryConfigured;beforeValueInUse=[int]$memoryInUse;pendingActivationAuthorized=[bool]$AuthorizePendingMinimumMemory}
            );state='PREPARED';createdUtc=[DateTime]::UtcNow.ToString('o')}
            $journalData |
                ConvertTo-Json | Set-Content -LiteralPath $journal -Encoding utf8
            $phase='authorized-clr-mutation'
            $configurationCommand=$connection.CreateCommand(); $configurationCommand.CommandTimeout=30
            $configurationCommand.CommandText="EXEC sys.sp_configure N'clr enabled',1; RECONFIGURE;"
            try { [void]$configurationCommand.ExecuteNonQuery() } finally { $configurationCommand.Dispose() }
            $phase='authorized-clr-verification'
            $enabled = Execute "SELECT value_in_use FROM sys.configurations WHERE name=N'clr enabled';"
            if ($enabled -ne 1 -or (Execute "SELECT value_in_use FROM sys.configurations WHERE name=N'clr strict security';") -ne 1) { throw 'Authorized CLR configuration verification failed.' }
            $phase='authorized-memory-verification'
            # Configured and effective min-memory values need not become equal.
            # Preserve actual postconditions without inventing an allocation promise.
            $memoryAfterConfigured=Execute "SELECT value FROM sys.configurations WHERE name=N'min server memory (MB)';"
            $memoryAfterInUse=Execute "SELECT value_in_use FROM sys.configurations WHERE name=N'min server memory (MB)';"
            if ($memoryAfterConfigured -ne $memoryConfigured) { throw 'Authorized setting configured value changed unexpectedly.' }
            $journalData.parameters[0]['afterValue']=1; $journalData.parameters[0]['afterValueInUse']=[int]$enabled
            $journalData.parameters[1]['afterValue']=[int]$memoryAfterConfigured
            $journalData.parameters[1]['afterValueInUse']=[int]$memoryAfterInUse
            $journalData['state']='APPLIED_VERIFIED'; $journalData | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $journal -Encoding utf8
            'PASS: authorized CLR preparation verified; strict security unchanged; actual configured/effective memory postconditions journaled. Restoration coordinated after all waves.'
        }
        if ($enabled -ne 1) { $phase='preflight-clr-disabled'; throw 'CLR prerequisite missing.' }
        [void](Execute "CREATE DATABASE [$database];"); $created = $true
        $connection.ChangeDatabase($database)
        $phase = 'assemblies'
        foreach ($binary in $binaries) {
            $bytes = [IO.File]::ReadAllBytes($binary.Path)
            $sha = [Security.Cryptography.SHA512]::Create(); try { $hash = $sha.ComputeHash($bytes) } finally { $sha.Dispose() }
            $hexHash = '0x' + [BitConverter]::ToString($hash).Replace('-','')
            if ((Execute "SELECT COUNT(*) FROM sys.trusted_assemblies WHERE hash=$hexHash;") -eq 0) {
                [void](Execute "EXEC sys.sp_add_trusted_assembly @hash=$hexHash,@description=N'Toolbelt synthetic XLSX qualification';")
                $added.Add($hash)
            }
            $hex = '0x' + [BitConverter]::ToString($bytes).Replace('-','')
            [void](Execute "CREATE ASSEMBLY [$($binary.Name)] FROM $hex WITH PERMISSION_SET=SAFE;")
        }
        [void](Execute "CREATE SCHEMA toolbelt_spike;")
        $phase = 'binding'
        [void](Execute "CREATE FUNCTION toolbelt_spike.SVF_QualificationXlsxProbe(@Binary varbinary(max), @SheetOrdinal int) RETURNS nvarchar(max) AS EXTERNAL NAME [Toolbelt_Xlsx_Qualification].[Toolbelt.Xlsx.Qualification.QualificationEntryPoints].[Probe];")
        $command = $connection.CreateCommand(); $command.CommandTimeout = 30
        $phase = 'probe'
        try {
            $command.CommandText = "USE [$database]; SELECT toolbelt_spike.SVF_QualificationXlsxProbe(@Binary,1);"
            [void]$command.Parameters.Add('@Binary',[Data.SqlDbType]::VarBinary,-1); $command.Parameters['@Binary'].Value=$fixture
            $result = $command.ExecuteScalar()
            if ($result -cne ('1|9|tail ' + [char]0x00e4 + [char]0xd83d + [char]0xde00)) { $phase='probe-text-oracle'; throw 'SAFE-Workbook-Oracle fehlgeschlagen.' }
            $command.Parameters['@Binary'].Value=[DBNull]::Value
            if ($command.ExecuteScalar() -isnot [DBNull]) { $phase='probe-null-oracle'; throw 'NULL-Input-Oracle fehlgeschlagen.' }
        } finally { $command.Dispose() }
        $phase='probe-safe-catalog'
        $permissions = Execute "USE [$database]; SELECT COUNT(*) FROM sys.assemblies WHERE name IN(N'Toolbelt_Archive_ZipMemory',N'Toolbelt_File_XlsxMemory',N'Toolbelt_Xlsx_Qualification') AND permission_set=1;"
        if ($permissions -ne 3) { throw 'SAFE-Katalogvertrag fehlt.' }
        "PASS: XLSX internal SAFE qualification SQL $Version/$Platform/$Patch; synthetic worksheet/cells/Unicode/NULL; strict security unchanged. Not public API validation."
    } catch {
        # Kein Roh-SQL-/Verbindungsfehler oder privater Endpoint in dauerhafter Evidence.
        $failureType = $_.Exception.GetType().Name
        $number = 0; $errorCause = $_.Exception
        while ($errorCause) { if ($errorCause -is [Data.SqlClient.SqlException]) { $number=$errorCause.Number }; $errorCause=$errorCause.InnerException }
        throw "XLSX SAFE qualification failed ($failureType, phase=$phase, SQL=$number); inspect only ephemeral diagnostics."
    } finally {
        if ($connection.State -eq [Data.ConnectionState]::Open) {
            if ($created) { [void](Execute "USE master; ALTER DATABASE [$database] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [$database];") }
            foreach ($hash in $added) {
                $hexHash = '0x' + [BitConverter]::ToString($hash).Replace('-','')
                [void](Execute "USE master; EXEC sys.sp_drop_trusted_assembly @hash=$hexHash;")
            }
        }
        $connection.Dispose()
    }
}
