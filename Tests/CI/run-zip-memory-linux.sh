#!/usr/bin/env bash
set -euo pipefail

sql_image="${TBX_SQL_IMAGE:?TBX_SQL_IMAGE fehlt}"
sql_version="${TBX_SQL_VERSION:?TBX_SQL_VERSION fehlt}"
compatibility_level="${TBX_COMPATIBILITY_LEVEL:?TBX_COMPATIBILITY_LEVEL fehlt}"
assembly_root_input="${TBX_ASSEMBLY_ROOT:?TBX_ASSEMBLY_ROOT fehlt}"

case "${compatibility_level}" in
  150|160|170) ;;
  *) echo "Ungültiger Compatibility Level: ${compatibility_level}" >&2; exit 1 ;;
esac

workspace="${GITHUB_WORKSPACE:-$(pwd)}"
assembly_root_host="$(realpath "${assembly_root_input}")"
assembly_relative="$(realpath --relative-to="${workspace}" "${assembly_root_host}")"

case "${assembly_relative}" in
  ../*|..) echo "Assembly-Artefakte müssen innerhalb des Workspaces liegen." >&2; exit 1 ;;
esac

assembly_root_container="/workspace/${assembly_relative}"
assembly_file_host="${assembly_root_host}/Toolbelt.Archive.ZipMemory.dll"
manifest_file_host="${assembly_root_host}/Toolbelt.Archive.ZipMemory.trust-manifest.json"
deploy_file_host="${assembly_root_host}/Deploy.WithAssembly.sql"

for required_file in \
  "${assembly_file_host}" \
  "${manifest_file_host}" \
  "${deploy_file_host}"; do
  [[ -f "${required_file}" ]] \
    || { echo "Release-Artefakt fehlt: ${required_file}" >&2; exit 1; }
done

python3 - \
  "${assembly_file_host}" \
  "${manifest_file_host}" \
  "${deploy_file_host}" <<'PY'
from hashlib import sha512
import json
from pathlib import Path
import sys

assembly_path, manifest_path, deploy_path = map(Path, sys.argv[1:])
assembly = assembly_path.read_bytes()
manifest = json.loads(manifest_path.read_text(encoding="utf-8-sig"))
deploy = deploy_path.read_text(encoding="utf-8-sig")

actual_hash = sha512(assembly).hexdigest().upper()
if actual_hash != manifest.get("sha512"):
    raise SystemExit("SHA2-512 des Binaries stimmt nicht mit dem Trust-Manifest überein.")
if manifest.get("assemblySqlName") != "Toolbelt_Archive_ZipMemory":
    raise SystemExit("Trust-Manifest enthält einen unerwarteten SQL-Assemblynamen.")
if manifest.get("permissionSet") != "SAFE":
    raise SystemExit("Trust-Manifest enthält nicht das Permission Set SAFE.")
if manifest.get("directFrameworkReferences") != ["System", "System.Data"]:
    raise SystemExit("Trust-Manifest enthält einen unerwarteten Abhängigkeitsgraphen.")

assembly_literal = "0x" + assembly.hex().upper()
if deploy.count(assembly_literal) != 1:
    raise SystemExit("Deploy.WithAssembly.sql enthält nicht exakt das gebaute Binary.")
if "$(AssemblyBits)" in deploy:
    raise SystemExit("Deploy.WithAssembly.sql enthält noch den Assembly-Platzhalter.")
PY

readarray -t manifest_values < <(
  python3 - "${manifest_file_host}" <<'PY'
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

container_name="tbx-zip-clr-${sql_version}-${compatibility_level}-${GITHUB_RUN_ID:-local}"
sa_password="Tbx!$(openssl rand -hex 20)Aa1"
echo "::add-mask::${sa_password}"

cleanup() {
  docker rm -f "${container_name}" >/dev/null 2>&1 || true
}
trap cleanup EXIT

docker run --detach \
  --name "${container_name}" \
  --env ACCEPT_EULA=Y \
  --env MSSQL_PID=Developer \
  --env MSSQL_SA_PASSWORD="${sa_password}" \
  --volume "${workspace}:/workspace:ro" \
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
    && { docker logs "${container_name}"; echo "SQL Server nicht bereit." >&2; exit 1; }
  sleep 2
done

run_file() {
  local database="$1"
  local workdir="$2"
  local file="$3"
  shift 3

  docker exec --workdir "${workdir}" "${container_name}" "${sqlcmd_path}" \
    -S localhost -U sa -P "${sa_password}" -C -b -d "${database}" \
    -i "${file}" "$@"
}

run_query() {
  local database="$1"
  local query="$2"

  docker exec "${container_name}" "${sqlcmd_path}" \
    -S localhost -U sa -P "${sa_password}" -C -b -d "${database}" \
    -Q "${query}"
}

deploy_result_table() {
  local target_database="$1"
  local mode="$2"

  run_file "${target_database}" \
    /workspace/Modules/toolbelt.core.result-table/Deployment \
    Deploy.sql \
    -v "DeploymentMode=${mode}"
}

deploy_zip_memory() {
  local target_database="$1"
  local mode="$2"

  run_file "${target_database}" \
    /workspace/Modules/toolbelt.archive.zip-memory/Deployment \
    "${assembly_root_container}/Deploy.WithAssembly.sql" \
    -v "DeploymentMode=${mode}"
}

run_query master "
EXEC sys.sp_configure N'clr enabled', 1;
RECONFIGURE;
IF NOT EXISTS
   (
       SELECT 1
       FROM sys.configurations
       WHERE name = N'clr strict security'
         AND value_in_use = 1
   )
    THROW 51480, N'clr strict security muss auf der disposable CI-Instanz aktiviert bleiben.', 1;"

run_file master \
  /workspace/Modules/toolbelt.archive.zip-memory/Deployment \
  Add-TrustedAssembly.sql \
  -v "AssemblyHash=${assembly_hash}" "AssemblyDescription=${assembly_description}"

run_query master "
IF NOT EXISTS
   (
       SELECT 1
       FROM sys.trusted_assemblies
       WHERE hash = CONVERT(varbinary(64), N'${assembly_hash}', 1)
   )
    THROW 51481, N'Der erwartete CLR-ZIP-Trust-Eintrag fehlt.', 1;"

local_database="tbx_zip_memory"
run_query master "CREATE DATABASE [${local_database}] COLLATE Latin1_General_100_CS_AS;"

deploy_result_table "${local_database}" local
deploy_zip_memory "${local_database}" local

run_file "${local_database}" \
  /workspace/Modules/toolbelt.archive.zip-memory/Tests/Runtime \
  Lifecycle.Contract.sql

run_query "${local_database}" \
  "ALTER DATABASE [${local_database}] SET COMPATIBILITY_LEVEL = ${compatibility_level};"

run_file "${local_database}" \
  /workspace/Modules/toolbelt.archive.zip-memory/Tests/Runtime \
  ZipMemory.Contract.sql \
  -v "CompatibilityLevel=${compatibility_level}"

# Wiederholungsdeployment derselben Release-Artefakte.
deploy_zip_memory "${local_database}" local

central_database="tbx_zip_memory_central"
consumer_database="tbx_zip_memory_consumer"
run_query master "CREATE DATABASE [${central_database}] COLLATE Latin1_General_100_BIN2;"
run_query master "CREATE DATABASE [${consumer_database}] COLLATE Latin1_General_100_CI_AS;"

deploy_result_table "${central_database}" central
deploy_zip_memory "${central_database}" central

run_file "${central_database}" \
  /workspace/Modules/toolbelt.archive.zip-memory/Tests/Runtime \
  Lifecycle.Contract.sql

run_file "${consumer_database}" \
  /workspace/Modules/toolbelt.archive.zip-memory/Tests/Runtime \
  Central.Contract.sql \
  -v "ToolbeltDatabase=${central_database}"

run_file "${central_database}" \
  /workspace/Modules/toolbelt.archive.zip-memory/Deployment \
  Uninstall.sql \
  -v ConfirmNoExternalConsumers=1
run_file "${central_database}" \
  /workspace/Modules/toolbelt.core.result-table/Deployment \
  Uninstall.sql \
  -v ConfirmNoExternalConsumers=1

run_query "${central_database}" "
IF OBJECT_ID(N'toolbelt_archive.USP_ExtractZipEntryFromBinary') IS NOT NULL
   OR OBJECT_ID(N'toolbelt_archive.TVF_InternalExtractZipEntryClr') IS NOT NULL
   OR EXISTS
      (
          SELECT 1
          FROM sys.assemblies
          WHERE name = N'Toolbelt_Archive_ZipMemory'
      )
    THROW 51482, N'Central Uninstall ließ CLR-ZIP-Objekte zurück.', 1;"

run_file "${local_database}" \
  /workspace/Modules/toolbelt.archive.zip-memory/Deployment \
  Uninstall.sql \
  -v ConfirmNoExternalConsumers=0
run_file "${local_database}" \
  /workspace/Modules/toolbelt.core.result-table/Deployment \
  Uninstall.sql \
  -v ConfirmNoExternalConsumers=0

run_query "${local_database}" "
IF OBJECT_ID(N'toolbelt_archive.USP_ExtractZipEntryFromBinary') IS NOT NULL
   OR OBJECT_ID(N'toolbelt_archive.TVF_InternalExtractZipEntryClr') IS NOT NULL
   OR EXISTS
      (
          SELECT 1
          FROM sys.assemblies
          WHERE name = N'Toolbelt_Archive_ZipMemory'
      )
    THROW 51483, N'Lokaler Uninstall ließ CLR-ZIP-Objekte zurück.', 1;"

run_query master "
IF NOT EXISTS
   (
       SELECT 1
       FROM sys.trusted_assemblies
       WHERE hash = CONVERT(varbinary(64), N'${assembly_hash}', 1)
   )
    THROW 51484, N'Der Modul-Uninstall darf den serverweiten Trust-Eintrag nicht entfernen.', 1;"

echo "ZIP-Memory CLR SQL Server ${sql_version} Linux / Compatibility ${compatibility_level}: erfolgreich"
