#!/usr/bin/env bash
set -euo pipefail

sql_image="${TBX_SQL_IMAGE:?TBX_SQL_IMAGE fehlt}"
sql_version="${TBX_SQL_VERSION:-2025}"
case "${sql_version}" in
  2019) compatibility_level="150" ;;
  2022) compatibility_level="160" ;;
  2025) compatibility_level="170" ;;
  *) echo "Nicht unterstützte SQL-Version: ${sql_version}" >&2; exit 1 ;;
esac

container_name="tbx-q1-${GITHUB_RUN_ID:-local}"
sa_password="Tbx!$(openssl rand -hex 16)Aa1"
if [[ "${GITHUB_ACTIONS:-}" == "true" ]]; then
  echo "::add-mask::${sa_password}"
fi
database="tbx_q1_migration_idempotency"
database_created="0"

run_query() {
  docker exec "${container_name}" "${sqlcmd_path}" \
    -S localhost -U sa -P "${sa_password}" -C -b -d "$1" -Q "$2"
}

cleanup() {
  set +e
  if [[ "${database_created}" == "1" ]]; then
    run_query master \
      "IF DB_ID(N'${database}') IS NOT NULL BEGIN ALTER DATABASE [${database}] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [${database}]; END;" \
      >/dev/null 2>&1
  fi
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
  if run_query master "SELECT 1;" >/dev/null 2>&1; then
    break
  fi
  [[ "${attempt}" -eq 60 ]] \
    && { echo "SQL Server nicht bereit." >&2; exit 1; }
  sleep 2
done

run_query master \
  "CREATE DATABASE [${database}]; ALTER DATABASE [${database}] SET COMPATIBILITY_LEVEL = ${compatibility_level};"
database_created="1"

docker exec --workdir /workspace/Modules/toolbelt.core.generate-series/Deployment \
  "${container_name}" "${sqlcmd_path}" \
  -S localhost -U sa -P "${sa_password}" -C -b -d "${database}" \
  -i /workspace/Tests/Quality/MigrationIdempotency/MigrationIdempotency.Contract.sql \
  -v DeploymentMode=local \
     ConfirmNoExternalConsumers=1 \
     ModuleId=toolbelt.core.generate-series \
     ExpectedVersion=1.0.0 \
     CaptureSnapshotPath=/workspace/Tests/Quality/MigrationIdempotency/CaptureSnapshot.sql \
     DeployScriptPath=/workspace/Modules/toolbelt.core.generate-series/Deployment/Deploy.sql
echo "Q1_RUNNER_PRIMARY_CONTRACT_DONE"

docker exec --workdir /workspace/Modules/toolbelt.core.generate-series/Deployment \
  "${container_name}" "${sqlcmd_path}" \
  -S localhost -U sa -P "${sa_password}" -C -b -d "${database}" \
  -i Uninstall.sql -v ConfirmNoExternalConsumers=1
echo "Q1_RUNNER_FIRST_UNINSTALL_DONE"

docker exec --workdir /workspace/Modules/toolbelt.core.generate-series/Deployment \
  "${container_name}" "${sqlcmd_path}" \
  -S localhost -U sa -P "${sa_password}" -C -b -d "${database}" \
  -i Uninstall.sql -v ConfirmNoExternalConsumers=1
echo "Q1_RUNNER_SECOND_UNINSTALL_DONE"

docker exec --workdir /workspace/Tests/Quality/MigrationIdempotency \
  "${container_name}" "${sqlcmd_path}" \
  -S localhost -U sa -P "${sa_password}" -C -b -d "${database}" \
  -i PostUninstall.Contract.sql -v ModuleId=toolbelt.core.generate-series
echo "Q1_RUNNER_POST_UNINSTALL_DONE"

run_query master \
  "ALTER DATABASE [${database}] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [${database}];"
database_created="0"

echo "Q1 Migration-Idempotency SQL Server ${sql_version} (${compatibility_level}): erfolgreich"
