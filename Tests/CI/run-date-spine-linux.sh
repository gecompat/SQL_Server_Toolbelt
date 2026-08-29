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

container_name="tbx-date-spine-${GITHUB_RUN_ID:-local}"
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

deploy_dependencies() {
  local target_database="$1"
  local mode="$2"
  run_file "${target_database}" \
    /workspace/Modules/toolbelt.core.generate-series/Deployment \
    Deploy.sql -v DeploymentMode="${mode}"
  run_file "${target_database}" \
    /workspace/Modules/toolbelt.datetime.truncate/Deployment \
    Deploy.sql -v DeploymentMode="${mode}"
}

deploy_date_spine() {
  local target_database="$1"
  local mode="$2"
  run_file "${target_database}" \
    /workspace/Modules/toolbelt.datetime.date-spine/Deployment \
    Deploy.sql -v DeploymentMode="${mode}"
}

uninstall_date_spine() {
  local target_database="$1"
  local confirmation="$2"
  run_file "${target_database}" \
    /workspace/Modules/toolbelt.datetime.date-spine/Deployment \
    Uninstall.sql -v ConfirmNoExternalConsumers="${confirmation}"
}

uninstall_dependencies() {
  local target_database="$1"
  local confirmation="$2"
  run_file "${target_database}" \
    /workspace/Modules/toolbelt.datetime.truncate/Deployment \
    Uninstall.sql -v ConfirmNoExternalConsumers="${confirmation}"
  run_file "${target_database}" \
    /workspace/Modules/toolbelt.core.generate-series/Deployment \
    Uninstall.sql -v ConfirmNoExternalConsumers="${confirmation}"
}

database="tbx_date_spine"
preflight_database="tbx_date_spine_preflight"
collision_database="tbx_date_spine_collision"
central_database="tbx_date_spine_central"
consumer_database="tbx_date_spine_consumer"

run_query master "CREATE DATABASE [${database}] COLLATE Latin1_General_100_CI_AS;"
deploy_dependencies "${database}" local
deploy_date_spine "${database}" local
run_file "${database}" \
  /workspace/Modules/toolbelt.datetime.date-spine/Tests/Runtime \
  Lifecycle.Contract.sql

for level in ${compatibility_levels}; do
  run_query "${database}" \
    "ALTER DATABASE [${database}] SET COMPATIBILITY_LEVEL = ${level};"
  run_file "${database}" \
    /workspace/Modules/toolbelt.datetime.date-spine/Tests/Runtime \
    DateSpine.Contract.sql -v CompatibilityLevel="${level}"
done

# Wiederholungsdeployment muss Objekt- und Modulzustand erhalten.
deploy_date_spine "${database}" local
run_file "${database}" \
  /workspace/Modules/toolbelt.datetime.date-spine/Tests/Runtime \
  Lifecycle.Contract.sql

# Eine same-database Dependency blockiert Uninstall vor der ersten Mutation.
run_query "${database}" \
  "CREATE VIEW dbo.VW_DateSpineConsumer AS SELECT Ordinal, PeriodStart FROM toolbelt_datetime.TVF_DateSpineDay('20260101','20260102');"
set +e
uninstall_date_spine "${database}" 0 >/dev/null 2>&1
blocked_uninstall_status=$?
set -e
if [[ "${blocked_uninstall_status}" -eq 0 ]]; then
  echo "Date-Spine-Uninstall ignorierte eine Dependency." >&2
  exit 1
fi
run_query "${database}" "DROP VIEW dbo.VW_DateSpineConsumer;"
uninstall_date_spine "${database}" 0
run_query "${database}" "
IF OBJECT_ID(N'toolbelt_datetime.TVF_DateSpineCore') IS NOT NULL
   OR OBJECT_ID(N'toolbelt_datetime.TVF_DateSpineDay') IS NOT NULL
   OR OBJECT_ID(N'toolbelt_datetime.TVF_DateSpineIsoWeek') IS NOT NULL
   OR OBJECT_ID(N'toolbelt_datetime.TVF_DateSpineMonth') IS NOT NULL
    THROW 52968, N'Der lokale Uninstall ließ Date-Spine-Objekte zurück.', 1;
IF OBJECT_ID(N'toolbelt_core.TVF_GenerateSeriesInt', N'IF') IS NULL
   OR OBJECT_ID(N'toolbelt_datetime.TVF_TruncateDate', N'IF') IS NULL
    THROW 52969, N'Der Date-Spine-Uninstall entfernte Dependencies.', 1;"
uninstall_dependencies "${database}" 0

# Fehlende Dependencies dürfen vor der ersten Mutation keine Objekte erzeugen.
run_query master \
  "CREATE DATABASE [${preflight_database}] COLLATE Latin1_General_100_CS_AS;"
set +e
deploy_date_spine "${preflight_database}" local >/dev/null 2>&1
missing_dependency_status=$?
set -e
if [[ "${missing_dependency_status}" -eq 0 ]]; then
  echo "Date-Spine-Deployment akzeptierte fehlende Dependencies." >&2
  exit 1
fi
run_query "${preflight_database}" "
IF SCHEMA_ID(N'toolbelt_datetime') IS NOT NULL
   OR EXISTS (SELECT 1 FROM sys.extended_properties WHERE name LIKE N'Toolbelt.Module.toolbelt.datetime.date-spine.%')
    THROW 52970, N'Der Dependency-Preflight hinterließ Teilzustand.', 1;"

# Ein frameworkfremder Zielname blockiert die gesamte Erstinstallation.
run_query master \
  "CREATE DATABASE [${collision_database}] COLLATE Latin1_General_100_BIN2;"
deploy_dependencies "${collision_database}" local
run_query "${collision_database}" "
CREATE FUNCTION toolbelt_datetime.TVF_DateSpineDay
(
    @RangeStart date,
    @RangeEndExclusive date
)
RETURNS TABLE AS RETURN (SELECT CONVERT(int, 0) AS Ordinal, @RangeStart AS PeriodStart);"
set +e
deploy_date_spine "${collision_database}" local >/dev/null 2>&1
collision_status=$?
set -e
if [[ "${collision_status}" -eq 0 ]]; then
  echo "Date-Spine-Deployment überschrieb einen frameworkfremden Zielnamen." >&2
  exit 1
fi
run_query "${collision_database}" "
IF OBJECT_ID(N'toolbelt_datetime.TVF_DateSpineCore') IS NOT NULL
   OR OBJECT_ID(N'toolbelt_datetime.TVF_DateSpineIsoWeek') IS NOT NULL
   OR OBJECT_ID(N'toolbelt_datetime.TVF_DateSpineMonth') IS NOT NULL
    THROW 52971, N'Der Kollisions-Preflight hinterließ Teilzustand.', 1;
DROP FUNCTION toolbelt_datetime.TVF_DateSpineDay;"
uninstall_dependencies "${collision_database}" 0

# Zentrale Installation und Cross-database-Aufruf unter abweichenden Collations.
run_query master \
  "CREATE DATABASE [${central_database}] COLLATE Latin1_General_100_BIN2;"
run_query master \
  "CREATE DATABASE [${consumer_database}] COLLATE Latin1_General_100_CS_AS;"
deploy_dependencies "${central_database}" central
deploy_date_spine "${central_database}" central
run_file "${central_database}" \
  /workspace/Modules/toolbelt.datetime.date-spine/Tests/Runtime \
  Lifecycle.Contract.sql
run_file "${consumer_database}" \
  /workspace/Modules/toolbelt.datetime.date-spine/Tests/Runtime \
  Central.Contract.sql -v ToolbeltDatabase="${central_database}"
deploy_date_spine "${central_database}" central
uninstall_date_spine "${central_database}" 1
uninstall_dependencies "${central_database}" 1

run_query master "
ALTER DATABASE [${database}] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
DROP DATABASE [${database}];
ALTER DATABASE [${preflight_database}] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
DROP DATABASE [${preflight_database}];
ALTER DATABASE [${collision_database}] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
DROP DATABASE [${collision_database}];
ALTER DATABASE [${consumer_database}] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
DROP DATABASE [${consumer_database}];
ALTER DATABASE [${central_database}] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
DROP DATABASE [${central_database}];"

echo "Date Spine SQL Server ${sql_version} (Compatibility ${compatibility_levels}): erfolgreich"
