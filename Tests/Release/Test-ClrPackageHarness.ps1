Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
foreach($file in @('Invoke-ClrPackageLab.ps1','Invoke-ClrPackageMatrix.ps1')){
 $errors=$null;$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot $file),[ref]$null,[ref]$errors)
 if($errors.Count){throw 'CLR_HARNESS_PARSE'}
 if($file -ceq 'Invoke-ClrPackageMatrix.ps1'){
  $coverage=@($ast.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq 'Assert-ClrWaveCoverage'},$true))
  if($coverage.Count -ne 1){throw 'CLR_COVERAGE_GUARD_MISSING'}
  . ([scriptblock]::Create($coverage[0].Extent.Text))
  Assert-ClrWaveCoverage @{completed=@(0)} 1
  Assert-ClrWaveCoverage @{completed=@(0..11)} 0 -Final
  foreach($bad in @(@{completed=@()},@{completed=@(0,0)},@{completed=@(12)})){
   $rejected=$false;try{Assert-ClrWaveCoverage $bad 1 -Final}catch{$rejected=$true}
   if(-not $rejected){throw 'CLR_COVERAGE_GUARD_BYPASSED'}
  }
  # Reale Budgetausdrücke gegen JSON-Roundtrip und beide Datumskulturen prüfen;
  # keine Verbindungs-, Dateischreib- oder Prozessstartblöcke ausführen.
  $expressions=@($ast.FindAll({param($n)$n -is [Management.Automation.Language.AssignmentStatementAst] -and $n.Left -is [Management.Automation.Language.VariableExpressionAst] -and $n.Left.VariablePath.UserPath -ceq 'elapsed'},$true))
  if($expressions.Count -ne 2){throw 'CLR_BUDGET_EXPRESSIONS_MISSING'}
  $original=[Globalization.CultureInfo]::CurrentCulture
  try{
   foreach($culture in @('de-AT','en-US')){
    [Globalization.CultureInfo]::CurrentCulture=[Globalization.CultureInfo]::new($culture)
    $started=[DateTime]::UtcNow.AddSeconds(-300).ToString('o')
    $parsed=('{"startedUtc":"'+$started+'"}')|ConvertFrom-Json -AsHashtable
    foreach($representation in @($started,$parsed.startedUtc)){
     $budget=@{startedUtc=$representation}
     foreach($expression in $expressions){
      $elapsed=& ([scriptblock]::Create($expression.Right.Extent.Text))
      if($elapsed -lt 295 -or $elapsed -gt 310){throw 'CLR_SHARED_BUDGET_RESET_OR_CULTURE_DRIFT'}
     }
    }
   }
  }finally{[Globalization.CultureInfo]::CurrentCulture=$original}
 }
}
$errors=$null;$installer=[Management.Automation.Language.Parser]::ParseFile((Join-Path $root 'Scripts/Release/Install-ClrPackage.ps1'),[ref]$null,[ref]$errors)
if($errors.Count){throw 'CLR_INSTALLER_PARSE'}
$entry=@($installer.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq 'Invoke-ClREntry'},$true))
if($entry.Count -ne 1){throw 'CLR_INSTALLER_ENTRY_MISSING'}
. ([scriptblock]::Create($entry[0].Extent.Text))
$ServerInstance='localhost'
$sqlcmd=[pscustomobject]@{Source={ $script:captured=@($args);$global:LASTEXITCODE=0 }}
foreach($trust in @($false,$true)){
 $TrustServerCertificate=$trust
 Invoke-ClREntry 'synthetic.sql' 'ToolbeltSynthetic'
 $expected='-S|localhost|-d|ToolbeltSynthetic|-E|-N|-f|65001|-b|-i|synthetic.sql'
 if($trust){$expected+='|-C'}
 if(($script:captured -join '|') -cne $expected){throw 'CLR_INSTALLER_TRANSPORT_OR_UTF8_CONTRACT'}
}
$script:calls=0;$sqlcmd=[pscustomobject]@{Source={$script:calls++;$global:LASTEXITCODE=1}}
$rejected=$false;try{Invoke-ClREntry 'synthetic.sql' 'ToolbeltSynthetic'}catch{$rejected=$_.Exception.Message -ceq 'CLR_PACKAGE_SQLCMD_FAILED_STOP'}
if(-not $rejected -or $script:calls -ne 1){throw 'CLR_INSTALLER_RETRY_OR_ERROR_BYPASS'}
'PASS CLR_HARNESS shared budget/culture/coverage, encrypted UTF8 arguments, explicit trust and no retry; no SQL'
