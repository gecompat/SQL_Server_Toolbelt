# Nur Fixture-/Recoverymechanik; wird vor jeder nativen Wirkung quellgebunden.
function Import-RecoveryDefinitions {
 $path=Join-Path $repoRoot 'Modules/toolbelt.tsql.ssis-debug/Tests/Runtime/Invoke-LabContract.ps1'
 $ast=[Management.Automation.Language.Parser]::ParseFile($path,[ref]$null,[ref]$null)
 foreach($name in @('Expand','Batches')){
  $f=@($ast.FindAll({param($n)$n-is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name-ceq $name},$true))
  if($f.Count-ne 1){throw 'SSIS_RECOVERY_CANONICAL_DEFINITION'}
  # Die vollständige Definition erhält insbesondere die Parameterliste.
  # Nur der Funktionsscope wird auf den aufrufenden Testscript-Scope gebunden.
  $anchor='function '+$name+'('
  if(($f[0].Extent.Text.Split($anchor).Count-1)-ne 1){throw 'SSIS_RECOVERY_CANONICAL_DEFINITION_ANCHOR'}
  $definition=$f[0].Extent.Text.Replace($anchor,('function script:'+$name+'('))
  . ([scriptblock]::Create($definition))
 }
}
function Get-RecoveryTrust($Connection){
 $r=Query-Client $Connection 'SELECT CONVERT(varchar(128),hash,2) AS H,description,CONVERT(varchar(33),create_date,126) AS C,created_by FROM sys.trusted_assemblies ORDER BY hash;'
 $rows=@($r.Rows|ForEach-Object {[ordered]@{hash=[string]$_.H;description=[string]$_.description;created=[string]$_.C;actor=[string]$_.created_by}})
 return ,$rows
}
function Get-RecoveryConsumers($Connection,[string]$Hash=''){
 $dbs=Query-Client $Connection 'SELECT name,state_desc,HAS_DBACCESS(name) AS A FROM sys.databases ORDER BY name;'
 $rows=@()
 foreach($db in $dbs.Rows){
  if($db.state_desc-cne 'ONLINE' -or $db.A-ne 1){throw 'SSIS_RECOVERY_CONSUMERS_NOT_OBSERVABLE'}
  $name=([string]$db.name).Replace(']',']]')
  $data=Query-Client $Connection ('SELECT a.name,CONVERT(varchar(128),HASHBYTES(''SHA2_512'',f.content),2) AS H FROM ['+$name+'].sys.assemblies a JOIN ['+$name+'].sys.assembly_files f ON f.assembly_id=a.assembly_id AND f.file_id=1 WHERE a.is_user_defined=1 ORDER BY a.name;')
  foreach($row in $data.Rows){if(-not $Hash -or $row.H-ceq $Hash){$rows += [ordered]@{database=[string]$db.name;assembly=[string]$row.name;hash=[string]$row.H}}}
 }
 return ,$rows
}
function Assert-RecoveryArtifacts($Plan){
 $prefix='Modules/toolbelt.tsql.ssis-debug/'
 $recordPath=Join-Path $repoRoot ($prefix+'Tests/Qualification/Current.Functional.20261031.json')
 if((Get-ClientHash $recordPath)-cne 'BB3BB417B4E571CE2D201A10988FA4015080586EE19E8C85CB87FA259E61E8B5'){throw 'SSIS_RECOVERY_APPROVAL_RECORD'}
 $record=Get-Content $recordPath -Raw|ConvertFrom-Json -DateKind String
 $ssisDll=Join-Path $Plan.ssis 'Toolbelt.Tsql.SsisDebug.dll'
 if((Get-ClientHash $ssisDll).ToLowerInvariant()-cne $record.current_delivery.assembly_sha256 -or
    (Get-ClientHash (Join-Path $Plan.ssis 'Deploy.WithAssembly.sql'))-cne $record.current_delivery.deployment_sha256){throw 'SSIS_RECOVERY_APPROVED_CURRENT_BINARY'}
 $pins=Get-Content (Join-Path $repoRoot ($prefix+'Contracts/DependencyPins.json')) -Raw|ConvertFrom-Json
 $archivePath=Join-Path $repoRoot ($prefix+'InstallPackages/SSIS-Debug-Current-Install-Windows.zip')
 if((Get-ClientHash $archivePath)-cne '6E83F4B534339E106B42C8911178BD09CB82001167A356D5A5D63BF69A15F4D7'){throw 'SSIS_RECOVERY_PARSER_ORIGIN'}
 $zip=[IO.Compression.ZipFile]::OpenRead($archivePath)
 try{
  foreach($file in @('Toolbelt.Tsql.ScriptParser.dll','Microsoft.SqlServer.TransactSql.ScriptDom.dll','Deploy.WithAssembly.sql','Toolbelt.Tsql.ScriptParser.trust-manifest.json')){
   $e=$zip.GetEntry('SSIS-Debug-Current-Install-Windows/Modules/toolbelt.tsql.script-parser/Artifacts/'+$file)
   $stream=$e.Open();try{$memory=[IO.MemoryStream]::new();$stream.CopyTo($memory);$bytes=$memory.ToArray();$memory.Dispose()}finally{$stream.Dispose()}
   if([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes))-cne (Get-ClientHash (Join-Path $Plan.parser $file))){throw 'SSIS_RECOVERY_PARSER_ARTIFACT_CHANGED'}
  }
 }finally{$zip.Dispose()}
 if((Get-FileHash (Join-Path $Plan.parser 'Toolbelt.Tsql.ScriptParser.dll') -Algorithm SHA512).Hash-cne $pins.parserSha512 -or
    (Get-FileHash (Join-Path $Plan.parser 'Microsoft.SqlServer.TransactSql.ScriptDom.dll') -Algorithm SHA512).Hash-cne $pins.scriptDomSha512){throw 'SSIS_RECOVERY_DEPENDENCY_PIN'}
 foreach($path in @('Modules/toolbelt.core.result-table/Deployment/Deploy.sql','Modules/toolbelt.core.result-table/Source/SchemaTrustPreflight.sql','Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql')){
  if((Get-ClientHash (Join-Path $repoRoot $path)).ToLowerInvariant()-cne ([string]$record.source_sha256.$path).ToLowerInvariant()){throw 'SSIS_RECOVERY_CORE_SOURCE_CHANGED'}
 }
}
function Invoke-RecoveryExplain($Connection,[byte[]]$Bytes,[string]$Operation,[string]$Bindings,[string]$Catalog){
 $cmd=$Connection.CreateCommand();$cmd.CommandTimeout=45;$cmd.CommandType='StoredProcedure';$cmd.CommandText='toolbelt_tsql.USP_ExplainSsisDataFlow'
 [void]$cmd.Parameters.Add('@PackageBytes',[Data.SqlDbType]::VarBinary,-1);$cmd.Parameters['@PackageBytes'].Value=$Bytes
 [void]$cmd.Parameters.Add('@Operation',[Data.SqlDbType]::NVarChar,32);$cmd.Parameters['@Operation'].Value=$Operation
 foreach($p in @(@('@Bindings',$Bindings),@('@CatalogBindings',$Catalog))){
  [void]$cmd.Parameters.Add($p[0],[Data.SqlDbType]::NVarChar,-1)
  # PowerShell bindet null an einen typisierten string als Leerstring.
  # Ausgelassene optionale JSON-Eingaben bleiben auch dann echtes SQL-NULL.
  $cmd.Parameters[$p[0]].Value=if([string]::IsNullOrEmpty([string]$p[1])){[DBNull]::Value}else{$p[1]}
 }
 [void]$cmd.Parameters.Add('@TSqlVersion',[Data.SqlDbType]::SmallInt);$cmd.Parameters['@TSqlVersion'].Value=150
 try{$dt=[Data.DataTable]::new();$r=$cmd.ExecuteReader();try{$dt.Load($r)}finally{$r.Dispose()};return ,$dt}finally{$cmd.Dispose()}
}
function Get-RecoveryPackage {
 $doc=[xml][IO.File]::ReadAllText((Join-Path $repoRoot 'Modules/toolbelt.tsql.ssis-debug/Tests/Fixtures/synthetic-8.dtsx'))
 foreach($component in $doc.SelectNodes('//*[local-name()="component"]')){
  if($component.GetAttribute('componentClassID')-in @('Microsoft.DerivedColumn','Microsoft.ConditionalSplit')){
   $input=$component.SelectSingleNode('inputs/input').GetAttribute('refId')
   foreach($port in $component.SelectNodes('outputs/output')){$port.SetAttribute('synchronousInputId',$input)}
  }
 }
 return ,[Text.Encoding]::UTF8.GetBytes($doc.OuterXml)
}
function Invoke-RecoveryDebug($Connection,[string]$Sql){
 $targets=@()
 foreach($batch in [regex]::Split($Sql,'(?im)^\s*GO\s*(?:--[^\r\n]*)?\r?$')){
  if(-not $batch.Trim()){continue}
  $cmd=$Connection.CreateCommand();$cmd.CommandText=$batch;$cmd.CommandTimeout=45
  $adapter=[Data.SqlClient.SqlDataAdapter]::new($cmd);$set=[Data.DataSet]::new()
  try{
   [void]$adapter.Fill($set)
   foreach($table in $set.Tables){
    if($table.Columns.Contains('KeyA')-and $table.Columns.Contains('KeyB')-and $table.Columns.Contains('Adjusted')){
     $targets+=@{count=$table.Rows.Count;rows=@($table.Rows|Sort-Object KeyA,KeyB,Adjusted|ForEach-Object {@([int]$_.KeyA,[int]$_.KeyB,[int]$_.Adjusted)})}
    }
   }
  }finally{$adapter.Dispose();$cmd.Dispose();$set.Dispose()}
 }
 return ,$targets
}
