# Ausschließlich synthetische Lifecycle-Guards in den eigenen Labdatenbanken.
# Keine Top-level-Effekte; der Labadapter importiert nur geprüfte Funktionen.
function Get-CsvGuardErrorIdentities($Exception){
 $cursor=$Exception
 while($null -ne $cursor){
  if($cursor -is [Data.SqlClient.SqlException]){
   foreach($item in $cursor.Errors){[pscustomobject]@{Number=[int]$item.Number;State=[int]$item.State}}
   return
  }
  $cursor=$cursor.InnerException
 }
}

function Test-CsvGuardErrorIdentities([object[]]$Identities,[int]$Number,[int]$State){
 # Ein einzelnes erwartetes THROW ist das Orakel; zusätzliche Fehler sind kein PASS.
 return $Identities.Count -eq 1 -and $Identities[0].Number -is [int] -and
  $Identities[0].State -is [int] -and $Identities[0].Number -eq $Number -and $Identities[0].State -eq $State
}

function Get-CsvGuardSessionOptions($Connection){
 # Im nativen Diagnosevergleich änderte das kombinierte SELECT mit @@OPTIONS
 # den beobachteten XACT_STATE-Wert. Beide Nullzustände werden daher vor dem
 # Options-SELECT einzeln geprüft; keine gelockerte Zustandsannahme.
 $rows=@(Invoke-CsvSql $Connection @'
IF @@TRANCOUNT<>0 THROW 51595,N'Synthetic guard requires zero transaction count.',3;
IF XACT_STATE()<>0 THROW 51595,N'Synthetic guard requires neutral transaction state.',4;
SELECT @@OPTIONS Options;
'@ -Rows)
 if($rows.Count -ne 1 -or $rows[0].Options -isnot [int]){throw 'CSV_GUARD_SESSION_WITNESS_INVALID'}
 return $rows[0].Options
}

function Assert-CsvGuardRejected($Connection,[string]$Sql,[int]$Number,[int]$State,[string]$Snapshot){
 if((Get-CsvSnapshot $Connection) -cne $Snapshot){throw 'CSV_GUARD_PRECONDITION_DRIFT'}
 # Der neutrale Lifecycle setzt diese beiden Optionen ausdrücklich. Die Fixture
 # bereitet denselben erlaubten Zustand vor und prüft anschließend exakt dessen
 # Erhalt. Der separate Caller-Transaktionsvertrag bleibt im Defaultscope.
 Invoke-CsvSql $Connection 'SET NOCOUNT ON;SET XACT_ABORT ON;'
 $before=Get-CsvGuardSessionOptions $Connection
 $caught=$false
 try{Invoke-CsvBatches $Connection $Sql}catch{
  $identities=@(Get-CsvGuardErrorIdentities $_.Exception)
  if(-not (Test-CsvGuardErrorIdentities $identities $Number $State)){throw 'CSV_GUARD_ERROR_ORACLE_MISMATCH'}
  $caught=$true
 }
 if(-not $caught){throw 'CSV_GUARD_REJECTION_MISSING'}
 if((Get-CsvSnapshot $Connection) -cne $Snapshot){throw 'CSV_GUARD_REJECTION_MUTATED_METADATA'}
 if((Get-CsvGuardSessionOptions $Connection) -ne $before){throw 'CSV_GUARD_REJECTION_CHANGED_SESSION'}
}

function Get-CsvMarkerGuardCases([ValidateSet('local','central')][string]$Mode,[ValidateSet('types','values',IgnoreCase=$false)][string]$Family='types'){
 if($Family -ceq 'values'){
  foreach($slot in @('USP_ParseCsv','USP_WriteCsv','TVF_InternalParseCsv','SVF_InternalMeasureCsvCell','SVF_InternalQuoteCsvCell')){
   [pscustomobject]@{Scope='OBJECT';Object=$slot;Property='Toolbelt.Managed';Original='CONVERT(bit,1)';Mutated='CONVERT(bit,0)';State=5}
   [pscustomobject]@{Scope='OBJECT';Object=$slot;Property='Toolbelt.ModuleId';Original="CONVERT(nvarchar(128),N'toolbelt.file.csv-memory')";Mutated="CONVERT(nvarchar(128),N'toolbelt.file.csv-foreign')";State=5}
   [pscustomobject]@{Scope='OBJECT';Object=$slot;Property='Toolbelt.ModuleVersion';Original="CONVERT(nvarchar(16),N'1.0.0')";Mutated="CONVERT(nvarchar(16),N'9.9.9')";State=5}
   $visibility=if($slot.StartsWith('USP_',[StringComparison]::Ordinal)){'public'}else{'internal'}
   [pscustomobject]@{Scope='OBJECT';Object=$slot;Property='Toolbelt.Visibility';Original="CONVERT(nvarchar(16),N'$visibility')";Mutated="CONVERT(nvarchar(16),N'unknown')";State=5}
  }
  [pscustomobject]@{Scope='ASSEMBLY';Object='Toolbelt_File_CsvMemory';Property='Toolbelt.Managed';Original='CONVERT(bit,1)';Mutated='CONVERT(bit,0)';State=4}
  [pscustomobject]@{Scope='ASSEMBLY';Object='Toolbelt_File_CsvMemory';Property='Toolbelt.ModuleId';Original="CONVERT(nvarchar(128),N'toolbelt.file.csv-memory')";Mutated="CONVERT(nvarchar(128),N'toolbelt.file.csv-foreign')";State=4}
  [pscustomobject]@{Scope='ASSEMBLY';Object='Toolbelt_File_CsvMemory';Property='Toolbelt.ModuleVersion';Original="CONVERT(nvarchar(16),N'1.0.0')";Mutated="CONVERT(nvarchar(16),N'9.9.9')";State=4}
  [pscustomobject]@{Scope='DATABASE';Object='';Property='Toolbelt.Module.toolbelt.file.csv-memory.Version';Original="CONVERT(nvarchar(16),N'1.0.0')";Mutated="CONVERT(nvarchar(16),N'9.9.9')";State=2}
  [pscustomobject]@{Scope='DATABASE';Object='';Property='Toolbelt.Module.toolbelt.file.csv-memory.DeploymentMode';Original="CONVERT(nvarchar(16),N'$Mode')";Mutated="CONVERT(nvarchar(16),N'invalid')";State=2}
  return
 }
 foreach($slot in @('USP_ParseCsv','USP_WriteCsv','TVF_InternalParseCsv','SVF_InternalMeasureCsvCell','SVF_InternalQuoteCsvCell')){
  [pscustomobject]@{Scope='OBJECT';Object=$slot;Property='Toolbelt.Managed';Original='CONVERT(bit,1)';Mutated='CONVERT(int,1)';State=5}
 }
 [pscustomobject]@{Scope='OBJECT';Object='USP_ParseCsv';Property='Toolbelt.ModuleId';Original="CONVERT(nvarchar(128),N'toolbelt.file.csv-memory')";Mutated="CONVERT(varchar(128),'toolbelt.file.csv-memory')";State=5}
 [pscustomobject]@{Scope='OBJECT';Object='USP_WriteCsv';Property='Toolbelt.ModuleVersion';Original="CONVERT(nvarchar(16),N'1.0.0')";Mutated="CONVERT(nvarchar(16),N'1.0.0 ')";State=5}
 [pscustomobject]@{Scope='OBJECT';Object='TVF_InternalParseCsv';Property='Toolbelt.Visibility';Original="CONVERT(nvarchar(16),N'internal')";Mutated="CONVERT(nvarchar(16),N'INTERNAL')";State=5}
 [pscustomobject]@{Scope='ASSEMBLY';Object='Toolbelt_File_CsvMemory';Property='Toolbelt.Managed';Original='CONVERT(bit,1)';Mutated='CONVERT(int,1)';State=4}
 [pscustomobject]@{Scope='DATABASE';Object='';Property='Toolbelt.Module.toolbelt.file.csv-memory.DeploymentMode';Original="CONVERT(nvarchar(16),N'$Mode')";Mutated="CONVERT(nvarchar(16),N'$Mode ')";State=2}
}

function Assert-CsvMarkerGuardCase($Case){
 $known=@(foreach($mode in @('local','central')){Get-CsvMarkerGuardCases $mode;Get-CsvMarkerGuardCases $mode 'values'})
 if($Case.State -isnot [int] -or @($known|Where-Object {$_.Scope -ceq $Case.Scope -and $_.Object -ceq $Case.Object -and $_.Property -ceq $Case.Property -and $_.Original -ceq $Case.Original -and $_.Mutated -ceq $Case.Mutated -and $_.State -eq $Case.State}).Count -lt 1){throw 'CSV_GUARD_MARKER_CASE_INVALID'}
}

function Set-CsvGuardMarker($Connection,$Case,[string]$Expected,[string]$Value){
 Assert-CsvMarkerGuardCase $Case
 if(-not (($Expected -ceq $Case.Original -and $Value -ceq $Case.Mutated) -or ($Expected -ceq $Case.Mutated -and $Value -ceq $Case.Original))){throw 'CSV_GUARD_MARKER_TRANSITION_INVALID'}
 # Alle Identifier und SQL-Wertausdrücke stammen aus der geschlossenen Fallliste.
 $class=0;$major='0';$levels=''
 if($Case.Scope -ceq 'OBJECT'){
  $class=1;$major="OBJECT_ID(N'toolbelt_file.$($Case.Object)')"
  $kind=if($Case.Object.StartsWith('USP_',[StringComparison]::Ordinal)){'PROCEDURE'}else{'FUNCTION'}
  $levels=",@level0type=N'SCHEMA',@level0name=N'toolbelt_file',@level1type=N'$kind',@level1name=N'$($Case.Object)'"
 }elseif($Case.Scope -ceq 'ASSEMBLY'){
  $class=5;$major="(SELECT assembly_id FROM sys.assemblies WHERE name=N'Toolbelt_File_CsvMemory')"
  $levels=",@level0type=N'ASSEMBLY',@level0name=N'Toolbelt_File_CsvMemory'"
 }elseif($Case.Scope -cne 'DATABASE'){throw 'CSV_GUARD_MARKER_SCOPE'}
 Invoke-CsvSql $Connection @"
DECLARE @Expected sql_variant=$Expected,@Actual sql_variant,@Value sql_variant=$Value;
IF (SELECT COUNT(*) FROM sys.extended_properties WHERE class=$class AND major_id=$major AND minor_id=0 AND name=N'$($Case.Property)')<>1
 THROW 51595,N'Synthetic marker identity required.',1;
SELECT @Actual=value FROM sys.extended_properties WHERE class=$class AND major_id=$major AND minor_id=0 AND name=N'$($Case.Property)';
IF @Actual IS NULL OR SQL_VARIANT_PROPERTY(@Actual,N'BaseType')<>SQL_VARIANT_PROPERTY(@Expected,N'BaseType')
 OR SQL_VARIANT_PROPERTY(@Actual,N'MaxLength')<>SQL_VARIANT_PROPERTY(@Expected,N'MaxLength')
 OR DATALENGTH(@Actual)<>DATALENGTH(@Expected) OR CONVERT(varbinary(max),@Actual)<>CONVERT(varbinary(max),@Expected)
 THROW 51595,N'Synthetic marker changed.',2;
EXEC sys.sp_updateextendedproperty @name=N'$($Case.Property)',@value=@Value$levels;
"@
}

function Invoke-CsvMarkerGuards($Connection,[string]$Deploy,[string]$Uninstall,[ValidateSet('local','central')][string]$Mode,[ValidateSet('types','values',IgnoreCase=$false)][string]$Family='types'){
 $cases=@(Get-CsvMarkerGuardCases $Mode $Family);$expected=if($Family -ceq 'values'){25}else{10}
 if($cases.Count -ne $expected -or @($cases|ForEach-Object {$_.Scope+'|'+$_.Object+'|'+$_.Property}|Sort-Object -Unique).Count -ne $expected){throw 'CSV_GUARD_MARKER_CASE_SET'}
 $passed=0
 foreach($case in $cases){
  $script:stage='MARKER_GUARD_'+$Mode+'_'+$passed
  $baseline=Get-CsvSnapshot $Connection;$mutated=$null
  Set-CsvGuardMarker $Connection $case $case.Original $case.Mutated
  try{
   $mutated=Get-CsvSnapshot $Connection
   if($mutated -ceq $baseline){throw 'CSV_GUARD_MUTATION_NOT_OBSERVED'}
   foreach($text in @($Deploy,$Uninstall)){
    Assert-CsvGuardRejected $Connection $text 55324 $case.State $mutated
    $passed++
   }
  }finally{
   # Keine Restaurierung bei unklarer Identität oder zwischenzeitlicher Drift.
   if($null -ne $mutated){
    if((Get-CsvSnapshot $Connection) -cne $mutated){throw 'CSV_GUARD_RESTORE_SCOPE_CHANGED'}
    Set-CsvGuardMarker $Connection $case $case.Mutated $case.Original
    if((Get-CsvSnapshot $Connection) -cne $baseline){throw 'CSV_GUARD_RESTORATION_MISMATCH'}
   }
  }
 }
 if($passed -ne (2*$expected)){throw 'CSV_GUARD_MARKER_COUNT'}
 return $passed
}
