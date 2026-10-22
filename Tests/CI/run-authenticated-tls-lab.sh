#!/usr/bin/env bash
set -euo pipefail

# Reiner Transportnachweis im vorhandenen Labadapter: keine Module, Datenbanken,
# Zertifikate oder Labressourcen anlegen. Der Adapter bindet beide Clientwege.
if [[ "${TBX_SQL_TARGET:-}" != lab || "${TBX_SQL_TEST_PURPOSE:-}" != AuthenticatedTls ||
      -z "${TBX_LAB_QUALIFIED_CONTEXT_FILE:-}" || -z "${TBX_SQL_RESOLVED_VERSION:-}" ]]; then
    echo 'AUTHENTICATED_LAB_CONTEXT_REQUIRED' >&2
    exit 65
fi

actual="$(docker exec -i toolbelt-qualified-probe /opt/mssql-tools18/bin/sqlcmd -N -C -h -1 -W -Q "SET NOCOUNT ON; WAITFOR DELAY '00:00:03'; SELECT CONVERT(varchar(32),SERVERPROPERTY('ProductVersion')) + '|' + encrypt_option FROM sys.dm_exec_connections WHERE session_id=@@SPID;")"
actual="$(printf '%s' "${actual}" | tr -d '\r')"
if [[ "${actual}" != "${TBX_SQL_RESOLVED_VERSION}|TRUE" ]]; then
    echo 'AUTHENTICATED_LAB_SQLCMD_RESULT_INVALID' >&2
    exit 1
fi
echo 'AUTHENTICATED_LAB_SQLCMD_PASS'
