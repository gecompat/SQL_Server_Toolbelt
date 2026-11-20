# Aktueller markerfreier Installationsablauf; Transport und Vorbereitung bleiben getrennt.
. (Join-Path $PSScriptRoot 'Toolbelt.SqlTransport.ps1')
. (Join-Path $PSScriptRoot 'Toolbelt.Package.ps1')
. (Join-Path $PSScriptRoot 'Toolbelt.Provisioning.ps1')

function Get-ToolbeltPreflightSql([string]$TargetDatabase,[bool]$NeedClr=$true) {
    if([string]::IsNullOrWhiteSpace($TargetDatabase) -or $TargetDatabase.Length -gt 128 -or
        $TargetDatabase.Contains('$(') -or @($TargetDatabase.ToCharArray()|Where-Object {[char]::IsControl($_)}).Count) {
        Stop-ToolbeltInstall 'TARGET' 'Ungültiger Datenbankname oder Client-Steuerzeichen.'
    }
    $literal=$TargetDatabase.Replace("'","''")
    $clrCheck=if($NeedClr){"IF NOT EXISTS(SELECT 1 FROM sys.configurations WHERE name=N'clr enabled' AND value_in_use=1) THROW 51000,N'TBX_CLR',1;"}else{''}
    $securityCheck=if($NeedClr){@'
IF NOT EXISTS(SELECT 1 FROM sys.configurations WHERE name=N'clr strict security' AND value=1 AND value_in_use=1)
 OR EXISTS(SELECT 1 FROM sys.configurations WHERE name=N'lightweight pooling' AND (value<>0 OR value_in_use<>0))
 THROW 51000,N'TBX_SECURITY',1;
'@}else{''}
    @"
SET NOCOUNT ON;
IF DB_ID()<=4 OR DB_NAME() COLLATE Latin1_General_100_BIN2<>N'$literal' COLLATE Latin1_General_100_BIN2
 THROW 51000,N'TBX_TARGET',1;
IF TRY_CONVERT(int,SERVERPROPERTY(N'ProductMajorVersion')) NOT IN(15,16,17)
 OR TRY_CONVERT(int,SERVERPROPERTY(N'EngineEdition')) NOT IN(2,3,4) THROW 51000,N'TBX_VERSION',1;
IF EXISTS(SELECT 1 FROM sys.databases WHERE database_id=DB_ID() AND (state<>0 OR is_read_only=1 OR compatibility_level<150))
 THROW 51000,N'TBX_DATABASE_STATE',1;
$clrCheck
$securityCheck
IF NOT EXISTS(SELECT 1 FROM sys.dm_os_host_info WHERE host_platform IN(N'Windows',N'Linux'))
 THROW 51000,N'TBX_PLATFORM',1;
SELECT N'TBX_PREFLIGHT|'+host_platform+N'|'+CONVERT(nvarchar(36),r.database_guid)
FROM sys.dm_os_host_info CROSS JOIN sys.database_recovery_status r WHERE r.database_id=DB_ID();
"@
}

function New-ToolbeltInstallScratch {
    $directory=Join-Path ([IO.Path]::GetTempPath()) ('ToolbeltInstall-'+[guid]::NewGuid().ToString('N'))
    [void][IO.Directory]::CreateDirectory($directory)
    if($IsWindows){
        $acl=[Security.AccessControl.DirectorySecurity]::new();$acl.SetAccessRuleProtection($true,$false)
        $sid=[Security.Principal.WindowsIdentity]::GetCurrent().User;$acl.SetOwner($sid)
        $acl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new($sid,'FullControl','ContainerInherit,ObjectInherit','None','Allow'))
        Set-Acl -LiteralPath $directory -AclObject $acl
    }else{[IO.File]::SetUnixFileMode($directory,[IO.UnixFileMode]::UserRead -bor [IO.UnixFileMode]::UserWrite -bor [IO.UnixFileMode]::UserExecute)}
    $directory
}

function Invoke-ToolbeltInstall {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][ValidateSet('local','central')][string]$DeploymentMode,
        [string]$ServerInstance,[string]$Database,[Management.Automation.PSCredential]$Credential,
        [string]$PackageZip,[string]$InstallSql,
        [ValidatePattern('^[A-Fa-f0-9]{64}$')][string]$ExpectedSha256,
        [ValidateSet('Auto','Windows','Portable')][string]$Platform='Auto',
        [ValidateSet('auto','hash','trustworthy-checked','trustworthy')][string]$TrustMethod='auto',
        [string]$SqlcmdPath='sqlcmd',[switch]$TrustServerCertificate,
        [switch]$ValidateOnly,[switch]$PreflightOnly,[switch]$CreateDatabase,[switch]$EnableClr,
        [ValidateRange(1,120)][int]$LoginTimeoutSeconds=60,
        [ValidateRange(1,1800)][int]$CommandTimeoutSeconds=600
    )
    if($PackageZip -and $InstallSql){Stop-ToolbeltInstall 'INPUT' 'PackageZip und InstallSql sind alternative Eingaben.'}
    if($ValidateOnly -and $PreflightOnly){Stop-ToolbeltInstall 'INPUT' 'ValidateOnly und PreflightOnly nicht gemeinsam verwenden.'}
    try {
        if($InstallSql){$package=Get-ToolbeltSqlPayload $InstallSql $ExpectedSha256}
        else {
            if(-not $PackageZip){
                $candidates=@((Join-Path $PSScriptRoot '../Package/Toolbelt-Install-Payload.zip'),
                    (Join-Path $PSScriptRoot '../Releases/1.0.0/InstallPackages/SQL-Server-Toolbelt-v1.0.0-rc.5-Payload.zip'))
                $found=@($candidates|Where-Object {Test-Path -LiteralPath $_ -PathType Leaf}|Select-Object -First 1)
                if($found.Count -ne 1){throw 'Aktuellen Release-/Installationssatz vollständig entpacken oder PackageZip beziehungsweise InstallSql ausdrücklich angeben.'}
                $PackageZip=[string]$found[0]
            }
            $package=Get-ToolbeltPayload $PackageZip $ExpectedSha256
        }
    }catch{Stop-ToolbeltInstall 'PACKAGE' $_.Exception.Message}
    if($ValidateOnly){return [pscustomobject]@{Status='PACKAGE_OK';Release=$package.Manifest.release;Profiles=@($package.Manifest.profiles).Count;SqlExecuted=$false}}
    if([string]::IsNullOrWhiteSpace($ServerInstance) -or @($ServerInstance.ToCharArray()|Where-Object {[char]::IsControl($_)}).Count){Stop-ToolbeltInstall 'TARGET' 'ServerInstance ausdrücklich und ohne Steuerzeichen angeben.'}
    [void](Get-ToolbeltPreflightSql $Database)
    if($InstallSql -and -not $PSBoundParameters.ContainsKey('TrustMethod')){$TrustMethod=$package.Manifest.profiles[0].trust}
    try{$tool=(Get-Command -Name $SqlcmdPath -CommandType Application -ErrorAction Stop|Select-Object -First 1).Source}
    catch{Stop-ToolbeltInstall 'CLIENT' 'sqlcmd (ODBC) fehlt; alternativ die normale SQL-Datei direkt in SSMS ausführen.'}
    $helpStart=[Diagnostics.ProcessStartInfo]::new($tool);$helpStart.UseShellExecute=$false;$helpStart.CreateNoWindow=$true
    $helpStart.RedirectStandardOutput=$true;$helpStart.RedirectStandardError=$true;$helpStart.ArgumentList.Add('-?')
    foreach($key in @($helpStart.Environment.Keys|Where-Object {$_ -like 'SQLCMD*'})){$helpStart.Environment.Remove($key)|Out-Null}
    $help=Invoke-ToolbeltNativeProcess $helpStart 10
    if(($help.Stdout+$help.Stderr) -notmatch 'SQL Server Command Line Tool'){Stop-ToolbeltInstall 'CLIENT' 'Dieser Clientweg benötigt sqlcmd (ODBC); kein automatischer Providerwechsel.'}
    $scratch=New-ToolbeltInstallScratch;$ownedFiles=[Collections.Generic.List[string]]::new();$preparationJournal=$null
    try {
        $call=@{Executable=$tool;Server=$ServerInstance;Catalog=$Database;SqlCredential=$Credential;
            CertificateOverride=[bool]$TrustServerCertificate;LoginTimeout=$LoginTimeoutSeconds;CommandTimeout=$CommandTimeoutSeconds}
        # Der opt-in-Vorbereitungsblock wird unten aus dem unveränderten bisherigen
        # Controller übernommen; seine eigenen Rechte-/Driftgrenzen bleiben erhalten.
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
                if($null -ne $parsed.database_guid -and $preparedGuid -ne [guid]$parsed.database_guid){Stop-ToolbeltInstall 'TBX_TARGET_CHANGED' 'Die vorhandene Datenbank wurde während der Vorbereitung ersetzt.'}
                if($created.Count -eq 1 -and $preparedGuid -ne [guid]$created[0].Groups[1].Value){Stop-ToolbeltInstall 'TBX_TARGET_CHANGED' 'Die angelegte Datenbank wurde während der Vorbereitung ersetzt.'}
                $preparationJournal.Record.state='PREPARATION_COMPLETE'
                $preparationJournal.Record.outcome=@{DatabaseCreated=($prepared.Stdout -match '(?m)^\s*TBX_PREPARATION_DATABASE_CREATED\s*$');ClrEnabled=($prepared.Stdout -match '(?m)^\s*TBX_PREPARATION_CLR_ENABLED\s*$');DatabaseGuid=$preparedGuid.ToString();CreatedGuid=$(if($created.Count -eq 1){$created[0].Groups[1].Value}else{$null})}
            } catch {
                Write-Warning ('Vorbereitung fehlgeschlagen; Teiländerungen möglich. Journal: '+$preparationJournal.Path+'. Keine automatische Rücknahme oder Wiederholung.')
                throw
            } finally { [IO.File]::WriteAllText($preparationJournal.Path,($preparationJournal.Record|ConvertTo-Json -Depth 8),[Text.UTF8Encoding]::new($false)) }
        }
        $needClr=@($package.Manifest.profiles | ForEach-Object {$_.assemblies.PSObject.Properties}).Count -gt 0
        $preflight=Get-ToolbeltPreflightSql $Database $needClr
        $probeFile=Join-Path $scratch 'preflight.sql';$ownedFiles.Add($probeFile)
        [IO.File]::WriteAllText($probeFile,$preflight,[Text.UTF8Encoding]::new($false))
        $probe=Invoke-ToolbeltSql @call -File $probeFile;Assert-ToolbeltSqlSuccess $probe 'Zielvorprüfung'
        $matches=@([regex]::Matches($probe.Stdout,'(?m)^\s*TBX_PREFLIGHT\|(Windows|Linux)\|([0-9a-fA-F-]{36})\s*$'))
        if($matches.Count -ne 1){Stop-ToolbeltInstall 'PROBE' 'Keine eindeutige Plattform-/Datenbankidentität. Metadatenrechte und Ziel prüfen.'}
        $hostPlatform=$matches[0].Groups[1].Value;$parsedGuid=[guid]::Empty
        if(-not [guid]::TryParse($matches[0].Groups[2].Value,[ref]$parsedGuid)){Stop-ToolbeltInstall 'PROBE' 'Ungültige Datenbankidentität.'}
        $guid=$parsedGuid.ToString()
        if($preparationJournal -and $guid -cne $preparationJournal.Record.outcome.DatabaseGuid){
            Stop-ToolbeltInstall 'TBX_TARGET_CHANGED' 'Die vorbereitete Datenbank wurde vor der Installationsprüfung ersetzt.'
        }
        $selectedPlatform=if($Platform -eq 'Auto'){if($hostPlatform -eq 'Linux'){'Portable'}else{'Windows'}}else{$Platform}
        if($hostPlatform -eq 'Linux' -and $selectedPlatform -eq 'Windows'){Stop-ToolbeltInstall 'PLATFORM' 'Windows-Profil ist auf Linux nicht unterstützt.'}
        $selection=@($package.Manifest.profiles|Where-Object {$_.platform -ceq $selectedPlatform -and $_.mode -ceq $DeploymentMode})
        if($selection.Count -ne 1){Stop-ToolbeltInstall 'PROFILE' 'Die gewählte Plattform-/Moduskombination fehlt in der Eingabe.'}
        $profile=$selection[0]
        if($PreflightOnly){return [pscustomobject]@{Status='PREFLIGHT_OK';Platform=$selectedPlatform;DeploymentMode=$DeploymentMode;Mutations=$false}}
        $sql=Get-ToolbeltInstallSql $package $profile $Database $TrustMethod
        $identifier=$Database.Replace(']',']]')
        $guard=@"
USE [$identifier];
SET NOCOUNT ON;
DECLARE @tbx_install_lock int;
EXEC @tbx_install_lock=sys.sp_getapplock @Resource=N'Toolbelt.SingleCallInstall',@LockMode=N'Exclusive',@LockOwner=N'Session',@LockTimeout=0,@DbPrincipal=N'public';
IF @tbx_install_lock<0 THROW 51000,N'TBX_LOCK',1;
IF NOT EXISTS(SELECT 1 FROM sys.database_recovery_status WHERE database_id=DB_ID() AND database_guid=CONVERT(uniqueidentifier,N'$guid'))
 THROW 51000,N'TBX_TARGET_CHANGED',1;
IF NOT EXISTS(SELECT 1 FROM sys.dm_os_host_info WHERE host_platform=N'$hostPlatform')
 THROW 51000,N'TBX_TARGET_CHANGED',1;
$preflight
"@
        $installFile=Join-Path $scratch 'install.sql';$ownedFiles.Add($installFile)
        $combined=$guard+"`n"+$sql+"`n"+(Get-ToolbeltReceiptSql $profile $Database)
        [IO.File]::WriteAllText($installFile,$combined,[Text.UTF8Encoding]::new($false))
        $result=Invoke-ToolbeltSql @call -File $installFile;Assert-ToolbeltSqlSuccess $result 'Trust/Installation'
        $receipt=@([regex]::Matches($result.Stdout,'(?m)^\s*TBX_INSTALL_OK\|(\d+)\s*$'))
        if($receipt.Count -ne 1 -or [int]$receipt[0].Groups[1].Value -ne @($profile.modules).Count){Stop-ToolbeltInstall 'RECEIPT' 'Vollständiger Schnittstellenabschluss fehlt; Zielzustand vor Wiederholung prüfen.'}
        [pscustomobject]@{Status='INSTALLED_OR_PRESENT';Profile=$selectedPlatform+'-'+$DeploymentMode;Modules=@($profile.modules).Count;
            Release=$package.Manifest.release;TrustMethod=$TrustMethod;Lifecycle='create-only';
            PreparationJournal=$(if($preparationJournal){$preparationJournal.Path}else{$null})}
    }finally{
        foreach($file in $ownedFiles){if([IO.File]::Exists($file)){[IO.File]::Delete($file)}}
        if([IO.Directory]::Exists($scratch)){[IO.Directory]::Delete($scratch,$false)}
    }
}
