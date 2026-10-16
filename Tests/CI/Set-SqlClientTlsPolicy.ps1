# Gemeinsame Transportpolicy für SQLClient-Metadatenprüfungen.
# Lab verlangt den bereits validierten Vertrag; selbstsignierte Zertifikate
# bleiben ausschließlich für eigene flüchtige Loopback-CI-Container zulässig.
[CmdletBinding()]
param([Parameter(Mandatory)][Data.SqlClient.SqlConnectionStringBuilder]$Builder)
$Builder.Encrypt=$true
if ($env:TBX_SQL_TARGET -ceq 'lab') {
    if ($env:TBX_SQL_ENCRYPT -cne 'True' -or $env:TBX_SQL_TRUST_SERVER_CERTIFICATE -cne 'False') {
        throw 'LAB_SQLCLIENT_TLS_CONTRACT_REQUIRED'
    }
    $Builder.TrustServerCertificate=$false
} else {
    $Builder.TrustServerCertificate=(($env:TBX_SQL_TARGET -ceq 'runner' -or $env:GITHUB_ACTIONS -ceq 'true') -and $Builder.DataSource -match '^(?:tcp:)?(?:localhost|127\.0\.0\.1)(?:,[0-9]{1,5})?$')
}
