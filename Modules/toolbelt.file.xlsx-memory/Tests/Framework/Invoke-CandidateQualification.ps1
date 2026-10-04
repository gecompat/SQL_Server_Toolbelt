# Consume supplied release artifacts; compile only separate test adapters.
[CmdletBinding()]
param([Parameter(Mandatory)][string]$XlsxDirectory,
      [Parameter(Mandatory)][string]$ZipDirectory,
      [Parameter(Mandatory)][string]$OutputDirectory,
      [string]$CompilerPath)
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
$repoRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../..'))
$EvidenceDirectory=[IO.Path]::GetFullPath($OutputDirectory)
if([IO.Directory]::Exists($EvidenceDirectory)-or[IO.File]::Exists($EvidenceDirectory)){throw 'OUTPUT_NOT_FRESH'}
$allPins=@();$artifacts=[Collections.Generic.List[object]]::new()
function Digest([byte[]]$bytes,[string]$kind='SHA256'){$h=[Security.Cryptography.HashAlgorithm]::Create($kind);try{return [BitConverter]::ToString($h.ComputeHash($bytes)).Replace('-','')}finally{$h.Dispose()}}
function Pin([string]$path){$path=[IO.Path]::GetFullPath($path);if(@($script:allPins|Where-Object {[string]::Equals($_.Path,$path,[StringComparison]::OrdinalIgnoreCase)}).Count){return $path};$bytes=[IO.File]::ReadAllBytes($path);$script:allPins+=,[pscustomobject]@{Path=$path;SHA256=(Digest $bytes)};return $path}
$ownedHelper=Pin (Join-Path $repoRoot 'Modules/toolbelt.string.edit-distance/Scripts/Invoke-OwnedProcess.ps1')
$ownedHelperSHA256=Digest ([IO.File]::ReadAllBytes($ownedHelper))
$ownedHelperBytes=[IO.File]::ReadAllBytes($ownedHelper)
if((Digest $ownedHelperBytes)-cne$ownedHelperSHA256){throw 'HELPER_CAPTURE_DRIFT'}
. ([scriptblock]::Create([Text.Encoding]::UTF8.GetString($ownedHelperBytes).TrimStart([char]0xFEFF)))
[void](Pin $PSCommandPath)
$spike=Join-Path $repoRoot 'Spikes/XlsxMemory'
$sourceMap=@{'QualificationEntryPoints.cs'=(Join-Path $spike 'QualificationEntryPoints.cs');'Sandbox.cs'=(Join-Path $spike 'Sandbox.cs');'Test-ProviderIL.ps1'=(Join-Path $spike 'Test-ProviderIL.ps1');'RawHarness.cs'=(Join-Path $PSScriptRoot 'RawCandidateHarness.cs');'TypeHarness.cs'=(Join-Path $PSScriptRoot 'TypeCandidateHarness.cs');'DisplayHarness.cs'=(Join-Path $PSScriptRoot 'DisplayCandidateHarness.cs');'DisplayTransportHarness.cs'=(Join-Path $PSScriptRoot 'DisplayTransportHarness.cs');'Test-Metadata.ps1'=(Join-Path $PSScriptRoot 'Test-CandidateMetadata.ps1');'MetadataExpectations.json'=(Join-Path $PSScriptRoot 'CandidateMetadataExpectations.json')}
foreach($path in $sourceMap.Values){[void](Pin $path)}
foreach($name in @('api-goldens.tsv','numeric-goldens.txt','display-numeric-goldens.tsv')){[void](Pin (Join-Path $PSScriptRoot $name))}
# Read each DLL once; the same snapshot binds manifest, SQL hex and test input.
function Release([string]$directory,[string]$module,[string]$assembly,[string]$version){
 $directory=[IO.Path]::GetFullPath($directory);$dll=Pin (Join-Path $directory ($assembly+'.dll'));[byte[]]$bytes=[IO.File]::ReadAllBytes($dll)
 $manifestPath=Pin (Join-Path $directory ($assembly+'.trust-manifest.json'));$manifest=[Text.Encoding]::UTF8.GetString([IO.File]::ReadAllBytes($manifestPath)).TrimStart([char]0xFEFF)|ConvertFrom-Json
 $sha512=Digest $bytes 'SHA512'
 $sqlName=if($module-ceq'toolbelt.file.xlsx-memory'){'Toolbelt_File_XlsxMemory'}else{'Toolbelt_Archive_ZipMemory'}
 if($manifest.assemblySqlName-cne$sqlName-or$manifest.moduleId-cne$module-or$manifest.moduleVersion-cne$version-or$manifest.assemblyFileName-cne($assembly+'.dll')-or$manifest.permissionSet-cne'SAFE'-or$manifest.sha512-cne$sha512-or$manifest.sqlServerHexLiteral-cne('0x'+$sha512)){throw 'RELEASE_MANIFEST_BINDING'}
 $templatePath=Pin (Join-Path $repoRoot ('Modules/'+$module+'/Deployment/Deploy.sql'));$deployPath=Pin (Join-Path $directory 'Deploy.WithAssembly.sql')
 $template=[Text.Encoding]::UTF8.GetString([IO.File]::ReadAllBytes($templatePath)).TrimStart([char]0xFEFF);$deploy=[Text.Encoding]::UTF8.GetString([IO.File]::ReadAllBytes($deployPath)).TrimStart([char]0xFEFF)
 $marker='$(AssemblyBits)';if([regex]::Matches($template,[regex]::Escape($marker)).Count-ne1-or$deploy.TrimEnd([char[]]"`r`n")-cne$template.Replace($marker,('0x'+[BitConverter]::ToString($bytes).Replace('-',''))).TrimEnd([char[]]"`r`n")){throw 'RELEASE_SQL_HEX_BINDING'}
 if($module-ceq'toolbelt.file.xlsx-memory'){
  $expectedSources=@('Clr/Toolbelt.File.XlsxMemory.csproj','Clr/AssemblyInfo.cs','Clr/Workbook.cs','Clr/XlsxEntryPoints.cs','Clr/XlsxCellType.cs','Clr/XlsxCellDisplay.cs','Clr/XlsxCellDisplayBridge.cs','Source/TVF_InternalXlsxSheets.sql','Source/TVF_InternalXlsxCells.sql','Source/USP_InternalXlsxRead.sql','Source/USP_ListXlsxWorksheets.sql','Source/USP_ReadXlsxWorksheetCells.sql','Source/TVF_InternalInterpretXlsxCell.sql','Source/TVF_InterpretXlsxCell.sql','Source/TVF_InternalFormatXlsxCell.sql','Source/TVF_FormatXlsxCell.sql','Deployment/Deploy.sql','Deployment/Uninstall.sql','Scripts/New-ClrReleaseArtifacts.ps1','Scripts/Invoke-XlsxBuildProcess.ps1')
  if(@($manifest.sourceFingerprints).Count-ne20){throw 'RELEASE_SOURCE_COUNT'}
  for($i=0;$i-lt20;$i++){if($manifest.sourceFingerprints[$i].path-cne$expectedSources[$i]){throw 'RELEASE_SOURCE_SET'}}
  foreach($entry in $manifest.sourceFingerprints){$root=[IO.Path]::GetFullPath((Join-Path $repoRoot ('Modules/'+$module)));$path=[IO.Path]::GetFullPath((Join-Path $root $entry.path));if(-not$path.StartsWith($root+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'RELEASE_SOURCE_PATH'};[void](Pin $path);if((Digest ([IO.File]::ReadAllBytes($path)))-cne$entry.sha256){throw 'RELEASE_SOURCE_DRIFT'}}
 }
 if((Digest ([IO.File]::ReadAllBytes($dll)))-cne(Digest $bytes)){throw 'RELEASE_BINARY_DRIFT'}
 return [pscustomobject]@{Path=$dll;SHA256=(Digest $bytes);SHA512=$sha512}
}
foreach($relative in @('Clr/Properties/AssemblyInfo.cs','Clr/ZipEntryProvider.cs','Clr/ZipWriter.cs','Clr/ArchiveSession.cs')){[void](Pin (Join-Path $repoRoot ('Modules/toolbelt.archive.zip-memory/'+$relative)))}
$product=Release $XlsxDirectory 'toolbelt.file.xlsx-memory' 'Toolbelt.File.XlsxMemory' '1.2.0'
$zip=Release $ZipDirectory 'toolbelt.archive.zip-memory' 'Toolbelt.Archive.ZipMemory' '1.4.0'
$ps5=Pin (Join-Path $env:WINDIR 'System32/WindowsPowerShell/v1.0/powershell.exe')
if(-not$CompilerPath){
 $command=Get-Command csc -ErrorAction SilentlyContinue
 if($command){$CompilerPath=$command.Source}else{
  $vswhere=Pin (Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio/Installer/vswhere.exe')
  $discovery=Invoke-OwnedProcess -FileName $vswhere -Arguments @('-latest','-products','*','-requires','Microsoft.Component.MSBuild','-find','MSBuild/**/Bin/Roslyn/csc.exe') -TimeoutMilliseconds 20000
  if($discovery.ExitCode-ne0-or-not$discovery.CaptureComplete-or$discovery.Stderr.Length-ne0){throw 'COMPILER_DISCOVERY'}
  $paths=@($discovery.Stdout -split '\r?\n'|Where-Object {-not[string]::IsNullOrWhiteSpace($_)});if($paths.Count-ne1){throw 'COMPILER_DISCOVERY_COUNT'};$CompilerPath=$paths[0]
 }
}
$CompilerPath=Pin $CompilerPath
$refRoot=Join-Path ${env:ProgramFiles(x86)} 'Reference Assemblies/Microsoft/Framework/.NETFramework/v4.8'
$refs=@(foreach($name in @('mscorlib','System','System.Data','System.Xml','System.Core','System.IO.Compression')){Pin (Join-Path $refRoot ($name+'.dll'))})
$binding=[pscustomobject]@{Product=$product;ProductSHA512=$product.SHA512;Zip=$zip;Compiler=$CompilerPath;PS5=$ps5;References=$refs}
[void][IO.Directory]::CreateDirectory($EvidenceDirectory);$bin=Join-Path $EvidenceDirectory 'Bin';[void][IO.Directory]::CreateDirectory($bin)

function Digest([byte[]]$bytes,[string]$kind='SHA256'){$h=[Security.Cryptography.HashAlgorithm]::Create($kind);try{return ([BitConverter]::ToString($h.ComputeHash($bytes))).Replace('-','')}finally{$h.Dispose()}}
function Check-Pins {foreach($pin in @($allPins)+@($artifacts)){if(-not[IO.File]::Exists($pin.Path)-or(Digest ([IO.File]::ReadAllBytes($pin.Path)))-cne$pin.SHA256){throw 'INPUT_OR_ARTIFACT_PIN_DRIFT'}}}
function Read-PinnedBytes([string]$path){$matches=@($allPins|Where-Object {[string]::Equals($_.Path,$path,[StringComparison]::OrdinalIgnoreCase)});if($matches.Count-ne1){throw 'CAPTURED_PIN_AUTHORITY'};$captured=[IO.File]::ReadAllBytes($path);if((Digest $captured)-cne$matches[0].SHA256){throw 'CAPTURED_PIN_DRIFT'};return ,$captured}
function Write-CapturedSnapshot([string]$path,[byte[]]$bytes){$expected=Digest $bytes;$file=$null;try{$file=[IO.File]::Open($path,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read);$file.Write($bytes,0,$bytes.Length);$file.Flush($true)}finally{if($file){$file.Dispose()}};if((Digest ([IO.File]::ReadAllBytes($path)))-cne$expected){throw 'SNAPSHOT_WRITE_DRIFT'};$artifacts.Add([pscustomobject]@{Path=$path;SHA256=$expected})}
function Require-QuietCompiler([string]$phase){if([IO.File]::ReadAllBytes((Join-Path $EvidenceDirectory ($phase+'.stdout.txt'))).Length-ne0-or[IO.File]::ReadAllBytes((Join-Path $EvidenceDirectory ($phase+'.stderr.txt'))).Length-ne0){throw 'COMPILER_CHANNEL_NOT_QUIET'}}
function Save-New([string]$name,$value){$bytes=[Text.UTF8Encoding]::new($false).GetBytes((ConvertTo-Json -InputObject $value -Depth 12));$f=$null;try{$f=[IO.File]::Open((Join-Path $EvidenceDirectory $name),[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read);$f.Write($bytes,0,$bytes.Length);$f.Flush($true)}finally{if($f){$f.Dispose()}}}
function Track([string]$path){$snapshot=[IO.File]::ReadAllBytes($path);$entry=[pscustomobject]@{Path=$path;SHA256=(Digest $snapshot)};$artifacts.Add($entry);return ,$snapshot}
function Invoke-Owned([string]$phase,[string]$exe,[string[]]$argv,[int]$seconds){
 Check-Pins
 $r=@{phase=$phase;Started=$null;Terminated=$null;TimedOut=$null;ExitCode=$null;CaptureComplete=$false;DisposePassed=$null;PostPinsPassed=$false;failure=$null;secondary=@();stdoutFile=($phase+'.stdout.txt');stderrFile=($phase+'.stderr.txt');DispositionEvidence='NOT_OBSERVED';HelperSHA256=$ownedHelperSHA256}
 $primary=$null;$returned=$false;$result=$null
 try{
  $result=Invoke-OwnedProcess -FileName $exe -Arguments $argv -TimeoutMilliseconds ($seconds*1000) -BinaryOutputPath (Join-Path $EvidenceDirectory $r.stdoutFile)
  $returned=$true
  # Normal return only after the helper observed Start+HasExited+both EOFs and its finally completed without cleanupUnsafe.
  $r.Started=$true;$r.Terminated=$true;$r.TimedOut=$false;$r.ExitCode=$result.ExitCode;$r.CaptureComplete=$result.CaptureComplete;$r.DisposePassed=$true;$r.DispositionEvidence='SUCCESSFUL_RETURN_FROM_SHARED_OWNED_HELPER'
  $errBytes=[Text.UTF8Encoding]::new($false).GetBytes($result.Stderr)
  Write-CapturedSnapshot (Join-Path $EvidenceDirectory $r.stderrFile) $errBytes
  $outBytes=[IO.File]::ReadAllBytes((Join-Path $EvidenceDirectory $r.stdoutFile));$r.StdoutSHA256=Digest $outBytes;$r.StderrSHA256=Digest $errBytes
  $artifacts.Add([pscustomobject]@{Path=(Join-Path $EvidenceDirectory $r.stdoutFile);SHA256=$r.StdoutSHA256})
  if($result.ExitCode-ne0){throw 'CHILD_EXIT_NONZERO'}
 }catch{$primary=$_;$r.failure=if($returned){'CHILD_RESULT_OR_CAPTURE_SAVE_FAILED'}else{'OWNED_HELPER_FAILED_DISPOSITION_UNKNOWN'}}finally{
  try{Check-Pins;$r.PostPinsPassed=$true}catch{$r.secondary+=,'POSTPIN_FAILED';if($null-eq$primary){$primary=$_;$r.failure='POSTPIN_FAILED'}}
  $record.phases+=,$r
  try{Save-New ($phase+'.process.json') $r}catch{$r.secondary+=,'PROCESS_RECEIPT_SAVE_FAILED';if($null-eq$primary){$primary=$_;$r.failure='PROCESS_RECEIPT_SAVE_FAILED'}}
 }
 if($null-ne$primary){throw $primary}
 if(-not$returned-or-not$r.CaptureComplete-or-not$r.PostPinsPassed-or@($r.secondary).Count-ne0){throw 'CHILD_REJECTED'}
 return $r
}

$record=@{Status='RUNNING';Scope='CONSUME_CANDIDATE_BINARY_OFFLINE_ONLY';phases=@();failure=$null;FinalPinsUnchanged=$false;ProductQualified=$false;SQLExecuted=$false;InstalledOrTrusted=$false;Cleanup='EVIDENCE_RETAINED_PROCESS_DISPOSITION_PENDING'}
function Snapshot([string]$source,[string]$target){Write-CapturedSnapshot $target (Read-PinnedBytes $source)}
function Add-OwnedArtifact([string]$path){[byte[]]$bytes=[IO.File]::ReadAllBytes($path);$artifacts.Add([pscustomobject]@{Path=$path;SHA256=(Digest $bytes)});return ,$bytes}
function Need-Output([string]$phase,[string]$expected){$out=[IO.File]::ReadAllBytes((Join-Path $EvidenceDirectory ($phase+'.stdout.txt')));$err=[IO.File]::ReadAllBytes((Join-Path $EvidenceDirectory ($phase+'.stderr.txt')));if($err.Length-ne0-or[Text.Encoding]::UTF8.GetString($out)-cne($expected+"`r`n")){throw 'EXACT_OUTPUT_REJECTED'}}
function Run-Phase([string]$phase,[string]$exe,[string[]]$argv,[int]$seconds){Save-New ($phase+'.argv.json') $argv;$r=Invoke-Owned $phase $exe $argv $seconds;if(@($r.secondary).Count-ne0-or$null-ne$r.failure){throw 'PHASE_SECONDARY'};return $r}
function Compile([string]$phase,[string]$name,[string]$source,[string]$kind){
 $output=Join-Path $bin $name;$argv=@('/nologo','/noconfig','/nostdlib+','/optimize+','/deterministic+','/langversion:7.3',('/target:'+$kind),('/out:'+$output))
 foreach($ref in $binding.References){$argv+=,('/reference:'+$ref)}
 foreach($ref in @('Toolbelt.Archive.ZipMemory.dll','Toolbelt.File.XlsxMemory.dll')){$argv+=,('/reference:'+(Join-Path $bin $ref))}
 if($phase-ceq'CompileRaw'){$argv+=,('/reference:'+(Join-Path $bin 'Toolbelt.Xlsx.Qualification.dll'))}
 $argv+=,$source;[void](Run-Phase $phase $binding.Compiler $argv 20);Require-QuietCompiler $phase;[void](Add-OwnedArtifact $output)
}
$stage='CAPTURE'
try{
 Snapshot $binding.Product.Path (Join-Path $bin 'Toolbelt.File.XlsxMemory.dll');Snapshot $binding.Zip.Path (Join-Path $bin 'Toolbelt.Archive.ZipMemory.dll')
 [byte[]]$actualProduct=[IO.File]::ReadAllBytes((Join-Path $bin 'Toolbelt.File.XlsxMemory.dll'));$actualSHA512=Digest $actualProduct 'SHA512'
 if((Digest $actualProduct)-cne$binding.Product.SHA256-or$actualSHA512-cne$binding.ProductSHA512){throw 'PRODUCT_BINARY'}
 foreach($name in @('QualificationEntryPoints.cs','RawHarness.cs','TypeHarness.cs','DisplayHarness.cs','DisplayTransportHarness.cs','Sandbox.cs','Test-Metadata.ps1','Test-ProviderIL.ps1','MetadataExpectations.json')){Snapshot $sourceMap[$name] (Join-Path $bin $name)}
 foreach($name in @('api-goldens.tsv','numeric-goldens.txt','display-numeric-goldens.tsv')){Snapshot (Join-Path $PSScriptRoot $name) (Join-Path $bin $name)}
 $stage='TEST_COMPILE'
 Compile 'CompileQualification' 'Toolbelt.Xlsx.Qualification.dll' (Join-Path $bin 'QualificationEntryPoints.cs') 'library'
 Compile 'CompileRaw' 'RawHarness.exe' (Join-Path $bin 'RawHarness.cs') 'exe'
 Compile 'CompileTypes' 'TypeHarness.exe' (Join-Path $bin 'TypeHarness.cs') 'exe'
 Compile 'CompileDisplay' 'DisplayHarness.exe' (Join-Path $bin 'DisplayHarness.cs') 'exe'
 Compile 'CompileTransport' 'DisplayTransportHarness.exe' (Join-Path $bin 'DisplayTransportHarness.cs') 'exe'
 Compile 'CompileSandbox' 'Toolbelt.Xlsx.Sandbox.exe' (Join-Path $bin 'Sandbox.cs') 'exe'
 $stage='METADATA'
 [void](Run-Phase 'Metadata' $binding.PS5 @('-NoProfile','-File',(Join-Path $bin 'Test-Metadata.ps1'),'-BinaryDirectory',$bin,'-ExpectationsPath',(Join-Path $bin 'MetadataExpectations.json')) 20);Need-Output 'Metadata' 'PASS METADATA CLR_SLOTS=4 SQL_SOURCES=9 SQL_EXECUTED=FALSE'
 $stage='TYPES_DISPLAY'
 foreach($culture in @('en-US','de-DE','tr-TR')){
  $phase='Types_'+$culture;[void](Run-Phase $phase (Join-Path $bin 'TypeHarness.exe') @((Join-Path $bin 'api-goldens.tsv'),(Join-Path $bin 'numeric-goldens.txt'),$culture) 20);Need-Output $phase 'PASS API=652 NUMERIC=370 ASSERTIONS=6437'
  $phase='Display_'+$culture;[void](Run-Phase $phase (Join-Path $bin 'DisplayHarness.exe') @((Join-Path $bin 'display-numeric-goldens.tsv'),$culture) 20);Need-Output $phase 'PASS CASES=5619'
 }
 [void](Run-Phase 'Transport' (Join-Path $bin 'DisplayTransportHarness.exe') @() 20);Need-Output 'Transport' 'PASS TRANSPORT ASSERTIONS=55'
 $stage='RAW'
 [void](Run-Phase 'Raw' (Join-Path $bin 'RawHarness.exe') @($bin) 45);Need-Output 'Raw' 'PASS RAW EXISTING_ORACLE'
 $stage='SANDBOX'
 for($i=0;$i-lt3;$i++){
  $fixture=Join-Path $bin ('SandboxFixture'+$i+'.txt');$bytes=Add-OwnedArtifact $fixture;$argv=@([Text.Encoding]::ASCII.GetString($bytes));if($i-eq1){$argv+=,'TBX_XLSX_EXTERNAL_RELATION_UNSUPPORTED'};if($i-eq2){$argv+=,'DTD'}
  $phase='Sandbox'+$i;[void](Run-Phase $phase (Join-Path $bin 'Toolbelt.Xlsx.Sandbox.exe') $argv 20);Need-Output $phase 'PASS: restricted Framework execution and deny canaries; not OS syscall observation'
 }
 $stage='OWN_IL'
 [void](Run-Phase 'OwnIL' $binding.PS5 @('-NoProfile','-File',(Join-Path $bin 'Test-ProviderIL.ps1'),'-BinaryDirectory',$bin) 20)
 Need-Output 'OwnIL' 'PASS: own provider IL/reference allowlist, no P/Invoke/File/Network/Process/IsolatedStorage APIs. Framework transitive behavior remains separately scoped.'
 if(@($record.phases).Count-ne19){throw 'PHASE_COUNT'}
 $record.Status='COMPLETE';$record.Cleanup='ALL_OWNED_CHILDREN_ENDED_DISPOSED_EVIDENCE_RETAINED'
}catch{$record.Status='FAILED';$record.failure=$stage}finally{
 try{Check-Pins;$record.FinalPinsUnchanged=$true}catch{$record.Status='FAILED';if($null-eq$record.failure){$record.failure='FINAL_PIN_DRIFT'}}
 $record.Artifacts=@($artifacts);Save-New 'RunEvidence.json' $record
}
if($record.Status-cne'COMPLETE'-or-not$record.FinalPinsUnchanged){Write-Output 'FAILED XLSX_CONSUME_CANDIDATE_OFFLINE';exit 1}
Write-Output 'PASS XLSX_CONSUME_CANDIDATE_OFFLINE';exit 0
