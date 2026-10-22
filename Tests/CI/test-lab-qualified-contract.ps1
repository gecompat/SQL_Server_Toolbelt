# Synthetische Consumergrenzen. Der explizite Modulstub ist kein Kryptobeweis;
# echte Lab-RSA-/Runtime-/Clientnachweise werden getrennt ausgefuehrt.
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'LabQualifiedContract.ps1')
$tokens=$null;$errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'run-lab-local.ps1'),[ref]$tokens,[ref]$errors)
if($errors.Count){throw 'RUNNER_PARSE_FAILED'}
foreach($name in @('Get-EnvironmentVariableValue','Resolve-LabContract')){
    $nodes=@($ast.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq $name},$false))
    if($nodes.Count -ne 1){throw 'RESOLVER_MISSING'}
    . ([scriptblock]::Create($nodes[0].Extent.Text))
}
$script:cases=0
function Assert-Case([bool]$Value,[string]$Case){if(-not $Value){throw ('QUALIFIED_CONSUMER_CASE_FAILED: '+$Case)};$script:cases++}
function Reject-Case([scriptblock]$Action,[string]$Code){try{& $Action|Out-Null;return $false}catch{return $_.Exception.Message -ceq $Code}}
Assert-Case (Reject-Case {Read-LabQualifiedSnapshot ([byte[]]@(1)) $null} 'LAB_QUALIFIED_CONTEXT_REQUIRED') 'explicit context required'
if(-not $IsWindows){Write-Output "QUALIFIED_CONSUMER_PASS cases=$script:cases; Windows private context fixtures NOT_EXECUTED; no SQL";return}
$fixture=Join-Path ([IO.Path]::GetTempPath()) ('toolbelt-qualified-fixture-'+[guid]::NewGuid().ToString('N'))
$bridge=$null;$moduleName=$null
$names=@('SQL_SERVER_LAB_TEST_ENV_FILE','SQL_SERVER_LAB_TEST_ENV_SCHEMA_FILE','SQL_SERVER_LAB_TEST_ENV_PROMPT_FILE','TBX_LAB_QUALIFIED_CONTEXT_FILE','TBX_LAB_QUALIFIED_CONTEXT_SHA256','TBX_SQL_HOST','TBX_SQL_PORT','TBX_SQL_USER','TBX_SQL_PASSWORD','TBX_SQL_KEY','TBX_SQL_ENCRYPT','TBX_SQL_TRUST_SERVER_CERTIFICATE','TBX_TEST_SQLCMD_BIN','TBX_SQL_RESOLVED_VERSION','TBX_SQL_TARGET','TBX_SQL_TEST_PURPOSE')
$saved=@{};foreach($name in $names){$saved[$name]=[Environment]::GetEnvironmentVariable($name,'Process')}
function Write-FixtureFile([string]$Path,[byte[]]$Bytes){
    $writer=[IO.FileSystemAclExtensions]::Create([IO.FileInfo]::new($Path),[IO.FileMode]::CreateNew,[Security.AccessControl.FileSystemRights]::FullControl,[IO.FileShare]::None,4096,[IO.FileOptions]::None,(Get-LabQualifiedPrivateSecurity))
    try{$writer.Write($Bytes,0,$Bytes.Length);$writer.Flush($true)}finally{$writer.Dispose()}
}
try {
    [IO.FileSystemAclExtensions]::Create([IO.DirectoryInfo]::new($fixture),(Get-LabQualifiedPrivateSecurity -Directory))
    $schema=Join-Path $fixture 'schema.json';$path=Join-Path $fixture 'contract.json';$prompt=Join-Path $fixture 'prompt.md';$client=Join-Path $fixture 'client.bin'
    # Ein permissiver Schemaoverride darf keine Signatur-/Kontextautoritaet liefern.
    Write-FixtureFile $schema ([Text.Encoding]::UTF8.GetBytes('{"type":"object","required":["contractVersion","groupStatus","environments"]}'))
    Write-FixtureFile $prompt ([Text.Encoding]::UTF8.GetBytes('Synthetic fixture only.'))
    Write-FixtureFile $client ([byte[]]@(1,2,3,4))
    $entry=[ordered]@{key='SYNTHETIC_TARGET';host='127.0.0.1';port=14333;username='sa';password='Synthetic-Only-8472!';database='master';encrypt=$true;trustServerCertificate=$false}
    $doc=[ordered]@{contractVersion='SqlServerLab.TestEnvironment/2.0';groupStatus='READY';environments=@($entry);qualification=@{signature='FORGED'}}
    $bytes=[Text.Encoding]::UTF8.GetBytes(($doc|ConvertTo-Json -Depth 8 -Compress))
    Write-FixtureFile $path $bytes
    $env:SQL_SERVER_LAB_TEST_ENV_FILE=$path;$env:SQL_SERVER_LAB_TEST_ENV_SCHEMA_FILE=$schema;$env:SQL_SERVER_LAB_TEST_ENV_PROMPT_FILE=$prompt
    Assert-Case (Reject-Case {Resolve-LabContract -TestPurpose AuthenticatedTls} 'LAB_QUALIFIED_CONTEXT_REQUIRED') 'schema cannot authorize a contextless V2 export'
    $moduleName='FakeQualifiedLab'+[guid]::NewGuid().ToString('N');$moduleFile=Join-Path $fixture ($moduleName+'.psm1')
    $module=@'
function Read-SqlServerLabQualifiedTestEnvironment {
 param([byte[]]$ExportBytes,[string]$StateRoot,[string]$RunId,[string]$InstanceId)
 if($StateRoot -cne 'SYNTHETIC_ROOT' -or $RunId -cne 'synthetic-run' -or $InstanceId -cne 'primary'){throw 'UNIT_CONTEXT_MISMATCH'}
 $doc=[Text.Encoding]::UTF8.GetString($ExportBytes)|ConvertFrom-Json -DateKind String
 if($doc.qualification.signature -cne 'UNIT_ONLY_VALID'){throw 'UNIT_SIGNATURE_REJECTED'}
 [pscustomobject]@{ContractVersion='SqlServerLab.QualifiedTestEnvironmentSnapshot/0.1';ExportBytes=[byte[]]$ExportBytes.Clone();ExportSha256=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($ExportBytes)).ToLowerInvariant();Contract=$doc;Qualification=[pscustomobject]@{ExpiresAt=[DateTimeOffset]::UtcNow.AddMinutes(10).ToString('o');SqlcmdSha256=$script:ClientHash;SqlBuild='17.0.5005.3'}}
}
'@
    $clientHash=Get-LabContractByteHash ([IO.File]::ReadAllBytes($client))
    Write-FixtureFile $moduleFile ([Text.Encoding]::UTF8.GetBytes(("`$script:ClientHash='$clientHash'`n"+$module)))
    $context=[pscustomobject]@{ModuleFile=$moduleFile;StateRoot='SYNTHETIC_ROOT';RunId='synthetic-run';InstanceId='primary'}
    Assert-Case (Reject-Case {Resolve-LabContract -TestPurpose AuthenticatedTls -TlsContext $context} 'LAB_QUALIFIED_EXPORT_REJECTED') 'schema-valid forged payload rejected by explicit verifier'
    $doc.qualification.signature='UNIT_ONLY_VALID';$bytes=[Text.Encoding]::UTF8.GetBytes(($doc|ConvertTo-Json -Depth 8 -Compress));[IO.File]::WriteAllBytes($path,$bytes)
    $resolved=Resolve-LabContract -TestPurpose AuthenticatedTls -TlsContext $context
    Assert-Case ($resolved.Snapshot.ExportSha256 -ceq (Get-LabContractByteHash $bytes) -and $resolved.Contract.environments[0].key -ceq 'SYNTHETIC_TARGET') 'verified snapshot supplies selected entry'
    [IO.File]::WriteAllText($path,'{"path":"replaced"}')
    $bridge=Open-LabQualifiedConsumerContext $resolved.Snapshot $context $client
    $blocked=$false;try{[IO.File]::WriteAllText($bridge.Path,'changed')}catch{$blocked=$_.Exception -is [IO.IOException] -or $_.Exception.InnerException -is [IO.IOException]}
    Assert-Case $blocked 'held parent file denies writer replacement'
    $current=Read-LabQualifiedConsumerContext $bridge.Path $bridge.Sha256
    Assert-Case ($current.Contract.environments[0].password -ceq 'Synthetic-Only-8472!') 'child consumes captured bytes instead of replaced export path'
    Assert-Case (Reject-Case {Read-LabQualifiedConsumerContext $bridge.Path ('0'*64)} 'LAB_CONTEXT_CHANGED') 'child rejects different expected bytes'
    [IO.File]::WriteAllBytes($client,([byte[]]@(5)))
    Assert-Case (Reject-Case {Read-LabQualifiedConsumerContext $bridge.Path $bridge.Sha256} 'LAB_CONTEXT_TARGET_OR_CLIENT_CHANGED') 'selected client drift rejects'
    [IO.File]::WriteAllBytes($client,([byte[]]@(1,2,3,4)))
    $env:TBX_LAB_QUALIFIED_CONTEXT_FILE=$bridge.Path;$env:TBX_LAB_QUALIFIED_CONTEXT_SHA256=$bridge.Sha256
    $env:TBX_SQL_TARGET='lab';$env:TBX_SQL_TEST_PURPOSE='AuthenticatedTls'
    $env:TBX_SQL_HOST='127.0.0.1';$env:TBX_SQL_PORT='14333';$env:TBX_SQL_USER='sa';$env:TBX_SQL_PASSWORD='Synthetic-Only-8472!';$env:TBX_SQL_KEY='SYNTHETIC_TARGET';$env:TBX_SQL_ENCRYPT='True';$env:TBX_SQL_TRUST_SERVER_CERTIFICATE='False';$env:TBX_TEST_SQLCMD_BIN=$client
    $env:TBX_SQL_RESOLVED_VERSION='17.0.5005.3'
    $builder=[Data.SqlClient.SqlConnectionStringBuilder]::new('Server=tcp:127.0.0.1,14333;User ID=sa;Password=Synthetic-Only-8472!;')
    & (Join-Path $PSScriptRoot 'Assert-LabQualifiedTlsBinding.ps1') -Builder $builder
    Assert-Case ($builder.Encrypt -and -not $builder.TrustServerCertificate -and -not $builder.Pooling -and $builder.ConnectRetryCount -eq 0) 'real builder uses strict fresh connection without retries'
    $env:TBX_SQL_RESOLVED_VERSION='17.0.1.1'
    Assert-Case (Reject-Case {& (Join-Path $PSScriptRoot 'Assert-LabQualifiedTlsBinding.ps1') -Sqlcmd} 'LAB_QUALIFIED_BINDING_REJECTED') 'different caller build rejected'
    $env:TBX_SQL_RESOLVED_VERSION='17.0.5005.3'
    $env:TBX_SQL_HOST='127.0.0.2'
    Assert-Case (Reject-Case {& (Join-Path $PSScriptRoot 'Assert-LabQualifiedTlsBinding.ps1') -Sqlcmd} 'LAB_QUALIFIED_BINDING_REJECTED') 'different live caller endpoint rejected'
    $near=[pscustomobject]@{Qualification=[pscustomobject]@{ExpiresAt=[DateTimeOffset]::UtcNow.AddSeconds(20).ToString('o')}}
    Assert-Case (Reject-Case {Assert-LabQualifiedConnectWindow $near} 'LAB_QUALIFIED_CONNECT_WINDOW_EXPIRED') 'near-expiry does not admit a new login'
    Close-LabQualifiedConsumerContext $bridge;$bridge=$null
    $legacy=[ordered]@{contractVersion='SqlServerLab.TestEnvironment/1.0';groupStatus='READY';environments=@(@{key='LEGACY';trustServerCertificate=$true;encrypt=$true})}
    [IO.File]::WriteAllText($path,($legacy|ConvertTo-Json -Depth 6))
    Assert-Case ($null -eq (Resolve-LabContract -TestPurpose Functional).Snapshot) 'V1 functional caller remains independent of Lab module'
    Assert-Case (Reject-Case {Resolve-LabContract -TestPurpose AuthenticatedTls} 'LAB_QUALIFIED_V2_REQUIRED') 'authenticated purpose cannot fall back to V1'
    $legacy.contractVersion='Unknown.Contract/3.0';[IO.File]::WriteAllText($path,($legacy|ConvertTo-Json -Depth 6))
    Assert-Case (Reject-Case {Resolve-LabContract -TestPurpose Functional} 'LAB_CONTRACT_VERSION_UNSUPPORTED') 'schema override cannot authorize unknown contract versions'
} finally {
    if($bridge){Close-LabQualifiedConsumerContext $bridge}
    foreach($name in $names){[Environment]::SetEnvironmentVariable($name,$saved[$name],'Process')}
    if($moduleName){Remove-Module $moduleName -ErrorAction SilentlyContinue}
    if(Test-Path -LiteralPath $fixture){
        $full=[IO.Path]::GetFullPath($fixture);$parent=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\','/')+[IO.Path]::DirectorySeparatorChar
        if(-not $full.StartsWith($parent,[StringComparison]::OrdinalIgnoreCase) -or [IO.Path]::GetFileName($full) -cnotmatch '^toolbelt-qualified-fixture-[a-f0-9]{32}$'){throw 'FIXTURE_CLEANUP_SCOPE_INVALID'}
        Remove-Item -LiteralPath $full -Recurse -Force
    }
}
Write-Output "QUALIFIED_CONSUMER_PASS cases=$script:cases; synthetic module and clients; no SQL/provider actions"
