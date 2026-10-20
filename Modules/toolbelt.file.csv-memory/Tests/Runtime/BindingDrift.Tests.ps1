# Begrenzte CLR-Metadatendrift in der eigenen installierten Testdatenbank.
function Get-CsvBindingDriftCases([ValidateSet('metadata','defaults',IgnoreCase=$false)][string]$Family='metadata'){
 $measure='SVF_InternalMeasureCsvCell';$quote='SVF_InternalQuoteCsvCell';$parse='TVF_InternalParseCsv'
 if($Family -ceq 'defaults'){
  foreach($row in @(
   @('measure-separator-default',$measure,'MeasureCell','FS','@Separator nvarchar(2)',"@Separator nvarchar(2)=N';'",2,"CONVERT(varbinary(max),default_value)=CONVERT(varbinary(max),N';')"),
   @('measure-header-default',$measure,'MeasureCell','FS','@IsHeader bit','@IsHeader bit=0',4,'TRY_CONVERT(bit,default_value)=0'),
   @('quote-null-token-default',$quote,'QuoteCell','FS','@NullToken nvarchar(128)','@NullToken nvarchar(128)=NULL',3,'default_value IS NULL'),
   @('quote-limit-default',$quote,'QuoteCell','FS','@MaxOutputBytes bigint','@MaxOutputBytes bigint=1024',5,'TRY_CONVERT(bigint,default_value)=1024'),
   @('parse-rows-default',$parse,'Parse','FT','@MaxRows bigint','@MaxRows bigint=10',5,'TRY_CONVERT(bigint,default_value)=10')
  )){[pscustomobject]@{Id=$row[0];Name=$row[1];Method=$row[2];Kind=$row[3];Needle=$row[4];Replacement=$row[5];State=7;Probe=('EXISTS(SELECT 1 FROM sys.parameters WHERE object_id=OBJECT_ID(@Object) AND parameter_id='+$row[6]+' AND has_default_value=1 AND '+$row[7]+')')}}
  return
 }
 foreach($row in @(
  @('measure-null',$measure,'MeasureCell','FS',"RETURNS bigint`nAS EXTERNAL NAME","RETURNS bigint`nWITH RETURNS NULL ON NULL INPUT`nAS EXTERNAL NAME",5,'EXISTS(SELECT 1 FROM sys.assembly_modules WHERE object_id=OBJECT_ID(@Object) AND null_on_null_input=1)'),
  @('quote-null',$quote,'QuoteCell','FS',"RETURNS nvarchar(max)`nAS EXTERNAL NAME","RETURNS nvarchar(max)`nWITH RETURNS NULL ON NULL INPUT`nAS EXTERNAL NAME",5,'EXISTS(SELECT 1 FROM sys.assembly_modules WHERE object_id=OBJECT_ID(@Object) AND null_on_null_input=1)'),
  @('measure-length',$measure,'MeasureCell','FS','@Value nvarchar(max)','@Value nvarchar(4000)',7,'EXISTS(SELECT 1 FROM sys.parameters WHERE object_id=OBJECT_ID(@Object) AND parameter_id=1 AND max_length=8000)'),
  @('quote-token-length',$quote,'QuoteCell','FS','@NullToken nvarchar(128)','@NullToken nvarchar(64)',7,'EXISTS(SELECT 1 FROM sys.parameters WHERE object_id=OBJECT_ID(@Object) AND parameter_id=3 AND max_length=128)'),
  @('parse-length',$parse,'Parse','FT','@Text nvarchar(max)','@Text nvarchar(4000)',7,'EXISTS(SELECT 1 FROM sys.parameters WHERE object_id=OBJECT_ID(@Object) AND parameter_id=1 AND max_length=8000)'),
  @('parse-value-length',$parse,'Parse','FT','[Value] nvarchar(max)','[Value] nvarchar(4000)',7,'EXISTS(SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID(@Object) AND column_id=4 AND max_length=8000)'),
  @('measure-parameter-name',$measure,'MeasureCell','FS','@Separator nvarchar(2)','@Delimiter nvarchar(2)',7,"EXISTS(SELECT 1 FROM sys.parameters WHERE object_id=OBJECT_ID(@Object) AND parameter_id=2 AND CONVERT(varbinary(max),name)=CONVERT(varbinary(max),N'@Delimiter'))"),
  @('parse-column-name',$parse,'Parse','FT','ColumnOrdinal int','CellOrdinal int',7,"EXISTS(SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID(@Object) AND column_id=3 AND CONVERT(varbinary(max),name)=CONVERT(varbinary(max),N'CellOrdinal'))")
 )){[pscustomobject]@{Id=$row[0];Name=$row[1];Method=$row[2];Kind=$row[3];Needle=$row[4];Replacement=$row[5];State=[int]$row[6];Probe=$row[7]}}
}

function Assert-CsvBindingDriftCase($Case){
 $known=@(@(Get-CsvBindingDriftCases;Get-CsvBindingDriftCases 'defaults')|Where-Object {$_.Id -ceq $Case.Id -and $_.Name -ceq $Case.Name -and $_.Method -ceq $Case.Method -and $_.Kind -ceq $Case.Kind -and $_.Needle -ceq $Case.Needle -and $_.Replacement -ceq $Case.Replacement -and $_.State -eq $Case.State -and $_.Probe -ceq $Case.Probe})
 if($known.Count -ne 1){throw 'CSV_BINDING_CASE_INVALID'}
}

function New-CsvBindingDriftSql([string]$Source,$Case,[switch]$Restore){
 Assert-CsvBindingDriftCase $Case
 $text=$Source.Replace("`r`n","`n")
 $pattern='(?s)\bCREATE FUNCTION toolbelt_file\.'+[regex]::Escape($Case.Name)+'\n.*?;(?=\nGO(?:\n|$))'
 $matches=[regex]::Matches($text,$pattern)
 if($matches.Count -ne 1){throw 'CSV_BINDING_SOURCE_IDENTITY'}
 $original=$matches[0].Value
 if([regex]::Matches($original,[regex]::Escape($Case.Needle)).Count -ne 1){throw 'CSV_BINDING_SOURCE_SEAM'}
 $sql=$original.Replace('CREATE FUNCTION','ALTER FUNCTION')
 if(-not $Restore){$sql=$sql.Replace($Case.Needle,$Case.Replacement)}
 return $sql
}

function Get-CsvBindingDriftIdentity($Connection,$Case){
 Assert-CsvBindingDriftCase $Case
 $rows=@(Invoke-CsvSql $Connection @'
SELECT o.object_id Id,CONVERT(varchar(18),CONVERT(varbinary(max),CONVERT(datetime2(7),o.create_date)),2) Created
FROM sys.objects o JOIN sys.assembly_modules m ON m.object_id=o.object_id JOIN sys.assemblies a ON a.assembly_id=m.assembly_id
WHERE o.schema_id=SCHEMA_ID(N'toolbelt_file') AND o.type=@Kind AND CONVERT(varbinary(max),o.name)=CONVERT(varbinary(max),@Name)
 AND CONVERT(varbinary(max),a.name)=CONVERT(varbinary(max),N'Toolbelt_File_CsvMemory')
 AND CONVERT(varbinary(max),m.assembly_class)=CONVERT(varbinary(max),N'Toolbelt.Csv.CsvEntryPoints')
 AND CONVERT(varbinary(max),m.assembly_method)=CONVERT(varbinary(max),@Method)
 AND EXISTS(SELECT 1 FROM sys.extended_properties p WHERE p.class=1 AND p.major_id=o.object_id AND p.minor_id=0
 AND p.name=N'Toolbelt.Managed' AND SQL_VARIANT_PROPERTY(p.value,N'BaseType')=N'bit' AND TRY_CONVERT(bit,p.value)=1)
 AND EXISTS(SELECT 1 FROM sys.extended_properties p WHERE p.class=1 AND p.major_id=o.object_id AND p.minor_id=0
 AND p.name=N'Toolbelt.ModuleId' AND SQL_VARIANT_PROPERTY(p.value,N'BaseType')=N'nvarchar'
 AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),p.value))=CONVERT(varbinary(max),N'toolbelt.file.csv-memory'));
'@ @{'@Name'=$Case.Name;'@Kind'=$Case.Kind;'@Method'=$Case.Method} -Rows)
 if($rows.Count -ne 1 -or $rows[0].Id -isnot [int] -or $rows[0].Id -le 0 -or $rows[0].Created -cnotmatch '^[A-F0-9]{18}$'){throw 'CSV_BINDING_IDENTITY_UNKNOWN'}
 return $rows[0]
}

function Assert-CsvBindingDriftIdentity($Connection,$Case,$Identity){
 $actual=Get-CsvBindingDriftIdentity $Connection $Case
 if($actual.Id -ne $Identity.Id -or $actual.Created -cne $Identity.Created){throw 'CSV_BINDING_IDENTITY_CHANGED'}
}

function Test-CsvBindingDriftWitness([object[]]$Rows){
 if($null -eq $Rows -or $Rows.Count -ne 1 -or $null -eq $Rows[0]){return $false}
 $columns=@($Rows[0].PSObject.Properties.Name)
 return $columns.Count -eq 1 -and $columns[0] -ceq 'Witness' -and $Rows[0].Witness -is [int] -and $Rows[0].Witness -eq 1
}

function Assert-CsvBindingDriftWitness($Connection,$Case){
 Assert-CsvBindingDriftCase $Case
 $rows=@(Invoke-CsvSql $Connection ('SELECT CONVERT(int,1) Witness WHERE '+$Case.Probe+';') @{'@Object'=('toolbelt_file.'+$Case.Name)} -Rows)
 if(-not (Test-CsvBindingDriftWitness $rows)){throw 'CSV_BINDING_MUTATION_WITNESS_MISSING'}
}

function Invoke-CsvBindingDriftGuards($Connection,[string]$Deploy,[string]$Uninstall,[string]$ModuleRoot,[ValidateSet('local','central')][string]$Mode,[ValidateSet('metadata','defaults',IgnoreCase=$false)][string]$Family='metadata'){
 $cases=@(Get-CsvBindingDriftCases $Family);$expected=if($Family -ceq 'defaults'){5}else{8}
 if($cases.Count -ne $expected -or @($cases.Id|Sort-Object -Unique).Count -ne $expected){throw 'CSV_BINDING_CASE_SET_INVALID'}
 $passed=0
 foreach($case in $cases){
  $script:stage='BINDING_DRIFT_'+$Mode+'_'+$case.Id
  $source=[IO.File]::ReadAllText((Join-Path $ModuleRoot ('Source/'+$case.Name+'.sql')))
  $mutate=New-CsvBindingDriftSql $source $case;$restore=New-CsvBindingDriftSql $source $case -Restore
  $identity=Get-CsvBindingDriftIdentity $Connection $case
  $baseline=Get-CsvSnapshot $Connection;$mutated=$null
  Invoke-CsvSql $Connection $mutate
  try{
   $observed=Get-CsvSnapshot $Connection
   if($observed -ceq $baseline){throw 'CSV_BINDING_MUTATION_UNOBSERVED'}
   $mutated=$observed
   Assert-CsvBindingDriftIdentity $Connection $case $identity
   Assert-CsvBindingDriftWitness $Connection $case
   foreach($text in @($Deploy,$Uninstall)){
    Assert-CsvGuardRejected $Connection $text 55324 $case.State $mutated
    # Der gemeinsame Snapshot erfasst das Defaultflag, nicht den Defaultwert.
    # Auch Werte, die keinen Snapshotteil ändern, bleiben separat geschützt.
    Assert-CsvBindingDriftWitness $Connection $case
    $passed++
   }
  }finally{
   if($null -ne $mutated){
    if((Get-CsvSnapshot $Connection) -cne $mutated){throw 'CSV_BINDING_RESTORE_DRIFT'}
    Assert-CsvBindingDriftIdentity $Connection $case $identity
    Assert-CsvBindingDriftWitness $Connection $case
    Invoke-CsvSql $Connection $restore
    if((Get-CsvSnapshot $Connection) -cne $baseline){throw 'CSV_BINDING_RESTORE_MISMATCH'}
   }
  }
 }
 if($passed -ne (2*$expected)){throw 'CSV_BINDING_CASE_COUNT'}
 return $passed
}
