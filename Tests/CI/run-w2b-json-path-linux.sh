#!/usr/bin/env bash
set -euo pipefail

sql_image="${TBX_SQL_IMAGE:?TBX_SQL_IMAGE fehlt}"
container_name="tbx-w2b-json-${GITHUB_RUN_ID:-local}"
sa_password="Tbx!$(openssl rand -hex 16)Aa1"
echo "::add-mask::${sa_password}"

cleanup() {
  docker rm -f "${container_name}" >/dev/null 2>&1 || true
}
trap cleanup EXIT

docker run --detach \
  --name "${container_name}" \
  --env ACCEPT_EULA=Y \
  --env MSSQL_PID=Developer \
  --env MSSQL_SA_PASSWORD="${sa_password}" \
  --volume "${GITHUB_WORKSPACE:-$(pwd)}:/workspace:ro" \
  "${sql_image}" >/dev/null

sqlcmd_path=""
for candidate in /opt/mssql-tools18/bin/sqlcmd /opt/mssql-tools/bin/sqlcmd; do
  if docker exec "${container_name}" test -x "${candidate}"; then
    sqlcmd_path="${candidate}"
    break
  fi
done
[[ -n "${sqlcmd_path}" ]] || { echo "sqlcmd fehlt." >&2; exit 1; }

for attempt in $(seq 1 60); do
  if docker exec "${container_name}" "${sqlcmd_path}" \
      -S localhost -U sa -P "${sa_password}" -C -b -Q "SELECT 1;" \
      >/dev/null 2>&1; then
    break
  fi
  [[ "${attempt}" -eq 60 ]] \
    && { echo "SQL Server nicht bereit." >&2; exit 1; }
  sleep 2
done

run_file() {
  docker exec --workdir "$2" "${container_name}" "${sqlcmd_path}" \
    -S localhost -U sa -P "${sa_password}" -C -b -d "$1" -i "$3" "${@:4}"
}
run_query() {
  docker exec "${container_name}" "${sqlcmd_path}" \
    -S localhost -U sa -P "${sa_password}" -C -b -d "$1" -Q "$2"
}

database="tbx_w2b_json"
run_query master "CREATE DATABASE [${database}] COLLATE Latin1_General_100_CS_AS;"

deploy_module() {
  local target_database="$1"
  local mode="$2"
  run_file "${target_database}" \
    /workspace/Modules/toolbelt.json.path-exists/Deployment \
    Deploy.sql -v DeploymentMode="${mode}"
}

run_lifecycle() {
  local target_database="$1"
  run_file "${target_database}" \
    /workspace/Modules/toolbelt.json.path-exists/Tests/Runtime \
    Lifecycle.Contract.sql
}

deploy_module "${database}" local
run_lifecycle "${database}"

for level in 150 160 170; do
  run_query "${database}" \
    "ALTER DATABASE [${database}] SET COMPATIBILITY_LEVEL = ${level};"
  run_file "${database}" \
    /workspace/Modules/toolbelt.json.path-exists/Tests/Runtime \
    JsonPathExists.Contract.sql -v CompatibilityLevel="${level}"
done

deploy_module "${database}" local
run_lifecycle "${database}"

central_database="tbx_w2b_json_central"
consumer_database="tbx_w2b_json_consumer"
run_query master \
  "CREATE DATABASE [${central_database}] COLLATE Latin1_General_100_BIN2;"
run_query master \
  "CREATE DATABASE [${consumer_database}] COLLATE Latin1_General_100_CI_AS;"
deploy_module "${central_database}" central
run_lifecycle "${central_database}"

run_file "${consumer_database}" \
  /workspace/Modules/toolbelt.json.path-exists/Tests/Runtime \
  Central.Contract.sql -v ToolbeltDatabase="${central_database}"

run_file "${central_database}" \
  /workspace/Modules/toolbelt.json.path-exists/Deployment \
  Uninstall.sql -v ConfirmNoExternalConsumers=1

run_query "${central_database}" "
IF OBJECT_ID(N'toolbelt_json.TVF_JsonPathExists') IS NOT NULL
    THROW 52999, N'Central Uninstall ließ das JSON-Path-Objekt zurück.', 1;"

echo "W2b JSON Path SQL Server 2025 Linux (Compatibility 150/160/170): erfolgreich"
