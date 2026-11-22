#!/usr/bin/env bash
set -euo pipefail
umask 077
cd "${GITHUB_WORKSPACE:?}/.runtime/common-linux-client"
sha256sum --check --status Toolbelt-Install.zip.sha256
root="$(mktemp -d "${RUNNER_TEMP:?}/common-linux-client.XXXXXXXX")"
container="toolbelt-client-$(basename "$root")"
cleanup() {
  local result=$? found
  found="$(docker container ls -aq --filter "name=^/${container}$")" || exit 1
  if [[ -n "$found" ]]; then
    docker rm -fv "$container" >/dev/null || exit 1
  fi
  found="$(docker container ls -aq --filter "name=^/${container}$")" || exit 1
  [[ -z "$found" ]] || exit 1
  echo 'PACKAGED_LINUX_CONTAINER_ABSENT'
  exit "$result"
}
trap cleanup EXIT

python3 - "$root" "$(git rev-parse HEAD)" <<'PY'
from hashlib import sha256
from io import BytesIO
import json
from pathlib import Path, PurePosixPath
import sys
from zipfile import ZipFile

root, commit = Path(sys.argv[1]), sys.argv[2]
with ZipFile("Toolbelt-Install.zip") as outer:
    manifest = json.loads(outer.read("INSTALL-SET.json"))
    files = manifest["files"]
    if (manifest["source_commit"] != commit
            or sorted(outer.namelist()) != sorted([*files, "INSTALL-SET.json"])
            or any(PurePosixPath(name).is_absolute() or ".." in PurePosixPath(name).parts for name in files)
            or any(sha256(outer.read(name)).hexdigest() != digest for name, digest in files.items())):
        raise SystemExit("PACKAGED_LINUX_INSTALL_SET_BINDING")
    with ZipFile(BytesIO(outer.read("Package/Toolbelt-Install-Payload.zip"))) as inner:
        payload = json.loads(inner.read("PACKAGE.json"))
        if payload["source_commit"] != commit:
            raise SystemExit("PACKAGED_LINUX_PAYLOAD_BINDING")
        profile, = (p for p in payload["profiles"] if (p["platform"], p["mode"]) == ("Portable", "central"))
    outer.extractall(root)
if len(profile["modules"]) != 41 or not profile["assemblies"]:
    raise SystemExit("PACKAGED_LINUX_INVENTORY")
(root / "expected-assemblies").write_text(
    "".join(f"{name}|{digest.upper()}|1\n" for name, digest in sorted(profile["assemblies"].items())),
    encoding="ascii",
)
PY

export MSSQL_SA_PASSWORD="Tbx!$(openssl rand -hex 20)Aa1"
echo "::add-mask::$MSSQL_SA_PASSWORD"
docker run --detach --name "$container" --publish 127.0.0.1::1433 \
  --env ACCEPT_EULA=Y --env MSSQL_PID=Developer --env MSSQL_SA_PASSWORD \
  mcr.microsoft.com/mssql/server:2025-latest >/dev/null
binding="$(docker port "$container" 1433/tcp)"
[[ "$binding" =~ ^127\.0\.0\.1:([0-9]+)$ ]]
export TBX_SERVER="tcp:127.0.0.1,${BASH_REMATCH[1]}"
export TBX_SQLCMD=/opt/mssql-tools18/bin/sqlcmd
sql() {
  SQLCMDPASSWORD="$MSSQL_SA_PASSWORD" "$TBX_SQLCMD" -S "$TBX_SERVER" -U sa \
    -N -C -l 2 -t 30 -b -x -f 65001 -h -1 -W -s '|' -r 1 "$@"
}
ready=false
for attempt in {1..50}; do
  if sql -Q 'SELECT 1;' >"$root/ready.log" 2>&1; then ready=true; break; fi
  if [[ "$(docker inspect -f '{{.State.Running}}' "$container")" != true ]]; then break; fi
  sleep 2
done
[[ "$ready" == true ]] || { echo 'PACKAGED_LINUX_SQL_NOT_READY' >&2; exit 1; }

sql -Q "IF NOT EXISTS (SELECT 1 FROM sys.dm_os_host_info WHERE host_platform=N'Linux')
  OR CONVERT(int,SERVERPROPERTY('ProductMajorVersion'))<>17
  OR NOT EXISTS (SELECT 1 FROM sys.configurations WHERE name=N'clr strict security' AND value=1 AND value_in_use=1)
  THROW 52850,N'PACKAGED_LINUX_TARGET',1;
  EXEC sys.sp_configure N'clr enabled',1; RECONFIGURE;"
sql -Q 'CREATE DATABASE [ContosoPackaged];'
sql -Q 'ALTER DATABASE [ContosoPackaged] SET COMPATIBILITY_LEVEL=170;'

# The client executes on the runner with real ODBC sqlcmd and discovers its
# adjacent payload. The server container has no workspace mount.
cd "$root"
pwsh -NoLogo -NoProfile -NonInteractive -Command '
  $ErrorActionPreference = "Stop"
  if (-not $IsLinux) { throw "PACKAGED_LINUX_CLIENT_OS" }
  $credential = [pscredential]::new("sa", (ConvertTo-SecureString $env:MSSQL_SA_PASSWORD -AsPlainText -Force))
  Remove-Item Env:MSSQL_SA_PASSWORD
  $result = & ./Deployment/Install-Toolbelt.ps1 -ServerInstance $env:TBX_SERVER -Database ContosoPackaged `
      -DeploymentMode central -Credential $credential -SqlcmdPath $env:TBX_SQLCMD -TrustServerCertificate `
      -LoginTimeoutSeconds 15 -CommandTimeoutSeconds 300
  if ($result.Status -cne "INSTALLED_OR_PRESENT" -or $result.Profile -cne "Portable-central" -or
      $result.Modules -ne 41 -or $result.Lifecycle -cne "create-only" -or $result.TrustMethod -cne "auto") {
    throw "PACKAGED_LINUX_RECEIPT"
  }
  "PACKAGED_LINUX_INSTALL_PASS profile=Portable-central modules=41"
'

sql -d ContosoPackaged -Q "SET NOCOUNT ON;
  IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE database_id=DB_ID() AND compatibility_level=170 AND is_trustworthy_on=0)
  OR NOT EXISTS (SELECT 1 FROM sys.configurations WHERE name=N'clr strict security' AND value=1 AND value_in_use=1)
  OR DB_ID(N'ContosoToolbelt') IS NOT NULL
  OR (SELECT COUNT(*) FROM toolbelt_metadata.VW_ObjectUsageSkills)<>259
  THROW 52850,N'PACKAGED_LINUX_CATALOGUE',2;
  SELECT a.name,CONVERT(varchar(128),h.digest,2),
    CASE WHEN EXISTS (SELECT 1 FROM sys.trusted_assemblies t WHERE t.hash=h.digest) THEN 1 ELSE 0 END
  FROM sys.assemblies a JOIN sys.assembly_files f ON f.assembly_id=a.assembly_id AND f.file_id=1
  CROSS APPLY (SELECT HASHBYTES('SHA2_512',f.content)) h(digest)
  WHERE a.is_user_defined=1;" |
  tr -d '\r' | LC_ALL=C sort >"$root/actual-assemblies"
cmp -s "$root/expected-assemblies" "$root/actual-assemblies" ||
  { echo 'PACKAGED_LINUX_ASSEMBLY_DIFF' >&2; exit 1; }
echo 'PACKAGED_LINUX_CATALOGUE_PASS'
