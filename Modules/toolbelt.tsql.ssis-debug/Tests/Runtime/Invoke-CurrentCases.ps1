[CmdletBinding()]
param([Parameter(Mandatory)][Data.SqlClient.SqlConnection]$Connection,
      [string]$CrossDatabase,[string]$FixtureModuleRoot)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$module=if($FixtureModuleRoot){[IO.Path]::GetFullPath($FixtureModuleRoot)}else{Split-Path (Split-Path $PSScriptRoot)}
$checks=0
function Assert-Current([bool]$Value,[string]$Code){if(-not $Value){throw ('SSIS_CURRENT_ASSERT_'+$Code)};$script:checks++}
function Invoke-CurrentSql([string]$Sql){
 $cmd=$Connection.CreateCommand();$cmd.CommandTimeout=Get-SsisNativeTimeout 40;$cmd.CommandText=$Sql
 try{$table=[Data.DataTable]::new();$reader=$cmd.ExecuteReader();try{if($reader.FieldCount -gt 0){$table.Load($reader)}}finally{$reader.Dispose()};return ,$table}finally{$cmd.Dispose()}
}
function Invoke-CurrentExplain([byte[]]$Bytes,[string]$Operation='explain',[string]$Bindings,[string]$Catalog,
 [string]$Context,[string]$ResultTable,[bool]$Keep=$false,[bool]$Help=$false,[hashtable]$Limits=@{}){
 $cmd=$Connection.CreateCommand();$cmd.CommandType='StoredProcedure';$cmd.CommandText='toolbelt_tsql.USP_ExplainSsisDataFlow'
 $cmd.CommandTimeout=Get-SsisNativeTimeout 45
 [void]$cmd.Parameters.Add('@PackageBytes',[Data.SqlDbType]::VarBinary,-1)
 $cmd.Parameters['@PackageBytes'].Value=if($null -eq $Bytes){[DBNull]::Value}else{$Bytes}
 [void]$cmd.Parameters.Add('@Operation',[Data.SqlDbType]::VarChar,32);$cmd.Parameters['@Operation'].Value=$Operation
 [void]$cmd.Parameters.Add('@TSqlVersion',[Data.SqlDbType]::SmallInt);$cmd.Parameters['@TSqlVersion'].Value=$script:currentDialect
 foreach($p in @(@('Bindings',$Bindings,-1),@('CatalogBindings',$Catalog,-1),@('ProjectContext',$Context,-1),@('ResultTable',$ResultTable,128))){
  [void]$cmd.Parameters.Add('@'+$p[0],[Data.SqlDbType]::NVarChar,[int]$p[2]);$cmd.Parameters['@'+$p[0]].Value=if($null -eq $p[1]){[DBNull]::Value}else{$p[1]}
 }
 foreach($p in @(@('KeepData',$Keep),@('Hilfe',$Help))){[void]$cmd.Parameters.Add('@'+$p[0],[Data.SqlDbType]::Bit);$cmd.Parameters['@'+$p[0]].Value=[bool]$p[1]}
 foreach($name in $Limits.Keys){[void]$cmd.Parameters.Add($name,[Data.SqlDbType]::BigInt);$cmd.Parameters[$name].Value=if($null -eq $Limits[$name]){[DBNull]::Value}else{[long]$Limits[$name]}}
 try{
  $table=[Data.DataTable]::new();$reader=$cmd.ExecuteReader()
  try{if($reader.FieldCount -gt 0){$table.Load($reader)};if(-not $reader.IsClosed -and $reader.NextResult()){throw 'SSIS_CURRENT_EXTRA_RESULTSET'}}finally{$reader.Dispose()}
  return ,$table
 }finally{$cmd.Dispose()}
}
function Reject-Current([scriptblock]$Action,[string]$Code){
 $caught=$false
 try{[void](& $Action)}catch{
  $e=$_.Exception;while($e -and $e -isnot [Data.SqlClient.SqlException]){$e=$e.InnerException}
  if($null -eq $e -or -not $e.Message.Contains($Code)){throw 'SSIS_CURRENT_REJECTION_ORACLE'};$caught=$true
 }
 Assert-Current $caught 'EXPECTED_REJECTION'
}
if($Connection.State -cne 'Open'){throw 'SSIS_CURRENT_CONNECTION_REQUIRED'}
$script:currentDialect=[int16](Invoke-CurrentSql 'SELECT compatibility_level AS C FROM sys.databases WITH(NOLOCK) WHERE database_id=DB_ID();').Rows[0].C
$api=Get-Content (Join-Path $module 'Contracts/Api.json') -Raw|ConvertFrom-Json
$actual=Invoke-CurrentSql "SELECT p.parameter_id,p.name,t.name AS TypeName,p.max_length FROM sys.parameters p WITH(NOLOCK) JOIN sys.types t WITH(NOLOCK) ON t.user_type_id=p.user_type_id WHERE p.object_id=OBJECT_ID(N'toolbelt_tsql.USP_ExplainSsisDataFlow') ORDER BY p.parameter_id;"
Assert-Current ($actual.Rows.Count -eq $api.parameters.Count) 'CURRENT_PARAMETER_COUNT'
for($i=0;$i -lt $api.parameters.Count;$i++){Assert-Current ($actual.Rows[$i].name -ceq $api.parameters[$i].name) 'PARAMETER_ORDER'}
$tail=@($actual.Rows|Select-Object -Last 4|ForEach-Object name)
Assert-Current (($tail -join ',') -ceq '@ResultTable,@KeepData,@Debug,@Hilfe') 'COMMON_TAIL'
$limitNames=@($api.parameters|Where-Object {$_.name.StartsWith('@Max')}|ForEach-Object name)
Assert-Current ($limitNames.Count -eq 24) 'LIMIT_PARAMETER_COUNT'
foreach($name in $limitNames){Assert-Current (@($actual.Rows|Where-Object {$_.name -ceq $name -and $_.TypeName -ceq 'bigint'}).Count -eq 1) 'LIMIT_BIGINT'}
$help=Invoke-CurrentExplain -Bytes $null -Help $true -Context '{invalid' -Limits @{'@MaxPackageBytes'=-1}
Assert-Current ($help.Columns.Count -eq 12 -and $help.Rows.Count -gt 0) 'HELP_FIRST'
$bytes=[IO.File]::ReadAllBytes((Join-Path $module 'Tests/Fixtures/synthetic-8.dtsx'))
$template=Invoke-CurrentExplain -Bytes $bytes -Operation 'bindings-template'
Assert-Current ($template.Columns.Count -eq 13 -and $template.Rows.Count -eq 1 -and $template.Rows[0].ArtifactKind -ceq 'BindingsTemplate') 'CURRENT_TEMPLATE_SHAPE'
$json=[string]$template.Rows[0].Content;$data=$json|ConvertFrom-Json -Depth 64
Assert-Current ($data.schemaVersion -eq 2) 'DEFAULT_CURRENT_SCHEMA'
Assert-Current (-not $data.PSObject.Properties['resourcePolicy'] -and -not $data.PSObject.Properties['resourceOptions']) 'NO_JSON_LIMITS'
Assert-Current ($data.PSObject.Properties['values'] -and $data.PSObject.Properties['availableInputs']) 'EDITABLE_VALUES_DIRECTORY'
foreach($pair in @(@('User::SourceFloor',0),@('User::Offset',1),@('User::Threshold',100))){
 $entry=@($data.availableInputs|Where-Object name -CEQ $pair[0])
 Assert-Current ($entry.Count -eq 1 -and $entry[0].defaultAvailable -eq $true) 'DISCOVERED_DEFAULT'
 Assert-Current ($data.values.PSObject.Properties[[string]$entry[0].key].Value -eq $pair[1]) 'PREFILLED_TYPED_DEFAULT'
}
foreach($entry in $data.availableInputs){if($entry.sensitive){Assert-Current (-not $data.values.PSObject.Properties[[string]$entry.key]) 'SENSITIVE_NOT_PREFILLED'}}
$replay=Invoke-CurrentExplain -Bytes $bytes -Bindings $json
Assert-Current ($replay.Columns.Count -eq 13) 'VALUES_ROUNDTRIP'
$plain=Invoke-CurrentExplain -Bytes $bytes
Assert-Current ($plain.Columns.Count -eq 13) 'PLAIN_EXPLAIN_CURRENT'
$allOpen=@{};foreach($name in $limitNames){$allOpen[$name]=0}
$open=Invoke-CurrentExplain -Bytes $bytes -Operation 'bindings-template' -Limits $allOpen
Assert-Current ($open.Rows.Count -eq 1) 'ALL_ZERO_ACCEPTED'
foreach($name in $limitNames){
 $bad=@{};$bad[$name]=-1;Reject-Current {Invoke-CurrentExplain -Bytes $bytes -Operation 'bindings-template' -Limits $bad} $name
 $bad=@{};$bad[$name]=$null;Reject-Current {Invoke-CurrentExplain -Bytes $bytes -Operation 'bindings-template' -Limits $bad} $name
}
Reject-Current {Invoke-CurrentExplain -Bytes $bytes -Operation 'bindings-template' -Limits @{'@MaxPackageBytes'=($bytes.Length-1)}} 'resource_limit'
Reject-Current {Invoke-CurrentExplain -Bytes $bytes -Operation 'bindings-template' -Context '{"schemaVersion":2,"resourceOptions":{"schemaVersion":1,"preset":"unlimited"}}'} '@Max'
[void](Invoke-CurrentSql 'CREATE TABLE #CurrentPreserve(Marker int NOT NULL);INSERT #CurrentPreserve VALUES(73);')
try{
 Reject-Current {Invoke-CurrentExplain -Bytes $bytes -ResultTable '#CurrentPreserve' -Limits @{'@MaxPackageBytes'=1}} 'resource_limit'
 $saved=Invoke-CurrentSql 'SELECT Marker FROM #CurrentPreserve;';Assert-Current ($saved.Rows.Count -eq 1 -and $saved.Rows[0].Marker -eq 73) 'LIMIT_ERROR_PRESERVES_RESULTTABLE'
}finally{[void](Invoke-CurrentSql 'DROP TABLE #CurrentPreserve;')}
[void](Invoke-CurrentSql 'CREATE TABLE #CurrentResult(Dummy bit);')
try{
 $out=Invoke-CurrentExplain -Bytes $bytes -Operation 'bindings-template' -ResultTable '#CurrentResult'
 Assert-Current ($out.Rows.Count -eq 0) 'RESULTTABLE_NO_EXTRA_SELECT'
 $saved=Invoke-CurrentSql 'SELECT ArtifactKind,Content FROM #CurrentResult;';Assert-Current ($saved.Rows.Count -eq 1 -and $saved.Rows[0].ArtifactKind -ceq 'BindingsTemplate') 'RESULTTABLE_REPLACE'
 [void](Invoke-CurrentExplain -Bytes $bytes -Operation 'bindings-template' -ResultTable '#CurrentResult' -Keep $true)
 $saved=Invoke-CurrentSql 'SELECT COUNT_BIG(*) AS N FROM #CurrentResult;';Assert-Current ($saved.Rows[0].N -eq 2) 'RESULTTABLE_APPEND'
}finally{[void](Invoke-CurrentSql 'DROP TABLE #CurrentResult;')}

# Execute the documented, ordered DebugScript batches with fixed synthetic oracles.
# Batch identities/hashes bind execution to the returned script rather than an
# independently assembled plan that could hide a broken user-facing bundle.
function Invoke-CurrentDebugScript($Artifacts,$Bundle){
 Assert-Current ($Bundle.IsComplete -and $Bundle.IsExecutable -and $Bundle.SafetyStatus -ceq 'passed') 'DEBUGSCRIPT_VALIDATED'
 $details=([string]$Bundle.DetailsJson)|ConvertFrom-Json -Depth 32
 $batches=@($details.batches)
 Assert-Current ($batches.Count -gt 2 -and $details.batchSeparator -ceq 'GO') 'DEBUGSCRIPT_BATCH_DIRECTORY'
 $parts=@();$selected=@();$sequence=1
 foreach($batch in $batches){
  $row=@($Artifacts.Rows|Where-Object Ordinal -EQ $batch.resultOrdinal)
  Assert-Current ($row.Count -eq 1 -and $batch.sequence -eq $sequence -and $row[0].ArtifactKind -ceq $batch.artifactKind) 'DEBUGSCRIPT_BATCH_IDENTITY'
  $content=[string]$row[0].Content
  $hash=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($content)))
  Assert-Current ($hash -ceq $batch.contentSha256 -and $row[0].IsExecutable -and $row[0].SafetyStatus -ceq 'passed') 'DEBUGSCRIPT_BATCH_HASH_SAFETY'
  $parts+=$content.TrimEnd();$selected+=,$row[0];$sequence++
 }
 $script=[string]$Bundle.Content
 $expected=($parts -join "`nGO`n")+"`n"
 Assert-Current ($script.EndsWith($expected,[StringComparison]::Ordinal)) 'DEBUGSCRIPT_EXACT_BATCH_CONTENT'
 $results=@{}
 try{
  foreach($row in $selected){
   if($row.ArtifactKind -ceq 'CleanupSql'){continue}
   $table=Invoke-CurrentSql ([string]$row.Content)
   if($row.ArtifactKind -in @('TargetSql','RowCountSql')){$results[[string]$row.ArtifactKind]=$table}
  }
 }finally{foreach($row in $selected){if($row.ArtifactKind -ceq 'CleanupSql'){[void](Invoke-CurrentSql ([string]$row.Content))}}}
 return $results
}
$database=[string](Invoke-CurrentSql 'SELECT DB_NAME() AS N;').Rows[0].N
[void](Invoke-CurrentSql @'
CREATE TABLE dbo.SyntheticSourceA(KeyA int NOT NULL,KeyB int NOT NULL,Amount int NOT NULL);
CREATE TABLE dbo.SyntheticSourceB(KeyA int NOT NULL,KeyB int NOT NULL,Amount int NOT NULL);
CREATE TABLE dbo.SyntheticLookup(KeyA int NOT NULL,KeyB int NOT NULL,Score int NULL);
CREATE TABLE dbo.SyntheticFlatFileRows(KeyA int NOT NULL,Amount int NOT NULL);
INSERT dbo.SyntheticSourceA VALUES(1,10,100),(1,20,20),(2,10,200);
INSERT dbo.SyntheticSourceB VALUES(1,10,80),(3,30,30);
INSERT dbo.SyntheticLookup VALUES(1,10,7),(1,10,9),(1,20,NULL),(2,10,2);
INSERT dbo.SyntheticFlatFileRows VALUES(11,110),(22,220);
'@)
try{
 $catalog=@{schemaVersion=2;defaultDatabase=$database;databases=@($database);connections=@{'Package.ConnectionManagers[Synthetic]'=$database};flatFileInputs=@{}}
 $rowBytes=[IO.File]::ReadAllBytes((Join-Path $module 'Tests/Fixtures/components-v2-rowcount.dtsx'))
 $rowTemplate=Invoke-CurrentExplain -Bytes $rowBytes -Operation 'bindings-template'
 $rowArtifacts=Invoke-CurrentExplain -Bytes $rowBytes -Bindings ([string]$rowTemplate.Rows[0].Content) -Catalog ($catalog|ConvertTo-Json -Depth 12 -Compress)
 $countArtifact=@($rowArtifacts.Rows|Where-Object ArtifactKind -CEQ 'RowCountSql')
 Assert-Current ($countArtifact.Count -eq 1) 'ROWCOUNT_ARTIFACT_PRESENT'
 $bundles=@($rowArtifacts.Rows|Where-Object {$_.ArtifactKind -ceq 'DebugScript' -and $_.IsComplete -and $_.TargetFlowId -ceq $countArtifact[0].TargetFlowId})
 Assert-Current ($bundles.Count -eq 1) 'ROWCOUNT_DEBUGSCRIPT_DISCOVERABLE'
 $result=Invoke-CurrentDebugScript $rowArtifacts $bundles[0]
 Assert-Current ($result.TargetSql.Rows.Count -eq 2 -and $result.RowCountSql.Rows.Count -eq 1 -and $result.RowCountSql.Rows[0].CountValue -eq 2) 'ROWCOUNT_DEBUGSCRIPT_FIXED_ORACLE'
 Assert-Current ($result.RowCountSql.Rows[0].CountValue -is [long]) 'ROWCOUNT_BIGINT_TYPE'
 $flatBytes=[IO.File]::ReadAllBytes((Join-Path $module 'Tests/Fixtures/components-v2-flatfile.dtsx'))
 $catalog.flatFileInputs=@{'Package.ConnectionManagers[FlatInput]'=@{database=$database;schema='dbo';object='SyntheticFlatFileRows';columns=@{'Package\Flow\FlatSource.output[Rows].Columns[KeyA]'='KeyA';'Package\Flow\FlatSource.output[Rows].Columns[Amount]'='Amount'}}}
 $flatTemplate=Invoke-CurrentExplain -Bytes $flatBytes -Operation 'bindings-template'
 $flatArtifacts=Invoke-CurrentExplain -Bytes $flatBytes -Bindings ([string]$flatTemplate.Rows[0].Content) -Catalog ($catalog|ConvertTo-Json -Depth 12 -Compress)
 $flatBundle=@($flatArtifacts.Rows|Where-Object {$_.ArtifactKind -ceq 'DebugScript' -and $_.ComponentId -ceq 'Package\Flow\FlatTarget'})
 Assert-Current ($flatBundle.Count -eq 1) 'FLATFILE_DEBUGSCRIPT_DISCOVERABLE'
 $result=Invoke-CurrentDebugScript $flatArtifacts $flatBundle[0]
 Assert-Current ($result.TargetSql.Rows.Count -eq 2 -and @($result.TargetSql.Select('KeyA=11 AND Amount=110')).Count -eq 1 -and @($result.TargetSql.Select('KeyA=22 AND Amount=220')).Count -eq 1) 'FLATFILE_DEBUGSCRIPT_FIXED_ORACLE'
 $blocked=@($flatArtifacts.Rows|Where-Object {$_.ArtifactKind -ceq 'DebugScript' -and -not $_.IsComplete})
 Assert-Current ($blocked.Count -gt 0 -and @($blocked|Where-Object IsExecutable).Count -eq 0) 'BLOCKED_PATH_NOT_EXECUTABLE'
 foreach($row in $blocked){$why=([string]$row.DetailsJson)|ConvertFrom-Json -Depth 32;Assert-Current ($why.path.Count -gt 0 -and $why.rootCause.code) 'BLOCKED_PATH_ROOT_CAUSE'}
}finally{[void](Invoke-CurrentSql 'DROP TABLE dbo.SyntheticSourceA,dbo.SyntheticSourceB,dbo.SyntheticLookup,dbo.SyntheticFlatFileRows;')}
"SSIS_CURRENT_NATIVE_PASS $checks assertions; current defaults, typed limits, editable values and executed DebugScript; synthetic inputs only"
