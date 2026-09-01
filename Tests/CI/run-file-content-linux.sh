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
container_name="tbx-file-content-${GITHUB_RUN_ID:-local}"
sa_password="Tbx!$(openssl rand -hex 16)Aa1"
echo "::add-mask::${sa_password}"

workspace="${GITHUB_WORKSPACE:-$(pwd)}"
fixture_root="${workspace}/.runtime/file-content-fixtures"
rm -rf "${fixture_root}"
mkdir -p "${fixture_root}"
python3 - "${fixture_root}" <<'PY'
import codecs
import sys
from pathlib import Path

root = Path(sys.argv[1])
(root / "utf8-bom.txt").write_bytes(
    codecs.BOM_UTF8 + "Hallo, Welt!\r\nDies ist ein UTF-8-Test.\r\n".encode("utf-8")
)
(root / "ansi.txt").write_bytes("Hallo, Welt!\r\nANSI-Test.\r\n".encode("cp1252"))
(root / "utf16le-bom.txt").write_bytes(
    codecs.BOM_UTF16_LE
    + "Hallo, Welt!\r\nUTF-16-LE korrigiert.\r\n".encode("utf-16-le")
)
(root / "utf16be-bom.txt").write_bytes(
    codecs.BOM_UTF16_BE + "UTF-16-BE-Test".encode("utf-16-be")
)
(root / "utf32le-bom.txt").write_bytes(
    codecs.BOM_UTF32_LE + "UTF-32-LE-Test".encode("utf-32-le")
)
(root / "utf32be-bom.txt").write_bytes(
    codecs.BOM_UTF32_BE + "UTF-32-BE-Test".encode("utf-32-be")
)
(root / "sample.bin").write_bytes(bytes((0x00, 0x01, 0x02, 0xFF, 0xFE, 0x10, 0x20)))
PY

cleanup() {
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
  if docker exec "${container_name}" "${sqlcmd_path}" \
      -S localhost -U sa -P "${sa_password}" -C -b -Q "SELECT 1;" \
      >/dev/null 2>&1; then
    break
  fi
  [[ "${attempt}" -eq 60 ]] \
    && { echo "SQL Server nicht bereit." >&2; exit 1; }
  sleep 2
done

run_file() {
  docker exec --workdir "$2" "${container_name}" "${sqlcmd_path}" \
    -S localhost -U sa -P "${sa_password}" -C -b -d "$1" -i "$3" "${@:4}"
}

run_query() {
  docker exec "${container_name}" "${sqlcmd_path}" \
    -S localhost -U sa -P "${sa_password}" -C -b -d "$1" -Q "$2"
}

deploy_file_content() {
  local target_database="$1"
  local mode="$2"
  run_file "${target_database}" \
    /workspace/Modules/toolbelt.file.content/Deployment \
    Deploy.sql -v DeploymentMode="${mode}"
}

database="tbx_file_content"
run_query master "CREATE DATABASE [${database}] COLLATE Latin1_General_100_CS_AS;"

# ad hoc distributed queries aktivieren, damit OPENROWSET(BULK...) funktioniert.
# Jede sp_configure/RECONFIGURE-Kombination muss in einem eigenen Batch laufen.
run_query master "sp_configure 'show advanced options', 1; RECONFIGURE;"
run_query master "sp_configure 'ad hoc distributed queries', 1; RECONFIGURE;"

deploy_file_content "${database}" local

# Allowlist für synthetische Testdateien vorbereiten.
run_query "${database}" "
INSERT INTO [toolbelt_file].[FileContentRootAllowlist] (RootPath, Description)
VALUES (N'/workspace/.runtime/file-content-fixtures', N'Runtime-Test-Fixtures');"

run_file "${database}" \
  /workspace/Modules/toolbelt.file.content/Tests/Runtime \
  Lifecycle.Contract.sql

for level in ${compatibility_levels}; do
  run_query "${database}" \
    "ALTER DATABASE [${database}] SET COMPATIBILITY_LEVEL = ${level};"
  run_file "${database}" \
    /workspace/Modules/toolbelt.file.content/Tests/Runtime \
    FileContent.Contract.sql -v CompatibilityLevel="${level}" FixtureRoot="/workspace/.runtime/file-content-fixtures"
done

run_file "${database}" \
  /workspace/Modules/toolbelt.file.content/Deployment \
  Uninstall.sql -v ConfirmNoExternalConsumers=0

run_query "${database}" "
IF OBJECT_ID(N'toolbelt_file.USP_LoadBinaryFile') IS NOT NULL
    THROW 51389, N'Lokaler Uninstall liess File-Content-Objekte zurueck.', 1;"
