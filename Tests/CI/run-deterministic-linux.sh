#!/usr/bin/env bash
set -euo pipefail
# Im Lab liefert der bestehende schema-validierte Adapter den Docker-Shim;
# echte disposable Container entstehen ausschließlich im Runnerpfad.
sql_version="${TBX_SQL_VERSION:-2025}"
case "${sql_version}" in
  2019) levels="150" ;;
  2022) levels="150 160" ;;
  2025) levels="150 160 170" ;;
  *) echo "Unsupported SQL version" >&2; exit 1 ;;
esac
container="tbx-deterministic-${GITHUB_RUN_ID:-local}"
password="Tbx!$(openssl rand -hex 16)Aa1"
echo "::add-mask::${password}"
cleanup() { docker rm -f "${container}" >/dev/null 2>&1 || true; }
trap cleanup EXIT
docker run --detach --name "${container}" --env ACCEPT_EULA=Y --env MSSQL_PID=Developer \
  --env MSSQL_SA_PASSWORD="${password}" --volume "${GITHUB_WORKSPACE:-$(pwd)}:/workspace:ro" \
  "${TBX_SQL_IMAGE:?SQL image missing}" >/dev/null
sqlcmd=""
for candidate in /opt/mssql-tools18/bin/sqlcmd /opt/mssql-tools/bin/sqlcmd; do
  if docker exec "${container}" test -x "${candidate}"; then sqlcmd="${candidate}"; break; fi
done
[[ -n "${sqlcmd}" ]] || exit 1
ready=0
for attempt in $(seq 1 60); do
  if docker exec "${container}" "${sqlcmd}" -S localhost -U sa -P "${password}" -C -b -Q 'SELECT 1;' >/dev/null 2>&1; then ready=1; break; fi
  sleep 2
done
[[ "${ready}" == 1 ]] || { echo "SQL login not ready" >&2; exit 1; }
query() { docker exec "${container}" "${sqlcmd}" -S localhost -U sa -P "${password}" -C -b -d "$1" -Q "$2"; }
file() { docker exec --workdir "$2" "${container}" "${sqlcmd}" -S localhost -U sa -P "${password}" -C -b -d "$1" -i "$3" "${@:4}"; }
# Fehlernummern exakt prüfen; keine rohe SQL-/Verbindungsdiagnostik ausgeben.
expect_failure() {
  local db="$1" directory="$2" script="$3" number="$4" output status
  shift 4
  set +e
  output=$(file "${db}" "${directory}" "${script}" "$@" 2>&1)
  status=$?
  set -e
  local signature=0 detected=none prefix=0
  [[ "${output}" == *"DETERMINISTIC_LIFECYCLE_CALLER_TRANSACTION:"* ]] && prefix=1
  if [[ "${output}" =~ Msg[[:space:]]([0-9]+), ]]; then detected="${BASH_REMATCH[1]}"; fi
  if [[ "${number}" == 50000 ]]; then
    # ODBC/sqlcmd kann RAISERROR nur mit Driver-/Prefixtext ausgeben. Die
    # clientseitige Probe prüft zusätzlich echte Number50000/State1.
    [[ ${prefix} == 1 ]] && signature=1
  elif [[ "${detected}" == "${number}" ]]; then signature=1
  fi
  [[ ${status} -ne 0 && ${signature} == 1 ]] || {
    for marker in "Error occurred while opening" "No such file" "not defined" "Deploy.CallerGuard.sql" "Uninstall.CallerGuard.sql" "ReleaseManifest.sql" "Deploy.sql" "Uninstall.sql"; do
      if [[ "${output}" == *"${marker}"* ]]; then echo "Expected-error diagnostic marker: ${marker}" >&2; fi
    done
    echo "Lifecycle expected-error oracle failed (${number}; exit=${status}; msg=${detected}; prefix=${prefix})" >&2; exit 1;
  }
}
metadata() {
  if [[ "${TBX_SQL_TARGET:-runner}" == "lab" ]]; then
    local root
    root="$(git rev-parse --show-toplevel)"
    pwsh -NoProfile -File "${root}/Modules/toolbelt.pseudonymization.deterministic/Tests/Runtime/SelectMetadata.Contract.ps1" \
      -Database "${1}_${TBX_TEST_DB_SUFFIX:?Synthetic suffix missing}"
  fi
}
module=/workspace/Modules/toolbelt.pseudonymization.deterministic
database=tbx_deterministic
query master "CREATE DATABASE [${database}] COLLATE Latin1_General_100_CS_AS;"
file "${database}" /workspace/Modules/toolbelt.core.result-table/Deployment Deploy.sql -v DeploymentMode=local
file "${database}" "${module}/Deployment" Deploy.sql -v DeploymentMode=local
for level in ${levels}; do
  query "${database}" "ALTER DATABASE [${database}] SET COMPATIBILITY_LEVEL=${level};"
  file "${database}" "${module}/Tests/Runtime" Range.Contract.sql
  file "${database}" "${module}/Tests/Runtime" DateShift.Contract.sql
  file "${database}" "${module}/Tests/Runtime" Lookup.Contract.sql
  file "${database}" "${module}/Tests/Runtime" Lookup.Boundaries.sql
done
file "${database}" "${module}/Tests/Runtime" Lifecycle.Contract.sql
metadata "${database}"
for abort in ON OFF; do
  expect_failure "${database}" "${module}/Deployment" "${module}/Tests/Runtime/Deploy.CallerGuard.sql" 50000 -v Abort="${abort}" DeploymentMode=local
  expect_failure "${database}" "${module}/Deployment" "${module}/Tests/Runtime/Uninstall.CallerGuard.sql" 50000 -v Abort="${abort}" ConfirmNoExternalConsumers=0
done
# SourceHash bleibt diagnostisch; bekannte eigene Releaseobjekte reparierbar.
query "${database}" "EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.SourceHash',@value=N'synthetic-drift',@level0type=N'SCHEMA',@level0name=N'toolbelt_pseudonymization',@level1type=N'FUNCTION',@level1name=N'TVF_DeterministicRange';"
file "${database}" "${module}/Deployment" Deploy.sql -v DeploymentMode=local
file "${database}" "${module}/Tests/Runtime" Lifecycle.Contract.sql
query "${database}" "EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.Module.toolbelt.pseudonymization.deterministic.Version',@value=N'1.0.0 ';"
expect_failure "${database}" "${module}/Deployment" Deploy.sql 54023 -v DeploymentMode=local
query "${database}" "IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.pseudonymization.deterministic.Version' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(64),value))=CONVERT(varbinary(max),N'1.0.0 ')) THROW 54090,N'Unknown version preflight mutated marker.',1; EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.Module.toolbelt.pseudonymization.deterministic.Version',@value=N'1.0.0';"
query "${database}" "CREATE VIEW dbo.SyntheticDeterministicDependency AS SELECT Value FROM toolbelt_pseudonymization.TVF_DeterministicRange(0x01,1,0,1,2);"
expect_failure "${database}" "${module}/Deployment" Uninstall.sql 54027 -v ConfirmNoExternalConsumers=0
query "${database}" "IF OBJECT_ID(N'dbo.SyntheticDeterministicDependency',N'V') IS NULL OR OBJECT_ID(N'toolbelt_pseudonymization.TVF_DeterministicRange',N'IF') IS NULL THROW 54090,N'Dependent preflight mutated objects.',1; DROP VIEW dbo.SyntheticDeterministicDependency;"
# Eigener Function-kind-Drift, kein erfundener Vorgänger-Upgrade.
query "${database}" "DROP FUNCTION toolbelt_pseudonymization.TVF_DeterministicRange;"
query "${database}" "CREATE FUNCTION toolbelt_pseudonymization.TVF_DeterministicRange(@Key varbinary(max),@MappingVersion int,@Seed bigint,@Min bigint,@Max bigint) RETURNS bigint AS BEGIN RETURN 7; END;"
query "${database}" "EXEC sys.sp_addextendedproperty @name=N'Toolbelt.ModuleId',@value=N'toolbelt.pseudonymization.deterministic',@level0type=N'SCHEMA',@level0name=N'toolbelt_pseudonymization',@level1type=N'FUNCTION',@level1name=N'TVF_DeterministicRange'; EXEC sys.sp_addextendedproperty @name=N'Toolbelt.ModuleVersion',@value=N'1.0.0',@level0type=N'SCHEMA',@level0name=N'toolbelt_pseudonymization',@level1type=N'FUNCTION',@level1name=N'TVF_DeterministicRange';"
file "${database}" "${module}/Deployment" Deploy.sql -v DeploymentMode=local
file "${database}" "${module}/Tests/Runtime" Range.Contract.sql
file "${database}" "${module}/Tests/Runtime" Lifecycle.Contract.sql
file "${database}" "${module}/Deployment" Uninstall.sql -v ConfirmNoExternalConsumers=0
query "${database}" "IF EXISTS(SELECT 1 FROM sys.objects WHERE schema_id=SCHEMA_ID(N'toolbelt_pseudonymization')) THROW 54090,N'Deterministic uninstall left objects.',1;"
file "${database}" "${module}/Deployment" Uninstall.sql -v ConfirmNoExternalConsumers=0
central=tbx_deterministic_central
consumer=tbx_deterministic_consumer
query master "CREATE DATABASE [${central}] COLLATE Latin1_General_100_BIN2; CREATE DATABASE [${consumer}] COLLATE Latin1_General_100_CI_AS;"
file "${central}" /workspace/Modules/toolbelt.core.result-table/Deployment Deploy.sql -v DeploymentMode=central
file "${central}" "${module}/Deployment" Deploy.sql -v DeploymentMode=central
for level in ${levels}; do
  query "${central}" "ALTER DATABASE [${central}] SET COMPATIBILITY_LEVEL=${level};"
  file "${central}" "${module}/Tests/Runtime" Range.Contract.sql
  file "${central}" "${module}/Tests/Runtime" DateShift.Contract.sql
  file "${central}" "${module}/Tests/Runtime" Lookup.Contract.sql
  file "${central}" "${module}/Tests/Runtime" Lookup.Boundaries.sql
  file "${consumer}" "${module}/Tests/Runtime" Central.Contract.sql -v CentralDb="${central}"
done
file "${central}" "${module}/Tests/Runtime" Lifecycle.Contract.sql
metadata "${central}"
expect_failure "${central}" "${module}/Deployment" Uninstall.sql 54026 -v ConfirmNoExternalConsumers=0
query "${central}" "IF OBJECT_ID(N'toolbelt_pseudonymization.TVF_DeterministicRange',N'IF') IS NULL THROW 54090,N'Central confirmation preflight mutated objects.',1;"
file "${central}" "${module}/Deployment" Uninstall.sql -v ConfirmNoExternalConsumers=1
collision=tbx_deterministic_collision
query master "CREATE DATABASE [${collision}] COLLATE Latin1_General_100_CI_AS;"
file "${collision}" /workspace/Modules/toolbelt.core.result-table/Deployment Deploy.sql -v DeploymentMode=local
query "${collision}" "CREATE SCHEMA toolbelt_pseudonymization;"
query "${collision}" "CREATE PROCEDURE toolbelt_pseudonymization.tvf_deterministicrange AS SELECT 7 AS SyntheticForeign;"
expect_failure "${collision}" "${module}/Deployment" Deploy.sql 54024 -v DeploymentMode=local
query "${collision}" "IF OBJECT_ID(N'toolbelt_pseudonymization.tvf_deterministicrange',N'P') IS NULL OR (SELECT COUNT(*) FROM sys.objects WHERE schema_id=SCHEMA_ID(N'toolbelt_pseudonymization'))<>1 OR EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.pseudonymization.deterministic.Version') THROW 54090,N'Foreign casing collision was mutated/adopted.',1;"
missing=tbx_deterministic_missing
query master "CREATE DATABASE [${missing}];"
expect_failure "${missing}" "${module}/Deployment" Deploy.sql 54028 -v DeploymentMode=local
query "${missing}" "IF SCHEMA_ID(N'toolbelt_pseudonymization') IS NOT NULL THROW 54090,N'Missing dependency preflight mutated schema.',1;"
echo "PASS: Deterministic synthetic API/resources/lifecycle/local/central SQL ${sql_version}; no crossDB lowpriv or throughput guarantee"
