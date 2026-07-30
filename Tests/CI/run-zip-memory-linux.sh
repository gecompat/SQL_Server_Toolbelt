#!/usr/bin/env bash
set -euo pipefail

sql_image="${TBX_SQL_IMAGE:?TBX_SQL_IMAGE fehlt}"
container_name="tbx-zip-memory-${GITHUB_RUN_ID:-local}"
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

deploy_result_table() {
  local target_database="$1"
  local mode="$2"
  run_file "${target_database}" \
    /workspace/Modules/toolbelt.core.result-table/Deployment \
    Deploy.sql -v DeploymentMode="${mode}"
}

deploy_zip_memory() {
  local target_database="$1"
  local mode="$2"
  run_file "${target_database}" \
    /workspace/Modules/toolbelt.archive.zip-memory/Deployment \
    Deploy.sql -v DeploymentMode="${mode}"
}

database="tbx_zip_memory"
run_query master "CREATE DATABASE [${database}] COLLATE Latin1_General_100_CS_AS;"

deploy_result_table "${database}" local
deploy_zip_memory "${database}" local

run_file "${database}" \
  /workspace/Modules/toolbelt.archive.zip-memory/Tests/Runtime \
  Lifecycle.Contract.sql

for level in 150 160 170; do
  run_query "${database}" \
    "ALTER DATABASE [${database}] SET COMPATIBILITY_LEVEL = ${level};"
  run_file "${database}" \
    /workspace/Modules/toolbelt.archive.zip-memory/Tests/Runtime \
    ZipMemory.Contract.sql -v CompatibilityLevel="${level}"
done

deploy_zip_memory "${database}" local

central_database="tbx_zip_memory_central"
consumer_database="tbx_zip_memory_consumer"
run_query master "CREATE DATABASE [${central_database}] COLLATE Latin1_General_100_BIN2;"
run_query master "CREATE DATABASE [${consumer_database}] COLLATE Latin1_General_100_CI_AS;"

deploy_result_table "${central_database}" central
deploy_zip_memory "${central_database}" central

run_file "${consumer_database}" \
  /workspace/Modules/toolbelt.archive.zip-memory/Tests/Runtime \
  Central.Contract.sql -v ToolbeltDatabase="${central_database}"

run_file "${central_database}" \
  /workspace/Modules/toolbelt.archive.zip-memory/Deployment \
  Uninstall.sql -v ConfirmNoExternalConsumers=1
run_file "${central_database}" \
  /workspace/Modules/toolbelt.core.result-table/Deployment \
  Uninstall.sql -v ConfirmNoExternalConsumers=1

run_query "${central_database}" "
IF OBJECT_ID(N'toolbelt_archive.USP_ExtractZipEntryFromBinary') IS NOT NULL
    THROW 51389, N'Central Uninstall liess ZIP-Memory-Objekte zurueck.', 1;"

run_file "${database}" \
  /workspace/Modules/toolbelt.archive.zip-memory/Deployment \
  Uninstall.sql -v ConfirmNoExternalConsumers=0
run_file "${database}" \
  /workspace/Modules/toolbelt.core.result-table/Deployment \
  Uninstall.sql -v ConfirmNoExternalConsumers=0

run_query "${database}" "
IF OBJECT_ID(N'toolbelt_archive.USP_ExtractZipEntryFromBinary') IS NOT NULL
    THROW 51389, N'Lokaler Uninstall liess ZIP-Memory-Objekte zurueck.', 1;"

echo "ZIP-Memory SQL Server 2025 Linux (Compatibility 150/160/170): erfolgreich"
