[CmdletBinding()]
param([Parameter(Mandatory)][Data.SqlClient.SqlConnection]$Connection,[string]$CrossDatabase,[string]$FixtureModuleRoot,[switch]$ExtendedExpressions,[switch]$FocusedVariablePlans)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if($Connection.State -ne 'Open'){throw 'SSIS_V2_CASE_CONNECTION_NOT_OPEN'}
$moduleRoot=if($FixtureModuleRoot){[IO.Path]::GetFullPath($FixtureModuleRoot)}else{Split-Path -Parent (Split-Path -Parent $PSScriptRoot)}
$script:v2Checks=0
function Assert-V2([bool]$Value,[string]$Name){
    if(-not $Value){throw ('SSIS_V2_ASSERT_'+$Name)}
    $script:v2Checks++
}
function New-ComponentsV2Command(
    [byte[]]$Bytes,[string]$Operation='bindings-template-v2',
    [string]$Context='{"schemaVersion":2}',[string]$Bindings,[string]$Catalog,
    [string]$Target,[string]$Stage,[string]$ResultTable,[bool]$Keep=$false,
    [bool]$Help=$false,[string]$Collation,[int16]$TSqlVersion=150,[ValidateRange(40,180)][int]$AnalysisTimeoutMaximum=40
){
    $command=$Connection.CreateCommand();$command.CommandType='StoredProcedure'
    $command.CommandText='toolbelt_tsql.USP_ExplainSsisDataFlow'
    $command.CommandTimeout=Get-SsisNativeTimeout $AnalysisTimeoutMaximum
    [void]$command.Parameters.Add('@PackageBytes',[Data.SqlDbType]::VarBinary,-1)
    if($null -eq $Bytes){$command.Parameters['@PackageBytes'].Value=[DBNull]::Value}
    else{$command.Parameters['@PackageBytes'].Value=$Bytes}
    [void]$command.Parameters.Add('@Operation',[Data.SqlDbType]::VarChar,32)
    $command.Parameters['@Operation'].Value=$Operation
    foreach($p in @(@('ProjectContext',$Context,-1),@('Bindings',$Bindings,-1),@('CatalogBindings',$Catalog,-1),@('TargetFlow',$Target,64),@('InspectStage',$Stage,64),@('ResultTable',$ResultTable,128),@('ComparisonCollation',$Collation,128))){
        [void]$command.Parameters.Add('@'+$p[0],[Data.SqlDbType]::NVarChar,[int]$p[2])
        $command.Parameters['@'+$p[0]].Value=if([string]::IsNullOrEmpty($p[1])){[DBNull]::Value}else{$p[1]}
    }
    [void]$command.Parameters.Add('@LookupPolicies',[Data.SqlDbType]::NVarChar,-1)
    $command.Parameters['@LookupPolicies'].Value=[DBNull]::Value
    foreach($p in @(@('KeepData',$Keep),@('Hilfe',$Help))){
        [void]$command.Parameters.Add('@'+$p[0],[Data.SqlDbType]::Bit)
        $command.Parameters['@'+$p[0]].Value=[bool]$p[1]
    }
    [void]$command.Parameters.Add('@Debug',[Data.SqlDbType]::TinyInt)
    $command.Parameters['@Debug'].Value=[byte]0
    [void]$command.Parameters.Add('@TSqlVersion',[Data.SqlDbType]::SmallInt)
    $command.Parameters['@TSqlVersion'].Value=$TSqlVersion
    return $command
}
function Invoke-V2Explain{
    param([byte[]]$Bytes,[string]$Operation='bindings-template-v2',[string]$Context='{"schemaVersion":2}',[string]$Bindings,[string]$Catalog,[string]$Target,[string]$Stage,[string]$ResultTable,[bool]$Keep=$false,[bool]$Help=$false,[string]$Collation,[int16]$TSqlVersion=$script:v2TSqlVersion)
    $forward=@{};foreach($name in $PSBoundParameters.Keys){$forward[$name]=$PSBoundParameters[$name]}
    $forward.TSqlVersion=$TSqlVersion
    $forward.AnalysisTimeoutMaximum=if($FocusedVariablePlans -and $Context -ceq '{"schemaVersion":2,"resourceOptions":{"schemaVersion":1,"preset":"unlimited"}}'){180}else{40}
    $command=New-ComponentsV2Command @forward
    try{
        $reader=$command.ExecuteReader()
        try{
            $table=[Data.DataTable]::new()
            if($reader.FieldCount -gt 0){$table.Load($reader)}
            if(-not $reader.IsClosed -and $reader.FieldCount -gt 0){throw 'SSIS_V2_EXTRA_RESULTSET'}
            return ,$table
        }finally{$reader.Dispose()}
    }finally{$command.Dispose()}
}
function Invoke-V2Sql([string]$Sql){
    $command=$Connection.CreateCommand();$command.CommandText=$Sql
    $command.CommandTimeout=Get-SsisNativeTimeout 40
    try{
        $table=[Data.DataTable]::new();$reader=$command.ExecuteReader()
        try{if($reader.FieldCount -gt 0){$table.Load($reader)}}finally{$reader.Dispose()}
        return ,$table
    }finally{$command.Dispose()}
}
function Reject-V2([scriptblock]$Action,[string]$Code,[string]$Counter,[switch]$ReturnMessage){
    $rejected=$false
    $diagnostic=$null
    try{& $Action | Out-Null}catch{
        $leaf=$_.Exception;while($leaf.InnerException){$leaf=$leaf.InnerException}
        if($leaf -isnot [Data.SqlClient.SqlException] -or $leaf.Number -ne 50000 -or
           $leaf.Message -notmatch ('TBX_SSISDBG_'+[regex]::Escape($Code)) -or
           ($Counter -and $leaf.Message -notmatch ('counter='+[regex]::Escape($Counter)+';'))){throw 'SSIS_V2_WRONG_REJECTION'}
        $rejected=$true
        $diagnostic=$leaf.Message
    }
    Assert-V2 $rejected ('REJECT_'+$Code)
    if($ReturnMessage){return $diagnostic}
}
$script:v2TSqlVersion=[int16](Invoke-V2Sql 'SELECT compatibility_level AS C FROM sys.databases WITH(NOLOCK) WHERE database_id=DB_ID();').Rows[0].C
Assert-V2 ($script:v2TSqlVersion -in @(150,160,170)) 'REQUESTED_TSQL_DIALECT_FROM_OWN_DATABASE'
$bytes=[IO.File]::ReadAllBytes((Join-Path $moduleRoot 'Tests/Fixtures/synthetic-8.dtsx'))
if(-not $FocusedVariablePlans){
$template=Invoke-V2Explain -Bytes $bytes
Assert-V2 ($template.Rows.Count -eq 1 -and $template.Rows[0].ArtifactKind -ceq 'BindingsTemplate') 'TEMPLATE_SINGLE_ROW'
$binding=([string]$template.Rows[0].Content)|ConvertFrom-Json -Depth 32
Assert-V2 ($binding.schemaVersion -eq 2 -and $binding.profile -ceq 'ssis-debug-components-v2') 'EXPLICIT_V2_PROFILE'
$exact='{"schemaVersion":2,"resourceOptions":{"schemaVersion":1,"limits":{"packageBytes":'+$bytes.Length+'}}}'
[void](Invoke-V2Explain -Bytes $bytes -Context $exact)
Assert-V2 $true 'EXACT_PACKAGE_BOUNDARY'
$below='{"schemaVersion":2,"resourceOptions":{"schemaVersion":1,"limits":{"packageBytes":'+($bytes.Length-1)+'}}}'
Reject-V2 {Invoke-V2Explain -Bytes $bytes -Context $below} 'resource_limit' 'packageBytes'
$xmlDiagnostic=Reject-V2 {Invoke-V2Explain -Bytes $bytes -Context '{"schemaVersion":2,"resourceOptions":{"schemaVersion":1,"limits":{"xmlCharacters":32}}}'} 'resource_limit' 'xmlCharacters' -ReturnMessage
Assert-V2 ($xmlDiagnostic -match 'actualAtLeast=33;') 'XML_CHARACTER_BOUND_IS_EXPLICIT_LOWER_BOUND'
$unlimited=Invoke-V2Explain -Bytes $bytes -Context '{"schemaVersion":2,"resourceOptions":{"schemaVersion":1,"preset":"unlimited"}}'
$policy=([string]$unlimited.Rows[0].Content)|ConvertFrom-Json -Depth 32
Assert-V2 ($policy.resourcePolicy.unlimited -eq $true) 'UNLIMITED_PROVENANCE'
[void](Invoke-V2Explain -Bytes $bytes -Context '{"schemaVersion":2,"resourceOptions":{"schemaVersion":1,"limits":{"jsonDocumentBytes":8}}}')
Assert-V2 $true 'CONTROL_ENVELOPE_SEPARATE_FROM_DATA_JSON'
foreach($bad in @('0','-1','1.5','null','9223372036854775808','"Infinity"')){
    $badContext='{"schemaVersion":2,"resourceOptions":{"schemaVersion":1,"limits":{"packageBytes":'+$bad+'}}}'
    Reject-V2 {Invoke-V2Explain -Bytes $bytes -Context $badContext} 'invalid_template'
}
Reject-V2 {Invoke-V2Explain -Bytes $bytes -Context '{"schemaVersion":2,"resourceOptions":{"schemaVersion":1,"preset":"unlimited","preset":"large10x"}}'} 'invalid_template'
$help=Invoke-V2Explain -Bytes ([byte[]]@(0)) -Context '{invalid' -Help $true
Assert-V2 ($help.Columns.Count -eq 12 -and $help.Rows.Count -gt 0) 'HELP_FIRST'
[void](Invoke-V2Sql 'CREATE TABLE #SsisV2Preserve(Marker int NOT NULL); INSERT #SsisV2Preserve VALUES(73);')
try{
    Reject-V2 {Invoke-V2Explain -Bytes $bytes -Context $below -ResultTable '#SsisV2Preserve'} 'resource_limit' 'packageBytes'
    $preserved=Invoke-V2Sql 'SELECT Marker FROM #SsisV2Preserve;'
    Assert-V2 ($preserved.Rows.Count -eq 1 -and $preserved.Rows[0].Marker -eq 73) 'RESOURCE_FAILURE_PRESERVES_RESULTTABLE'
}finally{[void](Invoke-V2Sql 'DROP TABLE #SsisV2Preserve;')}
"SSIS_V2_NATIVE_RESOURCE_PASS $script:v2Checks assertions; bounded synthetic inputs"
}
. (Join-Path $PSScriptRoot 'Invoke-ComponentsV2DomainCases.ps1')
