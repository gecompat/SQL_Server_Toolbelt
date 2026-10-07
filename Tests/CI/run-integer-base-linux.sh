#!/usr/bin/env bash
set -euo pipefail

sql_image="${TBX_SQL_IMAGE:?TBX_SQL_IMAGE fehlt}"
sql_version="${TBX_SQL_VERSION:-2025}"
case "${sql_version}" in
  2019) compatibility_levels="150"; max_compatibility_level="150" ;;
  2022) compatibility_levels="160"; max_compatibility_level="160" ;;
  2025) compatibility_levels="150 160 170"; max_compatibility_level="170" ;;
  *) echo "Nicht unterstützte SQL-Version: ${sql_version}" >&2; exit 1 ;;
esac
container_name="tbx-integer-base-${GITHUB_RUN_ID:-local}"
if [[ "${TBX_SQL_TARGET:-runner}" != lab ]]; then
    container_name="tbx-integer-base-${sql_version}-${GITHUB_RUN_ID:-$$}-${GITHUB_RUN_ATTEMPT:-1}"
    if [[ ! "${container_name}" =~ ^tbx-integer-base-(2019|2022|2025)-[0-9]+-[0-9]+$ ]]; then
        echo "INTEGER_BASE_CI_IDENTITY_INVALID" >&2
        exit 1
    fi
fi
sa_password="Tbx!$(openssl rand -hex 16)Aa1"
echo "::add-mask::${sa_password}"

container_owner=""; private_dir=""; container_options=()
if [[ "${TBX_SQL_TARGET:-runner}" != lab ]]; then
    container_owner="$(openssl rand -hex 16)"
    if [[ ! "${container_owner}" =~ ^[0-9a-f]{32}$ ]]; then
        echo "INTEGER_BASE_CI_OWNER_INVALID" >&2
        exit 1
    fi
    private_dir="$(mktemp -d)"
    container_options=(--label "tbx.integer-base.ci.owner=${container_owner}")
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
        if ! inspection="$(docker inspect --format '{{.Id}} {{ index .Config.Labels "tbx.integer-base.ci.owner" }}' \
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
        echo "INTEGER_BASE_CI_CLEANUP_UNVERIFIED" >&2
        result=1
    else
        echo "INTEGER_BASE_CI_CLEANUP_VERIFIED"
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

deployment_directory="/workspace/Modules/toolbelt.conversion.integer-base/Deployment"
runtime_directory="/workspace/Modules/toolbelt.conversion.integer-base/Tests/Runtime"
local_database="tbx_integer_base_local"

create_database "${local_database}" "Latin1_General_100_CS_AS"
run_file "${local_database}" "${deployment_directory}" Deploy.sql \
    -v DeploymentMode=local
run_file "${local_database}" "${runtime_directory}" Lifecycle.Contract.sql

for compatibility_level in ${compatibility_levels}; do
    run_file "${local_database}" "${runtime_directory}" \
        IntegerBase.Contract.sql -v CompatibilityLevel="${compatibility_level}"
done

# Wiederholungsdeployment stellt den kanonischen Frameworkstand wieder her.
run_query "${local_database}" \
    "ALTER FUNCTION [toolbelt_conversion].[TVF_IntegerToBase] (@Value bigint, @Alphabet varchar(93)) RETURNS TABLE AS RETURN (SELECT CONVERT(varchar(65), 'drift') AS EncodedValue);"
run_file "${local_database}" "${deployment_directory}" Deploy.sql \
    -v DeploymentMode=local
run_file "${local_database}" "${runtime_directory}" Lifecycle.Contract.sql
run_file "${local_database}" "${runtime_directory}" IntegerBase.Contract.sql \
    -v CompatibilityLevel="${max_compatibility_level}"

upgrade_database="tbx_integer_base_upgrade"
create_database "${upgrade_database}"
run_query "${upgrade_database}" \
    "CREATE SCHEMA [toolbelt_conversion];"
run_query "${upgrade_database}" \
    "CREATE FUNCTION [toolbelt_conversion].[SVF_IntegerToBase] (@Value bigint, @Alphabet varchar(93)) RETURNS varchar(65) AS BEGIN RETURN 'legacy'; END;"
run_query "${upgrade_database}" \
    "CREATE FUNCTION [toolbelt_conversion].[SVF_TryBaseToInteger] (@EncodedValue varchar(65), @Alphabet varchar(93)) RETURNS bigint AS BEGIN RETURN NULL; END;"
run_query "${upgrade_database}" \
    "EXEC sys.sp_addextendedproperty @name=N'Toolbelt.Module.toolbelt.conversion.integer-base.Version', @value=N'1.0.0';"
run_file "${upgrade_database}" "${deployment_directory}" Deploy.sql \
    -v DeploymentMode=local
run_file "${upgrade_database}" "${runtime_directory}" Lifecycle.Contract.sql
run_file "${upgrade_database}" "${runtime_directory}" IntegerBase.Contract.sql \
    -v CompatibilityLevel="${max_compatibility_level}"

central_database="tbx_integer_base_central"
consumer_database="tbx_integer_base_consumer"
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
    "IF OBJECT_ID(N'toolbelt_conversion.TVF_IntegerToBase') IS NOT NULL OR OBJECT_ID(N'toolbelt_conversion.TVF_TryBaseToInteger') IS NOT NULL OR OBJECT_ID(N'toolbelt_conversion.SVF_IntegerToBase') IS NOT NULL OR OBJECT_ID(N'toolbelt_conversion.SVF_TryBaseToInteger') IS NOT NULL THROW 52840, N'Central Uninstall ließ Release-Objekte zurück.', 1;"

existing_schema_database="tbx_integer_base_existing_schema"
create_database "${existing_schema_database}"
run_query "${existing_schema_database}" \
    "CREATE SCHEMA [toolbelt_conversion];"
run_file "${existing_schema_database}" "${deployment_directory}" Deploy.sql \
    -v DeploymentMode=local
run_file "${existing_schema_database}" "${deployment_directory}" Uninstall.sql \
    -v ConfirmNoExternalConsumers=0
run_query "${existing_schema_database}" \
    "IF SCHEMA_ID(N'toolbelt_conversion') IS NULL THROW 52841, N'Ein vorbestehendes unmarkiertes Schema wurde gelöscht.', 1;"

collision_database="tbx_integer_base_collision"
create_database "${collision_database}"
run_query "${collision_database}" \
    "CREATE SCHEMA [toolbelt_conversion];"
run_query "${collision_database}" \
    "CREATE FUNCTION [toolbelt_conversion].[TVF_IntegerToBase] (@Value bigint, @Alphabet varchar(93)) RETURNS TABLE AS RETURN (SELECT CONVERT(varchar(65), 'foreign') AS EncodedValue);"

# Ein beliebiger Fehler ist kein Kollisionsnachweis. Beide Ausgabekanäle
# bleiben im Speicher; nur Fehlerstatus UND die vollständige Kategorie zählen.
set +e
collision_output="$(run_file "${collision_database}" "${deployment_directory}" Deploy.sql \
    -v DeploymentMode=local 2>&1)"
collision_result=$?
set -e
if [[ "${collision_result}" -eq 0 ]] \
    || ! grep -Eq '(^|[^0-9])51094([^0-9]|$)' <<<"${collision_output}"; then
    echo "Integer-Base-Kollision wurde nicht mit Fehler 51094 abgelehnt." >&2
    exit 1
fi
unset collision_output
echo "INTEGER_BASE_COLLISION_VERIFIED"

run_query "${collision_database}" \
    "IF EXISTS (SELECT 1 FROM sys.extended_properties WHERE class = 0 AND name = N'Toolbelt.Module.toolbelt.conversion.integer-base.Version') THROW 52842, N'Kollisions-Preflight hinterließ einen Installationsmarker.', 1;"

run_file "${local_database}" "${deployment_directory}" Uninstall.sql \
    -v ConfirmNoExternalConsumers=0
run_query "${local_database}" \
    "IF OBJECT_ID(N'toolbelt_conversion.TVF_IntegerToBase') IS NOT NULL OR OBJECT_ID(N'toolbelt_conversion.TVF_TryBaseToInteger') IS NOT NULL OR OBJECT_ID(N'toolbelt_conversion.SVF_IntegerToBase') IS NOT NULL OR OBJECT_ID(N'toolbelt_conversion.SVF_TryBaseToInteger') IS NOT NULL THROW 52843, N'Uninstall ließ Release-Objekte zurück.', 1;"

echo "Integer-Base SQL Server ${sql_version} (Compatibility ${compatibility_levels}): erfolgreich"
