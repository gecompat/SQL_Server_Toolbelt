# Zusätzliche Fremdobjektarten ausschließlich in eigenen synthetischen DBs.
function Get-CsvForeignKindCases([ValidateSet('view-procedure','synonym-function','table-functions',IgnoreCase=$false)][string]$Family='view-procedure'){
 foreach($name in @(Get-CsvForeignSlotNames)){
  if($Family -ceq 'table-functions'){
   # Beide SQL-TVF-Arten belegen nur den reservierten Namen; keine CSV-Fachlogik.
   [pscustomobject]@{Name=$name;Type='FUNCTION';Kind='IF';Sql="CREATE FUNCTION toolbelt_file.[$name]() RETURNS TABLE AS RETURN (SELECT CONVERT(int,73) Marker,CONVERT(nvarchar(32),N'guard ') Payload);";Read="SELECT Marker,Payload FROM toolbelt_file.[$name]();"}
   [pscustomobject]@{Name=$name;Type='FUNCTION';Kind='TF';Sql="CREATE FUNCTION toolbelt_file.[$name]() RETURNS @Rows TABLE(Marker int,Payload nvarchar(32)) AS BEGIN INSERT @Rows VALUES(73,N'guard ');RETURN;END;";Read="SELECT Marker,Payload FROM toolbelt_file.[$name]();"}
   continue
  }
  if($Family -ceq 'synonym-function'){
   [pscustomobject]@{Name=$name;Type='SYNONYM';Kind='SN';Sql="CREATE SYNONYM toolbelt_file.[$name] FOR toolbelt_file.CsvGuardAliasTarget;";Read="SELECT Marker,Payload FROM toolbelt_file.[$name];"}
   [pscustomobject]@{Name=$name;Type='FUNCTION';Kind='FN';Sql="CREATE FUNCTION toolbelt_file.[$name](@Delta int) RETURNS int AS BEGIN RETURN 73+@Delta; END;";Read="SELECT toolbelt_file.[$name](0) Marker,CONVERT(nvarchar(32),N'guard ') Payload;"}
   continue
  }
  [pscustomobject]@{Name=$name;Type='VIEW';Kind='V';Sql="CREATE VIEW toolbelt_file.[$name] AS SELECT CONVERT(int,73) Marker,CONVERT(nvarchar(32),N'guard ') Payload;";Read="SELECT Marker,Payload FROM toolbelt_file.[$name];"}
  [pscustomobject]@{Name=$name;Type='PROCEDURE';Kind='P';Sql="CREATE PROCEDURE toolbelt_file.[$name] AS SELECT CONVERT(int,73) Marker,CONVERT(nvarchar(32),N'guard ') Payload;";Read="EXEC toolbelt_file.[$name];"}
 }
}

function Get-CsvAliasTargetCase {
 [pscustomobject]@{Name='CsvGuardAliasTarget';Type='TABLE';Kind='U';Sql="CREATE TABLE toolbelt_file.CsvGuardAliasTarget(Marker int NOT NULL,Payload nvarchar(32) NOT NULL);INSERT toolbelt_file.CsvGuardAliasTarget VALUES(73,N'guard ');";Read='SELECT Marker,Payload FROM toolbelt_file.CsvGuardAliasTarget;'}
}

function Assert-CsvForeignKindCase($Case){
 $known=@(Get-CsvForeignKindCases;Get-CsvForeignKindCases 'synonym-function';Get-CsvForeignKindCases 'table-functions';Get-CsvAliasTargetCase)
 if(@($known|Where-Object {$_.Name -ceq $Case.Name -and $_.Type -ceq $Case.Type -and $_.Kind -ceq $Case.Kind -and $_.Sql -ceq $Case.Sql -and $_.Read -ceq $Case.Read}).Count -ne 1){throw 'CSV_FOREIGN_KIND_CASE_INVALID'}
}

function Test-CsvAliasTarget([object[]]$Rows){
 if($null -eq $Rows -or $Rows.Count -ne 1 -or $null -eq $Rows[0]){return $false}
 $columns=@($Rows[0].PSObject.Properties.Name)
 return $columns.Count -eq 1 -and $columns[0] -ceq 'TargetBytes' -and $Rows[0].TargetBytes -is [byte[]] -and
  [Convert]::ToHexString($Rows[0].TargetBytes) -ceq [Convert]::ToHexString([Text.Encoding]::Unicode.GetBytes('[toolbelt_file].[CsvGuardAliasTarget]'))
}

function Test-CsvForeignKindResult([object[]]$Rows){
 if($null -eq $Rows -or $Rows.Count -ne 1 -or $null -eq $Rows[0]){return $false}
 $columns=@($Rows[0].PSObject.Properties.Name)
 return $columns.Count -eq 2 -and $columns[0] -ceq 'Marker' -and $columns[1] -ceq 'Payload' -and
  $Rows[0].Marker -is [int] -and $Rows[0].Marker -eq 73 -and $Rows[0].Payload -is [string] -and
  [string]::Equals($Rows[0].Payload,'guard ',[StringComparison]::Ordinal)
}

function Get-CsvForeignKindIdentity($Connection,$Case){
 Assert-CsvForeignKindCase $Case
 $rows=@(Invoke-CsvSql $Connection @'
SELECT o.object_id Id,CONVERT(varchar(18),CONVERT(varbinary(max),CONVERT(datetime2(7),o.create_date)),2) Created
FROM sys.objects o WHERE o.schema_id=SCHEMA_ID(N'toolbelt_file') AND o.type=@Kind
 AND CONVERT(varbinary(max),o.name)=CONVERT(varbinary(max),@Name)
 AND EXISTS(SELECT 1 FROM sys.extended_properties p WHERE p.class=1 AND p.major_id=o.object_id AND p.minor_id=0
 AND p.name=N'Toolbelt.Test.CsvGuard.Owner' AND SQL_VARIANT_PROPERTY(p.value,N'BaseType')=N'nvarchar'
 AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),p.value))=CONVERT(varbinary(max),@Owner));
'@ @{'@Kind'=$Case.Kind;'@Name'=$Case.Name;'@Owner'=$script:ledger.RunId} -Rows)
 if($rows.Count -ne 1 -or $rows[0].Id -isnot [int] -or $rows[0].Id -le 0 -or $rows[0].Created -cnotmatch '^[A-F0-9]{18}$'){throw 'CSV_FOREIGN_KIND_IDENTITY_UNKNOWN'}
 return $rows[0]
}

function Add-CsvForeignKindOwner($Connection,$Case){
 Assert-CsvForeignKindCase $Case
 Invoke-CsvSql $Connection @"
DECLARE @Value nvarchar(32)=@Owner;
EXEC sys.sp_addextendedproperty @name=N'Toolbelt.Test.CsvGuard.Owner',@value=@Value,
 @level0type=N'SCHEMA',@level0name=N'toolbelt_file',@level1type=N'$($Case.Type)',@level1name=N'$($Case.Name)';
"@ @{'@Owner'=$script:ledger.RunId}
 return Get-CsvForeignKindIdentity $Connection $Case
}

function Remove-CsvForeignKind($Connection,$Case,$Identity){
 Assert-CsvForeignKindCase $Case
 $actual=Get-CsvForeignKindIdentity $Connection $Case
 if($actual.Id -ne $Identity.Id -or $actual.Created -cne $Identity.Created){throw 'CSV_FOREIGN_KIND_IDENTITY_CHANGED'}
 Invoke-CsvSql $Connection @"
IF NOT EXISTS(SELECT 1 FROM sys.objects o WHERE o.object_id=@Id AND o.schema_id=SCHEMA_ID(N'toolbelt_file') AND o.type=@Kind
 AND CONVERT(varbinary(max),o.name)=CONVERT(varbinary(max),@Name)
 AND CONVERT(varbinary(max),CONVERT(datetime2(7),o.create_date))=@Created
 AND EXISTS(SELECT 1 FROM sys.extended_properties p WHERE p.class=1 AND p.major_id=o.object_id AND p.minor_id=0
 AND p.name=N'Toolbelt.Test.CsvGuard.Owner' AND SQL_VARIANT_PROPERTY(p.value,N'BaseType')=N'nvarchar'
 AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),p.value))=CONVERT(varbinary(max),@Owner)))
 THROW 51598,N'Synthetic foreign kind changed.',1;
DROP $($Case.Type) toolbelt_file.[$($Case.Name)];
"@ @{'@Id'=[int]$Identity.Id;'@Created'=[Convert]::FromHexString($Identity.Created);'@Name'=$Case.Name;'@Kind'=$Case.Kind;'@Owner'=$script:ledger.RunId}
}

function Assert-CsvForeignKindWitness($Connection,$Case){
 [void](Get-CsvForeignKindIdentity $Connection $Case)
 if($Case.Kind -ceq 'SN'){
  $target=@(Invoke-CsvSql $Connection 'SELECT CONVERT(varbinary(max),base_object_name) TargetBytes FROM sys.synonyms WHERE object_id=OBJECT_ID(@Object);' @{'@Object'=('toolbelt_file.'+$Case.Name)} -Rows)
  if(-not (Test-CsvAliasTarget $target)){throw 'CSV_ALIAS_TARGET_CHANGED'}
 }
 if(-not (Test-CsvForeignKindResult @(Invoke-CsvSql $Connection $Case.Read -Rows))){throw 'CSV_FOREIGN_KIND_RESULT_CHANGED'}
}

function Invoke-CsvForeignKindGuards($Connection,[string]$Deploy,[string]$Uninstall,[ValidateSet('local','central')][string]$Mode,[ValidateSet('view-procedure','synonym-function','table-functions',IgnoreCase=$false)][string]$Family='view-procedure'){
 $cases=@(Get-CsvForeignKindCases $Family)
 if($cases.Count -ne 10 -or @($cases|ForEach-Object {$_.Name+'|'+$_.Kind}|Sort-Object -Unique).Count -ne 10){throw 'CSV_FOREIGN_KIND_CASE_SET_INVALID'}
 Invoke-CsvBatches $Connection $Uninstall
 $targetCase=$null;$targetIdentity=$null;$outer=$null
 if($Family -ceq 'synonym-function'){
  $outer=Get-CsvSnapshot $Connection
  $targetCase=Get-CsvAliasTargetCase
  Invoke-CsvSql $Connection $targetCase.Sql
  $targetIdentity=Add-CsvForeignKindOwner $Connection $targetCase
 }
 $clean=Get-CsvSnapshot $Connection;$passed=0
 if($null -ne $targetCase -and $clean -ceq $outer){throw 'CSV_ALIAS_TARGET_MUTATION_UNOBSERVED'}
 $fixturesComplete=$false
 try{
 foreach($case in $cases){
  $script:stage='FOREIGN_KIND_'+$Mode+'_'+$passed
  Assert-CsvForeignKindCase $case
  if($null -ne $targetCase){Assert-CsvForeignKindWitness $Connection $targetCase}
  if((Get-CsvSnapshot $Connection) -cne $clean){throw 'CSV_FOREIGN_KIND_BASELINE_CHANGED'}
  Invoke-CsvSql $Connection $case.Sql
  $identity=Add-CsvForeignKindOwner $Connection $case
  $mutated=Get-CsvSnapshot $Connection
  if($mutated -ceq $clean){throw 'CSV_FOREIGN_KIND_MUTATION_UNOBSERVED'}
  try{
   Assert-CsvForeignKindWitness $Connection $case
   foreach($text in @($Deploy,$Uninstall)){
    Assert-CsvForeignKindWitness $Connection $case
    Assert-CsvGuardRejected $Connection $text 55324 3 $mutated
    Assert-CsvForeignKindWitness $Connection $case
    $passed++
   }
  }finally{
   if((Get-CsvSnapshot $Connection) -cne $mutated){throw 'CSV_FOREIGN_KIND_DROP_DRIFT'}
   Assert-CsvForeignKindWitness $Connection $case
   Remove-CsvForeignKind $Connection $case $identity
   if((Get-CsvSnapshot $Connection) -cne $clean){throw 'CSV_FOREIGN_KIND_RESTORE_MISMATCH'}
  }
 }
 $fixturesComplete=$true
 }finally{
  # Bei Fixturefehlern übernimmt der äußere journalgebundene OwnDB-Cleanup.
  # Keine weitere Targetaktion darf die ursprüngliche Diagnose verdecken.
  if($null -ne $targetIdentity -and $fixturesComplete){
   $script:stage='FOREIGN_ALIAS_TARGET_DROP_'+$Mode
   if((Get-CsvSnapshot $Connection) -cne $clean){throw 'CSV_ALIAS_TARGET_DROP_DRIFT'}
   Assert-CsvForeignKindWitness $Connection $targetCase
   Remove-CsvForeignKind $Connection $targetCase $targetIdentity
   if((Get-CsvSnapshot $Connection) -cne $outer){throw 'CSV_ALIAS_TARGET_RESTORE_MISMATCH'}
  }
 }
 Invoke-CsvBatches $Connection $Deploy
 if($passed -ne 20){throw 'CSV_FOREIGN_KIND_CASE_COUNT'}
 return $passed
}
