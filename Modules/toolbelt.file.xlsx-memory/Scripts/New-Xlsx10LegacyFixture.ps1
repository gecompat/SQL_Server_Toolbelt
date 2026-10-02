[CmdletBinding()]
param([Parameter(Mandatory)][string]$OutputDirectory)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
# Originaler öffentlicher 1.0-Release, keine nachträgliche Source- oder Markerkorrektur.
$revision='fdafa8038e4d5240dd727096f144c8d5fd884117'
$destination=[IO.Path]::GetFullPath($OutputDirectory)
if(Test-Path -LiteralPath $destination){throw 'Legacyziel existiert; kein Überschreiben.'}
[void](New-Item -ItemType Directory -Path $destination)
$archive=Join-Path $destination 'original.zip'
$git=[Diagnostics.ProcessStartInfo]::new('git')
$git.UseShellExecute=$false;$git.CreateNoWindow=$true;$git.RedirectStandardOutput=$true;$git.RedirectStandardError=$true
$git.Arguments='archive --format=zip "--output='+$archive+'" '+$revision+' Modules/toolbelt.file.xlsx-memory Modules/toolbelt.archive.zip-memory'
$process=[Diagnostics.Process]::Start($git)
$gitOutput=$process.StandardOutput.ReadToEndAsync();$gitErrors=$process.StandardError.ReadToEndAsync()
if(-not $process.WaitForExit(30000)){$process.Kill();throw 'Originalgitarchive überschritt Deadline.'}
$exit=$process.ExitCode;$stdout=$gitOutput.GetAwaiter().GetResult();$stderr=$gitErrors.GetAwaiter().GetResult();$process.Dispose()
if($exit){throw 'Exakter öffentlicher Legacycommit fehlt; kein Fallback.'}
$source=Join-Path $destination 'original'
Expand-Archive -LiteralPath $archive -DestinationPath $source
$legacy=Join-Path $source 'Modules/toolbelt.file.xlsx-memory'
if((Get-Content -LiteralPath (Join-Path $legacy 'module.yaml') -Raw) -notmatch '(?m)^version: "1\.0\.0"\s*$'){throw 'Gepinnter Originalrelease ist nicht XLSX1.0.'}
$files=@('Deployment/Deploy.sql','Deployment/Uninstall.sql','Source/TVF_InternalXlsxSheets.sql','Source/TVF_InternalXlsxCells.sql',
 'Source/USP_InternalXlsxRead.sql','Source/USP_ListXlsxWorksheets.sql','Source/USP_ReadXlsxWorksheetCells.sql',
 'Clr/Workbook.cs','Clr/XlsxEntryPoints.cs','Clr/AssemblyInfo.cs','Clr/Toolbelt.File.XlsxMemory.csproj','Scripts/New-ClrReleaseArtifacts.ps1')
$pins=[ordered]@{}
foreach($relative in $files){
 $repoPath='Modules/toolbelt.file.xlsx-memory/'+$relative
 $expected=(& git rev-parse ($revision+':'+$repoPath)).Trim()
 if($LASTEXITCODE){throw 'Legacyblob fehlt.'}
 $actual=(& git hash-object --no-filters (Join-Path $legacy $relative)).Trim()
 if($LASTEXITCODE -or $actual -cne $expected){throw 'Legacydatei ist nicht der bytegleiche Originalblob.'}
 $pins[$relative]=[ordered]@{gitBlob=$expected;sha256=(Get-FileHash -LiteralPath (Join-Path $legacy $relative) -Algorithm SHA256).Hash}
}
foreach($module in @('toolbelt.archive.zip-memory','toolbelt.file.xlsx-memory')){
 $script=Join-Path $source ('Modules/'+$module+'/Scripts/New-ClrReleaseArtifacts.ps1')
 $start=[Diagnostics.ProcessStartInfo]::new((Get-Command pwsh).Source)
 $start.UseShellExecute=$false;$start.CreateNoWindow=$true;$start.RedirectStandardOutput=$true;$start.RedirectStandardError=$true
 $start.Arguments='-NoProfile -File "'+$script+'"'
 $child=[Diagnostics.Process]::Start($start)
 $readOutput=$child.StandardOutput.ReadToEndAsync();$readErrors=$child.StandardError.ReadToEndAsync()
 if(-not $child.WaitForExit(60000)){$child.Kill();throw 'Originalframeworkbuild überschritt Deadline.'}
 $buildExit=$child.ExitCode;$buildOutput=$readOutput.GetAwaiter().GetResult();$buildErrors=$readErrors.GetAwaiter().GetResult();$child.Dispose()
 if($buildExit){throw 'Originalframeworkbuild fehlgeschlagen.'}
}
$manifest=Get-Content -LiteralPath (Join-Path $legacy 'Artifacts/Toolbelt.File.XlsxMemory.trust-manifest.json') -Raw|ConvertFrom-Json
$binary=Join-Path $legacy 'Artifacts/Toolbelt.File.XlsxMemory.dll'
if($manifest.moduleVersion -cne '1.0.0' -or (Get-FileHash -LiteralPath $binary -Algorithm SHA512).Hash -cne $manifest.sha512){throw 'Genuine1.0-Binarymanifest ist nicht kohärent.'}
[ordered]@{revision=$revision;sourcePins=$pins;assemblySHA512=$manifest.sha512;moduleVersion='1.0.0'}|
 ConvertTo-Json -Depth 5|Set-Content -LiteralPath (Join-Path $destination 'LegacyProvenance.json') -Encoding utf8
Write-Output 'PASS: bytegleiche genuine XLSX1.0-Source und Originalbuild; SQL-Upgrade nicht ausgeführt.'
