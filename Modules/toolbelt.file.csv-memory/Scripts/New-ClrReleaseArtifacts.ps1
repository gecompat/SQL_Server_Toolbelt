[CmdletBinding()]
param(
 [Parameter(Mandatory)][string]$AssemblyPath,
 [Parameter(Mandatory)][ValidatePattern('^[A-Fa-f0-9]{64}$')][string]$ExpectedAssemblySHA256,
 [string]$OutputDirectory=(Join-Path (Split-Path -Parent $PSScriptRoot) 'Artifacts')
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
# Build/Framework/IL sind eigenständige Nachweise. Dieser Generator startet
# keinen Compiler, konsumiert nur das ausdrücklich gepinnte Buildbinary.
$module=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$assembly=(Resolve-Path -LiteralPath $AssemblyPath).Path
$output=[IO.Path]::GetFullPath($OutputDirectory)
function Get-CsvReleaseSources {
 @(Get-ChildItem -LiteralPath (Join-Path $module 'Clr') -File -Recurse | Where-Object {$_.Extension -in @('.cs','.csproj') -and $_.FullName -notmatch '[\\/](bin|obj)[\\/]'})+
 @(Get-ChildItem -LiteralPath (Join-Path $module 'Source') -File -Filter '*.sql')+
 @(Get-ChildItem -LiteralPath (Join-Path $module 'Deployment') -File -Filter '*.sql')+
 @(Get-ChildItem -LiteralPath $PSScriptRoot -File -Filter '*.ps1')
}
$sourcePaths=@(Get-CsvReleaseSources)
$pins=@{};$fingerprints=@()
foreach($file in @($sourcePaths|Sort-Object FullName)){
 $hash=(Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
 $pins[$file.FullName]=$hash
 $fingerprints+=@([ordered]@{path=[IO.Path]::GetRelativePath($module,$file.FullName).Replace([IO.Path]::DirectorySeparatorChar,[char]'/');sha256=$hash})
}
function Assert-CsvSourcePins {
 if((@(Get-CsvReleaseSources|ForEach-Object FullName|Sort-Object) -join '|') -cne (@($pins.Keys|Sort-Object) -join '|')){throw 'CSV_RELEASE_SOURCE_SET_CHANGED'}
 foreach($path in $pins.Keys){if((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -cne $pins[$path]){throw 'CSV_RELEASE_SOURCE_CHANGED'}}
}
function Expand-CsvDeploy([string]$Path){
 $full=[IO.Path]::GetFullPath($Path)
 if(-not $pins.ContainsKey($full)){throw 'CSV_RELEASE_UNPINNED_INCLUDE'}
 $sql=[IO.File]::ReadAllText($full)
 return [regex]::Replace($sql,'(?im)^\s*:r\s+([^\r\n]+)\s*$',{param($match) Expand-CsvDeploy (Join-Path ([IO.Path]::GetDirectoryName($full)) $match.Groups[1].Value.Trim())})
}
Assert-CsvSourcePins
if((Get-FileHash -LiteralPath $assembly -Algorithm SHA256).Hash -cne $ExpectedAssemblySHA256.ToUpperInvariant()){throw 'CSV_RELEASE_BINARY_PIN'}
$identity=[Reflection.AssemblyName]::GetAssemblyName($assembly)
if($identity.Name -cne 'Toolbelt.File.CsvMemory' -or $identity.Version.ToString() -cne '1.0.0.0'){throw 'CSV_RELEASE_ASSEMBLY_IDENTITY'}
$bytes=[IO.File]::ReadAllBytes($assembly)
$sha256=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes))
if($sha256 -cne $ExpectedAssemblySHA256.ToUpperInvariant()){throw 'CSV_RELEASE_BINARY_SNAPSHOT_PIN'}
$sha512=[Convert]::ToHexString([Security.Cryptography.SHA512]::HashData($bytes))
$deploy=Expand-CsvDeploy (Join-Path $module 'Deployment/Deploy.sql')
$marker='$(AssemblyBits)'
if([regex]::Matches($deploy,[regex]::Escape($marker)).Count-ne1){throw 'CSV_RELEASE_ASSEMBLY_MARKER'}
$deploy=$deploy.Replace($marker,'0x'+[Convert]::ToHexString($bytes))
$description='SQL Server Toolbelt toolbelt.file.csv-memory SAFE provider 1.0.0'
$manifest=[ordered]@{schemaVersion='1.0';moduleId='toolbelt.file.csv-memory';moduleVersion='1.0.0';assemblySqlName='Toolbelt_File_CsvMemory';assemblyFileName='Toolbelt.File.CsvMemory.dll';permissionSet='SAFE';directFrameworkReferences=@('System','System.Data');directModuleReferences=@();sha256=$sha256;sha512=$sha512;sqlServerHexLiteral='0x'+$sha512;description=$description;sourceFingerprints=$fingerprints}
Assert-CsvSourcePins
$binaryOutput=Join-Path $output 'Toolbelt.File.CsvMemory.dll'
if([IO.Path]::GetFullPath($binaryOutput) -ieq [IO.Path]::GetFullPath($assembly)){throw 'CSV_RELEASE_INPUT_OUTPUT_ALIAS'}
if(Test-Path -LiteralPath $output){
 if(-not (Test-Path -LiteralPath $output -PathType Container) -or @(Get-ChildItem -LiteralPath $output -Force).Count-ne0){throw 'CSV_RELEASE_OUTPUT_NOT_EMPTY'}
}else{New-Item -ItemType Directory -Path $output|Out-Null}
function Write-CsvNewArtifact([string]$Path,[byte[]]$Content){
 $stream=[IO.File]::Open($Path,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
 try{$stream.Write($Content,0,$Content.Length)}finally{$stream.Dispose()}
}
Write-CsvNewArtifact $binaryOutput $bytes
Write-CsvNewArtifact (Join-Path $output 'Toolbelt.File.CsvMemory.trust-manifest.json') ([Text.UTF8Encoding]::new($false).GetBytes(($manifest|ConvertTo-Json -Depth 6)))
Write-CsvNewArtifact (Join-Path $output 'Deploy.WithAssembly.sql') ([Text.UTF8Encoding]::new($false).GetBytes($deploy))
if((Get-FileHash -LiteralPath $binaryOutput -Algorithm SHA512).Hash -cne $sha512){throw 'CSV_RELEASE_OUTPUT_PIN'}
Assert-CsvSourcePins
if((Get-FileHash -LiteralPath $assembly -Algorithm SHA256).Hash -cne $sha256){throw 'CSV_RELEASE_INPUT_CHANGED'}
[pscustomobject]@{AssemblyPath=$binaryOutput;TrustManifestPath=(Join-Path $output 'Toolbelt.File.CsvMemory.trust-manifest.json');DeployScriptPath=(Join-Path $output 'Deploy.WithAssembly.sql');AssemblyHash='0x'+$sha512;AssemblyDescription=$description}
