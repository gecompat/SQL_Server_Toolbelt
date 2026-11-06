# Vorhandene kanonische Readerorakel, nur begrenzte Timeout-/Verbindungsadaption.
function ConvertTo-ConstructorClientMetadataLoop([string]$Source){
 $parseErrors=$null;$tokens=$null
 $ast=[Management.Automation.Language.Parser]::ParseInput($Source,[ref]$tokens,[ref]$parseErrors)
 if($parseErrors.Count){throw 'CONSTRUCTOR_METADATA_SOURCE_PARSE'}
 $loops=@($ast.FindAll({param($n)$n-is[Management.Automation.Language.ForEachStatementAst]-and$n.Variable.VariablePath.UserPath-ceq'api'},$true))
 $expected="@('USP_JsonArray','USP_JsonObject','USP_JsonArraysByGroup','USP_JsonObjectsByGroup')"
 if($loops.Count-ne1-or$loops[0].Condition.Extent.Text-cne$expected){throw 'CONSTRUCTOR_METADATA_API_ROSTER'}
 $text=$loops[0].Extent.Text
 if(-not$text.Contains('foreach($empty in @($true,$false))')-or[regex]::Matches($text,'\$command=\$connection\.CreateCommand\(\)').Count-ne3-or[regex]::Matches($text,';\$command\.CommandTimeout=180').Count-ne1){throw 'CONSTRUCTOR_METADATA_SOURCE_FRAME'}
 # Keine fachlichen Orakeländerungen: alle drei Befehlsorte erhalten den
 # vorhandenen Restzeitvertrag, statt nur dem ersten180 Sekunden zu geben.
 $text=$text.Replace(';$command.CommandTimeout=180','').Replace('$command=$connection.CreateCommand()','$command=$connection.CreateCommand();$command.CommandTimeout=Get-ReleaseTimeout')
 return [scriptblock]::Create($text)
}

function Invoke-ConstructorClientMetadata([Data.SqlClient.SqlConnection]$Connection){
 if($null-eq$Connection-or$Connection.State-ne[Data.ConnectionState]::Open){throw 'CONSTRUCTOR_METADATA_OPEN_BORROWED_CONNECTION_REQUIRED'}
 $path=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../Modules/toolbelt.json.constructors/Tests/Runtime/SelectMetadata.Contract.ps1'))
 $loop=ConvertTo-ConstructorClientMetadataLoop ([IO.File]::ReadAllText($path))
 $messages=[Collections.Generic.List[string]]::new()
 [Data.SqlClient.SqlInfoMessageEventHandler]$handler={param($sender,$event)$messages.Add($event.Message)}.GetNewClosure()
 $Connection.add_InfoMessage($handler)
 try{
  $output=@(. $loop)
  if($output.Count){throw 'CONSTRUCTOR_METADATA_UNEXPECTED_ADAPTER_OUTPUT'}
  # Auch die bereits vorhandenen AGFs versprechen nvarchar(max). Die Abfrage-
  # aliase sind probeeigen; ein Nullable-Metadatenbit ist für AGFs nicht zugesagt
  # und wird nur privat beobachtet. Dies ist kein Lowpriv-/GRANT-Nachweis.
  $aggregateObservations=[Collections.Generic.List[object]]::new()
  foreach($aggregateApi in @('AGF_JsonArray','AGF_JsonObject')){
   $isObject=$aggregateApi-ceq'AGF_JsonObject'
   foreach($empty in @($true,$false)){
    $command=$Connection.CreateCommand();$reader=$null
    try{
     $command.CommandTimeout=Get-ReleaseTimeout
     $call=if($isObject){'AGF_JsonObject(Ordinal,[Key],ValueKind,[Value],Profile)'}else{'AGF_JsonArray(Ordinal,ValueKind,[Value],Profile)'}
     $insert=if($empty){''}else{"INSERT #AggregateMetadataInput VALUES(2,N'b',N'number',N'2',1),(1,N'a',N'string',N'x',1);"}
     $command.CommandText="SET NOCOUNT ON;CREATE TABLE #AggregateMetadataInput(Ordinal int NOT NULL,[Key] nvarchar(max) NOT NULL,ValueKind nvarchar(max) NOT NULL,[Value] nvarchar(max) NULL,Profile tinyint NOT NULL);$insert SELECT toolbelt_json.$call AS JsonValue FROM #AggregateMetadataInput;DROP TABLE #AggregateMetadataInput;"
     $reader=$command.ExecuteReader();$schema=$reader.GetSchemaTable()
     if($reader.FieldCount-ne1-or$reader.GetName(0)-cne'JsonValue'-or$reader.GetDataTypeName(0)-cne'nvarchar'-or$schema.Rows[0].ColumnSize-ne[int]::MaxValue){throw 'CONSTRUCTOR_AGGREGATE_CLIENT_TYPE'}
     $expected=if($isObject){if($empty){'{}'}else{'{"a":"x","b":2}'}}else{if($empty){'[]'}else{'["x",2]'}}
     if(-not$reader.Read()-or$reader.IsDBNull(0)-or$reader.GetString(0)-cne$expected-or$reader.Read()-or$reader.NextResult()){throw 'CONSTRUCTOR_AGGREGATE_CLIENT_VALUE'}
     $aggregateObservations.Add([pscustomobject]@{api=$aggregateApi;empty=$empty;allowDBNull=[bool]$schema.Rows[0].AllowDBNull})
    }finally{if($reader){$reader.Dispose()};$command.Dispose()}
   }
  }
  # Vier USP x(2SELECT+Help+ResultTable), zwei AGF x(leer+befüllt).
  return [pscustomobject]@{state='COMPLETE';profiles=(16+$aggregateObservations.Count);selectProfiles=8;helpProfiles=4;resultTableProfiles=4;aggregateProfiles=$aggregateObservations.Count;aggregateObservations=@($aggregateObservations)}
 }finally{$Connection.remove_InfoMessage($handler)}
}
