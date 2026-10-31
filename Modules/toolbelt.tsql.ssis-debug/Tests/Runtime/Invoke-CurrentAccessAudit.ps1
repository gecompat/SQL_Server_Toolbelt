[CmdletBinding()]
param(
 [Parameter(Mandatory)][ValidateSet('2019','2022','2025')][string]$Version,
 [string]$Patch='base',
 [Parameter(Mandatory)][string]$ExpectedTargetKey,
 [Parameter(Mandatory)][ValidatePattern('^[0-9A-F]{64}$')][string]$ExpectedContractSha256,
 [Parameter(Mandatory)][string]$JournalPath,
 [Parameter(Mandatory)][ValidatePattern('^[0-9A-F]{64}$')][string]$ExpectedJournalSha256,
 [Parameter(Mandatory)][string]$IdentityJournalPath,
 [Parameter(Mandatory)][ValidatePattern('^[0-9A-F]{64}$')][string]$ExpectedIdentityJournalSha256
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repository=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../..'))
$identityPath=[IO.Path]::GetFullPath($IdentityJournalPath)
$runtime=[IO.Path]::GetFullPath((Join-Path $repository '.runtime'))+[IO.Path]::DirectorySeparatorChar
if(-not $identityPath.StartsWith($runtime,[StringComparison]::OrdinalIgnoreCase)){throw 'SSIS_ACCESS_AUDIT_PRIVATE_SCOPE'}
$item=Get-Item -LiteralPath $identityPath -Force
if($item.Length -gt 1048576 -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or (Get-FileHash -LiteralPath $identityPath).Hash -cne $ExpectedIdentityJournalSha256){throw 'SSIS_ACCESS_AUDIT_IDENTITY_JOURNAL_CHANGED'}
$identity=Get-Content -LiteralPath $identityPath -Raw|ConvertFrom-Json
$base=Get-Content -LiteralPath $JournalPath -Raw|ConvertFrom-Json
if($identity.schemaVersion -ne 1 -or $identity.profile -cne 'ssis-current-access' -or $identity.runId -cne $base.runId -or $identity.runId -cnotmatch '^[0-9a-f]{32}$' -or $identity.sid -cnotmatch '^[0-9A-F]{32}$' -or $identity.login -cne ('ToolbeltSsisAccess_'+$identity.runId.Substring(0,16))){throw 'SSIS_ACCESS_AUDIT_IDENTITY_SCOPE'}
& (Join-Path $PSScriptRoot 'Invoke-ComponentsV2Audit.ps1') -Version $Version -Patch $Patch -ExpectedTargetKey $ExpectedTargetKey -ExpectedContractSha256 $ExpectedContractSha256 -JournalPath $JournalPath -ExpectedJournalSha256 $ExpectedJournalSha256
. (Join-Path $repository 'Tests/CI/LabQualifiedContract.ps1')
$tree=[Management.Automation.Language.Parser]::ParseFile((Join-Path $repository 'Tests/CI/run-lab-local.ps1'),[ref]$null,[ref]$null)
foreach($name in @('Get-EnvironmentVariableValue','Resolve-LabContract','Test-LabTargetReady','Get-LabTargetsForSelector','New-LabConnectionString')){
 $definitions=@($tree.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq $name},$true))
 if($definitions.Count -ne 1){throw 'SSIS_ACCESS_AUDIT_DISCOVERY_AMBIGUOUS'}
 . ([scriptblock]::Create($definitions[0].Extent.Text))
}
$lab=Resolve-LabContract
if((Get-FileHash -LiteralPath $lab.Path).Hash -cne $ExpectedContractSha256){throw 'SSIS_ACCESS_AUDIT_CONTRACT_CHANGED'}
$targets=@(Get-LabTargetsForSelector -Contract $lab.Contract -Selector ([pscustomobject]@{Platform='windows';Version=$Version;Patch=$Patch}))
if($targets.Count -ne 1 -or $targets[0].key -cne $ExpectedTargetKey){throw 'SSIS_ACCESS_AUDIT_TARGET_CHANGED'}
$builder=[Data.SqlClient.SqlConnectionStringBuilder]::new((New-LabConnectionString -Entry $targets[0] -TestPurpose Functional))
$builder['Initial Catalog']='master';$builder['Pooling']=$false
$connection=[Data.SqlClient.SqlConnection]::new($builder.ConnectionString)
try{
 $connection.Open();$command=$connection.CreateCommand();$command.CommandTimeout=15
 try{
  $command.CommandText='SELECT COUNT_BIG(*) FROM sys.server_principals WHERE name=@name OR sid=@sid;'
  [void]$command.Parameters.Add('@name',[Data.SqlDbType]::NVarChar,128);$command.Parameters['@name'].Value=[string]$identity.login
  [void]$command.Parameters.Add('@sid',[Data.SqlDbType]::VarBinary,16);$command.Parameters['@sid'].Value=[Convert]::FromHexString($identity.sid)
  if([long]$command.ExecuteScalar() -ne 0){throw 'SSIS_ACCESS_AUDIT_LOGIN_REMAINS'}
  $command.CommandText='SELECT COUNT_BIG(*) FROM sys.dm_exec_sessions WHERE security_id=@sid;'
  if([long]$command.ExecuteScalar() -ne 0){throw 'SSIS_ACCESS_AUDIT_LOGIN_SESSION_REMAINS'}
 }finally{$command.Dispose()}
}finally{$connection.Dispose()}
'SSIS_CURRENT_ACCESS_INDEPENDENT_AUDIT_PASS; databases, trust, configuration, own login and sessions absent'
