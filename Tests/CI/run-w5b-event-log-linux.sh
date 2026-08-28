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
container_name="tbx-w5b-${GITHUB_RUN_ID:-local}"
sa_password="TbxA1!$(openssl rand -hex 16)"
linked_server="TBX_LOOPBACK"
echo "::add-mask::${sa_password}"

cleanup() { docker rm -f "${container_name}" >/dev/null 2>&1 || true; }
trap cleanup EXIT

docker run -d --name "${container_name}" \
  -e ACCEPT_EULA=Y -e MSSQL_PID=Developer -e MSSQL_SA_PASSWORD="${sa_password}" \
  -v "${GITHUB_WORKSPACE:-$(pwd)}:/workspace:ro" "${sql_image}" >/dev/null

sqlcmd_path=""
for candidate in /opt/mssql-tools18/bin/sqlcmd /opt/mssql-tools/bin/sqlcmd; do
  if docker exec "${container_name}" test -x "${candidate}"; then sqlcmd_path="${candidate}"; break; fi
done
[[ -n "${sqlcmd_path}" ]] || { echo "sqlcmd fehlt" >&2; exit 1; }

for attempt in $(seq 1 60); do
  if docker exec "${container_name}" "${sqlcmd_path}" -S localhost -U sa -P "${sa_password}" -C -b -Q "SELECT 1" >/dev/null 2>&1; then break; fi
  if [[ "${attempt}" -eq 60 ]]; then docker logs "${container_name}"; exit 1; fi
  sleep 2
done

run_query() { docker exec "${container_name}" "${sqlcmd_path}" -S localhost -U sa -P "${sa_password}" -C -b -d "$1" -Q "$2"; }
run_file() {
  local db="$1" workdir="$2" file="$3"; shift 3
  docker exec --workdir "${workdir}" "${container_name}" "${sqlcmd_path}" \
    -S localhost -U sa -P "${sa_password}" -C -b -d "${db}" -i "${file}" "$@"
}
run_stdin() {
  local db="$1"; shift
  docker exec -i "${container_name}" "${sqlcmd_path}" -S localhost -U sa -P "${sa_password}" -C -b -d "${db}" -i /dev/stdin "$@"
}
deploy() { run_file "$1" "/workspace/$2/Deployment" Deploy.sql -v DeploymentMode="$3"; }
uninstall() { run_file "$1" "/workspace/$2/Deployment" Uninstall.sql -v ConfirmNoExternalConsumers="$3" AllowDataLoss="$4"; }

configure_linked_server() {
  run_stdin master -v SaPassword="${sa_password}" LinkedServerName="${linked_server}" <<'SQL'
:on error exit
IF EXISTS (SELECT 1 FROM sys.servers WHERE name=N'$(LinkedServerName)')
    EXEC master.dbo.sp_dropserver @server=N'$(LinkedServerName)',@droplogins='droplogins';
GO
EXEC master.dbo.sp_addlinkedserver @server=N'$(LinkedServerName)',@srvproduct=N'',@provider=N'MSOLEDBSQL',@datasrc=N'localhost',@provstr=N'encrypt=optional';
GO
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'$(LinkedServerName)',@useself=N'False',@locallogin=NULL,@rmtuser=N'sa',@rmtpassword=N'$(SaPassword)';
GO
EXEC master.dbo.sp_serveroption N'$(LinkedServerName)',N'rpc out',N'true';
EXEC master.dbo.sp_serveroption N'$(LinkedServerName)',N'remote proc transaction promotion',N'false';
GO
SQL
}

deploy_stack() {
  local db="$1" mode="$2"
  deploy "${db}" Modules/toolbelt.core.result-table "${mode}"
  deploy "${db}" Modules/toolbelt.core.execution-context "${mode}"
  deploy "${db}" Modules/toolbelt.core.work-type "${mode}"
  deploy "${db}" Modules/toolbelt.core.second-session "${mode}"
  run_query "${db}" "EXEC toolbelt_core.USP_ConfigureSecondSessionLoopback @LinkedServerName=N'${linked_server}';"
  deploy "${db}" Modules/toolbelt.core.event-log "${mode}"
}

uninstall_stack() {
  local db="$1" confirm="$2"
  uninstall "${db}" Modules/toolbelt.core.event-log "${confirm}" 1
  uninstall "${db}" Modules/toolbelt.core.second-session "${confirm}" 1
  uninstall "${db}" Modules/toolbelt.core.work-type "${confirm}" 1
  uninstall "${db}" Modules/toolbelt.core.execution-context "${confirm}" 1
  uninstall "${db}" Modules/toolbelt.core.result-table "${confirm}" 1
}

configure_linked_server
local_db=tbx_w5b_local
run_query master "CREATE DATABASE [${local_db}] COLLATE Latin1_General_100_CS_AS;"
deploy_stack "${local_db}" local
run_file "${local_db}" /workspace/Modules/toolbelt.core.event-log/Tests/Runtime Lifecycle.Contract.sql

for level in ${compatibility_levels}; do
  run_query "${local_db}" "ALTER DATABASE [${local_db}] SET COMPATIBILITY_LEVEL=${level}; DELETE FROM toolbelt_core.EventLog;"
  run_file "${local_db}" /workspace/Modules/toolbelt.core.event-log/Tests/Runtime EventLog.Contract.sql
done

run_query "${local_db}" "DELETE FROM toolbelt_core.EventLog WHERE EventName='test.concurrent';"
workers=()
for worker in 1 2 3 4; do
  run_file "${local_db}" /workspace/Modules/toolbelt.core.event-log/Tests/Runtime Concurrency.Contract.sql -v WorkerId="${worker}" &
  workers+=("$!")
done
for pid in "${workers[@]}"; do wait "${pid}"; done
run_file "${local_db}" /workspace/Modules/toolbelt.core.event-log/Tests/Runtime Concurrency.Verify.sql

# Redeploy muss Events und internen Work Type erhalten.
before_count="$(run_query "${local_db}" "SET NOCOUNT ON; SELECT COUNT(*) FROM toolbelt_core.EventLog;" | awk '/^[[:space:]]*[0-9]+[[:space:]]*$/ {gsub(/ /,""); print; exit}')"
deploy "${local_db}" Modules/toolbelt.core.event-log local
after_count="$(run_query "${local_db}" "SET NOCOUNT ON; SELECT COUNT(*) FROM toolbelt_core.EventLog;" | awk '/^[[:space:]]*[0-9]+[[:space:]]*$/ {gsub(/ /,""); print; exit}')"
[[ -n "${before_count}" && "${before_count}" = "${after_count}" ]] || { echo "Redeploy verlor Eventdaten." >&2; exit 1; }
run_query "${local_db}" "IF NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkType WHERE WorkTypeName='toolbelt.event-log.write' AND IsEnabled=1) THROW 52740,N'Redeploy verlor den Event-Log-Work-Type.',1;"

central_db=tbx_w5b_central
consumer_db=tbx_w5b_consumer
run_query master "CREATE DATABASE [${central_db}] COLLATE Latin1_General_100_BIN2; CREATE DATABASE [${consumer_db}] COLLATE Latin1_General_100_CS_AS;"
deploy_stack "${central_db}" central
run_file "${consumer_db}" /workspace/Modules/toolbelt.core.event-log/Tests/Runtime Central.Contract.sql -v ToolbeltDatabase="${central_db}"

# Data-Loss-Guard und Work-Type-Cleanup.
set +e
uninstall "${local_db}" Modules/toolbelt.core.event-log 0 0 >/tmp/w5b-uninstall.out 2>&1
uninstall_rc=$?
set -e
cat /tmp/w5b-uninstall.out
if ! grep -q "51749" /tmp/w5b-uninstall.out; then
  echo "Der erwartete Event-Data-Loss-Fehler 51749 fehlt; Exitcode=${uninstall_rc}." >&2
  exit 1
fi
run_query "${local_db}" "IF OBJECT_ID(N'toolbelt_core.EventLog',N'U') IS NULL OR NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkType WHERE WorkTypeName='toolbelt.event-log.write') THROW 52741,N'Der abgelehnte Event-Uninstall veränderte Daten oder Work Type.',1;"

uninstall "${local_db}" Modules/toolbelt.core.event-log 0 1
run_query "${local_db}" "IF EXISTS(SELECT 1 FROM toolbelt_core.WorkType WHERE WorkTypeName='toolbelt.event-log.write') THROW 52742,N'Der Event-Log-Work-Type blieb nach Uninstall bestehen.',1; IF OBJECT_ID(N'toolbelt_core.EventLog',N'U') IS NOT NULL THROW 52743,N'EventLog blieb nach Uninstall bestehen.',1;"
# Restlichen lokalen Stack abbauen, Event Log ist bereits entfernt.
uninstall "${local_db}" Modules/toolbelt.core.second-session 0 1
uninstall "${local_db}" Modules/toolbelt.core.work-type 0 1
uninstall "${local_db}" Modules/toolbelt.core.execution-context 0 1
uninstall "${local_db}" Modules/toolbelt.core.result-table 0 1

uninstall_stack "${central_db}" 1
run_query master "IF NOT EXISTS(SELECT 1 FROM sys.servers WHERE name=N'${linked_server}') THROW 52744,N'Modul-Uninstall entfernte den administrierten Linked Server.',1; EXEC master.dbo.sp_dropserver @server=N'${linked_server}',@droplogins='droplogins';"

echo "W5b Event Log Linux: erfolgreich"
