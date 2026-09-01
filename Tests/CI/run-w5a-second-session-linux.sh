#!/usr/bin/env bash
set -euo pipefail

sql_image="${TBX_SQL_IMAGE:?TBX_SQL_IMAGE fehlt}"
sql_version="${TBX_SQL_VERSION:-2025}"
case "${sql_version}" in
  2019) compatibility_levels="150" ;;
  2022) compatibility_levels="160" ;;
  2025) compatibility_levels="150 160 170" ;;
  *) echo "Nicht unterstützte SQL-Version: ${sql_version}" >&2; exit 1 ;;
esac
# encrypt=optional existiert erst ab MSOLEDBSQL 19; ältere Images kennen nur yes/no.
case "${sql_version}" in
  2019|2022) provider_encrypt="no" ;;
  *) provider_encrypt="optional" ;;
esac
container_name="tbx-w5a-${GITHUB_RUN_ID:-local}"
sa_password="TbxA1!$(openssl rand -hex 16)"
linked_server="TBX_LOOPBACK"
echo "::add-mask::${sa_password}"

cleanup() {
  docker rm -f "${container_name}" >/dev/null 2>&1 || true
}
trap cleanup EXIT

docker run -d \
  --name "${container_name}" \
  -e ACCEPT_EULA=Y \
  -e MSSQL_PID=Developer \
  -e MSSQL_SA_PASSWORD="${sa_password}" \
  -v "${GITHUB_WORKSPACE:-$(pwd)}:/workspace:ro" \
  "${sql_image}" >/dev/null

sqlcmd_path=""
for candidate in /opt/mssql-tools18/bin/sqlcmd /opt/mssql-tools/bin/sqlcmd; do
  if docker exec "${container_name}" test -x "${candidate}"; then
    sqlcmd_path="${candidate}"
    break
  fi
done
[[ -n "${sqlcmd_path}" ]] || { echo "sqlcmd fehlt" >&2; exit 1; }

for attempt in $(seq 1 60); do
  if docker exec "${container_name}" "${sqlcmd_path}" \
      -S localhost -U sa -P "${sa_password}" -C -b -Q "SELECT 1" >/dev/null 2>&1; then
    break
  fi
  if [[ "${attempt}" -eq 60 ]]; then
    docker logs "${container_name}"
    exit 1
  fi
  sleep 2
done

run_query() {
  docker exec "${container_name}" "${sqlcmd_path}" \
    -S localhost -U sa -P "${sa_password}" -C -b -d "$1" -Q "$2"
}

run_file() {
  local db="$1"
  local workdir="$2"
  local file="$3"
  shift 3
  docker exec --workdir "${workdir}" "${container_name}" "${sqlcmd_path}" \
    -S localhost -U sa -P "${sa_password}" -C -b -d "${db}" -i "${file}" "$@"
}

run_stdin() {
  local db="$1"
  shift
  docker exec -i "${container_name}" "${sqlcmd_path}" \
    -S localhost -U sa -P "${sa_password}" -C -b -d "${db}" -i /dev/stdin "$@"
}

deploy() {
  run_file "$1" "/workspace/$2/Deployment" Deploy.sql -v DeploymentMode="$3"
}

uninstall() {
  run_file "$1" "/workspace/$2/Deployment" Uninstall.sql \
    -v ConfirmNoExternalConsumers="$3" AllowDataLoss="$4"
}

configure_linked_server() {
  run_stdin master -v SaPassword="${sa_password}" LinkedServerName="${linked_server}" ProviderEncrypt="${provider_encrypt}" <<'SQL'
:on error exit
IF EXISTS (SELECT 1 FROM sys.servers WHERE name = N'$(LinkedServerName)')
    EXEC master.dbo.sp_dropserver @server=N'$(LinkedServerName)', @droplogins='droplogins';
GO
EXEC master.dbo.sp_addlinkedserver
      @server = N'$(LinkedServerName)'
    , @srvproduct = N''
    , @provider = N'MSOLEDBSQL'
    , @datasrc = N'localhost'
    , @provstr = N'encrypt=$(ProviderEncrypt)';
GO
EXEC master.dbo.sp_addlinkedsrvlogin
      @rmtsrvname = N'$(LinkedServerName)'
    , @useself = N'False'
    , @locallogin = NULL
    , @rmtuser = N'sa'
    , @rmtpassword = N'$(SaPassword)';
GO
EXEC master.dbo.sp_serveroption N'$(LinkedServerName)', N'rpc out', N'true';
EXEC master.dbo.sp_serveroption N'$(LinkedServerName)', N'remote proc transaction promotion', N'false';
GO
SQL
}

local_db=tbx_w5a_local
run_query master "CREATE DATABASE [${local_db}] COLLATE Latin1_General_100_CS_AS;"
deploy "${local_db}" Modules/toolbelt.core.result-table local
deploy "${local_db}" Modules/toolbelt.core.execution-context local
deploy "${local_db}" Modules/toolbelt.core.work-type local
deploy "${local_db}" Modules/toolbelt.core.second-session local
configure_linked_server

run_file "${local_db}" /workspace/Modules/toolbelt.core.second-session/Tests/Runtime Lifecycle.Contract.sql
for level in ${compatibility_levels}; do
  run_query "${local_db}" "ALTER DATABASE [${local_db}] SET COMPATIBILITY_LEVEL = ${level};"
  run_file "${local_db}" /workspace/Modules/toolbelt.core.second-session/Tests/Runtime SecondSession.Contract.sql \
    -v LinkedServerName="${linked_server}"
done

# Vier echte Caller-Sessions mit überlappenden Remote-Handlern.
run_stdin "${local_db}" <<'SQL'
:on error exit
DROP TABLE IF EXISTS toolbelt_core.SecondSessionConcurrencyEvidence;
GO
CREATE TABLE toolbelt_core.SecondSessionConcurrencyEvidence
(
      EvidenceId bigint IDENTITY(1,1) NOT NULL CONSTRAINT PK_SecondSessionConcurrencyEvidence PRIMARY KEY
    , WorkerId int NOT NULL
    , CallerSessionId int NOT NULL
    , RemoteSessionId int NOT NULL
    , CreatedAtUtc datetime2(7) NOT NULL CONSTRAINT DF_SecondSessionConcurrencyEvidence_CreatedAtUtc DEFAULT SYSUTCDATETIME()
);
GO
CREATE OR ALTER PROCEDURE toolbelt_core.USP_TestSecondSessionConcurrent
    @PayloadJson nvarchar(max)
AS
BEGIN
    SET NOCOUNT ON;
    WAITFOR DELAY '00:00:02';
    INSERT INTO toolbelt_core.SecondSessionConcurrencyEvidence
    (
        WorkerId, CallerSessionId, RemoteSessionId
    )
    VALUES
    (
          TRY_CONVERT(int, JSON_VALUE(@PayloadJson, '$.worker'))
        , TRY_CONVERT(int, JSON_VALUE(@PayloadJson, '$.callerSession'))
        , @@SPID
    );
    RETURN 0;
END;
GO
EXEC toolbelt_core.USP_RegisterWorkType
      @WorkTypeName = 'test.second-session.concurrent'
    , @HandlerSchema = N'toolbelt_core'
    , @HandlerProcedure = N'USP_TestSecondSessionConcurrent'
    , @ParameterMode = 'JSON_PAYLOAD'
    , @PayloadContractJson = N'{"type":"object"}';
GO
SQL

workers=()
for worker in 1 2 3 4; do
  run_file "${local_db}" /workspace/Modules/toolbelt.core.second-session/Tests/Runtime Concurrency.Contract.sql \
    -v WorkerId="${worker}" &
  workers+=("$!")
done
for pid in "${workers[@]}"; do
  wait "${pid}"
done
run_file "${local_db}" /workspace/Modules/toolbelt.core.second-session/Tests/Runtime Concurrency.Verify.sql

# Redeploy darf die administrierte Providerkonfiguration nicht verlieren.
deploy "${local_db}" Modules/toolbelt.core.second-session local
run_query "${local_db}" "IF NOT EXISTS (SELECT 1 FROM toolbelt_core.SecondSessionProvider WHERE ProviderName='loopback' AND LinkedServerName=N'${linked_server}') THROW 52690, N'Redeploy verlor die Providerkonfiguration.', 1;"

central_db=tbx_w5a_central
consumer_db=tbx_w5a_consumer
run_query master "CREATE DATABASE [${central_db}] COLLATE Latin1_General_100_BIN2; CREATE DATABASE [${consumer_db}] COLLATE Latin1_General_100_CS_AS;"
deploy "${central_db}" Modules/toolbelt.core.result-table central
deploy "${central_db}" Modules/toolbelt.core.execution-context central
deploy "${central_db}" Modules/toolbelt.core.work-type central
deploy "${central_db}" Modules/toolbelt.core.second-session central
run_query "${central_db}" "EXEC toolbelt_core.USP_ConfigureSecondSessionLoopback @LinkedServerName=N'${linked_server}';"

run_stdin "${central_db}" <<'SQL'
:on error exit
DROP TABLE IF EXISTS toolbelt_core.SecondSessionCentralEvidence;
GO
CREATE TABLE toolbelt_core.SecondSessionCentralEvidence
(
      EvidenceId bigint IDENTITY(1,1) NOT NULL CONSTRAINT PK_SecondSessionCentralEvidence PRIMARY KEY
    , RemoteSessionId int NOT NULL
    , ExecutionId uniqueidentifier NULL
    , Actor nvarchar(256) NULL
);
GO
CREATE OR ALTER PROCEDURE toolbelt_core.USP_TestSecondSessionCentral
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @ExecutionId uniqueidentifier;
    DECLARE @Actor nvarchar(256);
    SELECT @ExecutionId=c.ExecutionId, @Actor=c.Actor
    FROM toolbelt_core.TVF_CurrentExecutionContext() AS c;
    INSERT INTO toolbelt_core.SecondSessionCentralEvidence(RemoteSessionId, ExecutionId, Actor)
    VALUES (@@SPID, @ExecutionId, @Actor);
    RETURN 0;
END;
GO
EXEC toolbelt_core.USP_RegisterWorkType
      @WorkTypeName = 'test.second-session.central'
    , @HandlerSchema = N'toolbelt_core'
    , @HandlerProcedure = N'USP_TestSecondSessionCentral';
GO
SQL
run_file "${consumer_db}" /workspace/Modules/toolbelt.core.second-session/Tests/Runtime Central.Contract.sql \
  -v ToolbeltDatabase="${central_db}"
run_query "${central_db}" "DELETE FROM toolbelt_core.WorkType WHERE WorkTypeName='test.second-session.central'; DROP PROCEDURE toolbelt_core.USP_TestSecondSessionCentral; DROP TABLE toolbelt_core.SecondSessionCentralEvidence;"

# Der Modul-Uninstall darf weder Konfiguration still verlieren noch den Linked Server entfernen.
set +e
uninstall "${local_db}" Modules/toolbelt.core.second-session 0 0 >/tmp/w5a-uninstall.out 2>&1
uninstall_rc=$?
set -e
cat /tmp/w5a-uninstall.out
if ! grep -q "51649" /tmp/w5a-uninstall.out; then
  echo "Der erwartete Provider-Data-Loss-Fehler 51649 fehlt; Exitcode=${uninstall_rc}." >&2
  exit 1
fi
run_query "${local_db}" "IF OBJECT_ID(N'toolbelt_core.SecondSessionProvider', N'U') IS NULL OR NOT EXISTS (SELECT 1 FROM toolbelt_core.SecondSessionProvider WHERE ProviderName='loopback') THROW 52691, N'Der abgelehnte Uninstall veränderte die Providerkonfiguration.', 1;"

uninstall "${central_db}" Modules/toolbelt.core.second-session 1 1
uninstall "${central_db}" Modules/toolbelt.core.work-type 1 1
uninstall "${central_db}" Modules/toolbelt.core.execution-context 1 1
uninstall "${central_db}" Modules/toolbelt.core.result-table 1 1
uninstall "${local_db}" Modules/toolbelt.core.second-session 0 1
uninstall "${local_db}" Modules/toolbelt.core.work-type 0 1
uninstall "${local_db}" Modules/toolbelt.core.execution-context 0 1
uninstall "${local_db}" Modules/toolbelt.core.result-table 0 1

run_query master "IF NOT EXISTS (SELECT 1 FROM sys.servers WHERE name=N'${linked_server}') THROW 52692, N'Der Modul-Uninstall entfernte den administrierten Linked Server.', 1; EXEC master.dbo.sp_dropserver @server=N'${linked_server}', @droplogins='droplogins';"

echo "W5a Second Session Linux: erfolgreich"
