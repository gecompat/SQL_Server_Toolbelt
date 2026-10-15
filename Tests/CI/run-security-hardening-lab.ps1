param([string]$Version='2019',[string]$Platform='linux',[string]$Patch='latest')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$tree=[Management.Automation.Language.Parser]::ParseFile((Join-Path $repo 'Tests/CI/run-lab-local.ps1'),[ref]$null,[ref]$null)
foreach($name in @('Get-EnvironmentVariableValue','Resolve-LabContract','Test-LabTargetReady','Get-LabTargetsForSelector','New-LabConnectionString')){
 $nodes=@($tree.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq $name},$true))
 if($nodes.Count-ne1){throw 'WAVE1_DISCOVERY'}
 . ([scriptblock]::Create($nodes[0].Extent.Text))
}
function Read-Source([string]$Path){
 $full=[IO.Path]::GetFullPath($Path)
 if(-not$full.StartsWith($repo+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'WAVE1_SOURCE_SCOPE'}
 $text=Get-Content -LiteralPath $full -Raw
 if($full.EndsWith('Authorization.Repeat.Contract.sql')){$text=$text.Replace(':r Deploy.sql',(Read-Source (Join-Path $repo 'Modules/toolbelt.core.work-type/Deployment/Deploy.sql')))}
 $text=[regex]::Replace($text,'(?im)^:r\s+([^\r\n]+)\r?$',{param($m)Read-Source (Join-Path (Split-Path -Parent $full) $m.Groups[1].Value.Trim())})
 $text=[regex]::Replace($text,'(?im)^:on error exit\s*$','')
 return $text.Replace('$(DeploymentMode)','local').Replace('$(ToolbeltDatabase)',$database).Replace('$(CompatibilityLevel)','150').Replace('$(ConfirmNoExternalConsumers)','0').Replace('$(AllowDataLoss)','1')
}
function Execute([Data.SqlClient.SqlConnection]$Connection,[string]$Sql){
 $command=$Connection.CreateCommand();$command.CommandText=$Sql;$command.CommandTimeout=300
 try{[void]$command.ExecuteNonQuery()}finally{$command.Dispose()}
}
function Run-Source([Data.SqlClient.SqlConnection]$Connection,[string]$Path){
 foreach($batch in @([regex]::Split((Read-Source (Join-Path $repo $Path)),'(?im)^\s*GO\s*(?:--[^\r\n]*)?\r?$')|Where-Object{-not[string]::IsNullOrWhiteSpace($_)})){
  Execute $Connection $batch
 }
}
$lab=Resolve-LabContract
$targets=@(Get-LabTargetsForSelector -Contract $lab.Contract -Selector ([pscustomobject]@{Platform=$Platform;Version=$Version;Patch=$Patch}))
if($targets.Count-lt1){throw 'SECURITY_READY_TARGET_MISSING'}
foreach($target in $targets){
$builder=[Data.SqlClient.SqlConnectionStringBuilder]::new((New-LabConnectionString -Entry $target))
$builder['Initial Catalog']='master';$builder['Pooling']=$false
$master=[Data.SqlClient.SqlConnection]::new($builder.ConnectionString)
$connection=$null;$created=$false;$database='TBX_SecurityHardening_'+[guid]::NewGuid().ToString('N')
try{
 $master.Open();Execute $master ('CREATE DATABASE ['+$database+'] COLLATE Latin1_General_100_CS_AS;');$created=$true
 $builder['Initial Catalog']=$database;$connection=[Data.SqlClient.SqlConnection]::new($builder.ConnectionString);$connection.Open()


 $modules=@('toolbelt.core.result-table','toolbelt.core.work-type','toolbelt.core.execution-context','toolbelt.core.execution-cancel','toolbelt.core.second-session','toolbelt.core.event-log','toolbelt.core.console-message','toolbelt.core.generate-series','toolbelt.conversion.base64','toolbelt.conversion.uri-component','toolbelt.string.split-characters','toolbelt.string.split-advanced','toolbelt.json.path-exists','toolbelt.json.pointer')
 foreach($module in $modules){Run-Source $connection ('Modules/'+$module+'/Deployment/Deploy.sql')}
 foreach($module in $modules){
  $test='Modules/'+$module+'/Tests/Runtime/Security.Contract.sql'
  if(Test-Path (Join-Path $repo $test)){Run-Source $connection $test;Write-Output ('SECURITY_CONTRACT_PASS_'+$module)}
 }
 Execute $connection "DROP FUNCTION [toolbelt_conversion].[TVF_Base64EncodeStatus];"
 Execute $connection "CREATE FUNCTION [toolbelt_conversion].[TVF_Base64EncodeStatus](@Value varbinary(max),@UrlSafe bit=0) RETURNS TABLE AS RETURN(/* Contoso foreign */SELECT CONVERT(varchar(max),'Contoso foreign') AS EncodedValue,CONVERT(varchar(16),'OK') AS Status);"
 $denied=$false
 try{Run-Source $connection 'Modules/toolbelt.conversion.base64/Deployment/Deploy.sql'}catch{$failure=$_.Exception;while($failure.InnerException){$failure=$failure.InnerException};if($failure-is[Data.SqlClient.SqlException]-and$failure.Number-eq51044){$denied=$true}else{throw 'SECURITY_FOREIGN_STATUS_UNEXPECTED_ERROR'}}
 if(-not$denied){throw 'SECURITY_FOREIGN_STATUS_OVERWRITTEN'}
 Execute $connection "IF (SELECT type FROM sys.objects WHERE object_id=OBJECT_ID(N'toolbelt_conversion.TVF_Base64EncodeStatus'))<>'IF' OR OBJECT_DEFINITION(OBJECT_ID(N'toolbelt_conversion.TVF_Base64EncodeStatus')) NOT LIKE N'%Contoso foreign%' THROW 52990,N'Foreign status function changed.',12; DROP FUNCTION [toolbelt_conversion].[TVF_Base64EncodeStatus];"
 Run-Source $connection 'Modules/toolbelt.conversion.base64/Deployment/Deploy.sql'
 Execute $connection "DROP FUNCTION [toolbelt_core].[TVF_GenerateSeriesBigIntStatus];"
 Execute $connection "CREATE FUNCTION [toolbelt_core].[TVF_GenerateSeriesBigIntStatus](@Start bigint,@Stop bigint,@Step bigint=NULL) RETURNS TABLE AS RETURN(/* Contoso foreign */SELECT CONVERT(bigint,0) AS Value,CONVERT(varchar(16),'OK') AS Status,CONVERT(decimal(38,0),1) AS RequestedRows);"
 $denied=$false
 try{Run-Source $connection 'Modules/toolbelt.core.generate-series/Deployment/Deploy.sql'}catch{$failure=$_.Exception;while($failure.InnerException){$failure=$failure.InnerException};if($failure-is[Data.SqlClient.SqlException]-and$failure.Number-eq51054){$denied=$true}else{throw 'SECURITY_FOREIGN_STATUS_UNEXPECTED_ERROR'}}
 if(-not$denied){throw 'SECURITY_FOREIGN_STATUS_OVERWRITTEN'}
 Execute $connection "IF (SELECT type FROM sys.objects WHERE object_id=OBJECT_ID(N'toolbelt_core.TVF_GenerateSeriesBigIntStatus'))<>'IF' OR OBJECT_DEFINITION(OBJECT_ID(N'toolbelt_core.TVF_GenerateSeriesBigIntStatus')) NOT LIKE N'%Contoso foreign%' THROW 52990,N'Foreign status function changed.',12; DROP FUNCTION [toolbelt_core].[TVF_GenerateSeriesBigIntStatus];"
 Run-Source $connection 'Modules/toolbelt.core.generate-series/Deployment/Deploy.sql'
 Execute $connection "DROP FUNCTION [toolbelt_string].[TVF_SplitByCharactersStatus];"
 Execute $connection "CREATE FUNCTION [toolbelt_string].[TVF_SplitByCharactersStatus](@Input nvarchar(max),@Separators nvarchar(4000),@KeepEmpty bit=1) RETURNS TABLE AS RETURN(/* Contoso foreign */SELECT CONVERT(nvarchar(max),N'Contoso foreign') AS Value,CONVERT(bigint,1) AS Ordinal,CONVERT(varchar(16),'OK') AS Status);"
 $denied=$false
 try{Run-Source $connection 'Modules/toolbelt.string.split-characters/Deployment/Deploy.sql'}catch{$failure=$_.Exception;while($failure.InnerException){$failure=$failure.InnerException};if($failure-is[Data.SqlClient.SqlException]-and$failure.Number-eq51074){$denied=$true}else{throw 'SECURITY_FOREIGN_STATUS_UNEXPECTED_ERROR'}}
 if(-not$denied){throw 'SECURITY_FOREIGN_STATUS_OVERWRITTEN'}
 Execute $connection "IF (SELECT type FROM sys.objects WHERE object_id=OBJECT_ID(N'toolbelt_string.TVF_SplitByCharactersStatus'))<>'IF' OR OBJECT_DEFINITION(OBJECT_ID(N'toolbelt_string.TVF_SplitByCharactersStatus')) NOT LIKE N'%Contoso foreign%' THROW 52990,N'Foreign status function changed.',12; DROP FUNCTION [toolbelt_string].[TVF_SplitByCharactersStatus];"
 Run-Source $connection 'Modules/toolbelt.string.split-characters/Deployment/Deploy.sql'
 Write-Output 'SECURITY_FOREIGN_STATUS_NAMES_PRESERVED_PASS'
 # Real simultaneous requests compete for the last database slot. The actual
 # principal quota is empty; legacy-like synthetic seed rows count globally.
 Execute $connection "IF EXISTS(SELECT 1 FROM toolbelt_core.ExecutionCancellation) THROW 52990,N'Concurrent quota fixture needs its own empty table.',11; INSERT toolbelt_core.ExecutionCancellation(ExecutionId,RequestedBy) SELECT NEWID(),N'Contoso quota fixture' FROM toolbelt_core.TVF_GenerateSeriesBigInt(1,99999,1);"
 $clients=@();$commands=@();$tasks=@()
 try{
  foreach($i in 1..2){
   $client=[Data.SqlClient.SqlConnection]::new($builder.ConnectionString);$client.Open();$clients+=,$client
   $command=$client.CreateCommand();$command.CommandTimeout=30;$command.CommandText='EXEC toolbelt_core.USP_RequestExecutionCancellation @ExecutionId=@Id;'
   [void]$command.Parameters.Add('@Id',[Data.SqlDbType]::UniqueIdentifier);$command.Parameters['@Id'].Value=[guid]::NewGuid()
   $commands+=,$command;$tasks+=,$command.ExecuteNonQueryAsync()
  }
  $succeeded=0;$quotaDenied=0
  foreach($task in $tasks){try{[void]$task.GetAwaiter().GetResult();$succeeded++}catch{$failure=$_.Exception;while($failure.InnerException){$failure=$failure.InnerException};if($failure-is[Data.SqlClient.SqlException]-and$failure.Number-eq52605){$quotaDenied++}else{throw 'SECURITY_CONCURRENT_QUOTA_UNEXPECTED_ERROR'}}}
  if($succeeded-ne1-or$quotaDenied-ne1){throw 'SECURITY_CONCURRENT_QUOTA_NOT_ATOMIC'}
 }finally{foreach($command in $commands){$command.Dispose()};foreach($client in $clients){$client.Dispose()}}
 Write-Output 'SECURITY_CONCURRENT_QUOTA_PASS'
 # Nur synthetische Framelängen erfassen, keine Payloads oder Servermeldungen.
 $frameLengths=[Collections.Generic.List[int]]::new()
 $handler=[Data.SqlClient.SqlInfoMessageEventHandler]{param($sender,$event)foreach($error in $event.Errors){$frameLengths.Add($error.Message.Length)}}
 $connection.add_InfoMessage($handler)
 try{
  $command=$connection.CreateCommand();$command.CommandTimeout=30;$command.CommandText='EXEC toolbelt_core.USP_WriteConsoleMessage @Message=@Value,@Immediate=1;'
  [void]$command.Parameters.Add('@Value',[Data.SqlDbType]::NVarChar,-1);$command.Parameters['@Value'].Value=('a'*524288)
  [void]$command.ExecuteNonQuery()
  $sum=0;foreach($length in $frameLengths){$sum+=$length}
  if($sum-ne524288-or$frameLengths.Count-lt1-or$frameLengths.Count-gt512){throw 'SECURITY_CONSOLE_FRAME_BOUNDARY'}
  $frameLengths.Clear();$command.Parameters['@Value'].Value=('a'*524289);$denied=$false
  try{[void]$command.ExecuteNonQuery()}catch{$failure=$_.Exception;while($failure.InnerException){$failure=$failure.InnerException};if($failure-is[Data.SqlClient.SqlException]-and$failure.Number-eq52801){$denied=$true}else{throw 'SECURITY_CONSOLE_UNEXPECTED_ERROR'}}
  if(-not$denied-or$frameLengths.Count-ne0){throw 'SECURITY_CONSOLE_PARTIAL_OUTPUT'}
 }finally{if($command){$command.Dispose()};$connection.remove_InfoMessage($handler)}
 Write-Output 'SECURITY_CONSOLE_NO_PARTIAL_FRAMES_PASS'
 foreach($module in $modules){Run-Source $connection ('Modules/'+$module+'/Deployment/Deploy.sql')}
 Write-Output 'SECURITY_CURRENT_REPEAT_PASS'
 [array]::Reverse($modules)
 foreach($module in $modules){Run-Source $connection ('Modules/'+$module+'/Deployment/Uninstall.sql')}
 Write-Output 'SECURITY_REVERSE_UNINSTALL_PASS'

}
finally{
 if($connection){$connection.Dispose()}
 if($created){Execute $master ('DROP DATABASE ['+$database+'];');
  $check=$master.CreateCommand();$check.CommandText="SELECT COUNT(*) FROM sys.databases WHERE name=@name";[void]$check.Parameters.AddWithValue('@name',$database)
  try{if([int]$check.ExecuteScalar()-ne0){throw 'WAVE1_CLEANUP_FAILED'}}finally{$check.Dispose()}
 }
 $master.Dispose();Write-Output 'SECURITY_OWN_DATABASE_CLEANUP_VERIFIED'
}

}
