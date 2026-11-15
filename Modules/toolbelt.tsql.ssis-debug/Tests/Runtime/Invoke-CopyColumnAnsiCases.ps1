[CmdletBinding()]
param([Parameter(Mandatory)][Data.SqlClient.SqlConnection]$Connection,
      [Parameter(Mandatory)][string]$FixtureRoot)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if($Connection.State -cne 'Open'){throw 'SSIS_COPY_OPEN_CONNECTION_REQUIRED'}
# Nur die vorhandenen Client-/Bundlefunktionen übernehmen; deren vollständige
# historische Suite wird hier weder ausgeführt noch als aktuell behauptet.
$errors=$null
$tree=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'Invoke-CurrentCases.ps1'),[ref]$null,[ref]$errors)
if($errors.Count){throw 'SSIS_COPY_SHARED_HELPER_SYNTAX'}
foreach($name in @('Assert-Current','Invoke-CurrentSql','Invoke-CurrentExplain','Invoke-CurrentDebugScript')){
 $nodes=@($tree.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq $name},$true))
 if($nodes.Count -ne 1){throw 'SSIS_COPY_SHARED_HELPER_SCOPE'}
 . ([scriptblock]::Create($nodes[0].Extent.Text))
}
$script:checks=0
$profiles=0
$script:currentDialect=[int16](Invoke-CurrentSql 'SELECT compatibility_level AS C FROM sys.databases WHERE database_id=DB_ID();').Rows[0].C
$database=[string](Invoke-CurrentSql 'SELECT DB_NAME() AS N;').Rows[0].N
$catalog=@{schemaVersion=2;defaultDatabase=$database;databases=@($database);connections=@{'Package.ConnectionManagers[Synthetic]'=$database};flatFileInputs=@{}}|ConvertTo-Json -Depth 8 -Compress
foreach($format in @(6,8)){
 foreach($type in @('ansi-1252','ansi-65001')){
  $collation=if($type -ceq 'ansi-1252'){'Latin1_General_100_BIN2'}else{'Latin1_General_100_CI_AS_SC_UTF8'}
  $setup="CREATE TABLE dbo.SyntheticSourceA(KeyA varchar(10) COLLATE $collation NULL,KeyB int NOT NULL,Amount int NULL);INSERT dbo.SyntheticSourceA VALUES(N'é',10,100),(NULL,20,NULL),(N'',40,-2147483648);"
  $expected=@('é|é|100|100','NULL|NULL|NULL|NULL','||-2147483648|-2147483648')
  [void](Invoke-CurrentSql $setup)
  try{
   $witness="SELECT KeyA,KeyB,Amount FROM dbo.SyntheticSourceA ORDER BY KeyB FOR JSON PATH,INCLUDE_NULL_VALUES;"
   $before=[string](Invoke-CurrentSql $witness).Rows[0][0]
   $bytes=[IO.File]::ReadAllBytes((Join-Path $FixtureRoot "format-$format/copy-column-$type/package.dtsx"))
   $template=[string](Invoke-CurrentExplain -Bytes $bytes -Operation 'bindings-template').Rows[0].Content
   $artifacts=Invoke-CurrentExplain -Bytes $bytes -Bindings $template -Catalog $catalog
   $bundle=@($artifacts.Rows|Where-Object ArtifactKind -CEQ 'DebugScript')
   Assert-Current ($bundle.Count -eq 1) 'COPY_SINGLE_BUNDLE'
   $results=Invoke-CurrentDebugScript $artifacts $bundle[0]
   $table=$results['TargetSql']
   Assert-Current ($table.Columns.Count -eq 4 -and $table.Rows.Count -eq $expected.Count) 'COPY_EXACT_SCHEMA_ROWS'
   Assert-Current ($table.Columns[0].DataType -eq [string] -and $table.Columns[2].DataType -eq [int]) 'COPY_EXACT_SQL_TYPES'
   $actual=@(foreach($row in $table.Rows){(@(foreach($value in $row.ItemArray){if($value -is [DBNull]){'NULL'}else{[Convert]::ToString($value,[Globalization.CultureInfo]::InvariantCulture)}}) -join '|')})
   Assert-Current ((($actual|Sort-Object -CaseSensitive) -join "`n") -ceq (($expected|Sort-Object -CaseSensitive) -join "`n")) 'COPY_FIXED_VALUE_NULL_UNICODE_ORACLE'
   Assert-Current ([string](Invoke-CurrentSql $witness).Rows[0][0] -ceq $before) 'COPY_SOURCE_UNCHANGED'
   $xml=[xml][Text.Encoding]::UTF8.GetString($bytes)
   $copy=@($xml.SelectNodes('//component')|Where-Object name -CEQ 'Copy')[0]
   foreach($column in @($copy.SelectNodes('.//*[@dataType="str"]'))){$column.SetAttribute('codePage','850');$column.SetAttribute('cachedCodePage','850')}
   $bad=[Text.Encoding]::UTF8.GetBytes($xml.OuterXml)
   $badTemplate=[string](Invoke-CurrentExplain -Bytes $bad -Operation 'bindings-template').Rows[0].Content
   $denied=Invoke-CurrentExplain -Bytes $bad -Bindings $badTemplate -Catalog $catalog
   Assert-Current (@($denied.Rows|Where-Object {$_.ArtifactKind -ceq 'Diagnostic' -and $_.DiagnosticCode -ceq 'unsupported_component'}).Count -gt 0 -and @($denied.Rows|Where-Object {$_.ArtifactKind -ceq 'TargetSql' -and $_.IsExecutable}).Count -eq 0) 'COPY_ANSI_JOINT_METADATA_REJECTED'
   $profiles++
  }finally{[void](Invoke-CurrentSql 'DROP TABLE dbo.SyntheticSourceA;')}
 }
}

Assert-Current ($profiles -eq 4) 'COPY_ANSI_EXACT_PROFILE_COUNT'
"SSIS_COPY_COLUMN_ANSI_NATIVE_PASS $script:checks assertions"
