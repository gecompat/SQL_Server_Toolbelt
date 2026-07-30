#!/usr/bin/env bash
set -euo pipefail

sql_image="${TBX_SQL_IMAGE:?TBX_SQL_IMAGE fehlt}"
container_name="tbx-w1-${GITHUB_RUN_ID:-local}"
sa_password="Tbx!$(openssl rand -hex 16)Aa1"
echo "::add-mask::${sa_password}"
cleanup(){ docker rm -f "${container_name}" >/dev/null 2>&1 || true; }
trap cleanup EXIT
docker run --detach --name "${container_name}" --env ACCEPT_EULA=Y --env MSSQL_PID=Developer --env MSSQL_SA_PASSWORD="${sa_password}" --volume "${GITHUB_WORKSPACE:-$(pwd)}:/workspace:ro" "${sql_image}" >/dev/null
sqlcmd_path=""
for candidate in /opt/mssql-tools18/bin/sqlcmd /opt/mssql-tools/bin/sqlcmd; do if docker exec "${container_name}" test -x "${candidate}"; then sqlcmd_path="${candidate}"; break; fi; done
[[ -n "${sqlcmd_path}" ]] || { echo "sqlcmd fehlt." >&2; exit 1; }
for attempt in $(seq 1 60); do docker exec "${container_name}" "${sqlcmd_path}" -S localhost -U sa -P "${sa_password}" -C -b -Q "SELECT 1;" >/dev/null 2>&1 && break; [[ "${attempt}" -eq 60 ]] && { echo "SQL Server nicht bereit." >&2; exit 1; }; sleep 2; done
run_file(){ docker exec --workdir "$2" "${container_name}" "${sqlcmd_path}" -S localhost -U sa -P "${sa_password}" -C -b -d "$1" -i "$3" "${@:4}"; }
run_query(){ docker exec "${container_name}" "${sqlcmd_path}" -S localhost -U sa -P "${sa_password}" -C -b -d "$1" -Q "$2"; }
database="tbx_w1"
run_query master "CREATE DATABASE [${database}] COLLATE Latin1_General_100_CS_AS;"
run_file "${database}" /workspace/Modules/toolbelt.core.generate-series/Deployment Deploy.sql -v DeploymentMode=local
run_file "${database}" /workspace/Modules/toolbelt.datetime.calendar-difference/Deployment Deploy.sql -v DeploymentMode=local
run_file "${database}" /workspace/Modules/toolbelt.string.directional-trim/Deployment Deploy.sql -v DeploymentMode=local
run_file "${database}" /workspace/Modules/toolbelt.conversion.uri-component/Deployment Deploy.sql -v DeploymentMode=local
for level in 150 160 170; do
 run_query "${database}" "ALTER DATABASE [${database}] SET COMPATIBILITY_LEVEL = ${level};"
 run_file "${database}" /workspace/Modules/toolbelt.datetime.calendar-difference/Tests/Runtime CalendarDifference.Contract.sql -v CompatibilityLevel="${level}"
 run_file "${database}" /workspace/Modules/toolbelt.string.directional-trim/Tests/Runtime DirectionalTrim.Contract.sql -v CompatibilityLevel="${level}"
 run_file "${database}" /workspace/Modules/toolbelt.conversion.uri-component/Tests/Runtime UriComponent.Contract.sql -v CompatibilityLevel="${level}"
done
echo "W1 SQL Server 2025 Linux (Compatibility 150/160/170): erfolgreich"
