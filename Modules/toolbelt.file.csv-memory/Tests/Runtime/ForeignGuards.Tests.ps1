# Fremdbelegung ausschließlich in eigenen synthetischen Labdatenbanken.
# Gemeinsames Abweisungsorakel und Katalogsnapshot aus OwnershipGuards/CSV-Helper.
function Get-CsvForeignSlotNames {
 @('USP_ParseCsv','USP_WriteCsv','TVF_InternalParseCsv','SVF_InternalMeasureCsvCell','SVF_InternalQuoteCsvCell')
}

function Assert-CsvGuardFixtureName([string]$Type,[string]$Name){
 $valid=($Type -ceq 'TABLE' -and $Name -cin @(Get-CsvForeignSlotNames)) -or
  ($Type -ceq 'PROCEDURE' -and $Name -ceq 'USP_CsvGuardSqlConsumer') -or
  ($Type -ceq 'FUNCTION' -and $Name -ceq 'SVF_CsvGuardClrConsumer')
 if(-not $valid){throw 'CSV_FOREIGN_FIXTURE_NAME_INVALID'}
}

function Get-CsvGuardFixtureIdentity($Connection,[string]$Type,[string]$Name){
 Assert-CsvGuardFixtureName $Type $Name
 $kind=@{TABLE='U';PROCEDURE='P';FUNCTION='FS'}[$Type]
 $rows=@(Invoke-CsvSql $Connection @'
SELECT o.object_id Id,CONVERT(varchar(18),CONVERT(varbinary(max),CONVERT(datetime2(7),o.create_date)),2) Created
FROM sys.objects o WHERE o.schema_id=SCHEMA_ID(N'toolbelt_file') AND o.type=@Kind
 AND CONVERT(varbinary(max),o.name)=CONVERT(varbinary(max),@Name)
 AND EXISTS(SELECT 1 FROM sys.extended_properties p WHERE p.class=1 AND p.major_id=o.object_id AND p.minor_id=0
 AND p.name=N'Toolbelt.Test.CsvGuard.Owner' AND SQL_VARIANT_PROPERTY(p.value,N'BaseType')=N'nvarchar'
 AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),p.value))=CONVERT(varbinary(max),@Owner));
'@ @{'@Kind'=$kind;'@Name'=$Name;'@Owner'=$script:ledger.RunId} -Rows)
 if($rows.Count -ne 1 -or $rows[0].Id -isnot [int] -or $rows[0].Id -le 0 -or $rows[0].Created -cnotmatch '^[A-F0-9]{18}$'){throw 'CSV_FOREIGN_FIXTURE_IDENTITY_UNKNOWN'}
 return $rows[0]
}

function Add-CsvGuardFixtureOwner($Connection,[string]$Type,[string]$Name){
 Assert-CsvGuardFixtureName $Type $Name
 Invoke-CsvSql $Connection @"
DECLARE @Value nvarchar(32)=@Owner;
EXEC sys.sp_addextendedproperty @name=N'Toolbelt.Test.CsvGuard.Owner',@value=@Value,
 @level0type=N'SCHEMA',@level0name=N'toolbelt_file',@level1type=N'$Type',@level1name=N'$Name';
"@ @{'@Owner'=$script:ledger.RunId}
 return Get-CsvGuardFixtureIdentity $Connection $Type $Name
}

function Remove-CsvGuardFixture($Connection,[string]$Type,[string]$Name,$Identity){
 Assert-CsvGuardFixtureName $Type $Name
 $actual=Get-CsvGuardFixtureIdentity $Connection $Type $Name
 if($actual.Id -ne $Identity.Id -or $actual.Created -cne $Identity.Created){throw 'CSV_FOREIGN_FIXTURE_IDENTITY_CHANGED'}
 $kind=@{TABLE='U';PROCEDURE='P';FUNCTION='FS'}[$Type]
 Invoke-CsvSql $Connection @"
IF NOT EXISTS(SELECT 1 FROM sys.objects o WHERE o.object_id=@Id AND o.schema_id=SCHEMA_ID(N'toolbelt_file') AND o.type=@Kind
 AND CONVERT(varbinary(max),o.name)=CONVERT(varbinary(max),@Name)
 AND CONVERT(varbinary(max),CONVERT(datetime2(7),o.create_date))=@Created
 AND EXISTS(SELECT 1 FROM sys.extended_properties p WHERE p.class=1 AND p.major_id=o.object_id AND p.minor_id=0
 AND p.name=N'Toolbelt.Test.CsvGuard.Owner' AND SQL_VARIANT_PROPERTY(p.value,N'BaseType')=N'nvarchar'
 AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),p.value))=CONVERT(varbinary(max),@Owner)))
 THROW 51596,N'Synthetic foreign fixture changed.',1;
DROP $Type toolbelt_file.[$Name];
"@ @{'@Id'=[int]$Identity.Id;'@Created'=[Convert]::FromHexString($Identity.Created);'@Name'=$Name;'@Kind'=$kind;'@Owner'=$script:ledger.RunId}
}

function Test-CsvForeignWitness([string]$Before,[string]$After){
 return $Before -cmatch '^[A-F0-9]{64}$' -and $After -cmatch '^[A-F0-9]{64}$' -and $Before -ceq $After
}

function Get-CsvForeignTableWitness($Connection,[string]$Name){
 Assert-CsvGuardFixtureName 'TABLE' $Name
 [void](Get-CsvGuardFixtureIdentity $Connection 'TABLE' $Name)
 # Wertbytes mit INCLUDE_NULL_VALUES unterscheiden NULL, leer und Padding.
 # Index-/Constraintstruktur ergänzt die vom gemeinsamen Snapshot erfassten Spalten.
 $rows=@(Invoke-CsvSql $Connection @"
SELECT CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),CONCAT(
 (SELECT index_id,name,type,is_unique,is_primary_key,is_unique_constraint,is_disabled,filter_definition
  FROM sys.indexes WHERE object_id=OBJECT_ID(N'toolbelt_file.$Name',N'U') ORDER BY index_id FOR JSON PATH,INCLUDE_NULL_VALUES),N'|',
 (SELECT index_id,index_column_id,column_id,key_ordinal,is_descending_key,is_included_column
  FROM sys.index_columns WHERE object_id=OBJECT_ID(N'toolbelt_file.$Name',N'U') ORDER BY index_id,index_column_id FOR JSON PATH,INCLUDE_NULL_VALUES),N'|',
 (SELECT object_id,name,type,parent_object_id,unique_index_id FROM sys.key_constraints
  WHERE parent_object_id=OBJECT_ID(N'toolbelt_file.$Name',N'U') ORDER BY object_id FOR JSON PATH,INCLUDE_NULL_VALUES),N'|',
 (SELECT Marker,CONVERT(varchar(max),CONVERT(varbinary(max),Payload),2) PayloadBytes
  FROM toolbelt_file.[$Name] ORDER BY Marker FOR JSON PATH,INCLUDE_NULL_VALUES)))),2) Witness;
"@ -Rows)
 if($rows.Count -ne 1 -or $rows[0].Witness -isnot [string] -or $rows[0].Witness -cnotmatch '^[A-F0-9]{64}$'){throw 'CSV_FOREIGN_WITNESS_INVALID'}
 return $rows[0].Witness
}

function Assert-CsvForeignWitnessControls($Connection,[string]$Name,[string]$Baseline,[string]$Snapshot){
 Invoke-CsvSql $Connection "UPDATE toolbelt_file.[$Name] SET Payload=N'' WHERE Marker=74 AND Payload IS NULL;IF @@ROWCOUNT<>1 THROW 51596,N'Synthetic NULL witness missing.',2;"
 $mutated=Get-CsvForeignTableWitness $Connection $Name
 if(Test-CsvForeignWitness $Baseline $mutated){throw 'CSV_FOREIGN_NULL_MUTATION_UNOBSERVED'}
 if((Get-CsvSnapshot $Connection) -cne $Snapshot -or -not (Test-CsvForeignWitness $mutated (Get-CsvForeignTableWitness $Connection $Name))){throw 'CSV_FOREIGN_CONTROL_RESTORE_DRIFT'}
 Invoke-CsvSql $Connection "UPDATE toolbelt_file.[$Name] SET Payload=NULL WHERE Marker=74 AND Payload IS NOT NULL AND DATALENGTH(Payload)=0;IF @@ROWCOUNT<>1 THROW 51596,N'Synthetic empty witness changed.',3;"
 if(-not (Test-CsvForeignWitness $Baseline (Get-CsvForeignTableWitness $Connection $Name))){throw 'CSV_FOREIGN_CONTROL_RESTORE_MISMATCH'}
 Invoke-CsvSql $Connection "DROP INDEX IX_CsvGuardPayload ON toolbelt_file.[$Name];"
 $mutated=Get-CsvForeignTableWitness $Connection $Name
 if(Test-CsvForeignWitness $Baseline $mutated){throw 'CSV_FOREIGN_INDEX_MUTATION_UNOBSERVED'}
 if((Get-CsvSnapshot $Connection) -cne $Snapshot -or -not (Test-CsvForeignWitness $mutated (Get-CsvForeignTableWitness $Connection $Name))){throw 'CSV_FOREIGN_CONTROL_RESTORE_DRIFT'}
 Invoke-CsvSql $Connection "CREATE INDEX IX_CsvGuardPayload ON toolbelt_file.[$Name](Payload);"
 if(-not (Test-CsvForeignWitness $Baseline (Get-CsvForeignTableWitness $Connection $Name))){throw 'CSV_FOREIGN_CONTROL_RESTORE_MISMATCH'}
 return 2
}

function Invoke-CsvForeignGuards($Connection,[string]$Deploy,[string]$Uninstall,[ValidateSet('local','central')][string]$Mode){
 $slots=@(Get-CsvForeignSlotNames)
 if($slots.Count -ne 5 -or @($slots|Sort-Object -Unique).Count -ne 5){throw 'CSV_FOREIGN_SLOT_SET_INVALID'}
 $passed=0;$controls=0
 # Fremdslots werden ohne Modulmarker/Assembly vorbereitet, nach echtem Uninstall.
 Invoke-CsvBatches $Connection $Uninstall
 $clean=Get-CsvSnapshot $Connection
 foreach($slot in $slots){
  $script:stage='FOREIGN_SLOT_'+$Mode+'_'+$passed
  if((Get-CsvSnapshot $Connection) -cne $clean){throw 'CSV_FOREIGN_CLEAN_BASELINE_CHANGED'}
  Invoke-CsvSql $Connection @"
IF OBJECT_ID(N'toolbelt_file.$slot') IS NOT NULL THROW 51596,N'Synthetic slot collision.',4;
CREATE TABLE toolbelt_file.[$slot](Marker int NOT NULL,Payload nvarchar(32) NULL,CONSTRAINT PK_CsvGuardForeignSlot PRIMARY KEY(Marker));
INSERT toolbelt_file.[$slot] VALUES(73,N'guard '),(74,NULL);
CREATE INDEX IX_CsvGuardPayload ON toolbelt_file.[$slot](Payload);
"@
  $identity=Add-CsvGuardFixtureOwner $Connection 'TABLE' $slot
  $mutated=Get-CsvSnapshot $Connection;$witness=Get-CsvForeignTableWitness $Connection $slot
  if($mutated -ceq $clean){throw 'CSV_FOREIGN_SLOT_UNOBSERVED'}
  try{
   if($controls -eq 0){$controls+=Assert-CsvForeignWitnessControls $Connection $slot $witness $mutated}
   foreach($text in @($Deploy,$Uninstall)){
    Assert-CsvGuardRejected $Connection $text 55324 3 $mutated
    if(-not (Test-CsvForeignWitness $witness (Get-CsvForeignTableWitness $Connection $slot))){throw 'CSV_FOREIGN_REJECTION_CHANGED_TABLE'}
    $passed++
   }
  }finally{
   if((Get-CsvSnapshot $Connection) -cne $mutated -or -not (Test-CsvForeignWitness $witness (Get-CsvForeignTableWitness $Connection $slot))){throw 'CSV_FOREIGN_FIXTURE_DROP_DRIFT'}
   Remove-CsvGuardFixture $Connection 'TABLE' $slot $identity
   if((Get-CsvSnapshot $Connection) -cne $clean){throw 'CSV_FOREIGN_CLEAN_RESTORE_MISMATCH'}
  }
 }
 Invoke-CsvBatches $Connection $Deploy
 $baseline=Get-CsvSnapshot $Connection
 $consumers=@(
  @{Name='USP_CsvGuardSqlConsumer';Type='PROCEDURE';State=3;Sql="CREATE PROCEDURE toolbelt_file.USP_CsvGuardSqlConsumer AS EXEC toolbelt_file.USP_ParseCsv @Text=N'x';"},
  @{Name='SVF_CsvGuardClrConsumer';Type='FUNCTION';State=2;Sql='CREATE FUNCTION toolbelt_file.SVF_CsvGuardClrConsumer(@Value nvarchar(max),@Separator nvarchar(2),@NullToken nvarchar(128),@IsHeader bit) RETURNS bigint AS EXTERNAL NAME [Toolbelt_File_CsvMemory].[Toolbelt.Csv.CsvEntryPoints].[MeasureCell];'}
 )
 foreach($consumer in $consumers){
  $script:stage='FOREIGN_CONSUMER_'+$Mode+'_'+$passed
  if((Get-CsvSnapshot $Connection) -cne $baseline){throw 'CSV_FOREIGN_INSTALLED_BASELINE_CHANGED'}
  Invoke-CsvSql $Connection $consumer.Sql
  $identity=Add-CsvGuardFixtureOwner $Connection $consumer.Type $consumer.Name
  $mutated=Get-CsvSnapshot $Connection
  if($mutated -ceq $baseline){throw 'CSV_FOREIGN_CONSUMER_UNOBSERVED'}
  try{
   foreach($text in @($Deploy,$Uninstall)){
    Assert-CsvGuardRejected $Connection $text 55325 $consumer.State $mutated
    $passed++
   }
  }finally{
   if((Get-CsvSnapshot $Connection) -cne $mutated){throw 'CSV_FOREIGN_FIXTURE_DROP_DRIFT'}
   Remove-CsvGuardFixture $Connection $consumer.Type $consumer.Name $identity
   if((Get-CsvSnapshot $Connection) -cne $baseline){throw 'CSV_FOREIGN_INSTALLED_RESTORE_MISMATCH'}
  }
 }
 if($passed -ne 14 -or $controls -ne 2){throw 'CSV_FOREIGN_CASE_COUNT'}
 return [pscustomobject]@{GuardCases=$passed;WitnessControls=$controls}
}
