param([Parameter(Mandatory)][Data.SqlClient.SqlConnection]$Connection)
$ErrorActionPreference='Stop'
$script:EnvelopeDebugCount=0
$handler=[Data.SqlClient.SqlInfoMessageEventHandler]{param($sender,$eventArgs)
 if($eventArgs.Message.Contains('USP_CaptureErrorEnvelope: eine standardisierte Fehlerzeile wurde erzeugt.')){$script:EnvelopeDebugCount++}
}
$Connection.add_InfoMessage($handler)
$command=$Connection.CreateCommand()
$command.CommandText="EXEC toolbelt_core.USP_CaptureErrorEnvelope @ErrorNumber=8134,@ErrorSeverity=16,@ErrorState=1,@ErrorMessage=N'synthetic',@Debug=1;"
try{
 $reader=$command.ExecuteReader()
 try{
  $schema=$reader.GetSchemaTable()
  $names=@('CapturedAtUtc','ExecutionId','ErrorClass','ErrorNumber','ErrorSeverity','ErrorState','ErrorProcedure','ErrorLine','ErrorMessage','XactState','TransactionCount','DatabaseName','SessionId','AdditionalContext')
  $types=@('datetime2','uniqueidentifier','varchar','int','int','int','nvarchar','int','nvarchar','smallint','int','nvarchar','int','nvarchar')
  $nullable=@($false,$true,$false,$false,$false,$false,$true,$true,$false,$false,$false,$false,$false,$true)
  if($reader.FieldCount-ne14){throw 'ENVELOPE_METADATA_COUNT'}
  for($i=0;$i-lt14;$i++){
   if($reader.GetName($i)-cne$names[$i]-or$reader.GetDataTypeName($i)-cne$types[$i]-or[bool]$schema.Rows[$i].AllowDBNull-ne$nullable[$i]){throw ('ENVELOPE_METADATA_COLUMN_'+$i)}
  }
  if(-not$reader.Read()-or$reader.GetInt32(3)-ne8134-or$reader.Read()){throw 'ENVELOPE_DIRECT_ROW'}
 }finally{$reader.Dispose()}
 if($script:EnvelopeDebugCount-ne1){throw 'ENVELOPE_DIRECT_DEBUG_MESSAGE'}
 'ENVELOPE_METADATA_AND_DEBUG_PASS'
}finally{$command.Dispose();$Connection.remove_InfoMessage($handler)}
