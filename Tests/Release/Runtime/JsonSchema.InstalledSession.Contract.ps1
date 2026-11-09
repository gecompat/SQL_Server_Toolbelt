# New installed-Uninstall inputs only; original healthy-caller oracle reused.
foreach($block in Import-ClrFunctions (Join-Path $repo 'Tests/Release/Invoke-JsonSchemaAppLockLab.ps1') @(
 'Read-Scalar','Get-ModuleState','Get-ExternalSessionState','Test-ExternalSessionIdle')){. $block}
foreach($block in Import-ClrFunctions (Join-Path $repo 'Tests/Release/Invoke-JsonSchemaCallerTransactionLab.ps1') @(
 'Get-WitnessValue','Get-LocalTransactionState','Assert-ExternalActiveTransaction','Invoke-BlockedTransactionCase')){. $block}
function Sql($Connection,[string]$Text,[hashtable]$Parameters=@{},[switch]$Rows){Invoke-ReleaseSql $Connection $Text $Parameters -Rows:$Rows}
function Save-Journal{Save-ReleaseJournal}
function Invoke-PinnedLifecycle([string]$Operation){
 if($Operation-cne'uninstall'){throw 'JSON_INSTALLED_ONLY_UNINSTALL_GUARD'}
 Assert-ReleaseInputs;Invoke-ReleaseBatches $script:guardConnection ([IO.File]::ReadAllText($runset.scripts.uninstall))
}
function Invoke-JsonSchemaInstalledSessionProfiles($Db,$Observer){
 if([int](Read-Scalar $Db "SELECT CASE WHEN OBJECT_ID(N'toolbelt_json.USP_ValidateJsonSchema',N'P') IS NOT NULL THEN 1 ELSE 0 END ScalarValue;")-ne1){throw 'JSON_INSTALLED_SCHEMA_REQUIRED'}
 Sql $Db 'CREATE TABLE dbo.JsonSchemaCallerTransactionWitness(WitnessId int NOT NULL PRIMARY KEY,WitnessValue int NOT NULL);INSERT dbo.JsonSchemaCallerTransactionWitness VALUES(1,100);'
 $before=Get-ModuleState $Db;$script:guardConnection=$Db;$ordinal=0
 foreach($profile in @(@{xa=$false;nc=$true},@{xa=$true;nc=$false},@{xa=$true;nc=$true})){
  $xa=if($profile.xa){'ON'}else{'OFF'};$nc=if($profile.nc){'ON'}else{'OFF'}
  Sql $Db "SET QUOTED_IDENTIFIER ON;SET IMPLICIT_TRANSACTIONS OFF;SET XACT_ABORT $xa;SET NOCOUNT $nc;"
  $options=[int](Read-Scalar $Db 'SELECT @@OPTIONS ScalarValue;')
  if(($options-band256)-eq0-or($options-band2)-ne0-or[bool]($options-band16384)-ne$profile.xa-or[bool]($options-band512)-ne$profile.nc){throw 'JSON_INSTALLED_ACTUAL_SESSION_PROFILE'}
  $case=[pscustomobject]@{ordinal=$ordinal;operation='uninstall';expected_message='JSON_SCHEMA_CALLER_TRANSACTION: aktive Callertransaktion ausgeschlossen.'}
  $prior=@($ledger.results).Count;Invoke-BlockedTransactionCase $Db $Observer $case $before $options
  if(@($ledger.results).Count-ne($prior+1)){throw 'JSON_INSTALLED_ORIGINAL_RECEIPT_REQUIRED'}
  $ledger.results[-1]['xact_abort']=[bool]$profile.xa;$ledger.results[-1]['nocount']=[bool]$profile.nc
  $ledger.results[-1]['installed_module']=$true;$ledger.results[-1]['observed_options']=$options
  Save-ReleaseJournal;$ordinal++
 }
 if((Get-ModuleState $Db)-cne$before){throw 'JSON_INSTALLED_FINAL_STATE_DRIFT'}
}
