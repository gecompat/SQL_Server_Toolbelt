#!/usr/bin/env bash
set -euo pipefail

sql_image="${TBX_SQL_IMAGE:?TBX_SQL_IMAGE fehlt}"
container_name="tbx-w4b-${GITHUB_RUN_ID:-local}"
sa_password="Tbx!$(openssl rand -hex 16)Aa1"
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

deploy() {
  run_file "$1" "/workspace/$2/Deployment" Deploy.sql -v DeploymentMode="$3"
}

uninstall() {
  run_file "$1" "/workspace/$2/Deployment" Uninstall.sql \
    -v ConfirmNoExternalConsumers="$3" AllowDataLoss="$4"
}

local_db=tbx_w4b_local
run_query master "CREATE DATABASE [${local_db}] COLLATE Latin1_General_100_CS_AS;"
deploy "${local_db}" Modules/toolbelt.core.result-table local
deploy "${local_db}" Modules/toolbelt.core.work-type local
run_file "${local_db}" /workspace/Modules/toolbelt.core.work-type/Tests/Runtime Lifecycle.Contract.sql

for level in 150 160 170; do
  run_query "${local_db}" "ALTER DATABASE [${local_db}] SET COMPATIBILITY_LEVEL = ${level};"
  run_file "${local_db}" /workspace/Modules/toolbelt.core.work-type/Tests/Runtime WorkType.Contract.sql
  run_file "${local_db}" /workspace/Modules/toolbelt.core.work-type/Tests/Runtime Remove.Contract.sql
done

# Concurrency: gleicher idempotenter Register-Aufruf aus vier echten Sessions.
run_query "${local_db}" "CREATE OR ALTER PROCEDURE toolbelt_core.USP_TestWorkTypeConcurrent AS BEGIN SET NOCOUNT ON; END;"
workers=()
for worker in 1 2 3 4; do
  run_file "${local_db}" /workspace/Modules/toolbelt.core.work-type/Tests/Runtime Concurrency.Contract.sql &
  workers+=("$!")
done
for pid in "${workers[@]}"; do
  wait "${pid}"
done
run_file "${local_db}" /workspace/Modules/toolbelt.core.work-type/Tests/Runtime Concurrency.Verify.sql

# Redeploy muss persistente Daten erhalten.
run_query "${local_db}" "CREATE OR ALTER PROCEDURE toolbelt_core.USP_TestPreserve AS BEGIN SET NOCOUNT ON; END;"
run_query "${local_db}" "EXEC toolbelt_core.USP_RegisterWorkType @WorkTypeName='test.preserve', @HandlerSchema=N'toolbelt_core', @HandlerProcedure=N'USP_TestPreserve';"
deploy "${local_db}" Modules/toolbelt.core.work-type local
run_query "${local_db}" "IF NOT EXISTS (SELECT 1 FROM toolbelt_core.WorkType WHERE WorkTypeName='test.preserve') THROW 52550, N'Redeploy verlor persistente Daten.', 1;"
run_query "${local_db}" "DELETE FROM toolbelt_core.WorkType WHERE WorkTypeName='test.preserve'; DROP PROCEDURE toolbelt_core.USP_TestPreserve;"

central_db=tbx_w4b_central
consumer_db=tbx_w4b_consumer
run_query master "CREATE DATABASE [${central_db}] COLLATE Latin1_General_100_BIN2; CREATE DATABASE [${consumer_db}] COLLATE Latin1_General_100_CS_AS;"
deploy "${central_db}" Modules/toolbelt.core.result-table central
deploy "${central_db}" Modules/toolbelt.core.work-type central
run_file "${consumer_db}" /workspace/Modules/toolbelt.core.work-type/Tests/Runtime Central.Contract.sql -v ToolbeltDatabase="${central_db}"

# Uninstall-Schutz gegen stillen Datenverlust.
run_query "${local_db}" "CREATE OR ALTER PROCEDURE toolbelt_core.USP_TestUninstall AS BEGIN SET NOCOUNT ON; END;"
run_query "${local_db}" "EXEC toolbelt_core.USP_RegisterWorkType @WorkTypeName='test.uninstall', @HandlerSchema=N'toolbelt_core', @HandlerProcedure=N'USP_TestUninstall';"
run_query "${local_db}" "IF NOT EXISTS (SELECT 1 FROM toolbelt_core.WorkType WHERE WorkTypeName='test.uninstall') THROW 52552, N'Die Testzeile fehlt vor dem Data-Loss-Uninstall-Test.', 1;"
set +e
uninstall "${local_db}" Modules/toolbelt.core.work-type 0 0 >/tmp/w4b-uninstall.out 2>&1
uninstall_rc=$?
set -e
cat /tmp/w4b-uninstall.out
if ! grep -q "51549" /tmp/w4b-uninstall.out; then
  echo "Der erwartete Data-Loss-Fehler 51549 fehlt; Exitcode=${uninstall_rc}." >&2
  exit 1
fi
run_query "${local_db}" "IF OBJECT_ID(N'toolbelt_core.WorkType', N'U') IS NULL OR NOT EXISTS (SELECT 1 FROM toolbelt_core.WorkType WHERE WorkTypeName='test.uninstall') THROW 52551, N'Der abgelehnte Uninstall veränderte Katalog oder Testzeile.', 1;"

uninstall "${central_db}" Modules/toolbelt.core.work-type 1 1
uninstall "${central_db}" Modules/toolbelt.core.result-table 1 1
uninstall "${local_db}" Modules/toolbelt.core.work-type 0 1
uninstall "${local_db}" Modules/toolbelt.core.result-table 0 1

echo "W4b Work-Type-Katalog Linux: erfolgreich"
