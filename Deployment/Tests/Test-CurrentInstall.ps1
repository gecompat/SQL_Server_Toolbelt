# Controller-Gegenproben mit synthetischem Transport; keine SQL-Verbindung.
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
$repo=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
. (Join-Path $repo 'Deployment/Toolbelt.CurrentInstall.ps1')
$temp=Join-Path $repo ('.runtime/current-install-tests-'+[guid]::NewGuid().ToString('N'))
$null=New-Item -ItemType Directory -Path $temp
$script:checks=0;$script:scenario='success';$script:sqlCalls=0;$script:captured=''
function Assert-Test([bool]$Condition,[string]$Name){if(-not $Condition){throw $Name};$script:checks++}
function Reject-Test([scriptblock]$Action,[string]$Name){$failed=$false;try{& $Action|Out-Null}catch{$failed=$true};Assert-Test $failed $Name}
function Invoke-ToolbeltNativeProcess($StartInfo,[int]$TimeoutSeconds){
    @{ExitCode=0;Stdout=$(if($script:scenario -eq 'wrong-client'){'sqlcmd Go'}else{'SQL Server Command Line Tool'});Stderr=''}
}
function Invoke-ToolbeltSql {
    param($Executable,$Server,$Catalog,$File,$SqlCredential,$CertificateOverride,$LoginTimeout,$CommandTimeout)
    $script:sqlCalls++
    $sql=[IO.File]::ReadAllText($File)
    if([IO.Path]::GetFileName($File) -eq 'prepare.sql'){
        if($script:sqlCalls -eq 1){
            $plan=@{server_name='localhost';database_name='ContosoApp';platform=$(if($script:scenario -eq 'linux'){'Linux'}else{'Windows'});
                database_guid=$(if($script:scenario -eq 'prepared-identity-mismatch'){'22222222-2222-2222-2222-222222222222'}else{$null});
                configurations=@(@{configuration_id=1562;configured=1;running=1})}
            $wire=[Convert]::ToHexString([Text.Encoding]::Unicode.GetBytes((ConvertTo-Json -InputObject $plan -Depth 8 -Compress)))
            return @{ExitCode=0;Stdout=("TBX_PREPARATION_PART|0000|$wire`nTBX_PREPARATION_PARTS|1");Stderr=''}
        }
        return @{ExitCode=0;Stdout="TBX_PREPARATION_OK`nTBX_PREPARATION_TARGET|11111111-1111-1111-1111-111111111111`nTBX_PREPARATION_CREATED_GUID|11111111-1111-1111-1111-111111111111`nTBX_PREPARATION_DATABASE_CREATED";Stderr=''}
    }
    if([IO.Path]::GetFileName($File) -eq 'preflight.sql'){
        $identity=if($script:scenario -eq 'after-preparation-replaced'){'22222222-2222-2222-2222-222222222222'}else{'11111111-1111-1111-1111-111111111111'}
        return @{ExitCode=0;Stdout=('TBX_PREFLIGHT|'+$(if($script:scenario -in 'linux','after-preparation-platform-changed'){'Linux'}else{'Windows'})+'|'+$identity);Stderr=''}
    }
    if([IO.Path]::GetFileName($File) -ne 'install.sql'){throw 'UNEXPECTED_SQL_PHASE'}
    $script:captured=$sql
    if($script:scenario -eq 'install-error'){return @{ExitCode=1;Stdout='';Stderr='TBX_SECURITY'}}
    return @{ExitCode=0;Stdout='TBX_INSTALL_OK|1';Stderr=''}
}
function New-ToolbeltPreparationJournal($Database,$Server,$Plan){
    @{Path=(Join-Path $temp 'preparation.json');Record=@{state='PREPARED';outcome='not dispatched'}}
}
try{
    $path=Join-Path $temp 'Install.sql'
    $sql="USE [ContosoToolbelt];`nDECLARE @TrustMethod varchar(24)=N'auto';`nSELECT 1;`n"
    [IO.File]::WriteAllText($path,$sql,[Text.UTF8Encoding]::new($false))
    $record=@{schema='toolbelt-markerless-install/v1';platform='Windows';mode='local';trust='auto';
        modules=@('toolbelt.core.result-table');binary_sha512=@{};sql_sha256=(Get-ToolbeltSha256 ([IO.File]::ReadAllBytes($path)));
        objects=@(@{schema='toolbelt_core';name='USP_PrepareResultTable';types='P,PC'})}
    [IO.File]::WriteAllText(($path+'.manifest.json'),(ConvertTo-Json -InputObject $record -Depth 16),[Text.UTF8Encoding]::new($false))
    $base=@{DeploymentMode='local';InstallSql=$path;ServerInstance='localhost';Database='ContosoApp';SqlcmdPath=(Get-Command pwsh).Source}
    $valid=Invoke-ToolbeltInstall @base -ValidateOnly
    Assert-Test ($valid.Status -eq 'PACKAGE_OK' -and $script:sqlCalls -eq 0) 'VALIDATE_WITHOUT_CONNECTION'
    $preflight=Invoke-ToolbeltInstall @base -PreflightOnly
    Assert-Test ($preflight.Status -eq 'PREFLIGHT_OK' -and $script:sqlCalls -eq 1) 'READONLY_PREFLIGHT'
    $script:sqlCalls=0
    $installed=Invoke-ToolbeltInstall @base -TrustMethod trustworthy
    Assert-Test ($installed.Status -eq 'INSTALLED_OR_PRESENT' -and $installed.Modules -eq 1) 'DECLARED_COMPLETION'
    Assert-Test ($script:sqlCalls -eq 2) 'ONE_INSTALL_DISPATCH'
    Assert-Test ($script:captured.Contains("DECLARE @TrustMethod varchar(24)=N'trustworthy';")) 'REQUESTED_TRUST_NO_FALLBACK'
    Assert-Test ($script:captured.Contains('database_guid=CONVERT(uniqueidentifier') -and $script:captured.Contains('sp_getapplock')) 'IDENTITY_AND_SESSION_LOCK'
    Assert-Test ($script:captured.Contains("host_platform=N'Windows'")) 'PLATFORM_REBOUND_BEFORE_DDL'
    Assert-Test ($script:captured -notmatch 'extended_properties|Toolbelt\.Module|ModuleVersion') 'NO_VERSION_MARKER_DEPENDENCY'
    $preflightText=Get-ToolbeltPreflightSql 'ContosoApp'
    Assert-Test ($preflightText -notmatch 'CONTROL SERVER|sysadmin|TBX_NOT_EMPTY|is_trustworthy_on=1') 'NO_BLANKET_ADMIN_OR_OFF_ONLY_GATE'
    Assert-Test ($preflightText.Contains("name=N'clr strict security' AND value=1 AND value_in_use=1")) 'STRICT_SECURITY_RETAINED'
    Assert-Test ((Get-ToolbeltPreflightSql 'ContosoApp' $false) -notmatch 'sys.configurations') 'SQL_ONLY_REQUIRES_NO_CLR_CONFIGURATION'
    $script:scenario='linux';$script:sqlCalls=0
    Reject-Test {Invoke-ToolbeltInstall @base -Platform Windows} 'WINDOWS_PROFILE_REJECTED_ON_LINUX'
    Assert-Test ($script:sqlCalls -eq 1) 'NO_INSTALL_AFTER_PLATFORM_REJECTION'
    $script:sqlCalls=0
    Reject-Test {Invoke-ToolbeltInstall @base -Platform Windows -CreateDatabase -EnableClr} 'PREPARE_REJECTS_WINDOWS_ON_LINUX'
    Assert-Test ($script:sqlCalls -eq 1 -and -not (Test-Path (Join-Path $temp 'preparation.json'))) 'PLATFORM_REJECTION_BEFORE_MUTATION'
    $script:scenario='success';$script:sqlCalls=0
    $central=$base.Clone();$central.DeploymentMode='central'
    Reject-Test {Invoke-ToolbeltInstall @central -CreateDatabase -EnableClr} 'PREPARE_REJECTS_WRONG_MODE'
    Assert-Test ($script:sqlCalls -eq 1 -and -not (Test-Path (Join-Path $temp 'preparation.json'))) 'MODE_REJECTION_BEFORE_MUTATION'
    $record.platform='Portable';$record.mode='central'
    [IO.File]::WriteAllText(($path+'.manifest.json'),(ConvertTo-Json -InputObject $record -Depth 16),[Text.UTF8Encoding]::new($false))
    $script:sqlCalls=0
    $portable=Invoke-ToolbeltInstall @central
    Assert-Test ($portable.Profile -ceq 'Portable-central' -and $script:sqlCalls -eq 2) 'AUTO_SINGLE_PORTABLE_PROFILE_ON_WINDOWS'
    $record.platform='Windows';$record.mode='local'
    [IO.File]::WriteAllText(($path+'.manifest.json'),(ConvertTo-Json -InputObject $record -Depth 16),[Text.UTF8Encoding]::new($false))
    $script:scenario='wrong-client';$script:sqlCalls=0
    Reject-Test {Invoke-ToolbeltInstall @base} 'NO_IMPLICIT_GO_PROVIDER'
    Assert-Test ($script:sqlCalls -eq 0) 'NO_CONNECTION_AFTER_CLIENT_REJECTION'
    $script:scenario='install-error';$script:sqlCalls=0
    Reject-Test {Invoke-ToolbeltInstall @base} 'SQL_FAILURE_PROPAGATED'
    Assert-Test ($script:sqlCalls -eq 2) 'NO_AUTOMATIC_RETRY_AFTER_FAILURE'
    Reject-Test {Invoke-ToolbeltInstall @base -ValidateOnly -PreflightOnly} 'EXCLUSIVE_CLIENT_MODES'
    $script:scenario='success';$script:sqlCalls=0
    $planning=Invoke-ToolbeltInstall @base -CreateDatabase -PreflightOnly
    Assert-Test ($planning.Status -eq 'PREPARATION_PREFLIGHT_OK' -and $script:sqlCalls -eq 1) 'PREPARATION_PLAN_WITHOUT_MUTATIONS'
    $script:sqlCalls=0
    $created=Invoke-ToolbeltInstall @base -CreateDatabase 6>$null
    Assert-Test ($created.Status -eq 'INSTALLED_OR_PRESENT' -and $script:sqlCalls -eq 4) 'PREPARATION_TO_CURRENT_INSTALL_INTEGRATION'
    $journal=Get-Content -LiteralPath (Join-Path $temp 'preparation.json') -Raw|ConvertFrom-Json
    Assert-Test ($journal.state -eq 'PREPARATION_COMPLETE' -and $journal.outcome.DatabaseCreated) 'PREPARATION_RECEIPT_JOURNALED'
    $script:scenario='prepared-identity-mismatch';$script:sqlCalls=0
    Reject-Test {Invoke-ToolbeltInstall @base -CreateDatabase -WarningAction SilentlyContinue 6>$null} 'PREPARATION_IDENTITY_MISMATCH'
    Assert-Test ($script:sqlCalls -eq 2) 'NO_INSTALL_AFTER_PREPARATION_MISMATCH'
    $script:scenario='after-preparation-replaced';$script:sqlCalls=0
    Reject-Test {Invoke-ToolbeltInstall @base -CreateDatabase 6>$null} 'IDENTITY_CHANGED_AFTER_PREPARATION'
    Assert-Test ($script:sqlCalls -eq 3) 'NO_INSTALL_ON_REPLACED_PREPARED_TARGET'
    $script:scenario='after-preparation-platform-changed';$script:sqlCalls=0
    Reject-Test {Invoke-ToolbeltInstall @base -CreateDatabase 6>$null} 'PLATFORM_CHANGED_AFTER_PREPARATION'
    Assert-Test ($script:sqlCalls -eq 3) 'NO_INSTALL_ON_CHANGED_PREPARED_PLATFORM'
    "CURRENT_INSTALL_PASS checks=$script:checks; mocked transport only"
}finally{
    $full=[IO.Path]::GetFullPath($temp);$boundary=[IO.Path]::GetFullPath((Join-Path $repo '.runtime'))+[IO.Path]::DirectorySeparatorChar
    if(-not $full.StartsWith($boundary,[StringComparison]::OrdinalIgnoreCase)){throw 'TEST_CLEANUP_SCOPE'}
    Remove-Item -LiteralPath $full -Recurse -Force
}
