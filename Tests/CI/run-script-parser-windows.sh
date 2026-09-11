#!/usr/bin/env bash

set -euo pipefail

sql_image="${TBX_SQL_IMAGE:?TBX_SQL_IMAGE fehlt}"
sql_version="${TBX_SQL_VERSION:?TBX_SQL_VERSION fehlt}"
assembly_root_input="${TBX_ASSEMBLY_ROOT:?TBX_ASSEMBLY_ROOT fehlt}"

case "${sql_version}" in
  2019|2022|2025) ;;
  *) echo "Nicht unterstützte SQL-Version: ${sql_version}" >&2; exit 1 ;;
esac

workspace="${GITHUB_WORKSPACE:-$(pwd)}"
assembly_root_host="$(realpath "${assembly_root_input}")"
assembly_relative="$(realpath --relative-to="${workspace}" "${assembly_root_host}")"
case "${assembly_relative}" in ../*|..) echo "Assembly-Artefakte müssen innerhalb des Workspaces liegen." >&2; exit 1 ;; esac
assembly_root_container="/workspace/${assembly_relative}"

assembly_file_host="${assembly_root_host}/Toolbelt.Tsql.ScriptParser.dll"
manifest_file_host="${assembly_root_host}/Toolbelt.Tsql.ScriptParser.trust-manifest.json"
deploy_file_host="${assembly_root_host}/Deploy.WithAssembly.sql"
scriptdom_file_host="${assembly_root_host}/Microsoft.SqlServer.TransactSql.ScriptDom.dll"
for required_file in "${assembly_file_host}" "${scriptdom_file_host}" "${manifest_file_host}" "${deploy_file_host}"; do
  [[ -f "${required_file}" ]] || { echo "Release-Artefakt fehlt: ${required_file}" >&2; exit 1; }
done

python3 - "${assembly_file_host}" "${manifest_file_host}" "${deploy_file_host}" <<'PY'
from hashlib import sha512
import json
from pathlib import Path
import sys

assembly_path, manifest_path, deploy_path = map(Path, sys.argv[1:])
manifest = json.loads(manifest_path.read_text(encoding="utf-8-sig"))
actual_hash = sha512(assembly_path.read_bytes()).hexdigest().upper()
if actual_hash != manifest.get("sha512"):
    raise SystemExit("SHA2-512 des Binaries stimmt nicht mit dem Trust-Manifest überein.")
if manifest.get("assemblySqlName") != "Toolbelt_Tsql_ScriptParser":
    raise SystemExit("Trust-Manifest enthält einen unerwarteten SQL-Assemblynamen.")
if manifest.get("permissionSet") != "UNSAFE":
    raise SystemExit("Trust-Manifest enthält nicht UNSAFE als Permission Set.")
assembly_literal = "0x" + assembly_path.read_bytes().hex().upper()
deploy = deploy_path.read_text(encoding="utf-8-sig")
if deploy.count(assembly_literal) != 1 or "$(AssemblyBits)" in deploy:
    raise SystemExit("Deploy.WithAssembly.sql enthält nicht exakt das gebaute Binary.")
PY

readarray -t manifest_values < <(python3 - "${manifest_file_host}" <<'PY'
import json
from pathlib import Path
import sys
manifest = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8-sig"))
print(manifest["sqlServerHexLiteral"])
print(manifest["description"])
print(manifest["scriptDomSqlServerHexLiteral"])
PY
)
assembly_hash="${manifest_values[0]}"
assembly_description="${manifest_values[1]}"
scriptdom_hash="${manifest_values[2]}"

container_name="tbx-script-parser-${sql_version}-${GITHUB_RUN_ID:-local}"
sa_password="Tbx!$(openssl rand -hex 20)Aa1"
echo "::add-mask::${sa_password}"
trap 'docker rm -f "${container_name}" >/dev/null 2>&1 || true' EXIT

docker run --detach --name "${container_name}" --env ACCEPT_EULA=Y --env MSSQL_PID=Developer \
  --env MSSQL_SA_PASSWORD="${sa_password}" --volume "${workspace}:/workspace:ro" "${sql_image}" >/dev/null

sqlcmd_path=""
for candidate in /opt/mssql-tools18/bin/sqlcmd /opt/mssql-tools/bin/sqlcmd; do
  if docker exec "${container_name}" test -x "${candidate}"; then sqlcmd_path="${candidate}"; break; fi
done
[[ -n "${sqlcmd_path}" ]] || { echo "sqlcmd fehlt." >&2; exit 1; }
for attempt in $(seq 1 60); do
  if docker exec "${container_name}" "${sqlcmd_path}" -S localhost -U sa -P "${sa_password}" -C -b -Q "SELECT 1;" >/dev/null 2>&1; then break; fi
  [[ "${attempt}" -eq 60 ]] && { echo "SQL Server nicht bereit." >&2; exit 1; }
  sleep 2
done

run_file() { docker exec --workdir "$2" "${container_name}" "${sqlcmd_path}" -S localhost -U sa -P "${sa_password}" -C -b -d "$1" -i "$3" "${@:4}"; }
run_query() { docker exec "${container_name}" "${sqlcmd_path}" -S localhost -U sa -P "${sa_password}" -C -b -d "$1" -Q "$2"; }

run_query master "EXEC sys.sp_configure N'show advanced options', 1; RECONFIGURE; EXEC sys.sp_configure N'clr enabled', 1; RECONFIGURE;"
run_file master /workspace/Modules/toolbelt.tsql.script-parser/Deployment Add-TrustedAssembly.sql \
  -v "AssemblyHash=${assembly_hash}" "AssemblyDescription=${assembly_description}" "ScriptDomAssemblyHash=${scriptdom_hash}"

local_database="tbx_script_parser"
central_database="tbx_script_parser_central"
consumer_database="tbx_script_parser_consumer"
run_query master "CREATE DATABASE [${local_database}] COLLATE Latin1_General_100_CS_AS;"
run_file "${local_database}" "${assembly_root_container}" Deploy.WithAssembly.sql -v DeploymentMode=local
run_file "${local_database}" /workspace/Modules/toolbelt.tsql.script-parser/Tests/Runtime Lifecycle.Contract.sql
run_file "${local_database}" /workspace/Modules/toolbelt.tsql.script-parser/Tests/Runtime ScriptParser.Contract.sql
run_query master "CREATE DATABASE [${central_database}] COLLATE Latin1_General_100_BIN2; CREATE DATABASE [${consumer_database}] COLLATE Latin1_General_100_CS_AS;"
run_file "${central_database}" "${assembly_root_container}" Deploy.WithAssembly.sql -v DeploymentMode=central
run_file "${consumer_database}" /workspace/Modules/toolbelt.tsql.script-parser/Tests/Runtime Central.Contract.sql -v "ToolbeltDatabase=${central_database}"
run_file "${central_database}" /workspace/Modules/toolbelt.tsql.script-parser/Deployment Uninstall.sql -v ConfirmNoExternalConsumers=1
run_file "${local_database}" /workspace/Modules/toolbelt.tsql.script-parser/Deployment Uninstall.sql -v ConfirmNoExternalConsumers=0

echo "ScriptParser SQL Server ${sql_version} Windows: erfolgreich"
