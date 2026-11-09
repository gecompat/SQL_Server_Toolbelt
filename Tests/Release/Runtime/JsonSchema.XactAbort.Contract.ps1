# Originales Caller-/Savepoint-/Observerorakel; nur der neue Sessioninput variiert.
foreach($block in Import-ClrFunctions (Join-Path $repo 'Tests/Release/Invoke-JsonSchemaAppLockLab.ps1') @(
 'Read-Scalar','Get-ModuleState','Get-ExternalSessionState','Test-ExternalSessionIdle')){. $block}
foreach($block in Import-ClrFunctions (Join-Path $repo 'Tests/Release/Invoke-JsonSchemaCallerTransactionLab.ps1') @(
 'Get-WitnessValue','Get-LocalTransactionState','Assert-ExternalActiveTransaction','Invoke-BlockedTransactionCase')){. $block}
function Sql($Connection,[string]$Text,[hashtable]$Parameters=@{},[switch]$Rows){
 Invoke-ReleaseSql $Connection $Text $Parameters -Rows:$Rows
}
function Save-Journal{Save-ReleaseJournal}
function Invoke-PinnedLifecycle([string]$Operation){
 if($Operation-cnotin@('deploy','uninstall')){throw 'JSON_XACT_ABORT_OPERATION_SCOPE'}
 Assert-ReleaseInputs
 Invoke-ReleaseBatches $script:guardConnection ([IO.File]::ReadAllText($runset.scripts.$Operation))
}
function Invoke-JsonSchemaXactAbortProfiles($Db,$Observer){
 if([int](Read-Scalar $Db "SELECT COUNT(*) ScalarValue FROM sys.assemblies WHERE is_user_defined=1;")-ne0-or
    [int](Read-Scalar $Db "SELECT COUNT(*) ScalarValue FROM sys.schemas WHERE name IN(N'toolbelt_core',N'toolbelt_json');")-ne0){throw 'JSON_XACT_ABORT_EMPTY_MODULE_REQUIRED'}
 Sql $Db 'CREATE TABLE dbo.JsonSchemaCallerTransactionWitness(WitnessId int NOT NULL PRIMARY KEY,WitnessValue int NOT NULL); INSERT dbo.JsonSchemaCallerTransactionWitness VALUES(1,100);'
 $before=Get-ModuleState $Db;$ordinal=0;$script:guardConnection=$Db
 foreach($operation in @('deploy','uninstall')){
  foreach($noCount in @(0,1)){
   $count=if($noCount){'ON'}else{'OFF'}
   Sql $Db ("SET QUOTED_IDENTIFIER ON; SET IMPLICIT_TRANSACTIONS OFF; SET XACT_ABORT ON; SET NOCOUNT $count;")
   $options=[int](Read-Scalar $Db 'SELECT @@OPTIONS ScalarValue;')
   if(($options-band256)-eq0-or($options-band16384)-eq0-or($options-band2)-ne0-or
     [bool]($options-band512)-ne[bool]$noCount){throw 'JSON_XACT_ABORT_ACTUAL_SESSION_PROFILE'}
   $case=[pscustomobject]@{ordinal=$ordinal;operation=$operation;expected_message='JSON_SCHEMA_CALLER_TRANSACTION: aktive Callertransaktion ausgeschlossen.'}
   $prior=@($ledger.results).Count
   Invoke-BlockedTransactionCase $Db $Observer $case $before $options
   if(@($ledger.results).Count-ne($prior+1)){throw 'JSON_XACT_ABORT_ORIGINAL_RECEIPT_REQUIRED'}
   $ledger.results[-1]['xact_abort']=$true;$ledger.results[-1]['nocount']=[bool]$noCount
   $ledger.results[-1]['missing_module']=$true;$ledger.results[-1]['observed_options']=$options
   Save-ReleaseJournal;$ordinal++
  }
 }
}
