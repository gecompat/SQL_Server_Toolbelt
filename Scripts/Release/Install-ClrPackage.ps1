[CmdletBinding()]
param(
 [string]$PackageRoot=$PSScriptRoot,
 [ValidateSet('Windows-local','Windows-central','Portable-local','Portable-central')][string]$Profile='Windows-local',
 [ValidateSet('Install','Repeat','Uninstall','UninstallAbsent')][string]$Action='Install',
 [string]$ServerInstance,[string]$Database,[string]$SqlcmdPath='sqlcmd',
 [switch]$ValidateOnly,[switch]$RegisterExactTrust,[switch]$TrustServerCertificate,[switch]$ConfirmNoExternalConsumers
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if($PSVersionTable.PSVersion.Major -lt 7){throw 'CLR_PACKAGE_POWERSHELL7_REQUIRED'}
$root=[IO.Path]::GetFullPath($PackageRoot)
$metadata=Get-Content -LiteralPath (Join-Path $root 'CLR-PACKAGE.json') -Raw|ConvertFrom-Json -AsHashtable
if($metadata.state -cne 'prepared_not_published' -or $metadata.publication_authorized -ne $false){throw 'CLR_PACKAGE_STATE'}
# Erst sämtliche Paketdateien prüfen, dann Toolauswahl oder SQL. Der äußere
# ZIP-Hash wird zuvor entsprechend START-HERE separat verglichen.
foreach($name in $metadata.files.Keys){
 if($name -match '\\|(^|/)\.\.(/|$)' -or [IO.Path]::IsPathRooted($name)){throw 'CLR_PACKAGE_PATH'}
 $path=[IO.Path]::GetFullPath((Join-Path $root $name))
 if(-not $path.StartsWith($root.TrimEnd('\','/')+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'CLR_PACKAGE_PATH'}
 $item=Get-Item -LiteralPath $path -Force
 if($item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or $item.Length -ne $metadata.files[$name].size -or
    (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ine $metadata.files[$name].sha256){throw 'CLR_PACKAGE_FILE_HASH'}
}
if($ValidateOnly){'PASS CLR_PACKAGE_VALIDATE_ONLY; no sqlcmd or SQL';return}
if([string]::IsNullOrWhiteSpace($ServerInstance) -or [string]::IsNullOrWhiteSpace($Database)){throw 'CLR_PACKAGE_TARGET_REQUIRED'}
if($Action -like 'Uninstall*' -and -not $ConfirmNoExternalConsumers){throw 'CLR_PACKAGE_EXPLICIT_CONSUMER_CONFIRMATION_REQUIRED'}
$sqlcmd=Get-Command -Name $SqlcmdPath -CommandType Application -ErrorAction Stop
function Invoke-ClREntry([string]$Path,[string]$Catalog){
 $arguments=@('-S',$ServerInstance,'-d',$Catalog,'-E','-N','-b','-i',$Path)
 if($TrustServerCertificate){$arguments+=@('-C')}
 & $sqlcmd.Source @arguments
 if($LASTEXITCODE -ne 0){throw 'CLR_PACKAGE_SQLCMD_FAILED_STOP'}
}
if($RegisterExactTrust){Invoke-ClREntry (Join-Path $root "SQL/Trust-$Profile.sql") 'master'}
Invoke-ClREntry (Join-Path $root "SQL/$Action-$Profile.sql") $Database
'PASS CLR_PACKAGE_ACTION_COMPLETED; inspect installation and module-specific results'
