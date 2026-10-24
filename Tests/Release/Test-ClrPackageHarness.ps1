Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
foreach($file in @('Invoke-ClrPackageLab.ps1','Invoke-ClrPackageMatrix.ps1','Invoke-CompletePackageLab.ps1','Invoke-CompletePackageMatrix.ps1')){
 $errors=$null;$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot $file),[ref]$null,[ref]$errors)
 if($errors.Count){throw 'CLR_HARNESS_PARSE'}
 if($file.EndsWith('Matrix.ps1')){
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
# Den realen Auswahl-Ausdruck mit zwei vorhandenen Anwendungstreffern prüfen.
# Der Aufruf darf genau das erste Tool erreichen, nie ein zusammengefügtes
# Array als Befehlsnamen oder einen zweiten Versuch nach einem Fehler.
$selection=@($installer.FindAll({param($n)$n -is [Management.Automation.Language.AssignmentStatementAst] -and $n.Left -is [Management.Automation.Language.VariableExpressionAst] -and $n.Left.VariablePath.UserPath -ceq 'sqlcmd'},$true))
if($selection.Count -ne 1){throw 'CLR_INSTALLER_TOOL_SELECTION_MISSING'}
$lookup=New-Module -ScriptBlock {
 function Get-Command {
  [CmdletBinding()]param($Name,$CommandType)
  @([pscustomobject]@{Source='Invoke-SyntheticFirstSqlcmd'},[pscustomobject]@{Source='Invoke-SyntheticSecondSqlcmd'})
 }
}
$sqlcmd=& $lookup {param($source) & ([scriptblock]::Create($source))} $selection[0].Right.Extent.Text
$script:selectedCalls=0
function Invoke-SyntheticFirstSqlcmd {$script:selectedCalls++;$script:captured=@($args);$global:LASTEXITCODE=0}
function Invoke-SyntheticSecondSqlcmd {throw 'CLR_INSTALLER_SECOND_TOOL_INVOKED'}
Invoke-ClREntry 'synthetic.sql' 'ToolbeltSynthetic'
if($script:selectedCalls -ne 1){throw 'CLR_INSTALLER_MULTIPLE_TOOL_SELECTION'}

# SQL-Anmeldung nur durch explizite Credentialwahl. Passwort ausschließlich
# im Kindprozessenvironment; Elternzustand bleibt auch währenddessen erhalten.
$testSecret='synthetic-'+[guid]::NewGuid().ToString('N')
$credential=[Management.Automation.PSCredential]::new('ContosoSyntheticCaller',(ConvertTo-SecureString $testSecret -AsPlainText -Force))
$originalPassword=[Environment]::GetEnvironmentVariable('SQLCMDPASSWORD','Process')
function Invoke-ClRSqlcmdProcess([Diagnostics.ProcessStartInfo]$StartInfo){
 $script:credentialCalls++;$script:captured=@($StartInfo.ArgumentList);$script:capturedStart=$StartInfo
 if($StartInfo.Environment['SQLCMDPASSWORD'] -cne $testSecret){throw 'CLR_INSTALLER_SECRET_NOT_IN_CHILD_ENVIRONMENT'}
 if([Environment]::GetEnvironmentVariable('SQLCMDPASSWORD','Process') -cne $expectedPrior){throw 'CLR_INSTALLER_PARENT_SECRET_ENVIRONMENT_CHANGED'}
 if($throwBeforeExit){throw 'SYNTHETIC_SQLCMD_START_ERROR'}
 return $script:credentialExit
}
try{
 foreach($priorPassword in @($null,'','synthetic-existing-environment')){
  $setupValue=if($null -eq $priorPassword){[NullString]::Value}else{$priorPassword}
  [Environment]::SetEnvironmentVariable('SQLCMDPASSWORD',$setupValue,'Process')
  $expectedPrior=[Environment]::GetEnvironmentVariable('SQLCMDPASSWORD','Process')
  $script:credentialCalls=0
  $script:credentialExit=0;$throwBeforeExit=$false
  $sqlcmd=[pscustomobject]@{Source='synthetic-sqlcmd.exe'}
  Invoke-ClREntry 'synthetic.sql' 'ToolbeltSynthetic' $credential
  if(($script:captured -join '|') -cne '-S|localhost|-d|ToolbeltSynthetic|-U|ContosoSyntheticCaller|-N|-f|65001|-b|-i|synthetic.sql|-C' -or
     $script:captured -contains '-P' -or $script:captured -contains $testSecret -or $script:credentialCalls -ne 1){throw 'CLR_INSTALLER_SQL_IDENTITY_ARGUMENTS_OR_RETRY'}
  if([Environment]::GetEnvironmentVariable('SQLCMDPASSWORD','Process') -cne $expectedPrior){throw 'CLR_INSTALLER_PASSWORD_ENVIRONMENT_DRIFT'}
  if($script:capturedStart.Environment.ContainsKey('SQLCMDPASSWORD')){throw 'CLR_INSTALLER_CHILD_SECRET_NOT_RELEASED'}
  foreach($throwBeforeExit in @($false,$true)){
   $script:credentialExit=1
   $beforeCalls=$script:credentialCalls;$rejected=$false
   try{Invoke-ClREntry 'synthetic.sql' 'ToolbeltSynthetic' $credential}catch{$rejected=$_.Exception.Message -cin @('CLR_PACKAGE_SQLCMD_FAILED_STOP','SYNTHETIC_SQLCMD_START_ERROR')}
   if(-not $rejected -or $script:credentialCalls -ne $beforeCalls+1 -or
      [Environment]::GetEnvironmentVariable('SQLCMDPASSWORD','Process') -cne $expectedPrior -or
      $script:capturedStart.Environment.ContainsKey('SQLCMDPASSWORD')){throw 'CLR_INSTALLER_FAILURE_RESTORATION_OR_RETRY'}
  }
 }
}finally{
 $restoreValue=if($null -eq $originalPassword){[NullString]::Value}else{$originalPassword}
 [Environment]::SetEnvironmentVariable('SQLCMDPASSWORD',$restoreValue,'Process');$testSecret=$null;$credential=$null
}
$script:calls=0;$sqlcmd=[pscustomobject]@{Source={$script:calls++;$global:LASTEXITCODE=1}}
$rejected=$false;try{Invoke-ClREntry 'synthetic.sql' 'ToolbeltSynthetic'}catch{$rejected=$_.Exception.Message -ceq 'CLR_PACKAGE_SQLCMD_FAILED_STOP'}
if(-not $rejected -or $script:calls -ne 1){throw 'CLR_INSTALLER_RETRY_OR_ERROR_BYPASS'}
'PASS CLR_HARNESS shared budget/culture/coverage, one selected tool, explicit encrypted UTF8 identities, child-only secret environment and no retry; no SQL'
