#!/usr/bin/env bash
set -euo pipefail

sql_image="${TBX_SQL_IMAGE:?TBX_SQL_IMAGE fehlt}"
sql_version="${TBX_SQL_VERSION:?TBX_SQL_VERSION fehlt}"
compatibility_level="${TBX_COMPATIBILITY_LEVEL:?TBX_COMPATIBILITY_LEVEL fehlt}"
assembly_root_input="${TBX_ASSEMBLY_ROOT:?TBX_ASSEMBLY_ROOT fehlt}"

case "${compatibility_level}" in 150|160|170) ;; *) exit 64 ;; esac

workspace="${GITHUB_WORKSPACE:-$(pwd)}"
assembly_root_host="$(realpath "${assembly_root_input}")"
assembly_relative="$(realpath --relative-to="${workspace}" "${assembly_root_host}")"
case "${assembly_relative}" in ../*|..) echo "Assembly-Artefakte müssen im Workspace liegen." >&2; exit 1 ;; esac

assembly_root_container="/workspace/${assembly_relative}"
assembly_file_host="${assembly_root_host}/Toolbelt.String.Regex.dll"
manifest_file_host="${assembly_root_host}/Toolbelt.String.Regex.trust-manifest.json"
deploy_file_host="${assembly_root_host}/Deploy.WithAssembly.sql"
for required_file in "${assembly_file_host}" "${manifest_file_host}" "${deploy_file_host}"; do
  [[ -f "${required_file}" ]] || { echo "Regex-Releaseartefakt fehlt." >&2; exit 1; }
done

python3 - "${assembly_file_host}" "${manifest_file_host}" "${deploy_file_host}" <<'PY'
from hashlib import sha512
import json
from pathlib import Path
import sys

assembly_path, manifest_path, deploy_path = map(Path, sys.argv[1:])
assembly = assembly_path.read_bytes()
manifest = json.loads(manifest_path.read_text(encoding="utf-8-sig"))
deploy = deploy_path.read_text(encoding="utf-8-sig")
actual_hash = sha512(assembly).hexdigest().upper()
assert actual_hash == manifest["sha512"]
assert manifest["moduleId"] == "toolbelt.string.regex"
assert manifest["moduleVersion"] == "1.0.0"
assert manifest["assemblySqlName"] == "Toolbelt_String_Regex"
assert manifest["permissionSet"] == "SAFE"
assert manifest["directFrameworkReferences"] == ["System", "System.Data"]
assert deploy.count("0x" + assembly.hex().upper()) == 1
assert "$(AssemblyBits)" not in deploy
PY

readarray -t manifest_values < <(python3 - "${manifest_file_host}" <<'PY'
import json
from pathlib import Path
import sys
manifest = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8-sig"))
print(manifest["sqlServerHexLiteral"])
print(manifest["description"])
PY
)
assembly_hash="${manifest_values[0]}"
assembly_description="${manifest_values[1]}"

container_name="tbx-regex-${sql_version}-${compatibility_level}-${GITHUB_RUN_ID:-local}"
collision_log=""
sa_password="Tbx!$(openssl rand -hex 20)Aa1"
echo "::add-mask::${sa_password}"
cleanup() {
  docker rm -f "${container_name}" >/dev/null 2>&1 || true
  [[ -z "${collision_log}" ]] || rm -f "${collision_log}"
}
trap cleanup EXIT

docker run --detach --name "${container_name}" \
  --env ACCEPT_EULA=Y --env MSSQL_PID=Developer \
  --env MSSQL_SA_PASSWORD="${sa_password}" \
  --volume "${workspace}:/workspace:ro" "${sql_image}" >/dev/null

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

run_file() {
  local database="$1" workdir="$2" file="$3"; shift 3
  docker exec --workdir "${workdir}" "${container_name}" "${sqlcmd_path}" \
    -S localhost -U sa -P "${sa_password}" -C -b -d "${database}" -i "${file}" "$@"
}
run_query() {
  docker exec "${container_name}" "${sqlcmd_path}" -S localhost -U sa -P "${sa_password}" -C -b -d "$1" -Q "$2"
}
deploy_regex() {
  run_file "$1" /workspace/Modules/toolbelt.string.regex/Deployment \
    "${assembly_root_container}/Deploy.WithAssembly.sql" -v "DeploymentMode=$2"
}

run_query master "EXEC sys.sp_configure N'clr enabled', 1; RECONFIGURE;
IF NOT EXISTS (SELECT 1 FROM sys.configurations WHERE name=N'clr strict security' AND value_in_use=1)
 THROW 52090,N'clr strict security muss aktiviert bleiben.',1;"
run_file master /workspace/Modules/toolbelt.string.regex/Deployment Add-TrustedAssembly.sql \
  -v "AssemblyHash=${assembly_hash}" "AssemblyDescription=${assembly_description}"

local_database="tbx_regex"
central_database="tbx_regex_central"
consumer_database="tbx_regex_consumer"
collision_database="tbx_regex_collision"
run_query master "CREATE DATABASE [${local_database}] COLLATE Latin1_General_100_CS_AS;
CREATE DATABASE [${central_database}] COLLATE Latin1_General_100_BIN2;
CREATE DATABASE [${consumer_database}] COLLATE Latin1_General_100_CI_AS;
CREATE DATABASE [${collision_database}] COLLATE Latin1_General_100_CI_AS;"

deploy_regex "${local_database}" local
run_query "${local_database}" "ALTER DATABASE [${local_database}] SET COMPATIBILITY_LEVEL=${compatibility_level};"
run_file "${local_database}" /workspace/Modules/toolbelt.string.regex/Tests/Runtime Lifecycle.Contract.sql
run_file "${local_database}" /workspace/Modules/toolbelt.string.regex/Tests/Runtime Regex.Contract.sql
deploy_regex "${local_database}" local
run_file "${local_database}" /workspace/Modules/toolbelt.string.regex/Tests/Runtime Lifecycle.Contract.sql

deploy_regex "${central_database}" central
run_file "${consumer_database}" /workspace/Modules/toolbelt.string.regex/Tests/Runtime Central.Contract.sql \
  -v "ToolbeltDatabase=${central_database}"

run_query "${collision_database}" "EXEC(N'CREATE SCHEMA toolbelt_string');
EXEC(N'CREATE FUNCTION toolbelt_string.SVF_RegexCount(@Input nvarchar(max),@Pattern nvarchar(max),@Start int,@Flags nvarchar(4)) RETURNS int AS BEGIN RETURN 0; END');"
set +e
collision_log="$(mktemp)"
deploy_regex "${collision_database}" local >"${collision_log}" 2>&1
collision_status=$?
set -e
[[ "${collision_status}" -ne 0 ]] || { echo "Kollisionspreflight wurde nicht ausgelöst." >&2; exit 1; }
grep -q "Msg 52033" "${collision_log}" || { echo "Unerwarteter Kollisionsfehler." >&2; exit 1; }
run_query "${collision_database}" "
IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.string.regex.Version')
   OR EXISTS(SELECT 1 FROM sys.assemblies WHERE name=N'Toolbelt_String_Regex')
   OR toolbelt_string.SVF_RegexCount(N'a',N'a',1,N'c') <> 0
    THROW 52093,N'Der Kollisionspreflight hat das Ziel mutiert.',1;"

run_file "${central_database}" /workspace/Modules/toolbelt.string.regex/Deployment Uninstall.sql -v ConfirmNoExternalConsumers=1
run_file "${local_database}" /workspace/Modules/toolbelt.string.regex/Deployment Uninstall.sql -v ConfirmNoExternalConsumers=0
run_query "${local_database}" "IF OBJECT_ID(N'toolbelt_string.SVF_RegexIsMatch') IS NOT NULL OR EXISTS(SELECT 1 FROM sys.assemblies WHERE name=N'Toolbelt_String_Regex') THROW 52091,N'Uninstall unvollständig.',1;"
run_query master "IF NOT EXISTS(SELECT 1 FROM sys.trusted_assemblies WHERE hash=CONVERT(varbinary(64),N'${assembly_hash}',1)) THROW 52092,N'Trust wurde unerwartet entfernt.',1;"

echo "Regex SQL Server ${sql_version} / Compatibility ${compatibility_level}: erfolgreich"
