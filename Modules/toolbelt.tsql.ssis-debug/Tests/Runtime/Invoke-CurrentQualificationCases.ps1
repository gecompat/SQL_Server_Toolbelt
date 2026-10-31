[CmdletBinding()]
param(
 [Parameter(Mandatory)][Data.SqlClient.SqlConnection]$Connection,
 [string]$CrossDatabase,
 [switch]$LongPlan
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$moduleRoot=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$script:v2Checks=0
$script:v2TSqlVersion=[int16](Query $Connection 'SELECT compatibility_level AS C FROM sys.databases WHERE database_id=DB_ID();').Rows[0].C
$FocusedVariablePlans=$false
$ExtendedExpressions=[bool]$LongPlan

function Assert-V2([bool]$Value,[string]$Name){
 if(-not $Value){throw ('SSIS_CURRENT_QUALIFICATION_'+$Name)}
 $script:v2Checks++
}
function Invoke-V2Sql([string]$Sql){return ,(Query $Connection $Sql)}
function Invoke-V2Explain {
 param([byte[]]$Bytes,[string]$Operation='bindings-template',[string]$Context='{"schemaVersion":2}',
 [string]$Bindings,[string]$Catalog,[string]$Target,[string]$Stage,[string]$ResultTable,
 [bool]$Keep=$false,[bool]$Help=$false,[string]$Collation,[int16]$TSqlVersion=$script:v2TSqlVersion,
 [hashtable]$Limits=@{},[byte]$Debug=0,[string]$Procedure='toolbelt_tsql.USP_ExplainSsisDataFlow')
 # Diese Fachorakel benötigen ausdrücklich die synthetischen Entwurfswerte.
 # Auch ohne übergebene Testvorlage wird diese zuerst über die aktuelle API
 # erzeugt und vollständig zurückgegeben; Produktdefaults werden nicht geraten.
 if($Operation -ceq 'explain' -and [string]::IsNullOrEmpty($Bindings)){
  $design=Invoke-V2Explain -Bytes $Bytes -Operation 'bindings-template' -Context $Context -TSqlVersion $TSqlVersion -Limits $Limits -Procedure $Procedure
  $Bindings=[string]$design.Rows[0].Content
 }
 $command=$Connection.CreateCommand();$command.CommandType='StoredProcedure'
 $command.CommandText=$Procedure
 $command.CommandTimeout=Get-SsisNativeTimeout 120
 [void]$command.Parameters.Add('@PackageBytes',[Data.SqlDbType]::VarBinary,-1)
 if($null -eq $Bytes){$command.Parameters['@PackageBytes'].Value=[DBNull]::Value}
 else{$command.Parameters['@PackageBytes'].Value=$Bytes}
 foreach($p in @(@('Operation',$Operation,32,[Data.SqlDbType]::VarChar),@('ProjectContext',$Context,-1,[Data.SqlDbType]::NVarChar),
 @('Bindings',$Bindings,-1,[Data.SqlDbType]::NVarChar),@('CatalogBindings',$Catalog,-1,[Data.SqlDbType]::NVarChar),
 @('TargetFlow',$Target,64,[Data.SqlDbType]::NVarChar),@('InspectStage',$Stage,64,[Data.SqlDbType]::NVarChar),
 @('ResultTable',$ResultTable,128,[Data.SqlDbType]::NVarChar),@('ComparisonCollation',$Collation,128,[Data.SqlDbType]::NVarChar))){
  [void]$command.Parameters.Add('@'+$p[0],$p[3],[int]$p[2])
  $command.Parameters['@'+$p[0]].Value=if([string]::IsNullOrEmpty([string]$p[1])){[DBNull]::Value}else{$p[1]}
 }
 foreach($p in @(@('KeepData',$Keep),@('Hilfe',$Help))){[void]$command.Parameters.Add('@'+$p[0],[Data.SqlDbType]::Bit);$command.Parameters['@'+$p[0]].Value=[bool]$p[1]}
 [void]$command.Parameters.Add('@Debug',[Data.SqlDbType]::TinyInt);$command.Parameters['@Debug'].Value=$Debug
 [void]$command.Parameters.Add('@TSqlVersion',[Data.SqlDbType]::SmallInt);$command.Parameters['@TSqlVersion'].Value=$TSqlVersion
 foreach($name in $Limits.Keys){
  if($name -cnotmatch '^@Max[A-Za-z]+$'){throw 'SSIS_CURRENT_QUALIFICATION_LIMIT_NAME'}
  [void]$command.Parameters.Add($name,[Data.SqlDbType]::BigInt);$command.Parameters[$name].Value=[long]$Limits[$name]
 }
 try{
  $reader=$command.ExecuteReader()
  try{
   $tables=[Collections.Generic.List[Data.DataTable]]::new()
   do{if($reader.FieldCount -gt 0){$table=[Data.DataTable]::new();for($i=0;$i -lt $reader.FieldCount;$i++){[void]$table.Columns.Add($reader.GetName($i),$reader.GetFieldType($i))};while($reader.Read()){$values=[object[]]::new($reader.FieldCount);[void]$reader.GetValues($values);[void]$table.Rows.Add($values)};$tables.Add($table)}}while($reader.NextResult())
   Assert-V2 ($tables.Count -eq $(if($ResultTable -and -not $Help){0}else{1})) 'EXACT_RESULTSET_COUNT'
   if($tables.Count){return ,$tables[0]};return ,([Data.DataTable]::new())
  }finally{$reader.Dispose()}
 }finally{$command.Dispose()}
}
function Reject-V2([scriptblock]$Action,[string]$Code,[string]$Counter,[switch]$ReturnMessage){
 $rejected=$false;$diagnostic=$null
 try{& $Action|Out-Null}catch{
  $leaf=$_.Exception;while($leaf.InnerException){$leaf=$leaf.InnerException}
  if($leaf -isnot [Data.SqlClient.SqlException] -or $leaf.Number -ne 50000 -or $leaf.Message -notmatch ('TBX_SSISDBG_'+[regex]::Escape($Code)) -or ($Counter -and $leaf.Message -notmatch ('counter='+[regex]::Escape($Counter)+';'))){throw 'SSIS_CURRENT_QUALIFICATION_WRONG_REJECTION'}
  $rejected=$true;$diagnostic=$leaf.Message
 }
 Assert-V2 $rejected ('REJECT_'+$Code)
 if($ReturnMessage){return $diagnostic}
}

# Die unveränderten typisierten Fachorakel werden am heutigen öffentlichen
# Default ausgeführt. Nur die Eingabe des langen synthetischen Plans wird
# auf 32 Gruppen und das tatsächliche Defaultbudget angepasst; kein Legacy-
# Operationsname oder Ressourcen-JSON gelangt an den Produktaufruf.
$domain=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'Invoke-ComponentsV2DomainCases.ps1'))
$variable=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'Invoke-ComponentsV2VariableCases.ps1'))
if(($variable.Split('@($group)*256').Count-1) -ne 1 -or ($variable.Split('{"schemaVersion":2,"resourceOptions":{"schemaVersion":1,"preset":"unlimited"}}').Count-1) -ne 1){throw 'SSIS_CURRENT_QUALIFICATION_VARIABLE_ANCHOR'}
$variable=$variable.Replace('@($group)*256','@($group)*32').Replace('{"schemaVersion":2,"resourceOptions":{"schemaVersion":1,"preset":"unlimited"}}','{"schemaVersion":2}')
$hook=". (Join-Path `$PSScriptRoot 'Invoke-ComponentsV2VariableCases.ps1')"
if(($domain.Split($hook).Count-1) -ne 1){throw 'SSIS_CURRENT_QUALIFICATION_DOMAIN_ANCHOR'}
$domain=$domain.Replace($hook,'. ([scriptblock]::Create($variable))')
function Test-CurrentMissingContext($Artifacts,[string]$Component){
 # Der aktuelle Vertrag transportiert die Erstursache an der blockierten
 # Stufe; eine nachgelagerte Diagnostic darf einen Kaskadencode tragen.
 $found=$false
 foreach($row in @($Artifacts.Rows|Where-Object {$_.ArtifactKind -ceq 'StageIndex' -and $_.ComponentId -ceq $Component -and -not $_.IsComplete})){
  $details=([string]$row.DetailsJson)|ConvertFrom-Json -Depth 32
  if($details.rootCause.code -ceq 'missing_context' -and $details.rootCause.componentId -ceq $Component -and $details.rootCause.stageId -ceq $row.StageId){$found=$true}
 }
 return $found
}
$domain=$domain.Replace('(@($invalidCount.Select("ArtifactKind=''Diagnostic'' AND DiagnosticCode=''missing_context''")).Count -gt 0)', '(Test-CurrentMissingContext $invalidCount ''Package\Flow\RowCount'')')
$domain=$domain.Replace('(@($flat.Select("ArtifactKind=''Diagnostic'' AND DiagnosticCode=''missing_context''")).Count -gt 0)', '(Test-CurrentMissingContext $flat ''Package\Flow\FlatSource'')')
$domain=$domain.Replace('$PSScriptRoot',("'"+$PSScriptRoot.Replace("'","''")+"'"))
. ([scriptblock]::Create($domain))

. (Join-Path $PSScriptRoot 'Invoke-CurrentQualificationSafetyCases.ps1')
. (Join-Path $PSScriptRoot 'Invoke-CurrentQualificationBoundaryCases.ps1')
"SSIS_CURRENT_QUALIFICATION_SEMANTICS_PASS $script:v2Checks assertions; current API and default budgets"
