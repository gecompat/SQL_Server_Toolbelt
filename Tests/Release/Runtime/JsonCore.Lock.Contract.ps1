# Direct Core scripts; Schema lock cases are not repeated.
foreach($block in Import-ClrFunctions (Join-Path $repo 'Tests/Release/Invoke-JsonSchemaUninstallAppLockLab.ps1') @('Read-CoreProjection')){. $block}
foreach($block in Import-ClrFunctions (Join-Path $repo 'Tests/Release/Invoke-JsonSchemaAppLockLab.ps1') @('Get-ExternalSessionState','Test-ExternalSessionIdle')){. $block}
function Sql($Connection,[string]$Text,[hashtable]$Parameters=@{},[switch]$Rows){Invoke-ReleaseSql $Connection $Text $Parameters -Rows:$Rows}
function Test-CoreLockErrorFacts($Errors){
 $bad=@($Errors|Where-Object{$_.Class-ge11})
 return $bad.Count-eq1-and$bad[0].Number-eq55627-and$bad[0].State-eq1-and$bad[0].Class-eq16-and$bad[0].Message-ceq'JSON Core: gemeinsame AppLock nicht verfügbar.'
}
function Assert-CoreLockNeutral($Db){
 $local=@(Sql $Db 'DECLARE @T int=@@TRANCOUNT,@X smallint=XACT_STATE();SELECT @T T,@X X,@@SPID Spid;' -Rows)
 if($local.Count-ne1-or$local[0].T-ne0-or$local[0].X-ne0-or$local[0].Spid-le0){throw 'CORE_LOCK_LOCAL_TRANSACTION_LEAK'}
 $state=Get-ExternalSessionState $control $local[0].Spid
 if(-not(Test-ExternalSessionIdle $state)){throw 'CORE_LOCK_EXTERNAL_TRANSACTION_OR_LOCK_LEAK'}
}
function Invoke-CoreLockProfiles($Db,[string]$Mode){
 $resource='toolbelt.deploy.json.shared-core'
 $contender=@(Sql $Db 'SELECT @@SPID Spid,DB_ID() DbId;' -Rows)
 if($contender.Count-ne1-or$contender[0].Spid-le0-or$contender[0].DbId-le0){throw 'CORE_LOCK_CONTENDER_IDENTITY'}
 foreach($operation in @('deploy','uninstall')){
  $scriptPath=if($operation-ceq'deploy'){$runset.exports.$Mode}else{$runset.uninstall}
  $before=Read-CoreProjection $Db
  $holder=Open-ReleaseConnection $Db.Database
  try{
   $tag=[guid]::NewGuid().ToByteArray();Sql $holder 'SET CONTEXT_INFO @Tag;' @{'@Tag'=$tag}
   $held=@(Sql $holder @'
DECLARE @R int;EXEC @R=sys.sp_getapplock @Resource=@Resource,@LockMode=N'Exclusive',@LockOwner=N'Session',@LockTimeout=0,@DbPrincipal=N'public';
SELECT @R R,@@SPID Spid,DB_ID() DbId,CONVERT(int,@@TRANCOUNT) T;
'@ @{'@Resource'=$resource} -Rows)
   if($held.Count-ne1-or$held[0].R-ne0-or$held[0].T-ne0-or$held[0].Spid-le0-or$held[0].Spid-eq$contender[0].Spid-or$held[0].DbId-ne$contender[0].DbId){throw 'CORE_LOCK_SEPARATE_OWN_HOLDER_REQUIRED'}
   $identity=@(Sql $control 'SELECT COUNT(*) N FROM sys.dm_exec_sessions WHERE session_id=TRY_CONVERT(int,@Spid) AND database_id=DB_ID(@Database) AND database_id=TRY_CONVERT(int,@DbId) AND context_info=@Tag;' @{'@Spid'=$held[0].Spid;'@Database'=$Db.Database;'@DbId'=$held[0].DbId;'@Tag'=$tag} -Rows)
   $modeBefore=@(Sql $holder "SELECT APPLOCK_MODE(N'public',@Resource,N'Session') M;" @{'@Resource'=$resource} -Rows)
   if($identity.Count-ne1-or$identity[0].N-ne1-or$modeBefore.Count-ne1-or$modeBefore[0].M-cne'Exclusive'){throw 'CORE_LOCK_REAL_EXCLUSIVE_LEASE_REQUIRED'}
   $denied=$false
   try{Assert-ReleaseInputs;Invoke-ReleaseBatches $Db ([IO.File]::ReadAllText($scriptPath))}catch{
    $leaf=$_.Exception;while($leaf-and$leaf-isnot[Data.SqlClient.SqlException]){$leaf=$leaf.InnerException}
    if(-not$leaf-or-not(Test-CoreLockErrorFacts $leaf.Errors)){throw};$denied=$true
   }
   if(-not$denied){throw 'CORE_LOCK_EXPECTED_DENIAL_MISSING'}
   if((Read-CoreProjection $Db)-cne$before){throw 'CORE_LOCK_DENIAL_CHANGED_CORE'}
   Assert-CoreLockNeutral $Db
   $modeAfter=@(Sql $holder "SELECT APPLOCK_MODE(N'public',@Resource,N'Session') M;" @{'@Resource'=$resource} -Rows)
   if($modeAfter.Count-ne1-or$modeAfter[0].M-cne'Exclusive'){throw 'CORE_LOCK_HOLDER_LEASE_LOST'}
   $ledger.profileCompletions+=@(@{mode=$Mode;operation=$operation;profile='blocked';passed=$true;number=55627;state=1;class=16;resource=$resource;separateSession=$true;exclusiveBeforeAfter=$true;snapshotPreserved=$true;contenderNeutral=$true});Save-ReleaseJournal
   $released=@(Sql $holder @'
DECLARE @R int;EXEC @R=sys.sp_releaseapplock @Resource=@Resource,@LockOwner=N'Session',@DbPrincipal=N'public';
SELECT @R R,APPLOCK_MODE(N'public',@Resource,N'Session') M;
'@ @{'@Resource'=$resource} -Rows)
   if($released.Count-ne1-or$released[0].R-ne0-or$released[0].M-cne'NoLock'){throw 'CORE_LOCK_OWN_RELEASE_UNVERIFIED'}
   Assert-ReleaseInputs;Invoke-ReleaseBatches $Db ([IO.File]::ReadAllText($scriptPath));Assert-CoreLockNeutral $Db
   if($operation-ceq'deploy'){
    if((Read-CoreProjection $Db)-cne$before){throw 'CORE_LOCK_REPEAT_CHANGED_CORE'}
   }else{
    $remaining=@(Sql $Db "SELECT (SELECT COUNT(*) FROM sys.assemblies WHERE name=N'Toolbelt_JsonCore') A,(SELECT COUNT(*) FROM sys.extended_properties WHERE class=0 AND name LIKE N'Toolbelt.Module.toolbelt.json.core.%') P;" -Rows)
    if($remaining.Count-ne1-or$remaining[0].A-ne0-or$remaining[0].P-ne0){throw 'CORE_LOCK_UNINSTALL_NOT_COMPLETE'}
   }
   $ledger.profileCompletions+=@(@{mode=$Mode;operation=$operation;profile='after-release';passed=$true;resource=$resource;releaseVerified=$true;canonicalState=$true;contenderNeutral=$true});Save-ReleaseJournal
  }finally{$holder.Dispose()}
 }
}
