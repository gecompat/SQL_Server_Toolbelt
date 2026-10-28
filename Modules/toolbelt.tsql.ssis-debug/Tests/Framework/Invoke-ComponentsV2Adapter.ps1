$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$cases=Join-Path $PSScriptRoot '../Runtime/Invoke-ComponentsV2Cases.ps1'
$errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile($cases,[ref]$null,[ref]$errors)
if($errors.Count){throw 'SSIS_V2_ADAPTER_CASE_SYNTAX'}
$definitions=@($ast.FindAll({param($node)$node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq 'New-ComponentsV2Command'},$true))
if($definitions.Count -ne 1){throw 'SSIS_V2_ADAPTER_COMMAND_AMBIGUOUS'}
. ([scriptblock]::Create($definitions[0].Extent.Text))
function Get-SsisNativeTimeout([int]$Maximum){[Math]::Min(40,$Maximum)}
$Connection=[Data.SqlClient.SqlConnection]::new('Initial Catalog=ContosoSsisDebug')
$checks=0
$driver=Join-Path $PSScriptRoot '../Runtime/Invoke-ComponentsV2Lab.ps1'
$driverAst=[Management.Automation.Language.Parser]::ParseFile($driver,[ref]$null,[ref]$null)
$binders=@($driverAst.FindAll({param($node)$node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq 'Bind-ComponentsV2ScriptRoot'},$true))
if($binders.Count -ne 1){throw 'SSIS_V2_ADAPTER_ROOT_BINDER_AMBIGUOUS'}
. ([scriptblock]::Create($binders[0].Extent.Text))
$rootText=Bind-ComponentsV2ScriptRoot -Text '$PSScriptRoot' -Root $PSScriptRoot
if((& ([scriptblock]::Create($rootText))) -cne $PSScriptRoot){throw 'SSIS_V2_ADAPTER_SCRIPT_ROOT_SCOPE'}
$checks++
$quoted="C:/Contoso/one'two"
$rootText=Bind-ComponentsV2ScriptRoot -Text '$PSScriptRoot' -Root $quoted
if((& ([scriptblock]::Create($rootText))) -cne $quoted){throw 'SSIS_V2_ADAPTER_ROOT_QUOTING'}
$checks++
try{
    foreach($bytes in @(([byte[]]@(0,128,255)),([byte[]]@(0)))){
        $command=New-ComponentsV2Command -Bytes $bytes -Context '{"schemaVersion":2}'
        try{
            if($command.Parameters.Count -ne 14){throw 'SSIS_V2_ADAPTER_PARAMETER_COUNT'};$checks++
            if($command.Parameters['@PackageBytes'].Value -isnot [byte[]] -or $command.Parameters['@PackageBytes'].SqlValue.Length -ne $bytes.Length){throw 'SSIS_V2_ADAPTER_BINARY_TYPE'};$checks++
            if($command.Parameters['@Operation'].SqlDbType -ne [Data.SqlDbType]::VarChar){throw 'SSIS_V2_ADAPTER_OPERATION_TYPE'};$checks++
            foreach($parameter in $command.Parameters){[void]$parameter.SqlValue}
            if($Connection.State -ne 'Closed'){throw 'SSIS_V2_ADAPTER_OPENED_CONNECTION'};$checks++
        }finally{$command.Dispose()}
    }
    $command=New-ComponentsV2Command -Help $true -Context '{invalid'
    try{
        if($command.Parameters['@PackageBytes'].Value -isnot [DBNull] -or -not $command.Parameters['@Hilfe'].Value){throw 'SSIS_V2_ADAPTER_HELP_NULL_BYTES'};$checks++
        if($command.Parameters['@CatalogBindings'].Value -isnot [DBNull]){throw 'SSIS_V2_ADAPTER_NULL_CATALOG'};$checks++
        foreach($parameter in $command.Parameters){[void]$parameter.SqlValue}
    }finally{$command.Dispose()}
}finally{$Connection.Dispose()}
function Assert-V2([bool]$Value,[string]$Name){if(-not $Value){throw ('SSIS_V2_ASSERT_'+$Name)}}
$domain=Join-Path $PSScriptRoot '../Runtime/Invoke-ComponentsV2DomainCases.ps1'
$domainAst=[Management.Automation.Language.Parser]::ParseFile($domain,[ref]$null,[ref]$null)
$partBuilders=@($domainAst.FindAll({param($node)$node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq 'Get-V2PlanParts'},$true))
if($partBuilders.Count -ne 1){throw 'SSIS_V2_ADAPTER_PLAN_BUILDER_AMBIGUOUS'}
. ([scriptblock]::Create($partBuilders[0].Extent.Text))
$artifacts=[Data.DataTable]::new()
foreach($name in @('ArtifactKind','Content','DetailsJson','StageId','SafetyStatus')){[void]$artifacts.Columns.Add($name,[string])}
[void]$artifacts.Columns.Add('IsExecutable',[bool])
$sql='SELECT 1;'
$hash=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($sql))).ToLowerInvariant()
$unit=$artifacts.NewRow();$unit.ArtifactKind='PlanUnitSql';$unit.Content=$sql;$unit.DetailsJson='{"planHash":"synthetic","ordinal":0,"unitContentSha256":"'+$hash+'"}';$unit.StageId='s1';$unit.SafetyStatus='passed';$unit.IsExecutable=$true;$artifacts.Rows.Add($unit)
$manifest=$artifacts.NewRow();$manifest.ArtifactKind='PlanManifest';$manifest.Content='{"planHash":"synthetic","units":[{"unitId":"s1"}]}';$artifacts.Rows.Add($manifest)
$cleanup=$artifacts.NewRow();$cleanup.ArtifactKind='CleanupSql';$cleanup.DetailsJson='{"planHash":"synthetic","cleanupOrdinal":0}';$artifacts.Rows.Add($cleanup)
$target=[pscustomobject]@{DetailsJson='{"planHash":"synthetic","unitCount":1}'}
$parts=Get-V2PlanParts $artifacts $target
if($parts.Units.Count -ne 1 -or $parts.Cleanups.Count -ne 1){throw 'SSIS_V2_ADAPTER_PLAN_TRANSPORT'};$checks++
$unit.Content='SELECT 2;';$rejected=$false
try{[void](Get-V2PlanParts $artifacts $target)}catch{if($_.Exception.Message -cne 'SSIS_V2_ASSERT_PLAN_TRANSPORT_ORDER_HASH'){throw};$rejected=$true}
if(-not $rejected){throw 'SSIS_V2_ADAPTER_TAMPERED_UNIT_ACCEPTED'};$checks++
"SSIS_V2_ADAPTER_PASS $checks bounded type/scope/transport checks; no SQL"
