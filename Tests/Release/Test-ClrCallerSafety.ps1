# Isolierte Negativprüfungen der Konfigurationsgrenzen; keine SQL-Verbindung.
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'ClrCaller.Environment.ps1'),[ref]$null,[ref]$errors)
if($errors.Count){throw 'CLR_SAFETY_PARSE'}
foreach($name in @('Start-ClrCallerConfiguration','Restore-ClrCallerConfiguration','Assert-ClrCallerConfiguration','Get-ClrCallerPendingConfiguration')){
 $nodes=@($ast.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq $name},$true))
 if($nodes.Count -ne 1){throw 'CLR_SAFETY_IMPORT'}
 . ([scriptblock]::Create($nodes[0].Extent.Text))
}
function Reset-Mock([int]$Enabled){
 $script:rows=@(
  [pscustomobject]@{Name='clr enabled';Configured=$Enabled;Effective=$Enabled;IsAdvanced=0},
  [pscustomobject]@{Name='clr strict security';Configured=1;Effective=1;IsAdvanced=1},
  [pscustomobject]@{Name='Contoso unrelated';Configured=0;Effective=0;IsAdvanced=0})
 $script:consumers=0;$script:writes=0
 $script:ledger=@{configuration=@{changed=$false;state='UNPREPARED';before=@()}}
}
function Get-ClrCallerConfiguration($Control){@($script:rows|ConvertTo-Json -Depth 4|ConvertFrom-Json)}
function Get-ClrCallerUserAssemblyCount($Control){$script:consumers}
function Save-ReleaseJournal {}
function Invoke-ReleaseSql($Control,[string]$Sql){
 $script:writes++
 $value=if($Sql -match "sp_configure N'clr enabled',1"){1}elseif($Sql -match "sp_configure N'clr enabled',0"){0}else{throw 'CLR_SAFETY_UNKNOWN_WRITE'}
 $script:rows[0].Configured=$value;$script:rows[0].Effective=$value
}
function Assert-Refused([scriptblock]$Action,[string]$Expected){
 $caught=$false
 try{& $Action}catch{if($_.Exception.Message -cne $Expected){throw};$caught=$true}
 if(-not $caught){throw 'CLR_SAFETY_EXPECTED_REFUSAL'}
}
Reset-Mock 1
Start-ClrCallerConfiguration $null;Restore-ClrCallerConfiguration $null
if($script:writes -ne 0 -or $ledger.configuration.changed){throw 'CLR_SAFETY_PREEXISTING_CHANGED'}
Reset-Mock 0
$script:rows[2].Configured=1
Assert-Refused {Start-ClrCallerConfiguration $null} 'CLR_CALLER_CONFIGURATION_SCOPE_UNSAFE'
if($script:writes){throw 'CLR_SAFETY_PENDING_MUTATED'}
Reset-Mock 0
$script:consumers=1
Assert-Refused {Start-ClrCallerConfiguration $null} 'CLR_CALLER_EXISTING_CONSUMERS_NO_ENABLE'
if($script:writes){throw 'CLR_SAFETY_CONSUMER_MUTATED'}
Reset-Mock 0
Start-ClrCallerConfiguration $null;Restore-ClrCallerConfiguration $null
if($script:writes -ne 2 -or $ledger.configuration.state -cne 'RESTORED' -or $script:rows[0].Effective -ne 0){throw 'CLR_SAFETY_RESTORE'}
Reset-Mock 0
Start-ClrCallerConfiguration $null
$script:rows[2].Configured=1;$script:rows[2].Effective=1
Assert-Refused {Restore-ClrCallerConfiguration $null} 'CLR_CALLER_FOREIGN_CONFIGURATION_DRIFT'
if($script:writes -ne 1){throw 'CLR_SAFETY_FOREIGN_OVERWRITTEN'}
Reset-Mock 0
Start-ClrCallerConfiguration $null
$script:consumers=1
Assert-Refused {Restore-ClrCallerConfiguration $null} 'CLR_CALLER_NEW_CONSUMERS_NO_RESTORE'
if($script:writes -ne 1){throw 'CLR_SAFETY_NEW_CONSUMER_DISABLED'}
Reset-Mock 0
$script:rows+=@(
 [pscustomobject]@{Name='min server memory (MB)';Configured=0;Effective=16;IsAdvanced=1},
 [pscustomobject]@{Name='max server memory (MB)';Configured=0;Effective=2147483647;IsAdvanced=1})
Start-ClrCallerConfiguration $null;Restore-ClrCallerConfiguration $null
if($script:writes -ne 2 -or $script:rows[3].Configured -ne 0 -or $script:rows[3].Effective -ne 16){throw 'CLR_SAFETY_NORMALIZATION_CHANGED'}
Reset-Mock 0
$script:rows+=[pscustomobject]@{Name='min server memory (MB)';Configured=128;Effective=256;IsAdvanced=1}
Assert-Refused {Start-ClrCallerConfiguration $null} 'CLR_CALLER_CONFIGURATION_SCOPE_UNSAFE'
if($script:writes){throw 'CLR_SAFETY_REAL_MEMORY_PENDING_MUTATED'}
Reset-Mock 0
Start-ClrCallerConfiguration $null
$script:rows[0].Configured=0
Assert-Refused {Restore-ClrCallerConfiguration $null} 'CLR_CALLER_CONFIGURATION_OWNERSHIP_DRIFT'
if($script:writes -ne 1){throw 'CLR_SAFETY_FOREIGN_CLR_PENDING_ACTIVATED'}
Reset-Mock 0
Start-ClrCallerConfiguration $null
$ledger.configuration.state='ACTIVATING';$script:rows[0].Effective=0
Restore-ClrCallerConfiguration $null
if($script:writes -ne 2 -or $ledger.configuration.state -cne 'RESTORED'){throw 'CLR_SAFETY_OWN_PARTIAL_NOT_RESTORED'}
'PASS CLR caller safety: ten isolated configuration/ownership checks; no SQL'
