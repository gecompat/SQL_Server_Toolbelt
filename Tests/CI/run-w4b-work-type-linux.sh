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
container_name="tbx-w4b-${GITHUB_RUN_ID:-local}"
if [[ "${TBX_SQL_TARGET:-runner}" != lab ]]; then
    container_name="tbx-w4b-${sql_version}-${GITHUB_RUN_ID:-$$}-${GITHUB_RUN_ATTEMPT:-1}"
    if [[ ! "${container_name}" =~ ^tbx-w4b-(2019|2022|2025)-[0-9]+-[0-9]+$ ]]; then
        echo "W4B_CI_IDENTITY_INVALID" >&2
        exit 1
    fi
fi
sa_password="Tbx!$(openssl rand -hex 16)Aa1"
echo "::add-mask::${sa_password}"

container_owner=""; private_dir=""; container_options=()
if [[ "${TBX_SQL_TARGET:-runner}" != lab ]]; then
    container_owner="$(openssl rand -hex 16)"
    if [[ ! "${container_owner}" =~ ^[0-9a-f]{32}$ ]]; then
        echo "W4B_CI_OWNER_INVALID" >&2
        exit 1
    fi
    container_options=(--label "tbx.w4b.ci.owner=${container_owner}")
fi

private_dir="$(mktemp -d)"

cleanup() {
    local result=$? inspection="" container_id="" owner="" cleanup_verified=true
    trap - EXIT
    # Der bestehende Lab-Shim hat keinen Container und behandelt rm als No-op.
    # Seine Datenbankbereinigung bleibt beim Labtreiber; die Ausgabe ist privat.
    if [[ "${TBX_SQL_TARGET:-runner}" == lab ]]; then
        docker rm -f "${container_name}" >/dev/null 2>&1 || true
        if ! rm -rf -- "${private_dir}"; then
            echo "W4B_LAB_CLEANUP_UNVERIFIED" >&2
            result=1
        fi
        exit "${result}"
    fi
    # Name und Owner identifizieren ausschließlich unseren flüchtigen Scope.
    # ID und Label aus derselben Aufnahme binden das Entfernen bei Namensaustausch.
    if ! docker container ls --all --filter "name=^/${container_name}$" \
        --format '{{.Names}}' >"${private_dir}/owned-containers" 2>/dev/null; then
        cleanup_verified=false
    elif [[ -s "${private_dir}/owned-containers" ]]; then
        if ! inspection="$(docker inspect --format '{{.Id}} {{ index .Config.Labels "tbx.w4b.ci.owner" }}' \
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
        echo "W4B_CI_CLEANUP_UNVERIFIED" >&2
        result=1
    else
        echo "W4B_CI_CLEANUP_VERIFIED"
    fi
    exit "${result}"
}


trap cleanup EXIT

docker run -d \
  --name "${container_name}" "${container_options[@]}" \
  -e ACCEPT_EULA=Y \
  -e MSSQL_PID=Developer \
  -e MSSQL_SA_PASSWORD="${sa_password}" \
  -v "${GITHUB_WORKSPACE:-$(pwd)}:/workspace:ro" \
  "${sql_image}" >/dev/null

sqlcmd_path=""
for candidate in /opt/mssql-tools18/bin/sqlcmd /opt/mssql-tools/bin/sqlcmd; do
  if docker exec "${container_name}" test -x "${candidate}"; then
    sqlcmd_path="${candidate}"
    break
  fi
done
[[ -n "${sqlcmd_path}" ]] || { echo "sqlcmd fehlt" >&2; exit 1; }

for attempt in $(seq 1 60); do
  if docker exec "${container_name}" "${sqlcmd_path}" \
      -S localhost -U sa -P "${sa_password}" -C -b -Q "SELECT 1" >/dev/null 2>&1; then
    break
  fi
  if [[ "${attempt}" -eq 60 ]]; then
    docker logs "${container_name}"
    exit 1
  fi
  sleep 2
done

run_query() {
  docker exec "${container_name}" "${sqlcmd_path}" \
    -S localhost -U sa -P "${sa_password}" -C -b -d "$1" -Q "$2"
}

run_file() {
  local db="$1"
  local workdir="$2"
  local file="$3"
  shift 3
  docker exec --workdir "${workdir}" "${container_name}" "${sqlcmd_path}" \
    -S localhost -U sa -P "${sa_password}" -C -b -d "${db}" -i "${file}" "$@"
}

deploy() {
  run_file "$1" "/workspace/$2/Deployment" Deploy.sql -v DeploymentMode="$3"
}

uninstall() {
  run_file "$1" "/workspace/$2/Deployment" Uninstall.sql \
    -v ConfirmNoExternalConsumers="$3" AllowDataLoss="$4"
}

local_db=tbx_w4b_local
run_query master "CREATE DATABASE [${local_db}] COLLATE Latin1_General_100_CS_AS;"
deploy "${local_db}" Modules/toolbelt.core.result-table local
deploy "${local_db}" Modules/toolbelt.core.work-type local
run_file "${local_db}" /workspace/Modules/toolbelt.core.work-type/Tests/Runtime Lifecycle.Contract.sql

for level in ${compatibility_levels}; do
  run_query "${local_db}" "ALTER DATABASE [${local_db}] SET COMPATIBILITY_LEVEL = ${level};"
  run_file "${local_db}" /workspace/Modules/toolbelt.core.work-type/Tests/Runtime WorkType.Contract.sql
  run_file "${local_db}" /workspace/Modules/toolbelt.core.work-type/Tests/Runtime Remove.Contract.sql
done

# Concurrency: gleicher idempotenter Register-Aufruf aus vier echten Sessions.
run_query "${local_db}" "CREATE OR ALTER PROCEDURE toolbelt_core.USP_TestWorkTypeConcurrent AS BEGIN SET NOCOUNT ON; END;"
workers=()
for worker in 1 2 3 4; do
  run_file "${local_db}" /workspace/Modules/toolbelt.core.work-type/Tests/Runtime Concurrency.Contract.sql &
  workers+=("$!")
done
for pid in "${workers[@]}"; do
  wait "${pid}"
done
run_file "${local_db}" /workspace/Modules/toolbelt.core.work-type/Tests/Runtime Concurrency.Verify.sql

# Redeploy muss persistente Daten erhalten.
run_query "${local_db}" "CREATE OR ALTER PROCEDURE toolbelt_core.USP_TestPreserve AS BEGIN SET NOCOUNT ON; END;"
run_query "${local_db}" "EXEC toolbelt_core.USP_RegisterWorkType @WorkTypeName='test.preserve', @HandlerSchema=N'toolbelt_core', @HandlerProcedure=N'USP_TestPreserve';"
deploy "${local_db}" Modules/toolbelt.core.work-type local
run_query "${local_db}" "IF NOT EXISTS (SELECT 1 FROM toolbelt_core.WorkType WHERE WorkTypeName='test.preserve') THROW 52550, N'Redeploy verlor persistente Daten.', 1;"
run_query "${local_db}" "DELETE FROM toolbelt_core.WorkType WHERE WorkTypeName='test.preserve'; DROP PROCEDURE toolbelt_core.USP_TestPreserve;"

central_db=tbx_w4b_central
consumer_db=tbx_w4b_consumer
run_query master "CREATE DATABASE [${central_db}] COLLATE Latin1_General_100_BIN2; CREATE DATABASE [${consumer_db}] COLLATE Latin1_General_100_CS_AS;"
deploy "${central_db}" Modules/toolbelt.core.result-table central
deploy "${central_db}" Modules/toolbelt.core.work-type central
run_file "${consumer_db}" /workspace/Modules/toolbelt.core.work-type/Tests/Runtime Central.Contract.sql -v ToolbeltDatabase="${central_db}"

# Uninstall-Schutz gegen stillen Datenverlust.
run_query "${local_db}" "CREATE OR ALTER PROCEDURE toolbelt_core.USP_TestUninstall AS BEGIN SET NOCOUNT ON; END;"
run_query "${local_db}" "EXEC toolbelt_core.USP_RegisterWorkType @WorkTypeName='test.uninstall', @HandlerSchema=N'toolbelt_core', @HandlerProcedure=N'USP_TestUninstall';"
run_query "${local_db}" "IF NOT EXISTS (SELECT 1 FROM toolbelt_core.WorkType WHERE WorkTypeName='test.uninstall') THROW 52552, N'Die Testzeile fehlt vor dem Data-Loss-Uninstall-Test.', 1;"
set +e
uninstall "${local_db}" Modules/toolbelt.core.work-type 0 0 >"${private_dir}/w4b-uninstall.out" 2>&1
uninstall_rc=$?
set -e
cat "${private_dir}/w4b-uninstall.out"
if [[ "${uninstall_rc}" -eq 0 ]] || ! grep -q "51549" "${private_dir}/w4b-uninstall.out"; then
  echo "Der erwartete Data-Loss-Fehler 51549 fehlt; Exitcode=${uninstall_rc}." >&2
  exit 1
fi
run_query "${local_db}" "IF OBJECT_ID(N'toolbelt_core.WorkType', N'U') IS NULL OR NOT EXISTS (SELECT 1 FROM toolbelt_core.WorkType WHERE WorkTypeName='test.uninstall') THROW 52551, N'Der abgelehnte Uninstall veränderte Katalog oder Testzeile.', 1;"

uninstall "${central_db}" Modules/toolbelt.core.work-type 1 1
uninstall "${central_db}" Modules/toolbelt.core.result-table 1 1
uninstall "${local_db}" Modules/toolbelt.core.work-type 0 1
uninstall "${local_db}" Modules/toolbelt.core.result-table 0 1

echo "W4b Work-Type-Katalog Linux: erfolgreich"
