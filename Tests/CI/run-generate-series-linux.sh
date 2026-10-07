#!/usr/bin/env bash

set -euo pipefail

# Ausschließlich synthetische Datenbanken und ein flüchtiges, maskiertes
# Testkennwort. Es wird nicht als Artefakt gespeichert.
sql_image="${TBX_SQL_IMAGE:?TBX_SQL_IMAGE fehlt}"
sql_version="${TBX_SQL_VERSION:-2025}"
performance_baseline_milliseconds="${TBX_PERFORMANCE_BASELINE_MEDIAN_MILLISECONDS:-0}"
performance_max_regression_percent="${TBX_PERFORMANCE_MAX_MEDIAN_REGRESSION_PERCENT:-20}"
performance_max_batch_median_variance_percent="${TBX_PERFORMANCE_MAX_BATCH_MEDIAN_VARIANCE_PERCENT:-20}"
run_performance_workload="${TBX_RUN_PERFORMANCE_WORKLOAD:-0}"
case "${sql_version}" in
  2019) compatibility_levels="150"; max_compatibility_level="150" ;;
  2022) compatibility_levels="160"; max_compatibility_level="160" ;;
  2025) compatibility_levels="150 160 170"; max_compatibility_level="170" ;;
  *) echo "Nicht unterstützte SQL-Version: ${sql_version}" >&2; exit 1 ;;
esac
container_name="tbx-generate-series-${GITHUB_RUN_ID:-local}"
if [[ "${TBX_SQL_TARGET:-runner}" != lab ]]; then
    container_name="tbx-generate-series-${sql_version}-${GITHUB_RUN_ID:-$$}-${GITHUB_RUN_ATTEMPT:-1}"
    if [[ ! "${container_name}" =~ ^tbx-generate-series-(2019|2022|2025)-[0-9]+-[0-9]+$ ]]; then
        echo "GENERATE_SERIES_CI_IDENTITY_INVALID" >&2
        exit 1
    fi
fi
sa_password="Tbx!$(openssl rand -hex 16)Aa1"
echo "::add-mask::${sa_password}"

container_owner=""; private_dir=""; container_options=()
if [[ "${TBX_SQL_TARGET:-runner}" != lab ]]; then
    container_owner="$(openssl rand -hex 16)"
    if [[ ! "${container_owner}" =~ ^[0-9a-f]{32}$ ]]; then
        echo "GENERATE_SERIES_CI_OWNER_INVALID" >&2
        exit 1
    fi
    private_dir="$(mktemp -d)"
    container_options=(--label "tbx.generate-series.ci.owner=${container_owner}")
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
        if ! inspection="$(docker inspect --format '{{.Id}} {{ index .Config.Labels "tbx.generate-series.ci.owner" }}' \
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
        echo "GENERATE_SERIES_CI_CLEANUP_UNVERIFIED" >&2
        result=1
    else
        echo "GENERATE_SERIES_CI_CLEANUP_VERIFIED"
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

if [[ -z "${sqlcmd_path}" ]]; then
    echo "sqlcmd fehlt im SQL-Server-Container." >&2
    exit 1
fi

for attempt in $(seq 1 60); do
    if docker exec "${container_name}" "${sqlcmd_path}" \
        -S localhost -U sa -P "${sa_password}" -C -b \
        -Q "SELECT 1;" >/dev/null 2>&1; then
        break
    fi

    if [[ "${attempt}" -eq 60 ]]; then
        docker logs "${container_name}"
        echo "SQL Server wurde nicht rechtzeitig bereit." >&2
        exit 1
    fi

    sleep 2
done

run_query() {
    local database_name="$1"
    local query="$2"

    docker exec "${container_name}" "${sqlcmd_path}" \
        -S localhost -U sa -P "${sa_password}" -C -b \
        -d "${database_name}" -Q "${query}"
}

run_file() {
    local database_name="$1"
    local working_directory="$2"
    local file_name="$3"
    shift 3

    docker exec --workdir "${working_directory}" "${container_name}" \
        "${sqlcmd_path}" \
        -S localhost -U sa -P "${sa_password}" -C -b \
        -d "${database_name}" -i "${file_name}" "$@"
}

create_database() {
    local database_name="$1"
    local collation_name="${2:-}"

    if [[ -n "${collation_name}" ]]; then
        run_query master \
            "CREATE DATABASE [${database_name}] COLLATE ${collation_name};"
    else
        run_query master "CREATE DATABASE [${database_name}];"
    fi
}

deployment_directory="/workspace/Modules/toolbelt.core.generate-series/Deployment"
runtime_directory="/workspace/Modules/toolbelt.core.generate-series/Tests/Runtime"
local_database="tbx_generate_series_local"

create_database "${local_database}" "Latin1_General_100_CS_AS"
run_file "${local_database}" "${deployment_directory}" Deploy.sql \
    -v DeploymentMode=local
run_file "${local_database}" "${runtime_directory}" Lifecycle.Contract.sql

for compatibility_level in ${compatibility_levels}; do
    # Der relationale native Operator muss in einer neuen Session unter dem
    # bereits aktiven Compatibility Level kompiliert werden.
    run_query "${local_database}" \
        "ALTER DATABASE [${local_database}] SET COMPATIBILITY_LEVEL = ${compatibility_level};"
    run_file "${local_database}" "${runtime_directory}" \
        GenerateSeries.Contract.sql \
        -v CompatibilityLevel="${compatibility_level}"
done

if [[ "${run_performance_workload}" == "1" ]]; then
    performance_output="$(mktemp)"
    if ! run_file "${local_database}" "${runtime_directory}" Performance.Workload.sql \
        -v "PerformanceBaselineMedianMilliseconds=${performance_baseline_milliseconds}" \
        -v "PerformanceMaxMedianRegressionPercent=${performance_max_regression_percent}" \
        -v "PerformanceMaxBatchMedianVariancePercent=${performance_max_batch_median_variance_percent}" \
        >"${performance_output}" 2>&1; then
        if grep -q "Msg 52453" "${performance_output}"; then
            rm -f "${performance_output}"
            echo "PERFORMANCE_STABILITY_UNAVAILABLE" >&2
            exit 75
        fi
        cat "${performance_output}" >&2
        rm -f "${performance_output}"
        exit 1
    fi
    rm -f "${performance_output}"
elif [[ "${run_performance_workload}" != "0" ]]; then
    echo "TBX_RUN_PERFORMANCE_WORKLOAD muss 0 oder 1 sein." >&2
    exit 1
fi

# Eine lokale Änderung desselben bekannten Release-Objekts wird beim
# Wiederholungsdeployment durch die kanonische Source ersetzt.
run_query "${local_database}" \
    "ALTER FUNCTION [toolbelt_core].[TVF_GenerateSeriesBigInt] (@Start bigint, @Stop bigint, @Step bigint = NULL) RETURNS TABLE AS RETURN (SELECT CONVERT(bigint, -1) AS Value);"
run_file "${local_database}" "${deployment_directory}" Deploy.sql \
    -v DeploymentMode=local
run_file "${local_database}" "${runtime_directory}" Lifecycle.Contract.sql
run_file "${local_database}" "${runtime_directory}" GenerateSeries.Contract.sql \
    -v CompatibilityLevel="${max_compatibility_level}"

central_database="tbx_generate_series_central"
consumer_database="tbx_generate_series_consumer"
create_database "${central_database}" "Latin1_General_100_BIN2"
create_database "${consumer_database}" "Latin1_General_100_CS_AS"
run_file "${central_database}" "${deployment_directory}" Deploy.sql \
    -v DeploymentMode=central
run_file "${central_database}" "${runtime_directory}" Lifecycle.Contract.sql
run_file "${consumer_database}" "${runtime_directory}" Central.Contract.sql \
    -v ToolbeltDatabase="${central_database}"
run_file "${central_database}" "${deployment_directory}" Uninstall.sql \
    -v ConfirmNoExternalConsumers=1

run_query "${central_database}" \
    "IF OBJECT_ID(N'toolbelt_core.TVF_GenerateSeriesBigInt') IS NOT NULL OR OBJECT_ID(N'toolbelt_core.TVF_GenerateSeriesInt') IS NOT NULL THROW 52440, N'Central Uninstall ließ Release-Objekte zurück.', 1;"

existing_schema_database="tbx_generate_series_existing_schema"
create_database "${existing_schema_database}"
run_query "${existing_schema_database}" \
    "CREATE SCHEMA [toolbelt_core];"
run_file "${existing_schema_database}" "${deployment_directory}" Deploy.sql \
    -v DeploymentMode=local
run_file "${existing_schema_database}" "${deployment_directory}" Uninstall.sql \
    -v ConfirmNoExternalConsumers=0
run_query "${existing_schema_database}" \
    "IF SCHEMA_ID(N'toolbelt_core') IS NULL THROW 52441, N'Ein vorbestehendes unmarkiertes Schema wurde gelöscht.', 1;"

collision_database="tbx_generate_series_collision"
create_database "${collision_database}"
run_query "${collision_database}" \
    "CREATE SCHEMA [toolbelt_core];"
run_query "${collision_database}" \
    "CREATE FUNCTION [toolbelt_core].[TVF_GenerateSeriesBigInt] (@Start bigint, @Stop bigint, @Step bigint = NULL) RETURNS TABLE AS RETURN (SELECT CONVERT(bigint, 1) AS Value);"

# Ein beliebiger Fehler ist kein Kollisionsnachweis. Beide Ausgabekanäle
# bleiben im Speicher; nur Fehlerstatus UND die vollständige Kategorie zählen.
set +e
collision_output="$(run_file "${collision_database}" "${deployment_directory}" Deploy.sql \
    -v DeploymentMode=local 2>&1)"
collision_result=$?
set -e
if [[ "${collision_result}" -eq 0 ]] \
    || ! grep -Eq '(^|[^0-9])51054([^0-9]|$)' <<<"${collision_output}"; then
    echo "Generate-Series-Kollision wurde nicht mit Fehler 51054 abgelehnt." >&2
    exit 1
fi
unset collision_output
echo "GENERATE_SERIES_COLLISION_VERIFIED"

run_query "${collision_database}" \
    "IF EXISTS (SELECT 1 FROM sys.extended_properties WHERE class = 0 AND name = N'Toolbelt.Module.toolbelt.core.generate-series.Version') THROW 52442, N'Kollisions-Preflight hinterließ einen Installationsmarker.', 1;"

run_file "${local_database}" "${deployment_directory}" Uninstall.sql \
    -v ConfirmNoExternalConsumers=0
run_query "${local_database}" \
    "IF OBJECT_ID(N'toolbelt_core.TVF_GenerateSeriesBigInt') IS NOT NULL OR OBJECT_ID(N'toolbelt_core.TVF_GenerateSeriesInt') IS NOT NULL THROW 52443, N'Uninstall ließ Release-Objekte zurück.', 1;"

echo "Generate-Series SQL Server ${sql_version} (Compatibility ${compatibility_levels}): erfolgreich"
