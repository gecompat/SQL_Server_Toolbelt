[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$tokens=$null;$errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'run-json-schema-lab.ps1'),[ref]$tokens,[ref]$errors)
if($errors.Count){throw 'JSON_SCOPE_DRIVER_PARSE'}
# Echte Parametersyntax und Zielguard auswerten; die Testfunktion enthält
# ausschließlich diese Metadatenprüfung und führt keine Lab-/SQL-Operation aus.
$guards=@($ast.FindAll({param($node) $node-is[Management.Automation.Language.IfStatementAst]-and$node.Extent.Text.Contains('JSON_SCHEMA_APPROVED_TARGET_SCOPE')},$true))
if($guards.Count-ne1){throw 'JSON_SCOPE_GUARD_DISCOVERY'}
. ([scriptblock]::Create('function Test-BoundJsonLabScope { '+$ast.ParamBlock.Extent.Text+'; '+$guards[0].Extent.Text+'; "ACCEPTED" }'))
$base=@{QualifiedDirectory='unused';OutputDirectory='unused';ApprovedTrustHashes=@('unused');ExpectedPromptSHA256=('0'*64)}
$script:cases=0
function Assert-BoundScope([hashtable]$Arguments,[bool]$Accept,[bool]$BindingOnly=$false){
 $accepted=$false;$bindingRejected=$false
 try{$accepted=(Test-BoundJsonLabScope @base @Arguments)-ceq'ACCEPTED'}
 catch{
  $bindingRejected=$_.Exception-is[Management.Automation.ParameterBindingException]
  if(-not$bindingRejected-and$_.Exception.Message-cne'JSON_SCHEMA_APPROVED_TARGET_SCOPE'){throw}
 }
 if($accepted-ne$Accept-or($BindingOnly-and-not$bindingRejected)){throw 'JSON_SCOPE_CASE_FAILED'}
 $script:cases++
}
Assert-BoundScope @{Platform='linux';Version='2019';Patch='latest';CompatibilityLevel=150} $true
foreach($level in @(150,160,170)){
 Assert-BoundScope @{Platform='windows';Version='2025';Patch='CU8';CompatibilityLevel=$level} $true
}
foreach($scope in @('core-schema','constructors','migration')){
 Assert-BoundScope @{Platform='windows';Version='2025';Patch='CU8';QualificationScope=$scope} $true
}
Assert-BoundScope @{Platform='linux';Version='2025';Patch='latest';CompatibilityLevel=150} $false
foreach($level in @(160,170)){
 Assert-BoundScope @{Platform='linux';Version='2019';Patch='latest';CompatibilityLevel=$level} $false
}
foreach($patch in @('CU8','latest')){
 Assert-BoundScope @{Platform='windows';Version='2019';Patch=$patch} $false
}
foreach($patch in @('CU7','CU9','base','cu8')){
 Assert-BoundScope @{Platform='windows';Version='2025';Patch=$patch} $false
}
Assert-BoundScope @{Platform='windows';Version='2022';Patch='CU8'} $false $true
Assert-BoundScope @{Platform='windows';Version='2025';Patch='CU8';CompatibilityLevel=151} $false $true
foreach($platform in @('Windows','WINDOWS','WiNdOwS')){
 Assert-BoundScope @{Platform=$platform;Version='2019';Patch='latest'} $false $true
}
foreach($platform in @('Linux','LINUX','LiNuX')){
 Assert-BoundScope @{Platform=$platform;Version='2025';Patch='latest'} $false $true
}
foreach($scope in @('Core-Schema','Constructors','MIGRATION')){
 Assert-BoundScope @{Platform='windows';Version='2025';Patch='CU8';QualificationScope=$scope} $false $true
}
foreach($mode in @('LOCAL','Central')){
 Assert-BoundScope @{Platform='windows';Version='2025';Patch='CU8';DeploymentModes=@($mode)} $false $true
}
Assert-BoundScope @{Platform='windows';Version='2025';Patch='CU8';ConstructorTests=@('JSONAGGREGATES.CONTRACT.SQL')} $false $true

# Die zweite vorhandene Schutzschicht ebenfalls mit synthetischen Metadaten
# prüfen. READY wird für alle Beispiele angenommen; echte Labdaten bleiben frei.
function Test-LabTargetReady {param($Contract,$Entry);return $true}
$helper=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'run-lab-local.ps1'),[ref]$tokens,[ref]$errors)
if($errors.Count){throw 'JSON_SCOPE_HELPER_PARSE'}
$selectors=@($helper.FindAll({param($node) $node-is[Management.Automation.Language.FunctionDefinitionAst]-and$node.Name-ceq'Get-LabTargetsForSelector'},$true))
if($selectors.Count-ne1){throw 'JSON_SCOPE_SELECTOR_DISCOVERY'}
. ([scriptblock]::Create($selectors[0].Extent.Text))
$synthetic=[pscustomobject]@{environments=@(
 [pscustomobject]@{platform='windows';sqlVersion='2019';patch='latest';key='synthetic-unapproved'},
 [pscustomobject]@{platform='windows';sqlVersion='2025';patch='CU8';key='synthetic-approved'})}
foreach($example in @(
 @{Platform='WINDOWS';Version='2019';Patch='latest';Count=0},
 @{Platform='windows';Version='2019';Patch='latest';Count=1},
 @{Platform='windows';Version='2025';Patch='CU8';Count=1})){
 $selected=@(Get-LabTargetsForSelector -Contract $synthetic -Selector ([pscustomobject]$example))
 if($selected.Count-ne$example.Count){throw 'JSON_SCOPE_SELECTOR_CASE_FAILED'}
 $script:cases++
}
if($script:cases-ne33){throw 'JSON_SCOPE_ASSERTION_COUNT'}
'PASS JSON_LAB_SCOPE_BINDING_AND_SELECTOR 33'

# Nur die reine Versionsprüfung des historischen SQL-only-Adapters auswerten.
# Weder dessen Top-level-Initialisierung noch Lab-/SQL-Funktionen ausführen.
$legacyAst=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'run-json-groups-lab.ps1'),[ref]$tokens,[ref]$errors)
if($errors.Count){throw 'JSON_LEGACY_SCOPE_DRIVER_PARSE'}
$versionGuards=@($legacyAst.FindAll({param($node)$node-is[Management.Automation.Language.FunctionDefinitionAst]-and$node.Name-ceq'Assert-LegacyJsonLabVersion'},$true))
$versionCalls=@($legacyAst.FindAll({param($node)$node-is[Management.Automation.Language.CommandAst]-and$node.GetCommandName()-ceq'Assert-LegacyJsonLabVersion'},$true))
$legacyPaths=@($legacyAst.FindAll({param($node)$node-is[Management.Automation.Language.AssignmentStatementAst]-and$node.Left.Extent.Text-ceq'$legacy'},$true))
if($versionGuards.Count-ne1-or$versionCalls.Count-ne1-or$legacyPaths.Count-ne1-or$versionCalls[0].Extent.StartOffset-ge$legacyPaths[0].Extent.StartOffset){throw 'JSON_LEGACY_SCOPE_EARLY_GUARD'}
. ([scriptblock]::Create($versionGuards[0].Extent.Text))
$legacyCases=0
foreach($case in @(
 @{Text='version: "1.1.0"';Accept=$true},
 @{Text="module_id: Contoso`r`nversion: `"1.1.0`"`r`n";Accept=$true},
 @{Text='version: "1.2.0"';Accept=$false},
 @{Text='version: "1.3.0"';Accept=$false},
 @{Text='version: "2.0.0"';Accept=$false},
 @{Text='';Accept=$false},
 @{Text='version: 1.1.0';Accept=$false},
 @{Text="version: `"1.1.0`"`nversion: `"1.3.0`"";Accept=$false},
 @{Text="version: `"1.1.0`"`nversion: `"1.1.0`"";Accept=$false}
)){
 $accepted=$true
 try{Assert-LegacyJsonLabVersion $case.Text}catch{if($_.Exception.Message-cne'JSON_CLR_NATIVE_ADAPTER_REVIEW_REQUIRED'){throw};$accepted=$false}
 if($accepted-ne$case.Accept){throw 'JSON_LEGACY_SCOPE_VERSION_CASE_FAILED'}
 $legacyCases++
}
if($legacyCases-ne9){throw 'JSON_LEGACY_SCOPE_ASSERTION_COUNT'}
'PASS JSON_LEGACY_SCOPE_VERSION_AND_ORDER 9'
