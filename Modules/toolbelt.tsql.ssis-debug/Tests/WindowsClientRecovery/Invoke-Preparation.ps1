#Requires -Version 7.5
<#
Abnahme des öffentlichen Vorbereitungs-SQL mit vorhandenem Lab-Windowszugang.
Eigene Datenbank, genau ein eigener CLR-Parameter unter der bestehenden Lease.
Keine Labverwaltung oder Rechtevergabe. Finale Audits öffnen eine frische Sitzung.
#>
[CmdletBinding()]
param(
 [ValidateSet('Prepare','Run','Audit')][string]$Mode='Prepare',
 [Parameter(Mandatory)][string]$PlanPath,
 [ValidatePattern('^[0-9A-F]{64}$')][string]$ExpectedPlanSha256,
 [ValidateRange(0,2)][int]$CaseIndex=0,
 [string]$JournalPath,
 [ValidatePattern('^[0-9A-F]{64}$')][string]$ExpectedJournalSha256,
 [string]$LabModuleFile,
 [string]$BudgetPath,
 [switch]$ValidateOnly
)
Set-StrictMode -Version Latest;$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'LabClientCommon.ps1')
$PlanPath=[IO.Path]::GetFullPath($PlanPath)
if($JournalPath){$JournalPath=[IO.Path]::GetFullPath($JournalPath)}
if($BudgetPath){$BudgetPath=[IO.Path]::GetFullPath($BudgetPath)}
$relative='Modules/toolbelt.tsql.ssis-debug/'
$sources=@('Modules/toolbelt.tsql.ssis-debug/Tests/WindowsClientRecovery/Invoke-Preparation.ps1',
 'Modules/toolbelt.tsql.ssis-debug/Tests/WindowsClientRecovery/LabClientCommon.ps1',
 'Modules/toolbelt.tsql.ssis-debug/Examples/Installation/PrepareServer.sql','Tests/CI/LabQualifiedContract.ps1','Tests/CI/run-lab-local.ps1')
function Assert-PrivatePath([string]$Path){
 if(-not [IO.Path]::GetFullPath($Path).StartsWith((Join-Path $repoRoot '.runtime')+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'SSIS_PREPARATION_PRIVATE_PATH_REQUIRED'}
}
Assert-PrivatePath $PlanPath
if($Mode-ceq 'Prepare'){
 if(Test-Path -LiteralPath $PlanPath){throw 'SSIS_PREPARATION_PLAN_COLLISION'}
 if((Split-Path -Leaf $LabModuleFile)-cne 'SqlServerLab.psd1' -or -not (Test-Path -LiteralPath $LabModuleFile)){throw 'SSIS_PREPARATION_LAB_MODULE_REQUIRED'}
 $lab=Read-ClientLab
 $selected=@(foreach($s in @(@{V='2019';P='CU32'},@{V='2022';P='CU26'},@{V='2025';P='CU8'})){
  $t=Select-ClientTarget $lab $s.V $s.P
  @{version=$s.V;patch=$s.P;key=[string]$t.key}
 })
 $files=[ordered]@{};foreach($s in $sources){$files[$s]=Get-ClientHash (Join-Path $repoRoot $s)}
 $labRoot=Split-Path -Parent ([IO.Path]::GetFullPath($LabModuleFile))
 $commit=git -C $labRoot rev-parse HEAD
 if($LASTEXITCODE-ne 0 -or (git -C $labRoot status --porcelain --untracked-files=all)){throw 'SSIS_PREPARATION_LAB_CLEAN_COMMIT_REQUIRED'}
 $plan=@{contract='ssis-server-preparation/1';targets=$selected;files=$files;contractSha256=(Get-ClientHash $lab.Path);labModule=[IO.Path]::GetFullPath($LabModuleFile);labCommit=$commit}
 Save-ClientPrivate $PlanPath $plan
 'SSIS_PREPARATION_PLAN_PREPARED; no SQL';return
}
if(-not $ExpectedPlanSha256 -or (Get-ClientHash $PlanPath)-cne $ExpectedPlanSha256){throw 'SSIS_PREPARATION_PLAN_CHANGED'}
$plan=Get-Content -LiteralPath $PlanPath -Raw|ConvertFrom-Json -DateKind String
if($plan.contract-cne 'ssis-server-preparation/1' -or $plan.targets.Count-ne 3 -or
 (@($plan.targets|ForEach-Object {$_.version+'/'+$_.patch})-join ';')-cne '2019/CU32;2022/CU26;2025/CU8' -or
 @($plan.files.psobject.Properties).Count-ne $sources.Count){throw 'SSIS_PREPARATION_PLAN_SCHEMA'}
foreach($s in $sources){if((Get-ClientHash (Join-Path $repoRoot $s))-cne $plan.files.$s){throw 'SSIS_PREPARATION_SOURCE_CHANGED'}}
if($ValidateOnly){'SSIS_PREPARATION_INPUTS_VALIDATED; no SQL or Lab import';return}
Assert-PrivatePath $JournalPath;Assert-PrivatePath $BudgetPath
$lab=Read-ClientLab
if((Get-ClientHash $lab.Path)-cne $plan.contractSha256){throw 'SSIS_PREPARATION_CONTRACT_CHANGED'}
$selection=$plan.targets[$CaseIndex];$target=Select-ClientTarget $lab $selection.version $selection.patch
if($target.key-cne $selection.key){throw 'SSIS_PREPARATION_SELECTION_CHANGED'}
$labRoot=Split-Path -Parent $plan.labModule
if((git -C $labRoot rev-parse HEAD)-cne $plan.labCommit -or (git -C $labRoot status --porcelain --untracked-files=all)){throw 'SSIS_PREPARATION_LAB_CHANGED'}
Reserve-ClientCase $BudgetPath
$c=Open-ClientSql $target
$journal=$null;$lease=$false;$failure=$null;$guestDispatches=0
function Check([bool]$Value,[string]$Name){
 if(-not $Value){throw ('SSIS_PREPARATION_'+$Name)}
 $script:journal.checks.Add($Name)
}
function Save {Save-ClientPrivate $JournalPath $script:journal}
function Reject([string]$Sql,[string]$Name){
 $number=0
 try{Exec-Client $c $Sql}catch{
  $e=$_.Exception;while($e -and $e-isnot [Data.SqlClient.SqlException]){$e=$e.InnerException}
  if(-not $e){throw};$number=$e.Number
 }
 Check ($number-eq 50000) $Name
}
function Run-PublicPreparation([bool]$RejectPending=$false){
 $script:guestDispatches++
 $result=Invoke-SqlServerLabScript -RunId $target.runId -InstanceId $target.instanceId -WindowsAuthentication -Database master -KeepConnection -ScriptPath $scriptPath -TimeoutSeconds 90 3>$null 4>$null 5>$null 6>$null
 Save-ClientPrivate ($JournalPath+'.guest-'+$script:guestDispatches+'.json') $result
 Check ($result.Authentication-ceq 'Windows' -and $result.AuthScheme-cin @('NTLM','KERBEROS')) 'ACTUAL_WINDOWS_GUEST_LOGIN'
 if($RejectPending){Check (-not $result.Success -and $result.SqlErrorNumber-eq 50000) 'GENUINE_PENDING_REJECTED'}
 else{Check ($result.Success -and $result.Outcome-ceq 'SUCCEEDED') 'PUBLIC_PREPARATION_SUCCEEDED'}
}
function Database-State([string]$Name){
 $r=Query-Client $c ("SELECT database_id,CONVERT(varchar(33),create_date,126) AS Created,compatibility_level,is_trustworthy_on,is_db_chaining_on FROM sys.databases WHERE name=N'"+$Name+"';")
 if($r.Rows.Count-eq 0){return $null}
 $x=$r.Rows[0];return [ordered]@{id=[int]$x.database_id;created=[string]$x.Created;cl=[int]$x.compatibility_level;trustworthy=[bool]$x.is_trustworthy_on;chaining=[bool]$x.is_db_chaining_on}
}
function Trust-Fingerprint {
 $r=Query-Client $c 'SELECT CONVERT(varchar(128),hash,2) AS H,description,CONVERT(varchar(33),create_date,126) AS C,created_by FROM sys.trusted_assemblies ORDER BY hash;'
 $text=@($r.Rows|ForEach-Object {[ordered]@{hash=[string]$_.H;description=[string]$_.description;created=[string]$_.C;by=[string]$_.created_by}})|ConvertTo-Json -Compress
 return [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes([string]$text)))
}
try{
 [void](Query-Client $c 'SELECT @@VERSION;');[void](Query-Client $c 'SELECT name,state_desc FROM sys.databases ORDER BY database_id;')
 $identity=Query-Client $c "SELECT CONVERT(int,SERVERPROPERTY('ProductMajorVersion')) AS V,CONVERT(nvarchar(32),SERVERPROPERTY('ProductUpdateLevel')) AS P,IS_SRVROLEMEMBER('sysadmin') AS A,(SELECT host_platform FROM sys.dm_os_host_info) AS O;"
 if($identity.Rows[0].V-ne (@{'2019'=15;'2022'=16;'2025'=17}[$selection.version]) -or $identity.Rows[0].P-ine $selection.patch -or $identity.Rows[0].A-ne 1 -or $identity.Rows[0].O-cne 'Windows'){throw 'SSIS_PREPARATION_ACTUAL_IDENTITY'}
 if($Mode-ceq 'Audit'){
  if(-not $ExpectedJournalSha256 -or (Get-ClientHash $JournalPath)-cne $ExpectedJournalSha256){throw 'SSIS_PREPARATION_AUDIT_JOURNAL_CHANGED'}
  $j=Get-Content -LiteralPath $JournalPath -Raw|ConvertFrom-Json -DateKind String
  if($j.planSha256-cne $ExpectedPlanSha256 -or $j.caseIndex-ne $CaseIndex -or $j.state-cnotin @('PASS_CLEANED','FAILED_CLEANED')){throw 'SSIS_PREPARATION_AUDIT_BINDING'}
  if((Database-State $j.database) -or -not (Same-Client (Get-ClientConfiguration $c) $j.beforeConfig) -or (Trust-Fingerprint)-cne $j.beforeTrust){throw 'SSIS_PREPARATION_AUDIT_DRIFT'}
  Save-ClientPrivate ($JournalPath+'.audit.json') @{result='PASS';journalSha256=$ExpectedJournalSha256;databaseAbsent=$true;configurationRestored=$true;trustUnchanged=$true}
  'SSIS_PREPARATION_INDEPENDENT_AUDIT_PASS';return
 }
 if(Test-Path -LiteralPath $JournalPath){throw 'SSIS_PREPARATION_JOURNAL_COLLISION'}
 $lock=Query-Client $c "DECLARE @r int;EXEC @r=sys.sp_getapplock @Resource=N'toolbelt.lab.clr.configuration',@LockOwner=N'Session',@LockMode=N'Exclusive',@LockTimeout=0;SELECT @r AS R;"
 if($lock.Rows[0].R-lt 0){throw 'SSIS_PREPARATION_LEASE_BUSY'};$lease=$true
 $before=Get-ClientConfiguration $c
 if(@($before|Where-Object {$_.C-ne $_.R -and -not (Test-ClientImplicit $_)}).Count){throw 'SSIS_PREPARATION_FOREIGN_PENDING_CONFIGURATION'}
 if(@($before|Where-Object {$_.name-ceq 'clr strict security' -and $_.C-eq 1 -and $_.R-eq 1}).Count-ne 1){throw 'SSIS_PREPARATION_STRICT_SECURITY_REQUIRED'}
 $db='ContosoSsisClient_'+[guid]::NewGuid().ToString('N');$token=[guid]::NewGuid().ToString('N')
 $journal=[ordered]@{contract='ssis-server-preparation-run/1';planSha256=$ExpectedPlanSha256;caseIndex=$CaseIndex;state='BEFORE_EFFECTS';database=$db;token=$token;databaseState=$null;beforeConfig=$before;beforeTrust=(Trust-Fingerprint);checks=[Collections.Generic.List[string]]::new();guestDispatches=0;ownsPendingClr=$false}
 Check (-not (Database-State $db)) 'OWN_DATABASE_ABSENT';Save
 $sql=[IO.File]::ReadAllText((Join-Path $repoRoot ($relative+'Examples/Installation/PrepareServer.sql')))
 if(($sql.Split("N'ContosoSsisDebug'").Count-1)-ne 1){throw 'SSIS_PREPARATION_DATABASE_ANCHOR'}
 $sql=$sql.Replace("N'ContosoSsisDebug'","N'"+$db+"'")
 $scriptPath=$JournalPath+'.public.sql';[IO.File]::WriteAllText($scriptPath,$sql,[Text.UTF8Encoding]::new($false))
 Import-Module $plan.labModule -Force -DisableNameChecking
 Run-PublicPreparation
 $journal.databaseState=Database-State $db
 Check ($journal.databaseState -and $journal.databaseState.cl-eq 150 -and -not $journal.databaseState.trustworthy -and -not $journal.databaseState.chaining) 'OWN_DATABASE_CREATED_SAFE_CL150'
 Exec-Client $c ('EXEC ['+$db+"].sys.sp_addextendedproperty @name=N'ToolbeltSsisClientOwner',@value=N'"+$token+"';")
 $journal.state='OWN_DATABASE_MARKED';Save
 Run-PublicPreparation
 Check (Same-Client (Database-State $db) $journal.databaseState) 'REPEAT_PRESERVES_DATABASE_OPTIONS'
 Reject ('BEGIN TRAN;'+$sql) 'OPEN_TRANSACTION_REJECTED';Exec-Client $c 'IF @@TRANCOUNT>0 ROLLBACK;'
 Reject ('SET IMPLICIT_TRANSACTIONS ON;'+$sql) 'IMPLICIT_TRANSACTION_REJECTED';Exec-Client $c 'SET IMPLICIT_TRANSACTIONS OFF;IF @@TRANCOUNT>0 ROLLBACK;'
 try{Exec-Client $c "EXECUTE AS USER=N'guest';";Reject $sql 'GUEST_ADMIN_GUARD_REJECTED'}finally{Exec-Client $c 'REVERT;'}
 # Eigene ausstehende CLR-Deaktivierung bleibt ausschließlich vorgemerkt.
 # Der öffentliche Guard muss vor RECONFIGURE sperren; danach zurück auf1.
 $journal.ownsPendingClr=$true;$journal.state='OWN_CLR_CHANGE_PLANNED';Save
 Exec-Client $c "EXEC sys.sp_configure N'clr enabled',0;";$journal.state='OWN_CLR_CHANGE_PENDING';Save
 Run-PublicPreparation $true
 $pending=@(Get-ClientConfiguration $c|Where-Object name -CEQ 'clr enabled')[0]
 Check ($pending.C-eq 0 -and $pending.R-eq 1) 'PENDING_NOT_APPLIED'
 Exec-Client $c "EXEC sys.sp_configure N'clr enabled',1;";$journal.ownsPendingClr=$false;$journal.state='QUALIFICATION_COMPLETE';Save
 Check (Same-Client (Database-State $db) $journal.databaseState) 'NEGATIVE_CASES_PRESERVE_DATABASE'
 Check ((Trust-Fingerprint)-ceq $journal.beforeTrust) 'NO_TRUST_MUTATION'
}catch{
 $failure=$_.Exception
 if($journal){$journal.failure=$failure.GetType().Name;$journal.failureCode=if($failure.Message-match '((?:SSIS|WINDOWS)_[A-Z0-9_]+)'){$Matches[1]}else{'UNCLASSIFIED'};$journal.state='FAILED_REQUIRES_CLEANUP';Save}
}finally{
 if($journal){
  try{
   Exec-Client $c 'SET IMPLICIT_TRANSACTIONS OFF;IF @@TRANCOUNT>0 ROLLBACK;'
   $actual=Database-State $journal.database
   if($actual){
    if(-not $journal.databaseState -or -not (Same-Client $actual $journal.databaseState)){throw 'SSIS_PREPARATION_DATABASE_OWNERSHIP_UNKNOWN'}
    $marker=Query-Client $c ('SELECT CONVERT(nvarchar(128),value) AS V FROM ['+$journal.database+"].sys.extended_properties WHERE class=0 AND name=N'ToolbeltSsisClientOwner';")
    if($marker.Rows.Count-ne 1 -or $marker.Rows[0].V-cne $journal.token){throw 'SSIS_PREPARATION_DATABASE_OWNER_CHANGED'}
    Exec-Client $c ('DROP DATABASE ['+$journal.database+'];')
   }
   $current=Get-ClientConfiguration $c
   foreach($row in $current){
    $old=@($journal.beforeConfig|Where-Object name -CEQ $row.name)[0]
    if($row.name-ceq 'clr enabled'){
     if($row.C-ne $row.R -and -not ($row.C-eq 0 -and $row.R-eq 1 -and $journal.ownsPendingClr)){throw 'SSIS_PREPARATION_CLR_DRIFT'}
    }elseif(-not (Same-Client $row $old)){throw 'SSIS_PREPARATION_FOREIGN_CONFIGURATION_DRIFT'}
   }
   $oldClr=@($journal.beforeConfig|Where-Object name -CEQ 'clr enabled')[0]
   $nowClr=@($current|Where-Object name -CEQ 'clr enabled')[0]
   if($nowClr.C-ne $oldClr.C -or $nowClr.R-ne $oldClr.R){Exec-Client $c ("EXEC sys.sp_configure N'clr enabled',"+$oldClr.C+';RECONFIGURE;')}
   Check (-not (Database-State $journal.database)) 'OWN_DATABASE_REMOVED'
   Check (Same-Client (Get-ClientConfiguration $c) $journal.beforeConfig) 'EXACT_CONFIGURATION_RESTORED'
   Check ((Trust-Fingerprint)-ceq $journal.beforeTrust) 'TRUST_UNCHANGED_AFTER_CLEANUP'
   $journal.state=if($failure){'FAILED_CLEANED'}else{'PASS_CLEANED'}
  }catch{$journal.state='RECOVERY_REQUIRED';$journal.cleanupFailure=$_.Exception.GetType().Name;if(-not $failure){$failure=$_.Exception}}
  $journal.guestDispatches=$guestDispatches;Save
 }
 if($lease){try{Exec-Client $c "EXEC sys.sp_releaseapplock @Resource=N'toolbelt.lab.clr.configuration',@LockOwner=N'Session';"}catch{}}
 $c.Dispose()
}
if($failure){throw 'SSIS_PREPARATION_FAILED_PRIVATE_JOURNAL'}
if(-not $journal -or $journal.state-cne 'PASS_CLEANED'){throw 'SSIS_PREPARATION_NOT_CLEANED'}
'SSIS_PREPARATION_PASS '+$selection.version+' assertions='+$journal.checks.Count+'; Windows guest; own database/config restored'
