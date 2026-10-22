# Der feste Guard wird vor jeder qualifizierten sqlcmd-/Metadatenverbindung
# aufgerufen. Er liest nur den privaten, vom Parent gehaltenen Bytesnapshot;
# die urspruengliche Exportdatei wird niemals erneut geoeffnet.
[CmdletBinding()]
param(
    [Data.SqlClient.SqlConnectionStringBuilder]$Builder,
    [switch]$Sqlcmd
)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'LabQualifiedContract.ps1')
try {
    $purpose=if([string]::IsNullOrEmpty($env:TBX_SQL_TEST_PURPOSE)){'Functional'}else{$env:TBX_SQL_TEST_PURPOSE}
    if($env:TBX_SQL_TARGET -cne 'lab' -or $purpose -cnotin @('Functional','AuthenticatedTls')){throw 'LAB_CONTEXT_TARGET_REQUIRED'}
    if([string]::IsNullOrWhiteSpace($env:TBX_LAB_QUALIFIED_CONTEXT_FILE) -or [string]::IsNullOrWhiteSpace($env:TBX_LAB_QUALIFIED_CONTEXT_SHA256)){throw 'LAB_CONTEXT_REQUIRED'}
    $snapshot=Read-LabQualifiedConsumerContext $env:TBX_LAB_QUALIFIED_CONTEXT_FILE $env:TBX_LAB_QUALIFIED_CONTEXT_SHA256
    $entry=$snapshot.Contract.environments[0]
    if($env:TBX_SQL_HOST -cne $entry.host -or $env:TBX_SQL_PORT -cne ([string]$entry.port) -or $env:TBX_SQL_USER -cne $entry.username -or
        $env:TBX_SQL_PASSWORD -cne $entry.password -or $env:TBX_SQL_KEY -cne $entry.key -or $env:TBX_SQL_ENCRYPT -cne 'True' -or $env:TBX_SQL_TRUST_SERVER_CERTIFICATE -cne 'False'){throw 'LAB_CONTEXT_TARGET_CHANGED'}
    if(-not [string]::IsNullOrEmpty($env:TBX_SQL_RESOLVED_VERSION) -and $env:TBX_SQL_RESOLVED_VERSION -cne $snapshot.Qualification.SqlBuild){throw 'LAB_CONTEXT_BUILD_CHANGED'}
    if($Sqlcmd){
        if((Get-FileHash -LiteralPath $env:TBX_TEST_SQLCMD_BIN).Hash.ToLowerInvariant() -cne $snapshot.Qualification.SqlcmdSha256){throw 'LAB_SQLCMD_CHANGED'}
    } else {
        if($null -eq $Builder -or $Builder.IntegratedSecurity -or $Builder.UserID -cne $entry.username -or $Builder.Password -cne $entry.password -or
            $Builder.DataSource -cnotin @(("tcp:{0},{1}" -f $entry.host,$entry.port),("{0},{1}" -f $entry.host,$entry.port))){throw 'LAB_SQLCLIENT_TARGET_CHANGED'}
        $Builder.Encrypt=$true;$Builder.TrustServerCertificate=$false;$Builder.Pooling=$false;$Builder.ConnectRetryCount=0
    }
    Assert-LabQualifiedConnectWindow $snapshot
} catch {throw 'LAB_QUALIFIED_BINDING_REJECTED'}
