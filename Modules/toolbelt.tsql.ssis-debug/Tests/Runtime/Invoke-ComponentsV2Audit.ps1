[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('2019','2022','2025')][string]$Version,
    [string]$Patch='base',
    [Parameter(Mandatory)][string]$ExpectedTargetKey,
    [Parameter(Mandatory)][ValidatePattern('^[0-9A-F]{64}$')][string]$ExpectedContractSha256,
    [Parameter(Mandatory)][string]$JournalPath,
    [Parameter(Mandatory)][ValidatePattern('^[0-9A-F]{64}$')][string]$ExpectedJournalSha256,
    [switch]$ValidateOnly
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if($PSVersionTable.PSVersion.Major -ne 7){throw 'SSIS_V2_AUDIT_POWERSHELL_7_REQUIRED'}
$moduleRoot=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$repoRoot=Split-Path -Parent (Split-Path -Parent $moduleRoot)
$runtime=[IO.Path]::GetFullPath((Join-Path $repoRoot '.runtime'))+[IO.Path]::DirectorySeparatorChar
$journalFile=[IO.Path]::GetFullPath($JournalPath)
if(-not $journalFile.StartsWith($runtime,[StringComparison]::OrdinalIgnoreCase)){
    throw 'SSIS_V2_AUDIT_PRIVATE_SCOPE'
}
$item=Get-Item -LiteralPath $journalFile -Force
if($item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or $item.Length -gt 1048576){throw 'SSIS_V2_AUDIT_JOURNAL_FILE'}
if((Get-FileHash -LiteralPath $journalFile -Algorithm SHA256).Hash -cne $ExpectedJournalSha256){throw 'SSIS_V2_AUDIT_JOURNAL_CHANGED'}
$journal=Get-Content -LiteralPath $journalFile -Raw | ConvertFrom-Json -DateKind String
if($journal.schemaVersion -ne 1 -or $journal.purpose -cne 'Functional' -or
   $journal.runId -cnotmatch '^[0-9a-f]{32}$' -or
   $journal.state -cnotin @('PASS_CLEANED','FAILED_CLEANED','RECOVERY_REQUIRED')){throw 'SSIS_V2_AUDIT_JOURNAL_STATE'}
$databasePattern='^ToolbeltSsis_'+$journal.runId.Substring(0,16)+'_(local|central)(_client)?$'
foreach($name in $journal.databases){if($name -cnotmatch $databasePattern){throw 'SSIS_V2_AUDIT_DATABASE_SCOPE'}}
foreach($hash in $journal.trust){if($hash -cnotmatch '^[0-9A-F]{128}$'){throw 'SSIS_V2_AUDIT_TRUST_SCOPE'}}
. (Join-Path $repoRoot 'Tests/CI/LabQualifiedContract.ps1')
$errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $repoRoot 'Tests/CI/run-lab-local.ps1'),[ref]$null,[ref]$errors)
if($errors.Count){throw 'SSIS_V2_AUDIT_DISCOVERY_SYNTAX'}
foreach($name in @('Get-EnvironmentVariableValue','Resolve-LabContract','Test-LabTargetReady','Get-LabTargetsForSelector','New-LabConnectionString')){
    $definitions=@($ast.FindAll({param($node)$node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq $name},$true))
    if($definitions.Count -ne 1){throw 'SSIS_V2_AUDIT_DISCOVERY_AMBIGUOUS'}
    . ([scriptblock]::Create($definitions[0].Extent.Text))
}
$lab=Resolve-LabContract
if((Get-FileHash -LiteralPath $lab.Path -Algorithm SHA256).Hash -cne $ExpectedContractSha256){throw 'SSIS_V2_AUDIT_CONTRACT_CHANGED'}
$targets=@(Get-LabTargetsForSelector -Contract $lab.Contract -Selector ([pscustomobject]@{Platform='windows';Version=$Version;Patch=$Patch}))
if($targets.Count -ne 1 -or [string]$targets[0].key -cne $ExpectedTargetKey){throw 'SSIS_V2_AUDIT_TARGET_CHANGED'}
if($ValidateOnly){'SSIS_V2_AUDIT_INPUTS_VALIDATED; no SQL';return}
$builder=[Data.SqlClient.SqlConnectionStringBuilder]::new((New-LabConnectionString -Entry $targets[0] -TestPurpose Functional))
if(-not $builder.Encrypt){throw 'SSIS_V2_AUDIT_ENCRYPT_REQUIRED'}
$builder['Initial Catalog']='master';$builder['Pooling']=$false
$connection=[Data.SqlClient.SqlConnection]::new($builder.ConnectionString)
$clock=[Diagnostics.Stopwatch]::StartNew()
function Read-Audit([string]$Sql,[hashtable]$Values=@{}){
    if($clock.Elapsed.TotalSeconds -ge 60){throw 'SSIS_V2_AUDIT_DEADLINE'}
    $command=$connection.CreateCommand();$command.CommandText=$Sql
    $command.CommandTimeout=[int][Math]::Max(1,[Math]::Min(15,[Math]::Floor(60-$clock.Elapsed.TotalSeconds)))
    try{
        foreach($key in $Values.Keys){
            $value=$Values[$key]
            if($value -is [byte[]]){[void]$command.Parameters.Add($key,[Data.SqlDbType]::VarBinary,64)}
            else{[void]$command.Parameters.Add($key,[Data.SqlDbType]::NVarChar,128)}
            $command.Parameters[$key].Value=$value
        }
        $table=[Data.DataTable]::new();$reader=$command.ExecuteReader()
        try{$table.Load($reader)}finally{$reader.Dispose()}
        return ,$table
    }finally{$command.Dispose()}
}
try{
    $connection.Open()
    $strict=Read-Audit "SELECT CONVERT(int,value) AS C,CONVERT(int,value_in_use) AS R FROM sys.configurations WITH(NOLOCK) WHERE name=N'clr strict security';"
    if($strict.Rows.Count -ne 1 -or $strict.Rows[0].C -ne 1 -or $strict.Rows[0].R -ne 1){throw 'SSIS_V2_AUDIT_STRICT_SECURITY_DRIFT'}
    foreach($name in $journal.databases){
        $result=Read-Audit 'SELECT COUNT_BIG(*) AS N FROM sys.databases WITH(NOLOCK) WHERE name=@name;' @{'@name'=[string]$name}
        if($result.Rows[0].N -ne 0){throw 'SSIS_V2_AUDIT_DATABASE_REMAINS'}
    }
    foreach($hash in $journal.trust){
        $result=Read-Audit 'SELECT COUNT_BIG(*) AS N FROM sys.trusted_assemblies WITH(NOLOCK) WHERE hash=@hash;' @{'@hash'=[Convert]::FromHexString($hash)}
        if($result.Rows[0].N -ne 0){throw 'SSIS_V2_AUDIT_OWN_TRUST_REMAINS'}
    }
    foreach($before in $journal.configurationBefore){
        $result=Read-Audit 'SELECT CONVERT(int,value) AS C,CONVERT(int,value_in_use) AS R FROM sys.configurations WITH(NOLOCK) WHERE name=@name;' @{'@name'=[string]$before.name}
        if($result.Rows.Count -ne 1 -or $result.Rows[0].C -ne $before.configured -or $result.Rows[0].R -ne $before.running){throw 'SSIS_V2_AUDIT_CONFIGURATION_DRIFT'}
    }
    'SSIS_V2_INDEPENDENT_CLEANUP_AUDIT_PASS Functional; authenticated TLS not executed'
}finally{$connection.Dispose()}
