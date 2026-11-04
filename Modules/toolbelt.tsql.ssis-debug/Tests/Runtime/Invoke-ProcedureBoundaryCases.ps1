# Wird im bestehenden echten Lowpriv-Fall aufgerufen. Die Variablen und Orakel
# stammen aus dessen unverändertem, hashgebundenem Aufbau; kein weiterer Login.
Set-StrictMode -Version Latest
'SSIS_PROCEDURE_BOUNDARIES_STAGE_SESSION'
$stateSql='SELECT @@OPTIONS AS O,@@TRANCOUNT AS T,XACT_STATE() AS S;'
function Assert-ProcedureSession($Before,[string]$Name){
 $after=Query $caller $stateSql
 Assert-Current ($Before.Rows[0].O -eq $after.Rows[0].O -and $Before.Rows[0].T -eq $after.Rows[0].T -and $Before.Rows[0].S -eq $after.Rows[0].S) $Name
}
function Assert-NoProcedureTemps{
 foreach($name in @([regex]::Matches($definition,'CREATE TABLE \[(#tbx_SsisDebug_P_[A-F0-9_]+(?:s[0-9]+)(?:_result)?)\]')|ForEach-Object {$_.Groups[1].Value}|Sort-Object -Unique)){
  Assert-Current ((Query $caller "SELECT OBJECT_ID(N'tempdb..[$name]',N'U') AS Id;").Rows[0].IsNull('Id')) 'BOUNDARY_OWN_TEMP_CLEAN'
 }
}
$before=Query $caller $stateSql
$help=Query $caller "EXEC ContosoDebug.USP_Synthetic @Hilfe=1,@Debug=255,@ResultTable=N'not-local',@KeepData=1;"
Assert-Current ($help.Select("Section='PARAMETER'").Count -eq 6) 'BOUNDARY_HELP_FIRST_INVALID_BUSINESS'
Assert-ProcedureSession $before 'BOUNDARY_HELP_SESSION'
foreach($setting in @('SET XACT_ABORT ON;','SET XACT_ABORT OFF;')){
 NonQuery $caller $setting
 $before=Query $caller $stateSql
 [void](Query $caller "EXEC ContosoDebug.USP_Synthetic $floor=0,$offset=1;")
 Assert-ProcedureSession $before 'BOUNDARY_SUCCESS_OPTIONS'
 NonQuery $caller 'BEGIN TRANSACTION;'
 try{
  $inTransaction=Query $caller $stateSql
  Reject-Procedure {Query $caller "EXEC ContosoDebug.USP_Synthetic $floor=0,$offset=1;"} 50000
  Assert-ProcedureSession $inTransaction 'BOUNDARY_CALLER_TX_PRESERVED'
 }finally{NonQuery $caller 'ROLLBACK TRANSACTION;'}
}
NonQuery $caller 'SET XACT_ABORT OFF;SET IMPLICIT_TRANSACTIONS ON;'
try{
 $before=Query $caller $stateSql
 Reject-Procedure {Query $caller "EXEC ContosoDebug.USP_Synthetic $floor=0,$offset=1;"} 50000
 Assert-ProcedureSession $before 'BOUNDARY_IMPLICIT_TX_PRESERVED'
}finally{NonQuery $caller 'IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;SET IMPLICIT_TRANSACTIONS OFF;'}
$messages=[Collections.Generic.List[string]]::new()
'SSIS_PROCEDURE_BOUNDARIES_STAGE_MESSAGES'
$handler=[Data.SqlClient.SqlInfoMessageEventHandler]{param($sender,$eventArgs) foreach($errorItem in $eventArgs.Errors){$messages.Add($errorItem.Message)}}
$caller.add_InfoMessage($handler)
try{
 foreach($debug in @('NULL','0','1','255')){
  $messages.Clear()
  $rows=Query $caller "EXEC ContosoDebug.USP_Synthetic $floor=0,$offset=1,@Debug=$debug;"
  Assert-Current ($rows.Rows.Count -eq 2 -and $messages.Count -eq $(if($debug -in @('1','255')){1}else{0})) 'BOUNDARY_DEBUG_MESSAGES_ONLY'
 }
 $messages.Clear()
 [void](Query $caller "EXEC ContosoDebug.USP_Synthetic @Hilfe=1,@Debug=255,@ResultTable=N'not-local',@KeepData=1;")
 Assert-Current ($messages.Count -eq 0) 'BOUNDARY_HELP_IGNORES_DEBUG'
}finally{$caller.remove_InfoMessage($handler)}
foreach($empty in @($false,$true)){
 foreach($matching in @($false,$true)){
  foreach($keep in @(0,1)){
   $shape=if($matching){'KeyA int NOT NULL,Adjusted int NOT NULL'}else{'Dummy nvarchar(10) NULL'}
   NonQuery $caller "CREATE TABLE #SchemaCase($shape);"
   try{
    if(-not $empty){NonQuery $caller $(if($matching){'INSERT #SchemaCase VALUES(7,7);'}else{"INSERT #SchemaCase VALUES(N'Contoso');"})}
    $sql="EXEC ContosoDebug.USP_Synthetic $floor=0,$offset=1,@ResultTable=N'#SchemaCase',@KeepData=$keep;"
    if(-not $empty -and -not $matching -and $keep -eq 1){
     Reject-Procedure {Query $caller $sql} 51025
     Assert-Current ((Query $caller 'SELECT Dummy FROM #SchemaCase;').Rows[0].Dummy -ceq 'Contoso') 'BOUNDARY_SCHEMA_KEEP_REFUSAL'
    }else{
     NonQuery $caller $sql
     Assert-Current ((Query $caller 'SELECT COUNT(*) AS N FROM #SchemaCase;').Rows[0].N -eq $(if(-not $empty -and $matching -and $keep -eq 1){3}else{2})) 'BOUNDARY_ALL_SCHEMA_KEEP_STATES'
     Assert-Current ((Query $caller "SELECT COUNT(*) AS N FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#SchemaCase') AND name IN(N'KeyA',N'Adjusted') AND system_type_id=56 AND is_nullable=0;").Rows[0].N -eq 2) 'BOUNDARY_ALL_SCHEMA_EXACT'
    }
   }finally{NonQuery $caller 'DROP TABLE #SchemaCase;'}
  }
 }
}
foreach($keep in @('NULL','0','1')){
 NonQuery $caller 'DELETE FROM #Projection;INSERT #Projection VALUES(7,7);'
 $command=$caller.CreateCommand()
 try{
  $command.CommandText="EXEC ContosoDebug.USP_Synthetic $floor=0,$offset=1,@ResultTable=N'#Projection',@KeepData=$keep;"
  $reader=$command.ExecuteReader()
  try{Assert-Current ($reader.FieldCount -eq 0 -and -not $reader.NextResult()) 'BOUNDARY_RESULTTABLE_NO_RESULTSET'}finally{$reader.Dispose()}
 }finally{$command.Dispose()}
 Assert-Current ((Query $caller 'SELECT COUNT(*) AS N FROM #Projection;').Rows[0].N -eq $(if($keep -eq '1'){3}else{2})) 'BOUNDARY_KEEP_NULL_ZERO_ONE'
}
NonQuery $caller 'CREATE TABLE #Mismatch(Witness nvarchar(20));INSERT #Mismatch VALUES(N''Contoso'');'
'SSIS_PROCEDURE_BOUNDARIES_STAGE_FAILURES'
try{
 Reject-Procedure {Query $caller "EXEC ContosoDebug.USP_Synthetic $floor=0,$offset=1,@ResultTable=N'#Mismatch',@KeepData=1;"} 51025
 Assert-Current ((Query $caller 'SELECT Witness FROM #Mismatch;').Rows[0].Witness -ceq 'Contoso') 'BOUNDARY_MISMATCH_DATA_PRESERVED'
}finally{NonQuery $caller 'DROP TABLE #Mismatch;'}
foreach($name in @('dbo.Contoso','##Contoso','#Missing')){
 Reject-Procedure {Query $caller "EXEC ContosoDebug.USP_Synthetic $floor=0,$offset=1,@ResultTable=N'$name';"} 50000
}
# Ein Materialisierungsfehler darf weder die Ausgabe vorbereiten noch eigene
# Temps oder eine Transaktion im aufrufenden Scope hinterlassen.
foreach($setting in @('SET XACT_ABORT OFF;','SET XACT_ABORT ON;')){
 NonQuery $caller $setting
 foreach($route in @(',@ResultTable=N''#Projection'',@KeepData=0',',@ResultTable=N''#Projection'',@KeepData=1','')){
  NonQuery $caller 'DELETE FROM #Projection;INSERT #Projection VALUES(7,7);'
  $before=Query $caller $stateSql
  Reject-Procedure {Query $caller "EXEC ContosoDebug.USP_Synthetic $floor=0,$offset=2147483647$route;"} 8115
  $unchanged=Query $caller 'SELECT COUNT(*) AS N,MIN(KeyA) AS K,MIN(Adjusted) AS V FROM #Projection;'
  Assert-Current ($unchanged.Rows[0].N -eq 1 -and $unchanged.Rows[0].K -eq 7 -and $unchanged.Rows[0].V -eq 7) 'BOUNDARY_MATERIALIZATION_FAILURE_ATOMIC'
  Assert-ProcedureSession $before 'BOUNDARY_MATERIALIZATION_SESSION'
  Assert-NoProcedureTemps
 }
}
NonQuery $caller 'SET XACT_ABORT OFF;'
# Der Fehler tritt erst beim INSERT nach erfolgreicher Vorbereitung auf. Beide
# KeepData-Zweige müssen Inhalt und Index der Caller-Tabelle zurückrollen.
NonQuery $caller 'CREATE TABLE #Atomic(KeyA int NOT NULL,Adjusted int NOT NULL CHECK(Adjusted<150));CREATE INDEX IX_Atomic ON #Atomic(KeyA);INSERT #Atomic VALUES(7,7);'
try{
 foreach($keep in @(0,1)){
  $before=Query $caller $stateSql
  Reject-Procedure {Query $caller "EXEC ContosoDebug.USP_Synthetic $floor=0,$offset=1,@ResultTable=N'#Atomic',@KeepData=$keep;"} 547
  $witness=Query $caller "SELECT COUNT(*) AS N,MIN(KeyA) AS K,MIN(Adjusted) AS V FROM #Atomic;"
  Assert-Current ($witness.Rows[0].N -eq 1 -and $witness.Rows[0].K -eq 7 -and $witness.Rows[0].V -eq 7) 'BOUNDARY_WRITE_FAILURE_ATOMIC'
  Assert-Current ((Query $caller "SELECT COUNT(*) AS N FROM tempdb.sys.indexes WHERE object_id=OBJECT_ID(N'tempdb..#Atomic') AND name=N'IX_Atomic';").Rows[0].N -eq 1) 'BOUNDARY_WRITE_INDEX_PRESERVED'
  Assert-ProcedureSession $before 'BOUNDARY_WRITE_FAILURE_SESSION'
  Assert-NoProcedureTemps
 }
}finally{NonQuery $caller 'DROP TABLE #Atomic;'}
# Typgrenzen werden über echte RPC-Parameter geprüft, nicht durch Einbetten
# numerischer Literale in den generierten SQL-Text.
$intBytes=$bytes
'SSIS_PROCEDURE_BOUNDARIES_STAGE_TYPES'
foreach($family in @('bigint','decimal')){
 $bytes=[IO.File]::ReadAllBytes((Join-Path $PSScriptRoot "../Fixtures/procedure-$family-8.dtsx"))
 $typedTemplate=[string](Generate-ProcedureArtifact 'bindings-template' '').Rows[0].Content
 $typedArtifacts=Generate-ProcedureArtifact 'procedure-definition' $typedTemplate ('USP_Typed_'+$family)
 $typedDdl=[string]@($typedArtifacts.Select("ArtifactKind='ProcedureDefinition'"))[0].Content
 $typedManifest=([string]@($typedArtifacts.Select("ArtifactKind='ProcedureManifest'"))[0].Content)|ConvertFrom-Json
 $typedFloor=[string]@($typedManifest.parameters|Where-Object inputName -like '*SourceFloor')[0].name
 $typedOffset=[string]@($typedManifest.parameters|Where-Object inputName -like '*Offset')[0].name
 NonQuery $Connection $typedDdl
 try{
  NonQuery $Connection "GRANT EXECUTE ON OBJECT::ContosoDebug.USP_Typed_$family TO [$login];"
  $expectedType=if($family -ceq 'bigint'){'bigint'}else{'decimal(38,18)'}
  Assert-Current (@($typedManifest.parameters|Where-Object sqlType -CNE $expectedType).Count -eq 0) 'BOUNDARY_TYPED_MANIFEST'
  $metadata=Query $Connection "SELECT TYPE_NAME(user_type_id) AS T,precision AS P,scale AS S FROM sys.parameters WHERE object_id=OBJECT_ID(N'ContosoDebug.USP_Typed_$family') AND parameter_id<=2;"
  Assert-Current ($metadata.Rows.Count -eq 2 -and @($metadata.Rows|Where-Object {$_.T -cne $family -or $_.P -ne $(if($family -ceq 'bigint'){19}else{38}) -or $_.S -ne $(if($family -ceq 'bigint'){0}else{18})}).Count -eq 0) 'BOUNDARY_TYPED_NATIVE_SIGNATURE'
  $values=if($family -ceq 'bigint'){@('-9223372036854775808','9223372036854775807')}else{@('-99999999999999999999.999999999999999999','99999999999999999999.999999999999999999','0.000000000000000001')}
  foreach($value in $values){
   $command=$caller.CreateCommand();$command.CommandType='StoredProcedure';$command.CommandText="ContosoDebug.USP_Typed_$family"
   try{
    $sqlType=if($family -ceq 'bigint'){[Data.SqlDbType]::BigInt}else{[Data.SqlDbType]::Decimal}
    $p=$command.Parameters.Add($typedFloor,$sqlType);$p.Value=0
    $p=$command.Parameters.Add($typedOffset,$sqlType)
    if($family -ceq 'bigint'){$p.Value=[long]::Parse($value,[Globalization.CultureInfo]::InvariantCulture)}
    else{foreach($parameter in $command.Parameters){$parameter.Precision=38;$parameter.Scale=18};$p.Value=[Data.SqlTypes.SqlDecimal]::Parse($value)}
    $reader=$command.ExecuteReader()
    try{
     $shape=$reader.GetSchemaTable()
     # SqlClient verwendet für ganzzahlige Resultspalten den Scale-Sentinel
     # 255. Die SQL-Signatur wird oben separat im Katalog exakt geprüft.
     [IO.File]::AppendAllText((Join-Path (Split-Path -Parent $IdentityJournal) 'typed-schema.private.jsonl'),((@{family=$family;type=$reader.GetDataTypeName(1);precision=[int]$shape.Rows[1].NumericPrecision;scale=[int]$shape.Rows[1].NumericScale}|ConvertTo-Json -Compress)+"`n"))
     Assert-Current ($reader.FieldCount -eq 2 -and $reader.GetName(1) -ceq 'Adjusted' -and $reader.GetDataTypeName(1) -ceq $family -and $(if($family -ceq 'bigint'){$reader.GetFieldType(1) -eq [long]}else{$shape.Rows[1].NumericPrecision -eq 38 -and $shape.Rows[1].NumericScale -eq 18})) 'BOUNDARY_TYPED_RESULT_SCHEMA'
     $count=0
     while($reader.Read()){
      $actual=if($family -ceq 'bigint'){$reader.GetInt64(1).ToString([Globalization.CultureInfo]::InvariantCulture)}else{$reader.GetSqlDecimal(1).ToString()}
      Assert-Current ($actual -ceq $value) 'BOUNDARY_TYPED_EXACT_VALUE';$count++
     }
     Assert-Current ($count -eq 2 -and -not $reader.NextResult()) 'BOUNDARY_TYPED_SINGLE_RESULTSET'
    }finally{$reader.Dispose()}
    $command.Parameters[$typedOffset].Value=[DBNull]::Value
    Reject-Procedure {$command.ExecuteNonQuery()} 50000
   }finally{$command.Dispose()}
  }
  $command=$caller.CreateCommand()
  try{
   $command.CommandType='StoredProcedure';$command.CommandText="ContosoDebug.USP_Typed_$family"
   $command.Parameters.Add($typedFloor,[Data.SqlDbType]::Int).Value=0
   $command.Parameters.Add($typedOffset,[Data.SqlDbType]::NVarChar,100).Value=if($family -ceq 'bigint'){'9223372036854775808'}else{'100000000000000000000.000000000000000000'}
   # RPC-Konvertierung von nvarchar in einen außerhalb des Wertebereichs
   # liegenden numerischen Parameter meldet in beiden Fällen 8114.
   Reject-Procedure {$command.ExecuteNonQuery()} 8114
  }finally{$command.Dispose()}
 }finally{NonQuery $Connection "DROP PROCEDURE ContosoDebug.USP_Typed_$family;"}
}
$bytes=$intBytes
NonQuery $caller 'DROP TABLE #Projection;CREATE TABLE #Projection(KeyA int NOT NULL,Adjusted int NOT NULL);INSERT #Projection VALUES(2,207);'
"SSIS_PROCEDURE_BOUNDARIES_PASS"
