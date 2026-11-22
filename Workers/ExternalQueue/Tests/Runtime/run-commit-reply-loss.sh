#!/usr/bin/env bash
set -euo pipefail
umask 077
cd "${GITHUB_WORKSPACE:?}"
root="$(mktemp -d "${RUNNER_TEMP:?}/commit-reply.XXXXXXXX")"
profile='.runtime/worker-commit-reply/install.sql'
python3 - "$profile" <<'PY'
from hashlib import sha256
import json
from pathlib import Path
import sys

profile = Path(sys.argv[1])
record = json.loads(profile.with_suffix(".sql.manifest.json").read_bytes())
data = profile.read_bytes()
if (record["mode"], record["platform"], record["binary_sha512"]) != ("local", "Portable", {}) or (
    record["sql_sha256"] != sha256(data).hexdigest() or not data.startswith(b"USE [ContosoToolbelt];\n")
    or "toolbelt.core.worker-control" not in record["modules"]
):
    raise SystemExit("WORKER_COMMIT_INSTALL_BINDING")
PY

container=
cleanup() {
  local status=$? found
  if [[ -n "$container" ]]; then
    docker rm -fv "$container" >/dev/null || exit 1
    found="$(docker container ls -aq --no-trunc --filter "id=$container")" || exit 1
    [[ -z "$found" ]] || exit 1
    echo WORKER_COMMIT_FIXTURE_CONTAINER_ABSENT
  fi
  exit "$status"
}
trap cleanup EXIT
export MSSQL_SA_PASSWORD="Tbx!$(openssl rand -hex 20)Aa1"
echo "::add-mask::$MSSQL_SA_PASSWORD"
container="$(docker run --detach --publish 127.0.0.1::1433 --env ACCEPT_EULA=Y \
  --env MSSQL_PID=Developer --env MSSQL_SA_PASSWORD mcr.microsoft.com/mssql/server:2025-latest)"
binding="$(docker port "$container" 1433/tcp)"
[[ "$binding" =~ ^127\.0\.0\.1:([0-9]+)$ ]]
export TBX_COMMIT_SQL_PORT="${BASH_REMATCH[1]}"
sql() {
  docker exec -i --env SQLCMDPASSWORD="$MSSQL_SA_PASSWORD" "$container" /opt/mssql-tools18/bin/sqlcmd \
    -S tcp:127.0.0.1,1433 -U sa -C -b -x -l 2 -t 45 "$@"
}
ready=false
for attempt in {1..50}; do
  if sql -Q 'SELECT 1;' >"$root/ready.log" 2>&1; then ready=true; break; fi
  if [[ "$(docker inspect -f '{{.State.Running}}' "$container")" != true ]]; then break; fi
  sleep 2
done
[[ "$ready" == true ]] || { echo WORKER_COMMIT_SQL_NOT_READY >&2; exit 1; }
export TBX_COMMIT_DATABASE="ContosoCommit_$(openssl rand -hex 8)"
sql -Q "CREATE DATABASE [${TBX_COMMIT_DATABASE}];"
{
  sed "1s/^USE \[ContosoToolbelt\];$/USE [${TBX_COMMIT_DATABASE}];/" "$profile"
  printf '\nGO\n'
} | sql -d "$TBX_COMMIT_DATABASE" >/dev/null
sql -d "$TBX_COMMIT_DATABASE" -Q "CREATE TABLE dbo.TbxCommitFixtureMarker(DatabaseName sysname NOT NULL);
  INSERT dbo.TbxCommitFixtureMarker VALUES(DB_NAME());" >/dev/null
pwsh -NoLogo -NoProfile -NonInteractive -File Workers/ExternalQueue/Tests/Runtime/Invoke-CommitReplyLoss.ps1
