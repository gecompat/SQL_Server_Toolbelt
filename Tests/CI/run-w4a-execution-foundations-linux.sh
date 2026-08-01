#!/usr/bin/env bash
set -euo pipefail
sql_image="${TBX_SQL_IMAGE:?TBX_SQL_IMAGE fehlt}"
container_name="tbx-w4a-${GITHUB_RUN_ID:-local}"
sa_password="Tbx!$(openssl rand -hex 16)Aa1"
echo "::add-mask::${sa_password}"
cleanup(){ docker rm -f "${container_name}" >/dev/null 2>&1 || true; }
trap cleanup EXIT

docker run -d --name "${container_name}" -e ACCEPT_EULA=Y -e MSSQL_PID=Developer -e MSSQL_SA_PASSWORD="${sa_password}" -v "${GITHUB_WORKSPACE:-$(pwd)}:/workspace:ro" "${sql_image}" >/dev/null
sqlcmd_path=""
for candidate in /opt/mssql-tools18/bin/sqlcmd /opt/mssql-tools/bin/sqlcmd; do
 if docker exec "${container_name}" test -x "${candidate}"; then sqlcmd_path="${candidate}"; break; fi
done
[[ -n "${sqlcmd_path}" ]] || { echo 'sqlcmd fehlt' >&2; exit 1; }
for attempt in $(seq 1 60); do
 if docker exec "${container_name}" "${sqlcmd_path}" -S localhost -U sa -P "${sa_password}" -C -b -Q 'SELECT 1' >/dev/null 2>&1; then break; fi
 [[ "${attempt}" -eq 60 ]] && { docker logs "${container_name}"; exit 1; }
 sleep 2
done
run_query(){ docker exec "${container_name}" "${sqlcmd_path}" -S localhost -U sa -P "${sa_password}" -C -b -d "$1" -Q "$2"; }
run_file(){ local db="$1" wd="$2" file="$3"; shift 3; docker exec --workdir "${wd}" "${container_name}" "${sqlcmd_path}" -S localhost -U sa -P "${sa_password}" -C -b -d "${db}" -i "${file}" "$@"; }
deploy(){ run_file "$1" "/workspace/$2/Deployment" Deploy.sql -v DeploymentMode="$3"; }
uninstall(){ run_file "$1" "/workspace/$2/Deployment" Uninstall.sql -v ConfirmNoExternalConsumers="$3"; }

local_db=tbx_w4a_local
run_query master "CREATE DATABASE [${local_db}] COLLATE Latin1_General_100_CS_AS;"
deploy "${local_db}" Modules/toolbelt.core.result-table local
deploy "${local_db}" Modules/toolbelt.core.execution-context local
deploy "${local_db}" Modules/toolbelt.core.error-envelope local
run_file "${local_db}" /workspace/Modules/toolbelt.core.execution-context/Tests/Runtime Lifecycle.Contract.sql
run_file "${local_db}" /workspace/Modules/toolbelt.core.error-envelope/Tests/Runtime Lifecycle.Contract.sql
for level in 150 160 170; do
 run_query "${local_db}" "ALTER DATABASE [${local_db}] SET COMPATIBILITY_LEVEL = ${level};"
 run_file "${local_db}" /workspace/Modules/toolbelt.core.execution-context/Tests/Runtime ExecutionContext.Contract.sql
 run_file "${local_db}" /workspace/Modules/toolbelt.core.error-envelope/Tests/Runtime ErrorEnvelope.Contract.sql
 multi=()
 for worker in 1 2 3 4; do
  run_file "${local_db}" /workspace/Modules/toolbelt.core.execution-context/Tests/Runtime MultiSession.Contract.sql -v WorkerId="${worker}" & multi+=("$!")
 done
 for pid in "${multi[@]}"; do wait "${pid}"; done
done
# Wiederholungsdeployment
deploy "${local_db}" Modules/toolbelt.core.execution-context local
deploy "${local_db}" Modules/toolbelt.core.error-envelope local

central_db=tbx_w4a_central
consumer_db=tbx_w4a_consumer
run_query master "CREATE DATABASE [${central_db}] COLLATE Latin1_General_100_BIN2; CREATE DATABASE [${consumer_db}] COLLATE Latin1_General_100_CS_AS;"
deploy "${central_db}" Modules/toolbelt.core.result-table central
deploy "${central_db}" Modules/toolbelt.core.execution-context central
deploy "${central_db}" Modules/toolbelt.core.error-envelope central
run_file "${consumer_db}" /workspace/Modules/toolbelt.core.execution-context/Tests/Runtime Central.Contract.sql -v ToolbeltDatabase="${central_db}"
run_file "${consumer_db}" /workspace/Modules/toolbelt.core.error-envelope/Tests/Runtime Central.Contract.sql -v ToolbeltDatabase="${central_db}"
uninstall "${central_db}" Modules/toolbelt.core.error-envelope 1
uninstall "${central_db}" Modules/toolbelt.core.execution-context 1
uninstall "${central_db}" Modules/toolbelt.core.result-table 1
uninstall "${local_db}" Modules/toolbelt.core.error-envelope 0
uninstall "${local_db}" Modules/toolbelt.core.execution-context 0
uninstall "${local_db}" Modules/toolbelt.core.result-table 0

echo 'W4a Execution-Grundlagen Linux: erfolgreich'
