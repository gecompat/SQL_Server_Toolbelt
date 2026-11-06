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
  # Feste4 APIs x(2SELECT+1Help+1ResultTable); nur nach vollständigem Loop.
  return [pscustomobject]@{state='COMPLETE';profiles=16;selectProfiles=8;helpProfiles=4;resultTableProfiles=4}
 }finally{$Connection.remove_InfoMessage($handler)}
}
