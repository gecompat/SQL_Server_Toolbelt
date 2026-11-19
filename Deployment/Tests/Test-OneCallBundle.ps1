# Paketierter Kontext: tatsächlicher Einstieg, synthetischer Client, kein SQL/Netzwerk.
[CmdletBinding()]
param([Parameter(Mandatory)][string]$BundleRoot)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
. (Join-Path $BundleRoot 'Deployment/Install-Toolbelt.ps1') -DeploymentMode local
function Invoke-WebRequest { throw 'BUNDLE_NETWORK_ACCESS_FORBIDDEN' }
$script:bundleCalls=0;$script:bundlePlatform='Windows';$script:bundleModules=45
function Invoke-ToolbeltNativeProcess([Diagnostics.ProcessStartInfo]$StartInfo,[int]$TimeoutSeconds){
    if($StartInfo.ArgumentList.Contains('-?')){return @{ExitCode=0;Stdout='Microsoft (R) SQL Server Command Line Tool';Stderr=''}}
    $script:bundleCalls++
    $arguments=@($StartInfo.ArgumentList)
    if(-not $arguments.Contains('-E') -or -not $arguments.Contains('-N') -or -not $arguments.Contains('-b')){throw 'BUNDLE_CLIENT_FLAGS'}
    $file=$arguments[[array]::IndexOf($arguments,'-i')+1]
    if([IO.Path]::GetFileName($file) -eq 'preflight.sql'){
        return @{ExitCode=0;Stdout="TBX_PREFLIGHT|$script:bundlePlatform|00000000-0000-0000-0000-000000000001";Stderr=''}
    }
    $sql=[IO.File]::ReadAllText($file)
    if(-not $sql.Contains('TBX_RECEIPT') -or -not $sql.Contains('sp_add_trusted_assembly')){throw 'BUNDLE_INSTALL_FLOW'}
    return @{ExitCode=0;Stdout="TBX_INSTALL_OK|$script:bundleModules";Stderr=''}
}
$client=(Get-Command pwsh -CommandType Application|Select-Object -First 1).Source
foreach($platform in @('Windows','Linux')){
    foreach($mode in @('local','central')){
        $script:bundlePlatform=$platform;$script:bundleCalls=0
        $script:bundleModules=if($platform -eq 'Linux'){41}elseif($mode -eq 'local'){45}else{43}
        # Kein PackageZip übergeben: ausschließlich die lokale Auflösung aus dem
        # entpackten Lieferlayout muss funktionieren. Download ist oben gesperrt.
        $result=Invoke-ToolbeltInstall -DeploymentMode $mode -ServerInstance localhost -Database ContosoBundleTest -SqlcmdPath $client
        $profile=($(if($platform -eq 'Linux'){'Portable'}else{'Windows'}))+"-$mode"
        if($result.Status -cne 'INSTALLED' -or $result.Profile -cne $profile -or $result.Modules -ne $script:bundleModules -or $script:bundleCalls -ne 2){throw 'BUNDLE_PROFILE_RECEIPT'}
    }
}
'PASS ONE_CALL_BUNDLE_CONTEXT four profiles from extracted layout; no network, SQL or repackaged runtime code'
