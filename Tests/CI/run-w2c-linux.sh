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
container_name="tbx-w2c-${GITHUB_RUN_ID:-local}"
if [[ "${TBX_SQL_TARGET:-runner}" != lab ]]; then
    container_name="tbx-w2c-${sql_version}-${GITHUB_RUN_ID:-$$}-${GITHUB_RUN_ATTEMPT:-1}"
    if [[ ! "${container_name}" =~ ^tbx-w2c-(2019|2022|2025)-[0-9]+-[0-9]+$ ]]; then
        echo "W2C_CI_IDENTITY_INVALID" >&2
        exit 1
    fi
fi
sa_password="Tbx!$(openssl rand -hex 16)Aa1"
echo "::add-mask::${sa_password}"

container_owner=""; private_dir=""; container_options=()
if [[ "${TBX_SQL_TARGET:-runner}" != lab ]]; then
    container_owner="$(openssl rand -hex 16)"
    if [[ ! "${container_owner}" =~ ^[0-9a-f]{32}$ ]]; then
        echo "W2C_CI_OWNER_INVALID" >&2
        exit 1
    fi
    private_dir="$(mktemp -d)"
    container_options=(--label "tbx.w2c.ci.owner=${container_owner}")
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
        if ! inspection="$(docker inspect --format '{{.Id}} {{ index .Config.Labels "tbx.w2c.ci.owner" }}' \
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
        echo "W2C_CI_CLEANUP_UNVERIFIED" >&2
        result=1
    else
        echo "W2C_CI_CLEANUP_VERIFIED"
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

deploy_console() {
  local target_database="$1"
  local mode="$2"
  run_file "${target_database}" \
    /workspace/Modules/toolbelt.core.console-message/Deployment \
    Deploy.sql -v DeploymentMode="${mode}"
}

deploy_catalog() {
  local target_database="$1"
  local mode="$2"
  run_file "${target_database}" \
    /workspace/Modules/toolbelt.metadata.capability-catalog/Deployment \
    Deploy.sql -v DeploymentMode="${mode}"
}

database="tbx_w2c"
run_query master \
  "CREATE DATABASE [${database}] COLLATE Latin1_General_100_CS_AS;"

deploy_console "${database}" local
deploy_catalog "${database}" local

run_file "${database}" \
  /workspace/Modules/toolbelt.core.console-message/Tests/Runtime \
  Lifecycle.Contract.sql
run_file "${database}" \
  /workspace/Modules/toolbelt.metadata.capability-catalog/Tests/Runtime \
  Lifecycle.Contract.sql

for level in ${compatibility_levels}; do
  run_query "${database}" \
    "ALTER DATABASE [${database}] SET COMPATIBILITY_LEVEL = ${level};"
  run_file "${database}" \
    /workspace/Modules/toolbelt.core.console-message/Tests/Runtime \
    ConsoleMessage.Contract.sql -v CompatibilityLevel="${level}"
  run_file "${database}" \
    /workspace/Modules/toolbelt.metadata.capability-catalog/Tests/Runtime \
    ModuleCapabilities.Contract.sql -v CompatibilityLevel="${level}"
done

run_file "${database}" \
  /workspace/Modules/toolbelt.metadata.capability-catalog/Tests/Runtime \
  MetadataVisibility.Contract.sql

set +e
console_output="$(
  docker exec \
    --workdir /workspace/Modules/toolbelt.core.console-message/Tests/Runtime \
    "${container_name}" "${sqlcmd_path}" \
    -S localhost -U sa -P "${sa_password}" -C -b -f 65001 \
    -d "${database}" -i ConsoleOutput.Contract.sql 2>&1
)"
console_status=$?
set -e

if [[ "${console_status}" -ne 0 ]]; then
  printf '%s\n' "${console_output}" >&2
  exit "${console_status}"
fi

for marker in \
  "TBX-BUFFERED-BEGIN" \
  "TBX-BUFFERED-MIDDLE" \
  "TBX-BUFFERED-END" \
  "TBX-IMMEDIATE-100%-BEGIN" \
  "TBX-IMMEDIATE-MIDDLE" \
  "TBX-IMMEDIATE-END" \
  "🐼" \
  "TBX-LINE-A" \
  "TBX-LINE-B"; do
  if ! LC_ALL=C grep -Fq "${marker}" <<<"${console_output}"; then
    echo "Console-Ausgabemarker fehlt: ${marker}" >&2
    exit 1
  fi
done

deploy_console "${database}" local
deploy_catalog "${database}" local

central_database="tbx_w2c_central"
consumer_database="tbx_w2c_consumer"
run_query master \
  "CREATE DATABASE [${central_database}] COLLATE Latin1_General_100_BIN2;"
run_query master \
  "CREATE DATABASE [${consumer_database}] COLLATE Latin1_General_100_CI_AS;"

deploy_console "${central_database}" central
deploy_catalog "${central_database}" central

run_file "${consumer_database}" \
  /workspace/Modules/toolbelt.core.console-message/Tests/Runtime \
  Central.Contract.sql -v ToolbeltDatabase="${central_database}"
run_file "${consumer_database}" \
  /workspace/Modules/toolbelt.metadata.capability-catalog/Tests/Runtime \
  Central.Contract.sql -v ToolbeltDatabase="${central_database}"

run_file "${central_database}" \
  /workspace/Modules/toolbelt.metadata.capability-catalog/Deployment \
  Uninstall.sql -v ConfirmNoExternalConsumers=1
run_file "${central_database}" \
  /workspace/Modules/toolbelt.core.console-message/Deployment \
  Uninstall.sql -v ConfirmNoExternalConsumers=1

run_query "${central_database}" "
IF OBJECT_ID(N'toolbelt_metadata.VW_ModuleCapabilities') IS NOT NULL
   OR OBJECT_ID(N'toolbelt_core.USP_WriteConsoleMessage') IS NOT NULL
    THROW 52949, N'Central Uninstall ließ W2c-Objekte zurück.', 1;"

run_file "${database}" \
  /workspace/Modules/toolbelt.metadata.capability-catalog/Deployment \
  Uninstall.sql -v ConfirmNoExternalConsumers=0
run_file "${database}" \
  /workspace/Modules/toolbelt.core.console-message/Deployment \
  Uninstall.sql -v ConfirmNoExternalConsumers=0

run_query "${database}" "
IF OBJECT_ID(N'toolbelt_metadata.VW_ModuleCapabilities') IS NOT NULL
   OR OBJECT_ID(N'toolbelt_core.USP_WriteConsoleMessage') IS NOT NULL
    THROW 52949, N'Lokaler Uninstall ließ W2c-Objekte zurück.', 1;"

echo "W2c SQL Server ${sql_version} (Compatibility ${compatibility_levels}): erfolgreich"
