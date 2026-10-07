#!/usr/bin/env bash
set -euo pipefail
sql_image="${TBX_SQL_IMAGE:?TBX_SQL_IMAGE fehlt}"
sql_version="${TBX_SQL_VERSION:-2025}"
case "${sql_version}" in 2019) levels="150";; 2022) levels="160";; 2025) levels="150 160 170";; *) exit 1;; esac
container_name="tbx-w6d-${GITHUB_RUN_ID:-local}"
if [[ "${TBX_SQL_TARGET:-runner}" != lab ]]; then
    container_name="tbx-w6d-${sql_version}-${GITHUB_RUN_ID:-$$}-${GITHUB_RUN_ATTEMPT:-1}"
    if [[ ! "${container_name}" =~ ^tbx-w6d-(2019|2022|2025)-[0-9]+-[0-9]+$ ]]; then
        echo "W6D_CI_IDENTITY_INVALID" >&2
        exit 1
    fi
fi
sa_password="Tbx!$(openssl rand -hex 16)Aa1"
echo "::add-mask::${sa_password}"
container_owner=""; private_dir=""; container_options=()
if [[ "${TBX_SQL_TARGET:-runner}" != lab ]]; then
    container_owner="$(openssl rand -hex 16)"
    if [[ ! "${container_owner}" =~ ^[0-9a-f]{32}$ ]]; then
        echo "W6D_CI_OWNER_INVALID" >&2
        exit 1
    fi
    container_options=(--label "tbx.w6d.ci.owner=${container_owner}")
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
            echo "W6D_LAB_CLEANUP_UNVERIFIED" >&2
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
        if ! inspection="$(docker inspect --format '{{.Id}} {{ index .Config.Labels "tbx.w6d.ci.owner" }}' \
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
        echo "W6D_CI_CLEANUP_UNVERIFIED" >&2
        result=1
    else
        echo "W6D_CI_CLEANUP_VERIFIED"
    fi
    exit "${result}"
}


trap cleanup EXIT
docker run -d --name "${container_name}" "${container_options[@]}" -e ACCEPT_EULA=Y -e MSSQL_PID=Developer -e MSSQL_SA_PASSWORD="${sa_password}" -v "${GITHUB_WORKSPACE:-$(pwd)}:/workspace:ro" "${sql_image}" >/dev/null
sqlcmd_path=""
for candidate in /opt/mssql-tools18/bin/sqlcmd /opt/mssql-tools/bin/sqlcmd; do docker exec "${container_name}" test -x "${candidate}" && { sqlcmd_path="${candidate}"; break; }; done
[[ -n "${sqlcmd_path}" ]] || { echo 'sqlcmd fehlt' >&2; exit 1; }
for attempt in $(seq 1 60); do docker exec "${container_name}" "${sqlcmd_path}" -S localhost -U sa -P "${sa_password}" -C -b -Q 'SELECT 1' >/dev/null 2>&1 && break; [[ "${attempt}" -eq 60 ]] && exit 1; sleep 2; done
run_query(){ docker exec "${container_name}" "${sqlcmd_path}" -S localhost -U sa -P "${sa_password}" -C -b -d "$1" -Q "$2"; }
run_file(){ local db="$1" wd="$2" file="$3"; shift 3; docker exec --workdir "${wd}" "${container_name}" "${sqlcmd_path}" -S localhost -U sa -P "${sa_password}" -C -b -d "${db}" -i "${file}" "$@"; }
deploy(){ run_file "$1" "/workspace/$2/Deployment" Deploy.sql -v DeploymentMode="$3"; }
uninstall(){ run_file "$1" "/workspace/$2/Deployment" Uninstall.sql -v ConfirmNoExternalConsumers="$3" AllowDataLoss="$4"; }

dependency_db=tbx_w6d_dependency
run_query master "CREATE DATABASE [${dependency_db}];"
set +e; deploy "${dependency_db}" Modules/toolbelt.core.execution-cancel local >"${private_dir}/w6d-dependency.out" 2>&1; rc=$?; set -e
if [[ ${rc} -eq 0 ]] || ! grep -q '52641' "${private_dir}/w6d-dependency.out"; then echo 'Dependency-Preflight fehlgeschlagen.' >&2; exit 1; fi

local_db=tbx_w6d_local
run_query master "CREATE DATABASE [${local_db}] COLLATE Latin1_General_100_CS_AS;"
deploy "${local_db}" Modules/toolbelt.core.execution-context local
deploy "${local_db}" Modules/toolbelt.core.execution-cancel local
run_file "${local_db}" /workspace/Modules/toolbelt.core.execution-cancel/Deployment \
 ../Tests/Runtime/RepeatCurrent.Contract.sql -v DeploymentMode=local
run_file "${local_db}" /workspace/Modules/toolbelt.core.execution-cancel/Tests/Runtime Lifecycle.Contract.sql
for level in ${levels}; do
 run_query "${local_db}" "ALTER DATABASE [${local_db}] SET COMPATIBILITY_LEVEL=${level};"
 run_file "${local_db}" /workspace/Modules/toolbelt.core.execution-cancel/Tests/Runtime ExecutionCancellation.Contract.sql
 pids=(); for worker in 1 2 3 4; do run_file "${local_db}" /workspace/Modules/toolbelt.core.execution-cancel/Tests/Runtime Concurrency.Contract.sql & pids+=("$!"); done
 for pid in "${pids[@]}"; do wait "${pid}"; done
 run_file "${local_db}" /workspace/Modules/toolbelt.core.execution-cancel/Tests/Runtime Concurrency.Verify.sql
done
deploy "${local_db}" Modules/toolbelt.core.execution-cancel local
set +e; uninstall "${local_db}" Modules/toolbelt.core.execution-cancel 0 0 >"${private_dir}/w6d-uninstall.out" 2>&1; rc=$?; set -e
if [[ ${rc} -eq 0 ]] || ! grep -q '52646' "${private_dir}/w6d-uninstall.out"; then echo 'Data-loss-Guard fehlgeschlagen.' >&2; exit 1; fi

central_db=tbx_w6d_central; consumer_db=tbx_w6d_consumer
run_query master "CREATE DATABASE [${central_db}]; CREATE DATABASE [${consumer_db}];"
deploy "${central_db}" Modules/toolbelt.core.execution-context central
deploy "${central_db}" Modules/toolbelt.core.execution-cancel central
run_file "${central_db}" /workspace/Modules/toolbelt.core.execution-cancel/Deployment \
 ../Tests/Runtime/RepeatCurrent.Contract.sql -v DeploymentMode=central
run_file "${consumer_db}" /workspace/Modules/toolbelt.core.execution-cancel/Tests/Runtime Central.Contract.sql -v ToolbeltDatabase="${central_db}"
uninstall "${central_db}" Modules/toolbelt.core.execution-cancel 1 1
uninstall "${central_db}" Modules/toolbelt.core.execution-context 1 0
uninstall "${local_db}" Modules/toolbelt.core.execution-cancel 0 1
uninstall "${local_db}" Modules/toolbelt.core.execution-context 0 0
echo 'W6d Cooperative Cancellation: erfolgreich'
