#!/usr/bin/env bash

set -euo pipefail

# Ausschließlich synthetische Datenbanken und ein flüchtiges, maskiertes
# Testkennwort. Es wird nicht als Artefakt gespeichert.
sql_image="${TBX_SQL_IMAGE:?TBX_SQL_IMAGE fehlt}"
sql_version="${TBX_SQL_VERSION:-2025}"
case "${sql_version}" in
  2019) compatibility_levels="150" ;;
  2022) compatibility_levels="160" ;;
  2025) compatibility_levels="150 160 170" ;;
  *) echo "Nicht unterstützte SQL-Version: ${sql_version}" >&2; exit 1 ;;
esac
container_name="tbx-date-spine-${GITHUB_RUN_ID:-local}"
if [[ "${TBX_SQL_TARGET:-runner}" != lab ]]; then
    container_name="tbx-date-spine-${sql_version}-${GITHUB_RUN_ID:-$$}-${GITHUB_RUN_ATTEMPT:-1}"
    if [[ ! "${container_name}" =~ ^tbx-date-spine-(2019|2022|2025)-[0-9]+-[0-9]+$ ]]; then
        echo "DATE_SPINE_CI_IDENTITY_INVALID" >&2
        exit 1
    fi
fi
sa_password="Tbx!$(openssl rand -hex 16)Aa1"
echo "::add-mask::${sa_password}"

container_owner=""; private_dir=""; container_options=()
if [[ "${TBX_SQL_TARGET:-runner}" != lab ]]; then
    container_owner="$(openssl rand -hex 16)"
    if [[ ! "${container_owner}" =~ ^[0-9a-f]{32}$ ]]; then
        echo "DATE_SPINE_CI_OWNER_INVALID" >&2
        exit 1
    fi
    private_dir="$(mktemp -d)"
    container_options=(--label "tbx.date-spine.ci.owner=${container_owner}")
fi

cleanup() {
    local result=$? inspection="" container_id="" owner="" cleanup_verified=true
    trap - EXIT
    # Der bestehende Lab-Shim hat keinen Container und behandelt rm als No-op.
    # Seine eigene Datenbankbereinigung bleibt beim separaten Labtreiber.
    if [[ "${TBX_SQL_TARGET:-runner}" == lab ]]; then
        docker rm -f "${container_name}" >/dev/null 2>&1 || true
        exit "${result}"
    fi
    # Name und Owner identifizieren ausschließlich unseren flüchtigen Scope.
    # ID und Label aus derselben Aufnahme binden den DROP auch bei Namensaustausch.
    if ! docker container ls --all --filter "name=^/${container_name}$" \
        --format '{{.Names}}' >"${private_dir}/owned-containers" 2>/dev/null; then
        cleanup_verified=false
    elif [[ -s "${private_dir}/owned-containers" ]]; then
        if ! inspection="$(docker inspect --format '{{.Id}} {{ index .Config.Labels "tbx.date-spine.ci.owner" }}' \
            "${container_name}" 2>/dev/null)" || [[ ! "${inspection}" =~ ^([0-9a-f]{64})\ ([0-9a-f]{32})$ ]]; then
            cleanup_verified=false
        else
            container_id="${BASH_REMATCH[1]}"; owner="${BASH_REMATCH[2]}"
            if [[ "${owner}" != "${container_owner}" ]]; then
                cleanup_verified=false
            elif ! docker rm -f "${container_id}" >/dev/null 2>&1; then
                cleanup_verified=false
            fi
        fi
    fi
    if ! docker container ls --all --filter "name=^/${container_name}$" \
        --format '{{.Names}}' >"${private_dir}/owned-containers" 2>/dev/null \
        || [[ -s "${private_dir}/owned-containers" ]]; then
        cleanup_verified=false
    fi
    if ! rm -rf -- "${private_dir}"; then
        cleanup_verified=false
    fi
    if [[ "${cleanup_verified}" != true ]]; then
        echo "DATE_SPINE_CI_CLEANUP_UNVERIFIED" >&2
        result=1
    else
        echo "DATE_SPINE_CI_CLEANUP_VERIFIED"
    fi
    exit "${result}"
}


trap cleanup EXIT

docker run --detach \
  --name "${container_name}" \
  "${container_options[@]}" \
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
# Ein beliebiger Fehler ist kein Ablehnungsnachweis. Beide Rohkanäle
# bleiben im Speicher; Fehlerstatus UND die vollständige Kategorie sind nötig.
set +e
blocked_uninstall_output="$(uninstall_date_spine "${database}" 0 2>&1)"
blocked_uninstall_status=$?
set -e
if [[ "${blocked_uninstall_status}" -eq 0 ]] \
    || ! grep -Eq '(^|[^0-9])51806([^0-9]|$)' <<<"${blocked_uninstall_output}"; then
    echo "Date-Spine-Uninstall wurde nicht mit Fehler 51806 abgelehnt." >&2
    exit 1
fi
unset blocked_uninstall_output
echo "DATE_SPINE_UNINSTALL_VERIFIED"
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
# Ein beliebiger Fehler ist kein Ablehnungsnachweis. Beide Rohkanäle
# bleiben im Speicher; Fehlerstatus UND die vollständige Kategorie sind nötig.
set +e
missing_dependency_output="$(deploy_date_spine "${preflight_database}" local 2>&1)"
missing_dependency_status=$?
set -e
if [[ "${missing_dependency_status}" -eq 0 ]] \
    || ! grep -Eq '(^|[^0-9])51809([^0-9]|$)' <<<"${missing_dependency_output}"; then
    echo "Date-Spine-Dependency wurde nicht mit Fehler 51809 abgelehnt." >&2
    exit 1
fi
unset missing_dependency_output
echo "DATE_SPINE_DEPENDENCY_VERIFIED"
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
# Ein beliebiger Fehler ist kein Ablehnungsnachweis. Beide Rohkanäle
# bleiben im Speicher; Fehlerstatus UND die vollständige Kategorie sind nötig.
set +e
collision_output="$(deploy_date_spine "${collision_database}" local 2>&1)"
collision_status=$?
set -e
if [[ "${collision_status}" -eq 0 ]] \
    || ! grep -Eq '(^|[^0-9])51804([^0-9]|$)' <<<"${collision_output}"; then
    echo "Date-Spine-Kollision wurde nicht mit Fehler 51804 abgelehnt." >&2
    exit 1
fi
unset collision_output
echo "DATE_SPINE_COLLISION_VERIFIED"
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
