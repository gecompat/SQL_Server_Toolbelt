[CmdletBinding()]
param(
 [Parameter(Mandatory)][string]$LabModuleFile,
 [Parameter(Mandatory)][string]$TargetRunId,
 [Parameter(Mandatory)][string]$TargetInstanceId,
 [Parameter(Mandatory)][string]$ModuleDatabase,
 [Parameter(Mandatory)][string]$ConsumerDatabase,
 [Parameter(Mandatory)][byte[]]$PackageBytes,
 [Parameter(Mandatory)][string]$Catalog,
 [Parameter(Mandatory)][Data.DataTable]$Artifacts,
 [Parameter(Mandatory)][ValidatePattern('^[0-9A-F]{128}$')][string]$QualifiedProviderSha512,
 [Parameter(Mandatory)][string]$JournalDirectory
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$checks=0
function Check-Windows([bool]$Value,[string]$Name){if(-not $Value){throw ('SSIS_WINDOWS_ACCESS_'+$Name)};$script:checks++}
Import-Module $LabModuleFile -Force -DisableNameChecking
$invoke=@{RunId=$TargetRunId;InstanceId=$TargetInstanceId;WindowsAuthentication=$true;Database=$ConsumerDatabase;KeepConnection=$true;TimeoutSeconds=(Get-SsisNativeTimeout 90)}
$analysis=Invoke-SqlServerLabScript @invoke -ScriptPath (Join-Path $PSScriptRoot 'CurrentWindowsAccess.sql') -Parameters @{
 ModuleDatabase=$ModuleDatabase;ConsumerDatabase=$ConsumerDatabase;PackageBytes=$PackageBytes;Catalog=$Catalog;ExpectedAssembly=[Convert]::FromHexString($QualifiedProviderSha512)
}
$analysis|ConvertTo-Json -Depth 14|Set-Content -LiteralPath (Join-Path $JournalDirectory 'windows-analysis.json') -Encoding utf8
Check-Windows ($analysis.Success -and $analysis.Outcome -ceq 'SUCCEEDED') 'ANALYSIS_SUCCEEDED'
Check-Windows ($analysis.Authentication -ceq 'Windows' -and $analysis.AuthScheme -cin @('NTLM','KERBEROS')) 'REAL_WINDOWS_LOGIN'
Check-Windows ($analysis.ResultSets.Count -eq 1) 'EXACT_RESULTSETS'
Check-Windows ($analysis.ResultSets[0].Rows.Count -eq 1 -and $analysis.ResultSets[0].Rows[0][0] -ceq 'SSIS_WINDOWS_ANALYSIS_PASS' -and $analysis.ResultSets[0].Rows[0][1] -eq 38) 'CURRENT_HELP_BINARY_TEMPLATE_PLAN_ASSERTIONS'
Check-Windows ($analysis.ResultSets[0].Rows[0][3] -eq 2 -and $analysis.ResultSets[0].Rows[0][4] -ceq 'Grüße Ω') 'BOTH_COMPLETE_DEBUGSCRIPTS_AND_UNICODE'
$index=0
foreach($row in @($Artifacts.Select("ArtifactKind='DebugScript' AND IsExecutable=true",'Ordinal'))){
 $component=[string]$row.ComponentId;$script=[string]$row.Content
 Check-Windows ($component -cin @('Package\Flow\DestinationHigh','Package\Flow\DestinationDefault') -and $script.Contains("`nGO`n")) 'DEBUGSCRIPT_IDENTITY_AND_BATCHES'
 $path=Join-Path $JournalDirectory ('windows-debug-'+$index+'.sql')
 [IO.File]::WriteAllText($path,$script,[Text.UTF8Encoding]::new($false))
 $invoke.TimeoutSeconds=Get-SsisNativeTimeout 90
 $execution=Invoke-SqlServerLabScript @invoke -ScriptPath $path
 $execution|ConvertTo-Json -Depth 14|Set-Content -LiteralPath (Join-Path $JournalDirectory ('windows-debug-'+$index+'.json')) -Encoding utf8
 Check-Windows ($execution.Success -and $execution.Outcome -ceq 'SUCCEEDED') 'DEBUGSCRIPT_EXECUTED'
 Check-Windows ($execution.Authentication -ceq 'Windows' -and $execution.AuthScheme -ceq $analysis.AuthScheme) 'WINDOWS_AUTHENTICATION_PRESERVED'
 $targets=@($execution.ResultSets|Where-Object {$_.Columns -ccontains 'KeyA' -and $_.Columns -ccontains 'KeyB' -and $_.Columns -ccontains 'Adjusted'})
 Check-Windows ($targets.Count -eq 1) 'ONE_TYPED_TARGET_RESULT'
 $high=$component -ceq 'Package\Flow\DestinationHigh'
 Check-Windows ($targets[0].Rows.Count -eq $(if($high){2}else{3})) 'FIXED_SYNTHETIC_TARGET_ROW_COUNT'
 $index++
}
$record=[ordered]@{schemaVersion=1;profile='ssis-current-windows-access';result='PASS';authentication='Windows';authScheme=$analysis.AuthScheme;encrypted=$true;authenticatedTls='not executed';parameterCount=38;checks=$checks;debugScripts=2;scriptGenerationIdentity='same current API with real lowpriv SQL login';publicLabModuleSha256=(Get-FileHash -LiteralPath $LabModuleFile).Hash}
$record|ConvertTo-Json|Set-Content -LiteralPath (Join-Path $JournalDirectory 'windows-result.json') -Encoding utf8
"SSIS_CURRENT_WINDOWS_ACCESS_PASS $checks assertions; real Windows login and executed current DebugScript; Functional TLS only"
