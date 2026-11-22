#!/usr/bin/env bash
set -euo pipefail
case "${TBX_SQL_VERSION:?}/${TBX_INSTALL_MODE:?}" in
  2019/local) major=15; cl=150; collation=Latin1_General_100_CI_AS ;;
  2025/central) major=17; cl=170; collation=Latin1_General_100_CI_AS_SC_UTF8 ;;
  *) echo 'COMMON_PORTABLE_SCOPE' >&2; exit 1 ;;
esac
cd "${GITHUB_WORKSPACE:?}"
mode="$TBX_INSTALL_MODE"
root="$(mktemp -d .runtime/common-portable/run.XXXXXXXX)"
chmod 755 "$root"
profile=".runtime/common-portable/profiles/Install-Portable-$mode.sql"
python3 Tests/Metadata/new_usage_skill_expectations.py "$root/skills.json"
python3 - "$profile" "$root" "$mode" <<'PY'
from hashlib import sha256
import json
from pathlib import Path
import sys

profile, root = map(Path, sys.argv[1:3])
mode = sys.argv[3]
raw = profile.read_bytes()
record = json.loads(profile.with_suffix(".sql.manifest.json").read_text(encoding="utf-8"))
if (record["mode"] != mode or record["platform"] != "Portable" or record["trust"] != "auto"
    or len(record["modules"]) != 41 or record["sql_sha256"] != sha256(raw).hexdigest()
    or not raw.startswith(b"USE [ContosoToolbelt];")):
    raise SystemExit("COMMON_PORTABLE_PROFILE_BINDING")
target = root / "install.sql"
target.write_bytes(raw + b"\nGO\n")
target.chmod(0o644)
catalogue = json.loads((root / "skills.json").read_text(encoding="utf-8"))
fields = ("SchemaName", "ObjectName", "ObjectType", "DatabaseRole", "IsInternal",
          "Description", "SkillFormatVersion", "SkillMarkdown")
rows = []
for item in catalogue:
    values = [str(int(item[key])) if key == "IsInternal" else str(item[key]) for key in fields]
    digest = sha256(chr(31).join(values).encode("utf-16-le")).hexdigest().upper()
    rows.append("|".join((item["SchemaName"], item["ObjectName"], digest)))
if len(rows) != len(set(rows)):
    raise SystemExit("COMMON_CATALOGUE_DUPLICATE")
(root / "expected").write_text("\n".join(sorted(rows)) + "\n", encoding="utf-8")
PY

container=
cleanup() {
  local result=$?
  if [[ -n "$container" ]]; then
    docker rm -f "$container" >/dev/null || exit 1
    [[ -z "$(docker container ls -aq --no-trunc --filter "id=$container")" ]] || exit 1
    echo 'COMMON_PORTABLE_CONTAINER_REMOVED'
  fi
  exit "$result"
}
trap cleanup EXIT
MSSQL_SA_PASSWORD="Tbx!$(openssl rand -hex 20)Aa1"
export MSSQL_SA_PASSWORD
echo "::add-mask::$MSSQL_SA_PASSWORD"
container="$(docker run --detach --env ACCEPT_EULA=Y --env MSSQL_PID=Developer \
  --env MSSQL_SA_PASSWORD --volume "$PWD:/workspace:ro" \
  "mcr.microsoft.com/mssql/server:$TBX_SQL_VERSION-latest")"
client="$(docker exec "$container" sh -c '
for bin in /opt/mssql-tools18/bin/sqlcmd /opt/mssql-tools/bin/sqlcmd; do
  if test -x "$bin"; then echo "$bin"; exit 0; fi
done
exit 1
')"
as_login() {
  local user="$1" password="$2"
  shift 2
  docker exec -i --env SQLCMDPASSWORD="$password" "$container" "$client" \
    -S tcp:127.0.0.1,1433 -U "$user" -C -b "$@"
}
sql() { as_login sa "$MSSQL_SA_PASSWORD" -x -f 65001 -h -1 -W -s '|' -w 512 -r 1 "$@"; }
ready=false
for attempt in {1..50}; do
  if as_login sa "$MSSQL_SA_PASSWORD" -l 2 -Q 'SELECT 1;' >"$root/ready.log" 2>&1; then ready=true; break; fi
  if [[ "$(docker inspect -f '{{.State.Running}}' "$container")" != true ]]; then break; fi
  sleep 2
done
[[ "$ready" == true ]] || { cat "$root/ready.log" >&2; exit 1; }

sql -Q "IF NOT EXISTS (SELECT 1 FROM sys.dm_os_host_info WHERE host_platform=N'Linux')
  OR CONVERT(int,SERVERPROPERTY('ProductMajorVersion'))<>$major
  THROW 52850,N'COMMON_PORTABLE_ENGINE',1;
  IF (SELECT value_in_use FROM sys.configurations WHERE name=N'clr strict security')<>1
  THROW 52850,N'COMMON_PORTABLE_STRICT_SECURITY',2;
  EXEC sys.sp_configure N'clr enabled',1; RECONFIGURE;"
sql -Q "CREATE DATABASE [ContosoToolbelt] COLLATE $collation;"
sql -Q "ALTER DATABASE [ContosoToolbelt] SET COMPATIBILITY_LEVEL=$cl;"
sql -i "/workspace/$root/install.sql" >/dev/null

catalogue_query="SET NOCOUNT ON;
SELECT SchemaName,ObjectName,CONVERT(varchar(64),HASHBYTES('SHA2_256',
  CONCAT(SchemaName,NCHAR(31),ObjectName,NCHAR(31),ObjectType,NCHAR(31),DatabaseRole,NCHAR(31),
  IsInternal,NCHAR(31),Description,NCHAR(31),SkillFormatVersion,NCHAR(31),SkillMarkdown)),2)
FROM [ContosoToolbelt].toolbelt_metadata.VW_ObjectUsageSkills;"
compare_catalogue() {
  LC_ALL=C sort "$root/actual" >"$root/sorted"
  cmp -s "$root/expected" "$root/sorted" || { echo 'COMMON_SKILL_CATALOGUE_DIFF' >&2; exit 1; }
}
sql -d ContosoToolbelt -Q "$catalogue_query" | tr -d '\r' >"$root/actual"
compare_catalogue
echo "COMMON_PORTABLE_SKILLS_PASS $mode rows=$(wc -l <"$root/expected")"

edges="$({ cat Tests/Metadata/FunctionEdgeCases.sql; printf '\nGO\n'; } | sql -d ContosoToolbelt | tr -d '\r')"
[[ "$edges" == 19 ]] || { echo 'COMMON_PORTABLE_COLLATION_RECEIPT' >&2; exit 1; }
echo "COMMON_PORTABLE_COLLATION_PASS $mode checks=19"

if [[ "$mode" == central ]]; then
  reader_password="Tbx!$(openssl rand -hex 20)Aa1"
  echo "::add-mask::$reader_password"
  sql -Q 'CREATE DATABASE [ContosoCaller] COLLATE Latin1_General_100_CS_AS;'
  sql -Q "CREATE LOGIN ContosoSkillReader WITH PASSWORD=N'$reader_password', CHECK_POLICY=OFF;"
  for db in ContosoCaller ContosoToolbelt; do
    sql -d "$db" -Q 'CREATE USER ContosoSkillReader FOR LOGIN ContosoSkillReader; GRANT CONNECT TO ContosoSkillReader;'
  done
  sql -d ContosoToolbelt -Q 'GRANT SELECT ON OBJECT::toolbelt_metadata.VW_ObjectUsageSkills TO ContosoSkillReader;'
  reader() {
    as_login ContosoSkillReader "$reader_password" -x -f 65001 -h -1 -W -s '|' -w 512 -r 1 -d ContosoCaller "$@"
  }
  reader -Q "$catalogue_query" | tr -d '\r' >"$root/actual"
  compare_catalogue
  reader -Q "IF USER_NAME()<>N'ContosoSkillReader' OR IS_SRVROLEMEMBER(N'sysadmin')<>0
      OR IS_MEMBER(N'db_owner')<>0 THROW 52850,N'COMMON_SKILL_IDENTITY',3;
    BEGIN TRY SELECT COUNT(*) FROM ContosoToolbelt.toolbelt_metadata.VW_ModuleCapabilities;
      THROW 52850,N'COMMON_SKILL_EXCESS_ACCESS',4; END TRY BEGIN CATCH IF ERROR_NUMBER()<>229 THROW; END CATCH;"
  sql -d ContosoToolbelt -Q 'REVOKE SELECT ON OBJECT::toolbelt_metadata.VW_ObjectUsageSkills FROM ContosoSkillReader;'
  reader -Q "BEGIN TRY SELECT COUNT(*) FROM ContosoToolbelt.toolbelt_metadata.VW_ObjectUsageSkills;
    THROW 52850,N'COMMON_SKILL_REVOKE',5; END TRY BEGIN CATCH IF ERROR_NUMBER()<>229 THROW; END CATCH;"
  for db in ContosoCaller ContosoToolbelt; do
    sql -d "$db" -Q 'DROP USER ContosoSkillReader;'
  done
  sql -Q "DROP LOGIN ContosoSkillReader;
    IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name=N'ContosoSkillReader')
    THROW 52850,N'COMMON_SKILL_LOGIN_REMAINS',6;"
  echo 'COMMON_PORTABLE_MAPPED_SKILL_PASS checks=3'
fi
