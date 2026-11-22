#!/usr/bin/env bash
set -euo pipefail

version="${TBX_SQL_VERSION:?Select SQL Server 2019, 2022 or 2025}"
case "$version" in
  2019) major=15; levels=(150) ;;
  2022) major=16; levels=(150 160) ;;
  2025) major=17; levels=(150 160 170) ;;
  *) echo 'ZIP_PORTABLE_ENGINE_SELECTION' >&2; exit 1 ;;
esac

cd "${GITHUB_WORKSPACE:?A disposable GitHub runner is required}"
artifacts=.runtime/zip-memory-current/installers
test_root=Modules/toolbelt.archive.zip-memory/Tests/Runtime
root="$(mktemp -d .runtime/zip-memory-current/sql.XXXXXXXX)"
chmod 755 "$root"
container=
cleanup() {
  local result=$?
  if [[ -n "$container" ]]; then
    docker rm -f "$container" >/dev/null || exit 1
    [[ -z "$(docker container ls -aq --no-trunc --filter "id=$container")" ]] || exit 1
    echo 'ZIP_PORTABLE_CONTAINER_REMOVED'
  fi
  exit "$result"
}
trap cleanup EXIT

hash="$(python3 - "$artifacts" "$root" <<'PY'
from hashlib import sha256
import json
from pathlib import Path
import re
import sys

artifacts, root = map(Path, sys.argv[1:])
hashes = set()
for mode, database in (("local", "ContosoZipLocal"), ("central", "ContosoZipCentral")):
    sql = artifacts / f"Install-{mode}.sql"
    raw = sql.read_bytes()
    manifest = json.loads(sql.with_suffix(".sql.manifest.json").read_text(encoding="utf-8-sig"))
    binary = manifest["binary_sha512"]
    if (
        manifest["platform"] != "Portable" or manifest["mode"] != mode or manifest["trust"] != "hash"
        or manifest["sql_sha256"].lower() != sha256(raw).hexdigest()
        or set(binary) != {"tlblt_Archive_ZipMemory"}
        or not re.fullmatch(r"[a-fA-F0-9]{128}", binary["tlblt_Archive_ZipMemory"])
        or not raw.startswith(b"USE [ContosoToolbelt];")
    ):
        raise SystemExit("ZIP_PORTABLE_ARTIFACT_BINDING")
    hashes.add(binary["tlblt_Archive_ZipMemory"].lower())
    target = root / sql.name
    target.write_bytes(raw.replace(b"USE [ContosoToolbelt];", f"USE [{database}];".encode(), 1) + b"\nGO\n")
    target.chmod(0o644)
if len(hashes) != 1:
    raise SystemExit("ZIP_PORTABLE_PROFILE_BINARY_MISMATCH")
print("0x" + hashes.pop())
PY
)"

MSSQL_SA_PASSWORD="Tbx!$(openssl rand -hex 20)Aa1"
export MSSQL_SA_PASSWORD
echo "::add-mask::$MSSQL_SA_PASSWORD"
container="$(docker run --detach --network none \
  --env ACCEPT_EULA=Y --env MSSQL_PID=Developer --env MSSQL_SA_PASSWORD \
  --volume "$PWD:/workspace:ro" "mcr.microsoft.com/mssql/server:$version-latest")"
sqlcmd_path="$(docker exec "$container" sh -c '
  for candidate in /opt/mssql-tools18/bin/sqlcmd /opt/mssql-tools/bin/sqlcmd; do
    if test -x "$candidate"; then echo "$candidate"; exit 0; fi
  done
  exit 1
')"
sql() {
  SQLCMDPASSWORD="$MSSQL_SA_PASSWORD" docker exec -i --env SQLCMDPASSWORD "$container" \
    "$sqlcmd_path" -S localhost -U sa -C -b -x -f 65001 -h -1 -W -r 1 "$@"
}
ready=false
for attempt in {1..60}; do
  if sql -l 2 -Q 'SELECT 1;' >/dev/null 2>&1; then ready=true; break; fi
  sleep 2
done
[[ "$ready" == true ]] || { echo 'ZIP_PORTABLE_SQL_STARTUP' >&2; exit 1; }

sql -Q "IF NOT EXISTS (SELECT 1 FROM sys.dm_os_host_info WHERE host_platform=N'Linux')
  OR CONVERT(int,SERVERPROPERTY('ProductMajorVersion'))<>$major
  THROW 54738,N'ZIP_PORTABLE_ACTUAL_ENGINE',1;
  IF (SELECT value_in_use FROM sys.configurations WHERE name=N'clr strict security')<>1
  THROW 54738,N'ZIP_PORTABLE_STRICT_SECURITY',2;
  EXEC sys.sp_configure N'clr enabled',1; RECONFIGURE;
  EXEC sys.sp_add_trusted_assembly @hash=$hash,@description=N'Contoso portable CI test';"

for database in ContosoZipLocal ContosoZipCentral; do
  sql -Q "CREATE DATABASE [$database] COLLATE Latin1_General_100_CI_AS_SC;"
done
sql -Q 'CREATE DATABASE [ContosoZipCaller] COLLATE Latin1_General_100_CS_AS;'
for mode in local central; do
  sql -i "/workspace/$root/Install-$mode.sql" >/dev/null
done
for database in ContosoZipLocal ContosoZipCentral; do
  sql -d "$database" -Q "IF NOT EXISTS (
      SELECT 1 FROM sys.assemblies a
      JOIN sys.assembly_files f ON f.assembly_id=a.assembly_id AND f.file_id=1
      WHERE a.name=N'tlblt_Archive_ZipMemory' AND a.permission_set_desc=N'SAFE_ACCESS'
        AND HASHBYTES('SHA2_512',f.content)=$hash)
    OR (SELECT is_trustworthy_on FROM sys.databases WHERE database_id=DB_ID())<>0
    THROW 54739,N'ZIP_PORTABLE_INSTALLED_BINARY',1;"
done

probe() {
  local fixture="$1" database="$2" prefix="$3" expected="$4"
  local result
  result="$({ sed "s/\[__ZIP_TARGET__\]\./$prefix/g" "$fixture"; printf '\nGO\n'; } |
    sql -d "$database" | tr -d '\r')"
  [[ "$result" == "$expected" ]] || { echo 'ZIP_PORTABLE_NATIVE_RECEIPT' >&2; return 1; }
}
for cl in "${levels[@]}"; do
  for database in ContosoZipLocal ContosoZipCentral ContosoZipCaller; do
    sql -Q "ALTER DATABASE [$database] SET COMPATIBILITY_LEVEL=$cl;"
  done
  fixture="$root/current.sql"
  { printf 'DECLARE @ExpectedCl int=%s;\n' "$cl"; cat "$test_root/ZipMemory.CurrentPortable.sql"; } > "$fixture"
  probe "$fixture" ContosoZipLocal '' 'ZIP_CURRENT_PORTABLE_PASS 4'
  probe "$fixture" ContosoZipCaller '[ContosoZipCentral].' 'ZIP_CURRENT_PORTABLE_PASS 4'
  echo "ZIP_CURRENT_PORTABLE_PASS SQL$version CL$cl local+central checks=8"
done

if [[ "$version" == 2019 ]]; then
  python3 Tests/Release/compose_zip_entry_limits.py "$root/entries"
  python3 - "$root" "$test_root/ZipMemory.ReaderLiveCeilings.sql" <<'PY'
import json
from pathlib import Path
import sys

root, fixture = map(Path, sys.argv[1:])
entry_dir = root / "entries"
metadata = json.loads((entry_dir / "manifest.private.json").read_text(encoding="utf-8"))
for key, entry in metadata["fixtures"].items():
    expected_error = (
        "%komprimierte ZIP-Entry%134217728%" if key.startswith("compressed_")
        else "%ZIP-Entry überschreitet @MaxEntryBytes%"
    )
    crc = entry["crc32"]
    if crc > 2**31 - 1:
        crc -= 2**32
    prologue = f"""
DECLARE @Input varbinary(max) =
   (SELECT BulkColumn FROM OPENROWSET(BULK '/workspace/{entry_dir}/{key}.zip', SINGLE_BLOB) AS Archive);
DECLARE @Packed bigint={entry["compressed_bytes"]}, @Expanded bigint={entry["output_bytes"]},
    @Method int={entry["method"]}, @Crc int={crc}, @Overflow bit={int(entry["overflow"])},
    @Digest binary(32)=0x{entry["payload_sha256"]}, @ExpectedError nvarchar(100)=N'{expected_error}';
"""
    (root / f"{key}.sql").write_text(prologue + fixture.read_text(encoding="utf-8"), encoding="utf-8")
PY
  for entry in compressed_cap compressed_overflow output_cap output_overflow; do
    probe "$root/$entry.sql" ContosoZipLocal '' 'ZIP_PORTABLE_READER_CEILING_PASS 1'
    probe "$root/$entry.sql" ContosoZipCaller '[ContosoZipCentral].' 'ZIP_PORTABLE_READER_CEILING_PASS 1'
  done
  echo 'ZIP_PORTABLE_READER_CEILING_PASS local+central checks=8'
  probe "$test_root/ZipMemory.WriterLiveCeilings.sql" ContosoZipLocal '' 'ZIP_PORTABLE_WRITER_CEILING_PASS 6'
  probe "$test_root/ZipMemory.WriterLiveCeilings.sql" ContosoZipCaller '[ContosoZipCentral].' 'ZIP_PORTABLE_WRITER_CEILING_PASS 6'
  echo 'ZIP_PORTABLE_WRITER_CEILING_PASS local+central checks=12'
fi
