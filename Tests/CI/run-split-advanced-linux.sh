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
container_name="tbx-split-advanced-${GITHUB_RUN_ID:-local}"
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


deployment_directory="/workspace/Modules/toolbelt.string.split-advanced/Deployment"
runtime_directory="/workspace/Modules/toolbelt.string.split-advanced/Tests/Runtime"
local_database="tbx_split_advanced_local"
create_database "${local_database}" "Latin1_General_100_CS_AS"
run_file "${local_database}" "${deployment_directory}" Deploy.sql -v DeploymentMode=local
run_file "${local_database}" "${runtime_directory}" Lifecycle.Contract.sql
for compatibility_level in ${compatibility_levels}; do
    run_query "${local_database}" "ALTER DATABASE [${local_database}] SET COMPATIBILITY_LEVEL = ${compatibility_level};"
    run_file "${local_database}" "${runtime_directory}" SplitAdvanced.Contract.sql
run_file "${local_database}" "${runtime_directory}" UnquoteToken.Contract.sql
run_file "${local_database}" "${runtime_directory}" SplitAdvancedUsp.Contract.sql
done

# Gleiches Release wird bei lokalem Drift erneut vollständig ersetzt.
run_file "${local_database}" "${runtime_directory}" MinimumRights.Contract.sql
if [[ "${TBX_SQL_TARGET:-runner}" == "lab" ]]; then
    repo_root="$(git rev-parse --show-toplevel)"
    pwsh -NoProfile -File "${repo_root}/Modules/toolbelt.string.split-advanced/Tests/Runtime/SelectMetadata.Contract.ps1" \
        -Database "${local_database}_${TBX_TEST_DB_SUFFIX}"
fi

# Gleiches Release wird bei lokalem Drift erneut vollständig ersetzt.
run_query "${local_database}" "ALTER FUNCTION toolbelt_string.TVF_SplitAdvanced (@Input nvarchar(max), @SeparatorsJson nvarchar(max), @Quote nvarchar(max)=N'', @Escape nvarchar(max)=N'', @KeepEmpty bit=1) RETURNS @r TABLE (Value nvarchar(max),Ordinal bigint,IsValid bit,ErrorCode varchar(64),ErrorPosition bigint) AS BEGIN INSERT @r VALUES(N'drift',1,1,NULL,NULL); RETURN; END;"
run_file "${local_database}" "${deployment_directory}" Deploy.sql -v DeploymentMode=local
run_file "${local_database}" "${runtime_directory}" Lifecycle.Contract.sql
run_file "${local_database}" "${runtime_directory}" SplitAdvanced.Contract.sql
run_file "${local_database}" "${runtime_directory}" UnquoteToken.Contract.sql
run_file "${local_database}" "${runtime_directory}" SplitAdvancedUsp.Contract.sql

# Typwechsel eines bekannten Release-Namens IF -> TF wird repariert.
run_query "${local_database}" "DROP FUNCTION toolbelt_string.TVF_SplitAdvanced;"
run_query "${local_database}" "CREATE FUNCTION toolbelt_string.TVF_SplitAdvanced (@Input nvarchar(max),@SeparatorsJson nvarchar(max),@Quote nvarchar(max),@Escape nvarchar(max),@KeepEmpty bit) RETURNS TABLE AS RETURN SELECT N'drift' AS Value;"
run_file "${local_database}" "${deployment_directory}" Deploy.sql -v DeploymentMode=local
run_file "${local_database}" "${runtime_directory}" Lifecycle.Contract.sql
run_file "${local_database}" "${runtime_directory}" SplitAdvanced.Contract.sql
run_file "${local_database}" "${runtime_directory}" UnquoteToken.Contract.sql
run_file "${local_database}" "${runtime_directory}" SplitAdvancedUsp.Contract.sql
run_query "${local_database}" "CREATE USER TbxSplitReader WITHOUT LOGIN; GRANT SELECT ON OBJECT::toolbelt_string.TVF_SplitAdvanced TO TbxSplitReader; EXECUTE AS USER=N'TbxSplitReader'; IF (SELECT COUNT(*) FROM toolbelt_string.TVF_SplitAdvanced(N'a;b',N'['+NCHAR(34)+N';'+NCHAR(34)+N']',N'',N'',1))<>2 THROW 54544,N'Minimales SELECT-Recht falsch.',1; REVERT; DROP USER TbxSplitReader;"

# Zusätzliche CI- und BIN2-Datenbankkontexte einschließlich zentraler Nutzung.
central_database="tbx_split_advanced_central"
consumer_database="tbx_split_advanced_consumer"
create_database "${central_database}" "Latin1_General_100_BIN2"
create_database "${consumer_database}" "Latin1_General_100_CI_AS"
run_file "${central_database}" "${deployment_directory}" Deploy.sql -v DeploymentMode=central
run_file "${central_database}" "${runtime_directory}" Lifecycle.Contract.sql
run_file "${central_database}" "${runtime_directory}" SplitAdvanced.Contract.sql
run_file "${central_database}" "${runtime_directory}" UnquoteToken.Contract.sql
run_file "${central_database}" "${runtime_directory}" SplitAdvancedUsp.Contract.sql
run_file "${central_database}" "${runtime_directory}" MinimumRights.Contract.sql
run_query "${central_database}" "CREATE USER TbxSplitCentralReader WITHOUT LOGIN; GRANT SELECT ON OBJECT::toolbelt_string.TVF_SplitAdvanced TO TbxSplitCentralReader; EXECUTE AS USER=N'TbxSplitCentralReader'; IF (SELECT COUNT(*) FROM toolbelt_string.TVF_SplitAdvanced(N'a;b',N'['+NCHAR(34)+N';'+NCHAR(34)+N']',N'',N'',1))<>2 THROW 54545,N'Zentrales minimales SELECT-Recht falsch.',1; REVERT; DROP USER TbxSplitCentralReader;"
run_file "${consumer_database}" "${deployment_directory}" Deploy.sql -v DeploymentMode=local
run_file "${consumer_database}" "${runtime_directory}" SplitAdvanced.Contract.sql
run_file "${consumer_database}" "${runtime_directory}" Central.Contract.sql -v ToolbeltDatabase="${central_database}"
if run_file "${central_database}" "${deployment_directory}" Uninstall.sql -v ConfirmNoExternalConsumers=0; then
    echo "Central-Uninstall akzeptierte fehlende Bestätigung." >&2; exit 1
fi
run_file "${central_database}" "${deployment_directory}" Uninstall.sql -v ConfirmNoExternalConsumers=1
run_query "${central_database}" "IF OBJECT_ID(N'toolbelt_string.TVF_SplitAdvanced') IS NOT NULL THROW 54540,N'Central-Uninstall ließ das Ziel zurück.',1;"

existing_schema_database="tbx_split_advanced_existing_schema"
create_database "${existing_schema_database}"
run_query "${existing_schema_database}" "CREATE SCHEMA toolbelt_string;"
run_file "${existing_schema_database}" "${deployment_directory}" Deploy.sql -v DeploymentMode=local
run_query "${existing_schema_database}" "CREATE TABLE toolbelt_string.ForeignData (Value int NULL);"
run_file "${existing_schema_database}" "${deployment_directory}" Uninstall.sql -v ConfirmNoExternalConsumers=0
run_query "${existing_schema_database}" "IF OBJECT_ID(N'toolbelt_string.ForeignData') IS NULL OR SCHEMA_ID(N'toolbelt_string') IS NULL THROW 54541,N'Uninstall entfernte fremden Bestand.',1;"

collision_database="tbx_split_advanced_collision"
create_database "${collision_database}"
run_query "${collision_database}" "CREATE SCHEMA toolbelt_string;"
run_query "${collision_database}" "CREATE VIEW toolbelt_string.TVF_SplitAdvanced AS SELECT 1 AS ForeignValue;"
if run_file "${collision_database}" "${deployment_directory}" Deploy.sql -v DeploymentMode=local; then
    echo "Fremde Zielnamenskollision wurde überschrieben." >&2; exit 1
fi
run_query "${collision_database}" "IF OBJECT_ID(N'toolbelt_string.TVF_SplitAdvanced',N'V') IS NULL OR EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.string.split-advanced.Version') THROW 54542,N'Kollisionspräflight veränderte Bestand.',1;"


# Echter gepinnter 1.0-Installer samt Originalsource aus Git; generierter,
# ignorierter Export außerhalb versionierter Quellen, keine historische Kopie im PR.
legacy_commit="3bc644e964b8a35c4e38d3eb2d58e2b1b18631eb"
repo_root="$(git rev-parse --show-toplevel)"
mkdir -p "${repo_root}/.runtime"
legacy_export="$(mktemp -d "${repo_root}/.runtime/split-advanced-v1.XXXXXX")"
git archive "${legacy_commit}" -- Modules/toolbelt.string.split-advanced/Deployment/Deploy.sql \
    Modules/toolbelt.string.split-advanced/Source/TVF_SplitAdvanced.sql | tar -x -C "${legacy_export}"
legacy_directory="/workspace/.runtime/$(basename "${legacy_export}")/Modules/toolbelt.string.split-advanced/Deployment"
upgrade_database="tbx_split_advanced_upgrade"
create_database "${upgrade_database}"
run_file "${upgrade_database}" "${legacy_directory}" Deploy.sql -v DeploymentMode=local
for new_name in TVF_UnquoteToken USP_SplitAdvanced; do
    run_query "${upgrade_database}" "CREATE VIEW toolbelt_string.${new_name} AS SELECT 17 AS ForeignValue;"
    if run_file "${upgrade_database}" "${deployment_directory}" Deploy.sql -v DeploymentMode=local; then
        echo "Neuer Release-Name wurde fremd übernommen." >&2; exit 1
    fi
    run_query "${upgrade_database}" "IF OBJECT_ID(N'toolbelt_string.${new_name}',N'V') IS NULL OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.string.split-advanced.Version' AND CONVERT(nvarchar(64),value)=N'1.0.0') THROW 54546,N'Upgrade-Kollision veränderte Bestand.',1; DROP VIEW toolbelt_string.${new_name};"
done
run_file "${upgrade_database}" "${deployment_directory}" Deploy.sql -v DeploymentMode=local
run_file "${upgrade_database}" "${runtime_directory}" Lifecycle.Contract.sql
run_file "${upgrade_database}" "${runtime_directory}" UnquoteToken.Contract.sql
run_file "${upgrade_database}" "${runtime_directory}" SplitAdvancedUsp.Contract.sql
run_file "${upgrade_database}" "${deployment_directory}" Uninstall.sql -v ConfirmNoExternalConsumers=0
run_query "${upgrade_database}" "IF OBJECT_ID(N'toolbelt_string.TVF_UnquoteToken') IS NOT NULL OR OBJECT_ID(N'toolbelt_string.USP_SplitAdvanced') IS NOT NULL THROW 54547,N'Upgrade-Uninstall ließ neue Objekte zurück.',1;"

# Eine lokale referenzierende View blockiert die Deinstallation.
run_query "${local_database}" "CREATE VIEW toolbelt_string.VW_SplitAdvancedConsumer AS SELECT * FROM toolbelt_string.TVF_SplitAdvanced(N'a',N'['+NCHAR(34)+N';'+NCHAR(34)+N']',N'',N'',1);"
if run_file "${local_database}" "${deployment_directory}" Uninstall.sql -v ConfirmNoExternalConsumers=0; then
    echo "Uninstall akzeptierte lokale Dependency." >&2; exit 1
fi
run_query "${local_database}" "DROP VIEW toolbelt_string.VW_SplitAdvancedConsumer;"
run_query "${local_database}" "DROP FUNCTION toolbelt_string.TVF_SplitAdvanced;"
run_query "${local_database}" "CREATE FUNCTION toolbelt_string.TVF_SplitAdvanced (@Input nvarchar(max),@SeparatorsJson nvarchar(max),@Quote nvarchar(max),@Escape nvarchar(max),@KeepEmpty bit) RETURNS TABLE AS RETURN SELECT N'drift' AS Value;"
run_file "${local_database}" "${deployment_directory}" Uninstall.sql -v ConfirmNoExternalConsumers=0
run_query "${local_database}" "IF OBJECT_ID(N'toolbelt_string.TVF_SplitAdvanced') IS NOT NULL THROW 54543,N'Uninstall ließ die TVF zurück.',1;"
run_file "${consumer_database}" "${deployment_directory}" Uninstall.sql -v ConfirmNoExternalConsumers=0
echo "Split-Advanced SQL Server ${sql_version}: erfolgreich"
