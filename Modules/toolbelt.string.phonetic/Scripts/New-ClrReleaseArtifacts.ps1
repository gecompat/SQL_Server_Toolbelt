[CmdletBinding()]
param([Parameter(Mandatory)][string]$MSBuildPath,[Parameter(Mandatory)][string]$OutputDirectory)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$moduleRoot=Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'Invoke-OwnedProcess.ps1')
if(-not [IO.File]::Exists($MSBuildPath)){throw 'PHONETIC_BUILD_TOOL'}
if(Test-Path -LiteralPath $OutputDirectory){throw 'PHONETIC_BUILD_OUTPUT_EXISTS'}
$sourcePaths=@('Clr/Toolbelt.String.Phonetic.csproj','Clr/Properties/AssemblyInfo.cs',
 'Clr/PhoneticInput.cs','Clr/PhoneticBridge.cs','Clr/CologneKernel.cs','Clr/DoubleMetaphoneKernel.cs',
 'Source/TVF_ColognePhonetic.sql','Source/TVF_DoubleMetaphone.sql',
 'Source/TVF_ColognePhoneticCore.sql','Source/TVF_DoubleMetaphoneCore.sql',
 'Deployment/Deploy.sql','Deployment/Uninstall.sql','Deployment/Preflight.sql',
 'Deployment/MarkRelease.sql','Deployment/Add-TrustedAssembly.sql','Scripts/New-ClrReleaseArtifacts.ps1','Scripts/Invoke-OwnedProcess.ps1',
 'ThirdParty/ApacheCommonsCodec/LICENSE.txt','ThirdParty/ApacheCommonsCodec/NOTICE.txt')
function Get-SourcePins { foreach($relative in $sourcePaths){[ordered]@{path=$relative;sha256=(Get-FileHash -LiteralPath (Join-Path $moduleRoot $relative) -Algorithm SHA256).Hash}} }
$pins=@(Get-SourcePins);$before=ConvertTo-Json -InputObject $pins -Compress
$toolHash=(Get-FileHash -LiteralPath $MSBuildPath -Algorithm SHA256).Hash
$project=Join-Path $moduleRoot 'Clr/Toolbelt.String.Phonetic.csproj'
$arguments=@($project,'/t:Rebuild','/p:Configuration=Release','/p:Platform=AnyCPU','/m:1','/nr:false','/noAutoResponse','/p:UseSharedCompilation=false')
$result=Invoke-OwnedProcess -FileName $MSBuildPath -Arguments $arguments -TimeoutMilliseconds 120000
if(-not $result.CaptureComplete -or $result.ExitCode -ne 0){throw 'PHONETIC_BUILD_FAILED'}
if((ConvertTo-Json -InputObject @(Get-SourcePins) -Compress) -cne $before -or
 (Get-FileHash -LiteralPath $MSBuildPath -Algorithm SHA256).Hash -cne $toolHash){throw 'PHONETIC_BUILD_PIN_DRIFT'}
$dll=Join-Path $moduleRoot 'Clr/bin/Release/Toolbelt.String.Phonetic.dll'
$bytes=[IO.File]::ReadAllBytes($dll)
function Digest([byte[]]$value,[string]$algorithm){$hash=[Security.Cryptography.HashAlgorithm]::Create($algorithm);try{[BitConverter]::ToString($hash.ComputeHash($value)).Replace('-','')}finally{$hash.Dispose()}}
$sha256=Digest $bytes 'SHA256';$sha512=Digest $bytes 'SHA512'
if((Get-FileHash -LiteralPath $dll -Algorithm SHA256).Hash -cne $sha256){throw 'PHONETIC_BUILD_BINARY_DRIFT'}
$identity=[Reflection.AssemblyName]::GetAssemblyName($dll)
if($identity.Name -cne 'Toolbelt.String.Phonetic' -or $identity.Version.ToString() -cne '1.0.0.0'){throw 'PHONETIC_BUILD_IDENTITY'}
if((Get-FileHash -LiteralPath $dll -Algorithm SHA256).Hash -cne $sha256){throw 'PHONETIC_BUILD_BINARY_DRIFT'}
[void][IO.Directory]::CreateDirectory($OutputDirectory)
$utf8=[Text.UTF8Encoding]::new($false)
function Save-New([string]$name,[byte[]]$data){$stream=[IO.File]::Open((Join-Path $OutputDirectory $name),[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None);try{$stream.Write($data,0,$data.Length)}finally{$stream.Dispose()}}
Save-New 'Toolbelt.String.Phonetic.dll' $bytes
Save-New 'Build.stdout.txt' ($utf8.GetBytes($result.Stdout))
Save-New 'Build.stderr.txt' ($utf8.GetBytes($result.Stderr))
# Kein qualifiziertes Binary wird aus einem Build-Ergebnis allein abgeleitet.
$manifest=[ordered]@{schemaVersion='1.0';moduleId='toolbelt.string.phonetic';moduleVersion='1.0.0';assemblySqlName='Toolbelt_String_Phonetic';assemblyFileName='Toolbelt.String.Phonetic.dll';permissionSet='SAFE';directFrameworkReferences=@('System','System.Data');sha256=$sha256;sha512=$sha512;sqlServerHexLiteral=('0x'+$sha512);managedIdentity=$identity.FullName;sourceFingerprints=$pins;buildOnly=$true;offlineQualified=$false;sqlQualified=$false}
Save-New 'Toolbelt.String.Phonetic.trust-manifest.json' ($utf8.GetBytes((ConvertTo-Json -InputObject $manifest -Depth 8)))
$deploy=[IO.File]::ReadAllText((Join-Path $moduleRoot 'Deployment/Deploy.sql'),$utf8)
if([regex]::Matches($deploy,[regex]::Escape('$(AssemblyBits)')).Count -ne 1){throw 'PHONETIC_BUILD_BITS_PLACEHOLDER'}
$deploy=$deploy.Replace('$(AssemblyBits)','0x'+[BitConverter]::ToString($bytes).Replace('-',''))
[void][IO.Directory]::CreateDirectory((Join-Path $OutputDirectory 'Deployment'))
[void][IO.Directory]::CreateDirectory((Join-Path $OutputDirectory 'Source'))
foreach($relative in @('Deployment/Preflight.sql','Deployment/MarkRelease.sql','Deployment/Uninstall.sql','Deployment/Add-TrustedAssembly.sql','Source/TVF_ColognePhonetic.sql','Source/TVF_DoubleMetaphone.sql','Source/TVF_ColognePhoneticCore.sql','Source/TVF_DoubleMetaphoneCore.sql')){
 Save-New $relative ([IO.File]::ReadAllBytes((Join-Path $moduleRoot $relative)))
}
Save-New 'Deployment/Deploy.WithAssembly.sql' ($utf8.GetBytes($deploy))
# Vollständiges SQLCMD-Paket: alle referenzierten Include-Bytes sind gebunden.
if((ConvertTo-Json -InputObject @(Get-SourcePins) -Compress) -cne $before -or (Get-FileHash -LiteralPath $dll -Algorithm SHA256).Hash -cne $sha256){throw 'PHONETIC_BUILD_FINAL_DRIFT'}
Write-Output 'PASS PHONETIC_BUILD_ONLY'