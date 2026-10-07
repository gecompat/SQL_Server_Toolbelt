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
if [[ "${TBX_SQL_TARGET:-runner}" != lab ]]; then
    container_name="tbx-table-clone-${GITHUB_RUN_ID:-$$}-${GITHUB_RUN_ATTEMPT:-1}-${sql_version}"
    if [[ ! "${container_name}" =~ ^tbx-table-clone-[0-9]+-[0-9]+-(2019|2022|2025)$ ]]; then
        echo "TABLE_CLONE_CI_IDENTITY_INVALID" >&2
        exit 1
    fi
fi
legacy_directory="${RUNNER_TEMP:-${TMPDIR:-/tmp}}/tbx-clone-v1-${GITHUB_RUN_ID:-local}"
pwsh -NoProfile -File Modules/toolbelt.metadata.table-clone/Deployment/New-LegacyTestArtifacts.ps1 -OutputDirectory "${legacy_directory}"
sa_password="Tbx!$(openssl rand -hex 16)Aa1"

echo "::add-mask::${sa_password}"

container_owner=""; private_dir=""; container_options=()
if [[ "${TBX_SQL_TARGET:-runner}" != lab ]]; then
    container_owner="$(openssl rand -hex 16)"
    if [[ ! "${container_owner}" =~ ^[0-9a-f]{32}$ ]]; then
        echo "TABLE_CLONE_CI_OWNER_INVALID" >&2
        exit 1
    fi
    private_dir="$(mktemp -d)"
    container_options=(--label "tbx.table-clone.ci.owner=${container_owner}")
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
        if ! inspection="$(docker inspect --format '{{.Id}} {{ index .Config.Labels "tbx.table-clone.ci.owner" }}' \
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
        echo "TABLE_CLONE_CI_CLEANUP_UNVERIFIED" >&2
        result=1
    else
        echo "TABLE_CLONE_CI_CLEANUP_VERIFIED"
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
    --volume "${legacy_directory}:/legacy:ro" \
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
    run_file "${local_database}" "${runtime_directory}" Wave1.Contract.sql
    run_file "${local_database}" "${runtime_directory}" Wave1.DateTimeOffset.sql
    run_file "${local_database}" "${runtime_directory}" Wave2.Contract.sql
    run_file "${local_database}" "${runtime_directory}" Wave2.Safety.sql
    run_file "${local_database}" "${runtime_directory}" Wave2.Caps.sql
done
# Neue Executorverträge einmal auf dem höchsten unterstützten CL je Ziel;
# keine erneute Executor-CL-Schleife oder Wiederholung historischer Grenzfixtures.
run_file "${local_database}" "${runtime_directory}" Execute.Contract.sql
run_file "${local_database}" "${runtime_directory}" Execute.Safety.sql
# Fünf neue Copy-Gruppen genau einmal auf dem höchsten Ziel-CL; keine alte Vollmatrix erneut.
run_file "${local_database}" "${runtime_directory}" Copy.Contract.sql
run_file "${local_database}" "${runtime_directory}" Copy.Safety.sql
run_file "${local_database}" "${runtime_directory}" MinimumRights.Contract.sql
# Neue Byte- und Predicategrenzen einmal lokal; keine doppelte Vollmatrix.
run_file "${local_database}" "${runtime_directory}" Wave1.Bytes.sql
run_file "${local_database}" "${runtime_directory}" Wave1.PermissionPredicate.sql
run_query "${local_database}" "CREATE TABLE #TBX_TableClone_Plan(UnexpectedColumn int); BEGIN TRY EXEC toolbelt_metadata.USP_ScriptTableClone; THROW 54920,N'Namespaceguard fehlt.',8; END TRY BEGIN CATCH IF ERROR_NUMBER()<>53908 THROW; END CATCH; EXEC toolbelt_metadata.USP_ScriptTableClone @Hilfe=1,@Debug=255,@ResultTable=N'invalid';"
if [[ "${TBX_SQL_TARGET:-runner}" == "lab" ]]; then
    repo_root="$(git rev-parse --show-toplevel)"
    pwsh -NoProfile -File "${repo_root}/Modules/toolbelt.metadata.table-clone/Tests/Runtime/SelectMetadata.Contract.ps1" \
        -Database "${local_database}_${TBX_TEST_DB_SUFFIX}"
fi
# Wrong-kind bleibt trotz imitierter Id/Version unangetastet; danach explizite eigene Fixture-Restaurierung.
run_query "${local_database}" "DROP PROCEDURE toolbelt_metadata.USP_ScriptTableClone;"
run_query "${local_database}" "CREATE FUNCTION toolbelt_metadata.USP_ScriptTableClone() RETURNS @r TABLE(Value int) AS BEGIN RETURN; END;"
run_query "${local_database}" "EXEC sys.sp_addextendedproperty @name=N'Toolbelt.ModuleId',@value=N'toolbelt.metadata.table-clone',@level0type=N'SCHEMA',@level0name=N'toolbelt_metadata',@level1type=N'FUNCTION',@level1name=N'USP_ScriptTableClone'; EXEC sys.sp_addextendedproperty @name=N'Toolbelt.ModuleVersion',@value=N'4.1.0',@level0type=N'SCHEMA',@level0name=N'toolbelt_metadata',@level1type=N'FUNCTION',@level1name=N'USP_ScriptTableClone';"
expect_failure 53923 run_file "${local_database}" "${deployment_directory}" Deploy.sql -v DeploymentMode=local
run_query "${local_database}" "IF OBJECT_ID(N'toolbelt_metadata.USP_ScriptTableClone',N'TF') IS NULL THROW 54920,N'Wrong-kind wurde verändert.',11; DROP FUNCTION toolbelt_metadata.USP_ScriptTableClone;"
run_file "${local_database}" "/workspace/Modules/toolbelt.metadata.table-clone/Source" USP_ScriptTableClone.sql
run_query "${local_database}" "EXEC sys.sp_addextendedproperty @name=N'Toolbelt.ModuleId',@value=N'toolbelt.metadata.table-clone',@level0type=N'SCHEMA',@level0name=N'toolbelt_metadata',@level1type=N'PROCEDURE',@level1name=N'USP_ScriptTableClone'; EXEC sys.sp_addextendedproperty @name=N'Toolbelt.ModuleVersion',@value=N'4.1.0',@level0type=N'SCHEMA',@level0name=N'toolbelt_metadata',@level1type=N'PROCEDURE',@level1name=N'USP_ScriptTableClone';"
run_query "${local_database}" "EXEC sys.sp_addextendedproperty @name=N'Toolbelt.DeploymentMode',@value=N'local',@level0type=N'SCHEMA',@level0name=N'toolbelt_metadata',@level1type=N'PROCEDURE',@level1name=N'USP_ScriptTableClone';"
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
run_file "${central_database}" "${runtime_directory}" Wave1.Contract.sql
run_file "${central_database}" "${runtime_directory}" Wave1.DateTimeOffset.sql
run_file "${central_database}" "${runtime_directory}" Wave2.Contract.sql
run_file "${central_database}" "${runtime_directory}" Wave2.Safety.sql
run_file "${central_database}" "${runtime_directory}" Wave1.PermissionPredicate.sql
run_file "${consumer_database}" "${runtime_directory}" Central.Contract.sql -v ToolbeltDatabase="${central_database}"
expect_failure 53925 run_file "${central_database}" "${deployment_directory}" Uninstall.sql -v ConfirmNoExternalConsumers=0
run_file "${central_database}" "${deployment_directory}" Uninstall.sql -v ConfirmNoExternalConsumers=1
run_query "${local_database}" "CREATE PROCEDURE dbo.SyntheticCloneConsumer AS EXEC toolbelt_metadata.USP_ScriptTableClone @Hilfe=1;"
expect_failure 53926 run_file "${local_database}" "${deployment_directory}" Uninstall.sql -v ConfirmNoExternalConsumers=0
run_query "${local_database}" "DROP PROCEDURE dbo.SyntheticCloneConsumer;"
run_file "${local_database}" "${deployment_directory}" Uninstall.sql -v ConfirmNoExternalConsumers=0
run_file "${local_database}" "${deployment_directory}" Uninstall.sql -v ConfirmNoExternalConsumers=0
run_query "${local_database}" "IF OBJECT_ID(N'toolbelt_metadata.USP_ScriptTableClone') IS NOT NULL OR OBJECT_ID(N'toolbelt_metadata.USP_ScriptTableCloneInternal') IS NOT NULL OR OBJECT_ID(N'toolbelt_metadata.USP_ExecuteTableClone') IS NOT NULL OR OBJECT_ID(N'toolbelt_metadata.USP_CopyTableCloneData') IS NOT NULL THROW 54920,N'Uninstall unvollständig.',9;"
run_file "${local_database}" "${deployment_directory}" Deploy.sql -v DeploymentMode=local
run_file "${local_database}" "${runtime_directory}" Lifecycle.Contract.sql
for object_name in USP_ScriptTableClone USP_ScriptTableCloneInternal USP_ExecuteTableClone USP_CopyTableCloneData; do
    collision_database="tbx_table_clone_collision_${object_name}"
    create_database "${collision_database}" "Latin1_General_100_CI_AS"
    foreign_object_name="${object_name,,}"
    run_query "${collision_database}" "CREATE SCHEMA toolbelt_metadata;"
    run_query "${collision_database}" "CREATE PROCEDURE toolbelt_metadata.${foreign_object_name} AS SELECT 1 AS SyntheticForeign;"
    expect_failure 53924 run_file "${collision_database}" "${deployment_directory}" Deploy.sql -v DeploymentMode=local
    run_query "${collision_database}" "IF OBJECT_ID(N'toolbelt_metadata.${object_name}',N'P') IS NULL OR EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.metadata.table-clone.Version') THROW 54920,N'Kollision verändert Fremdbestand.',10;"
done

# Genuine1.0 wurde unverändert aus dem öffentlichen Pin gewonnen.
legacy_database="tbx_table_clone_legacy"
create_database "${legacy_database}" "Latin1_General_100_CS_AS"
run_file "${legacy_database}" "/legacy/Deployment" Deploy.sql -v DeploymentMode=local
run_query "${legacy_database}" "IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.metadata.table-clone.Version' AND CONVERT(nvarchar(64),value)=N'1.0.0') OR (SELECT COUNT(*) FROM sys.parameters WHERE object_id=OBJECT_ID(N'toolbelt_metadata.USP_ScriptTableClone'))<>9 THROW 54920,N'Genuine V1 metadata fehlt.',20; EXEC toolbelt_metadata.USP_ScriptTableClone @Hilfe=1;"
run_file "${legacy_database}" "${deployment_directory}" Deploy.sql -v DeploymentMode=local
run_file "${legacy_database}" "${runtime_directory}" Lifecycle.Contract.sql
run_file "${legacy_database}" "${runtime_directory}" Wave1.Contract.sql
run_file "${legacy_database}" "${runtime_directory}" Wave1.PermissionPredicate.sql
run_file "${legacy_database}" "${deployment_directory}" Uninstall.sql -v ConfirmNoExternalConsumers=0
