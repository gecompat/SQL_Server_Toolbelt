[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ScriptDomDllPath,
    [Parameter(Mandatory)][string]$ParserReleaseDirectory,
    [string]$OutputDirectory=(Join-Path (Split-Path -Parent $PSScriptRoot) 'Artifacts')
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$moduleRoot=Split-Path -Parent $PSScriptRoot
$repoRoot=Split-Path -Parent (Split-Path -Parent $moduleRoot)
. (Join-Path $repoRoot 'Modules/toolbelt.string.edit-distance/Scripts/Invoke-OwnedProcess.ps1')
$pin=Get-Content -LiteralPath (Join-Path $moduleRoot 'Contracts/DependencyPins.json') -Raw | ConvertFrom-Json
$parserManifest=Get-Content -LiteralPath (Join-Path $ParserReleaseDirectory 'Toolbelt.Tsql.ScriptParser.trust-manifest.json') -Raw | ConvertFrom-Json
if($parserManifest.moduleVersion -cne $pin.parserVersion -or $parserManifest.sha512 -cne $pin.parserSha512 -or
 (Get-FileHash -LiteralPath (Join-Path $ParserReleaseDirectory 'Toolbelt.Tsql.ScriptParser.dll') -Algorithm SHA512).Hash -cne $pin.parserSha512 -or
 (Get-FileHash -LiteralPath $ScriptDomDllPath -Algorithm SHA512).Hash -cne $pin.scriptDomSha512){throw 'SSIS_BUILD_DEPENDENCY_PIN_MISMATCH'}
$project=Join-Path $moduleRoot 'Clr/Toolbelt.Tsql.SsisDebug.csproj'
$assembly=Join-Path $moduleRoot 'Clr/bin/Release/Toolbelt.Tsql.SsisDebug.dll'
$outputRoot=[IO.Path]::GetFullPath((Join-Path $moduleRoot 'Clr/bin'))+[IO.Path]::DirectorySeparatorChar
if([IO.Path]::GetFullPath($ScriptDomDllPath).StartsWith($outputRoot,[StringComparison]::OrdinalIgnoreCase)){throw 'SSIS_BUILD_INPUT_MUST_BE_OUTSIDE_BUILD_OUTPUT'}
$builder=Get-Command msbuild -ErrorAction SilentlyContinue
if(-not $builder){
 $vswhere=Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio/Installer/vswhere.exe'
 if(Test-Path -LiteralPath $vswhere){
  $discovery=Invoke-OwnedProcess -FileName $vswhere -Arguments @('-latest','-products','*','-requires','Microsoft.Component.MSBuild','-find','MSBuild/**/Bin/MSBuild.exe') -TimeoutMilliseconds 30000
  if($discovery.ExitCode -ne 0){throw 'SSIS_BUILD_MSBUILD_DISCOVERY_FAILED'}
  $path=($discovery.Stdout -split '\r?\n' | Where-Object {$_} | Select-Object -First 1)
  if($path){$builder=[pscustomobject]@{Source=$path}}
 }
}
if(-not $builder){throw 'SSIS_BUILD_MSBUILD_UNAVAILABLE'}
$log=Join-Path ([IO.Path]::GetTempPath()) ('ToolbeltSsisBuild-'+[guid]::NewGuid().ToString('N')+'.log')
function Build-Release {
 $build=Invoke-OwnedProcess -FileName $builder.Source -Arguments @($project,'/t:Rebuild','/p:Configuration=Release',"/p:ScriptDomDllPath=$ScriptDomDllPath",'/m:1','/v:minimal','/nologo') -TimeoutMilliseconds 120000
 [IO.File]::WriteAllText($log,$build.Stdout+"`n"+$build.Stderr,[Text.UTF8Encoding]::new($false))
 if($build.ExitCode -ne 0){throw 'SSIS_RELEASE_BUILD_FAILED_PRIVATE_LOG_AVAILABLE'}
 if([Reflection.AssemblyName]::GetAssemblyName($assembly).Version.ToString() -cne '1.0.0.0'){throw 'SSIS_RELEASE_ASSEMBLY_VERSION_MISMATCH'}
}
Build-Release
$first=(Get-FileHash -LiteralPath $assembly -Algorithm SHA512).Hash
Build-Release
if((Get-FileHash -LiteralPath $assembly -Algorithm SHA512).Hash -cne $first){throw 'SSIS_BUILD_NOT_REPRODUCIBLE'}
function Fingerprint([string[]]$Entries){
 $h=[Security.Cryptography.SHA256]::Create()
 try{[BitConverter]::ToString($h.ComputeHash([Text.Encoding]::UTF8.GetBytes(($Entries -join "`n")))).Replace('-','')}finally{$h.Dispose()}
}
$sources=@(Get-ChildItem -LiteralPath (Join-Path $moduleRoot 'Clr') -Recurse -File | Where-Object {$_.Extension -in '.cs','.csproj' -and $_.FullName -notmatch '[\\/](bin|obj|\.runtime)[\\/]'} | Sort-Object {$_.FullName.Substring($moduleRoot.Length).Replace('\','/')} | ForEach-Object {$_.FullName.Substring($moduleRoot.Length+1).Replace('\','/')+':'+(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash})
$shared=Join-Path (Split-Path -Parent $moduleRoot) 'toolbelt.tsql.script-parser/Clr/PreparseGuardCore.cs'
$sources += @(Get-ChildItem -LiteralPath (Join-Path $moduleRoot 'Exchange/Core') -File -Filter '*.cs' | Sort-Object Name | ForEach-Object {'Exchange/Core/'+$_.Name+':'+(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash})
$sources += '../toolbelt.tsql.script-parser/Clr/PreparseGuardCore.cs:'+(Get-FileHash -LiteralPath $shared -Algorithm SHA256).Hash
$deployment=@(foreach($folder in @('Contracts','Source','Deployment','Scripts')){
 # Paketpins binden dieses Manifest erst nach der nativen Qualifikation.
 # Sie und der reine ZIP-Packer sind keine CLR-/SQL-Deploymentinputs; ihre Aufnahme wäre zyklisch.
 Get-ChildItem -LiteralPath (Join-Path $moduleRoot $folder) -File | Where-Object {($folder+'/'+$_.Name) -cnotin @('Contracts/InstallPackageInputs.json','Scripts/New-InstallPackage.py')} | Sort-Object Name | ForEach-Object {$folder+'/'+$_.Name+':'+(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash}
})
function Expand-Includes([string]$Path){
 $text=Get-Content -LiteralPath $Path -Raw
 [regex]::Replace($text,'(?m)^:r\s+([^\r\n]+)\s*$',{param($m)
  $target=[IO.Path]::GetFullPath((Join-Path (Split-Path -Parent $Path) $m.Groups[1].Value.Trim()))
  if(-not $target.StartsWith([IO.Path]::GetFullPath($moduleRoot)+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'SSIS_INCLUDE_OUTSIDE_MODULE'}
  Expand-Includes $target
 })
}
function Procedure-Definition([string]$Name){
 $source=Get-Content -LiteralPath (Join-Path $moduleRoot ('Source/'+$Name+'.sql')) -Raw
 $start=$source.IndexOf('CREATE OR ALTER PROCEDURE',[StringComparison]::Ordinal)
 if($start -lt 0){throw 'SSIS_CANONICAL_PROCEDURE_MISSING'}
 $definition=[regex]::Replace($source.Substring($start),'(?i)\r?\nGO\s*\z','')
 "N'"+$definition.Replace("'","''")+"'"
}
$bits='0x'+[BitConverter]::ToString([IO.File]::ReadAllBytes($assembly)).Replace('-','')
$deploy=Expand-Includes (Join-Path $moduleRoot 'Deployment/Deploy.sql')
$deploy=$deploy.Replace('$(AssemblyBits)',$bits).Replace('$(ExpectedAssemblySha512)','0x'+$first).Replace('$(PublicProcedureSql)',(Procedure-Definition 'USP_ExplainSsisDataFlow')).Replace('$(InternalProcedureSql)',(Procedure-Definition 'USP_ExplainSsisDataFlowInternal'))
if($deploy -match '(?m)^:r\s' -or $deploy.Replace('$(DeploymentMode)','') -match '\$\('){throw 'SSIS_UNRESOLVED_RELEASE_INPUT'}
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$deployPath=Join-Path $OutputDirectory 'Deploy.WithAssembly.sql'
$encoding=[Text.UTF8Encoding]::new($false)
[IO.File]::WriteAllText($deployPath,$deploy,$encoding)
[IO.File]::WriteAllText((Join-Path $OutputDirectory 'Uninstall.Expanded.sql'),(Expand-Includes (Join-Path $moduleRoot 'Deployment/Uninstall.sql')),$encoding)
Copy-Item -LiteralPath $assembly -Destination (Join-Path $OutputDirectory 'Toolbelt.Tsql.SsisDebug.dll') -Force
$manifest=[ordered]@{
 schemaVersion=1;moduleId='toolbelt.tsql.ssis-debug';moduleVersion='1.0.0';buildProfile='net48-anycpu-release-deterministic'
 sha512=$first;scriptDomSha512=$pin.scriptDomSha512;parserVersion=$pin.parserVersion;parserSha512=$pin.parserSha512
 sourceFingerprintSha256=(Fingerprint $sources);sourceFiles=$sources
 deploymentFingerprintSha256=(Fingerprint $deployment);deploymentFiles=$deployment
 deploymentArtifactSha256=(Get-FileHash -LiteralPath $deployPath -Algorithm SHA256).Hash
 reproducedBuild=$true;permissionSet='UNSAFE';directFrameworkReferences=@('System','System.Core','System.Data','System.Xml','System.Xml.Linq')
 guardProfile=[ordered]@{atoms=4096;rawUnits=65536;structure=32;comments=16;operators=256;queryOperators=64;tokens=65536;astDepth=100;nodes=65536;properties=262144}
}
[IO.File]::WriteAllText((Join-Path $OutputDirectory 'Toolbelt.Tsql.SsisDebug.trust-manifest.json'),($manifest|ConvertTo-Json -Depth 6),$encoding)
'SSIS_RELEASE_BUILD_PASS reproducible net48; no SQL executed'
