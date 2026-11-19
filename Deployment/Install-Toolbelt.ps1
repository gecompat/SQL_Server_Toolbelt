<#
.SYNOPSIS
Installiert den gebundenen rc.2-Satz mit Vorprüfung und exaktem Assembly-Trust.
.DESCRIPTION
PowerShell 7.4 oder neuer und sqlcmd (ODBC) sind erforderlich. Ohne Credential wird die
integrierte Anmeldung verwendet. CreateDatabase und EnableClr erlauben gezielt
Datenbankanlage und CLR-Aktivierung. Rechte werden nicht vergeben.
Der veröffentlichte rc.2-Satz bleibt unverändert; Details: ONE-CALL-INSTALL.md.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('local','central')][string]$DeploymentMode,
    [string]$ServerInstance,
    [string]$Database,
    [Management.Automation.PSCredential]$Credential,
    [string]$PackageZip,
    [string]$SqlcmdPath = 'sqlcmd',
    [switch]$TrustServerCertificate,
    [switch]$ValidateOnly,
    [switch]$PreflightOnly,
    [switch]$CreateDatabase,
    [switch]$EnableClr,
    [ValidateRange(1,120)][int]$LoginTimeoutSeconds = 60,
    [ValidateRange(1,1800)][int]$CommandTimeoutSeconds = 600
)

Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'Toolbelt.Provisioning.ps1')

function Stop-ToolbeltInstall([string]$Code, [string]$Message) {
    throw [InvalidOperationException]::new("[$Code] $Message")
}

function Get-ToolbeltModuleVersions {
    # Generierter Pin aus Modules/*/module.yaml des veröffentlichten Quellstands
    # 78fb85711bc0b4dd053ed9354399f1b34e52e875; kein Lesen heutiger Fremdquellen.
    # Die Gegenprobe vergleicht ihn mit dem unveränderten rc.2-Quellarchiv.
    return @{
        'toolbelt.archive.zip-files' = '1.0.0'
        'toolbelt.archive.zip-memory' = '1.4.0'
        'toolbelt.binary.bit-operations' = '1.0.0'
        'toolbelt.conversion.base64' = '1.1.0'
        'toolbelt.conversion.integer-base' = '1.1.0'
        'toolbelt.conversion.safe-cast' = '1.0.0'
        'toolbelt.conversion.uri-component' = '1.0.0'
        'toolbelt.core.console-message' = '1.0.0'
        'toolbelt.core.error-envelope' = '1.0.0'
        'toolbelt.core.event-log' = '1.0.0'
        'toolbelt.core.execution-cancel' = '1.0.0'
        'toolbelt.core.execution-context' = '1.0.0'
        'toolbelt.core.generate-series' = '1.0.0'
        'toolbelt.core.result-table' = '1.0.0'
        'toolbelt.core.second-session' = '1.1.0'
        'toolbelt.core.work-queue' = '2.1.0'
        'toolbelt.core.work-type' = '1.2.0'
        'toolbelt.core.worker-control' = '1.0.0'
        'toolbelt.datetime.bucket' = '1.0.0'
        'toolbelt.datetime.calendar-difference' = '1.0.0'
        'toolbelt.datetime.date-spine' = '1.0.0'
        'toolbelt.datetime.truncate' = '1.0.0'
        'toolbelt.file.content' = '1.0.0'
        'toolbelt.file.csv-memory' = '1.0.0'
        'toolbelt.file.xlsx-memory' = '1.2.0'
        'toolbelt.filesystem.windows' = '1.0.0'
        'toolbelt.json.constructors' = '1.3.0'
        'toolbelt.json.core' = '1.0.0'
        'toolbelt.json.path-exists' = '1.0.0'
        'toolbelt.json.pointer' = '1.0.0'
        'toolbelt.json.schema' = '1.0.1'
        'toolbelt.metadata.capability-catalog' = '1.0.0'
        'toolbelt.metadata.identifier' = '1.0.0'
        'toolbelt.metadata.table-clone' = '4.1.1'
        'toolbelt.pseudonymization.deterministic' = '1.2.0'
        'toolbelt.string.directional-trim' = '1.0.0'
        'toolbelt.string.edit-distance' = '1.1.0'
        'toolbelt.string.phonetic' = '1.0.0'
        'toolbelt.string.regex' = '1.3.0'
        'toolbelt.string.split-advanced' = '1.1.0'
        'toolbelt.string.split-characters' = '1.0.0'
        'toolbelt.string.text-pairs' = '1.0.0'
        'toolbelt.tsql.script-parser' = '2.0.1'
        'toolbelt.tsql.ssis-debug' = '1.0.0'
        'toolbelt.validation.semantic-version' = '1.1.0'
    }
}

function Get-ToolbeltPayload([string]$ArchivePath) {
    # Der äußere Hash bindet auch das Manifest. Ein selbst neu gehashtes,
    # manipuliertes Paket kann deshalb keine anderen Skripte autorisieren.
    $item = Get-Item -LiteralPath $ArchivePath -Force -ErrorAction Stop
    if ($item.PSIsContainer -or $item.Length -ne 7204625 -or
        ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
        Stop-ToolbeltInstall 'PACKAGE' 'Erwartet wird die unveränderte Installer-ZIP aus v1.0.0-rc.2.'
    }
    $bytes = [IO.File]::ReadAllBytes($item.FullName)
    if ([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes)) -ine
        '78a8a737395ee42d34d264191756d8c5d06bae5b82b368c04c35afd9f67183fb') {
        Stop-ToolbeltInstall 'PACKAGE' 'Die Paketprüfsumme stimmt nicht mit dem veröffentlichten rc.2-Installer überein.'
    }
    $stream = [IO.MemoryStream]::new($bytes, $false)
    $zip = [IO.Compression.ZipArchive]::new($stream, [IO.Compression.ZipArchiveMode]::Read)
    try {
        $payload = [Collections.Generic.Dictionary[string,byte[]]]::new([StringComparer]::OrdinalIgnoreCase)
        [long]$total = 0
        if ($zip.Entries.Count -gt 64) { Stop-ToolbeltInstall 'PACKAGE' 'Zu viele Paketdateien.' }
        foreach ($entry in $zip.Entries) {
            $name = $entry.FullName
            $total += $entry.Length
            if ($total -gt 67108864 -or $name -match '(^/|\\|:|(^|/)\.\.?(/|$)|/$)' -or $payload.ContainsKey($name)) {
                Stop-ToolbeltInstall 'PACKAGE' 'Ungültiger Dateipfad, doppelter Eintrag oder überschrittenes Paketbudget.'
            }
            $inputStream = $entry.Open(); $outputStream = [IO.MemoryStream]::new()
            try { $inputStream.CopyTo($outputStream); $payload.Add($name, $outputStream.ToArray()) }
            finally { $inputStream.Dispose(); $outputStream.Dispose() }
        }
        $metadata = [Text.Encoding]::UTF8.GetString($payload['PACKAGE.json']) | ConvertFrom-Json -AsHashtable
        if ($metadata.scope -cne 'CURRENT_COMBINED_FRESH_INSTALL' -or $payload.Count -ne $metadata.files.Count + 2) {
            Stop-ToolbeltInstall 'PACKAGE' 'Unbekannter Paketvertrag.'
        }
        foreach ($name in $metadata.files.Keys) {
            if (-not $payload.ContainsKey($name) -or
                [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($payload[$name])) -ine $metadata.files[$name]) {
                Stop-ToolbeltInstall 'PACKAGE' 'Eine Paketdatei stimmt nicht mit dem gebundenen Manifest überein.'
            }
        }
        return @{ Files = $payload; Metadata = $metadata }
    } finally { $zip.Dispose(); $stream.Dispose() }
}

function Invoke-ToolbeltNativeProcess([Diagnostics.ProcessStartInfo]$StartInfo, [int]$TimeoutSeconds) {
    $process = [Diagnostics.Process]::new(); $process.StartInfo = $StartInfo
    $started = $false
    try {
        $started = $process.Start()
        $stdout = $process.StandardOutput.ReadToEndAsync()
        $stderr = $process.StandardError.ReadToEndAsync()
        if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
            $process.Kill($true); $process.WaitForExit()
            Stop-ToolbeltInstall 'TIMEOUT' 'Zeitgrenze erreicht. Keine Wiederholung. Bereits installierte Module und Trusteinträge können bestehen bleiben.'
        }
        return @{ ExitCode = $process.ExitCode; Stdout = $stdout.GetAwaiter().GetResult(); Stderr = $stderr.GetAwaiter().GetResult() }
    } catch [ComponentModel.Win32Exception] {
        Stop-ToolbeltInstall 'CLIENT_START' 'Der ausgewählte Clientprozess konnte nicht gestartet werden. Installation und Ausführungsrechte des Clients prüfen.'
    } finally {
        if ($started -and -not $process.HasExited) { $process.Kill($true); $process.WaitForExit() }
        $process.Dispose()
    }
}

function Invoke-ToolbeltSql([string]$Executable, [string]$Server, [string]$Catalog, [string]$File,
    [Management.Automation.PSCredential]$SqlCredential, [bool]$CertificateOverride,
    [int]$LoginTimeout, [int]$CommandTimeout) {
    $start = [Diagnostics.ProcessStartInfo]::new($Executable)
    $start.UseShellExecute = $false; $start.CreateNoWindow = $true
    $start.RedirectStandardOutput = $true; $start.RedirectStandardError = $true
    # Keine implizite Anmeldung aus der Elternumgebung, keine SQLCMD-Variablen,
    # kein Shellaufruf und kein Zertifikatsfallback. SQL-Fehler stoppen den Client.
    foreach ($name in @('SQLCMDPASSWORD','SQLCMDUSER','SQLCMDSERVER','SQLCMDDBNAME','SQLCMDINI','SQLCMDLOGINTIMEOUT','SQLCMDSTATTIMEOUT')) {
        [void]$start.Environment.Remove($name)
    }
    $arguments = @('-S',$Server,'-d',$Catalog,'-N','-b','-V','11','-x','-f','65001','-h','-1','-w','512',
        '-l',[string]$LoginTimeout,'-t',[string]$CommandTimeout,'-i',$File)
    if ($SqlCredential) {
        $arguments += @('-U',$SqlCredential.UserName)
        $start.Environment['SQLCMDPASSWORD'] = $SqlCredential.GetNetworkCredential().Password
    } else { $arguments += @('-E','-X1') }
    # -X1 unterdrückt auch SQLCMDPASSWORD und würde eine interaktive Abfrage
    # erzwingen. Bei SQL-Anmeldung sichern stattdessen das geleerte SQLCMDINI,
    # -x und ausschließlich hashgebundene, eigene Eingabedateien den Aufruf.
    if ($CertificateOverride) { $arguments += '-C' }
    foreach ($argument in $arguments) { $start.ArgumentList.Add($argument) }
    try {
        $result = Invoke-ToolbeltNativeProcess $start ($LoginTimeout + $CommandTimeout + 10)
        if ($SqlCredential -and $result.ExitCode -ne 0) {
            $secret = $SqlCredential.GetNetworkCredential().Password
            if ($secret) {
                $result.Stdout = $result.Stdout.Replace($secret,'[REDACTED]')
                $result.Stderr = $result.Stderr.Replace($secret,'[REDACTED]')
            }
            $secret = $null
        }
        return $result
    }
    finally { [void]$start.Environment.Remove('SQLCMDPASSWORD') }
}

function Get-ToolbeltPreflightSql([string]$TargetDatabase) {
    $literal = $TargetDatabase.Replace("'", "''")
    # Nur lesende Prüfungen. Der spätere Installationsprozess führt sie nach
    # seiner Session-AppLock erneut aus, bevor erstmals Trust geändert wird.
    return @"
SET NOCOUNT ON;
IF DB_ID() <= 4 OR DB_NAME() COLLATE Latin1_General_100_BIN2 <> N'$literal' COLLATE Latin1_General_100_BIN2
    THROW 51000, N'TBX_TARGET', 1;
IF ISNULL(HAS_PERMS_BY_NAME(NULL,N'SERVER',N'CONTROL SERVER'),0) <> 1 AND ISNULL(IS_SRVROLEMEMBER(N'sysadmin'),0) <> 1
    THROW 51000, N'TBX_SERVER_RIGHTS', 1;
IF ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'CONTROL'),0) <> 1
    THROW 51000, N'TBX_DATABASE_RIGHTS', 1;
IF TRY_CONVERT(int,SERVERPROPERTY(N'ProductMajorVersion')) NOT IN (15,16,17)
   OR TRY_CONVERT(int,SERVERPROPERTY(N'EngineEdition')) NOT IN (2,3,4)
    THROW 51000, N'TBX_VERSION', 1;
IF EXISTS(SELECT 1 FROM sys.databases WHERE database_id=DB_ID() AND
    (state <> 0 OR is_read_only=1 OR is_trustworthy_on=1 OR compatibility_level < 150))
    THROW 51000, N'TBX_DATABASE_STATE', 1;
IF NOT EXISTS(SELECT 1 FROM sys.configurations WHERE name=N'clr enabled' AND value_in_use=1)
    THROW 51000, N'TBX_CLR', 1;
IF NOT EXISTS(SELECT 1 FROM sys.configurations WHERE name=N'clr strict security' AND value_in_use=1)
   OR EXISTS(SELECT 1 FROM sys.configurations WHERE name=N'lightweight pooling' AND value_in_use<>0)
    THROW 51000, N'TBX_SECURITY', 1;
IF EXISTS(SELECT 1 FROM sys.objects WHERE is_ms_shipped=0)
   OR EXISTS(SELECT 1 FROM sys.assemblies WHERE is_user_defined=1)
   OR EXISTS(SELECT 1 FROM sys.types WHERE is_user_defined=1)
   OR EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name LIKE N'Toolbelt.%')
   OR EXISTS(SELECT 1 FROM sys.schemas WHERE name NOT IN
       (N'dbo',N'guest',N'INFORMATION_SCHEMA',N'sys',N'db_owner',N'db_accessadmin',N'db_securityadmin',
        N'db_ddladmin',N'db_backupoperator',N'db_datareader',N'db_datawriter',N'db_denydatareader',N'db_denydatawriter'))
    THROW 51000, N'TBX_NOT_EMPTY', 1;
IF NOT EXISTS(SELECT 1 FROM sys.dm_os_host_info WHERE host_platform IN (N'Windows',N'Linux'))
    THROW 51000, N'TBX_PLATFORM', 1;
SELECT N'TBX_PREFLIGHT|' + host_platform + N'|' + CONVERT(nvarchar(36),r.database_guid)
FROM sys.dm_os_host_info CROSS JOIN sys.database_recovery_status AS r WHERE r.database_id=DB_ID();
GO
"@
}

function Assert-ToolbeltSqlSuccess($Result, [string]$Phase) {
    if ($Result.ExitCode -eq 0) { return }
    $messages = [ordered]@{
        TBX_TARGET = 'Wähle ausdrücklich eine eigene Zieldatenbank; Systemdatenbanken sind ausgeschlossen.'
        TBX_SERVER_RIGHTS = 'Die Anmeldung benötigt für den Trustschritt CONTROL SERVER oder sysadmin. Es werden keine Rechte vergeben.'
        TBX_DATABASE_RIGHTS = 'Die Anmeldung benötigt CONTROL auf der Zieldatenbank.'
        TBX_VERSION = 'Der Satz unterstützt SQL Server 2019, 2022 und 2025 als reguläre Datenbank-Engine.'
        TBX_DATABASE_STATE = 'Ziel muss online, beschreibbar, mit CL mindestens 150 und TRUSTWORTHY OFF bereitstehen.'
        TBX_CLR = 'CLR ist deaktiviert. Die Administration muss clr enabled vorbereiten; danach erneut bewusst starten.'
        TBX_SECURITY = 'Erforderlich sind clr strict security=1 und lightweight pooling=0. Keine automatische Konfigurationsänderung.'
        TBX_NOT_EMPTY = 'Die Zieldatenbank enthält bereits Objekte oder Toolbelt-Marker. Dieser Aufruf ist nur für eine leere Neuinstallation bestimmt.'
        TBX_PLATFORM = 'Die SQL-Server-Plattform muss Windows oder Linux sein.'
        TBX_LOCK = 'Ein anderer Ein-Aufruf-Installer belegt das Ziel. Keine automatische Wiederholung.'
        TBX_TARGET_CHANGED = 'Zielidentität oder Plattform hat sich seit der Vorprüfung geändert. Abbruch vor Trust.'
        TBX_RECEIPT = 'Die abschließenden Modulversions-/Modusmarker stimmen nicht vollständig überein.'
        TBX_DATABASE_MISSING = 'Die Zieldatenbank fehlt. Vorbereiten oder ausdrücklich CreateDatabase verwenden.'
        TBX_PENDING_CONFIGURATION = 'Vorgemerkte Serverkonfiguration gefunden. Keine fremden Änderungen mit RECONFIGURE aktivieren; administrativ klären.'
        TBX_PREPARATION_DRIFT = 'Ziel oder Serverkonfiguration hat sich seit dem gespeicherten Plan geändert. Keine automatische Wiederholung.'
        TBX_PREPARATION_CONTEXT = 'Vorbereitung benötigt master ohne offene Transaktion.'
        TBX_MODEL = 'Die model-Datenbank ist für eine leere sichere Neuinstallation ungeeignet. Administration muss die Vorlage prüfen.'
    }
    $text = $Result.Stdout + "`n" + $Result.Stderr
    Write-Verbose ($text.Substring(0,[Math]::Min($text.Length,4096)))
    foreach ($code in $messages.Keys) {
        if ($text -match "\b$code\b") { Stop-ToolbeltInstall $code $messages[$code] }
    }
    Stop-ToolbeltInstall 'SQL_FAILED' "$Phase fehlgeschlagen (sqlcmd Exitcode $($Result.ExitCode)). Prüfe Anmeldung, Netzwerk, Zertifikatsprüfung und SQL-Fehler im Ziel. Es wird nichts automatisch wiederholt. Nach Installationsbeginn können Module und Trust bestehen bleiben."
}

function Invoke-ToolbeltInstall {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][ValidateSet('local','central')][string]$DeploymentMode,
        [string]$ServerInstance, [string]$Database,
        [Management.Automation.PSCredential]$Credential, [string]$PackageZip,
        [string]$SqlcmdPath = 'sqlcmd', [switch]$TrustServerCertificate,
        [switch]$ValidateOnly, [switch]$PreflightOnly,
        [switch]$CreateDatabase, [switch]$EnableClr,
        [ValidateRange(1,120)][int]$LoginTimeoutSeconds = 60,
        [ValidateRange(1,1800)][int]$CommandTimeoutSeconds = 600
    )
    $ErrorActionPreference = 'Stop'
    if ($PSVersionTable.PSVersion.Major -lt 7 -or ($PSVersionTable.PSVersion.Major -eq 7 -and $PSVersionTable.PSVersion.Minor -lt 4)) { Stop-ToolbeltInstall 'CLIENT' 'PowerShell 7.4 oder neuer ist erforderlich.' }
    if ($ValidateOnly -and $PreflightOnly) { Stop-ToolbeltInstall 'ARGUMENT' 'ValidateOnly und PreflightOnly sind getrennte Modi.' }
    if (-not $ValidateOnly -and ([string]::IsNullOrWhiteSpace($ServerInstance) -or
        [string]::IsNullOrWhiteSpace($Database) -or $Database.Length -gt 128 -or
        $Database -match '[\x00-\x1f\x7f]' -or $ServerInstance -match '[\x00-\x1f\x7f]')) {
        Stop-ToolbeltInstall 'TARGET' 'ServerInstance und Database müssen ausdrücklich und ohne Steuerzeichen angegeben werden (Datenbank: 1–128 Zeichen).'
    }
    $scratch = Join-Path ([IO.Path]::GetTempPath()) ('toolbelt-install-' + [guid]::NewGuid().ToString('N'))
    [void][IO.Directory]::CreateDirectory($scratch)
    if (-not $IsWindows) { [IO.File]::SetUnixFileMode($scratch,[IO.UnixFileMode]::UserRead -bor [IO.UnixFileMode]::UserWrite -bor [IO.UnixFileMode]::UserExecute) }
    $ownedFiles = [Collections.Generic.List[string]]::new()
    try {
        Write-Host '[1/4] Gebundenes rc.2-Paket prüfen.'
        if (-not $PackageZip) {
            $checkoutZip = Join-Path $PSScriptRoot '../Releases/1.0.0/Builds/2026-11-18-78fb8571/SQL-Server-Toolbelt-1.0.0-Current-Install.zip'
            if (Test-Path -LiteralPath $checkoutZip -PathType Leaf) { $PackageZip = $checkoutZip }
            else {
                $PackageZip = Join-Path $scratch 'package.zip'; $ownedFiles.Add($PackageZip)
                try {
                    Invoke-WebRequest -Uri 'https://github.com/gecompat/SQL_Server_Toolbelt/releases/download/v1.0.0-rc.2/SQL-Server-Toolbelt-1.0.0-Current-Install.zip' -OutFile $PackageZip -TimeoutSec 120
                } catch { Stop-ToolbeltInstall 'DOWNLOAD' 'Der rc.2-Download ist fehlgeschlagen. Alternativ die originale ZIP mit PackageZip übergeben.' }
            }
        }
        try { $package = Get-ToolbeltPayload $PackageZip }
        catch { Stop-ToolbeltInstall 'PACKAGE' 'Paket nicht lesbar oder nicht unverändert. Verwende die originale rc.2-Installer-ZIP.' }
        if ($ValidateOnly) { return [pscustomobject]@{ Status='PACKAGE_OK'; Release='v1.0.0-rc.2'; SqlExecuted=$false } }
        try { $tool = (Get-Command -Name $SqlcmdPath -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source }
        catch { Stop-ToolbeltInstall 'CLIENT' 'sqlcmd (ODBC) fehlt. Installiere den Microsoft-ODBC-Client oder gib SqlcmdPath ausdrücklich an.' }
        $helpStart = [Diagnostics.ProcessStartInfo]::new($tool)
        $helpStart.UseShellExecute=$false; $helpStart.CreateNoWindow=$true
        $helpStart.RedirectStandardOutput=$true; $helpStart.RedirectStandardError=$true; $helpStart.ArgumentList.Add('-?')
        $help = Invoke-ToolbeltNativeProcess $helpStart 10
        if (($help.Stdout + $help.Stderr) -notmatch 'SQL Server Command Line Tool') {
            Stop-ToolbeltInstall 'CLIENT' 'Dieser Einstieg benötigt sqlcmd (ODBC); sqlcmd (Go) wird nicht automatisch als Ersatz verwendet.'
        }
        Write-Host '[2/4] Ziel, Rechte, CLR, Sicherheitszustand und leere Datenbank prüfen.'
        $preparationJournal=$null
        if ($CreateDatabase -or $EnableClr) {
            $prepareFile=Join-Path $scratch 'prepare.sql'; $ownedFiles.Add($prepareFile)
            $prepareCall=@{Executable=$tool;Server=$ServerInstance;Catalog='master';SqlCredential=$Credential
                CertificateOverride=[bool]$TrustServerCertificate;LoginTimeout=$LoginTimeoutSeconds;CommandTimeout=$CommandTimeoutSeconds}
            [IO.File]::WriteAllText($prepareFile,(Get-ToolbeltPreparationSql $Database ([bool]$CreateDatabase) ([bool]$EnableClr)),[Text.UTF8Encoding]::new($false))
            $planResult=Invoke-ToolbeltSql @prepareCall -File $prepareFile
            Assert-ToolbeltSqlSuccess $planResult 'Lesende Vorbereitung'
            $parts=@([regex]::Matches($planResult.Stdout,'(?m)^[ \t]*TBX_PREPARATION_PART\|(\d{4})\|([0-9A-F]+)[ \t]*\r?$'))
            $counts=@([regex]::Matches($planResult.Stdout,'(?m)^\s*TBX_PREPARATION_PARTS\|(\d+)\s*$'))
            if($counts.Count -ne 1 -or $parts.Count -lt 1 -or $parts.Count -ne [int]$counts[0].Groups[1].Value){Stop-ToolbeltInstall 'PROBE' 'Kein vollständiger Vorbereitungsplan. Keine Änderung ausgeführt.'}
            $builder=[Text.StringBuilder]::new()
            for($i=0;$i -lt $parts.Count;$i++){
                if([int]$parts[$i].Groups[1].Value -ne $i){Stop-ToolbeltInstall 'PROBE' 'Mehrdeutige Planreihenfolge.'}
                [void]$builder.Append($parts[$i].Groups[2].Value.TrimEnd())
            }
            $plan=[Text.UnicodeEncoding]::new($false,$false,$true).GetString([Convert]::FromHexString($builder.ToString()))
            $parsed=$plan|ConvertFrom-Json
            if($parsed.database_name -cne $Database -or $parsed.platform -cnotin @('Windows','Linux') -or @($parsed.configurations).Count -lt 1){Stop-ToolbeltInstall 'PROBE' 'Ungültiger Vorbereitungsplan.'}
            if($PreflightOnly){return [pscustomobject]@{Status='PREPARATION_PREFLIGHT_OK';Mutations=$false;DatabaseExists=($null -ne $parsed.database_guid);Platform=$parsed.platform}}
            $preparationJournal=New-ToolbeltPreparationJournal $Database $ServerInstance $plan
            Write-Host ('Privates Vorbereitungsjournal: '+$preparationJournal.Path)
            [IO.File]::WriteAllText($prepareFile,(Get-ToolbeltPreparationSql $Database ([bool]$CreateDatabase) ([bool]$EnableClr) $plan),[Text.UTF8Encoding]::new($false))
            $preparationJournal.Record.state='DISPATCHED_OUTCOME_UNKNOWN'
            [IO.File]::WriteAllText($preparationJournal.Path,($preparationJournal.Record|ConvertTo-Json -Depth 8),[Text.UTF8Encoding]::new($false))
            try {
                $prepared=Invoke-ToolbeltSql @prepareCall -File $prepareFile
                $created=@([regex]::Matches($prepared.Stdout,'(?m)^\s*TBX_PREPARATION_CREATED_GUID\|([0-9a-fA-F-]{36})\s*$'))
                $preparationJournal.Record.outcome=@{ExitCode=$prepared.ExitCode;CreatedGuid=$(if($created.Count -eq 1){$created[0].Groups[1].Value}else{$null})}
                Assert-ToolbeltSqlSuccess $prepared 'Datenbank-/CLR-Vorbereitung'
                if(@([regex]::Matches($prepared.Stdout,'(?m)^\s*TBX_PREPARATION_OK\s*$')).Count -ne 1){Stop-ToolbeltInstall 'RECEIPT' 'Vorbereitungsabschluss fehlt. Privates Journal und Zielzustand prüfen.'}
                $targets=@([regex]::Matches($prepared.Stdout,'(?m)^\s*TBX_PREPARATION_TARGET\|([0-9a-fA-F-]{36})\s*$'))
                $preparedGuid=[guid]::Empty
                if($targets.Count -ne 1 -or ![guid]::TryParse($targets[0].Groups[1].Value,[ref]$preparedGuid)){Stop-ToolbeltInstall 'RECEIPT' 'Vorbereitete Datenbankidentität fehlt.'}
                $preparationJournal.Record.state='PREPARATION_COMPLETE'
                $preparationJournal.Record.outcome=@{DatabaseCreated=($prepared.Stdout -match '(?m)^\s*TBX_PREPARATION_DATABASE_CREATED\s*$');ClrEnabled=($prepared.Stdout -match '(?m)^\s*TBX_PREPARATION_CLR_ENABLED\s*$');DatabaseGuid=$preparedGuid.ToString();CreatedGuid=$(if($created.Count -eq 1){$created[0].Groups[1].Value}else{$null})}
            } catch {
                Write-Warning ('Vorbereitung fehlgeschlagen; Teiländerungen möglich. Journal: '+$preparationJournal.Path+'. Keine automatische Rücknahme oder Wiederholung.')
                throw
            } finally { [IO.File]::WriteAllText($preparationJournal.Path,($preparationJournal.Record|ConvertTo-Json -Depth 8),[Text.UTF8Encoding]::new($false)) }
        }
        $preflight = Get-ToolbeltPreflightSql $Database
        $probeFile = Join-Path $scratch 'preflight.sql'; $ownedFiles.Add($probeFile)
        [IO.File]::WriteAllText($probeFile,$preflight,[Text.UTF8Encoding]::new($false))
        $call = @{ Executable=$tool; Server=$ServerInstance; Catalog=$Database; SqlCredential=$Credential
            CertificateOverride=[bool]$TrustServerCertificate; LoginTimeout=$LoginTimeoutSeconds; CommandTimeout=$CommandTimeoutSeconds }
        $probe = Invoke-ToolbeltSql @call -File $probeFile
        Assert-ToolbeltSqlSuccess $probe 'Zielvorprüfung'
        $probeMatches = @([regex]::Matches($probe.Stdout,'(?m)^\s*TBX_PREFLIGHT\|(Windows|Linux)\|([0-9a-fA-F-]{36})\s*$'))
        if ($probeMatches.Count -ne 1) { Stop-ToolbeltInstall 'PROBE' 'Die Zielvorprüfung lieferte keinen eindeutigen Plattform-/Identitätsnachweis.' }
        $platform = $probeMatches[0].Groups[1].Value
        $guid = [guid]::Empty
        if (-not [guid]::TryParse($probeMatches[0].Groups[2].Value,[ref]$guid)) { Stop-ToolbeltInstall 'PROBE' 'Die Zielidentität ist ungültig.' }
        if($preparationJournal -and $guid -ne $preparedGuid){Stop-ToolbeltInstall 'TBX_TARGET_CHANGED' 'Die vorbereitete Datenbank wurde vor der Installation ersetzt.'}
        $profilePlatform = if ($platform -eq 'Windows') { 'Windows' } else { 'Portable' }
        $profile = "$profilePlatform-$DeploymentMode"
        $selection = @($package.Metadata.profiles | Where-Object { $_.name -ceq $profile })
        if ($selection.Count -ne 1) { Stop-ToolbeltInstall 'PACKAGE' 'Das gewählte Profil fehlt im Paket.' }
        if ($PreflightOnly) { return [pscustomobject]@{ Status='PREFLIGHT_OK'; Profile=$profile; Modules=$selection[0].modules.Count; Mutations=$false } }
        $identifier = $Database.Replace(']',']]')
        $expectedPlatform = $platform.Replace("'","''")
        $versions = Get-ToolbeltModuleVersions
        $modules = @($selection[0].modules | ForEach-Object {
            if (-not $versions.ContainsKey($_)) { Stop-ToolbeltInstall 'PACKAGE' 'Für ein Modul fehlt die gebundene Releaseversion.' }
            "(N'$($_.Replace("'","''"))',N'$($versions[$_])')"
        }) -join ",`n"
        $trust = [Text.Encoding]::UTF8.GetString($package.Files["Trust-$profilePlatform.sql"])
        $install = [Text.Encoding]::UTF8.GetString($package.Files["Install-$profile.sql"])
        # Ein Installationsprozess: Session-Lock, erneute Vorprüfung, originales
        # Trustskript, ursprünglicher Export und abschließender Modulnachweis.
        # Die Module behalten ihre eigenen Transaktionen und Fehlerabbruchgrenzen.
        $sql = @"
:ON ERROR EXIT
SET NOCOUNT ON;
DECLARE @lock int;
EXEC @lock=sys.sp_getapplock @Resource=N'Toolbelt.SingleCallInstall',@LockMode=N'Exclusive',@LockOwner=N'Session',@LockTimeout=0,@DbPrincipal=N'public';
IF @lock<0 THROW 51000,N'TBX_LOCK',1;
IF NOT EXISTS(SELECT 1 FROM sys.database_recovery_status WHERE database_id=DB_ID() AND database_guid=CONVERT(uniqueidentifier,N'$guid'))
   OR NOT EXISTS(SELECT 1 FROM sys.dm_os_host_info WHERE host_platform=N'$expectedPlatform')
    THROW 51000,N'TBX_TARGET_CHANGED',1;
GO
$preflight
$trust
USE [$identifier];
GO
$install
GO
DECLARE @expected TABLE(id nvarchar(128) NOT NULL PRIMARY KEY,version nvarchar(64) NOT NULL);
INSERT @expected VALUES $modules;
IF EXISTS(SELECT 1 FROM @expected e WHERE
    NOT EXISTS(SELECT 1 FROM sys.extended_properties p WHERE p.class=0 AND p.name=N'Toolbelt.Module.'+e.id+N'.Version' AND CONVERT(nvarchar(64),p.value)=e.version) OR
    (e.id NOT IN (N'toolbelt.filesystem.windows',N'toolbelt.tsql.ssis-debug') AND
     NOT EXISTS(SELECT 1 FROM sys.extended_properties p WHERE p.class=0 AND p.name=N'Toolbelt.Module.'+e.id+N'.DeploymentMode' AND CONVERT(nvarchar(16),p.value)=N'$DeploymentMode')))
    THROW 51000,N'TBX_RECEIPT',1;
SELECT N'TBX_INSTALL_OK|'+CONVERT(nvarchar(10),COUNT(*)) FROM @expected;
GO
"@
        $installFile = Join-Path $scratch 'install.sql'; $ownedFiles.Add($installFile)
        [IO.File]::WriteAllText($installFile,$sql,[Text.UTF8Encoding]::new($false))
        Write-Host "[3/4] Exakten Assembly-Trust vorbereiten und $profile installieren."
        $result = Invoke-ToolbeltSql @call -File $installFile
        Assert-ToolbeltSqlSuccess $result 'Trust/Installation'
        $receipt = @([regex]::Matches($result.Stdout,'(?m)^\s*TBX_INSTALL_OK\|(\d+)\s*$'))
        if ($receipt.Count -ne 1 -or [int]$receipt[0].Groups[1].Value -ne $selection[0].modules.Count) {
            Stop-ToolbeltInstall 'RECEIPT' 'Der Client lieferte keinen vollständigen Abschlussnachweis. Vor erneutem Aufruf den Zielzustand prüfen.'
        }
        Write-Host '[4/4] Alle erwarteten Modulversions- und Modusmarker bestätigt.'
        return [pscustomobject]@{ Status='INSTALLED'; Profile=$profile; Modules=$selection[0].modules.Count; Release='v1.0.0-rc.2'; PreparationJournal=$(if($preparationJournal){$preparationJournal.Path}else{$null}) }
    } finally {
        # Nur eigene, einzeln gebundene Dateien löschen; niemals fremde Reste oder
        # Testdatenbanken/Trusteinträge pauschal entfernen. Keine rekursive Löschung.
        try {
            foreach ($file in $ownedFiles) { if ([IO.File]::Exists($file)) { [IO.File]::Delete($file) } }
            if ([IO.Directory]::Exists($scratch)) { [IO.Directory]::Delete($scratch,$false) }
        } catch { Write-Warning "Temporäres Arbeitsverzeichnis konnte nicht vollständig entfernt werden: $scratch" }
    }
}

if ($MyInvocation.InvocationName -ne '.') { Invoke-ToolbeltInstall @PSBoundParameters }
