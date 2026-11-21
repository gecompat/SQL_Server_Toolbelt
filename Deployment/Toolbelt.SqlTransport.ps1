# Gemeinsamer SQL-Clienttransport; keine Modulmarker oder Paketversionslogik.

function Stop-ToolbeltInstall([string]$Code, [string]$Message) {
    throw [InvalidOperationException]::new("[$Code] $Message")
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

function Assert-ToolbeltSqlSuccess($Result, [string]$Phase) {
    if ($Result.ExitCode -eq 0) { return }
    $messages = [ordered]@{
        TBX_TARGET = 'Wähle ausdrücklich eine eigene Zieldatenbank; Systemdatenbanken sind ausgeschlossen.'
        TBX_SERVER_RIGHTS = 'Die Anmeldung benötigt für den Trustschritt CONTROL SERVER oder sysadmin. Es werden keine Rechte vergeben.'
        TBX_DATABASE_RIGHTS = 'Die Anmeldung benötigt CONTROL auf der Zieldatenbank.'
        TBX_VERSION = 'Der Satz unterstützt SQL Server 2019, 2022 und 2025 als reguläre Datenbank-Engine.'
        TBX_DATABASE_STATE = 'Ziel muss online und beschreibbar sein sowie Compatibility Level 150 oder höher verwenden.'
        TBX_CLR = 'CLR ist deaktiviert. Die Administration muss clr enabled vorbereiten; danach erneut bewusst starten.'
        TBX_SECURITY = 'Lightweight Pooling muss deaktiviert sein. CLR Strict Security muss aktiviert sein, außer bei bestehendem TRUSTWORTHY ON mit ausdrücklich gewähltem DB-Trustweg. Die administrative Vorbereitung erfordert Strict Security ON. Eine automatische Konfigurationsänderung erfolgt nicht.'
        TBX_NOT_EMPTY = 'Die Zieldatenbank enthält bereits Objekte oder Toolbelt-Marker. Dieser Aufruf ist nur für eine leere Neuinstallation bestimmt.'
        TBX_PLATFORM = 'Die SQL-Server-Plattform muss Windows oder Linux sein.'
        TBX_LOCK = 'Ein anderer Ein-Aufruf-Installer belegt das Ziel. Keine automatische Wiederholung.'
        TBX_TARGET_CHANGED = 'Zielidentität oder Plattform hat sich seit der Vorprüfung geändert. Abbruch vor Trust.'
        TBX_RECEIPT = 'Mindestens eine erwartete SQL-Schnittstelle oder Assembly fehlt oder hat einen abweichenden Objekttyp.'
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
