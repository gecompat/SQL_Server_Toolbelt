[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'JsonSchemaQualificationScope.ps1')
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
Assert-BoundScope @{Platform='linux';Version='2025';Patch='latest';CompatibilityLevel=150} $true
foreach($level in @(160,170)){
 Assert-BoundScope @{Platform='linux';Version='2019';Patch='latest';CompatibilityLevel=$level} $false
}
foreach($patch in @('CU8','latest')){
 Assert-BoundScope @{Platform='windows';Version='2019';Patch=$patch} $false
}
foreach($patch in @('CU7','CU9','base','cu8')){
 Assert-BoundScope @{Platform='windows';Version='2025';Patch=$patch} $false
}
Assert-BoundScope @{Platform='windows';Version='2022';Patch='CU8'} $false
Assert-BoundScope @{Platform='windows';Version='2017';Patch='CU8'} $false $true
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
# Constructor-Auswahl bleibt erhalten; Core/Schema hat seinen eigenen erweiterten
# Scope. Migration, falsche Patches und nicht unterstützte CLs bleiben begrenzt.
foreach($selection in @(
 @{Version='2019';Patch='CU32';CompatibilityLevel=150},
 @{Version='2022';Patch='CU26';CompatibilityLevel=150},
 @{Version='2022';Patch='CU26';CompatibilityLevel=160}
)){
 foreach($scope in @('constructors','core-schema','migration')){
  Assert-BoundScope @{Platform='windows';Version=$selection.Version;Patch=$selection.Patch;CompatibilityLevel=$selection.CompatibilityLevel;QualificationScope=$scope} ($scope-cin@('constructors','core-schema'))
 }
 foreach($patch in @('base',$selection.Patch.ToLowerInvariant())){
  Assert-BoundScope @{Platform='windows';Version=$selection.Version;Patch=$patch;CompatibilityLevel=$selection.CompatibilityLevel;QualificationScope='constructors'} $false
 }
}
foreach($level in @(160,170)){
 Assert-BoundScope @{Platform='windows';Version='2019';Patch='CU32';CompatibilityLevel=$level;QualificationScope='constructors'} $false
}
Assert-BoundScope @{Platform='windows';Version='2022';Patch='CU26';CompatibilityLevel=170;QualificationScope='constructors'} $false
Assert-BoundScope @{Platform='linux';Version='2022';Patch='CU26';QualificationScope='constructors'} $false
if($script:cases-ne53){throw 'JSON_SCOPE_ASSERTION_COUNT'}
'PASS JSON_LAB_SCOPE_BINDING_AND_SELECTOR 53'

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

# Auch der unabhängige Audit muss genau dieselben Ziel-/CL-/Scopetupel
# akzeptieren. Nur dessen reine Guard-AST ausführen, niemals den SQL-Teil.
$dispositionAst=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'Test-JsonSchemaLabDisposition.ps1'),[ref]$tokens,[ref]$errors)
if($errors.Count){throw 'JSON_SCOPE_DISPOSITION_PARSE'}
$dispositionGuards=@($dispositionAst.FindAll({param($node)$node-is[Management.Automation.Language.IfStatementAst]-and$node.Extent.Text.Contains('JSON_DISPOSITION_TARGET_SCOPE')},$true))
if($dispositionGuards.Count-ne1){throw 'JSON_SCOPE_DISPOSITION_DISCOVERY'}
. ([scriptblock]::Create('function Test-BoundJsonDispositionScope { param($journal); '+$dispositionGuards[0].Extent.Text+'; "ACCEPTED" }'))
$auditCases=[Collections.Generic.List[object]]::new()
$auditCases.Add(@{Platform='linux';Version='2019';Patch='latest';CompatibilityLevel=150;Scope='core-schema';Accept=$true})
$auditCases.Add(@{Platform='windows';Version='2025';Patch='CU8';CompatibilityLevel=170;Scope='core-schema';Accept=$true})
foreach($selection in @(
 @{Version='2019';Patch='CU32';CompatibilityLevel=150},
 @{Version='2022';Patch='CU26';CompatibilityLevel=150},
 @{Version='2022';Patch='CU26';CompatibilityLevel=160}
)){
 foreach($scope in @('constructors','core-schema','migration')){
  $auditCases.Add(@{Platform='windows';Version=$selection.Version;Patch=$selection.Patch;CompatibilityLevel=$selection.CompatibilityLevel;Scope=$scope;Accept=($scope-cin@('constructors','core-schema'))})
 }
 foreach($patch in @('base',$selection.Patch.ToLowerInvariant())){
  $auditCases.Add(@{Platform='windows';Version=$selection.Version;Patch=$patch;CompatibilityLevel=$selection.CompatibilityLevel;Scope='constructors';Accept=$false})
 }
}
foreach($level in @(160,170)){$auditCases.Add(@{Platform='windows';Version='2019';Patch='CU32';CompatibilityLevel=$level;Scope='constructors';Accept=$false})}
$auditCases.Add(@{Platform='windows';Version='2022';Patch='CU26';CompatibilityLevel=170;Scope='constructors';Accept=$false})
$auditCases.Add(@{Platform='windows';Version='2025';Patch='CU8';CompatibilityLevel=170;Scope='unknown';Accept=$false})
$auditCases.Add(@{Platform='linux';Version='2022';Patch='CU26';CompatibilityLevel=150;Scope='constructors';Accept=$false})
$auditCases.Add(@{Platform='windows';Version='2017';Patch='CU8';CompatibilityLevel=150;Scope='constructors';Accept=$false})
foreach($case in $auditCases){
 $driverAccepted=$false;$auditAccepted=$false
 try{$driverAccepted=(Test-BoundJsonLabScope @base -Platform $case.Platform -Version $case.Version -Patch $case.Patch -CompatibilityLevel $case.CompatibilityLevel -QualificationScope $case.Scope)-ceq'ACCEPTED'}catch{if($_.Exception-isnot[Management.Automation.ParameterBindingException]-and$_.Exception.Message-cne'JSON_SCHEMA_APPROVED_TARGET_SCOPE'){throw}}
 try{$auditAccepted=(Test-BoundJsonDispositionScope ([pscustomobject]$case))-ceq'ACCEPTED'}catch{if($_.Exception.Message-cne'JSON_DISPOSITION_TARGET_SCOPE'){throw}}
 if($driverAccepted-ne$case.Accept-or$auditAccepted-ne$case.Accept){throw 'JSON_SCOPE_DRIVER_DISPOSITION_DISAGREE'}
}
if($auditCases.Count-ne23){throw 'JSON_SCOPE_DISPOSITION_CASE_COUNT'}
'PASS JSON_DRIVER_DISPOSITION_SCOPE_AGREEMENT 23'

# Den echten Read-only-Verbraucherguard isoliert mit synthetischen Katalogen
# prüfen. Ein Compiler-/Lab-/SQL-Prozess wird dabei nicht gestartet.
$consumerGuards=@($ast.FindAll({param($node)$node-is[Management.Automation.Language.FunctionDefinitionAst]-and$node.Name-ceq'Assert-JsonTrustConsumersAbsent'},$true))
$consumerCalls=@($ast.FindAll({param($node)$node-is[Management.Automation.Language.CommandAst]-and$node.GetCommandName()-ceq'Assert-JsonTrustConsumersAbsent'},$true))
$trustDrops=@($ast.FindAll({param($node)$node-is[Management.Automation.Language.CommandAst]-and$node.GetCommandName()-ceq'Sql'-and$node.Extent.Text.Contains('EXEC sys.sp_drop_trusted_assembly')},$true))
if($consumerGuards.Count-ne1-or$consumerCalls.Count-ne1-or$trustDrops.Count-ne1-or$consumerCalls[0].Extent.StartOffset-ge$trustDrops[0].Extent.StartOffset){throw 'JSON_SCOPE_CONSUMER_GUARD_ORDER'}
. ([scriptblock]::Create($consumerGuards[0].Extent.Text))
function Sql($Connection,[string]$Text,[hashtable]$Parameters=@{},[switch]$Rows){
 if(-not$Rows-or$Text-notmatch'^SELECT '){throw 'JSON_SCOPE_CONSUMER_PROBE_NOT_READ_ONLY'}
 if($Text.Contains('IS_SRVROLEMEMBER')){return [pscustomobject]@{Allowed=$(if($script:consumerScenario-ceq'visibility'){0}else{1})}}
 if($Text.Contains('FROM sys.databases')){
  $script:consumerCatalogReads++
  if($script:consumerScenario-ceq'catalog-empty'){return @()}
  $name=if($script:consumerScenario-ceq'catalog-change'-and$script:consumerCatalogReads-gt1){'Fabrikam'}else{'Contoso]Db'}
  return [pscustomobject]@{name=$name;state=$(if($script:consumerScenario-ceq'offline'){[byte]6}else{[byte]0})}
 }
 if($script:consumerScenario-ceq'read-failure'){throw 'synthetic private diagnostics'}
 if(-not$Text.Contains('[Contoso]]Db].sys.assemblies')-or$Parameters.Keys.Count-ne1-or-not$Parameters.ContainsKey('@Hash')-or$Parameters['@Hash'].Length-ne64){throw 'JSON_SCOPE_CONSUMER_QUERY_BINDING'}
 $script:consumerAssemblyReads++
 if($script:consumerScenario-ceq'result-empty'){return @()}
 $count=switch($script:consumerScenario){'present'{[long]1};'negative'{[long]-1};'malformed'{'0'};default{[long]0}}
 return [pscustomobject]@{Consumers=$count}
}
$consumerCases=@(
 @{Name='absent';Error=$null},
 @{Name='present';Error='JSON_SCHEMA_TRUST_CONSUMER_PRESENT'},
 @{Name='visibility';Error='JSON_SCHEMA_TRUST_CONSUMER_VISIBILITY'},
 @{Name='catalog-empty';Error='JSON_SCHEMA_TRUST_CONSUMER_CATALOG'},
 @{Name='offline';Error='JSON_SCHEMA_TRUST_CONSUMER_DATABASE_UNAVAILABLE'},
 @{Name='read-failure';Error='JSON_SCHEMA_TRUST_CONSUMER_READ_FAILED'},
 @{Name='result-empty';Error='JSON_SCHEMA_TRUST_CONSUMER_RESULT'},
 @{Name='negative';Error='JSON_SCHEMA_TRUST_CONSUMER_RESULT'},
 @{Name='malformed';Error='JSON_SCHEMA_TRUST_CONSUMER_RESULT'},
 @{Name='catalog-change';Error='JSON_SCHEMA_TRUST_CONSUMER_CATALOG_CHANGED'}
)
foreach($case in $consumerCases){
 $script:consumerScenario=$case.Name;$script:consumerCatalogReads=0;$script:consumerAssemblyReads=0;$actual=$null
 try{Assert-JsonTrustConsumersAbsent $null ([byte[]]::new(64))}catch{$actual=$_.Exception.Message}
 if($actual-cne$case.Error){throw 'JSON_SCOPE_CONSUMER_EXPECTED_OUTCOME'}
 if($case.Name-cin@('visibility','catalog-empty','offline')-and$script:consumerAssemblyReads-ne0){throw 'JSON_SCOPE_CONSUMER_EARLY_STOP'}
}
try{Assert-JsonTrustConsumersAbsent $null ([byte[]]::new(63));throw 'JSON_SCOPE_CONSUMER_HASH_ACCEPTED'}catch{if($_.Exception.Message-cne'JSON_SCHEMA_TRUST_CONSUMER_HASH'){throw}}
'PASS JSON_TRUST_CONSUMER_GUARD 11'
