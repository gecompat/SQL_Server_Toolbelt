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
container_name="tbx-w2a-${GITHUB_RUN_ID:-local}"
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

database="tbx_w2a"
run_query master "CREATE DATABASE [${database}] COLLATE Latin1_General_100_CS_AS;"

deploy_modules() {
  local target_database="$1"
  local mode="$2"
  run_file "${target_database}" \
    /workspace/Modules/toolbelt.datetime.truncate/Deployment \
    Deploy.sql -v DeploymentMode="${mode}"
  run_file "${target_database}" \
    /workspace/Modules/toolbelt.datetime.bucket/Deployment \
    Deploy.sql -v DeploymentMode="${mode}"
  run_file "${target_database}" \
    /workspace/Modules/toolbelt.binary.bit-operations/Deployment \
    Deploy.sql -v DeploymentMode="${mode}"
}

run_lifecycle() {
  local target_database="$1"
  run_file "${target_database}" \
    /workspace/Modules/toolbelt.datetime.truncate/Tests/Runtime \
    Lifecycle.Contract.sql
  run_file "${target_database}" \
    /workspace/Modules/toolbelt.datetime.bucket/Tests/Runtime \
    Lifecycle.Contract.sql
  run_file "${target_database}" \
    /workspace/Modules/toolbelt.binary.bit-operations/Tests/Runtime \
    Lifecycle.Contract.sql
}

deploy_modules "${database}" local
run_lifecycle "${database}"

for level in ${compatibility_levels}; do
  run_query "${database}" \
    "ALTER DATABASE [${database}] SET COMPATIBILITY_LEVEL = ${level};"
  run_file "${database}" \
    /workspace/Modules/toolbelt.datetime.truncate/Tests/Runtime \
    DateTimeTruncate.Contract.sql -v CompatibilityLevel="${level}"
  run_file "${database}" \
    /workspace/Modules/toolbelt.datetime.bucket/Tests/Runtime \
    DateTimeBucket.Contract.sql -v CompatibilityLevel="${level}"
  run_file "${database}" \
    /workspace/Modules/toolbelt.binary.bit-operations/Tests/Runtime \
    BitOperations.Contract.sql -v CompatibilityLevel="${level}"
done

run_file "${database}" \
  /workspace/Modules/toolbelt.datetime.bucket/Tests/Runtime \
  Optimizer.Workload.sql

deploy_modules "${database}" local
run_lifecycle "${database}"

central_database="tbx_w2a_central"
consumer_database="tbx_w2a_consumer"
run_query master \
  "CREATE DATABASE [${central_database}] COLLATE Latin1_General_100_BIN2;"
run_query master \
  "CREATE DATABASE [${consumer_database}] COLLATE Latin1_General_100_CS_AS;"
deploy_modules "${central_database}" central
run_lifecycle "${central_database}"

run_file "${consumer_database}" \
  /workspace/Modules/toolbelt.datetime.truncate/Tests/Runtime \
  Central.Contract.sql -v ToolbeltDatabase="${central_database}"
run_file "${consumer_database}" \
  /workspace/Modules/toolbelt.datetime.bucket/Tests/Runtime \
  Central.Contract.sql -v ToolbeltDatabase="${central_database}"
run_file "${consumer_database}" \
  /workspace/Modules/toolbelt.binary.bit-operations/Tests/Runtime \
  Central.Contract.sql -v ToolbeltDatabase="${central_database}"

run_file "${central_database}" \
  /workspace/Modules/toolbelt.binary.bit-operations/Deployment \
  Uninstall.sql -v ConfirmNoExternalConsumers=1
run_file "${central_database}" \
  /workspace/Modules/toolbelt.datetime.bucket/Deployment \
  Uninstall.sql -v ConfirmNoExternalConsumers=1
run_file "${central_database}" \
  /workspace/Modules/toolbelt.datetime.truncate/Deployment \
  Uninstall.sql -v ConfirmNoExternalConsumers=1

run_query "${central_database}" "
IF OBJECT_ID(N'toolbelt_datetime.TVF_TruncateDate') IS NOT NULL
   OR OBJECT_ID(N'toolbelt_datetime.TVF_TruncateDateTime2') IS NOT NULL
   OR OBJECT_ID(N'toolbelt_datetime.TVF_TruncateDateTimeOffset') IS NOT NULL
   OR OBJECT_ID(N'toolbelt_datetime.TVF_DateBucketDate') IS NOT NULL
   OR OBJECT_ID(N'toolbelt_datetime.TVF_DateBucketDateTime2') IS NOT NULL
   OR OBJECT_ID(N'toolbelt_datetime.TVF_DateBucketDateTimeOffset') IS NOT NULL
   OR OBJECT_ID(N'toolbelt_datetime.TVF_DateBucketCore') IS NOT NULL
   OR OBJECT_ID(N'toolbelt_binary.TVF_LeftShiftBigInt') IS NOT NULL
   OR OBJECT_ID(N'toolbelt_binary.TVF_RightShiftBigInt') IS NOT NULL
   OR OBJECT_ID(N'toolbelt_binary.TVF_BitCountBigInt') IS NOT NULL
   OR OBJECT_ID(N'toolbelt_binary.TVF_GetBitBigInt') IS NOT NULL
   OR OBJECT_ID(N'toolbelt_binary.TVF_SetBitBigInt') IS NOT NULL
    THROW 52899, N'Central Uninstall ließ W2a-Objekte zurück.', 1;"

collision_database=tbx_w2a_collision
run_query master "CREATE DATABASE [${collision_database}] COLLATE Latin1_General_100_CS_AS;"
run_query "${collision_database}" "CREATE SCHEMA toolbelt_datetime;"
run_query "${collision_database}" "CREATE SCHEMA toolbelt_binary;"
run_query "${collision_database}" "CREATE FUNCTION toolbelt_datetime.TVF_TruncateDate(@Value int) RETURNS TABLE AS RETURN SELECT @Value AS ForeignValue;"
run_query "${collision_database}" "CREATE FUNCTION toolbelt_datetime.TVF_DateBucketDate(@Value int) RETURNS TABLE AS RETURN SELECT @Value AS ForeignValue;"
run_query "${collision_database}" "CREATE FUNCTION toolbelt_binary.TVF_LeftShiftBigInt(@Value int) RETURNS TABLE AS RETURN SELECT @Value AS ForeignValue;"

set +e
truncate_collision_output="$(run_file "${collision_database}" /workspace/Modules/toolbelt.datetime.truncate/Deployment Deploy.sql -v DeploymentMode=local 2>&1)"
truncate_collision_rc=$?
bucket_collision_output="$(run_file "${collision_database}" /workspace/Modules/toolbelt.datetime.bucket/Deployment Deploy.sql -v DeploymentMode=local 2>&1)"
bucket_collision_rc=$?
bit_collision_output="$(run_file "${collision_database}" /workspace/Modules/toolbelt.binary.bit-operations/Deployment Deploy.sql -v DeploymentMode=local 2>&1)"
bit_collision_rc=$?
set -e

[[ "${truncate_collision_rc}" -ne 0 && "${truncate_collision_output}" == *"51234"* ]] || { echo 'Truncate-Kollisionspreflight ist fehlgeschlagen.' >&2; exit 1; }
[[ "${bucket_collision_rc}" -ne 0 && "${bucket_collision_output}" == *"51244"* ]] || { echo 'Bucket-Kollisionspreflight ist fehlgeschlagen.' >&2; exit 1; }
[[ "${bit_collision_rc}" -ne 0 && "${bit_collision_output}" == *"51254"* ]] || { echo 'Bit-Operations-Kollisionspreflight ist fehlgeschlagen.' >&2; exit 1; }
run_query "${collision_database}" "IF EXISTS (SELECT 1 FROM sys.extended_properties WHERE class=0 AND name IN (N'Toolbelt.Module.toolbelt.datetime.truncate.Version',N'Toolbelt.Module.toolbelt.datetime.bucket.Version',N'Toolbelt.Module.toolbelt.binary.bit-operations.Version')) THROW 52900,N'Ein abgelehntes W2a-Deployment hinterließ einen Modulmarker.',1;"

echo "W2a SQL Server ${sql_version} (Compatibility ${compatibility_levels}): erfolgreich"
