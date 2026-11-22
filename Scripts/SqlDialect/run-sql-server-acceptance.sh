#!/usr/bin/env bash
set -euo pipefail
umask 077
cd "${GITHUB_WORKSPACE:?}"
root="$(mktemp -d "${RUNNER_TEMP:?}/sql-dialect.XXXXXXXX")"
python Scripts/SqlDialect/native_cases.py >"$root/cases.json"
container=
cleanup() {
  local status=$? found
  if [[ -n "$container" ]]; then
    docker rm -fv "$container" >/dev/null || exit 1
    found="$(docker container ls -aq --no-trunc --filter "id=$container")" || exit 1
    [[ -z "$found" ]] || exit 1
    echo NATIVE_SQL_DIALECT_CONTAINER_ABSENT
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
export TBX_DIALECT_SQL_PORT="${BASH_REMATCH[1]}"
ready=false
for attempt in {1..45}; do
  if docker exec --env SQLCMDPASSWORD="$MSSQL_SA_PASSWORD" "$container" /opt/mssql-tools18/bin/sqlcmd \
      -S tcp:127.0.0.1,1433 -U sa -C -b -l 2 -Q 'SELECT 1;' >"$root/ready.log" 2>&1; then
    ready=true
    break
  fi
  if [[ "$(docker inspect -f '{{.State.Running}}' "$container")" != true ]]; then break; fi
  sleep 2
done
[[ "$ready" == true ]] || { echo NATIVE_SQL_DIALECT_NOT_READY >&2; exit 1; }
pwsh -NoLogo -NoProfile -NonInteractive -File Scripts/SqlDialect/Invoke-SqlServerAcceptance.ps1 -CasesPath "$root/cases.json"
