# Namensgebundene SQL-Abhängigkeiten ausschließlich in der eigenen Testdatenbank.
function Get-CsvNamedConsumerCases {
 foreach($name in @(Get-CsvForeignSlotNames)){
  $reference=switch -CaseSensitive ($name){
   'USP_ParseCsv'{"EXEC {DB}.toolbelt_file.USP_ParseCsv @Text=N'x';"}
   'USP_WriteCsv'{"EXEC {DB}.toolbelt_file.USP_WriteCsv @CellsTable=N'#CsvNamedCells';"}
   'TVF_InternalParseCsv'{"SELECT COUNT_BIG(*) FROM {DB}.toolbelt_file.TVF_InternalParseCsv(N'x',N',',0,NULL,10,2,20,100);"}
   'SVF_InternalMeasureCsvCell'{"SELECT {DB}.toolbelt_file.SVF_InternalMeasureCsvCell(N'x',N',',NULL,0);"}
   'SVF_InternalQuoteCsvCell'{"SELECT {DB}.toolbelt_file.SVF_InternalQuoteCsvCell(N'x',N',',NULL,0,1024);"}
   default{throw 'CSV_NAMED_SLOT_UNKNOWN'}
  }
  [pscustomobject]@{Name=$name;Reference=$reference}
 }
}

function Assert-CsvNamedConsumerCase($Case){
 if(@(Get-CsvNamedConsumerCases|Where-Object {$_.Name -ceq $Case.Name -and $_.Reference -ceq $Case.Reference}).Count -ne 1){throw 'CSV_NAMED_CASE_INVALID'}
}

function New-CsvNamedConsumerSql([string]$Database,$Case){
 Assert-CsvNamedConsumerCase $Case
 if($Database -cnotmatch '^Toolbelt_CsvTypes_[a-f0-9]{32}$'){throw 'CSV_NAMED_DATABASE_INVALID'}
 return 'CREATE PROCEDURE toolbelt_file.USP_CsvGuardSqlConsumer AS '+$Case.Reference.Replace('{DB}',('['+$Database+']'))
}

function Test-CsvNamedWitness([object[]]$Rows){
 if($null -eq $Rows -or $Rows.Count -ne 1 -or $null -eq $Rows[0]){return $false}
 $columns=@($Rows[0].PSObject.Properties.Name)
 return $columns.Count -eq 1 -and $columns[0] -ceq 'Witness' -and $Rows[0].Witness -is [int] -and $Rows[0].Witness -eq 1
}

function Get-CsvNamedDatabaseEntry($Connection,[string]$Database){
 if($Database -cnotmatch '^Toolbelt_CsvTypes_[a-f0-9]{32}$' -or $Connection.Database -cne $Database){throw 'CSV_NAMED_CONNECTION_DATABASE'}
 $entries=@($script:ledger.Databases|Where-Object {$_.Name -ceq $Database})
 if($entries.Count -ne 1 -or $entries[0].State -cne 'OWNED' -or $entries[0].Marker -isnot [bool] -or -not $entries[0].Marker -or $entries[0].Id -isnot [int] -or $entries[0].Id -le 0 -or $entries[0].Creation -cnotmatch '^[A-F0-9]{18}$' -or $script:ledger.RunId -cnotmatch '^[a-f0-9]{32}$'){throw 'CSV_NAMED_DATABASE_NOT_OWNED'}
 return $entries[0]
}

function Assert-CsvNamedDatabase($Connection,[string]$Database){
 $entry=Get-CsvNamedDatabaseEntry $Connection $Database
 $rows=@(Invoke-CsvSql $Connection @'
SELECT CONVERT(int,1) Witness WHERE DB_ID()=@Id
 AND EXISTS(SELECT 1 FROM sys.databases WHERE database_id=DB_ID()
 AND DATALENGTH(name)=DATALENGTH(@Database) AND CONVERT(varbinary(max),name)=CONVERT(varbinary(max),@Database)
 AND CONVERT(varbinary(max),CONVERT(datetime2(7),create_date))=@Created)
 AND EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Test.CsvTypes.Owner'
 AND SQL_VARIANT_PROPERTY(value,N'BaseType')=N'nvarchar' AND DATALENGTH(value)=DATALENGTH(@Owner)
 AND CONVERT(varbinary(max),value)=CONVERT(varbinary(max),@Owner));
'@ @{'@Id'=$entry.Id;'@Database'=$Database;'@Created'=[Convert]::FromHexString($entry.Creation);'@Owner'=$script:ledger.RunId} -Rows)
 if(-not (Test-CsvNamedWitness $rows)){throw 'CSV_NAMED_DATABASE_IDENTITY_CHANGED'}
}

function Get-CsvNamedDependencyWitnessSql {
 @'
SELECT CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),(
 SELECT referencing_minor_id,referenced_class,referenced_server_name,referenced_database_name,
 referenced_schema_name,referenced_entity_name,referenced_id,referenced_minor_id,is_caller_dependent,is_ambiguous
 FROM sys.sql_expression_dependencies WHERE referencing_id=@Consumer
 ORDER BY referenced_class,referenced_entity_name,referenced_id,referenced_minor_id,referencing_minor_id
 FOR JSON PATH,INCLUDE_NULL_VALUES))),2) Witness
WHERE (SELECT COUNT(*) FROM (SELECT DISTINCT referenced_server_name,referenced_database_name,
 referenced_schema_name,referenced_entity_name,referenced_id
 FROM sys.sql_expression_dependencies WHERE referencing_id=@Consumer AND referenced_class=1) d)=1
 AND EXISTS(SELECT 1 FROM sys.sql_expression_dependencies WHERE referencing_id=@Consumer AND referenced_class=1
 AND OBJECT_ID(N'toolbelt_file.'+QUOTENAME(@Name)) IS NOT NULL
 AND referenced_server_name IS NULL AND is_caller_dependent=0
 AND (referenced_id IS NULL OR referenced_id=OBJECT_ID(N'toolbelt_file.'+QUOTENAME(@Name)))
 AND (referenced_database_name IS NULL OR
 (DATALENGTH(referenced_database_name)=DATALENGTH(@Database)
 AND CONVERT(varbinary(max),referenced_database_name)=CONVERT(varbinary(max),@Database)))
 AND DATALENGTH(referenced_schema_name)=DATALENGTH(N'toolbelt_file')
 AND CONVERT(varbinary(max),referenced_schema_name)=CONVERT(varbinary(max),N'toolbelt_file')
 AND DATALENGTH(referenced_entity_name)=DATALENGTH(@Name)
 AND CONVERT(varbinary(max),referenced_entity_name)=CONVERT(varbinary(max),@Name));
'@
}

function Get-CsvNamedDependency($Connection,[string]$Database,$Case,$Identity){
 Assert-CsvNamedConsumerCase $Case
 Assert-CsvNamedDatabase $Connection $Database
 $actual=Get-CsvGuardFixtureIdentity $Connection 'PROCEDURE' 'USP_CsvGuardSqlConsumer'
 if($actual.Id -ne $Identity.Id -or $actual.Created -cne $Identity.Created){throw 'CSV_NAMED_CONSUMER_IDENTITY_CHANGED'}
 $rows=@(Invoke-CsvSql $Connection (Get-CsvNamedDependencyWitnessSql) @{'@Consumer'=$Identity.Id;'@Database'=$Database;'@Name'=$Case.Name} -Rows)
 if($rows.Count -ne 1 -or @($rows[0].PSObject.Properties).Count -ne 1 -or $rows[0].PSObject.Properties.Name -cne 'Witness' -or $rows[0].Witness -isnot [string] -or $rows[0].Witness -cnotmatch '^[A-F0-9]{64}$'){throw 'CSV_NAMED_DEPENDENCY_WITNESS_MISSING'}
 return $rows[0].Witness
}

function Assert-CsvNamedDependency($Connection,[string]$Database,$Case,$Identity,[string]$Expected){
 if(-not (Test-CsvForeignWitness $Expected (Get-CsvNamedDependency $Connection $Database $Case $Identity))){throw 'CSV_NAMED_DEPENDENCY_CHANGED'}
}

function Invoke-CsvNamedConsumerGuards($Connection,[string]$Deploy,[string]$Uninstall,[string]$Database,[ValidateSet('local','central')][string]$Mode){
 Assert-CsvNamedDatabase $Connection $Database
 $cases=@(Get-CsvNamedConsumerCases)
 if($cases.Count -ne 5 -or @($cases.Name|Sort-Object -Unique).Count -ne 5){throw 'CSV_NAMED_CASE_SET_INVALID'}
 $baseline=Get-CsvSnapshot $Connection;$passed=0
 foreach($case in $cases){
  $script:stage='NAMED_CONSUMER_'+$Mode+'_'+$case.Name
  if((Get-CsvSnapshot $Connection) -cne $baseline){throw 'CSV_NAMED_BASELINE_CHANGED'}
  Assert-CsvNamedDatabase $Connection $Database
  Invoke-CsvSql $Connection (New-CsvNamedConsumerSql $Database $case)
  $identity=Add-CsvGuardFixtureOwner $Connection 'PROCEDURE' 'USP_CsvGuardSqlConsumer'
  $mutated=Get-CsvSnapshot $Connection
  if($mutated -ceq $baseline){throw 'CSV_NAMED_MUTATION_UNOBSERVED'}
  $witness=$null
  try{
   $witness=Get-CsvNamedDependency $Connection $Database $case $identity
   foreach($text in @($Deploy,$Uninstall)){
    Assert-CsvGuardRejected $Connection $text 55325 3 $mutated
    Assert-CsvNamedDependency $Connection $Database $case $identity $witness
    $passed++
   }
  }finally{
   # Ohne initialen Dependencywitness bleibt ausschließlich OwnDB-Cleanup.
   if($null -ne $witness){
    if((Get-CsvSnapshot $Connection) -cne $mutated){throw 'CSV_NAMED_DROP_DRIFT'}
    Assert-CsvNamedDependency $Connection $Database $case $identity $witness
    Remove-CsvGuardFixture $Connection 'PROCEDURE' 'USP_CsvGuardSqlConsumer' $identity
    if((Get-CsvSnapshot $Connection) -cne $baseline){throw 'CSV_NAMED_RESTORE_MISMATCH'}
   }
  }
 }
 if($passed -ne 10){throw 'CSV_NAMED_CASE_COUNT'}
 return $passed
}
