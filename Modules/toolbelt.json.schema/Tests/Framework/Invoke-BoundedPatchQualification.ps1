#requires -Version 7.0
[CmdletBinding()]
param([Parameter(Mandatory)][string]$CompilerPath,
 [Parameter(Mandatory)][string]$ReferenceDirectory,
 [Parameter(Mandatory)][string]$FrameworkPowerShell,
 [Parameter(Mandatory)][string]$MSBuildPath,
 [Parameter(Mandatory)][string]$CoreAssemblyPath,
 [Parameter(Mandatory)][ValidateRange(1,10000)][int]$ExpectedSchemaCases,
 [Parameter(Mandatory)][ValidateRange(1,100000)][int]$ExpectedSchemaAssertions,
 [Parameter(Mandatory)][string]$OutputDirectory,
 [string]$KnownClosurePath)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$moduleRoot=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$repoRoot=Split-Path -Parent (Split-Path -Parent $moduleRoot)
$commonPath=Join-Path $moduleRoot 'Scripts/SchemaPatch.Common.ps1'
$ownedPath=Join-Path $repoRoot 'Modules/toolbelt.json.constructors/Scripts/Invoke-OwnedProcess.ps1'
. $commonPath
. $ownedPath
# Bewusst begrenzte Patchwelle: bestehende Corebytes, nur Schema und kleine Harnesses.
# Exakte Witnesszahlen sind explizite Inputs; kein Constructor-/Maximallast-/SQL-Nachweis.
$record=$null;$output=$null;$pins=@();$productPins=@()
try{
 if(-not $KnownClosurePath){$KnownClosurePath=Join-Path $repoRoot 'Modules/toolbelt.json.core/Documentation/KNOWN_JSON_ARTIFACT_CLOSURE_SCHEMA_1_0.json'}
 $KnownClosurePath=[IO.Path]::GetFullPath($KnownClosurePath)
 $closure=Read-SchemaPatchClosure $KnownClosurePath
 $coreFields=$closure.artifacts[0].Fields
 if((Get-SchemaPatchHash $CoreAssemblyPath) -cne $coreFields.binarySha256 -or
  (Get-SchemaPatchHash $CoreAssemblyPath 'SHA512') -cne $coreFields.binarySha512){throw 'SCHEMA_PATCH_CORE_PIN'}
 $coreIdentity=[Reflection.AssemblyName]::GetAssemblyName($CoreAssemblyPath)
 if($coreIdentity.Name -cne 'Toolbelt.JsonCore' -or $coreIdentity.Version.ToString() -cne '1.0.0.0'){throw 'SCHEMA_PATCH_CORE_IDENTITY'}
 $project=Join-Path $moduleRoot 'Clr/Toolbelt.JsonSchema.csproj'
 $sources=@(Get-SchemaPatchSources $project)
 $references=@('mscorlib.dll','System.dll','System.Data.dll')|ForEach-Object{Join-Path $ReferenceDirectory $_}
 $harnesses=[ordered]@{Schema=(Join-Path $PSScriptRoot 'SchemaHarness.cs');Numbers=(Join-Path $PSScriptRoot 'NumberHarness.cs');Bridge=(Join-Path $PSScriptRoot 'BridgeHarness.cs')}
 $oracles=Join-Path $PSScriptRoot 'NumberOracles.tsv'
 $ilGate=Join-Path $repoRoot 'Modules/toolbelt.json.core/Tests/Framework/Test-JsonClosureIL.ps1'
 $inputs=@($KnownClosurePath,$CoreAssemblyPath,$project,$CompilerPath,$MSBuildPath,$FrameworkPowerShell,$commonPath,$ownedPath,$ilGate,$PSCommandPath,$oracles)+@($references)+@($harnesses.Values)+@($sources|ForEach-Object{$_.path})
 $pins=@($inputs|ForEach-Object{[ordered]@{path=[IO.Path]::GetFullPath($_);sha256=(Get-SchemaPatchHash $_)}})
 $output=Assert-SchemaPatchPrivateOutput $repoRoot $OutputDirectory
 [void][IO.Directory]::CreateDirectory($output)
 Write-SchemaPatchJson (Join-Path $output 'FrozenInputs.private.json') $pins
 $record=[ordered]@{scope='BOUNDED_SCHEMA_PATCH';qualificationScope='OFFLINE_BOUNDED_SCHEMA_PATCH_FRAMEWORK_AND_OWN_IL_AND_CANONICAL_PROJECT_BYTE_EQUALITY';status='FAILED';postPins=$false;
  moduleVersion='1.0.1';managedVersion='1.0.1.0';knownClosureSha256=(Get-SchemaPatchHash $KnownClosurePath);coreArtifactId=$closure.artifacts[0].ArtifactId;
  coreSha256=$coreFields.binarySha256;projectSha256=(Get-SchemaPatchHash $project);sources=@($sources|ForEach-Object{[ordered]@{relative=$_.relative;sha256=$_.sha256}});
  expectedSchemaCases=$ExpectedSchemaCases;expectedSchemaAssertions=$ExpectedSchemaAssertions;phases=@();binaryPins=@();
  limitations=@('CORE_AND_CONSTRUCTORS_NOT_REQUALIFIED','NO_CONSTRUCTOR_LARGE','NO_SQL_RUNTIME','NO_TRUST_AUTHORIZATION','FRAMEWORK_TRANSITIVE_SAFE_NOT_CERTIFIED')}
 $options=@('/nologo','/noconfig','/nostdlib+','/checked+','/optimize+','/deterministic+','/warnaserror+','/debug-','/langversion:7.3')
 function Invoke-PatchPhase([string]$Name,[string]$File,[string[]]$Arguments,[int]$Milliseconds,[AllowNull()][object]$WitnessPattern) {
  try{$process=Invoke-OwnedProcess -FileName $File -Arguments $Arguments -TimeoutMilliseconds $Milliseconds}
  catch{
   $category=$_.Exception.Message
   if($category -cnotmatch '^OWNED_PROCESS_(START|TIMEOUT|CAPTURE_FAILED|ENCODING_FAILED|CAPTURE_LIMIT|CLEANUP_UNSAFE|FAILED)$'){$category='OWNED_PROCESS_FAILED'}
   throw ('SCHEMA_PATCH_PROCESS_'+$Name+'_'+$category)
  }
  [IO.File]::WriteAllText((Join-Path $output ($Name+'.stdout.private')),$process.Stdout)
  [IO.File]::WriteAllText((Join-Path $output ($Name+'.stderr.private')),$process.Stderr)
  $phase=[ordered]@{name=$Name;exitCode=$process.ExitCode;captureComplete=$process.CaptureComplete;emptyStderr=($process.Stderr.Length -eq 0);status='FAILED'}
  $record.phases+=@($phase)
  if($process.ExitCode -ne 0 -or -not $process.CaptureComplete -or $process.Stderr.Length -ne 0){throw 'SCHEMA_PATCH_PHASE_PROCESS'}
  if($null -ne $WitnessPattern){
   $match=[regex]::Match($process.Stdout,$WitnessPattern,[Text.RegularExpressions.RegexOptions]::CultureInvariant)
   if(-not $match.Success){throw 'SCHEMA_PATCH_PHASE_WITNESS'}
   foreach($metric in @('cases','assertions')){if($match.Groups[$metric].Success){$phase[$metric]=[int]::Parse($match.Groups[$metric].Value,[Globalization.CultureInfo]::InvariantCulture)}}
   if($match.Groups['culture'].Success){$phase['culture']=$match.Groups['culture'].Value}
  }
  $phase.status='PASSED'
  Write-Output ($Name+': PASS')
 }
 function Add-PatchBinary([string]$Path) {
  $script:productPins+=@([ordered]@{path=$Path;sha256=(Get-SchemaPatchHash $Path)})
  $record.binaryPins+=@([ordered]@{fileName=[IO.Path]::GetFileName($Path);sha256=(Get-SchemaPatchHash $Path);sha512=(Get-SchemaPatchHash $Path 'SHA512')})
 }
 $core=Join-Path $output 'Toolbelt.JsonCore.dll';[IO.File]::Copy($CoreAssemblyPath,$core,$false);Add-PatchBinary $core
 $schema=Join-Path $output 'Toolbelt.JsonSchema.dll'
 Invoke-PatchPhase 'CompileSchema' $CompilerPath (@($options)+@('/target:library',('/out:'+$schema),('/reference:'+$core))+@($references|ForEach-Object{'/reference:'+$_})+@($sources|ForEach-Object{$_.path})) 15000 '\A\z'
 Add-PatchBinary $schema
 $identity=[Reflection.AssemblyName]::GetAssemblyName($schema)
 if($identity.Name -cne 'Toolbelt.JsonSchema' -or $identity.Version.ToString() -cne '1.0.1.0'){throw 'SCHEMA_PATCH_IDENTITY'}
 Invoke-PatchPhase 'SchemaIL' $FrameworkPowerShell @('-NoProfile','-NonInteractive','-File',$ilGate,'-BinaryPath',$schema,'-ExpectedSha256',(Get-SchemaPatchHash $schema).ToUpperInvariant(),'-CorePath',$core,'-ExpectedCoreSha256',$coreFields.binarySha256.ToUpperInvariant(),'-EvidencePath',(Join-Path $output 'Toolbelt.JsonSchema.IL.private.json')) 15000 '\APASS JSON_SHARED_PRODUCT_IL\r?\n\z'
 $il=Get-Content -LiteralPath (Join-Path $output 'Toolbelt.JsonSchema.IL.private.json') -Raw|ConvertFrom-Json
 if($il.status -cne 'PASS' -or @($il.unknown).Count -ne 0 -or $il.frameworkTransitiveSafe){throw 'SCHEMA_PATCH_IL_EVIDENCE'}
 $productPins+=@([ordered]@{path=(Join-Path $output 'Toolbelt.JsonSchema.IL.private.json');sha256=(Get-SchemaPatchHash (Join-Path $output 'Toolbelt.JsonSchema.IL.private.json'))})
 $build=Join-Path $output 'canonical/'
 Invoke-PatchPhase 'CanonicalSchema' $MSBuildPath @($project,'/nologo','/v:minimal','/m:1','/nr:false','/t:Build','/p:Configuration=Release',('/p:OutputPath='+$build),('/p:IntermediateOutputPath='+(Join-Path $build 'obj/')),('/p:CoreReferenceHintPath='+$core),('/p:CscToolPath='+(Split-Path -Parent $CompilerPath)),('/p:CscToolExe='+[IO.Path]::GetFileName($CompilerPath)),('/p:FrameworkPathOverride='+$ReferenceDirectory)) 30000 $null
 $canonical=Join-Path $build 'Toolbelt.JsonSchema.dll'
 if((Get-SchemaPatchHash $canonical) -cne (Get-SchemaPatchHash $schema)){throw 'SCHEMA_PATCH_CANONICAL_BYTES'}
 $record.phases[-1]['byteEqual']=$true
 $productPins+=@([ordered]@{path=$canonical;sha256=(Get-SchemaPatchHash $canonical)})
 foreach($name in $harnesses.Keys){
  $exe=Join-Path $output ($name+'Harness.exe')
  Invoke-PatchPhase ('Compile'+$name+'Harness') $CompilerPath (@($options)+@('/target:exe',('/out:'+$exe),('/reference:'+$core),('/reference:'+$schema))+@($references|ForEach-Object{'/reference:'+$_})+@($harnesses[$name])) 15000 '\A\z'
  Add-PatchBinary $exe
 }
 foreach($culture in @('en-US','de-DE','tr-TR')){
  Invoke-PatchPhase ('Schema-'+$culture) (Join-Path $output 'SchemaHarness.exe') @($culture) 30000 ('\APASS SCHEMA_PROFILE cases=(?<cases>'+$ExpectedSchemaCases+') assertions=(?<assertions>'+$ExpectedSchemaAssertions+') culture=(?<culture>'+[regex]::Escape($culture)+')\r?\n\z')
  Invoke-PatchPhase ('Numbers-'+$culture) (Join-Path $output 'NumbersHarness.exe') @($oracles,$culture) 30000 '\APASS SCHEMA_NUMBERS CASES (?<cases>854) ASSERTIONS (?<assertions>6830)\r?\n\z'
  $record.phases[-1]['culture']=$culture
  Invoke-PatchPhase ('Bridge-'+$culture) (Join-Path $output 'BridgeHarness.exe') @($culture) 30000 ('\APASS SCHEMA_BRIDGE assertions=(?<assertions>120) culture=(?<culture>'+[regex]::Escape($culture)+')\r?\n\z')
 }
 $record.status='PASSED'
}catch{
 $category=$_.Exception.Message
 if($category -cnotmatch '^SCHEMA_PATCH_[A-Za-z0-9_-]+$'){$category='SCHEMA_PATCH_FAILED'}
 if($null -ne $record){$record.status='FAILED';$record['failure']=$category}
 throw $category
}finally{
 if($null -ne $record){
  try{Assert-SchemaPatchPins (@($pins)+@($productPins));$record.postPins=$true}
  catch{$record.status='FAILED';$record.postPins=$false;$record['failure']='SCHEMA_PATCH_POSTPIN'}
  Write-SchemaPatchJson (Join-Path $output 'Receipt.private.json') $record
 }
}
if($record.status -cne 'PASSED' -or -not $record.postPins){throw 'SCHEMA_PATCH_QUALIFICATION_FAILED'}
'PASS BOUNDED_SCHEMA_PATCH'
