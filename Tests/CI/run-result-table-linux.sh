#!/usr/bin/env bash

set -euo pipefail

# Dieser Runner verwendet ausschließlich synthetische Datenbanken und erzeugt
# das Testkennwort flüchtig. Es wird maskiert und nie als Artefakt gespeichert.
sql_image="${TBX_SQL_IMAGE:?TBX_SQL_IMAGE fehlt}"
test_suite="${TBX_TEST_SUITE:?TBX_TEST_SUITE fehlt}"
sql_version="${TBX_SQL_VERSION:?TBX_SQL_VERSION fehlt}"
container_name="tbx-result-table-${sql_version}-${GITHUB_RUN_ID:-local}"
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

deployment_directory="/workspace/Modules/toolbelt.core.result-table/Deployment"
runtime_directory="/workspace/Modules/toolbelt.core.result-table/Tests/Runtime"
local_database="tbx_result_table_local"

create_database "${local_database}" "Latin1_General_100_CS_AS"
run_file "${local_database}" "${deployment_directory}" Deploy.sql \
    -v DeploymentMode=local
run_file "${local_database}" "${runtime_directory}" Lifecycle.Contract.sql

if [[ "${test_suite}" == "full" ]]; then
    run_file "${local_database}" "${runtime_directory}" \
        USP_PrepareResultTable.Contract.sql
    run_file "${local_database}" "${runtime_directory}" \
        Collation.Contract.sql
    run_file "${local_database}" "${runtime_directory}" \
        BoundaryAndTransaction.Contract.sql
    run_file "${local_database}" "${runtime_directory}" \
        SavepointEngineError.Contract.sql

    multi_session_pids=()
    for worker_id in 1 2 3 4; do
        run_file "${local_database}" "${runtime_directory}" \
            MultiSession.Contract.sql -v WorkerId="${worker_id}" &
        multi_session_pids+=("$!")
    done

    multi_session_failed=0
    for worker_pid in "${multi_session_pids[@]}"; do
        if ! wait "${worker_pid}"; then
            multi_session_failed=1
        fi
    done

    if [[ "${multi_session_failed}" -ne 0 ]]; then
        echo "Mindestens ein synthetischer Multi-Session-Worker ist fehlgeschlagen." >&2
        exit 1
    fi

    run_file "${local_database}" "${runtime_directory}" \
        Performance.Workload.sql

    # CREATE OR ALTER durch das Release muss eine lokale Framework-Änderung bei
    # derselben Version bewusst überschreiben.
    run_query "${local_database}" \
        "ALTER PROCEDURE [toolbelt_core].[USP_PrepareResultTable] AS BEGIN SET NOCOUNT ON; RETURN 0; END;"
    run_file "${local_database}" "${deployment_directory}" Deploy.sql \
        -v DeploymentMode=local
    run_file "${local_database}" "${runtime_directory}" Lifecycle.Contract.sql

    central_database="tbx_result_table_central"
    consumer_database="tbx_result_table_consumer"
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
        "IF OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable') IS NOT NULL THROW 52201, N'Central Uninstall ließ das Release-Objekt zurück.', 1;"

    existing_schema_database="tbx_result_table_existing_schema"
    create_database "${existing_schema_database}"
    run_query "${existing_schema_database}" "CREATE SCHEMA [toolbelt_core];"
    run_file "${existing_schema_database}" "${deployment_directory}" Deploy.sql \
        -v DeploymentMode=local
    run_file "${existing_schema_database}" "${deployment_directory}" Uninstall.sql \
        -v ConfirmNoExternalConsumers=0
    run_query "${existing_schema_database}" \
        "IF SCHEMA_ID(N'toolbelt_core') IS NULL THROW 52202, N'Ein vorbestehendes unmarkiertes Schema wurde gelöscht.', 1;"

    collision_database="tbx_result_table_collision"
    create_database "${collision_database}"
    run_query "${collision_database}" "CREATE SCHEMA [toolbelt_core];"
    run_query "${collision_database}" \
        "CREATE PROCEDURE [toolbelt_core].[USP_PrepareResultTable] AS SELECT 1 AS ForeignObject;"

    if run_file "${collision_database}" "${deployment_directory}" Deploy.sql \
        -v DeploymentMode=local; then
        echo "Eine frameworkfremde Zielnamenskollision wurde überschrieben." >&2
        exit 1
    fi

    run_query "${collision_database}" \
        "IF EXISTS (SELECT 1 FROM sys.extended_properties WHERE class = 0 AND name = N'Toolbelt.Module.toolbelt.core.result-table.Version') THROW 52203, N'Kollisions-Preflight hinterließ einen Installationsmarker.', 1;"
else
    run_file "${local_database}" "${runtime_directory}" Compatibility.Smoke.sql
    run_file "${local_database}" "${deployment_directory}" Deploy.sql \
        -v DeploymentMode=local
    run_file "${local_database}" "${runtime_directory}" Lifecycle.Contract.sql
fi

run_file "${local_database}" "${deployment_directory}" Uninstall.sql \
    -v ConfirmNoExternalConsumers=0
run_query "${local_database}" \
    "IF OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable') IS NOT NULL THROW 52204, N'Uninstall ließ das Release-Objekt zurück.', 1;"

echo "ResultTable SQL Server ${sql_version} Linux (${test_suite}): erfolgreich"
