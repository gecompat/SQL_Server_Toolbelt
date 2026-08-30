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

container_name="tbx-work-queue-${GITHUB_RUN_ID:-local}"
sa_password="Tbx!$(openssl rand -hex 16)Aa1"
echo "::add-mask::${sa_password}"
local_db=tbx_work_queue_local
central_db=tbx_work_queue_central
consumer_db=tbx_work_queue_consumer
dependency_db=tbx_work_queue_dependency
collision_db=tbx_work_queue_collision
sqlcmd_path=""

cleanup() {
  if [[ -n "${sqlcmd_path}" ]]; then
    for db in "${consumer_db}" "${central_db}" "${local_db}" "${dependency_db}" "${collision_db}"; do
      docker exec "${container_name}" "${sqlcmd_path}" -S localhost -U sa -P "${sa_password}" -C -b -d master \
        -Q "IF DB_ID(N'${db}') IS NOT NULL BEGIN ALTER DATABASE [${db}] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [${db}]; END;" >/dev/null 2>&1 || true
    done
  fi
  rm -f /tmp/work-queue-dependency.out /tmp/work-queue-collision.out /tmp/work-queue-uninstall.out
  docker rm -f "${container_name}" >/dev/null 2>&1 || true
}
trap cleanup EXIT

docker run -d --name "${container_name}" -e ACCEPT_EULA=Y -e MSSQL_PID=Developer \
  -e MSSQL_SA_PASSWORD="${sa_password}" -v "${GITHUB_WORKSPACE:-$(pwd)}:/workspace:ro" "${sql_image}" >/dev/null

for candidate in /opt/mssql-tools18/bin/sqlcmd /opt/mssql-tools/bin/sqlcmd; do
  if docker exec "${container_name}" test -x "${candidate}"; then sqlcmd_path="${candidate}"; break; fi
done
[[ -n "${sqlcmd_path}" ]] || { echo "sqlcmd fehlt" >&2; exit 1; }

for attempt in $(seq 1 60); do
  if docker exec "${container_name}" "${sqlcmd_path}" -S localhost -U sa -P "${sa_password}" -C -b -Q "SELECT 1" >/dev/null 2>&1; then break; fi
  [[ "${attempt}" -lt 60 ]] || exit 1
  sleep 2
done

run_query() { docker exec "${container_name}" "${sqlcmd_path}" -S localhost -U sa -P "${sa_password}" -C -b -d "$1" -Q "$2"; }
run_file() {
  local db="$1" workdir="$2" file="$3"; shift 3
  docker exec --workdir "${workdir}" "${container_name}" "${sqlcmd_path}" -S localhost -U sa -P "${sa_password}" -C -b -d "${db}" -i "${file}" "$@"
}
deploy() { run_file "$1" "/workspace/$2/Deployment" Deploy.sql -v DeploymentMode="$3"; }
uninstall() { run_file "$1" "/workspace/$2/Deployment" Uninstall.sql -v ConfirmNoExternalConsumers="$3" AllowDataLoss="$4"; }

run_query master "CREATE DATABASE [${dependency_db}] COLLATE Latin1_General_100_CS_AS;"
set +e
deploy "${dependency_db}" Modules/toolbelt.core.work-queue local >/tmp/work-queue-dependency.out 2>&1
dependency_rc=$?
set -e
if [[ "${dependency_rc}" -eq 0 ]] || ! grep -q "51942" /tmp/work-queue-dependency.out; then
  echo "Der Dependency-Preflight ist inkonsistent." >&2; exit 1
fi

run_query master "CREATE DATABASE [${collision_db}] COLLATE Latin1_General_100_CS_AS;"
deploy "${collision_db}" Modules/toolbelt.core.result-table local
deploy "${collision_db}" Modules/toolbelt.core.work-type local
run_query "${collision_db}" "CREATE VIEW toolbelt_core.VW_WorkQueue AS SELECT 1 AS ForeignObject;"
set +e
deploy "${collision_db}" Modules/toolbelt.core.work-queue local >/tmp/work-queue-collision.out 2>&1
collision_rc=$?
set -e
if [[ "${collision_rc}" -eq 0 ]] || ! grep -q "51944" /tmp/work-queue-collision.out; then
  echo "Der Fremdobjekt-Preflight ist inkonsistent." >&2; exit 1
fi

run_query master "CREATE DATABASE [${local_db}] COLLATE Latin1_General_100_CS_AS;"
deploy "${local_db}" Modules/toolbelt.core.result-table local
deploy "${local_db}" Modules/toolbelt.core.work-type local
deploy "${local_db}" Modules/toolbelt.core.work-queue local
run_file "${local_db}" /workspace/Modules/toolbelt.core.work-queue/Tests/Runtime Lifecycle.Contract.sql
for level in ${compatibility_levels}; do
  run_query "${local_db}" "ALTER DATABASE [${local_db}] SET COMPATIBILITY_LEVEL=${level};"
  run_file "${local_db}" /workspace/Modules/toolbelt.core.work-queue/Tests/Runtime WorkQueue.Contract.sql
done

run_query "${local_db}" "EXEC(N'CREATE OR ALTER PROCEDURE dbo.USP_TbxQueueConcurrent AS BEGIN SET NOCOUNT ON; END;'); EXEC toolbelt_core.USP_RegisterWorkType @WorkTypeName='test.queue.concurrent',@HandlerSchema=N'dbo',@HandlerProcedure=N'USP_TbxQueueConcurrent'; CREATE TABLE #S(Dummy int NULL); EXEC toolbelt_core.USP_EnqueueWork @WorkTypeName='test.queue.concurrent',@ResultTable=N'#S';"
workers=()
for worker in 1 2 3 4; do
  run_file "${local_db}" /workspace/Modules/toolbelt.core.work-queue/Tests/Runtime Concurrency.Contract.sql & workers+=("$!")
done
for pid in "${workers[@]}"; do wait "${pid}"; done
run_file "${local_db}" /workspace/Modules/toolbelt.core.work-queue/Tests/Runtime Concurrency.Verify.sql
run_query "${local_db}" "DELETE wi FROM toolbelt_core.WorkItem wi JOIN toolbelt_core.WorkType wt ON wt.WorkTypeId=wi.WorkTypeId WHERE wt.WorkTypeName='test.queue.concurrent'; DELETE FROM toolbelt_core.WorkType WHERE WorkTypeName='test.queue.concurrent'; DROP PROCEDURE dbo.USP_TbxQueueConcurrent;"

run_query "${local_db}" "EXEC(N'CREATE OR ALTER PROCEDURE dbo.USP_TbxQueuePreserve AS BEGIN SET NOCOUNT ON; END;'); EXEC toolbelt_core.USP_RegisterWorkType @WorkTypeName='test.queue.preserve',@HandlerSchema=N'dbo',@HandlerProcedure=N'USP_TbxQueuePreserve'; CREATE TABLE #S(Dummy int NULL); EXEC toolbelt_core.USP_EnqueueWork @WorkTypeName='test.queue.preserve',@ResultTable=N'#S';"
deploy "${local_db}" Modules/toolbelt.core.work-queue local
run_query "${local_db}" "IF NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkItem wi JOIN toolbelt_core.WorkType wt ON wt.WorkTypeId=wi.WorkTypeId WHERE wt.WorkTypeName='test.queue.preserve') THROW 52960,N'Redeploy verlor persistente Daten.',1;"

set +e
uninstall "${local_db}" Modules/toolbelt.core.work-queue 0 0 >/tmp/work-queue-uninstall.out 2>&1
uninstall_rc=$?
set -e
if [[ "${uninstall_rc}" -eq 0 ]] || ! grep -q "51949" /tmp/work-queue-uninstall.out; then
  echo "Der Datenverlustschutz ist inkonsistent." >&2; exit 1
fi
run_query "${local_db}" "IF OBJECT_ID(N'toolbelt_core.WorkItem',N'U') IS NULL OR NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkItem) THROW 52961,N'Der abgelehnte Uninstall veränderte Daten oder Objektbestand.',1;"
run_query "${local_db}" "DELETE wi FROM toolbelt_core.WorkItem wi JOIN toolbelt_core.WorkType wt ON wt.WorkTypeId=wi.WorkTypeId WHERE wt.WorkTypeName='test.queue.preserve'; DELETE FROM toolbelt_core.WorkType WHERE WorkTypeName='test.queue.preserve'; DROP PROCEDURE dbo.USP_TbxQueuePreserve;"

run_query master "CREATE DATABASE [${central_db}] COLLATE Latin1_General_100_BIN2; CREATE DATABASE [${consumer_db}] COLLATE Latin1_General_100_CS_AS;"
deploy "${central_db}" Modules/toolbelt.core.result-table central
deploy "${central_db}" Modules/toolbelt.core.work-type central
deploy "${central_db}" Modules/toolbelt.core.work-queue central
run_query "${central_db}" "EXEC(N'CREATE OR ALTER PROCEDURE dbo.USP_TbxQueueCentral AS BEGIN SET NOCOUNT ON; END;'); EXEC toolbelt_core.USP_RegisterWorkType @WorkTypeName='test.queue.central',@HandlerSchema=N'dbo',@HandlerProcedure=N'USP_TbxQueueCentral';"
run_file "${consumer_db}" /workspace/Modules/toolbelt.core.work-queue/Tests/Runtime Central.Contract.sql -v ToolbeltDatabase="${central_db}"

uninstall "${central_db}" Modules/toolbelt.core.work-queue 1 1
uninstall "${central_db}" Modules/toolbelt.core.work-type 1 1
uninstall "${central_db}" Modules/toolbelt.core.result-table 1 1
uninstall "${local_db}" Modules/toolbelt.core.work-queue 0 0
uninstall "${local_db}" Modules/toolbelt.core.work-type 0 1
uninstall "${local_db}" Modules/toolbelt.core.result-table 0 1

echo "E1a Work Queue: erfolgreich"
