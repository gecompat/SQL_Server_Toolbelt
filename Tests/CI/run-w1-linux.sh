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
run_file "${database}" /workspace/Modules/toolbelt.datetime.calendar-difference/Tests/Runtime Lifecycle.Contract.sql
run_file "${database}" /workspace/Modules/toolbelt.string.directional-trim/Tests/Runtime Lifecycle.Contract.sql
run_file "${database}" /workspace/Modules/toolbelt.conversion.uri-component/Tests/Runtime Lifecycle.Contract.sql
for level in ${compatibility_levels}; do
 run_query "${database}" "ALTER DATABASE [${database}] SET COMPATIBILITY_LEVEL = ${level};"
 run_file "${database}" /workspace/Modules/toolbelt.datetime.calendar-difference/Tests/Runtime CalendarDifference.Contract.sql -v CompatibilityLevel="${level}"
 run_file "${database}" /workspace/Modules/toolbelt.string.directional-trim/Tests/Runtime DirectionalTrim.Contract.sql -v CompatibilityLevel="${level}"
 run_file "${database}" /workspace/Modules/toolbelt.conversion.uri-component/Tests/Runtime UriComponent.Contract.sql -v CompatibilityLevel="${level}"
done
run_file "${database}" /workspace/Modules/toolbelt.datetime.calendar-difference/Deployment Deploy.sql -v DeploymentMode=local
run_file "${database}" /workspace/Modules/toolbelt.string.directional-trim/Deployment Deploy.sql -v DeploymentMode=local
run_file "${database}" /workspace/Modules/toolbelt.conversion.uri-component/Deployment Deploy.sql -v DeploymentMode=local
run_file "${database}" /workspace/Modules/toolbelt.datetime.calendar-difference/Tests/Runtime Lifecycle.Contract.sql
run_file "${database}" /workspace/Modules/toolbelt.string.directional-trim/Tests/Runtime Lifecycle.Contract.sql
run_file "${database}" /workspace/Modules/toolbelt.conversion.uri-component/Tests/Runtime Lifecycle.Contract.sql

central_database="tbx_w1_central"
consumer_database="tbx_w1_consumer"
run_query master "CREATE DATABASE [${central_database}] COLLATE Latin1_General_100_BIN2;"
run_query master "CREATE DATABASE [${consumer_database}] COLLATE Latin1_General_100_CS_AS;"
run_file "${central_database}" /workspace/Modules/toolbelt.core.generate-series/Deployment Deploy.sql -v DeploymentMode=central
run_file "${central_database}" /workspace/Modules/toolbelt.datetime.calendar-difference/Deployment Deploy.sql -v DeploymentMode=central
run_file "${central_database}" /workspace/Modules/toolbelt.string.directional-trim/Deployment Deploy.sql -v DeploymentMode=central
run_file "${central_database}" /workspace/Modules/toolbelt.conversion.uri-component/Deployment Deploy.sql -v DeploymentMode=central
run_file "${central_database}" /workspace/Modules/toolbelt.datetime.calendar-difference/Tests/Runtime Lifecycle.Contract.sql
run_file "${central_database}" /workspace/Modules/toolbelt.string.directional-trim/Tests/Runtime Lifecycle.Contract.sql
run_file "${central_database}" /workspace/Modules/toolbelt.conversion.uri-component/Tests/Runtime Lifecycle.Contract.sql
run_file "${consumer_database}" /workspace/Modules/toolbelt.datetime.calendar-difference/Tests/Runtime Central.Contract.sql -v ToolbeltDatabase="${central_database}"
run_file "${consumer_database}" /workspace/Modules/toolbelt.string.directional-trim/Tests/Runtime Central.Contract.sql -v ToolbeltDatabase="${central_database}"
run_file "${consumer_database}" /workspace/Modules/toolbelt.conversion.uri-component/Tests/Runtime Central.Contract.sql -v ToolbeltDatabase="${central_database}"
run_file "${central_database}" /workspace/Modules/toolbelt.conversion.uri-component/Deployment Uninstall.sql -v ConfirmNoExternalConsumers=1
run_file "${central_database}" /workspace/Modules/toolbelt.string.directional-trim/Deployment Uninstall.sql -v ConfirmNoExternalConsumers=1
run_file "${central_database}" /workspace/Modules/toolbelt.datetime.calendar-difference/Deployment Uninstall.sql -v ConfirmNoExternalConsumers=1
run_query "${central_database}" "IF OBJECT_ID(N'toolbelt_datetime.TVF_CalendarDifference') IS NOT NULL OR OBJECT_ID(N'toolbelt_string.TVF_TrimDirectionalNvarchar') IS NOT NULL OR OBJECT_ID(N'toolbelt_string.TVF_TrimDirectionalVarchar') IS NOT NULL OR OBJECT_ID(N'toolbelt_conversion.TVF_UriComponentEncode') IS NOT NULL OR OBJECT_ID(N'toolbelt_conversion.TVF_UriComponentDecode') IS NOT NULL OR OBJECT_ID(N'toolbelt_conversion.SVF_UriComponentEncode') IS NOT NULL OR OBJECT_ID(N'toolbelt_conversion.SVF_UriComponentDecode') IS NOT NULL THROW 52739,N'Central Uninstall ließ W1-Objekte zurück.',1;"
echo "W1 SQL Server ${sql_version} (Compatibility ${compatibility_levels}): erfolgreich"
