[CmdletBinding()]
param([ValidateSet('linux','windows')][string]$Platform,
 [ValidateSet('2019','2022','2025')][string]$Version,[string]$Patch,
 [switch]$SkipLongHeartbeat,[switch]$IdentityGuardsOnly,[switch]$ManagedOnly,[switch]$ManagedSqlOnly,[switch]$QueueUpgradeOnly)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if(-not $Platform -or -not $Version -or -not $Patch){throw 'Explicit Lab platform/version/patch selection required.'}
if(([int]$ManagedOnly.IsPresent+[int]$ManagedSqlOnly.IsPresent+[int]$QueueUpgradeOnly.IsPresent)-gt1){throw 'Select exactly one focused contract consumer.'}
$root=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$errors=$null;$tokens=$null
$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'run-lab-local.ps1'),[ref]$tokens,[ref]$errors)
if($errors.Count){throw 'Canonical Lab discovery has syntax errors.'}
foreach($name in @('Get-EnvironmentVariableValue','Resolve-LabContract','Test-LabTargetReady','Get-LabTargetsForSelector','New-LabConnectionString','Invoke-LabPreflight')){
 $definitions=@($ast.FindAll({param($node)$node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $name},$true))
 if($definitions.Count-ne1){throw 'Canonical Lab function not unique.'}
 . ([scriptblock]::Create($definitions[0].Extent.Text))
}
$lab=Resolve-LabContract
$promptPath=Get-EnvironmentVariableValue 'SQL_SERVER_LAB_TEST_ENV_PROMPT_FILE'
if($promptPath){$prompt=Get-Content -LiteralPath $promptPath -Raw;if([string]::IsNullOrWhiteSpace($prompt)){throw 'Lab supplemental instructions empty.'}}
$targets=@(Get-LabTargetsForSelector -Contract $lab.Contract -Selector ([pscustomobject]@{Platform=$Platform;Version=$Version;Patch=$Patch}))
if(-not$targets.Count){throw 'No explicitly selected eligible READY target.'}
$variable='TBX_EXTERNAL_QUEUE_TEST_CONNECTION'
$before=[Environment]::GetEnvironmentVariable($variable,'Process')
try{
 foreach($target in $targets){
  [void](Invoke-LabPreflight -Entry $target)
  [Environment]::SetEnvironmentVariable($variable,(New-LabConnectionString -Entry $target),'Process')
  $runtimeArguments=@{ConnectionStringEnvironmentVariable=$variable;ExpectedSqlVersion=$Version;
   SkipLongHeartbeat=$SkipLongHeartbeat;IdentityGuardsOnly=$IdentityGuardsOnly}
  if($ManagedOnly){$runtimeArguments.ManagedOnly=$true}
  if($ManagedSqlOnly){$runtimeArguments.ManagedSqlOnly=$true}
  if($QueueUpgradeOnly){$runtimeArguments.QueueUpgradeOnly=$true}
  & (Join-Path $root 'Workers/ExternalQueue/Tests/Runtime/Invoke-Contract.ps1') @runtimeArguments
 }
}finally{[Environment]::SetEnvironmentVariable($variable,$before,'Process');$targets=$null;$lab=$null}
