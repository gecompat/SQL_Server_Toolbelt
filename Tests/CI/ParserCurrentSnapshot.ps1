# Private read-only snapshots for the current parser qualification coordinator.
function Get-CurrentParserTimeout {
 $limit=$script:parserCurrentRunEnd
 if($script:parserCurrentCleanup){$limit=$script:parserCurrentCleanupEnd}
 $remaining=[int][Math]::Floor(($limit-[datetimeoffset]::UtcNow).TotalSeconds)
 if($remaining -lt 1){throw 'PARSER_CURRENT_DEADLINE'}
 return [Math]::Min(90,$remaining)
}
function Read-CurrentParserJson($Connection,[string]$Sql){
 $command=$Connection.CreateCommand();$command.CommandTimeout=Get-CurrentParserTimeout
 $command.CommandText=$Sql;$reader=$null;$text=[Text.StringBuilder]::new()
 try{
  $reader=$command.ExecuteReader()
  while($reader.Read()){
   [void](Get-CurrentParserTimeout)
   $chunk=$reader.GetString(0)
   if($text.Length+$chunk.Length -gt 4194304){throw 'PARSER_CURRENT_SNAPSHOT_LIMIT'}
   [void]$text.Append($chunk)
  }
  $json=$text.ToString();[void]($json|ConvertFrom-Json -DateKind String)
  return $json
 }finally{if($reader){$reader.Dispose()};$command.Dispose()}
}
function Get-CurrentParserSnapshot($Connection,[string[]]$Hashes){
 foreach($hash in $Hashes){if($hash -cnotmatch '^0x[0-9A-F]{128}$'){throw 'PARSER_CURRENT_HASH_FORMAT'}}
 $identity=Read-CurrentParserJson $Connection "SELECT CONVERT(nvarchar(128),SERVERPROPERTY('MachineName')) AS machine,CONVERT(nvarchar(128),SERVERPROPERTY('InstanceName')) AS instance,CONVERT(int,SERVERPROPERTY('ProcessID')) AS processId,sqlserver_start_time AS started,SUSER_SNAME() AS actor FROM sys.dm_os_sys_info FOR JSON PATH;"
 $configuration=Read-CurrentParserJson $Connection "SELECT name,CONVERT(nvarchar(100),value) AS configured,CONVERT(nvarchar(100),value_in_use) AS effective FROM sys.configurations ORDER BY name FOR JSON PATH;"
 $trust=Read-CurrentParserJson $Connection "SELECT CONVERT(varchar(130),hash,1) AS hash,description,create_date,created_by FROM sys.trusted_assemblies ORDER BY hash FOR JSON PATH;"
 $databases=Read-CurrentParserJson $Connection 'SELECT name,state FROM sys.databases ORDER BY name FOR JSON PATH;'
 $consumers=[Collections.Generic.List[object]]::new()
 foreach($database in @($databases|ConvertFrom-Json -DateKind String)){
  if($database.state -ne 0){throw 'PARSER_CURRENT_DATABASE_NOT_ONLINE'}
  $safeName=$database.name.Replace(']',']]')
  $sql='SELECT a.name,a.permission_set_desc,CONVERT(varchar(130),HASHBYTES(N''SHA2_512'',f.content),1) AS hash FROM ['+$safeName+'].sys.assemblies a JOIN ['+$safeName+'].sys.assembly_files f ON a.assembly_id=f.assembly_id WHERE f.file_id=1 AND HASHBYTES(N''SHA2_512'',f.content) IN ('+($Hashes -join ',')+') ORDER BY a.name FOR JSON PATH;'
  $consumers.Add([ordered]@{database=$database.name;assemblies=(Read-CurrentParserJson $Connection $sql)})
 }
 return @{identity=$identity;configuration=$configuration;trust=$trust;databases=$databases;consumers=($consumers|ConvertTo-Json -Depth 5 -Compress)}
}
function Save-CurrentParserPrivate([string]$Path,$Value){
 $temporary=$Path+'.'+[guid]::NewGuid().ToString('N')+'.tmp'
 try{[IO.File]::WriteAllText($temporary,($Value|ConvertTo-Json -Depth 20));[IO.File]::Move($temporary,$Path,$true)}
 finally{[IO.File]::Delete($temporary)}
}
function Assert-CurrentParserLedger($Ledger){
 if($Ledger.State -cne 'COMPLETE' -or @($Ledger.OwnedDatabases).Count -gt 3){throw 'PARSER_CURRENT_LEDGER_NOT_COMPLETE'}
 foreach($database in $Ledger.OwnedDatabases){
  if($database.Name -cnotmatch '^ToolbeltParser(?:Contract|Caller)_[a-f0-9]{32}$' -or
     -not $database.Created -or -not $database.Dropped -or $database.State -cne 'DROPPED'){throw 'PARSER_CURRENT_DATABASE_SCOPE'}
 }
 foreach($entry in $Ledger.Entries){
  if($entry.AddedByWave -and $entry.State -cne 'RESTORED'){throw 'PARSER_CURRENT_TRUST_NOT_RESTORED'}
 }
}
