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
container_name="tbx-table-clone-${GITHUB_RUN_ID:-local}"
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


# Der Lab-Shim adaptiert die lokale CI-Containerkonfiguration ohne Lab-Infrastrukturverwaltung.
deployment_directory="/workspace/Modules/toolbelt.metadata.table-clone/Deployment"
runtime_directory="/workspace/Modules/toolbelt.metadata.table-clone/Tests/Runtime"
expect_failure() {
    local number="$1"; shift
    local failure_output
    if failure_output=$("$@" 2>&1); then
        echo "Erwarteter Lifecyclefehler blieb aus." >&2; exit 1
    fi
    if [[ "$failure_output" != *"Msg ${number},"* ]]; then
        echo "Unerwartete Lifecyclefehlerkategorie." >&2; exit 1
    fi
}
local_database="tbx_table_clone_local"
create_database "${local_database}" "Latin1_General_100_CS_AS"
run_file "${local_database}" "${deployment_directory}" Deploy.sql -v DeploymentMode=local
expect_failure 50000 run_file "${local_database}" "${runtime_directory}" Lifecycle.CallerTransaction.Deploy.sql -v DeploymentMode=local
expect_failure 50000 run_file "${local_database}" "${runtime_directory}" Lifecycle.CallerTransaction.Uninstall.sql -v ConfirmNoExternalConsumers=0
for compatibility_level in ${compatibility_levels}; do
    run_query "${local_database}" "ALTER DATABASE [${local_database}] SET COMPATIBILITY_LEVEL = ${compatibility_level};"
    run_file "${local_database}" "${runtime_directory}" Lifecycle.Contract.sql
    run_file "${local_database}" "${runtime_directory}" TableClone.Contract.sql
done
run_file "${local_database}" "${runtime_directory}" MinimumRights.Contract.sql
run_query "${local_database}" "CREATE TABLE #TBX_TableClone_Plan(UnexpectedColumn int); BEGIN TRY EXEC toolbelt_metadata.USP_ScriptTableClone; THROW 54920,N'Namespaceguard fehlt.',8; END TRY BEGIN CATCH IF ERROR_NUMBER()<>53908 THROW; END CATCH; EXEC toolbelt_metadata.USP_ScriptTableClone @Hilfe=1,@Debug=255,@ResultTable=N'invalid';"
if [[ "${TBX_SQL_TARGET:-runner}" == "lab" ]]; then
    repo_root="$(git rev-parse --show-toplevel)"
    pwsh -NoProfile -File "${repo_root}/Modules/toolbelt.metadata.table-clone/Tests/Runtime/SelectMetadata.Contract.ps1" \
        -Database "${local_database}_${TBX_TEST_DB_SUFFIX}"
fi
# Echter registrierter P->TF-Typdrift und Wiederholungsdeployment.
run_query "${local_database}" "DROP PROCEDURE toolbelt_metadata.USP_ScriptTableClone;"
run_query "${local_database}" "CREATE FUNCTION toolbelt_metadata.USP_ScriptTableClone() RETURNS @r TABLE(Value int) AS BEGIN RETURN; END;"
run_file "${local_database}" "${deployment_directory}" Deploy.sql -v DeploymentMode=local
run_file "${local_database}" "${runtime_directory}" Lifecycle.Contract.sql
run_file "${local_database}" "${runtime_directory}" TableClone.Contract.sql
central_database="tbx_table_clone_central"
consumer_database="tbx_table_clone_consumer"
create_database "${central_database}" "Latin1_General_100_BIN2"
create_database "${consumer_database}" "Latin1_General_100_CI_AS"
run_file "${central_database}" "${deployment_directory}" Deploy.sql -v DeploymentMode=central
run_file "${central_database}" "${runtime_directory}" Lifecycle.Contract.sql
run_file "${central_database}" "${runtime_directory}" TableClone.Contract.sql
run_file "${consumer_database}" "${runtime_directory}" Central.Contract.sql -v ToolbeltDatabase="${central_database}"
expect_failure 53925 run_file "${central_database}" "${deployment_directory}" Uninstall.sql -v ConfirmNoExternalConsumers=0
run_file "${central_database}" "${deployment_directory}" Uninstall.sql -v ConfirmNoExternalConsumers=1
run_query "${local_database}" "CREATE PROCEDURE dbo.SyntheticCloneConsumer AS EXEC toolbelt_metadata.USP_ScriptTableClone @Hilfe=1;"
expect_failure 53926 run_file "${local_database}" "${deployment_directory}" Uninstall.sql -v ConfirmNoExternalConsumers=0
run_query "${local_database}" "DROP PROCEDURE dbo.SyntheticCloneConsumer;"
run_file "${local_database}" "${deployment_directory}" Uninstall.sql -v ConfirmNoExternalConsumers=0
run_file "${local_database}" "${deployment_directory}" Uninstall.sql -v ConfirmNoExternalConsumers=0
run_query "${local_database}" "IF OBJECT_ID(N'toolbelt_metadata.USP_ScriptTableClone') IS NOT NULL OR OBJECT_ID(N'toolbelt_metadata.USP_ScriptTableCloneInternal') IS NOT NULL THROW 54920,N'Uninstall unvollständig.',9;"
run_file "${local_database}" "${deployment_directory}" Deploy.sql -v DeploymentMode=local
run_file "${local_database}" "${runtime_directory}" Lifecycle.Contract.sql
for object_name in USP_ScriptTableClone USP_ScriptTableCloneInternal; do
    collision_database="tbx_table_clone_collision_${object_name}"
    create_database "${collision_database}" "Latin1_General_100_CI_AS"
    foreign_object_name="${object_name,,}"
    run_query "${collision_database}" "CREATE SCHEMA toolbelt_metadata;"
    run_query "${collision_database}" "CREATE PROCEDURE toolbelt_metadata.${foreign_object_name} AS SELECT 1 AS SyntheticForeign;"
    expect_failure 53924 run_file "${collision_database}" "${deployment_directory}" Deploy.sql -v DeploymentMode=local
    run_query "${collision_database}" "IF OBJECT_ID(N'toolbelt_metadata.${object_name}',N'P') IS NULL OR EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.metadata.table-clone.Version') THROW 54920,N'Kollision verändert Fremdbestand.',10;"
done
