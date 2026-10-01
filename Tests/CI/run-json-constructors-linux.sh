#!/usr/bin/env bash

set -euo pipefail

# Ausschließlich synthetische Datenbanken und ein flüchtiges, maskiertes
# Testkennwort. Es wird nicht als Artefakt gespeichert.
sql_image="${TBX_SQL_IMAGE:?TBX_SQL_IMAGE fehlt}"
sql_version="${TBX_SQL_VERSION:-2025}"
case "${sql_version}" in
  2019) compatibility_levels="150"; max_compatibility_level="150" ;;
  2022) compatibility_levels="160"; max_compatibility_level="160" ;;
  2025) compatibility_levels="150 160 170"; max_compatibility_level="170" ;;
  *) echo "Nicht unterstützte SQL-Version: ${sql_version}" >&2; exit 1 ;;
esac
container_name="tbx-json-constructors-${GITHUB_RUN_ID:-local}"
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
    run_file "${database_name}" "/workspace/Modules/toolbelt.core.result-table/Deployment" Deploy.sql -v DeploymentMode=local
}


deployment_directory="/workspace/Modules/toolbelt.json.constructors/Deployment"
runtime_directory="/workspace/Modules/toolbelt.json.constructors/Tests/Runtime"
expect_failure() {
    local expected_number="$1"
    shift
    local failure_output
    # Nur flüchtiger Speicher; niemals vollständige Diagnostik/Verbindung ausgeben.
    if failure_output=$("$@" 2>&1); then
        echo "Expected SQL failure was absent." >&2; exit 1
    fi
    if [[ "${failure_output}" != *"Msg ${expected_number},"* ]]; then
        echo "Unexpected SQL error category." >&2; exit 1
    fi
}
local_database="tbx_json_constructor_local"
central_database="tbx_json_constructor_central"
consumer_database="tbx_json_constructor_consumer"
for db in "${local_database}" "${central_database}" "${consumer_database}"; do
    create_database "${db}" "Latin1_General_100_CI_AS"
done
run_file "${local_database}" "${deployment_directory}" Deploy.sql -v DeploymentMode=local
run_file "${local_database}" "${runtime_directory}" Lifecycle.Contract.sql
run_file "${local_database}" "${runtime_directory}" JsonConstructors.Contract.sql
if [[ "${TBX_SQL_TARGET:-runner}" == "lab" ]]; then
    repo_root="$(git rev-parse --show-toplevel)"
    pwsh -NoProfile -File "${repo_root}/Modules/toolbelt.json.constructors/Tests/Runtime/SelectMetadata.Contract.ps1" \
        -Database "${local_database}_${TBX_TEST_DB_SUFFIX}"
fi
run_file "${local_database}" "${deployment_directory}" Deploy.sql -v DeploymentMode=local
run_file "${local_database}" "${runtime_directory}" Lifecycle.Contract.sql
run_file "${central_database}" "${deployment_directory}" Deploy.sql -v DeploymentMode=central
run_query "${local_database}" "DROP PROCEDURE toolbelt_json.USP_JsonArray;"
run_query "${local_database}" "CREATE FUNCTION toolbelt_json.USP_JsonArray() RETURNS @r TABLE(Drift int) AS BEGIN INSERT @r VALUES(7); RETURN; END;"
run_file "${local_database}" "${deployment_directory}" Deploy.sql -v DeploymentMode=local
run_file "${local_database}" "${runtime_directory}" Lifecycle.Contract.sql
run_query "${local_database}" "CREATE TABLE #DriftInput(Ordinal int,ValueKind nvarchar(max),[Value] nvarchar(max)); EXEC toolbelt_json.USP_JsonArray @EntriesTable=N'#DriftInput';"
case_database="tbx_json_constructor_case_sensitive"
create_database "${case_database}" "Latin1_General_100_CS_AS"
run_file "${case_database}" "${deployment_directory}" Deploy.sql -v DeploymentMode=local
run_file "${case_database}" "${runtime_directory}" Collation.Contract.sql
run_file "${local_database}" "${runtime_directory}" Collation.Contract.sql
run_file "${central_database}" "${runtime_directory}" JsonConstructors.Contract.sql
run_file "${central_database}" "${runtime_directory}" Lifecycle.Contract.sql
run_file "${consumer_database}" "${runtime_directory}" Central.Contract.sql -v ToolbeltDatabase="${central_database}"
run_query "${local_database}" "CREATE USER TbxJsonCaller WITHOUT LOGIN; GRANT EXECUTE ON OBJECT::toolbelt_json.USP_JsonArray TO TbxJsonCaller; GRANT EXECUTE ON OBJECT::toolbelt_json.USP_JsonObject TO TbxJsonCaller; GRANT EXECUTE ON OBJECT::toolbelt_core.USP_PrepareResultTable TO TbxJsonCaller;"
run_file "${local_database}" "${runtime_directory}" MinimumRights.Contract.sql
run_query "${local_database}" "DROP USER TbxJsonCaller;"
run_query "${local_database}" "CREATE PROCEDURE dbo.USP_SyntheticJsonConsumer AS EXEC toolbelt_json.USP_JsonArray @Hilfe=1;"
expect_failure 53626 run_file "${local_database}" "${deployment_directory}" Uninstall.sql -v ConfirmNoExternalConsumers=0
run_file "${local_database}" "${runtime_directory}" Lifecycle.Contract.sql
run_query "${local_database}" "DROP PROCEDURE dbo.USP_SyntheticJsonConsumer;"
for name in USP_JsonArray USP_JsonObject USP_JsonConstructInternal; do
    collision_database="tbx_json_collision_${name}"
    create_database "${collision_database}" "Latin1_General_100_CI_AS"
    run_query "${collision_database}" "CREATE SCHEMA toolbelt_json;"
    run_query "${collision_database}" "CREATE PROCEDURE toolbelt_json.${name} AS SELECT 7 AS SyntheticForeign;"
    expect_failure 53624 run_file "${collision_database}" "${deployment_directory}" Deploy.sql -v DeploymentMode=local
    run_query "${collision_database}" "IF OBJECT_DEFINITION(OBJECT_ID(N'toolbelt_json.${name}')) NOT LIKE N'%SyntheticForeign%' OR EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.json.constructors.Version') THROW 54600,N'Collision mutated foreign state.',47;"
done
run_file "${local_database}" "${deployment_directory}" Uninstall.sql -v ConfirmNoExternalConsumers=0
run_file "${central_database}" "${deployment_directory}" Uninstall.sql -v ConfirmNoExternalConsumers=1
run_file "${local_database}" "${deployment_directory}" Uninstall.sql -v ConfirmNoExternalConsumers=0
run_file "${local_database}" "${deployment_directory}" Deploy.sql -v DeploymentMode=local
run_file "${local_database}" "${runtime_directory}" Lifecycle.Contract.sql
echo "JSON Constructors adapter: local/central/contract/lifecycle PASS."
