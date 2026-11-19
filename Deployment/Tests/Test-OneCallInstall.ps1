# Ausschließlich synthetische Clientantworten; kein SQL-Server wird kontaktiert.
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$entry = Join-Path $repoRoot 'Deployment/Install-Toolbelt.ps1'
. $entry -DeploymentMode local
$packageZip = Join-Path $repoRoot 'Releases/1.0.0/Builds/2026-11-18-78fb8571/SQL-Server-Toolbelt-1.0.0-Current-Install.zip'
$package = Get-ToolbeltPayload $packageZip
$versionPins = Get-ToolbeltModuleVersions
$sourceZip = Join-Path $repoRoot 'Releases/1.0.0/Builds/2026-11-18-78fb8571/SQL-Server-Toolbelt-1.0.0-source-78fb8571.zip'
if ((Get-FileHash -LiteralPath $sourceZip -Algorithm SHA256).Hash -ine '089cfca66a8949eaa94b707c95dc7f263b9b3f1c505715ec8acf2599c614d5b9') { throw 'ONE_CALL_SOURCE_ORACLE_HASH' }
$sourceArchive=[IO.Compression.ZipFile]::OpenRead($sourceZip)
try {
    $sourceVersions=@{}
    foreach($member in $sourceArchive.Entries) {
        if($member.FullName -match '^[^/]+/Modules/([^/]+)/module.yaml$') {
            $moduleId=$Matches[1]
            $reader=[IO.StreamReader]::new($member.Open())
            try {$manifest=$reader.ReadToEnd()}finally{$reader.Dispose()}
            $version=[regex]::Match($manifest,'(?m)^version:\s*"([^"\r\n]+)"\s*$')
            if(-not $version.Success -or $versionPins[$moduleId] -cne $version.Groups[1].Value){throw 'ONE_CALL_SOURCE_VERSION_ORACLE'}
            $sourceVersions[$moduleId]=$version.Groups[1].Value
        }
    }
    if($sourceVersions.Count -ne 45 -or $versionPins.Count -ne 45){throw 'ONE_CALL_SOURCE_MODULE_ORACLE'}
}finally{$sourceArchive.Dispose()}
$nativeImplementation = (Get-Item Function:Invoke-ToolbeltNativeProcess).ScriptBlock
$script:assertions=0
function Assert-Test([bool]$Condition,[string]$Message) {
    $script:assertions++
    if (-not $Condition) { throw "ONE_CALL_TEST: $Message" }
}
function Expect-Failure([scriptblock]$Body,[string]$Code) {
    $caught=$false
    try { & $Body | Out-Null } catch { $caught=$_.Exception.Message.Contains("[$Code]") }
    Assert-Test $caught "expected failure $Code"
}

function Assert-OneCallNativeEvidence([hashtable]$Record) {
    if($Record.kind -cne 'one_call_installer_client_composition' -or $Record.result -cne 'PASS_FOR_DECLARED_SCOPE' -or
        $Record.release -cne 'v1.0.0-rc.2' -or $Record.scope.native_authentication -cne 'explicit SqlCredential' -or
        $Record.scope.new_business_module_qualification -ne $false -or $Record.scope.new_tls_or_gui_qualification -ne $false -or
        $Record.scope.published_assets_modified -ne $false){throw 'ONE_CALL_NATIVE_SCOPE'}
    $required=@('Deployment/Install-Toolbelt.ps1','Deployment/Tests/Invoke-OneCallInstallLab.ps1',
        'Tests/Release/Invoke-ApiQualificationLab.ps1','Tests/Release/Invoke-StablePackageLab.ps1','Tests/Release/ClrCaller.Environment.ps1',
        'Tests/CI/run-csv-memory-lab.ps1','Tests/CI/run-lab-local.ps1','Tests/CI/LabQualifiedContract.ps1')
    if($Record.method_source_sha256.Count -ne $required.Count){throw 'ONE_CALL_NATIVE_METHOD_SET'}
    foreach($path in $required){
        $source=[IO.File]::ReadAllText((Join-Path $repoRoot $path)).Replace("`r`n","`n")
        $hash=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($source)))
        if($hash -ine $Record.method_source_sha256[$path]){throw 'ONE_CALL_NATIVE_SOURCE_DRIFT'}
    }
    if($Record.package.path -cne 'Releases/1.0.0/Builds/2026-11-18-78fb8571/SQL-Server-Toolbelt-1.0.0-Current-Install.zip' -or
       $Record.package.sha256 -ine (Get-FileHash -LiteralPath $packageZip -Algorithm SHA256).Hash){throw 'ONE_CALL_NATIVE_PACKAGE'}
    $seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $profiles=0;$modules=0
    foreach($case in $Record.cases){
        $key=$case.platform+'/'+$case.sql_version
        if(-not $seen.Add($key) -or $case.platform -cnotin @('windows','linux') -or $case.sql_version -cnotin @('2019','2022','2025') -or
           $case.compatibility_level -ne @{'2019'=150;'2022'=160;'2025'=170}[$case.sql_version] -or
           $case.result -cne 'COMPLETE' -or $case.fresh_independent_audit -cne 'PASS' -or $case.owned_databases_removed -ne 2 -or
           $case.own_trust_removed_or_preexisting -ne $true -or $case.configuration_restored_or_unchanged -ne $true -or $case.profiles.Count -ne 2){throw 'ONE_CALL_NATIVE_CASE'}
        foreach($mode in @('local','central')){
            $profile=@($case.profiles|Where-Object mode -CEQ $mode)
            $platform=if($case.platform -ceq 'windows'){'Windows'}else{'Portable'}
            $count=if($platform -ceq 'Portable'){41}elseif($mode -ceq 'local'){45}else{43}
            if($profile.Count -ne 1 -or $profile[0].profile -cne "$platform-$mode" -or $profile[0].modules -ne $count -or $profile[0].entry_receipt -cne 'INSTALLED'){throw 'ONE_CALL_NATIVE_PROFILE'}
            $profiles++;$modules+=$count
        }
    }
    if($seen.Count -ne 6 -or $profiles -ne 12 -or $modules -ne 510 -or $Record.totals.profiles -ne 12 -or $Record.totals.fresh_success_audits -ne 6 -or
       $Record.history.sql_auth_failure -cne 'FAILED_CLEANED' -or $Record.history.failed_case_fresh_audit -cne 'PASS' -or
       $Record.history.preconnection_adapter_date_failure_preserved -ne $true -or $Record.accounting.closed -ne $true -or
       $Record.accounting.original_shared_deadline_preserved -ne $true){throw 'ONE_CALL_NATIVE_TOTALS_OR_HISTORY'}
}
$nativeEvidence=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'Qualification/OneCallInstaller.20261119.json') -Raw|ConvertFrom-Json -AsHashtable
Assert-OneCallNativeEvidence $nativeEvidence
Assert-Test $true 'fresh native evidence bound to current source and exact package'
foreach($mutation in @('source','audit','profile','history','scope')){
    $copy=$nativeEvidence|ConvertTo-Json -Depth 10|ConvertFrom-Json -AsHashtable
    switch($mutation){
        source {$copy.method_source_sha256['Deployment/Install-Toolbelt.ps1']='0'*64}
        audit {$copy.cases[0].fresh_independent_audit='not executed'}
        profile {$copy.cases[0].profiles[0].modules=1}
        history {$copy.history.sql_auth_failure='PASS'}
        scope {$copy.scope.new_tls_or_gui_qualification=$true}
    }
    $rejected=$false;try{Assert-OneCallNativeEvidence $copy}catch{$rejected=$true}
    Assert-Test $rejected "native evidence rejects $mutation mutation"
}
$script:sqlCalls=0; $script:helpCalls=0; $script:probeFailure=''; $script:installFailure=''
$script:platform='Windows'; $script:expectedModules=45; $script:missingReceipt=$false; $script:duplicateProbe=$false
$script:clientHelp='Microsoft (R) SQL Server Command Line Tool'
$script:capturedSql=''; $script:capturedStart=$null; $script:expectedCredential=$null
$script:privatePassword='synthetic-'+[guid]::NewGuid().ToString('N')
function Invoke-ToolbeltNativeProcess([Diagnostics.ProcessStartInfo]$StartInfo,[int]$TimeoutSeconds) {
    if ($StartInfo.ArgumentList.Contains('-?')) {
        $script:helpCalls++
        return @{ExitCode=0;Stdout=$script:clientHelp;Stderr=''}
    }
    $script:sqlCalls++; $script:capturedStart=$StartInfo
    $argsList=@($StartInfo.ArgumentList)
    Assert-Test ($argsList.Contains('-N') -and $argsList.Contains('-b') -and $argsList.Contains('-x')) 'encryption and fail-closed client flags'
    Assert-Test ($argsList.Contains('-X1') -eq (-not $script:expectedCredential)) 'SQL auth must retain its child password channel; integrated auth uses X1'
    Assert-Test (-not $argsList.Contains('-P') -and -not $argsList.Contains($script:privatePassword)) 'no password argument'
    Assert-Test (-not $StartInfo.Environment.ContainsKey('SQLCMDINI')) 'no ambient startup script'
    if ($script:expectedCredential) {
        Assert-Test ($StartInfo.Environment['SQLCMDPASSWORD'] -ceq $script:privatePassword -and $argsList.Contains('-U') -and -not $argsList.Contains('-E')) 'explicit SQL identity, child-only secret'
    } else {
        Assert-Test (-not $StartInfo.Environment.ContainsKey('SQLCMDPASSWORD') -and $argsList.Contains('-E') -and -not $argsList.Contains('-U')) 'explicit integrated identity'
    }
    Assert-Test ($env:SQLCMDPASSWORD -ceq 'synthetic-parent-password') 'parent password untouched'
    $inputFile=$argsList[[array]::IndexOf($argsList,'-i')+1]
    $sql=[IO.File]::ReadAllText($inputFile)
    Assert-Test (-not $sql.StartsWith([char]0xfeff)) 'UTF8 without BOM'
    if ([IO.Path]::GetFileName($inputFile) -eq 'preflight.sql') {
        Assert-Test ($sql -notmatch 'sp_add_trusted_assembly|CREATE ASSEMBLY|RECONFIGURE') 'probe is read-only'
        if ($script:probeFailure) { return @{ExitCode=1;Stdout='';Stderr=$script:probeFailure} }
        $line="TBX_PREFLIGHT|$script:platform|00000000-0000-0000-0000-000000000001"
        if ($script:duplicateProbe) { $line+="`n$line" }
        return @{ExitCode=0;Stdout=$line;Stderr=''}
    }
    $script:capturedSql=$sql
    if ($script:installFailure) { return @{ExitCode=1;Stdout='';Stderr=$script:installFailure} }
    return @{ExitCode=0;Stdout=$(if($script:missingReceipt){''}else{"TBX_INSTALL_OK|$script:expectedModules"});Stderr=''}
}
$savedPassword=[Environment]::GetEnvironmentVariable('SQLCMDPASSWORD','Process')
$savedIni=[Environment]::GetEnvironmentVariable('SQLCMDINI','Process')
$scratch=Join-Path ([IO.Path]::GetTempPath()) ('toolbelt-client-test-'+[guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($scratch)
try {
    $env:SQLCMDPASSWORD='synthetic-parent-password'; $env:SQLCMDINI='synthetic-startup.sql'
    $client=(Get-Command pwsh -CommandType Application | Select-Object -First 1).Source
    $options=@{ServerInstance='localhost';Database="Contoso]O'Brien `$(SYNTHETIC)";PackageZip=$packageZip;SqlcmdPath=$client}
    $result=Invoke-ToolbeltInstall -DeploymentMode local -ValidateOnly -PackageZip $packageZip
    Assert-Test ($result.Status -eq 'PACKAGE_OK' -and $script:sqlCalls -eq 0 -and $script:helpCalls -eq 0) 'offline validation before any tool/SQL'
    foreach($targetPlatform in @('Windows','Linux')) {
        $script:platform=$targetPlatform
        foreach($mode in @('local','central')) {
            foreach($useCredential in @($false,$true)) {
                $script:sqlCalls=0; $script:expectedCredential=$useCredential
                $profile=($(if($targetPlatform -eq 'Windows'){'Windows'}else{'Portable'}))+"-$mode"
                $selected=@($package.Metadata.profiles | Where-Object name -eq $profile)[0]
                $script:expectedModules=$selected.modules.Count
                $extra=@{}
                if($useCredential){$extra.Credential=[Management.Automation.PSCredential]::new('ContosoInstaller',(ConvertTo-SecureString $script:privatePassword -AsPlainText -Force));$extra.TrustServerCertificate=$true}
                $result=Invoke-ToolbeltInstall @options @extra -DeploymentMode $mode
                Assert-Test ($result.Status -eq 'INSTALLED' -and $result.Profile -eq $profile -and $result.Modules -eq $selected.modules.Count -and $script:sqlCalls -eq 2) 'eight complete synthetic platform/mode/identity paths'
                $trust=[Text.Encoding]::UTF8.GetString($package.Files["Trust-$($selected.platform).sql"])
                $deploy=[Text.Encoding]::UTF8.GetString($package.Files["Install-$profile.sql"])
                Assert-Test ($script:capturedSql.Contains($trust) -and $script:capturedSql.Contains($deploy)) 'canonical trust and deploy scripts embedded unchanged'
                Assert-Test ($script:capturedSql.IndexOf('TBX_NOT_EMPTY') -lt $script:capturedSql.IndexOf($trust) -and $script:capturedSql.IndexOf('TBX_TARGET_CHANGED') -lt $script:capturedSql.IndexOf($trust)) 'preflight and identity guard precede trust'
                Assert-Test ($script:capturedSql.Contains("USE [Contoso]]O'Brien `$(SYNTHETIC)];") -and $script:capturedSql.Contains("N'Contoso]O''Brien `$(SYNTHETIC)'")) 'quoted identifier and literal, SQLCMD substitution disabled'
                Assert-Test ($script:capturedSql.Contains("@LockOwner=N'Session'") -and $script:capturedSql.IndexOf('TBX_RECEIPT') -gt $script:capturedSql.IndexOf($deploy)) 'session lock and final receipt'
                foreach($module in $selected.modules) {
                    $declaresMode=$deploy.Contains("N'Toolbelt.Module.$module.DeploymentMode'")
                    Assert-Test ($declaresMode -eq ($module -notin @('toolbelt.filesystem.windows','toolbelt.tsql.ssis-debug'))) 'receipt follows actual module mode marker contract'
                    Assert-Test ($script:capturedSql.Contains("(N'$module',N'$($sourceVersions[$module])')")) 'receipt uses actual published module version, not project version'
                }
                Assert-Test ($script:capturedSql.Contains("e.id NOT IN (N'toolbelt.filesystem.windows',N'toolbelt.tsql.ssis-debug')")) 'do not invent mode markers absent from original deployment'
                Assert-Test ($script:capturedStart.ArgumentList.Contains('-C') -eq $useCredential) 'certificate override is explicit only'
                Assert-Test (-not $script:capturedStart.Environment.ContainsKey('SQLCMDPASSWORD')) 'child secret released'
            }
        }
    }
    $script:expectedCredential=$false; $script:sqlCalls=0
    $result=Invoke-ToolbeltInstall @options -DeploymentMode local -PreflightOnly
    Assert-Test ($result.Status -eq 'PREFLIGHT_OK' -and $script:sqlCalls -eq 1) 'preflight-only cannot mutate'
    foreach($failure in @('TBX_TARGET','TBX_SERVER_RIGHTS','TBX_DATABASE_RIGHTS','TBX_VERSION','TBX_DATABASE_STATE','TBX_CLR','TBX_SECURITY','TBX_NOT_EMPTY','TBX_PLATFORM')) {
        $script:probeFailure=$failure; $script:sqlCalls=0
        Expect-Failure {Invoke-ToolbeltInstall @options -DeploymentMode local} $failure
        Assert-Test ($script:sqlCalls -eq 1) 'failed probe prevents trust and retry'
    }
    $script:probeFailure='';$script:duplicateProbe=$true;$script:sqlCalls=0
    Expect-Failure {Invoke-ToolbeltInstall @options -DeploymentMode local} 'PROBE'
    Assert-Test ($script:sqlCalls -eq 1) 'ambiguous probe prevents trust'
    $script:duplicateProbe=$false;$script:installFailure='synthetic SQL error';$script:sqlCalls=0
    Expect-Failure {Invoke-ToolbeltInstall @options -DeploymentMode local} 'SQL_FAILED'
    Assert-Test ($script:sqlCalls -eq 2) 'install failure cannot retry or report success'
    $script:installFailure='';$script:missingReceipt=$true;$script:sqlCalls=0
    Expect-Failure {Invoke-ToolbeltInstall @options -DeploymentMode local} 'RECEIPT'
    $script:missingReceipt=$false;$script:clientHelp='sqlcmd version (Go)';$script:sqlCalls=0
    Expect-Failure {Invoke-ToolbeltInstall @options -DeploymentMode local} 'CLIENT'
    Assert-Test ($script:sqlCalls -eq 0) 'wrong client refused before connection'
    $script:clientHelp='Microsoft (R) SQL Server Command Line Tool'
    Expect-Failure {Invoke-ToolbeltInstall -DeploymentMode local -PackageZip $packageZip} 'TARGET'
    Expect-Failure {Invoke-ToolbeltInstall -DeploymentMode local -ValidateOnly -PreflightOnly} 'ARGUMENT'
    $tampered=Join-Path $scratch 'tampered.zip'
    $bytes=[IO.File]::ReadAllBytes($packageZip);$bytes[100]=$bytes[100] -bxor 1;[IO.File]::WriteAllBytes($tampered,$bytes)
    $script:sqlCalls=0
    Expect-Failure {Invoke-ToolbeltInstall -DeploymentMode local -PackageZip $tampered -ValidateOnly} 'PACKAGE'
    Assert-Test ($script:sqlCalls -eq 0) 'corrupt package rejected before tool/SQL'
    [IO.File]::Delete($tampered)

    $script:expectedCredential=$true;$script:installFailure=$script:privatePassword
    $redactionFile=Join-Path $scratch 'redaction.sql';[IO.File]::WriteAllText($redactionFile,'SELECT 1;')
    $sqlCredential=[Management.Automation.PSCredential]::new('ContosoInstaller',(ConvertTo-SecureString $script:privatePassword -AsPlainText -Force))
    try {
        $redacted=Invoke-ToolbeltSql -Executable $client -Server localhost -Catalog Contoso -File $redactionFile -SqlCredential $sqlCredential -CertificateOverride $false -LoginTimeout 1 -CommandTimeout 1
        Assert-Test (-not ($redacted.Stdout+$redacted.Stderr).Contains($script:privatePassword) -and $redacted.Stderr.Contains('[REDACTED]')) 'failure diagnostics redact explicit SQL password'
    } finally {[IO.File]::Delete($redactionFile);$sqlCredential=$null;$script:expectedCredential=$false;$script:installFailure=''}

    # Derselbe Deadlinehelper muss JSON-Datumswerte alter/neuer PowerShell-
    # Versionen unabhängig von der Benutzerkultur verarbeiten.
    $adapterAst=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'Invoke-OneCallInstallLab.ps1'),[ref]$null,[ref]$null)
    $deadlineFn=@($adapterAst.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq 'Get-ReleaseTimeout'},$true))
    Assert-Test ($deadlineFn.Count -eq 1) 'one shared native deadline helper'
    . ([scriptblock]::Create($deadlineFn[0].Extent.Text))
    $savedCulture=[Threading.Thread]::CurrentThread.CurrentCulture
    try {
        foreach($culture in @('de-AT','en-US')) {
            [Threading.Thread]::CurrentThread.CurrentCulture=[Globalization.CultureInfo]::GetCultureInfo($culture)
            $end=[DateTimeOffset]::UtcNow.AddMinutes(10)
            foreach($value in @($end.ToString('o'),$end.UtcDateTime,$end)) {
                $script:runset=[pscustomobject]@{deadline_utc=$value};$script:clock=[Diagnostics.Stopwatch]::StartNew();$script:cleanup=$false;$AuditOnly=$false
                Assert-Test ((Get-ReleaseTimeout) -gt 0 -and (Get-ReleaseTimeout) -le 120) 'culture-invariant typed native deadline'
            }
        }
    }finally{[Threading.Thread]::CurrentThread.CurrentCulture=$savedCulture}

    # Die tatsächliche Prozessgrenze ohne SQL prüfen: Startfehler, Timeout,
    # beidseitige Ausgabe und Exitcode. Die Fakes oben beweisen keine Anmeldung.
    Set-Item Function:Invoke-ToolbeltNativeProcess $nativeImplementation
    $start=[Diagnostics.ProcessStartInfo]::new((Join-Path $scratch 'missing-client.exe'))
    $start.UseShellExecute=$false;$start.RedirectStandardOutput=$true;$start.RedirectStandardError=$true
    Expect-Failure {Invoke-ToolbeltNativeProcess $start 1} 'CLIENT_START'
    $start=[Diagnostics.ProcessStartInfo]::new($client)
    $start.UseShellExecute=$false;$start.RedirectStandardOutput=$true;$start.RedirectStandardError=$true
    foreach($arg in @('-NoProfile','-Command',"[Console]::Out.Write('synthetic-out');[Console]::Error.Write('synthetic-err');exit 7")){$start.ArgumentList.Add($arg)}
    $r=Invoke-ToolbeltNativeProcess $start 10
    Assert-Test ($r.ExitCode -eq 7 -and $r.Stdout -ceq 'synthetic-out' -and $r.Stderr -ceq 'synthetic-err') 'real process output and exit code'
    $start.ArgumentList.Clear()
    foreach($arg in @('-NoProfile','-Command','Start-Sleep -Seconds 30')){$start.ArgumentList.Add($arg)}
    Expect-Failure {Invoke-ToolbeltNativeProcess $start 1} 'TIMEOUT'
} finally {
    [Environment]::SetEnvironmentVariable('SQLCMDPASSWORD',$savedPassword,'Process')
    [Environment]::SetEnvironmentVariable('SQLCMDINI',$savedIni,'Process')
    if([IO.File]::Exists((Join-Path $scratch 'tampered.zip'))){[IO.File]::Delete((Join-Path $scratch 'tampered.zip'))}
    [IO.Directory]::Delete($scratch,$false)
}
"PASS ONE_CALL_INSTALL: $script:assertions synthetic assertions; no SQL connection or native installation qualification"
