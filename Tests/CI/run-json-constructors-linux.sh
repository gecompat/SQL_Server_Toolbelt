#!/usr/bin/env bash

set -euo pipefail

# Ausschließlich synthetische Datenbanken und ein flüchtiges, maskiertes
# Testkennwort. Es wird nicht als Artefakt gespeichert.
# Native Lab ausschließlich über den eigenen koordinierenden Gruppen-Driver.
if [[ "${TBX_SQL_TARGET:-runner}" == lab ]]; then
    echo "DEDICATED_JSON_GROUPS_LAB_DRIVER_REQUIRED" >&2
    exit 65
fi
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


# Ausschließlich das Windows-built, exakt bekannte Artefakt; kein Mono-/SDK-Fallback.
[[ -f .runtime/json-clr/Deploy.sql && -f .runtime/json-clr/Uninstall.sql ]] || { echo "KNOWN_JSON_ARTIFACT_REQUIRED" >&2; exit 65; }
deployment_directory="/workspace/.runtime/json-clr"
run_query master "EXEC sys.sp_configure N'clr enabled',1; RECONFIGURE;"
run_query master "IF NOT EXISTS(SELECT 1 FROM sys.configurations WHERE name=N'clr strict security' AND value_in_use=1) THROW 53622,N'CLR strict security required.',1; IF NOT EXISTS(SELECT 1 FROM sys.trusted_assemblies WHERE hash=0xFF266A2FC46EB4101D87BC046AEF63197B985C8CCBAEA40F372E9918D1254C44F1F2CF8CED7942383625D28E2E1AF5BF6164FA8A16B3DD5A16DF5957FAA34276) EXEC sys.sp_add_trusted_assembly @hash=0xFF266A2FC46EB4101D87BC046AEF63197B985C8CCBAEA40F372E9918D1254C44F1F2CF8CED7942383625D28E2E1AF5BF6164FA8A16B3DD5A16DF5957FAA34276,@description=N'Synthetic known JSON CI artifact';"
runtime_directory="/workspace/Modules/toolbelt.json.constructors/Tests/Runtime"
expect_failure() {
    local expected_number="$1"
    shift
    local failure_output
    # Nur flüchtiger Speicher; niemals vollständige Diagnostik/Verbindung ausgeben.
    if failure_output=$("$@" 2>&1); then
        echo "Expected SQL failure was absent." >&2; exit 1
    fi
    if [[ "${failure_output}" != *"Msg ${expected_number},"* && !( "${expected_number}" == 50000 && "${failure_output}" == *"JSON_LIFECYCLE_CALLER_TRANSACTION:"* ) ]]; then
        echo "Unexpected SQL error category." >&2; exit 1
    fi
}
# Synthetische Predicate-Injektion, kein tatsächlicher Lowpriv-Nachweis.
# Pass 0 verwendet echte Rechte; erst unter AppLock wird 0 bzw. NULL injiziert.
run_uninstall_metadata_injection() {
    local database_name="$1" permission="$2" injected="$3"
    python3 - "${permission}" "${injected}" <<'PYSQL' | docker exec -i "${container_name}" "${sqlcmd_path}" \
        -S localhost -U sa -P "${sa_password}" -C -b -d "${database_name}"
from pathlib import Path
import sys
source = Path('.runtime/json-clr/Uninstall.sql').read_text(encoding='utf-8')
expressions = {
    'view': "HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'VIEW DEFINITION')",
    'select': "HAS_PERMS_BY_NAME(N'sys.sql_expression_dependencies',N'OBJECT',N'SELECT')",
}
expression = expressions[sys.argv[1]]
value = sys.argv[2]
predicate = ("  IF COALESCE(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'VIEW DEFINITION'),0)<>1\n"
             "   OR COALESCE(HAS_PERMS_BY_NAME(N'sys.sql_expression_dependencies',N'OBJECT',N'SELECT'),0)<>1\n"
             "   THROW 53622,N'JSON lifecycle: erforderliche Metadatenrechte für Uninstall fehlen.',1;")
assert value in ('0', 'NULL') and source.count(predicate) == 1
assert predicate.count(expression) == 1
injected_predicate = predicate.replace(expression, f'CASE WHEN @Pass=1 THEN {value} ELSE {expression} END')
source = source.replace(predicate, injected_predicate)
source = source.replace('$(ConfirmNoExternalConsumers)', '0')
assert '$(' not in source
print(source)
PYSQL
}
legacy_directory="/workspace/.runtime/json-constructors-legacy/Deployment"
local_database="tbx_json_constructor_local"
central_database="tbx_json_constructor_central"
consumer_database="tbx_json_constructor_consumer"
for db in "${local_database}" "${central_database}" "${consumer_database}"; do
    create_database "${db}" "Latin1_General_100_CI_AS"
done
run_file "${local_database}" "${legacy_directory}" Deploy.sql -v DeploymentMode=local
run_file "${local_database}" "${runtime_directory}" JsonConstructors.Contract.sql
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
run_file "${central_database}" "${legacy_directory}" Deploy.sql -v DeploymentMode=central
run_file "${central_database}" "${runtime_directory}" JsonConstructors.Contract.sql
run_file "${central_database}" "${deployment_directory}" Deploy.sql -v DeploymentMode=central
# Falsche Objektarten ohne kohärente Proceduremarker sind kein Reparaturfall.
wrongtype_database=tbx_json_wrong_type
create_database "${wrongtype_database}" "Latin1_General_100_CI_AS"
run_file "${wrongtype_database}" "${deployment_directory}" Deploy.sql -v DeploymentMode=local
run_query "${wrongtype_database}" "DROP PROCEDURE toolbelt_json.USP_JsonArray;"
run_query "${wrongtype_database}" "CREATE FUNCTION toolbelt_json.USP_JsonArray() RETURNS @r TABLE(Drift int) AS BEGIN INSERT @r VALUES(7); RETURN; END;"
expect_failure 53623 run_file "${wrongtype_database}" "${deployment_directory}" Deploy.sql -v DeploymentMode=local
case_database="tbx_json_constructor_case_sensitive"
create_database "${case_database}" "Latin1_General_100_CS_AS"
run_file "${case_database}" "${deployment_directory}" Deploy.sql -v DeploymentMode=local
run_file "${case_database}" "${runtime_directory}" Collation.Contract.sql
run_file "${local_database}" "${runtime_directory}" Collation.Contract.sql
run_file "${central_database}" "${runtime_directory}" JsonConstructors.Contract.sql
run_file "${central_database}" "${runtime_directory}" Lifecycle.Contract.sql
run_file "${consumer_database}" "${runtime_directory}" Central.Contract.sql -v ToolbeltDatabase="${central_database}"
for db in "${local_database}" "${central_database}"; do
  for level in ${compatibility_levels}; do
    run_query "${db}" "ALTER DATABASE [${db}] SET COMPATIBILITY_LEVEL=${level};"
    for test in JsonConstructors.Contract.sql Collation.Contract.sql JsonGroups.Contract.sql JsonGroups.Boundaries.sql InstalledMetadata.Contract.sql JsonAggregates.Contract.sql JsonEntryBridge.Contract.sql; do
      run_file "${db}" "${runtime_directory}" "${test}"
    done
  done
  mode=local; [[ "${db}" == "${central_database}" ]] && mode=central
  for abort in ON OFF; do
    expect_failure 50000 run_file "${db}" "${deployment_directory}" "${runtime_directory}/Deploy.CallerGuard.sql" -v Abort="${abort}" DeploymentMode="${mode}"
    expect_failure 50000 run_file "${db}" "${deployment_directory}" "${runtime_directory}/Uninstall.CallerGuard.sql" -v Abort="${abort}" ConfirmNoExternalConsumers=0
  done
  for historical in 1.0.0; do
    for fault in FutureSlot ImitatedFutureSlot; do
      faultdb="${db}_${historical//./}_${fault}"
      create_database "${faultdb}" "Latin1_General_100_CI_AS"
      run_file "${faultdb}" "${legacy_directory}" Deploy.sql -v DeploymentMode=local
      run_file "${faultdb}" "${runtime_directory}" Lifecycle.CollisionFixture.sql -v FaultCase="${fault}" HistoricalVersion="${historical}"
      expect_failure 53624 run_file "${faultdb}" "${deployment_directory}" Deploy.sql -v DeploymentMode=local
    done
  done
done
run_query "${local_database}" "CREATE USER TbxJsonCaller WITHOUT LOGIN; GRANT EXECUTE ON OBJECT::toolbelt_json.USP_JsonArray TO TbxJsonCaller; GRANT EXECUTE ON OBJECT::toolbelt_json.USP_JsonObject TO TbxJsonCaller; GRANT EXECUTE ON OBJECT::toolbelt_core.USP_PrepareResultTable TO TbxJsonCaller;"
run_file "${local_database}" "${runtime_directory}" MinimumRights.Contract.sql
run_query "${local_database}" "DROP USER TbxJsonCaller;"
for permission in view select; do
  for injected in 0 NULL; do
    expect_failure 53622 run_uninstall_metadata_injection "${local_database}" "${permission}" "${injected}"
    # Eigene TX wurde zurückgerollt: Definitionen, Marker und fünf Slots intakt.
    run_file "${local_database}" "${runtime_directory}" Lifecycle.Contract.sql
    run_file "${local_database}" "${runtime_directory}" InstalledMetadata.Contract.sql
  done
done

run_query "${local_database}" "CREATE PROCEDURE dbo.USP_SyntheticJsonConsumer AS EXEC toolbelt_json.USP_JsonArray @Hilfe=1;"
expect_failure 53626 run_file "${local_database}" "${deployment_directory}" Uninstall.sql -v ConfirmNoExternalConsumers=0
run_file "${local_database}" "${runtime_directory}" Lifecycle.Contract.sql
run_query "${local_database}" "DROP PROCEDURE dbo.USP_SyntheticJsonConsumer;"
for name in USP_JsonArray USP_JsonObject USP_JsonConstructInternal USP_JsonArraysByGroup USP_JsonObjectsByGroup; do
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
