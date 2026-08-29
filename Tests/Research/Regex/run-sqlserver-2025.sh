#!/usr/bin/env bash
set -euo pipefail

sql_image="${TBX_SQL_IMAGE:?TBX_SQL_IMAGE fehlt}"
sql_version="${TBX_SQL_VERSION:-2025}"
if [[ "${sql_version}" != "2025" ]]; then
  echo "R1a native Semantik ist ausschließlich auf SQL Server 2025 ausführbar." >&2
  exit 1
fi

container_name="tbx-r1a-${GITHUB_RUN_ID:-local}"
sa_password="Tbx!$(openssl rand -hex 16)Aa1"
database="tbx_r1a_regex_semantics"
database_created="0"

if [[ "${GITHUB_ACTIONS:-}" == "true" ]]; then
  echo "::add-mask::${sa_password}"
fi

run_query() {
  docker exec "${container_name}" "${sqlcmd_path}" \
    -S localhost -U sa -P "${sa_password}" -C -b -d "$1" -Q "$2"
}

cleanup() {
  set +e
  if [[ "${database_created}" == "1" ]]; then
    run_query master \
      "IF DB_ID(N'${database}') IS NOT NULL BEGIN ALTER DATABASE [${database}] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [${database}]; END;" \
      >/dev/null 2>&1
  fi
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
[[ -n "${sqlcmd_path}" ]] || { echo "sqlcmd fehlt." >&2; exit 1; }

for attempt in $(seq 1 60); do
  if run_query master "SELECT 1;" >/dev/null 2>&1; then
    break
  fi
  [[ "${attempt}" -eq 60 ]] \
    && { echo "SQL Server nicht bereit." >&2; exit 1; }
  sleep 2
done

run_query master "CREATE DATABASE [${database}];"
database_created="1"

for compatibility_level in 150 160 170; do
  run_query master \
    "ALTER DATABASE [${database}] SET COMPATIBILITY_LEVEL = ${compatibility_level};"
  docker exec --workdir /workspace/Tests/Research/Regex \
    "${container_name}" "${sqlcmd_path}" \
    -S localhost -U sa -P "${sa_password}" -C -b -d "${database}" \
    -i SqlServer2025Compatibility.sql \
    -v CompatibilityLevel="${compatibility_level}"
done

docker exec --workdir /workspace/Tests/Research/Regex \
  "${container_name}" "${sqlcmd_path}" \
  -S localhost -U sa -P "${sa_password}" -C -b -d "${database}" \
  -i SqlServer2025Semantics.sql

run_query master \
  "ALTER DATABASE [${database}] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [${database}];"
database_created="0"

echo "R1a SQL Server 2025 native Semantik: erfolgreich"
