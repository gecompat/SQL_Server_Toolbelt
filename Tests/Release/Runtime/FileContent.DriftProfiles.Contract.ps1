# Ausschließlich eigene synthetische Definitionen und Konfiguration; keine Datei-I/O.
foreach($block in Import-ClrFunctions (Join-Path $PSScriptRoot 'LifecycleProfiles.Contract.ps1') @('Get-FileLifecycleState')){. $block}
function Get-FileDriftDefinition($Db,[string]$Name){
 $rows=@(Invoke-ReleaseSql $Db "SELECT o.object_id Id,CONVERT(varchar(64),HASHBYTES('SHA2_256',m.definition),2) Hash FROM sys.objects o JOIN sys.sql_modules m ON m.object_id=o.object_id WHERE o.schema_id=SCHEMA_ID(N'toolbelt_file') AND o.name=@Name AND o.type=N'P';" @{'@Name'=$Name} -Rows)
 if($rows.Count-ne1-or$rows[0].Id-le0-or$rows[0].Hash-cnotmatch'^[A-F0-9]{64}$'){throw 'FILE_DRIFT_DEFINITION_REQUIRED'}
 return $rows[0]
}
function Assert-FileDriftTransition($Baseline,$Observed,[bool]$Restored){
 if($Baseline.Id-le0-or$Observed.Id-ne$Baseline.Id-or$Baseline.Hash-cnotmatch'^[A-F0-9]{64}$'-or$Observed.Hash-cnotmatch'^[A-F0-9]{64}$'){
  throw 'FILE_DRIFT_STABLE_IDENTITY_REQUIRED'
 }
 if(($Restored-and$Observed.Hash-cne$Baseline.Hash)-or(-not$Restored-and$Observed.Hash-ceq$Baseline.Hash)){
  throw 'FILE_DRIFT_EXPECTED_BODY_TRANSITION'
 }
}
function Get-FileDriftData($Db){
 $sql=@'
SELECT RootPathId,CONVERT(varchar(max),CONVERT(varbinary(max),RootPath),2) RootBytes,
CONVERT(varchar(max),CONVERT(varbinary(max),Description),2) DescriptionBytes,IsActive,
CONVERT(varchar(16),CONVERT(varbinary(8),CreatedAt),2) CreatedBytes
FROM toolbelt_file.FileContentRootAllowlist ORDER BY RootPathId;
SELECT IDENT_CURRENT(N'toolbelt_file.FileContentRootAllowlist') IdentityValue;
SELECT class,major_id,minor_id,grantee_principal_id,grantor_principal_id,type,state FROM sys.database_permissions
ORDER BY class,major_id,minor_id,grantee_principal_id,grantor_principal_id,type,state;
'@
 return (@(Invoke-ReleaseSql $Db $sql -Rows)|ConvertTo-Json -Depth 5 -Compress)
}
function Invoke-FileDriftProfiles($Db,[string]$Mode){
 Invoke-ReleaseSql $Db @'
IF EXISTS(SELECT 1 FROM toolbelt_file.FileContentRootAllowlist) THROW 52098,N'Unexpected initial test data.',1;
INSERT toolbelt_file.FileContentRootAllowlist(RootPath,Description,IsActive,CreatedAt)
VALUES(N'/Contoso/FileContentDrift/Allowed',N'Contoso synthetic Ω',1,CONVERT(datetime2(0),'2001-01-01T00:00:00',126)),
(N'/Contoso/FileContentDrift/Inactive',NULL,0,CONVERT(datetime2(0),'2002-01-01T00:00:00',126));
'@
 $canonical=Get-FileLifecycleState $Db;$data=Get-FileDriftData $Db
 $deploy=Get-FileDriftText $Mode
 foreach($name in @('USP_LoadBinaryFile','USP_LoadTextFile')){
  $baseline=Get-FileDriftDefinition $Db $name
  # Der feste Name stammt ausschließlich aus der oben geschlossenen Liste.
  Invoke-ReleaseBatches $Db ("SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;`nGO`nALTER PROCEDURE toolbelt_file.[$name] AS SELECT CONVERT(nvarchar(64),N'Contoso synthetic definition drift') Drift;`nGO")
  $drift=Get-FileDriftDefinition $Db $name
  Assert-FileDriftTransition $baseline $drift $false
  if((Get-FileLifecycleState $Db)-ceq$canonical-or(Get-FileDriftData $Db)-cne$data){throw 'FILE_DRIFT_NOT_ISOLATED'}
  $receipt=[ordered]@{mode=$Mode;object=$name;objectId=$baseline.Id;baselineHash=$baseline.Hash;driftHash=$drift.Hash;restoredHash=$null;driftEstablished=$true;restored=$false;configurationUnchanged=$false}
  $ledger.driftReceipts+=@($receipt);Save-ReleaseJournal
  Invoke-ReleaseBatches $Db $deploy
  $after=Get-FileDriftDefinition $Db $name
  Assert-FileDriftTransition $baseline $after $true
  if((Get-FileLifecycleState $Db)-cne$canonical-or(Get-FileDriftData $Db)-cne$data){throw 'FILE_DRIFT_CANONICAL_STATE_NOT_RESTORED'}
  $receipt.restoredHash=$after.Hash;$receipt.restored=$true;$receipt.configurationUnchanged=$true
  $ledger.profileCompletions+=@(@{mode=$Mode;profile=$name;restored=$true;configurationUnchanged=$true});Save-ReleaseJournal
 }
}
