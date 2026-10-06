[CmdletBinding()]
param([Parameter(Mandatory)][string]$CompilerPath,
 [Parameter(Mandatory)][string]$ReferenceDirectory,
 [Parameter(Mandatory)][string]$FrameworkPowerShell,
 [Parameter(Mandatory)][string]$OutputDirectory)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
# Explizite lokale Tools; kein Download, SQL-Zugriff, Trust oder impliziter Build.
$moduleRoot=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$repoRoot=Split-Path -Parent (Split-Path -Parent $moduleRoot)
$constructorRoot=Join-Path $repoRoot 'Modules/toolbelt.json.constructors'
$coreRoot=Join-Path $repoRoot 'Modules/toolbelt.json.core'
$helper=Join-Path $constructorRoot 'Scripts/Invoke-OwnedProcess.ps1'
. $helper
$output=[IO.Path]::GetFullPath($OutputDirectory)
$privatePrefix=[IO.Path]::GetFullPath((Join-Path $repoRoot '.runtime'))+[IO.Path]::DirectorySeparatorChar
if(-not $output.StartsWith($privatePrefix,[StringComparison]::OrdinalIgnoreCase)){throw 'SCHEMA_SOURCE_PRIVATE_OUTPUT_REQUIRED'}
if(Test-Path -LiteralPath $output){throw 'SCHEMA_SOURCE_OUTPUT_EXISTS'}
& git -C $repoRoot check-ignore --quiet -- $output
if($LASTEXITCODE -ne 0){throw 'SCHEMA_SOURCE_OUTPUT_NOT_IGNORED'}
$projects=@((Join-Path $coreRoot 'Clr/Toolbelt.JsonCore.csproj'),
 (Join-Path $constructorRoot 'Clr/Toolbelt.JsonConstructors.csproj'),
 (Join-Path $moduleRoot 'Clr/Toolbelt.JsonSchema.csproj'))
$sources=@{}
foreach($project in $projects){
 $settings=[Xml.XmlReaderSettings]::new();$settings.DtdProcessing=[Xml.DtdProcessing]::Prohibit;$settings.XmlResolver=$null
 $reader=[Xml.XmlReader]::Create($project,$settings)
 try{$xml=[Xml.XmlDocument]::new();$xml.XmlResolver=$null;$xml.Load($reader)}finally{$reader.Dispose()}
 $names=[Xml.XmlNamespaceManager]::new($xml.NameTable);$names.AddNamespace('p','http://schemas.microsoft.com/developer/msbuild/2003')
 $root=[IO.Path]::GetFullPath((Split-Path -Parent $project))+[IO.Path]::DirectorySeparatorChar
 $paths=@($xml.SelectNodes('//p:Compile',$names)|ForEach-Object{
  $path=[IO.Path]::GetFullPath((Join-Path $root $_.Include))
  if(-not $path.StartsWith($root,[StringComparison]::OrdinalIgnoreCase) -or -not(Test-Path -LiteralPath $path)){throw 'SCHEMA_SOURCE_COMPILE_PATH'}
  $path
 })
 if($paths.Count -eq 0 -or @($paths|Sort-Object -Unique).Count -ne $paths.Count){throw 'SCHEMA_SOURCE_COMPILE_SET'}
 $sources[[IO.Path]::GetFileNameWithoutExtension($project)]=$paths
}
$references=@('mscorlib.dll','System.dll','System.Data.dll')|ForEach-Object{Join-Path $ReferenceDirectory $_}
$harnesses=[ordered]@{
 'ProductHarness'=(Join-Path $constructorRoot 'Tests/Framework/ProductHarness.cs')
 'TokenHarness'=(Join-Path $coreRoot 'Tests/Framework/TokenHarness.cs')
 'WorkBudgetHarness'=(Join-Path $coreRoot 'Tests/Framework/WorkBudgetHarness.cs')
 'NumberHarness'=(Join-Path $PSScriptRoot 'NumberHarness.cs')
 'SchemaHarness'=(Join-Path $PSScriptRoot 'SchemaHarness.cs')
 'BridgeHarness'=(Join-Path $PSScriptRoot 'BridgeHarness.cs')
}
$goldens=Join-Path $constructorRoot 'Tests/Framework/BridgeGoldens.tsv'
$numberOracles=Join-Path $PSScriptRoot 'NumberOracles.tsv'
$ilGate=Join-Path $coreRoot 'Tests/Framework/Test-JsonClosureIL.ps1'
$negativeGate=Join-Path $coreRoot 'Tests/Framework/Test-RejectedClosure.ps1'
$inputs=@($projects)+@($references)+@($CompilerPath,$FrameworkPowerShell,$ilGate,$negativeGate,
 (Join-Path $coreRoot 'Tests/Framework/RejectedClosureFixture.cs'),$helper,$PSCommandPath,$goldens,$numberOracles,
 (Join-Path $PSScriptRoot 'generate-number-oracles.py'))+@($harnesses.Values)
foreach($paths in $sources.Values){$inputs+=@($paths)}
$pins=@($inputs|ForEach-Object{[pscustomobject]@{path=[IO.Path]::GetFullPath($_);sha256=(Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash}})
[void][IO.Directory]::CreateDirectory($output)
$record=[ordered]@{scope='OFFLINE_SOURCE_FRAMEWORK_ONLY';status='FAILED';postPins=$false;phases=@();binaryPins=@()}
$common=@('/nologo','/noconfig','/nostdlib+','/checked+','/optimize+','/deterministic+','/warnaserror+','/debug-','/langversion:7.3')
$productPins=@()
function Phase([string]$name,[string]$file,[string[]]$arguments,[int]$milliseconds,[string]$witness){
 try{$process=Invoke-OwnedProcess -FileName $file -Arguments $arguments -TimeoutMilliseconds $milliseconds}
 catch{
  $category=$_.Exception.Message
  if($category -cnotmatch '^OWNED_PROCESS_(START|TIMEOUT|CAPTURE_FAILED|ENCODING_FAILED|CAPTURE_LIMIT|CLEANUP_UNSAFE|FAILED)$'){$category='OWNED_PROCESS_FAILED'}
  throw ('SCHEMA_SOURCE_PROCESS_'+$name+'_'+$category)
 }
 [IO.File]::WriteAllText((Join-Path $output ($name+'.stdout.private')),$process.Stdout)
 [IO.File]::WriteAllText((Join-Path $output ($name+'.stderr.private')),$process.Stderr)
 $record.phases+=@([ordered]@{name=$name;exitCode=$process.ExitCode;captureComplete=$process.CaptureComplete;emptyStderr=($process.Stderr.Length -eq 0);witness=$process.Stdout.Trim()})
 if($process.ExitCode -ne 0 -or -not $process.CaptureComplete -or $process.Stderr.Length -ne 0 -or $process.Stdout -cne $witness){throw ('SCHEMA_SOURCE_PHASE: '+$name)}
 Write-Output ($name+': PASS')
}
function Pin-Product([string]$path){$script:productPins+=@([pscustomobject]@{path=$path;sha256=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash})}
try{
 $core=Join-Path $output 'Toolbelt.JsonCore.dll'
 $ctor=Join-Path $output 'Toolbelt.JsonConstructors.dll'
 $schema=Join-Path $output 'Toolbelt.JsonSchema.dll'
 Phase 'CompileCore' $CompilerPath (@($common)+@('/target:library',('/out:'+$core),('/reference:'+$references[0]),('/reference:'+$references[1]))+@($sources['Toolbelt.JsonCore'])) 15000 ''
 Pin-Product $core
 foreach($product in @('Toolbelt.JsonConstructors','Toolbelt.JsonSchema')){
  $dll=Join-Path $output ($product+'.dll')
  Phase ('Compile-'+$product) $CompilerPath (@($common)+@('/target:library',('/out:'+$dll),('/reference:'+$core))+@($references|ForEach-Object{'/reference:'+$_})+@($sources[$product])) 15000 ''
  Pin-Product $dll
 }
 foreach($product in @('Toolbelt.JsonCore','Toolbelt.JsonConstructors','Toolbelt.JsonSchema')){
  $dll=Join-Path $output ($product+'.dll')
  $arguments=@('-NoProfile','-NonInteractive','-File',$ilGate,'-BinaryPath',$dll,
   '-ExpectedSha256',(Get-FileHash -LiteralPath $dll -Algorithm SHA256).Hash,
   '-EvidencePath',(Join-Path $output ($product+'.IL.private.json')))
  if($product-cne'Toolbelt.JsonCore'){$arguments+=@('-CorePath',$core,'-ExpectedCoreSha256',(Get-FileHash -LiteralPath $core -Algorithm SHA256).Hash)}
  Phase ('IL-'+$product) $FrameworkPowerShell $arguments 15000 "PASS JSON_SHARED_PRODUCT_IL`r`n"
 }
 foreach($name in $harnesses.Keys){
  $exe=Join-Path $output ($name+'.exe')
  $argsForHarness=@($common)+@('/target:exe',('/out:'+$exe),('/reference:'+$core))+@($references|ForEach-Object{'/reference:'+$_})
  if($name -eq 'ProductHarness'){$argsForHarness+=('/reference:'+$ctor)}
  if($name -in @('NumberHarness','SchemaHarness','BridgeHarness')){$argsForHarness+=('/reference:'+$schema)}
  $argsForHarness+=$harnesses[$name]
  Phase ('Compile-'+$name) $CompilerPath $argsForHarness 15000 ''
  Pin-Product $exe
 }
 foreach($culture in @('en-US','de-DE','tr-TR')){
  Phase ('Constructors-'+$culture) (Join-Path $output 'ProductHarness.exe') @('SMALL',$culture,$goldens) 45000 ("PASS PRODUCT_FRAMEWORK SMALL $culture ROWS 37 ASSERTIONS 960`r`n")
  Phase ('Numbers-'+$culture) (Join-Path $output 'NumberHarness.exe') @($numberOracles,$culture) 30000 "PASS SCHEMA_NUMBERS CASES 854 ASSERTIONS 6830`r`n"
  Phase ('Schema-'+$culture) (Join-Path $output 'SchemaHarness.exe') @($culture) 30000 ("PASS SCHEMA_PROFILE cases=169 assertions=1275 culture=$culture`r`n")
  Phase ('Bridge-'+$culture) (Join-Path $output 'BridgeHarness.exe') @($culture) 30000 ("PASS SCHEMA_BRIDGE assertions=120 culture=$culture`r`n")
 }
 Phase 'ConstructorLarge' (Join-Path $output 'ProductHarness.exe') @('LARGE','invariant',$goldens) 45000 "PASS PRODUCT_FRAMEWORK LARGE invariant ROWS 3 ASSERTIONS 67`r`n"
 Phase 'Tokens' (Join-Path $output 'TokenHarness.exe') @() 15000 "PASS CORE_TOKENS CASES 37 ASSERTIONS 95`r`n"
 Phase 'Budget' (Join-Path $output 'WorkBudgetHarness.exe') @() 15000 "PASS CORE_BUDGET ASSERTIONS 10`r`n"
 $record.status='COMPLETE'
}finally{
 try{
  foreach($pin in @($pins)+@($productPins)){if((Get-FileHash -LiteralPath $pin.path -Algorithm SHA256).Hash -cne $pin.sha256){throw 'SCHEMA_SOURCE_PIN_DRIFT'}}
  $record.postPins=$true
 }catch{$record.status='FAILED';$record.postPins=$false}
 $record.binaryPins=@($productPins|ForEach-Object{[ordered]@{fileName=[IO.Path]::GetFileName($_.path);sha256=$_.sha256}})
 [IO.File]::WriteAllText((Join-Path $output 'Receipt.private.json'),($record|ConvertTo-Json -Depth 8))
 [IO.File]::WriteAllText((Join-Path $output 'FrozenInputs.private.json'),(ConvertTo-Json -InputObject $pins -Depth 4))
}
if($record.status -cne 'COMPLETE' -or -not $record.postPins){throw 'SCHEMA_SOURCE_QUALIFICATION_FAILED'}
'PASS SCHEMA_SOURCE_FRAMEWORK_ONLY'
