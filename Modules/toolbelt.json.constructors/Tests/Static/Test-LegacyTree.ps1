[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$source=Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'Deployment/New-LegacyTestArtifacts.ps1'
$tokens=$null;$errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile($source,[ref]$tokens,[ref]$errors)
if($errors.Count){throw 'LEGACY_TEST_PARSE'}
$statements=@($ast.EndBlock.Statements)
function Unique-Statement([string]$Prefix){
 $selected=@($statements|Where-Object{$_.Extent.Text.StartsWith($Prefix,[StringComparison]::Ordinal)})
 if($selected.Count -ne 1){throw 'LEGACY_TEST_EXTENT'}
 return $selected[0].Extent.Text
}
# Tatsächliche geschlossene Dateiliste und Parser importieren; kein Git-/Childstart.
$set=(Unique-Statement '$expected=@(')+"`n"+(Unique-Statement "if(`$Version -ceq '1.1.0')")
$body=(Unique-Statement '$entries=@()')+"`n"+(Unique-Statement 'foreach($entry in $tree.Split(')+"`n"+(Unique-Statement 'if($entries.Count -ne $expected.Count')
$treeStatement=Unique-Statement '$tree=[Text.Encoding]::UTF8.GetString('
if(-not $treeStatement.Contains("@('ls-tree','--full-tree','-r','-z',`$revision)+`$treePaths")){throw 'LEGACY_TEST_ROOT_RELATIVE_ARGV'}
$parser=[scriptblock]::Create('param($tree,$Version)'+"`n"+'$modulePath="Modules/toolbelt.json.constructors/"'+"`n"+$set+"`n"+$body+"`n"+'return ,$entries')
$files=[scriptblock]::Create('param($Version)'+"`n"+$set+"`n"+'return ,$expected')
$checks=0
foreach($version in @('1.0.0','1.1.0')){
 $paths=& $files $version
 $lines=@($paths|ForEach-Object{'100644 blob '+('a'*40)+"`tModules/toolbelt.json.constructors/"+$_})
 $valid=[string]::Join([char]0,$lines)+[char]0
 $entries=& $parser $valid $version
 if($entries.Count -ne $(if($version -ceq '1.0.0'){5}else{7})){throw 'LEGACY_TEST_VALID_COUNT'}
 $checks++
 $bad=@(
  [pscustomobject]@{Text=[string]::Join([char]0,$lines[0..($lines.Count-2)]);Code='LEGACY_FILE_SET_MISMATCH'},
  [pscustomobject]@{Text=$valid+$lines[0];Code='LEGACY_FILE_SET_MISMATCH'},
  [pscustomobject]@{Text=$valid+('100644 blob '+('a'*40)+"`tModules/toolbelt.json.constructors/Deployment/New-LegacyTestArtifacts.ps1");Code='LEGACY_FILE_SET_MISMATCH'},
  [pscustomobject]@{Text=$valid.Replace('100644','100755');Code='LEGACY_TREE_INVALID'},
  [pscustomobject]@{Text=$valid.Replace(('a'*40),('G'*40));Code='LEGACY_TREE_INVALID'},
  [pscustomobject]@{Text=$valid.Replace('Modules/toolbelt.json.constructors/','Modules/other/');Code='LEGACY_TREE_SCOPE_INVALID'}
 )
 foreach($case in $bad){
  $actual=$null
  try{[void](& $parser $case.Text $version)}catch{$actual=$_.Exception.Message}
  if($actual -cne $case.Code){throw 'LEGACY_TEST_REJECTION'}
  $checks++
 }
}
Write-Output ('PASS: legacy SQL tree parser pure controls CHECKS='+$checks+'; no Git/process/SQL execution')
