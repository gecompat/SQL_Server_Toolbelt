# Gemeinsame Transportpolicy für SQLClient-Metadatenprüfungen.
# Fachtests übernehmen den validierten Labvertrag. AuthenticatedTls prüft
# zusätzlich die Serveridentität; außerhalb von Lab bleibt nur Loopback-CI ausgenommen.
[CmdletBinding()]
param([Parameter(Mandatory)][Data.SqlClient.SqlConnectionStringBuilder]$Builder)
$Builder.Encrypt=$true
if ($env:TBX_SQL_TARGET -ceq 'lab') {
    $purpose = if ([string]::IsNullOrEmpty($env:TBX_SQL_TEST_PURPOSE)) { 'Functional' } else { $env:TBX_SQL_TEST_PURPOSE }
    if ($purpose -cnotin @('Functional', 'AuthenticatedTls') -or
        $env:TBX_SQL_ENCRYPT -cne 'True' -or $env:TBX_SQL_TRUST_SERVER_CERTIFICATE -cnotin @('True', 'False') -or
        ($purpose -ceq 'AuthenticatedTls' -and $env:TBX_SQL_TRUST_SERVER_CERTIFICATE -cne 'False')) {
        throw 'LAB_SQLCLIENT_TLS_CONTRACT_REQUIRED'
    }
    $Builder.TrustServerCertificate=($env:TBX_SQL_TRUST_SERVER_CERTIFICATE -ceq 'True')
} else {
    $Builder.TrustServerCertificate=(($env:TBX_SQL_TARGET -ceq 'runner' -or $env:GITHUB_ACTIONS -ceq 'true') -and $Builder.DataSource -match '^(?:tcp:)?(?:localhost|127\.0\.0\.1)(?:,[0-9]{1,5})?$')
}
